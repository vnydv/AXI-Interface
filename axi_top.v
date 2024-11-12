`timescale 1ns / 1ps

module axi_top;

    `define ABUS_SIZE 5
    `define DBUS_SIZE 32
    `define TP 5

    `define use_tasks 0
    `define read_check 1

    reg clk;
    
    // signals for reading from master (this top)
    reg rst;
    reg [`ABUS_SIZE-1:0] raddr;
    reg arvalid;
    reg rready;

    //  signals from slave for reading
    wire arready;
    wire rvalid;
    wire [`DBUS_SIZE:0] rdata;
    wire [1:0] rresp;

    // signals for writing
    reg [`ABUS_SIZE-1:0] awaddr;
    reg awvalid;
    wire awready;

    reg [`DBUS_SIZE-1:0] wdata;
    wire wready;
    reg wvalid;

    wire [1:0] bresp;
    wire bvalid;
    reg bready;

    axi_subordinator #(.ABUS_SIZE(`ABUS_SIZE), .DBUS_SIZE(`DBUS_SIZE)) AXIS
    (
        .ACLK(clk),
        .ARESETn(rst),
        .ARADDR(raddr),
        .ARVALID(arvalid),
        .ARREADY(arready),
        .RDATA(rdata),
        .RVALID(rvalid),
        .RREADY(rready),
        .RRESP(rresp),

        .AWADDR(awaddr),
        .AWVALID(awvalid),
        .AWREADY(awready),
        .WDATA(wdata),
        .WVALID(wvalid),
        .WREADY(wready),
        .BRESP(bresp),
        .BVALID(bvalid),
        .BREADY(bready)
    );



    // initial load the RAM
    initial begin
        AXIS.RAM[0] = 32'b0;
        AXIS.RAM[1] = 32'b1;
        AXIS.RAM[2] = 32'b10;
        AXIS.RAM[3] = 32'b11;

        clk = 0;
        rst = 0;
        forever #`TP clk = ~clk;
    end
    

    // state machine kind of Reading Operation Verification
    // S0 -> RESET
    // S1 -> SET_VALID and WAITING_FOR_SLAVE_READY
    // S2 -> SLAVE_READY set READ_READY
    // S3 -> got READ_VALID -- strobe the values

    // read states
    parameter S_RESET = 2'b00;
    parameter S_AVALID = 2'b01;
    parameter S_SREADY = 2'b10;
    parameter S_RVALID = 2'b11;

    reg [1:0] rstate = S_RESET;

    // write states
    // S0 -> RESET
    // S1 -> PUT Addr and WriteData valid
    // S2 -> WAIT for awready
    // S3 -> WAIT for wready
    // S4 -> WAIT for bvalid
    // S5 -> RESET

    parameter S_WRESET = 3'b000;
    parameter S_WARVALID = 3'b001;
    parameter S_AREADY = 3'b010;
    parameter S_WREADY = 3'b011;
    parameter S_BVALID = 3'b100;
    
    reg [2:0] wstate = S_RESET;

    // read check
    always @(posedge clk)
    begin
        if ((`read_check) && !`use_tasks) begin
        
            case (rstate)
                S_RESET: begin
                    rst <= 0;
                    raddr <= 0;
                    arvalid <= 0;
                    rready <= 0;
                    rstate <= S_AVALID;
                end
                S_AVALID: begin
                    rst <= 1;
                    raddr <= 5'b10;
                    arvalid <= 1;
                    rstate <= S_SREADY;
                    // use strobe -- since update at end of time frame
                    $strobe("%d \t sent ARADDR: %b", $time, raddr);
                    $strobe("%d \t set ARVALID: %b", $time, arvalid);
                end
                S_SREADY: begin
                    if (arready) begin
                        arvalid <= 0;
                        raddr <= 0;
                        rready <= 1;
                        rstate <= S_RVALID;
                        $display("%d \t ARREADY asserted", $time);
                    end
                end
                S_RVALID: begin
                    if (rvalid) begin
                        $display("%d \t RDATA: %d %b", $time, rdata, rdata);
                        rstate <= S_RESET;
                        if (rdata == 32'b10) begin
                            $display("%d \t RDATA is correct", $time);
                        end
                    end
                end
            endcase
        end
    end

    // write check
    always @(posedge clk) begin
        if ((!`read_check) && !`use_tasks) begin
            case (wstate)
                S_WRESET: begin
                    rst <= 0;
                    awaddr <= 0;
                    awvalid <= 0;
                    wdata <= 0;
                    wvalid <= 0;
                    bready <= 0;
                    wstate <= S_WARVALID;
                    $display("%d \t WRITE RESET", $time);
                end
                S_WARVALID: begin
                    // asserted together
                    rst <= 1;
                    awaddr <= 5'b11;
                    awvalid <= 1;
                    wdata <= 32'b101;
                    wvalid <= 1;
                    wstate <= S_AREADY;
                    bready <= 1;
                    $strobe("%d \t sent AWADDR: %b", $time, awaddr);
                    $strobe("%d \t set AWVALID: %b", $time, awvalid);                    
                end
                S_AREADY: begin
                    if (awready) begin
                        // just some dummy data to write and check below
                        wstate <= S_WREADY;
                        $display("%d \t AWREADY asserted", $time);
                        $strobe("%d \t sent WDATA: %b", $time, wdata);
                        $strobe("%d \t set WVALID: %b", $time, wvalid);
                    end
                end
                S_WREADY: begin
                    if (wready) begin
                        awvalid <= 0;
                        awaddr <= 0;
                        wvalid <= 0;
                        wstate <= S_BVALID;
                        $display("%d \t WREADY asserted", $time);
                    end
                end
                S_BVALID: begin
                    if (bvalid) begin
                        $display("%d \t BRESP: %d %b", $time, bresp, bresp);
                        wstate <= S_WRESET;
                        wdata <= 0;
                        if (AXIS.RAM[3] == 32'b101) begin
                            $display("%d \t WRITE_DATA is correct", $time);
                        end
                    end
                end
            endcase
        end
    end


    // using task based approach
    task make_read_transaction;
        input [`ABUS_SIZE-1:0] addr;
        input [`DBUS_SIZE-1:0] expectedData;
        begin
            // reset the signals
            rst = 1;
            rready = 0;

            // set the data
            raddr = addr;
            arvalid = 1;

            $display("%d \t sent ARADDR: %b", $time, raddr);
            $display("%d \t set ARVALID: %b", $time, arvalid);

            // skip a clock
            @(posedge clk);
            rst = 1;
            // check if slave ready
            while (!arready) @(posedge clk);
            arvalid = 0;
            $display("%d \t ARREADY asserted", $time);

            // wait for read valid
            rready = 1;
            while (!rvalid) @(posedge clk);
            rready = 0;
            $display("%d \t RREADY asserted", $time);

            if (rdata == expectedData) begin
                $display("%d \t RDATA is correct %d %d", $time, rdata, expectedData);
            end
            else begin
                $display("%d \t RDATA is wrong! %d %d", $time, rdata, expectedData);
            end
        end
    endtask



    // end after 100 ns
    initial begin
        
        #20
        if (`use_tasks) begin
            // let a read transaction 
            // with Reg Addr 2 - 0b10 with expected data being 0b10
            // TODO: add for write also
            make_read_transaction(`ABUS_SIZE'b10,`DBUS_SIZE'b10);
        end

        #200
        $finish;
    end

endmodule 

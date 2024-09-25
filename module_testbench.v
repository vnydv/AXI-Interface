module tb_axi_interface;

    // Parameters
    localparam ADDR_WIDTH = 32;
    localparam DATA_WIDTH = 32;
    localparam ID_WIDTH = 4;

    // Clock and reset
    reg clk;
    reg resetn;

    // Write Address Channel
    reg [ID_WIDTH-1:0] awid;
    reg [ADDR_WIDTH-1:0] awaddr;
    reg [7:0] awlen;
    reg [2:0] awsize;
    reg [1:0] awburst;
    reg awvalid;
    wire awready;

    // Write Data Channel
    reg [DATA_WIDTH-1:0] wdata;
    reg [(DATA_WIDTH/8)-1:0] wstrb;
    reg wlast;
    reg wvalid;
    wire wready;

    // Write Response Channel
    wire [ID_WIDTH-1:0] bid;
    wire [1:0] bresp;
    wire bvalid;
    reg bready;

    // Read Address Channel
    reg [ID_WIDTH-1:0] arid;
    reg [ADDR_WIDTH-1:0] araddr;
    reg [7:0] arlen;
    reg [2:0] arsize;
    reg [1:0] arburst;
    reg arvalid;
    wire arready;

    // Read Data Channel
    wire [ID_WIDTH-1:0] rid;
    wire [DATA_WIDTH-1:0] rdata;
    wire [1:0] rresp;
    wire rlast;
    wire rvalid;
    reg rready;

    // Instantiate the AXI interface
    axi_interface #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ID_WIDTH(ID_WIDTH)
    ) uut (
        .clk(clk),
        .resetn(resetn),
        .awid(awid),
        .awaddr(awaddr),
        .awlen(awlen),
        .awsize(awsize),
        .awburst(awburst),
        .awvalid(awvalid),
        .awready(awready),
        .wdata(wdata),
        .wstrb(wstrb),
        .wlast(wlast),
        .wvalid(wvalid),
        .wready(wready),
        .bid(bid),
        .bresp(bresp),
        .bvalid(bvalid),
        .bready(bready),
        .arid(arid),
        .araddr(araddr),
        .arlen(arlen),
        .arsize(arsize),
        .arburst(arburst),
        .arvalid(arvalid),
        .arready(arready),
        .rid(rid),
        .rdata(rdata),
        .rresp(rresp),
        .rlast(rlast),
        .rvalid(rvalid),
        .rready(rready)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Reset task
    task reset;
        begin
            resetn = 1'b0;
            repeat (2) @(posedge clk);
            resetn = 1'b1;
        end
    endtask

    // Write transaction task
    task write_transaction;
        input [ID_WIDTH-1:0] id;
        input [ADDR_WIDTH-1:0] address;
        input [DATA_WIDTH-1:0] data;
        begin
            awid = id;
            awaddr = address;
            awlen = 8'd0;
            awsize = 3'b010;
            awburst = 2'b01;
            awvalid = 1'b1;
            wdata = data;
            wstrb = 4'b1111;
            wlast = 1'b1;
            wvalid = 1'b1;

            @(posedge clk);
            while (!awready) @(posedge clk);
            awvalid = 1'b0;

            while (!wready) @(posedge clk);
            wvalid = 1'b0;

            bready = 1'b1;
            while (!bvalid) @(posedge clk);
            bready = 1'b0;
        end
    endtask

    // Read transaction task
    task read_transaction;
        input [ID_WIDTH-1:0] id;
        input [ADDR_WIDTH-1:0] address;
        begin
            arid = id;
            araddr = address;
            arlen = 8'd0;
            arsize = 3'b010;
            arburst = 2'b01;
            arvalid = 1'b1;

            @(posedge clk);
            while (!arready) @(posedge clk);
            arvalid = 1'b0;

            rready = 1'b1;
            while (!rvalid) @(posedge clk);
            rready = 1'b0;
        end
    endtask

    // Test sequence
    initial begin
        clk = 1'b0;
        resetn = 1'b0;

        awid = 0;
        awaddr = 0;
        awlen = 0;
        awsize = 0;
        awburst = 0;
        awvalid = 0;
        wdata = 0;
        wstrb = 0;
        wlast = 0;
        wvalid = 0;
        bready = 0;

        arid = 0;
        araddr = 0;
        arlen = 0;
        arsize = 0;
        arburst = 0;
        arvalid = 0;
        rready = 0;

        reset;

        // Write transaction
        write_transaction(4'b0001, 32'hA000_0000, 32'hDEADBEEF);

        // Read transaction
        read_transaction(4'b0010, 32'hA000_0000);

        #100 $finish;
    end

endmodule

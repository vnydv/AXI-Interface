
// Timing diagram reference
// https://docs.amd.com/r/en-US/pg202-mipi-dphy/AXI4-Lite-Interface

// Doc reference for Reg and Signals
// https://www.realdigital.org/doc/a9fee931f7a172423e1ba73f66ca4081

// Theory refernce
// ARM Fundamentals Manual

// implementation breakdown
// read transaction
// write transaction

module axi_subordinator #(
    // memory access address size
    parameter ABUS_SIZE = 5,
    // memory data bus width
    parameter DBUS_SIZE = 32)
(
    input ACLK, ARESETn,

    // read address channel
    input [ABUS_SIZE-1:0] ARADDR,
    input ARVALID,
    output ARREADY,

    // read data channel
    output [DBUS_SIZE:0] RDATA,
    output RVALID,
    input RREADY,

    // read response
    output [1:0] RRESP,

    // write address channel
    input [ABUS_SIZE-1:0] AWADDR,
    input AWVALID,
    output AWREADY,

    // write data channel
    input [DBUS_SIZE-1:0] WDATA,
    input WVALID,
    output WREADY,

    // write response channel
    output [1:0] BRESP,
    output BVALID,
    input BREADY
);

    // define the RAM -- for writing and reading
    reg [DBUS_SIZE-1:0] RAM [ABUS_SIZE-1:0];



    // ------------------------ WRITE Transaction control ---------------
    // define the regs for signal assignment
    reg [ABUS_SIZE-1:0] awaddr;
    reg [DBUS_SIZE-1:0] wdata;

    // write signals
    reg awready;
    reg wready;
    reg bvalid;
    reg _wdone;
    reg [1:0] bresp;

    // assign to ports
    assign AWREADY = awready;
    assign WREADY = wready;
    assign BVALID = bvalid;
    assign BRESP = bresp;

    // note both address and data must be set to 1
    // for write address to be valid
    always @(posedge ACLK) begin
        if (!ARESETn) awready <= 1'b0;
        else if (AWVALID && WVALID) awready <= 1'b1;
        else awready <= 1'b0;
    end

    // set the write ready signal
    // stating data is ready to be written
    // yo, handshake again!!!
    always @(posedge ACLK) begin
        if (!ARESETn) wready <= 1'b0;
        else if (awready && WVALID) wready <= 1'b1;
        else wready <= 1'b0;
    end

    // take the write address
    always @(posedge ACLK) begin
        if (!ARESETn) awaddr <= 0;
        else if (awready) awaddr <= AWADDR;
        else awaddr <= awaddr;
    end

    // take the data upon wready
    // set the bvalid signal
    always @(posedge ACLK) begin
        if (!ARESETn) begin
            bvalid <= 0;
            _wdone <= 2'b00;
            bresp <= 2'b00;
        end
        else if (awready && wready) begin 
            // TODO: condition check for invalid read access
            RAM[awaddr] <= WDATA;
            _wdone <= 1;
            bresp <= 2'b01;
        end
    end

    // send the bvalid
    // upon the write done
    always @(posedge ACLK) begin
        if (!ARESETn) bvalid <= 1'b0;
        else if (_wdone && BREADY) begin 
            bvalid <= 1'b1;
            _wdone <= 0;
        end
        else bvalid <= 1'b0;
    end


    // ------------------------ READ Transaction control ---------------    
    // read    
    reg [ABUS_SIZE-1:0] araddr;
    reg [ABUS_SIZE-1:0] rdata;

    // internal signals to assign to ports
    // ready signals
    reg arready;
    // valid signals
    reg rvalid;
    reg[1:0] rresp;
    reg _rvalid; // using this to store that the read is requested

    // assign to ports
    assign ARREADY = arready;
    assign RVALID = rvalid;
    assign RDATA = rdata;
    assign RRESP = rresp;

    // check address valid
    // steps:
    // if valid address
    // set addr ready to 1
    always @(posedge ACLK) begin
        // if reset if 0 (-ve triggered)
        if (!ARESETn) arready <= 0;
        // if valid and not-ready make ready
        else if (ARVALID) arready <= 1'b1;
        // else: don't signal or dassert after the AR is latched
        else arready <= 1'b0;
    end

    // if both:
    // addr valid and slave ready
    // handshake!!!
    // update the addr and deassert the line
    // (done as per valid -- check previous)
    always @(posedge ACLK) begin
        if (!ARESETn) araddr <= 0;
        else if (arready) araddr <= ARADDR;
        else araddr <= 0;
    end

    // set the internal valid signal -- since Master can deassrt the others
    always @(posedge ACLK) begin
        if (!ARESETn) begin
            _rvalid <= 1'b0;
        end
        else if (arready && ARVALID) begin
            _rvalid <= 1'b1;
        end
    end

    // read the data from RAM
    // and set the ready valid signal
    // upon reading set the rvalid to 1
    always @(posedge ACLK) begin
        if (!ARESETn) begin
            rvalid <= 1'b0;
            rdata <= 0;
            rresp <= 2'b00;
        end
        else if (RREADY && _rvalid) begin
            rdata <= RAM[araddr];
            rvalid <= 1'b1;
            rresp <= 2'b01;
            _rvalid <= 1'b0;
        end
        else begin
            rdata <= rdata;
            rvalid <= 1'b0;
            rresp <= 2'b00;
        end
    end


    


endmodule

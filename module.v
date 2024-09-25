module axi_interface #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter ID_WIDTH = 4
) (
    input wire clk,
    input wire resetn,

    // Write Address Channel
    input wire [ID_WIDTH-1:0] awid,
    input wire [ADDR_WIDTH-1:0] awaddr,
    input wire [7:0] awlen,
    input wire [2:0] awsize,
    input wire [1:0] awburst,
    input wire awvalid,
    output wire awready,

    // Write Data Channel
    input wire [DATA_WIDTH-1:0] wdata,
    input wire [(DATA_WIDTH/8)-1:0] wstrb,
    input wire wlast,
    input wire wvalid,
    output wire wready,

    // Write Response Channel
    output wire [ID_WIDTH-1:0] bid,
    output wire [1:0] bresp,
    output wire bvalid,
    input wire bready,

    // Read Address Channel
    input wire [ID_WIDTH-1:0] arid,
    input wire [ADDR_WIDTH-1:0] araddr,
    input wire [7:0] arlen,
    input wire [2:0] arsize,
    input wire [1:0] arburst,
    input wire arvalid,
    output wire arready,

    // Read Data Channel
    output wire [ID_WIDTH-1:0] rid,
    output wire [DATA_WIDTH-1:0] rdata,
    output wire [1:0] rresp,
    output wire rlast,
    output wire rvalid,
    input wire rready
);

// Internal Signals
reg awready_reg, wready_reg, bvalid_reg, arready_reg, rvalid_reg;
reg [ID_WIDTH-1:0] bid_reg, rid_reg;
reg [1:0] bresp_reg, rresp_reg;
reg [DATA_WIDTH-1:0] rdata_reg;
reg rlast_reg;

assign awready = awready_reg;
assign wready = wready_reg;
assign bvalid = bvalid_reg;
assign bid = bid_reg;
assign bresp = bresp_reg;
assign arready = arready_reg;
assign rvalid = rvalid_reg;
assign rid = rid_reg;
assign rdata = rdata_reg;
assign rresp = rresp_reg;
assign rlast = rlast_reg;

always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
        awready_reg <= 1'b0;
        wready_reg <= 1'b0;
        bvalid_reg <= 1'b0;
        arready_reg <= 1'b0;
        rvalid_reg <= 1'b0;
        rlast_reg <= 1'b0;
    end else begin
        awready_reg <= 1'b1;
        wready_reg <= 1'b1;
        bvalid_reg <= 1'b1;
        bid_reg <= awid;
        bresp_reg <= 2'b00;

        arready_reg <= 1'b1;
        rvalid_reg <= 1'b1;
        rid_reg <= arid;
        rdata_reg <= {DATA_WIDTH{1'b0}};
        rresp_reg <= 2'b00;
        rlast_reg <= 1'b1;
    end
end

endmodule

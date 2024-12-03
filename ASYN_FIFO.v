 `timescale 1ns/1ps
 
 module ASYN_FIFO
 #(parameter DATESIZE = 17,
   parameter ADDRSIZE = 4,
   parameter WATERLINE = 1
)
(
    input [DATESIZE-1:0] wdata,
    input wen, wclk, wrst_n,
    input ren, rclk, rrst_n,
    output wire [DATESIZE-1:0] rdata,
    output reg wfull,
    output reg rempty,
    output reg almost_full,
    output reg almost_empty
);

//=================================================================================
// AGENTS
//=================================================================================
localparam DEPTH = 1<<ADDRSIZE;

wire [ADDRSIZE-1:0] waddr, raddr;
reg  [ADDRSIZE:0] wptr, rptr;
wire rempty_val,wfull_val;

reg [DATESIZE-1:0] mem [0:DEPTH-1];

reg [ADDRSIZE:0] wq1_rptr,wq2_rptr;
reg [ADDRSIZE:0] rq1_wptr,rq2_wptr;

reg [ADDRSIZE:0] rbin;
wire [ADDRSIZE:0] rgraynext, rbinnext;

reg [ADDRSIZE:0] wbin;
wire [ADDRSIZE:0] wgraynext, wbinnext;

wire [ADDRSIZE:0] full_flag;

wire [ADDRSIZE:0]rq2_wptr_bin,wq2_rptr_bin;
wire almost_empty_val,almost_full_val;

wire [ADDRSIZE:0] rgap_reg;

wire [ADDRSIZE:0] wgap_reg;

//=================================================================================
// MAIN
//=================================================================================
assign rdata = mem[raddr];

always @(posedge wclk) begin
    if (wen && !wfull) begin
        mem[waddr] <= wdata;  
    end 
end

// rd to wr sync
always @(posedge wclk or negedge wrst_n) begin
    if (!wrst_n) begin
        {wq2_rptr,wq1_rptr} <= 0;
    end else begin
        {wq2_rptr,wq1_rptr} <= {wq1_rptr,rptr};
    end
end

// wr to rd sync
always @(posedge rclk or negedge rrst_n) begin
    if (!rrst_n) begin
        {rq2_wptr,rq1_wptr} <= 0;    
    end else begin
        {rq2_wptr,rq1_wptr} <= {rq1_wptr,wptr};
    end
end

//rd_p & empty generation
always @(posedge rclk or negedge rrst_n) begin
    if (!rrst_n) begin
        {rbin, rptr} <= 0; 
    end else begin
        {rbin, rptr} <= {rbinnext, rgraynext};
    end
end

// mem rd addr pointer
assign raddr = rbin[ADDRSIZE-1:0];
assign rbinnext = rbin + (ren & ~rempty);
assign rgraynext = (rbinnext>>1) ^ rbinnext;

// FIFO empty when the next rptr == synced wp or on reset
assign rempty_val = (rgraynext == rq2_wptr);

always @(posedge rclk or negedge rrst_n) begin
    if (!rrst_n) begin
        rempty <= 1'b1;
    end else begin
        rempty <= rempty_val;
    end
end

// wr_p & full generation
always @(posedge wclk or negedge wrst_n) begin
    if (!wrst_n)begin
        {wbin, wptr} <= 0;
    end else begin
        {wbin, wptr} <= {wbinnext, wgraynext};
    end
end

// mem wr addr pointer
assign waddr = wbin[ADDRSIZE-1:0];
assign wbinnext = wbin + (wen & ~ wfull);
assign wgraynext = (wbinnext>>1) ^ wbinnext;

assign full_flag = {~wq2_rptr[ADDRSIZE:ADDRSIZE-1],wq2_rptr[ADDRSIZE-2:0]};
assign wfull_val = (wgraynext==full_flag);

always @(posedge wclk or negedge wrst_n) begin
    if (!wrst_n) begin
        wfull <= 1'b0;
    end else begin
        wfull <= wfull_val;
    end
end

// almost logic
assign rq2_wptr_bin[ADDRSIZE] = rq2_wptr[ADDRSIZE]; 
assign wq2_rptr_bin[ADDRSIZE] = wq2_rptr[ADDRSIZE];

genvar i;
generate
    for(i=ADDRSIZE-1;i>=0;i=i-1) begin:wp_gray2bin          
        assign rq2_wptr_bin[i] = rq2_wptr_bin[i+1]^rq2_wptr[i];
        assign wq2_rptr_bin[i] = wq2_rptr_bin[i+1]^wq2_rptr[i];
    end
endgenerate

// rd almost empty
assign rgap_reg = rq2_wptr_bin - rbin;
assign almost_empty_val = (rgap_reg <= WATERLINE);

always @(posedge rclk or negedge rrst_n) begin
    if (!rrst_n) begin
        almost_empty <= 1'b1;
    end else begin
        almost_empty <= almost_empty_val;
    end
end

//wr almost full
assign wgap_reg = (wbin[ADDRSIZE] ^ wq2_rptr_bin[ADDRSIZE])? wq2_rptr_bin[ADDRSIZE-1:0] - wbin[ADDRSIZE-1:0]:DEPTH + wq2_rptr_bin - wbin;
assign almost_full_val = (wgap_reg <= WATERLINE);

always @(posedge wclk or negedge wrst_n)begin
    if (!wrst_n) begin
        almost_full <= 1'b0;
    end else begin
        almost_full <= almost_full_val;
    end
end

//=================================================================================
// INSTANTIATION
//=================================================================================

//=================================================================================
// END MODULE
//=================================================================================
endmodule 

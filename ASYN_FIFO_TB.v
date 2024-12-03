`timescale 1ns/1ps

module ASYN_FIFO_TB;

    parameter DATESIZE = 17;
    parameter ADDRSIZE = 4;
    parameter WATERLINE = 1; 

    reg wclk;
    reg wrst_n;
    reg rclk;
    reg rrst_n;

    reg wen;
    reg ren;

    reg [DATESIZE-1:0]wdata;
    wire [DATESIZE-1:0]rdata;

    wire wfull;
    wire rempty;
    wire almost_empty;
    wire almost_full;

    reg [3:0]a;
    reg [3:0]b;
    reg [4:0]c;
    reg x;

    always begin 
        #4;
        wclk = ~wclk;
    end
    always begin
        #2;
        rclk = ~rclk;
    end

    initial begin
        $dumpfile("ASYN_FIFO_TB.vcd");
        $dumpvars;
        wclk = 0;
        wrst_n = 0;
        rclk = 0;
        rrst_n = 0;
        
        ren = 0;
        wen = 0;

        wdata = 0;
    
        #4;
        wrst_n = 0;
        rrst_n = 0;
        #2;
        wrst_n = 1; 
        rrst_n = 1;
     
        #10000;
        $finish();
    end

 always @(posedge wclk or wrst_n)begin
    if( wrst_n == 1'b0 )begin 
        wen = 1'b0;
    end 
    else if(wfull)
        wen = 1'b0;
    else 
        wen = 1'b1 ;
end 
    
// ren generate    
always @(posedge rclk or rrst_n)begin
    if(rrst_n == 1'b0)begin
        ren = 1'b0 ;
    end 
    else if(rempty)
        ren = 1'b0;
    else 
        ren = 1'b1 ;
end 

// wdata 
always @(posedge wclk or negedge wrst_n)begin
    if( wrst_n == 1'b0 )begin
        wdata = 0 ;
    end  
    else if( wen )begin 
        wdata = wdata + 1'b1;
    end 
end 



ASYN_FIFO#(
    .DATESIZE                       (DATESIZE),
    .ADDRSIZE                       (ADDRSIZE),
    .WATERLINE                      (WATERLINE)
)U_ASYN_FIFO_0(
    .wdata                          (wdata),
    .wen                            (wen),
    .wclk                           (wclk),
    .wrst_n                         (wrst_n),
    .ren                            (ren),
    .rclk                           (rclk),
    .rrst_n                         (rrst_n),
    .rdata                          (rdata),
    .wfull                          (wfull),
    .rempty                         (rempty),
    .almost_empty                   (almost_empty),
    .almost_full                    (almost_full)
);

endmodule
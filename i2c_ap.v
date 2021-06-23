`timescale 1ns / 1ps
//******************************************************************************
// File Name            : i2c_ap.v
//------------------------------------------------------------------------------
// Function             : i2c sample application
//                        
//------------------------------------------------------------------------------
// Designer             : yokomizo 
//------------------------------------------------------------------------------
// History
// -.-- 2010/10/09
//******************************************************************************
module i2c_ap ( 
 clk, rstb, led_0,
 scl, sda
);
  input clk;
  input rstb;
  output scl;   //I2C SCL
  inout  sda;   //I2C SDA
   
  wire wr;
  wire rd;
  wire [6:0]adr;
  wire [31:0]wr_data; 
  wire [2:0]wr_bytes; 
  wire [3:0]wr_be; 
  wire rd_data_en;
  wire [31:0]rd_data;
  wire [2:0]rd_bytes; 
  wire [3:0]rd_be; 
  wire    scl_drv;
  wire    sda_i;
  wire    sda_o;

// IO driver      
assign sda = (sda_o==1'b0)?1'b0:1'bz;
assign sda_i = sda;
assign scl = (scl_drv==1'b0)?1'b0:1'bz;
   
i2c_m_if i2c_m_if(
  .clk(   clk),
  .rstb(  rstb),
  .scl(  scl_drv),
  .sda_o(  sda_o),
  .sda_i(  sda_i),
  .wr(    wr),
  .rd(    rd),
  .adr(   adr),
  .wr_data(wr_data),
  .wr_bytes(wr_bytes),
  .rd_data(rd_data),
  .rd_data_en(rd_data_en),
  .rd_bytes(rd_bytes),
  .busy(busy) 
  );

i2c_kxp84_ctrl i2c_dev_ctrl( 
  .clk(   clk),
  .rstb(  rstb),
  .led_0( led_0),
  .wr(    wr),
  .rd(    rd),
  .adr(   adr),
  .wr_data(wr_data),
  .wr_bytes(wr_bytes),
  .rd_data(rd_data),
  .rd_data_en(rd_data_en),
  .rd_bytes(rd_bytes),
  .tx_fifo_data_en    (tx_fifo_data_en),   
  .tx_fifo_data   (tx_fifo_data)
);
   
endmodule







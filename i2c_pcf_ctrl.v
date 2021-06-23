`timescale 1ns / 1ps
//******************************************************************************
// File Name            : i2c_lm_ctrl.v
//------------------------------------------------------------------------------
// Function             : i2c LM73 controler
//                        
//------------------------------------------------------------------------------
// Designer             : yokomizo 
//------------------------------------------------------------------------------
// History
// -.-- 2010/10/09
//******************************************************************************
module i2c_pcf_ctrl ( 
 clk, rstb, led_0,
 wr,rd,adr,wr_data,wr_bytes,rd_data,rd_data_en,rd_bytes
);
  input clk;
  input rstb;
  output wr;
  output rd;
  output [6:0]adr;
  output [31:0]wr_data;
  output [2:0]wr_bytes;
  output [2:0]rd_bytes;
  input[31:0]rd_data;
  input  rd_data_en;
 
  reg  [25:0] main_cnt;

  reg wr;
  reg rd;
  reg [6:0]adr;
  reg [31:0]wr_data; 
  reg [2:0]wr_bytes; 
  wire [3:0]wr_be; 
  wire rd_data_en;
  wire [31:0]rd_data;
  reg [2:0]rd_bytes; 
  wire [3:0]rd_be; 
   
  reg [3:0] msg_cnt;  //tx fifo data 8bit
  reg [1:0] msg_type;
  wire [31:0]msg_data;
  wire [3:0]msg_be;
   
  reg  [7:0] tx_fifo_data;    //tx fifo data 8bit
  reg        tx_fifo_data_en; //tx fifo data enable 

  reg        temp;
  reg [31:0] temp_data;
  reg [31:0] temp_be;
  wire [11:0] seisuu;
  wire [3:0]  point1;
   
   
function [7:0] hex2ascii;
  input [3:0] hex_data;
  begin
    if (hex_data<4'ha)
      hex2ascii = 8'h30 + hex_data;
    else
      hex2ascii = 8'h37 + hex_data;
  end
endfunction
   
//16進->バイナリーコードデシマル変換　整数二桁
function [11:0] hex2bcd;
  input [7:0] hex_data;
  reg   [7:0] tmp_data;   
  begin
    if (hex_data>=8'hc8)
      begin
        hex2bcd[11:8] = 4'h2;
        tmp_data = hex_data -8'hc8;       
      end
    else if (hex_data>=8'h64)
      begin
        hex2bcd[11:8] = 4'h1;
        tmp_data = hex_data -8'h64;      
      end
    else
      begin
        hex2bcd[11:8] = 4'h0;
        tmp_data = hex_data; 
      end
    // 
    if (tmp_data>=8'h5A)
      begin
        hex2bcd[7:4] = 4'h9;
        tmp_data = tmp_data -8'h5a;       
      end
    else if (tmp_data>=8'h50)
      begin
        hex2bcd[7:4] = 4'h8;
        tmp_data = tmp_data -8'h50;       
      end
    else if (tmp_data>=8'h46)
      begin
        hex2bcd[7:4] = 4'h7;
        tmp_data = tmp_data -8'h46;       
      end
    else if (tmp_data>=8'h3c)
      begin
        hex2bcd[7:4] = 4'h6;
        tmp_data = tmp_data -8'h3c;       
      end
    else if (tmp_data>=8'h32)
      begin
        hex2bcd[7:4] = 4'h5;
        tmp_data = tmp_data -8'h32;       
      end
    else if (tmp_data>=8'h28)
      begin
        hex2bcd[7:4] = 4'h4;
        tmp_data = tmp_data -8'h28;       
      end
    else if (tmp_data>=8'h1e)
      begin
        hex2bcd[7:4] = 4'h3;
        tmp_data = tmp_data -8'h1e;       
      end
    else if (tmp_data>=8'h14)
      begin
        hex2bcd[7:4] = 4'h2;
        tmp_data = tmp_data -8'h14;      
      end
    else if (tmp_data>=8'ha)
      begin
        hex2bcd[7:4] = 4'h1;
        tmp_data = tmp_data -8'ha;        
      end
    else 
      begin
        hex2bcd[7:4] = 4'h0;
        tmp_data = tmp_data ;    
      end
     //
     hex2bcd[3:0]=tmp_data[3:0];
  end
endfunction


   
//16進->バイナリーコードデシマル変換　小数点以下1位
function [3:0] hex2point1;
  input [3:0] hex_data;
  begin
    if (hex_data==4'hf)
      hex2point1 = 4'd9;
    else if (hex_data>=4'hd)
      hex2point1 = 4'd8;
    else if (hex_data>=4'hc)
      hex2point1 = 4'd7;
    else if (hex_data>=4'ha)
      hex2point1 = 4'd6;
    else if (hex_data>=4'h8)
      hex2point1 = 4'd5;
    else if (hex_data>=4'h7)
      hex2point1 = 4'd4;
    else if (hex_data>=4'h5)
      hex2point1 = 4'd3;
    else if (hex_data>=4'h4)
      hex2point1 = 4'd2;
    else if (hex_data>=4'h2)
      hex2point1 = 4'd1;
    else
      hex2point1 = 4'd0;
  end
endfunction

always @ (posedge clk or negedge rstb )
  if (rstb==1'b0) begin 
    main_cnt <= 26'b0;
  end
  //else if (main_cnt == 26'd7999999) begin
  else if (main_cnt == 26'd39999999) begin
  //else if (main_cnt ==26'd5000000) begin
    main_cnt <= 26'b0;
    end
  else begin
    main_cnt <= main_cnt + 26'd1;
  end
   
assign led_0 = main_cnt[25];
 
   
// for LM73 temperature sensor

always @ (posedge clk or negedge rstb )
  if (rstb==1'b0) begin
    wr <= 1'b0;
    wr_data <=32'h00000000;
    wr_bytes <= 4'd0; 
    adr <= 7'b1001101;    //LM73
    end
  else
    //LM73の内部レジスタ指定の書き込み
    if (main_cnt == 26'd500000)
      begin
        wr <= 1'b1;
        //温度データレジスタ・ポインタを設定
        wr_data <= {32'h00000000};
        adr <= adr ;
        wr_bytes <= 3'd1;
      end
    else
      begin
        wr <= 1'b0;
        wr_data <= wr_data;
        adr <= adr;
        wr_bytes <= wr_bytes; 
      end

always @ (posedge clk or negedge rstb )
  if (rstb==1'b0)
    begin
      rd <= 1'b0; 
      rd_bytes <= 3'd0; 
    end   
  else 
    //温度の読み出し  
    if (main_cnt ==26'd3000000)
      begin
        rd <= 1'b1;
        rd_bytes <= 3'd2; 
      end
    else
      begin   
        rd <= 1'b0;
        rd_bytes <= rd_bytes; 
      end   
 
// wr,rd byte enable
assign wr_be = (wr_bytes==3'd1)?4'b1000:    
               (wr_bytes==3'd2)?4'b1100: 
               (wr_bytes==3'd3)?4'b1110:
               (wr_bytes==3'd4)?4'b1111:4'b0000;
   
assign rd_be = (rd_bytes==3'd1)?4'b1000:    
               (rd_bytes==3'd2)?4'b1100: 
               (rd_bytes==3'd3)?4'b1110:
               (rd_bytes==3'd4)?4'b1111:4'b0000;
   
//temperature message
//温度データを10進表示に変更
assign seisuu = hex2bcd(rd_data[30:23]);
assign point1 = hex2point1(rd_data[22:19]);
   
always @ (posedge clk or negedge rstb )
  if (rstb==1'b0)
    begin
      temp <= 1'b0; 
      temp_be <= 4'b0000; 
      temp_data<= 32'h00000000; 
    end   
  else   
    if (main_cnt ==26'd3500000)
      begin
        temp <= 1'b1;
        temp_be <= 4'b1110;
        temp_data<= {seisuu,4'h0,point1,12'h0000}; 
      end
    else
      begin   
        temp <= 1'b0;
        temp_be <= temp_be; 
        temp_data<= temp_data; 
      end // else: !if(main_cnt ==26'd3500000)
   

//re232c message
   
always @ (posedge clk or negedge rstb )
  if (rstb==1'b0)
    msg_type <= 2'b0;
  else
    if (wr==1'b1)
      msg_type <= 2'b00;
    else if (rd_data_en==1'b1)
      msg_type <= 2'b01;
    else if (temp==1'b1)
      msg_type <= 2'b10;
    else
      msg_type <= msg_type;

  
assign msg_data =(msg_type == 2'b00)? wr_data:
                 (msg_type == 2'b01)? rd_data:
                 (msg_type == 2'b10)? temp_data:32'h00000000;
   
assign msg_be =( msg_type == 2'b00)? wr_be:
               ( msg_type == 2'b01)? rd_be:
               ( msg_type == 2'b10)? temp_be:4'b0000;
   
always @ (posedge clk or negedge rstb )
  if (rstb==1'b0)
    msg_cnt <= 4'd0;
  else
    if ((wr==1'b1)||(rd_data_en==1'b1)||(temp==1'b1))
      msg_cnt <= 4'd1;
    else
      if (msg_cnt==4'd0)
        msg_cnt <= 4'd0;
      else
        msg_cnt <= msg_cnt + 4'd1;
    
always @ (posedge clk or negedge rstb )
  if (rstb==1'b0)
    begin
      tx_fifo_data <= 8'h00;
      tx_fifo_data_en <= 1'b0;
    end
  else
    case(msg_cnt)
      4'd0:begin
        tx_fifo_data <= 8'h00;
        tx_fifo_data_en <= 1'b0;
        end
      4'd1:begin
        if (msg_type==2'b00) 
          begin
            tx_fifo_data <= 8'h57; //"W"
            tx_fifo_data_en <= 1'b1;
          end
        else if (msg_type==2'b01) 
          begin
            tx_fifo_data <= 8'h52; //"R"
            tx_fifo_data_en <= 1'b1;
          end
        else if (msg_type==2'b10) 
          begin
            tx_fifo_data <= 8'h54; //"T"
            tx_fifo_data_en <= 1'b1;
          end
        else  
          begin
            tx_fifo_data <= 8'h44; //"E"
            tx_fifo_data_en <= 1'b1;
          end
        end
      4'd2:begin
        tx_fifo_data <= 8'h5f; // "-"
        tx_fifo_data_en <= 1'b1;
        end
      4'd3:begin
        if (msg_type[1]==1'b0)
          begin 
             tx_fifo_data <= hex2ascii(adr[6:3]);
             tx_fifo_data_en <= 1'b1;
          end
        else
          begin
            tx_fifo_data <= 8'h5f; // "-"
            tx_fifo_data_en <= 1'b1;
          end
        end
      4'd4:begin
        if (msg_type[1]==1'b0)
          begin
            tx_fifo_data <= hex2ascii({adr[2:0],msg_type[0]});
            tx_fifo_data_en <= 1'b1;
          end
        else
          begin
            tx_fifo_data <= 8'h5f; // "-"
            tx_fifo_data_en <= 1'b1;
          end
        end        
      4'd5:begin
        tx_fifo_data <= 8'h5f; // "-"
        tx_fifo_data_en <= 1'b1;
        end
      4'd6:begin
        tx_fifo_data <=  hex2ascii(msg_data[31:28]);
        tx_fifo_data_en <= msg_be[3];
        end
      4'd7:begin
        tx_fifo_data <=  hex2ascii(msg_data[27:24]);
        tx_fifo_data_en <= msg_be[3];
        end
      4'd8:begin
        tx_fifo_data <=  hex2ascii(msg_data[23:20]);
        tx_fifo_data_en <= msg_be[2];
        end
      4'd9:begin
        if (msg_type[1]==1'b0)
          begin
            tx_fifo_data <=  hex2ascii(msg_data[19:16]);
            tx_fifo_data_en <= msg_be[2];
          end
        else
          begin
            tx_fifo_data <= 8'h2e; // "."
            tx_fifo_data_en <= 1'b1;
          end
        end
      4'd10:begin
        tx_fifo_data <=  hex2ascii(msg_data[15:12]);
        tx_fifo_data_en <= msg_be[1];
        end
      4'd11:begin
        if (msg_type[1]==1'b0)
          begin
            tx_fifo_data <=  hex2ascii(msg_data[11:8]);
            tx_fifo_data_en <= msg_be[1];
          end
        else
          begin
            tx_fifo_data <= 8'h20; // " "
            tx_fifo_data_en <= 1'b1;
          end
        end
      4'd12:begin
        tx_fifo_data <=  hex2ascii(msg_data[7:4]);
        tx_fifo_data_en <= msg_be[0];
        end
      4'd13:begin
        tx_fifo_data <=  hex2ascii(msg_data[3:0]);
        tx_fifo_data_en <= msg_be[0];
        end
      4'd14:begin
        tx_fifo_data <= 8'h0a; // LF
        tx_fifo_data_en <= 1'b1;
        end
      default
        begin
          tx_fifo_data <= 8'h00;
          tx_fifo_data_en <= 1'b0;
        end
    endcase 
endmodule







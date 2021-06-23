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
 clk, rstb, led_0, wr, adr, wr_data, wr_bytes, busy, amount
);

  input clk;
  input rstb;
  output led_0;
  output wr;
  output [6:0]adr;
  output [31:0]wr_data;
  output [2:0]wr_bytes;
  input busy;
  input [7:0]amount;

  wire led_0;
  reg  [25:0] main_cnt;

  reg wr;
  reg [6:0]adr;
  reg [31:0]wr_data;
  reg [2:0]wr_bytes;
  wire [3:0]wr_be;

  reg init_finished;
  reg [3:0]init_state;
  reg [2:0]instruct_count;


function [7:0] hex2ascii;
  input [3:0] hex_data;
  begin
      hex2ascii = 8'b00110000 || hex_data;
  end
endfunction

task send(
  input [7:0]inst,
  output wr,
  output [31:0]wr_data,
  output [6:0]adr,
  output [2:0]wr_bytes
);
begin
  wr <= 1'b1;
  wr_data[31:28] <= {inst || 8'b00000000};
  adr <= adr ;
  wr_bytes <= 3'd1;
end
endtask

task send4bit(
  input [7:0]inst,
  output wr,
  output [31:0]wr_data,
  output [6:0]adr,
  output [2:0]wr_bytes
);
begin
  send({inst || 8'b00000000}, wr,wr_data, adr,wr_bytes);
  wait(~busy) #11500 send({inst || 8'b00000100}, wr,wr_data, adr,wr_bytes);
  wait(~busy) #11500 send({inst || 8'b00000000}, wr,wr_data, adr,wr_bytes);
end
endtask

//16進->バイナリーコードデシマル変換　整数二桁
function [11:0] hex2bcd;
  input [7:0] hex_data;
  reg   [7:0] amount_data;
  begin
    if (hex_data>=8'hc8)
      begin
        hex2bcd[11:8] = 4'h2;
        amount_data = hex_data -8'hc8;
      end
    else if (hex_data>=8'h64)
      begin
        hex2bcd[11:8] = 4'h1;
        amount_data = hex_data -8'h64;
      end
    else
      begin
        hex2bcd[11:8] = 4'h0;
        amount_data = hex_data;
      end
    //
    if (amount_data>=8'h5A)
      begin
        hex2bcd[7:4] = 4'h9;
        amount_data = amount_data -8'h5a;
      end
    else if (amount_data>=8'h50)
      begin
        hex2bcd[7:4] = 4'h8;
        amount_data = amount_data -8'h50;
      end
    else if (amount_data>=8'h46)
      begin
        hex2bcd[7:4] = 4'h7;
        amount_data = amount_data -8'h46;
      end
    else if (amount_data>=8'h3c)
      begin
        hex2bcd[7:4] = 4'h6;
        amount_data = amount_data -8'h3c;
      end
    else if (amount_data>=8'h32)
      begin
        hex2bcd[7:4] = 4'h5;
        amount_data = amount_data -8'h32;
      end
    else if (amount_data>=8'h28)
      begin
        hex2bcd[7:4] = 4'h4;
        amount_data = amount_data -8'h28;
      end
    else if (amount_data>=8'h1e)
      begin
        hex2bcd[7:4] = 4'h3;
        amount_data = amount_data -8'h1e;
      end
    else if (amount_data>=8'h14)
      begin
        hex2bcd[7:4] = 4'h2;
        amount_data = amount_data -8'h14;
      end
    else if (amount_data>=8'ha)
      begin
        hex2bcd[7:4] = 4'h1;
        amount_data = amount_data -8'ha;
      end
    else
      begin
        hex2bcd[7:4] = 4'h0;
        amount_data = amount_data ;
      end
     //
     hex2bcd[3:0]=amount_data[3:0];
  end
endfunction

always @ (posedge clk or negedge rstb )
  if (rstb==1'b0) begin
    main_cnt <= 26'b0;
  end
  //else if (main_cnt == 26'd7999999) begin
  else if (main_cnt == 26'd49999999) begin
  //else if (main_cnt ==26'd5000000) begin
    main_cnt <= 26'b0;
    end
  else begin
    main_cnt <= main_cnt + 26'd1;
  end

assign led_0 = main_cnt[25];

// for PCF8574T controll

reg [11:0] amountbcd;
reg [7:0] senddec;

always @ (posedge clk or negedge rstb )
  // Internal Reset
  if (rstb==1'b0) begin
    wr <= 1'b0;
    wr_data <=32'h00000000;
    wr_bytes <= 4'd0;
    adr <= 7'h27;
    init_state <= 4'b0;
    #2500000 init_finished <= 0;
    end
  // Initialise
  else if (init_finished == 0 && busy != 1) begin
    case (init_state)
      // Set 8bit mode
      4'd0: begin
        send4bit(8'b00110000, wr, wr_data, adr, wr_bytes);
        if(instruct_count == 4'd3) begin
          wait(~busy) #7500 init_state = init_state + 4'd1;
        end else begin
          wait(~busy) #225000 instruct_count = instruct_count + 4'd1;
        end
      end
      // Set 4bit mode and more
      4'd1: begin
        // Set 4bit mode
        send4bit(8'b00100000, wr, wr_data, adr, wr_bytes);
        // Set 2 lines mode
        send4bit(8'b00100000, wr, wr_data, adr, wr_bytes);
        send4bit(8'b10000000, wr, wr_data, adr, wr_bytes);
        // Set Disp ON, Cursor ON, Blink ON
        send4bit(8'b00000000, wr, wr_data, adr, wr_bytes);
        send4bit(8'b11110000, wr, wr_data, adr, wr_bytes);
        // Disp Clear
        send4bit(8'b00000000, wr, wr_data, adr, wr_bytes);
        send4bit(8'b00010000, wr, wr_data, adr, wr_bytes);
        #100000 wait(busy);
        // Entry Mode
        send4bit(8'b00000000, wr, wr_data, adr, wr_bytes);
        send4bit(8'b01100000, wr, wr_data, adr, wr_bytes);
        // Go to home position
        send4bit(8'b00000000, wr, wr_data, adr, wr_bytes);
        send4bit(8'b00100000, wr, wr_data, adr, wr_bytes);
        init_finished <= 1'b1;
      end
    endcase
  end
  else
    // 人数表示
    if (main_cnt == 26'd001000)
      begin
        amountbcd = hex2bcd(amount);

        send4bit(8'b00000000, wr, wr_data, adr, wr_bytes);
        send4bit(8'b00101000, wr, wr_data, adr, wr_bytes);

        senddec = hex2ascii(amountbcd[11:8]);

        send4bit(((senddec << 4) & 8'hf0) || 8'b00001001, wr, wr_data, adr, wr_bytes);
        send4bit(((senddec & 8'h0f) << 4) || 8'b00001001, wr, wr_data, adr, wr_bytes);

        senddec = hex2ascii(amountbcd[7:4]);

        send4bit(((senddec << 4) & 8'hf0) || 8'b00001001, wr, wr_data, adr, wr_bytes);
        send4bit(((senddec & 8'h0f) << 4) || 8'b00001001, wr, wr_data, adr, wr_bytes);

        senddec = hex2ascii(amountbcd[3:0]);

        send4bit(((senddec << 4) & 8'hf0) || 8'b00001001, wr, wr_data, adr, wr_bytes);
        send4bit(((senddec & 8'h0f) << 4) || 8'b00001001, wr, wr_data, adr, wr_bytes);

      end

// wr,rd byte enable
assign wr_be = (wr_bytes==3'd1)?4'b1000:
               (wr_bytes==3'd2)?4'b1100:
               (wr_bytes==3'd3)?4'b1110:
               (wr_bytes==3'd4)?4'b1111:4'b0000;

endmodule







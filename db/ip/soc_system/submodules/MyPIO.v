module MyPIO (
              input wire        reset,
              input wire        clk,
              input wire [1:0]  address,
              input wire        read,
              output reg [31:0] readdata,
              input wire        write,
              input wire [31:0] writedata,
              output wire [7:0] amount,
              output wire       soundenable
              );

   reg [7:0]  amount_value;
   reg        se_value;

   always @ (posedge clk, posedge reset ) begin
      if (reset) begin
         amount_value <= 8'd0;
      end
      else begin
         if (write) begin
            case (address)
              2'b00: amount_value <= writedata[7:0];
              2'b01: se_value     <= writedata[0];
            endcase
         end
      end
   end

   always @* begin
      readdata [31:0] = 24'd0;
      case (address)
        2'b00: readdata [7:0] <= amount_value;
        2'b01: readdata [0] <= se_value;
      endcase
   end

   assign amount = amount_value;
   assign soundenable = se_value;

endmodule

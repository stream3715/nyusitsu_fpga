module pwm_module #(
 parameter period_cnt = 50000,
 parameter high_cnt = 25000
 )(
 input clk,
 input reset,
 output reg out = 0
 );

reg[15:0]cnt;
initial begin
     cnt = 16'd0;
     out = 0;
end
always@(posedge clk)begin
     if(reset)begin
         out <= 0;
         cnt <= 15'd0;
     end else begin
         cnt <= cnt + 8'd1;
         if(cnt == period_cnt-1)begin
             cnt <= 15'd0;
         end else if(cnt < high_cnt)begin
             out <= 1'b1;
         end else begin
             out <= 0;
         end
     end
 end
 endmodule
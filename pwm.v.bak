module pwm(pout, clk, nreset, en);
parameter pw=1;
parameter DIV_tenkilo=50000;
parameter DIV=1;
	output pout;
	input clk;
	input nreset;
	input en;
	
	reg tenkilo;
	reg [15:0] tenkilodiv;
	reg [7:0] cnt ;
	reg [15:0] div ;
	reg poutreg;
 
   always @(posedge clk)
   begin
		tenkilodiv <= (tenkilodiv == DIV_tenkilo)? 16'b0: tenkilodiv + 16'b1;
		if(tenkilodiv == 0) begin
			tenkilo <= ~tenkilo;
		end
	end
	
	always @(posedge tenkilo or negedge nreset)
	begin
		if(!nreset) begin
			poutreg <= 0 ;
			cnt <= 0 ;
			div <= 0 ;
		end
		else begin
			div <= (div == DIV)? 16'b0 : div + 16'b1 ;
			cnt <= cnt + (div == 0) ;
			if(en) begin
				poutreg <= (pw >= cnt);
			end
		end
	end
	
	assign pout = poutreg;
endmodule
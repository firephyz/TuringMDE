module timer(max, start, done, clk);

	input clk;
	input [31:0] max;
	input start;
	output done;
	
	reg [31:0] count;
	reg done_reg;
	
	assign done = done_reg;
	
	always@(posedge clk) begin
		if(start == 0 || count >= max - 1) begin
			count <= 0;
		end
		else begin
			count <= count + 32'b1;
		end
	end
	
	always@(*) begin
		if(count == max - 1) begin
			done_reg <= 1;
		end
		else begin
			done_reg <= 0;
		end
	end
	
endmodule

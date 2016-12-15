module seven_seg(in0, in1, in2, in3, a, b, c, d, e, f, g);
	
	input in0, in1, in2, in3;
	output a, b, c, d, e, f, g;
	
	assign a = !((in2 & in1) | (!in3 & in1) | (in3 & !in0) | (!in3 & in2 & in0) | (in3 & !in2 & !in1) | (!in2 & !in1 & !in0));
	assign b = !((!in3 & !in2) | (!in3 & in1 & in0) | (!in3 & !in1 & !in0) | (in3 & !in1 & in0) | (!in2 & !in1) | (!in2 & in1 & !in0));
	assign c = !((!in3 & !in1) | (!in3 & !in2 & in1 & in0) | (!in3 & in2) | (in3 & !in2) | (!in1 & in0));
	assign d = !((!in3 & !in2 & !in1 & !in0) | (!in3 & !in2 & in1) | (in2 & !in1 & in0) | (in3 & !in1 & !in0) | (in3 & !in2 & in1 & in0) | (in2 & in1 & !in0));
	assign e = !((in1 & !in0) | (in3 & in2) | (!in2 & !in1 & !in0) | (in3 & in1));
	assign f = !((in3 & !in2) | (in3 & in1) | (in2 & !in0) | (!in3 & !in1 & !in0) | (!in3 & in2 & !in1));
	assign g = !((!in3 & !in2 & in1) | (in1 & !in0) | (in3 & !in2) | (in3 & in2 & in0) | (!in3 & in2 & !in1));
	
endmodule

module keyboard(keycode, is_pressed, PS2_DATA, PS2_CLOCK, clk);

	parameter READY = 2'b00,
				 GRAB  = 2'b01,
				 PARITY = 2'b10,
				 DONE  = 2'b11;
	
	input clk;
	input PS2_DATA, PS2_CLOCK;
	output reg [7:0] keycode;
	output reg is_pressed;
	
	reg [1:0] prev_state;
	reg [1:0] state;
	reg [2:0] index;
	reg [7:0] data;
	
	initial begin
		state <= READY;
		index <= 0;
		keycode <= 0;
		data <= 0;
		is_pressed <= 0;
	end
	
	always@(posedge clk) begin
		prev_state <= state;
		
		if(state == READY && prev_state == DONE) is_pressed <= 1;
		else is_pressed <= 0;
	end
				 
	always@(negedge PS2_CLOCK) begin
		case (state)
			READY: begin
				state <= GRAB;
			end
			GRAB: begin
				if(index == 7) begin
					data <= (data >> 1) | (PS2_DATA << 7);
					index <= 0;
					state <= PARITY;
				end
				else begin
					data <= (data >> 1) | (PS2_DATA << 7);
					index <= index + 3'b1;
				end
			end
			PARITY: begin
				state <= DONE;
			end
			DONE: begin
				state <= READY;
				keycode <= data;
				data <= 0;
				index <= 0;
			end
		endcase
	end
	
endmodule

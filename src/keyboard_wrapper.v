module keyboard_wrapper(keycode, breakcode, is_valid, PS2_DATA, PS2_CLOCK, clk);

	input clk;
	input PS2_DATA;
	input PS2_CLOCK;

	wire [7:0] keycode_wire;
	output reg is_valid;
	output reg [7:0] keycode;
	output reg [15:0] breakcode;
	
	reg [1:0] state;
	reg [1:0] next_state;
	
	reg timer_start;
	wire timer_done;
	wire is_pressed; // Goes high the moment we get the first breakcode. Pulse
	
	parameter 	GET_MAKE 		= 2'h0,
					GET_BREAK		= 2'h1,
					GET_MAKE_END 	= 2'h2;
	
	keyboard keyboard(keycode_wire, is_pressed, PS2_DATA, PS2_CLOCK, clk);
	timer time_keeper(4000, timer_start, timer_done, clk);
	
	initial begin
		state <= GET_MAKE;
		timer_start <= 0;
	end
	
	always@(posedge clk) begin
		state <= next_state;
	end
	
	always@(*) begin
		case(state)
			GET_MAKE: begin
				if(is_pressed) begin
					next_state = GET_BREAK;
				end
				else begin
					next_state = GET_MAKE;
				end
			end
			GET_BREAK: begin
				if(is_pressed) begin
					next_state = GET_MAKE_END;
				end
				else begin
					next_state = GET_BREAK;
				end
			end
			GET_MAKE_END: begin
				if(is_valid) begin
					if(is_pressed) begin
						next_state = GET_MAKE;
					end
					else begin
						next_state = GET_MAKE_END;
					end
				end
				else begin
					if(timer_done) begin
						next_state = GET_MAKE;
					end
					else begin
						next_state = GET_MAKE_END;
					end
				end
			end
			default: next_state = GET_MAKE;
		endcase
	end
	
	always@(posedge clk) begin
		case(state)
			GET_MAKE: begin
				timer_start <= 0;
				if(is_pressed) keycode <= keycode_wire;
			end
			GET_BREAK: begin
				if(is_pressed) begin
					if(keycode_wire == 8'hF0) begin
						breakcode[15:8] <= keycode_wire;
						is_valid <= 1; 
					end
					else begin
						breakcode <= 0;
						keycode <= 0;
						is_valid <= 0;
					end
				end
			end
			GET_MAKE_END: begin
				is_valid <= 0;
				if(is_valid) begin
					if(is_pressed) breakcode[7:0] <= keycode_wire;
				end
				else
					timer_start <= 1;
				end
		endcase
	end
	
endmodule

module keyboard_wrapper(keycode, breakcode, is_pressed_yeah, PS2_DATA, PS2_CLOCK, clk, rst, state, keycode_wire, seg0, seg1);

	input clk, rst;
	input PS2_DATA;
	input PS2_CLOCK;

	output wire [7:0] keycode_wire;
	output reg [7:0] keycode;
	output reg [15:0] breakcode;
	
	output reg [1:0] state;
	reg [1:0] next_state;
	
	output wire is_pressed_yeah;
	wire is_pressed; // Goes high the moment we get the first breakcode. Pulse
	
	parameter 	GET_MAKE 		= 2'h0,
					GET_BREAK		= 2'h1,
					GET_MAKE_END 	= 2'h2,
					INIT				= 2'h3;
	
	keyboard keyboard(keycode_wire, is_pressed, PS2_DATA, PS2_CLOCK, clk, rst);
	
	assign is_pressed_yeah = (state == GET_MAKE_END && is_pressed) ? 1 : 0;
	
	output [6:0] seg0, seg1;
	seven_seg seven_seg0(keycode[3:0], seg0);
	seven_seg seven_seg1(keycode[7:4], seg1);
	
	initial begin
		state <= GET_MAKE;
	end
	
	always@(posedge clk) begin
		state <= next_state;
	end
	
	always@(*) begin
		case(state)
			INIT: begin
				if(is_pressed) begin
					next_state = GET_MAKE;
				end
				else begin
					next_state = INIT;
				end
			end
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
				if(is_pressed) begin
					next_state = GET_MAKE;
				end
				else begin
					next_state = GET_MAKE_END;
				end
			end
			default: next_state = GET_MAKE;
		endcase
	end
	
	always@(posedge clk) begin
		case(state)
			GET_MAKE: begin
				if(is_pressed) keycode <= keycode_wire;
			end
			GET_BREAK: begin
				if(is_pressed) begin
					if(keycode_wire == 8'hF0) begin
						breakcode[15:8] <= keycode_wire;
					end
					else begin
						breakcode <= 0;
						keycode <= 0;
					end
				end
			end
			GET_MAKE_END: begin
				if(is_pressed) breakcode[7:0] <= keycode_wire;
			end
		endcase
	end
	
endmodule

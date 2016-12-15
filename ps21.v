module keyboard(keycode, is_pressed, PS2_DATA, PS2_CLOCK, clk, rst);

	parameter READY = 2'b00,
				 GRAB  = 2'b01,
				 PARITY = 2'b10,
				 DONE  = 2'b11;
	
	input clk, rst;
	input PS2_DATA, PS2_CLOCK;
	output reg [7:0] keycode;
	output reg is_pressed;
	reg is_pressed_prev;
	
	reg [1:0] state;
	reg [2:0] index;
	reg [7:0] data;
	
	reg did_send_pulse;
	reg counter_start;
	reg [15:0] counter;
	reg ps2_clk_prev;
	wire rst_wire;
	
	assign rst_wire = rst & !(!is_pressed && is_pressed_prev);
	
	always@(posedge clk or negedge rst) begin
		if(rst == 0) begin
			counter <= 0;
			counter_start <= 0;
			is_pressed <= 0;
			is_pressed_prev <= 0;
		end
		else begin
			is_pressed_prev <= is_pressed;
			ps2_clk_prev <= PS2_CLOCK;
			
			if(counter == 16'd50000) is_pressed <= 1;
			else is_pressed <= 0;
			
			// Executes the first negedge of the ps2 clock
			if(!counter_start && !PS2_CLOCK && ps2_clk_prev) begin
				counter_start <= 1;
				is_pressed <= 0;
			end
			else if(counter_start) begin
				counter <= counter + 16'b1;
			
				if(counter == 16'd50000) begin
					counter <= 0;
					counter_start <= 0;
				end
			end
		end
	end
				 
	always@(negedge PS2_CLOCK or negedge rst_wire) begin
		if(rst_wire == 0) begin
			state <= READY;
			index <= 0;
			keycode <= 0;
			data <= 0;
		end
		else begin
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
	end
	
endmodule

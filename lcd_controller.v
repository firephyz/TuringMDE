module lcd_controller(rs_in, rw_in, data_in, execute, is_ready, en, rs, rw, io, rst, clk);

	// Clock and reset
	input rst;
	input clk;

	// Data to send to the lcd
	input rs_in;
	input rw_in;
	input [7:0] data_in;
	input execute;
	output wire is_ready;
	
	// Pins to the actual lcd module
	output en;
	output rs;
	output rw;
	inout [7:0] io;
	
	// Timer related stuff
	reg timer_start;
	wire timer_done;
	reg [31:0] timer_target;
	timer time_keeper(timer_target, timer_start, timer_done, clk);
	
	// FSM data
	reg has_init;
	reg [3:0] state;
	reg [3:0] next_state;
	
	reg rs_reg;
	reg rw_reg;
	reg [7:0] io_reg;
	reg en_reg;
	reg busy;
	
	assign rs = rs_reg;
	assign rw = rw_reg;
	assign en = en_reg;
	assign io = (state == BUSY_DISABLE) ? 8'bZ : io_reg;
	assign is_ready = (state == WTI) ? !execute : 0;
	
	parameter INSTRUCTION = 1'b0,
				 DATA 		 = 1'b1;
				 
	parameter READ 	    = 1'b1,
				 WRITE		 = 1'b0;
	
	parameter WTI 				= 4'h00,
				 BUSY_SETUP 	= 4'h01,
				 BUSY_ENABLE 	= 4'h02,
				 BUSY_DISABLE 	= 4'h03,
				 BUSY_RELEASE 	= 4'h04,
				 DATA_SETUP 	= 4'h05,
				 DATA_ENABLE 	= 4'h06,
				 DATA_DISABLE 	= 4'h07,
				 DATA_RELEASE 	= 4'h08,
				 SPIN 			= 4'h09;
	
	// Update the current state
	always@(posedge clk or negedge rst) begin
		if(rst == 0) begin
			state <= BUSY_SETUP; // Start here so we release the module when it's free
		end
		else begin
			state <= next_state;
		end
	end
	
	// Manage the setting of regs based on state
	always@(posedge clk or negedge rst) begin
		if(rst == 0) begin
			rs_reg <= INSTRUCTION;
			rw_reg <= READ;
			io_reg <= 0;
			en_reg <= 0;
			timer_start <= 0;
			timer_target <= 8'hFF;
			busy <= 0;
			has_init <= 0;
		end
		else begin
			case(state)
				WTI: begin
					rs_reg <= INSTRUCTION;
					rw_reg <= READ;
					io_reg <= 0;
					en_reg <= 0;
					timer_start <= 0;
					has_init <= 1;
				end
				BUSY_SETUP: begin
					rs_reg <= INSTRUCTION;
					rw_reg <= READ;
					busy <= 0;
					
					timer_target <= 8;
					timer_start <= 1;
				end
				BUSY_ENABLE: begin
					en_reg <= 1;
					
					timer_target <= 25;
				end
				BUSY_DISABLE: begin
					en_reg <= 0;
					busy <= io[7];
					
					timer_target <= 8;
				end
				BUSY_RELEASE: begin
					rs_reg <= INSTRUCTION;
					rw_reg <= READ;
					
					timer_target <= 35;
				end
				DATA_SETUP: begin
					rs_reg <= rs_in;
					rw_reg <= rw_in;
					busy <= 0;
					
					timer_target <= 8;
				end
				DATA_ENABLE: begin
					en_reg <= 1;
					io_reg <= data_in;
					
					timer_target <= 25;
				end
				DATA_DISABLE: begin
					en_reg <= 0;
					
					timer_target <= 8;
				end
				DATA_RELEASE: begin
					rs_reg <= INSTRUCTION;
					rw_reg <= READ;
					io_reg <= 0;
					
					timer_target <= 35;
				end
				default:;
			endcase
		end
	end
	
	
	// Compute the next state
	always@(*) begin
		case(state)
			WTI: begin
				if(execute == 0) begin
					next_state = WTI;
				end
				else begin
					next_state = BUSY_SETUP;
				end
			end
			BUSY_SETUP: begin
				if(timer_done) begin
					next_state = BUSY_ENABLE;
				end
				else begin
					next_state = BUSY_SETUP;
				end
			end
			BUSY_ENABLE:begin
				if(timer_done) begin
					next_state = BUSY_DISABLE;
				end
				else begin
					next_state = BUSY_ENABLE;
				end
			end
			BUSY_DISABLE:begin
				if(timer_done) begin
					next_state = BUSY_RELEASE;
				end
				else begin
					next_state = BUSY_DISABLE;
				end
			end
			BUSY_RELEASE:begin
				if(timer_done) begin
					if(busy) begin
						next_state = BUSY_SETUP;
					end
					else begin
						if(has_init == 0) begin
							next_state = WTI;
						end
						else begin
							next_state = DATA_SETUP;
						end
					end
				end
				else begin
					next_state = BUSY_RELEASE;
				end
			end
			DATA_SETUP: begin
				if(timer_done) begin
					next_state = DATA_ENABLE;
				end
				else begin
					next_state = DATA_SETUP;
				end
			end
			DATA_ENABLE:begin
				if(timer_done) begin
					next_state = DATA_DISABLE;
				end
				else begin
					next_state = DATA_ENABLE;
				end
			end
			DATA_DISABLE: begin
				if(timer_done) begin
					next_state = DATA_RELEASE;
				end
				else begin
					next_state = DATA_DISABLE;
				end
			end
			DATA_RELEASE: begin
				if(timer_done) begin
					next_state = SPIN;
				end
				else begin
					next_state = DATA_RELEASE;
				end
			end
			SPIN: begin
				if(execute == 1) begin
					next_state = SPIN;
				end
				else begin
					next_state = WTI;
				end
			end
			default: begin
				next_state = BUSY_ENABLE;
			end
		endcase
	end
	
endmodule

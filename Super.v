module Super(seg_0, seg_1, seg_2, seg_3, key_valid, lcd_data, lcd_enable, lcd_rw, lcd_rs, key_clock, key_data, clk, rst, timer_start, timer_done, is_pressed, next_state, print_start_turing_wire, timer_start, keycode, string_num, print_done);

	input clk, rst;

	inout [7:0] lcd_data;
	output lcd_enable;
	output lcd_rw;
	output lcd_rs;
	
	input key_clock;
	input key_data;
	output wire is_pressed;
	output wire [7:0] keycode;
	wire [7:0] break_code;
	
	reg [31:0] timer_max;
	output reg timer_start;
	output wire timer_done;
	reg [1:0] counter;
	
	output [6:0] seg_0, seg_1;
	output [6:0] seg_2, seg_3;
	output key_valid;
	assign key_valid = is_pressed;
	
	// Interface with the turing machine module
	reg execute;
	wire execute_is_done;
	reg print_start;	// Reg set by this module to toggle when to print
	wire print_start_wire; // Wire that joins print_start and print_start_turing_wire and moves it to the lcd module
	output wire print_start_turing_wire; // Wire set by turing module to toggle when to print
	output wire print_done;
	
	reg mem_access; // Set by super to access memory
	wire mem_access_wire; // Set by lcd interface to access memory
	wire mem_access_lcd_wire;
	wire [1:0] mem_io_wire;
	reg [1:0] mem_io;
	reg mem_rw; // 1 is read, 0 is write
	wire mem_rw_wire;
	wire mem_rw_lcd_wire;
	reg [9:0] mem_addr;
	wire [9:0] mem_addr_wire;
	wire [9:0] mem_addr_lcd_wire;	
	wire [9:0] head_loc;
	reg head_dir;
	reg move_head;
	
	reg state_access;
	reg [9:0] state_addr;
	reg [10:0] state_in;
	
	output reg [4:0] string_num;
	
	// Internal state stuff
	reg [4:0] state;
	output reg [4:0] next_state;
	reg [4:0] prev_state;
	reg [9:0] t_state_addr;
	reg [10:0] t_state_contents;
	
	reg has_visited; // Used in LCD_OFF to record if we have visiting LCD_OFF with this prev_state 
						  // already. If so, that means we must go to the next get cycle instead of going to
						  // LCD_ON_TIMER_START
	
	// Passes mem_io data into the turing machine for some states.
	// For others, it relays mem_io from the turing machine to the Super and lcd modules
	assign mem_io_wire = 		(state == PRINT_TAPE || state == TURING_START) ? 2'hZ : mem_io;
	assign mem_access_wire = 	(state == PRINT_TAPE || state == TURING_START) ? mem_access_lcd_wire : mem_access;
	assign mem_rw_wire = 		(state == PRINT_TAPE || state == TURING_START) ? mem_rw_lcd_wire : mem_rw;
	assign mem_addr_wire = 		(state == PRINT_TAPE || state == TURING_START) ? mem_addr_lcd_wire : mem_addr;
	
	assign print_start_wire = 	(state == TURING_START) ? print_start_turing_wire : print_start;
	
	turing_machine turing_machine(execute, execute_is_done, print_start_turing_wire, print_done, mem_access_wire, mem_io_wire, mem_rw_wire, mem_addr_wire, head_loc, head_dir, move_head, state_access, state_addr, state_in, clk, rst);
	keyboard_wrapper keyboard_wrapper(keycode, break_code, is_pressed, key_data, key_clock, clk, rst);
	timer timer(timer_max, timer_start, timer_done, clk);
	lcd_interface lcd_interface(print_start_wire, print_done, string_num, keycode, head_loc, mem_access_lcd_wire, mem_io_wire, mem_rw_lcd_wire, mem_addr_lcd_wire, lcd_enable, lcd_rs, lcd_rw, lcd_data, rst, clk);
	
	seven_seg seven_seg_0({6'h0, t_state_addr[1:0]}, seg_0[0], seg_0[1], seg_0[2], seg_0[3], seg_0[4], seg_0[5], seg_0[6]);
	seven_seg seven_seg_1(8'h0, seg_1[0], seg_1[1], seg_1[2], seg_1[3], seg_1[4], seg_1[5], seg_1[6]);
	
	//seven_seg seven_seg_0(state[3:0], seg_0[0], seg_0[1], seg_0[2], seg_0[3], seg_0[4], seg_0[5], seg_0[6]);
	//seven_seg seven_seg_1({3'h0, state[4]}, seg_1[0], seg_1[1], seg_1[2], seg_1[3], seg_1[4], seg_1[5], seg_1[6]);
	
	seven_seg seven_seg_2(t_state_addr[5:2], seg_2[0], seg_2[1], seg_2[2], seg_2[3], seg_2[4], seg_2[5], seg_2[6]);
	seven_seg seven_seg_3(t_state_addr[9:6], seg_3[0], seg_3[1], seg_3[2], seg_3[3], seg_3[4], seg_3[5], seg_3[6]);
	
	parameter CHOICE 			= 5'h0,
				 GET_STATE 		= 5'h1,
				 GET_STATE_0 	= 5'h2,
				 GET_STATE_1 	= 5'h3,
				 GET_READ 		= 5'h4,
				 GET_READ_0 	= 5'h5,
				 GET_WRITE 		= 5'h6,
				 GET_WRITE_0 	= 5'h7,
				 GET_DIR 		= 5'h8,
				 GET_DIR_0 		= 5'h9,
				 GET_NS 			= 5'hA,
				 GET_NS_0 		= 5'hB,
				 GET_NS_1 		= 5'hC,
				 WRITE_STATE 	= 5'hD,
				 PRINT_TAPE 	= 5'hE,
				 GET_KEY 		= 5'hF,
				 DELETE_TAPE 	= 5'h10,
				 WRITE_TAPE 	= 5'h11,
				 TURING_START  = 5'h12,
				 LCD_ON_TIMER_START	= 5'h13,
				 TURING_WAIT	= 5'h14,
				 LCD_OFF			= 5'h15;
			
	parameter KEY_ZERO 	= 8'h45,
				 KEY_ONE	 	= 8'h16,
				 KEY_TWO		= 8'h1E,
				 KEY_THREE	= 8'h26,
				 KEY_FOUR	= 8'h25,
				 KEY_FIVE	= 8'h2E,
				 KEY_SIX		= 8'h36,
				 KEY_SEVEN	= 8'h3D,
				 KEY_EIGHT	= 8'h3E,
				 KEY_NINE	= 8'h46,
				 KEY_A		= 8'h1C,
				 KEY_B		= 8'h32,
				 KEY_C		= 8'h21,
				 KEY_D		= 8'h23,
				 KEY_E		= 8'h24,
				 KEY_F		= 8'h2B,
				 KEY_HASH	= 8'h26,
				 KEY_SPACE	= 8'h29,
				 KEY_LEFT	= 8'h1C,
				 KEY_RIGHT	= 8'h23,
				 KEY_ENTER	= 8'h5A,
				 KEY_BACK	= 8'h66;
				 
	parameter SYM_BLANK = 	2'b00,
				 SYM_ZERO = 	2'b01,
				 SYM_ONE = 		2'b10,
				 SYM_HASH = 	2'b11;
				 
	parameter LEFT = 	1'b0,
				 RIGHT = 1'b1;
	
	// String nums for lcd module
	parameter 	GET_STATE_STRING 		= 5'h0,
					GET_STATE_0_STRING 	= 5'h1,
					GET_STATE_1_STRING 	= 5'h2,
					GET_READ_STRING		= 5'h3,
					GET_READ_0_STRING 	= 5'h4,
					GET_WRITE_STRING		= 5'h5,
					GET_WRITE_0_STRING	= 5'h6,
					GET_DIR_STRING			= 5'h7,
					GET_DIR_0_STRING 		= 5'h8,
					GET_NS_STRING			= 5'h9,
					GET_NS_0_STRING		= 5'hA,
					GET_NS_1_STRING		= 5'hB,
					PRESENT_CHOICE			= 5'hC,
					DISPLAY_TAPE			= 5'hD;
				 
	parameter HALF_SECOND 	= 32'd10000000,
				 TURING_DELAY 	= 32'd25000000;
				 
	// Update the state
	always@(posedge clk or negedge rst) begin
		if(rst == 0) begin
			state <= CHOICE;
			prev_state <= CHOICE;
			counter <= 0;
		end
		else begin
			if(state == LCD_ON_TIMER_START || state == TURING_WAIT) begin
				if(timer_done) begin
					state <= next_state;
				end
				
				if(state == TURING_WAIT) begin
					prev_state <= state;
				end
			end
			else if(state == GET_STATE ||
					  state == GET_READ  ||
					  state == GET_WRITE ||
					  state == GET_DIR   ||
					  state == GET_NS		||
					  state == PRINT_TAPE) begin
				if(print_done) begin
					state <= next_state;
					prev_state <= state;
				end
			end
			else if (state == WRITE_TAPE || state == DELETE_TAPE) begin
				// Makes us stay in WRITE_TAPE or DELETE_TAPE for one extra tick
				// to allow for mem io with the turing machine
				if(counter == 1) begin
					state <= next_state;
					prev_state <= state;
					counter <= 0;
				end
				else begin
					counter <= 1;
				end
			end
			else if (state == LCD_OFF) begin
				state <= next_state;
			end
			else begin
				prev_state <= state;
				state <= next_state;
			end
		end
	end
	
	// Set control wires
	always@(posedge clk or negedge rst) begin
		if(rst == 0) begin
			execute <= 0;
			
			mem_access <= 0;
			mem_io <= 0;
			mem_rw <= 0;
			mem_addr <= 0;
			head_dir <= 0;
			move_head <= 0;
			
			state_access <= 0;
			state_addr <= 0;
			state_in <= 0;
			
			string_num <= 0;
			timer_start <= 0;
			timer_max <= 0;
			print_start <= 0;
		end
		else begin
			case(state)
				CHOICE: begin
					print_start <= 1;
					string_num <= PRESENT_CHOICE;
				end
				GET_STATE: begin
					print_start <= 1;
					string_num <= GET_STATE_STRING;
					timer_start <= 0;
					state_access <= 0;
				end
				GET_READ: begin
					print_start <= 1;
					string_num <= GET_READ_STRING;
					timer_start <= 0;
				end
				GET_WRITE: begin
					print_start <= 1;
					string_num <= GET_WRITE_STRING;
					timer_start <= 0;
				end
				GET_DIR: begin
					print_start <= 1;
					string_num <= GET_DIR_STRING;
					timer_start <= 0;
				end
				GET_NS: begin
					print_start <= 1;
					string_num <= GET_NS_STRING;
					timer_start <= 0;
				end
				WRITE_STATE: begin
					state_in <= t_state_contents;
					state_addr <= t_state_addr;
					state_access <= 1;
				end
				PRINT_TAPE: begin
					print_start <= 1;
					string_num <= DISPLAY_TAPE;
					
					mem_access <= 0;
					move_head <= 0;
				end
				GET_KEY: begin
					if(is_pressed) begin
						case(keycode)
							KEY_A: begin
								move_head <= 1;
								head_dir <= RIGHT;
							end
							KEY_D: begin
								move_head <= 1;
								head_dir <= LEFT;
							end
						endcase
					end
				end
				DELETE_TAPE: begin
					mem_addr <= head_loc;
					mem_access <= 1;
					mem_rw <= 0;
					mem_io <= SYM_BLANK;
					head_dir <= RIGHT;
					move_head <= 1;
				end
				WRITE_TAPE: begin
					mem_addr <= head_loc;
					mem_access <= 1;
					mem_rw <= 0;
					head_dir <= LEFT;
					case(keycode)
						KEY_SPACE:  mem_io <= SYM_BLANK;
						KEY_ZERO:  	mem_io <= SYM_ZERO;
						KEY_ONE:    mem_io <= SYM_ONE;
						KEY_HASH:	mem_io <= SYM_HASH;
					endcase
				end
				TURING_START: begin
					string_num <= DISPLAY_TAPE;
					execute <= 1;
					timer_start <= 0;
				end
				TURING_WAIT: begin
					timer_start <= 1;
					timer_max <= TURING_DELAY;
				end
				LCD_OFF: begin
					print_start <= 0;
					
					case(prev_state)
						GET_STATE_0: begin
							if(is_pressed) begin
								case(keycode)
									KEY_ZERO: 	t_state_addr[9:6] <= 4'h0;
									KEY_ONE: 	t_state_addr[9:6] <= 4'h1;
									KEY_TWO: 	t_state_addr[9:6] <= 4'h2;
									KEY_THREE: 	t_state_addr[9:6] <= 4'h3;
									KEY_FOUR: 	t_state_addr[9:6] <= 4'h4;
									KEY_FIVE: 	t_state_addr[9:6] <= 4'h5;
									KEY_SIX: 	t_state_addr[9:6] <= 4'h6;
									KEY_SEVEN: 	t_state_addr[9:6] <= 4'h7;
									KEY_EIGHT: 	t_state_addr[9:6] <= 4'h8;
									KEY_NINE:	t_state_addr[9:6] <= 4'h9;
									KEY_A: 		t_state_addr[9:6] <= 4'hA;
									KEY_B: 		t_state_addr[9:6] <= 4'hB;
									KEY_C: 		t_state_addr[9:6] <= 4'hC;
									KEY_D: 		t_state_addr[9:6] <= 4'hD;
									KEY_E: 		t_state_addr[9:6] <= 4'hE;
									KEY_F: 		t_state_addr[9:6] <= 4'hF;
								endcase
							end
						end
						GET_STATE_1: begin
							if(is_pressed) begin
								case(keycode)
									KEY_ZERO: 	t_state_addr[5:2] <= 4'h0;
									KEY_ONE: 	t_state_addr[5:2] <= 4'h1;
									KEY_TWO: 	t_state_addr[5:2] <= 4'h2;
									KEY_THREE: 	t_state_addr[5:2] <= 4'h3;
									KEY_FOUR: 	t_state_addr[5:2] <= 4'h4;
									KEY_FIVE: 	t_state_addr[5:2] <= 4'h5;
									KEY_SIX: 	t_state_addr[5:2] <= 4'h6;
									KEY_SEVEN: 	t_state_addr[5:2] <= 4'h7;
									KEY_EIGHT: 	t_state_addr[5:2] <= 4'h8;
									KEY_NINE: 	t_state_addr[5:2] <= 4'h9;
									KEY_A: 		t_state_addr[5:2] <= 4'hA;
									KEY_B: 		t_state_addr[5:2] <= 4'hB;
									KEY_C: 		t_state_addr[5:2] <= 4'hC;
									KEY_D: 		t_state_addr[5:2] <= 4'hD;
									KEY_E: 		t_state_addr[5:2] <= 4'hE;
									KEY_F: 		t_state_addr[5:2] <= 4'hF;
								endcase
								
								if(!has_visited) has_visited <= 1;
							end
							else if(has_visited) has_visited <= 0;
						end
						GET_READ_0: begin
							if(is_pressed) begin
								case(keycode)
									KEY_SPACE: 	t_state_addr[1:0] <= SYM_BLANK;
									KEY_ZERO: 	t_state_addr[1:0] <= SYM_ZERO;
									KEY_ONE: 	t_state_addr[1:0] <= SYM_ONE;
									KEY_THREE: 	t_state_addr[1:0] <= SYM_HASH;
								endcase
								
								if(!has_visited) has_visited <= 1;
							end
							else if(has_visited) has_visited <= 0;
						end
						GET_WRITE_0: begin
							if(is_pressed) begin
								case(keycode)
									KEY_SPACE: 	t_state_contents[10:9] <= SYM_BLANK;
									KEY_ZERO: 	t_state_contents[10:9] <= SYM_ZERO;
									KEY_ONE: 	t_state_contents[10:9] <= SYM_ONE;
									KEY_THREE: 	t_state_contents[10:9] <= SYM_HASH;
								endcase
								
								if(!has_visited) has_visited <= 1;
							end
							else if(has_visited) has_visited <= 0;
						end
						GET_DIR_0: begin
							if(is_pressed) begin
								case(keycode)
									KEY_A: t_state_contents[8] <= LEFT;
									KEY_D: t_state_contents[8] <= RIGHT;
								endcase
								
								if(!has_visited) has_visited <= 1;
							end
							else if(has_visited) has_visited <= 0;
						end
						GET_NS_0: begin
							if(is_pressed) begin
								case(keycode)
									KEY_ZERO: 	t_state_contents[7:4] <= 4'h0;
									KEY_ONE: 	t_state_contents[7:4] <= 4'h1;
									KEY_TWO: 	t_state_contents[7:4] <= 4'h2;
									KEY_THREE: 	t_state_contents[7:4] <= 4'h3;
									KEY_FOUR: 	t_state_contents[7:4] <= 4'h4;
									KEY_FIVE: 	t_state_contents[7:4] <= 4'h5;
									KEY_SIX: 	t_state_contents[7:4] <= 4'h6;
									KEY_SEVEN: 	t_state_contents[7:4] <= 4'h7;
									KEY_EIGHT: 	t_state_contents[7:4] <= 4'h8;
									KEY_NINE: 	t_state_contents[7:4] <= 4'h9;
									KEY_A: 		t_state_contents[7:4] <= 4'hA;
									KEY_B: 		t_state_contents[7:4] <= 4'hB;
									KEY_C: 		t_state_contents[7:4] <= 4'hC;
									KEY_D: 		t_state_contents[7:4] <= 4'hD;
									KEY_E: 		t_state_contents[7:4] <= 4'hE;
									KEY_F: 		t_state_contents[7:4] <= 4'hF;
								endcase
							end
						end
						GET_NS_1: begin
							if(is_pressed) begin
								case(keycode)
									KEY_ZERO: 	t_state_contents[3:0] <= 4'h0;
									KEY_ONE: 	t_state_contents[3:0] <= 4'h1;
									KEY_TWO: 	t_state_contents[3:0] <= 4'h2;
									KEY_THREE: 	t_state_contents[3:0] <= 4'h3;
									KEY_FOUR: 	t_state_contents[3:0] <= 4'h4;
									KEY_FIVE: 	t_state_contents[3:0] <= 4'h5;
									KEY_SIX: 	t_state_contents[3:0] <= 4'h6;
									KEY_SEVEN: 	t_state_contents[3:0] <= 4'h7;
									KEY_EIGHT: 	t_state_contents[3:0] <= 4'h8;
									KEY_NINE: 	t_state_contents[3:0] <= 4'h9;
									KEY_A: 		t_state_contents[3:0] <= 4'hA;
									KEY_B: 		t_state_contents[3:0] <= 4'hB;
									KEY_C: 		t_state_contents[3:0] <= 4'hC;
									KEY_D: 		t_state_contents[3:0] <= 4'hD;
									KEY_E: 		t_state_contents[3:0] <= 4'hE;
									KEY_F: 		t_state_contents[3:0] <= 4'hF;
								endcase
								
								if(!has_visited) has_visited <= 1;
							end
							else if(has_visited) has_visited <= 0;
						end
					endcase
				end
				LCD_ON_TIMER_START: begin
					case(prev_state)
						GET_STATE_0: begin
							timer_max <= HALF_SECOND;
							timer_start <= 1;
							print_start <= 1;
							string_num 	<= GET_STATE_0_STRING;
						end
						GET_STATE_1: begin
							timer_max <= HALF_SECOND;
							timer_start <= 1;
							print_start <= 1;
							string_num <= GET_STATE_1_STRING;
						end
						GET_READ_0: begin
							timer_max <= HALF_SECOND;
							timer_start <= 1;
							print_start <= 1;
							string_num <= GET_READ_0_STRING;
						end
						GET_WRITE_0: begin
							timer_max <= HALF_SECOND;
							timer_start <= 1;
							print_start <= 1;
							string_num <= GET_WRITE_0_STRING;
						end
						GET_DIR_0: begin
							timer_max <= HALF_SECOND;
							timer_start <= 1;
							print_start <= 1;
							string_num <= GET_DIR_0_STRING;
						end
						GET_NS_0: begin
							timer_max <= HALF_SECOND;
							timer_start <= 1;
							print_start <= 1;
							string_num <= GET_NS_0_STRING;
						end
						GET_NS_1: begin
							timer_max <= HALF_SECOND;
							timer_start <= 1;
							print_start <= 1;
							string_num <= GET_NS_1_STRING;
						end
					endcase
				end
				default:	begin
					execute <= 0;
			
					mem_access <= 0;
					mem_io <= 0;
					mem_rw <= 0;
					mem_addr <= 0;
					head_dir <= 0;
					move_head <= 0;
					
					state_access <= 0;
					state_addr <= 0;
					state_in <= 0;
					
					string_num <= 0;
					timer_start <= 0;
					timer_max <= 0;
				end
			endcase
		end
	end
	
	// Calculate next state
	always@(*) begin
		case(state)
			CHOICE: next_state = LCD_OFF;
			GET_STATE: next_state = LCD_OFF;
			GET_STATE_0: next_state = LCD_OFF;
			GET_STATE_1: next_state = LCD_OFF;
			GET_READ: 	next_state = LCD_OFF;
			GET_READ_0: next_state = LCD_OFF;
			GET_WRITE:	next_state = LCD_OFF;
			GET_WRITE_0: next_state = LCD_OFF;
			GET_DIR:		next_state = LCD_OFF;
			GET_DIR_0: next_state = LCD_OFF;
			GET_NS:	next_state = LCD_OFF;
			GET_NS_0: next_state = LCD_OFF;
			GET_NS_1: next_state = LCD_OFF;
			WRITE_STATE: next_state = GET_STATE;
			PRINT_TAPE:		next_state = LCD_OFF;
			GET_KEY: begin
				if(is_pressed) begin
					if(keycode == KEY_ENTER)
						next_state = GET_STATE;
					else if (keycode == KEY_A || keycode == KEY_D)
						next_state = PRINT_TAPE;
					else
						next_state = WRITE_TAPE;
				end
				else next_state = GET_KEY;
			end
			DELETE_TAPE: 	next_state = PRINT_TAPE;
			WRITE_TAPE:		next_state = PRINT_TAPE;
			TURING_START: begin
				if(execute_is_done)
					next_state = TURING_WAIT;
				else
					next_state = TURING_START;
			end
			TURING_WAIT: begin
				next_state = TURING_START;
			end
			LCD_ON_TIMER_START: begin
				case(prev_state)
					GET_STATE: 		next_state = GET_STATE_0;
					GET_STATE_0: 	next_state = GET_STATE_1;
					GET_STATE_1:	next_state = LCD_OFF;
					GET_READ: 		next_state = GET_READ_0;
					GET_READ_0: 	next_state = LCD_OFF;
					GET_WRITE:		next_state = GET_WRITE_0;
					GET_WRITE_0:	next_state = LCD_OFF;
					GET_DIR:			next_state = GET_DIR_0;
					GET_DIR_0:		next_state = LCD_OFF;
					GET_NS:			next_state = GET_NS_0;
					GET_NS_0:		next_state = GET_NS_1;
					GET_NS_1:		next_state = LCD_OFF;
					default: 		next_state = CHOICE;
				endcase
			end
			LCD_OFF: begin
				case(prev_state)
					CHOICE: begin
						if(is_pressed) begin
							if(keycode == KEY_ZERO)
								next_state = PRINT_TAPE;
							else if(keycode == KEY_ONE)
								next_state = GET_STATE;
							else
								next_state = CHOICE;
						end
						else
							next_state = LCD_OFF;
					end
					GET_STATE: begin
						next_state = GET_STATE_0;
					end
					GET_STATE_0: begin
						if(is_pressed) begin
							if(keycode == KEY_ENTER)
								next_state = TURING_START;	
							// Make sure this movement back to CHOICE state actually
							// works and the lcd prints the prompt
							else if(keycode == KEY_BACK)
								next_state = CHOICE;
							else
								next_state = LCD_ON_TIMER_START;
						end
						else next_state = LCD_OFF;
					end
					GET_STATE_1: begin
						if(!has_visited) begin
							if(is_pressed)
								next_state = LCD_ON_TIMER_START;
							else
								next_state = LCD_OFF;
						end
						else begin
							next_state = GET_READ;
						end
					end
					GET_READ: next_state = GET_READ_0;
					GET_READ_0: begin
						if(!has_visited) begin
							if(is_pressed)
								next_state = LCD_ON_TIMER_START;
							else
								next_state = LCD_OFF;
						end
						else begin
							next_state = GET_WRITE;
						end
					end
					GET_WRITE: next_state = GET_WRITE_0;
					GET_WRITE_0: begin
						if(!has_visited) begin
							if(is_pressed)
								next_state = LCD_ON_TIMER_START;
							else
								next_state = LCD_OFF;
						end
						else begin
							next_state = GET_DIR;
						end
					end
					GET_DIR: next_state = GET_DIR_0;
					GET_DIR_0: begin
						if(!has_visited) begin
							if(is_pressed)
								next_state = LCD_ON_TIMER_START;
							else
								next_state = LCD_OFF;
						end
						else begin
							next_state = GET_NS;
						end
					end
					GET_NS: next_state = GET_NS_0;
					GET_NS_0: begin
						if(is_pressed)
							next_state = LCD_ON_TIMER_START;
						else
							next_state = LCD_OFF;
					end
					GET_NS_1: begin
						if(!has_visited) begin
							if(is_pressed)
								next_state = LCD_ON_TIMER_START;
							else
								next_state = LCD_OFF;
						end
						else begin
							next_state = WRITE_STATE;
						end
					end
					PRINT_TAPE: next_state = GET_KEY;
					default: next_state = CHOICE;
				endcase
			end
			default: 		next_state = CHOICE;
		endcase
	end

endmodule

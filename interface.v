module lcd_interface(print_start, print_done, string_num, keycode, head_loc, mem_access, mem_in, mem_rw, mem_addr, en, rs, rw, io, rst, clk, state);

	input clk;
	input rst;

	// LCD connections
	output en;
	output rs, rw;
	inout [7:0] io;
	
	// Interface wires with turing machine and super module
	input print_start;
	output reg print_done;
	input [4:0] string_num;
	input [7:0] keycode;
	input [9:0] head_loc;
	output reg mem_access;
	input [1:0] mem_in;
	output reg mem_rw;
	output reg [9:0] mem_addr;
	
	reg [7:0] key_to_print;
	reg [127:0] line1;
	reg [127:0] line2;
	
	output reg [4:0] state;
	reg [3:0] line_index; // Used within the various print states to record where it is along the line
	
	// Instantiate the lcd module
	LCD_Display lcd_module(clk, rst, line2, line1, rs, en, rw, io);
	
	parameter WAIT 	= 5'h00,
				 PRINT	= 5'h01,
				 SPIN		= 5'h02,
				 PRINT_TURING_MEM_SETUP		= 5'h03,
				 PRINT_TURING_MEM_RECORD 	= 5'h04,
				 PRINT_TURING_MEM_SHIFT		= 5'h05,
				 PRINT_PRESENT_CHOICE		= 5'h06,
				 PRINT_GET_STATE				= 5'h07,
				 PRINT_GET_STATE_0			= 5'h08,
				 PRINT_GET_STATE_1			= 5'h09,
				 PRINT_GET_READ				= 5'h0A,
				 PRINT_GET_READ_0				= 5'h0B,
				 PRINT_GET_WRITE				= 5'h0C,
				 PRINT_GET_WRITE_0			= 5'h0D,
				 PRINT_GET_DIR					= 5'h0E,
				 PRINT_GET_DIR_0				= 5'h0F,
				 PRINT_GET_NS					= 5'h10,
				 PRINT_GET_NS_0				= 5'h11,
				 PRINT_GET_NS_1				= 5'h12;
				 
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
	
	parameter LCD_ZERO 	= 8'h30,
				 LCD_ONE	 	= 8'h31,
				 LCD_TWO		= 8'h32,
				 LCD_THREE	= 8'h33,
				 LCD_FOUR	= 8'h34,
				 LCD_FIVE	= 8'h35,
				 LCD_SIX		= 8'h36,
				 LCD_SEVEN	= 8'h37,
				 LCD_EIGHT	= 8'h38,
				 LCD_NINE	= 8'h39,
				 LCD_A		= 8'h41,
				 LCD_B		= 8'h42,
				 LCD_C		= 8'h43,
				 LCD_D		= 8'h44,
				 LCD_E		= 8'h45,
				 LCD_F		= 8'h46,
				 LCD_HASH	= 8'h23,
				 LCD_SPACE	= 8'h20,
				 LCD_EXP		= 8'h5E,
				 LCD_L		= 8'h4C,
				 LCD_R		= 8'h52,
				 LCD_UNDERSCORE = 8'h5F;
	
	parameter SYM_BLANK = 	2'b00,
				 SYM_ZERO = 	2'b01,
				 SYM_ONE = 		2'b10,
				 SYM_HASH = 	2'b11;
				 
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
				 KEY_BACK	= 8'h66,
				 KEY_L 		= 8'h4B,
				 KEY_R 		= 8'h2D;
	
	always@(posedge clk or negedge rst) begin
		if(rst == 0) begin
			state <= WAIT;
			line_index <= 0;
			print_done <= 0;
			line1 <= 0;
			line2 <= 0;
		end
		else begin
			case(state)
				WAIT: begin
					if(print_start) begin
						line_index <= 4'h0;
						state <= PRINT;
					end
				end
				PRINT: begin
					case(string_num)
						DISPLAY_TAPE: state <= PRINT_TURING_MEM_SETUP;
						PRESENT_CHOICE: state <= PRINT_PRESENT_CHOICE;
						GET_STATE_STRING: state <= PRINT_GET_STATE;
						GET_STATE_0_STRING: state <= PRINT_GET_STATE_0;
						GET_STATE_1_STRING: state <= PRINT_GET_STATE_1;
						GET_READ_STRING: state <= PRINT_GET_READ;
						GET_READ_0_STRING: state <= PRINT_GET_READ_0;
						GET_WRITE_STRING: state <= PRINT_GET_WRITE;
						GET_WRITE_0_STRING: state <= PRINT_GET_WRITE_0;
						GET_DIR_STRING: state <= PRINT_GET_DIR;
						GET_DIR_0_STRING: state <= PRINT_GET_DIR_0;
						GET_NS_STRING:	state <= PRINT_GET_NS;
						GET_NS_0_STRING: state <= PRINT_GET_NS_0;
						GET_NS_1_STRING: state <= PRINT_GET_NS_1;
						default: state <= WAIT;
					endcase
				end
				SPIN: begin
					print_done <= 0;
					if(!print_start) begin
						state <= WAIT;
					end
				end
				/*
				 * Print the tape contents
				 */
				PRINT_TURING_MEM_SETUP: begin
					mem_addr <= head_loc - 4'h8 + line_index;
					mem_rw <= 1;
					mem_access <= 1;
					state <= PRINT_TURING_MEM_RECORD;
				end
				PRINT_TURING_MEM_RECORD: begin
					// This if statement effectively makes us wait in this state for two ticks instead of one.
					// Gives the turing machine time to report back the tape contents
					if(mem_access) begin
						mem_access <= 0;
						state <= PRINT_TURING_MEM_RECORD;
					end
					else begin
						state <= PRINT_TURING_MEM_SHIFT;
						
						// Print the head pointer
						if(line_index == 4'h8) begin
							line2[7:0] <= LCD_EXP;
						end
						else begin
							line2[7:0] <= LCD_SPACE;
						end
						
						// Print the tape contents
						case(mem_in)
							SYM_BLANK:	line1[7:0] = LCD_SPACE;
							SYM_ZERO:	line1[7:0] = LCD_ZERO;
							SYM_ONE:		line1[7:0] = LCD_ONE;
							SYM_HASH:	line1[7:0] = LCD_HASH;
						endcase
					end
				end
				PRINT_TURING_MEM_SHIFT: begin
					line_index <= line_index + 4'h1;
					
					// Change state if we must
					if(line_index == 4'hF) begin
						state <= SPIN;
						print_done <= 1;
					end
					else begin
						state <= PRINT_TURING_MEM_SETUP;
						line1 <= line1 << 8;
						line2 <= line2 << 8;
					end
				end
				/*
				 * Present the user with the choice to edit the tape or edit states
				 */
				PRINT_PRESENT_CHOICE: begin
					line1 <= 128'h4564697420546170653A203020202020;
					line2 <= 128'h45646974205374617465733A20312020;
					state <= SPIN;
					print_done <= 1;
				end
				/*
				* Prompt the user for getting the state to edit
				*/
				PRINT_GET_STATE: begin
					line1 <= 128'h456E7465722053746174653A20202020;
					line2 <= 128'h28454E54455220546F2052756E292020;
					state <= SPIN;
					print_done <= 1;
				end
				PRINT_GET_STATE_0: begin
					line1[23:16] <= key_to_print;
					line2 <= 128'h20202020202020202020202020202020;
					state <= SPIN;
					print_done <= 1;
				end
				PRINT_GET_STATE_1: begin
					line1[15:8] <= key_to_print;
					state <= SPIN;
					print_done <= 1;
				end
				PRINT_GET_READ: begin
					line1 <= 128'h456E7465722052656164202020202020;
					line2 <= 128'h53796d626f6c3a202020202020202020;
					state <= SPIN;
					print_done <= 1;
				end
				PRINT_GET_READ_0: begin
					line2[63:56] <= key_to_print;
					state <= SPIN;
					print_done <= 1;
				end
				PRINT_GET_WRITE: begin
					line1 <= 128'h456E7465722057726974652020202020;
					line2 <= 128'h53796D626F6C3A202020202020202020;   
					state <= SPIN;
					print_done <= 1;
				end
				PRINT_GET_WRITE_0: begin
					line2[63:56] <= key_to_print;
					state <= SPIN;
					print_done <= 1;
				end
				PRINT_GET_DIR: begin
					line1 <= 128'h456E746572204D6F7665202020202020;
					line2 <= 128'h4469723A202020202020202020202020;
					state <= SPIN;
					print_done <= 1;
				end
				PRINT_GET_DIR_0: begin
					line2[87:80] <= key_to_print;
					state <= SPIN;
					print_done <= 1;
				end
				PRINT_GET_NS: begin
					line1 <= 128'h456E746572204E657874202020202020;
					line2 <= 128'h53746174653A20202020202020202020;
					state <= SPIN;
					print_done <= 1;
				end
				PRINT_GET_NS_0: begin
					line2[71:64] <= key_to_print;
					state <= SPIN;
					print_done <= 1;
				end
				PRINT_GET_NS_1: begin
					line2[63:56] <= key_to_print;
					state <= SPIN;
					print_done <= 1;
				end
			endcase
		end
	end
	
	always@(*) begin
		if(state == PRINT_GET_STATE_0 || 
		   state == PRINT_GET_STATE_1 ||
			state == PRINT_GET_NS_0    ||
			state == PRINT_GET_NS_1)
			begin
				case(keycode)
					KEY_ZERO: 	key_to_print = LCD_ZERO;
					KEY_ONE: 	key_to_print = LCD_ONE;
					KEY_TWO: 	key_to_print = LCD_TWO;
					KEY_THREE: 	key_to_print = LCD_THREE;
					KEY_FOUR: 	key_to_print = LCD_FOUR;
					KEY_FIVE: 	key_to_print = LCD_FIVE;
					KEY_SIX: 	key_to_print = LCD_SIX;
					KEY_SEVEN: 	key_to_print = LCD_SEVEN;
					KEY_EIGHT: 	key_to_print = LCD_EIGHT;
					KEY_NINE: 	key_to_print = LCD_NINE;
					KEY_A: 		key_to_print = LCD_A;
					KEY_B: 		key_to_print = LCD_B;
					KEY_C: 		key_to_print = LCD_C;
					KEY_D: 		key_to_print = LCD_D;
					KEY_E:		key_to_print = LCD_E;
					KEY_F: 		key_to_print = LCD_F;
					default:		key_to_print = LCD_EXP;
				endcase
		end
		else if(state == PRINT_GET_READ_0 || state == PRINT_GET_WRITE_0) begin
			case(keycode)
				KEY_ZERO: 	key_to_print = LCD_ZERO;
				KEY_ONE: 	key_to_print = LCD_ONE;
				KEY_THREE: 	key_to_print = LCD_HASH;
				KEY_SPACE:  key_to_print = LCD_UNDERSCORE;
				default:		key_to_print = LCD_EXP;
			endcase
		end
		else if(state == PRINT_GET_DIR_0) begin
			case(keycode)
				KEY_A: 	key_to_print = LCD_L;
				KEY_D: 	key_to_print = LCD_R;
				default:		key_to_print = LCD_EXP;
			endcase
		end
		else key_to_print = LCD_SPACE;
	end

endmodule

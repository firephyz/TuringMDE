module turing_machine(execute, print_start, print_done, mem_access, mem_io_pin, mem_rw, mem_addr, head_dir, move_head, state_access, state_addr, state_in, clk, rst);

	parameter TURING_MEMORY_SIZE = 1024;

	// Tape symbols
	parameter SYM_BLANK = 	2'b00,
				 SYM_ZERO = 	2'b01,
				 SYM_ONE = 		2'b10,
				 SYM_HASH = 	2'b11;
				 
	parameter LEFT = 	1'b0,
				 RIGHT = 1'b1;
	
	// State names
	parameter STATE_PRINT = 	3'h0,
				 STATE_READ = 		3'h1,
				 STATE_FETCH = 	3'h2,
				 STATE_WRITE = 	3'h3,
				 STATE_UPDATE = 	3'h4,
				 STATE_DONE = 		3'h5;

	// Clock and reset
	input clk, rst;
	
	// Control wires
	input execute;

	// Interfacing with the lcd control module
	input 		print_done;	// Lets this module know when the lcd is done printing tape contents
	inout [1:0] mem_io_pin; // Used to communicate tape conents back and forth between this and lcd module
	reg [1:0]   mem_out;
	input [10:0] mem_addr; // Used to lcd to get tape contents
	input 		mem_access; // Pulse set by super module to read or write memory
	input 		mem_rw, // Used by super modules to read or write memory (1 is read, 0 is write)
					state_access; // Pulse set by super module
	input [10:0] state_in;
	input [10:0] state_addr; // Set by super module to edit a state
	input 		head_dir;	// Set by super module to move the head in a certain direction
	input 		move_head; // Pulse used by the super module to move the head to starting position
	
	output reg	print_start; // Tells the lcd when to print the tape contents
	
	// Memories
	reg [10:0] 	index; // Used to initialize the memory contents in a for loop
	reg [1:0] 	memory[TURING_MEMORY_SIZE - 1:0]; // Holds turing machine tape contents
	reg [10:0] 	t_states[2047:0];
	
	// Internal state registeres
	reg [2:0] 	state; // This FSM state
	reg [2:0] 	next_state;
	reg [1:0]	read;
	reg [9:0] 	head;
	reg [7:0]	t_state; // Turing machine state
	reg [10:0] 	instr;
	
	assign mem_io_pin = mem_rw ? mem_out : 2'bZ;
	
	// Update the state
	always@(posedge clk or negedge rst) begin
		if(rst == 0) begin
			state <= STATE_PRINT;
			
//			t_states[{8'h00, 2'b01}] <= {2'b10, 1'b1, 8'h01};
//			t_states[{8'h00, 2'b10}] <= {2'b01, 1'b0, 8'h02};
//			t_states[{8'h01, 2'b00}] <= {2'b00, 1'b0, 8'h00};
//			t_states[{8'h01, 2'b01}] <= {2'b01, 1'b1, 8'h01};
//			t_states[{8'h01, 2'b10}] <= {2'b10, 1'b1, 8'h01};
//			t_states[{8'h02, 2'b00}] <= {2'b10, 1'b1, 8'h01};
//			t_states[{8'h02, 2'b01}] <= {2'b10, 1'b1, 8'h01};
//			t_states[{8'h02, 2'b10}] <= {2'b01, 1'b0, 8'h02};
		end
		else begin
			state <= next_state;
		end
	end
	
	// Toggle wires and regs
	always@(posedge clk or negedge rst) begin
		if(rst == 0) begin
			read <= 0;
			head <= TURING_MEMORY_SIZE / 2;
			instr <= 0;
			t_state <= 0;
			print_start <= 0;
			
			// Clear the tape to all blanks
			for(index = 0; index < TURING_MEMORY_SIZE; index = index + 1) begin
//				if(index == TURING_MEMORY_SIZE / 2)
//					memory[index] <= SYM_ZERO;
//				else
					memory[index] <= SYM_BLANK;
			end
		end
		else begin
			// Execute the actual machine
			if(execute) begin
				case(state)
					STATE_PRINT: 	print_start <= 1;
					STATE_READ: begin
						print_start <= 0;
						read <= memory[head];
					end
					STATE_FETCH: 	instr <= t_states[{t_state, read}];
					STATE_WRITE: 	memory[head] <= instr[10:9];
					STATE_UPDATE: begin
						if(instr[8] == LEFT) head <= head + 10'b1;
						else head <= head - 10'b1;
						t_state <= instr[7:0];
					end
					STATE_DONE: begin
						print_start <= 0;
						read <= 0;
						instr <= 0;
						head <= head;
						t_state <= 0;
					end
					default:;
				endcase
			end
			// Move head when editing tape contents
			else if(move_head) begin
				head <= head_dir == 0 ? head + 10'b1 : head - 10'b1;
			end
			else if(mem_access) begin
				if(mem_rw)
					mem_out <= memory[mem_addr];
				else begin
					memory[mem_addr] <= mem_io_pin;
					head <= head_dir == 0 ? head + 10'b1 : head - 10'b1; 
				end
			end
			else if(state_access) begin
				t_states[state_addr] <= state_in;
			end
		end
	end
	
	// Compute the next state
	always@(*) begin
		if(execute && state != STATE_DONE) begin
			case(state)
				STATE_PRINT: begin
					if(print_done) next_state = STATE_READ;
					else next_state = STATE_PRINT;
				end
				STATE_READ: next_state = STATE_FETCH;
				STATE_FETCH: next_state = STATE_WRITE;
				STATE_WRITE: next_state = STATE_UPDATE;
				STATE_UPDATE: begin
					if(instr[7:0] == 8'hFF) next_state = STATE_DONE;
					else next_state = STATE_PRINT;
				end
				default: next_state = STATE_PRINT;
			endcase
		end
		else
			if(state == STATE_DONE)
				next_state = STATE_DONE;
			else
				next_state = STATE_PRINT;
	end
	
endmodule

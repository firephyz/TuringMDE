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
					GET_STATE_1:	next_state = GET_READ;
					GET_READ: 		next_state = GET_READ_0;
					GET_READ_0: 	next_state = GET_WRITE;
					GET_WRITE:		next_state = GET_WRITE_0;
					GET_WRITE_0:	next_state = GET_DIR;
					GET_DIR:			next_state = GET_DIR_0;
					GET_DIR_0:		next_state = GET_NS;
					GET_NS:			next_state = GET_NS_0;
					GET_NS_0:		next_state = GET_NS_1;
					GET_NS_1:		next_state = WRITE_STATE;
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
						if(is_pressed)
							next_state = LCD_ON_TIMER_START;
						else
							next_state = LCD_OFF;
					end
					GET_READ: next_state = LCD_ON_TIMER_START;
					GET_READ_0: begin
						if(is_pressed)
							next_state = LCD_ON_TIMER_START;
						else
							next_state = LCD_OFF;
					end
					GET_WRITE: next_state = LCD_ON_TIMER_START;
					GET_WRITE_0: begin
						if(is_pressed)
							next_state = LCD_ON_TIMER_START;
						else
							next_state = LCD_OFF;
					end
					GET_DIR: next_state = LCD_ON_TIMER_START;
					GET_DIR_0: begin
						if(is_pressed)
							next_state = LCD_ON_TIMER_START;
						else
							next_state = LCD_OFF;
					end
					GET_NS: next_state = LCD_ON_TIMER_START;
					GET_NS_0: begin
						if(is_pressed)
							next_state = LCD_ON_TIMER_START;
						else
							next_state = LCD_OFF;
					end
					GET_NS_1: begin
						if(is_pressed)
							next_state = LCD_ON_TIMER_START;
						else
							next_state = LCD_OFF;
					end
					PRINT_TAPE: next_state = GET_KEY;
					default: next_state = CHOICE;
				endcase
			end
			default: 		next_state = CHOICE;
		endcase
	end
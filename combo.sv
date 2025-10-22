module combo(inout wire [15:0] ARDUINO_IO,
				 input  logic MAX10_CLK1_50,
				 output logic [9:0] LEDR,
				 output logic [7:0] HEX0,
				 output logic [7:0] HEX1,
				 output logic [7:0] HEX2,
				 output logic [7:0] HEX3,
				 output logic [7:0] HEX4,
				 output logic [7:0] HEX5);
				 
				 //Creates the key variables that combo is in charge of
				 logic key_validin;
				 logic key_validin_sync1;
				 logic key_validin_sync2;
				 logic key_code_sync1;
				 logic key_code_sync2;
				 logic [3:0] key_code;
				 logic [3:0] key_code_sync;
				 
				 assign LEDR[3:0] = password_attempt[0];//{key_validin_sync, key_code_sync};
				 assign LEDR[7:4] = password_attempt[1];
				 assign LEDR[9:8] = state;
				 
				 
				 //Assigns them accordingly to the output of the keyboard DE-10
				 assign key_validin = ARDUINO_IO [12];
				 assign key_code = ARDUINO_IO [11:8];
				 
				 //Some basic variables to either count variables, reset or load the shift registers and the password itself that is stored in memory of the shift registers
				 logic key_validin_prev;
				 logic load;
				 logic reset;
				 logic [3:0] password[5:0];
				 logic [3:0] password_attempt[5:0];
				 
				 //Useful constants to refer to instead of the cursed crap of just their straight values
				 localparam logic [47:0] OPEN   = 48'hF7_C0_8C_86_AB_F7;
				 localparam logic [47:0] LOCKED = 48'hC7_C0_C6_89_86_C0;
				 
				 localparam logic [3:0] KEY_CANCEL = 4'hF; // *
				 localparam logic [3:0] KEY_ENTER  = 4'hE; // #
				
				 
				 always_ff @(posedge MAX10_CLK1_50) begin
				 	 key_validin_sync1 <= key_validin;
					 key_validin_sync2 <= key_validin_sync1;

					 key_code_sync1 <= key_code;
					 key_code_sync2 <= key_code_sync1;
						 
//						 if (key_validin_sync & ~key_validin_prev) begin
//							  key_code_sync <= key_code; // Capture the valid key code
//						 end
//						 
//						 else begin
//							  key_code_sync <= 4'h0;     // Clear the code so it's a one-cycle pulse
//						 end
					//					
					//Resets if reset key_code is detected
					if(KEY_CANCEL == key_code_sync2) begin
						reset <= 1'b1;
					end
					else begin
						reset <= 1'b0;
					end
					
					//Enables loading if key_code_sync is not 0, and also not * or #
					if( key_code_sync && key_code_sync2 != KEY_CANCEL) begin
						load <= 1'b1;
					end
					else begin
						load <= 1'b0;
					end
					
					if(state == STATE_B && password_attempt[5] != 0 && key_code_sync2 == KEY_ENTER) begin
						password <= password_attempt;
					end
				 end
					
				//final things to implements, we need the 4 states and the state transitions, we need to output the states to the other board to be 
				//able to read what states its in and act accordingly, a password refresh/keep depending on the state(i.e only storing the password in the shift
				//register if in the password typing state in unlocked and then doing it into password_attempt otherwise).
					
				enum int unsigned {STATE_A = 0,
										 STATE_B = 1,
										 STATE_C = 2,
										 STATE_D = 3}
										 state,nextState;
				
				//Seperate flip flop just to manage states since its a cleaner implementation even tough they may be equivelant
				always_comb begin
					nextState = state;
					case(state)
						STATE_A: begin
						   {HEX5, HEX4, HEX3, HEX2, HEX1, HEX0} = OPEN;
							nextState = STATE_B;
						end
						STATE_B: begin
							{HEX5, HEX4, HEX3, HEX2, HEX1, HEX0} = OPEN;
							if(KEY_ENTER == key_code_sync2 && password_attempt[5] != 0) begin
								nextState = STATE_C;
							end
						end
						
						STATE_C: begin
						   {HEX5, HEX4, HEX3, HEX2, HEX1, HEX0} = LOCKED;
							nextState = STATE_D;
						end
						
						STATE_D: begin
						   {HEX5, HEX4, HEX3, HEX2, HEX1, HEX0} = LOCKED;
							if(KEY_ENTER == key_code_sync2 && password_attempt == password) begin
								nextState = STATE_A;
							end
							
							if(KEY_ENTER == key_code_sync2 && password_attempt != password) begin
								nextState = STATE_C;
							end

						end
					endcase
				end
					
				always_ff @(posedge MAX10_CLK1_50) begin
					if(key_code_sync == KEY_CANCEL) begin
						state <= STATE_A;
					end
					else begin
						state <= nextState;
					end
				end
			 
				 //From LSB to MSB we create shift registers to store and shift the password one hexadecimal digit at a time
				 //Hex 0 
				 shiftreg shift0(.clk(MAX10_CLK1_50), .reset(reset), .load(load),.sin(1'b0), .d(key_code_sync2), .q(password_attempt[0]), .sout() );
				 //Hex 1 
				 shiftreg shift1(.clk(MAX10_CLK1_50), .reset(reset), .load(load),.sin(1'b0), .d(password_attempt[0]), .q(password_attempt[1]), .sout() );
				 //Hex 2 
				 shiftreg shift2(.clk(MAX10_CLK1_50), .reset(reset), .load(load),.sin(1'b0), .d(password_attempt[1]), .q(password_attempt[2]), .sout() );
				 //Hex 3 
				 shiftreg shift3(.clk(MAX10_CLK1_50), .reset(reset), .load(load),.sin(1'b0), .d(password_attempt[2]), .q(password_attempt[3]), .sout() );
				 //Hex 4 
				 shiftreg shift4(.clk(MAX10_CLK1_50), .reset(reset), .load(load),.sin(1'b0), .d(password_attempt[3]), .q(password_attempt[4]), .sout() );
				 //Hex 5 
				 shiftreg shift5(.clk(MAX10_CLK1_50), .reset(reset), .load(load),.sin(1'b0), .d(password_attempt[4]), .q(password_attempt[5]), .sout() );				

				
				
								
endmodule

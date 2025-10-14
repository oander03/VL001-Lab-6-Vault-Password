module combo(inout wire [15:0] ARDUINO_IO,
				 input MAX10_CLK1_50,
				 output [6:0] HEX0,
				 output [6:0] HEX1,
				 output [6:0] HEX2,
				 output [6:0] HEX3,
				 output [6:0] HEX4,
				 output [6:0] HEX5);
				 
				 //Creates the key variables that combo is in charge of
				 logic key_validin;
				 logic key_validin_sync;
				 logic [3:0] key_code;
				 logic [3:0] key_code_sync;
				 
				 
				 //Assigns them accordingly to the output of the keyboard DE-10
				 assign key_valdin = ARDUINO_IO [12];
				 assign key_code = ARDUINO_IO [11:8];
				 
				 //Some basic variables to either count variables, reset or load the shift registers and the password itself that is stored in memory of the shift registers
				 logic wentKey = 0;
				 logic wentCode = 0;
				 logic reset;
				 logic load;
				 logic [3:0] password[5:0];
				 logic [3:0] password_attempt[5:0];
				 
				 //Useful constants to refer to instead of the cursed crap of just their straight values
				 localparam logic [47:0] OPEN   = 48'hF7_C0_8C_86_AB_F7;
				 localparam logic [47:0] LOCKED = 48'hC7_C0_C6_89_86_C0;
				 
				 localparam logic [3:0] KEY_CANCEL = 4'hF; // *
				 localparam logic [3:0] KEY_ENTER  = 4'hE; // #
				
				 
				 always_ff @(posedge MAX10_CLK1_50) begin
				 //Ensures that its gone through one flip flop before syncing key_validin
					wentKey <= 1;
					if (wentKey) begin
						key_validin_sync <= key_validin;		
						wentKey <= 0;
					end
					
					//Makes sure that key_validin_sync falls to low before it waits one flip flop to then sync key_code
					if (~key_validin_sync) begin
							wentCode <= 1;
					end
					
					if(wentCode) begin
						key_code_sync <= key_code;
						wentCode <=0;
					end
					
					//Resets if reset key_code is detected
					if(KEY_CANCEL == key_code_sync)begin
						reset <= 1'b1;
					end
					else begin
						reset <= 1'b0;
					end
					
					//Enables loading if key_code_sync is not 0, and also not * or #
					if( key_code_sync & key_code_sync != KEY_CANCEL & key_code_sync != KEY_ENTER) begin
						load <= 1'b1;
					end
					else begin
						load <= 1'b0;
					end
					
					if(password == password_attempt) begin
						{HEX5, HEX4, HEX3, HEX2, HEX1, HEX0} = OPEN;
					end
					else begin 
						{HEX5, HEX4, HEX3, HEX2, HEX1, HEX0} = LOCKED;
					end
				 end
					
				//final thing to implement 
					
					
					
					
			 
				 //From LSB to MSB we create shift registers to store and shift the password one hexadecimal digit at a time
				 //Hex 0 
				 shiftreg shift0(.clk(MAX10_CLK1_50), .reset(reset), .load(load),.sin(1'b0), .d(key_code_sync), .q(password_attempt[0]), .sout() );
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
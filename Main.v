/*
	----------Cave for Verilog------------
	
	by Aaron Williams
	Completed Fall 2013 for Digital Logic II
	George Washington University

*/


module Main(clk, BTN, HS, vga_h_sync, vga_v_sync, vga_R, vga_G, vga_B, AN, DISP);

	input clk, BTN, HS;
	output vga_h_sync, vga_v_sync, vga_R, vga_G, vga_B;

	wire inDisplayArea;
	wire [9:0] CounterX;
	wire [9:0] CounterY;

	reg clk25_int;
	wire clk25;

	always@(posedge clk)
	begin
		clk25_int <= ~clk25_int;
	end

	BUFG bufg_inst(clk25, clk25_int);

	hvsync_generator syncgen((clk25), (vga_h_sync), (vga_v_sync), (inDisplayArea), (CounterX), (CounterY));
	

/////////////////////////////////////////////////////////////////
//					Handling of Commands					   //
/////////////////////////////////////////////////////////////////

	reg wide_clk;
	reg enable = 0;
	reg seed_load = 0;
	reg load_seed = 1;
	reg reset = 0;
	reg score_display = 0;
	reg init = 1;

	//Score
	reg [3:0]	Score [0:3];
	reg [3:0]	HScore [0:3];

	reg [20:0] wide_counter = 0;
	reg [15:0] seed;
				
	always @ (posedge clk25)
		begin
		
		wide_counter = wide_counter + 1;
		if( wide_counter == 21'b100000000000000000000 )
			begin
			
			if(enable)
				begin
				Score[0] = Score[0] + 1;
				if(Score[0] == 10)
					begin
					Score[0] = 0;
					Score[1] = Score[1] + 1;
					if(Score[1] == 10)
						begin
						Score[1] = 0;
						Score[2] = Score[2] + 1;
						if(Score[2] == 10)
							begin
							Score[2] = 0;
							Score[3] = Score[3] + 1;
							end
						end
					end
				end
		
			wide_clk = !wide_clk;
			wide_counter = 0;
			
			end	
			
		if(enable)
			begin
			
			if(seed_load == 1)
				begin
				load_seed = 0;
				end
				
			if(reset)
				begin
				
				enable = 0;
				
				end
			end
		else
			begin
			
			if(init)
				begin
				HScore[3] = 0;
				HScore[2] = 0;
				HScore[1] = 0;
				HScore[0] = 0;
				init = 0;
				end
			
			if(BTN)
				begin
				enable = 1;
				seed = wide_counter;
				load_seed = 1;
				
				//Reset HighScore
				if(Score[3] > HScore[3])
					begin
					HScore[3] = Score[3];
					HScore[2] = Score[2];
					HScore[1] = Score[1];
					HScore[0] = Score[0];
					end
				else if((Score[3] == HScore[3]) && (Score[2] > HScore[2]))
					begin
					HScore[2] = Score[2];
					HScore[1] = Score[1];
					HScore[0] = Score[0];
					end
				else if((Score[3] == HScore[3]) && (Score[2] == HScore[2]) && (Score[1] > HScore[1]))
					begin
					HScore[2] = Score[2];
					HScore[1] = Score[1];
					HScore[0] = Score[0];
					end
					
				Score[0] = 0;
				Score[1] = 0;
				Score[2] = 0;
				Score[3] = 0;

				end
			end
		end

/////////////////////////////////////////////////////////////////
//					WAll and Score Generation								//
/////////////////////////////////////////////////////////////////

	reg [16:0] Terrain [0:79];
	reg [6:0] for_count;

	//Variables for RandomNG
	reg	[15:0]	randomN;
	reg	[23:0]	LFSR_reg;
	reg	[19:0]	CASR_reg;
	
	reg	[23:0]	LFSR_var;
	reg	outLFSR;
	
	reg	[19:0]	CASR_out;
		
	//Variables for new Terrain Calculation
	reg			isblock = 0;
	reg [1:0]   dir_out;
	reg [2:0]	random_var, dir_count;
	reg [3:0]   blockheight;
	reg [5:0]	height;

	//Terrain calculation variables with initial conditions
	reg [2:0]	dir = 3;
	reg [5:0]	prior_height = 18;
	reg [5:0]	width = 44;
	reg [4:0]	width_counter = 0;
	reg [2:0] 	block_count = 5;
	
	//Giant Terrain Generation Set
	always @ (posedge wide_clk)
		begin

		if(enable)
			begin

		///////////////////////////
		//Random Number Generator//
		///////////////////////////
		
			//LSFR section of the Random Number Generator
			if(reset)
				begin
				LFSR_reg = 1;
				end
			else
				begin
				if(load_seed)
					begin
					LFSR_var [23:16] = 0;
					LFSR_var	[15:0] = seed;
					LFSR_reg = LFSR_var;
					end
				else
					begin
					LFSR_var = LFSR_reg;
					outLFSR = LFSR_var [23];	
					LFSR_var [23] = LFSR_var [22];
					LFSR_var [22] = LFSR_var [21]^outLFSR;
					LFSR_var [21] = LFSR_var [20];
					LFSR_var [20] = LFSR_var [19]^outLFSR;
					LFSR_var [19] = LFSR_var [18];
					LFSR_var [18] = LFSR_var [17];
					LFSR_var [17] = LFSR_var [16]^outLFSR;
					LFSR_var [16] = LFSR_var [15]^outLFSR;
					LFSR_var [15] = LFSR_var [14];
					LFSR_var [14] = LFSR_var [13]^outLFSR;
					LFSR_var [13] = LFSR_var [12];
					LFSR_var [12] = LFSR_var [11];
					LFSR_var [11] = LFSR_var [10]^outLFSR;
					LFSR_var [10] = LFSR_var [9]^outLFSR;
					LFSR_var [9] = LFSR_var [8];
					LFSR_var [8] = LFSR_var [7];
					LFSR_var [7] = LFSR_var [6]^outLFSR;
					LFSR_var [6] = LFSR_var [5]^outLFSR;
					LFSR_var [5] = LFSR_var [4];
					LFSR_var [4] = LFSR_var [3]^outLFSR;
					LFSR_var [3] = LFSR_var [2];
					LFSR_var [2] = LFSR_var [1];
					LFSR_var [1] = LFSR_var [0]^outLFSR;
					LFSR_var [0] = LFSR_var [23];
					LFSR_reg = LFSR_var;
					end
				end
			
			//CASR section of the Random Number Generator
			if(reset)
				begin
				CASR_reg = 1;
				end
			else
				begin
				if(load_seed)
					begin
					CASR_reg [19:16] = 0;
					CASR_reg [15:0] = seed;
					seed_load = 1;
					end
				else
					begin
					CASR_out [19] = CASR_reg [18]^CASR_reg [11];
					CASR_out [18] = CASR_reg [16]^CASR_reg [12];
					CASR_out [17] = CASR_reg [14]^CASR_reg [13];
					CASR_out [16] = CASR_reg [12]^CASR_reg [14];
					CASR_out [15] = CASR_reg [10]^CASR_reg [15];
					CASR_out [14] = CASR_reg [8]^CASR_reg [16];
					CASR_out [13] = CASR_reg [6]^CASR_reg [17];
					CASR_out [12] = CASR_reg [4]^CASR_reg [18];
					CASR_out [11] = CASR_reg [2]^CASR_reg [19];
					CASR_out [10] = CASR_reg [0]^CASR_reg [0];
					CASR_out [9] = CASR_reg [19]^CASR_reg [1];
					CASR_out [8] = CASR_reg [17]^CASR_reg [2];
					CASR_out [7] = CASR_reg [15]^CASR_reg [3];
					CASR_out [6] = CASR_reg [13]^CASR_reg [4];
					CASR_out [5] = CASR_reg [11]^CASR_reg [5];
					CASR_out [4] = CASR_reg [9]^CASR_reg [6];
					CASR_out [3] = CASR_reg [7]^CASR_reg [7];
					CASR_out [2] = CASR_reg [5]^CASR_reg [8];
					CASR_out [1] = CASR_reg [3]^CASR_reg [9];
					CASR_out [0] = CASR_reg [1]^CASR_reg [10];	
					CASR_reg = CASR_out;
					end
				end
				
			//XORing the results of the two sections
			if(reset)
				begin
				randomN = 0;
				end
			else
				begin
				randomN = LFSR_reg [15:0]^CASR_reg [15:0];
				end
				
			end
		/////////////////////////////////
		//Terrain Calculation Generator//
		/////////////////////////////////
		
		if(enable)
			begin
			//Counter for width decrease
			
			width_counter = width_counter + 1;
			if( width_counter == 20 )
				begin
				width_counter = 0;
				width = width - 1;
				end
				
			//Random Variance Changes
			
			casex (randomN[15:13])
			
				3'b00x: random_var = 2;
				3'b01x: random_var = 1;
				3'b10x: random_var = 3;
				3'b111: random_var = 4;
				3'b110: random_var = 0;
				
				endcase
			
			//
			//Direction Decisions
			//
			
			if(dir_count == 3)
				begin
				dir_count = 0;
				end
			else
				begin
				dir_count = dir_count + 1;
				end
			
			//Changes the direction variable
			
			if(randomN[12:10] == 1)
				begin
				dir = dir+1;
				end
			else if(randomN[12:10] == 0)
				begin
				dir = dir-1;
				end
			
			
			if((prior_height <= 14) && !(prior_height + width >= 66))
				begin
				dir = 6;
				end
			else if((prior_height+width >= 66) && !(prior_height <= 14))
				begin
				dir = 0;
				end
			
			//Changes the dir_out output
			
			dir_out = 1;
			
			if(dir == 0)
				begin
					dir_out = 0;
				end
			else if((dir == 1)&&(dir_count [0] == 0))
				begin 
					dir_out = 0;
				end
			else if((dir == 2)&&(dir_count == 0))
				begin
					dir_out = 0;
				end			
			else if((dir == 4)&&(dir_count == 0))
				begin
					dir_out = 2;
				end
			else if((dir == 5)&&(dir_count [0] == 0))
				begin
					dir_out = 2;
				end
			else if(dir == 6)
				begin
					dir_out = 2;
				end
				
			//Final Calculation for Height
				//Takes in to account Direction
			prior_height = prior_height + dir_out - 1;
				//Takes in to account random variance
			height = prior_height - 10 + random_var - 2;
			
			
			//Block Calculations

			if((block_count == 5) )
				begin
				isblock = 1;
				block_count = 0;
				blockheight = randomN[9:6];
				end
			
			if( block_count != 5 )
				begin
				
				block_count = block_count + 1;
				
				end
			else
				begin
				
				isblock = 0;
				
				end
				
			end
			
		if(enable)
			begin
			for(for_count = 0; for_count<79 ; for_count = for_count + 1)
				begin
					
				Terrain[for_count] = Terrain[for_count+1];
					
				end
			Terrain[79] = {height,width,isblock,blockheight};
			end
		else
			begin
			dir = 3;
			prior_height = 18;
			width = 44;
			width_counter = 0;
			block_count = 5;
			isblock = 0;
			for(for_count = 0; for_count<80 ; for_count = for_count + 1)
				begin
				
				Terrain[for_count] = 18'b00101010110000000;
				
				end
			end
		end
	
	
	wire Walls = ((Terrain[CounterX[9:3]][16:11] >= CounterY[9:3]) || ((Terrain[CounterX[9:3]][10:5] + Terrain[CounterX[9:3]][16:11])) <= CounterY[9:3])&&(CounterX[9:3] <= 79);
	wire Blocks = (Terrain[CounterX[9:3]][3:0] == CounterY[8:5]) & (CounterX[9:3] <= 79);

/////////////////////////////////////////////////////////////////
//					Ship Generation											//
/////////////////////////////////////////////////////////////////

	reg [5:0] Location [0:15];
	reg [4:0] loc_count;
	
	//Ship Variables
	
	reg [3:0] ship_direction = 4'b1000;
	reg [5:0] ship_height = 6'b011111;
	
	
	always @(posedge wide_clk)
		begin
		if(enable)
			begin
			
			
			//Directions for Ship
			if(BTN && ship_direction!=4'b0001)
				begin
				
				ship_direction = ship_direction-1;
				
				end
			else if(ship_direction!=4'b1111)
				begin
				
				ship_direction = ship_direction+1;
				
				end
			
			//finalizing ship height
			ship_height = ship_height + ship_direction[3:1] + ship_direction[0] - 4;

			//Managing Array values
			for(loc_count = 0; loc_count<15 ; loc_count = loc_count + 1)
				begin
					
				Location[loc_count] = Location[loc_count+1];
					
				end
			Location[15] = ship_height;

			
			if((Location[15] <= Terrain[15][16:11]) || (Location[15] >= (Terrain[15][16:11] + Terrain[15][10:5]) ))
				begin
				
				reset = 1;
				
				end
			if((Location[15][5:2] == Terrain[15][3:0]))
				begin
				
				reset = 1;
				
				end
			
			end
		else
			begin
			reset = 0;
			ship_height = 6'b011111;
			ship_direction = 4'b1000;
			for(loc_count = 0; loc_count<16 ; loc_count = loc_count + 1)
				begin
				
				Location[loc_count] = 6'b011111;
				
				end
			end
		end

wire Ship = (CounterX[9:3]==16) && (Location[15] == CounterY[9:3]);
wire Trail = (CounterX[9:3]<16) && (Location[CounterX[9:3]-1] == CounterY[9:3]);


/////////////////////////////////////////////////////////////////
//					Coloration      											//
/////////////////////////////////////////////////////////////////

	wire R = Trail | Walls | Blocks;
	wire G = Ship | Walls | Blocks;
	wire B = Walls;

	reg vga_R, vga_G, vga_B;
	always @(posedge clk25)
	begin
		vga_R <= R & inDisplayArea;
		vga_G <= G & inDisplayArea;
		vga_B <= B & inDisplayArea;

	end

/////////////////////////////////////////////////////////////////
//			7-Segment Display      											//
/////////////////////////////////////////////////////////////////

	output [6:0] DISP;
	reg [6:0] DISP;
	reg [3:0] CNTR = 4'b0001;
	output [3:0] AN;
	reg [3:0] AN;
	reg [15:0] CLKCNTR;

	wire[3:0] Num;
	wire[2:0] Dec;

	reg[3:0] Val;
	
	always @ (posedge clk)
	begin
		
		CLKCNTR=CLKCNTR+1;
	
		if (CLKCNTR==16'b1100001101010000)	//Multiplexing Display
		begin

			CLKCNTR=0;
	
			if(CNTR==4'b0001) CNTR=4'b1000;
			else CNTR=CNTR>>1;
		
			AN=~CNTR;	
		
			Val = 4'b1111;							//Sets Null for 7seg at digits 1 and 4  
			
			if(!HS)
				begin
				if(CNTR==4'b0001)	Val=Score[0];			
				else if(CNTR==4'b0010) Val=Score[1];
				else if(CNTR==4'b0100) Val=Score[2];
				else if(CNTR==4'b1000) Val=Score[3];
				end
			else
				begin
				if(CNTR==4'b0001)	Val=HScore[0];			
				else if(CNTR==4'b0010) Val=HScore[1];
				else if(CNTR==4'b0100) Val=HScore[2];
				else if(CNTR==4'b1000) Val=HScore[3];
				end
				
				
			case(Val)								//Case for determining 7seg values
				4'b0000: DISP=7'b1000000;
				4'b0001: DISP=7'b1111001;
				4'b0010: DISP=7'b0100100;
				4'b0011: DISP=7'b0110000;
				4'b0100: DISP=7'b0011001;
				4'b0101: DISP=7'b0010010;
				4'b0110: DISP=7'b0000010;
				4'b0111: DISP=7'b1111000;
				4'b1000: DISP=7'b0000000;
				4'b1001: DISP=7'b0011000;
				
				default: DISP=7'b1111111;
			endcase
		end
	end
	
endmodule
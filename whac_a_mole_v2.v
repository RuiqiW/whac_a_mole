
module whac_a_mole_v2(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
      KEY,
      SW,
		HEX0,
		HEX1,

		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B   						//	VGA Blue[9:0]
	);
	
	// Declare inputs and outputs11
	input	CLOCK_50;				//	50 MHz
	input   [9:0]   SW;
	input   [3:0]   KEY;
	output [6:0] HEX0, HEX1; //score display
	
	// Do not change the following outputs
	output	VGA_CLK;   				//	VGA Clock
	output	VGA_HS;					//	VGA H_SYNC
	output	VGA_VS;					//	VGA V_SYNC
	output	VGA_BLANK_N;				//	VGA BLANK
	output	VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   			//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 			//	VGA Green[9:0]
	output	[9:0]	VGA_B;   			//	VGA Blue[9:0]
	
	

	wire resetn;
	assign resetn = SW[0];
	wire go;
	assign go = SW[1];
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [7:0] x;
	wire [6:0] y;
	wire writeEn;
	wire [2:0] rgb;

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(rgb),
			.x(x),
			.y(y),
			.plot(writeEn),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK)
		);
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";
			
	
	// for the VGA controller, in addition to any other functionality your design may require.
    
	
	wire  draw_mole, draw_hammer, clear, erase, update, count, m, f_en, f;
	assign writeEn = draw_mole || draw_hammer || clear || erase; 

	wire move;			// a signal to move to next state
	wire [1:0] mole_id;
	wire [5:0]current_state;
	wire [3:0] frame;
	wire [7:0] score;

    // Instansiate datapath
        datapath d0(
			.resetn(resetn),
		   .clk(CLOCK_50),
			.h(KEY[3:0]),
			.update(update),
			.erase(erase),
			.clear(clear),

			.draw_mole(draw_mole),
			.draw_hammer(draw_hammer),
			.mole_id(mole_id),
	

			.m(m),
			.x(x),
			.y(y),
			.move(move),
			.rgb(rgb),
			.score(score[7:0])

		);

    // Instansiate FSM control
        control c0(
			.resetn(resetn),
		   .clk(CLOCK_50),
			.go(go),
			.move(move),
			.count(count),
			.difficulty(SW[9:8]),
			
			.frame(frame),
			.f(f),
			.m(m),
			.update(update),
			.mole_id(mole_id),
			.erase(erase),
			.clear(clear),
			.draw_mole(draw_mole),
			.draw_hammer(draw_hammer),
			.current_state(current_state)
		);



  delaycounter u0(
    .clock(CLOCK_50), 
    .resetn(count), 
    .enable(1'b1), 
    .en(f_en)
);

  framecounter u1(
    .clock(CLOCK_50),
    .resetn(count),
	 .frame(frame),
    .enable(f_en),
    .en(f)
);

hex_decoder h0(
	.hex_digit(score[3:0]),
	.segments(HEX0)
	);

hex_decoder h1(
	.hex_digit(score[7:4]),
	.segments(HEX1)
);


endmodule
                

module control(
    input clk,
    input resetn,
    input go,
    input move, f,
	 input difficulty,
    output reg  draw_mole,draw_hammer, clear, erase, update, count, m,
	 output reg [3:0]frame,
    output reg [1:0]mole_id,
    output reg [5:0]current_state
    );

    reg [5:0]  next_state; 
    
    localparam  CLEAR = 6'd0,
		D_MOLE_1 = 6'd1,
		D_MOLE_2 = 6'd2,
		D_MOLE_3 = 6'd3,
		D_MOLE_4 = 6'd4,
		D_HAMMER_1 = 6'd5,
		D_HAMMER_2 = 6'd6,
		D_HAMMER_3 = 6'd7,
		D_HAMMER_4 = 6'd8,
		ERASE_1 = 6'd9,
		ERASE_2 = 6'd10,
		ERASE_3 = 6'd11,
		ERASE_4 = 6'd12,
		WAIT = 6'd13,
		UPDATE = 6'd14,
		COUNT_TIME = 6'd15,
		WAIT1 = 6'd16,
		WAIT2 = 6'd17,
		WAIT3 = 6'd18,
		WAIT4= 6'd19,
		EWAIT1= 6'd20,
		EWAIT2= 6'd21,
		EWAIT3= 6'd22,
		EWAIT4= 6'd23,
		HWAIT1= 6'd24,
		HWAIT2= 6'd25,
		HWAIT3= 6'd26,
		HWAIT4= 6'd27,
		COUNT_WAIT= 6'd28;
		
	always@(*)
	begin
	 case(difficulty)
	   2'd0: frame = 4'd14;
		2'd1: frame = 4'd9;
		2'd2: frame = 4'd4;
		default: frame = 4'd14;
	endcase
	end
		

    // Next state logic aka our state table
    always@(*)
    begin: state_table 
            case (current_state)
		CLEAR: next_state = move ? WAIT : CLEAR; 
		WAIT: next_state = go ? D_MOLE_1 : WAIT;
		D_MOLE_1: next_state = move ? WAIT1 : D_MOLE_1;
		WAIT1: next_state = D_MOLE_2;
		D_MOLE_2: next_state = move ? WAIT2 : D_MOLE_2;
		WAIT2: next_state = D_MOLE_3;
		D_MOLE_3: next_state = move ? WAIT3 : D_MOLE_3;
		WAIT3: next_state = D_MOLE_4;
		D_MOLE_4: next_state = move ? WAIT4 : D_MOLE_4;
		WAIT4:next_state = COUNT_TIME;
		COUNT_TIME :  next_state = f ? COUNT_WAIT : COUNT_TIME;
		COUNT_WAIT: next_state = ERASE_1;
		ERASE_1: next_state = move? EWAIT1 : ERASE_1;
		EWAIT1: next_state = ERASE_2;
		ERASE_2: next_state = move? EWAIT2 : ERASE_2;
		EWAIT2: next_state = ERASE_3;
		ERASE_3: next_state = move? EWAIT3 : ERASE_3;
		EWAIT3: next_state = ERASE_4;
		ERASE_4: next_state = move? EWAIT4 : ERASE_4;
		EWAIT4: next_state = UPDATE;
		UPDATE: next_state = D_HAMMER_1;
		D_HAMMER_1 : next_state = move ? HWAIT1 : D_HAMMER_1;
		HWAIT1: next_state = D_HAMMER_2;
		D_HAMMER_2 : next_state = move ? HWAIT2 : D_HAMMER_2;
		HWAIT2: next_state = D_HAMMER_3;
		D_HAMMER_3 : next_state = move ? HWAIT3 : D_HAMMER_3;
		HWAIT3: next_state = D_HAMMER_4;
		D_HAMMER_4 : next_state = move ? HWAIT4 : D_HAMMER_4;
		HWAIT4: next_state = D_MOLE_1;
		
      default:     next_state = CLEAR;
      endcase
    end // state_table
   

    // Output logic aka all of our datapath control signals
    always @(*)
    begin: enable_signals
        // By default make all our signals 0
	erase = 1'b0;
   draw_mole = 1'b0;
	draw_hammer = 1'b0;
	clear = 1'b0;
	mole_id = 2'd0;
	update = 1'b0;
	count = 1'b0;
	m = 1'b1;

        case (current_state)
            CLEAR: begin
		clear = 1'b1;
		m = 1'b0;
                end
            D_MOLE_1: begin
		draw_mole = 1'b1;
				m = 1'b0;
                end
            D_MOLE_2: begin
		draw_mole = 1'b1;
		mole_id = 2'd1;
				m = 1'b0;
                end
            D_MOLE_3: begin
		draw_mole = 1'b1;
		mole_id = 2'd2;
				m = 1'b0;
                end
            D_MOLE_4: begin
		draw_mole = 1'b1;
		mole_id = 2'd3;
				m = 1'b0;
                end
	    D_HAMMER_1: begin
		draw_hammer = 1'b1;
				m = 1'b0;
                end
            D_HAMMER_2: begin
		draw_hammer = 1'b1;
		mole_id = 2'd1;
				m = 1'b0;
                end
            D_HAMMER_3: begin
		draw_hammer = 1'b1;
		mole_id = 2'd2;
				m = 1'b0;
                end
            D_HAMMER_4: begin
		draw_hammer = 1'b1;
		mole_id = 2'd3;
				m = 1'b0;
                end
	    ERASE_1: begin
		erase = 1'b1;
				m = 1'b0;
		end
	    ERASE_2: begin
		erase = 1'b1;
		mole_id = 2'd1;
				m = 1'b0;
                end
            ERASE_3: begin
		erase = 1'b1;
		mole_id = 2'd2;
				m = 1'b0;
                end
            ERASE_4: begin
		erase = 1'b1;
		mole_id = 2'd3;
				m = 1'b0;
                end
	    UPDATE: begin
		update = 1'b1;
				m = 1'b0;

		end
	    COUNT_TIME: begin
		count = 1'b1;
				m = 1'b0;
		end

        // default:    // don't need default since we already made sure all of our outputs were assigned a value at the start of the always block
        endcase
    end // enable_signals
      // current_state registers
 
   always@(posedge clk)
    begin:state_FFs 
        if(resetn == 0)
            current_state <= CLEAR;
        else
            current_state <= next_state;
    end // state_FFS


endmodule



module datapath(
    input clk,
    input resetn,
    input draw_mole, draw_hammer, erase, clear, update, m,
    input [1:0]mole_id,
    input [3:0] h,
    output reg [7:0] x, //the exact position of pixel to be drawn
    output reg [6:0] y,
    output reg move,
    output reg [2:0]rgb,
    output reg [7:0]score
    );
    
    reg [7:0] x_counter; //for bg
    reg [6:0] y_counter;
    reg [7:0] counter;  //counter for drawing a mole/hammer/erase

    //reg [3:0] frame_counter;
    //reg [19:0] delay_counter;
    
    reg [7:0] x_posi;
    reg [6:0] y_posi;
    reg [7:0] mole_1, mole_2, mole_3, mole_4; //y position of moles
    reg [3:0] score_reg;
    reg [3:0] hammer, hammer_to_draw;

    reg [31:0] sequence1, sequence2, sequence3, sequence4;
    reg [3:0] direction;

    localparam  M_X_1 = 8'd19, // 1st mole
		M_X_2 = 8'd43, // 2nd mole 
		M_X_3 = 8'd67, // 3rd mole 
		M_X_4 = 8'd91, // 4th mole 
		M_Y_S = 7'd59, // starting position of mole
		M_Y_E = 7'd51, // ending position of mole
		M_Y_H = 7'd47, // y position of hammer
 		S1 = 24'b110000111100101100110000,
		S2 = 24'b110011000110011110110011,
		S3 = 24'b000110011011000111001100,
		S4 = 24'b001101100110110011011011;

   always @(*) begin
	case (mole_id)
	  2'd0: x_posi = M_X_1;
	  2'd1: x_posi = M_X_2;
	  2'd2: x_posi = M_X_3;
	  2'd3: x_posi = M_X_4;
     default: x_posi = M_X_1;
	endcase
   end

   always @(*) begin
	if(draw_hammer || erase)
	   y_posi = M_Y_H;
      else begin
		if(draw_mole) begin
			case (mole_id)
	  			2'd0: y_posi = mole_1;
	  			2'd1: y_posi = mole_2;
	  			2'd2: y_posi = mole_3;
	  			2'd3: y_posi = mole_4;
				default: y_posi = mole_1;
			endcase
		end
		else y_posi = mole_1;
		end
		end 

    always @ (posedge clk) begin
        if (resetn == 0) begin
	    x <= 8'd0; 		//output to vga
	    y <= 7'd0;	 	//output to vga
       move <= 1'b0;  	// signal that returns to controler to move to next state
	    rgb <= 3'd0;
	    score <= 8'd0; 
	    
	    x_counter <= 8'd0; //for bg
 	    y_counter <= 7'd0;
    	 counter <= 8'd0;  //8*8 or 8*8*3 counter

	    //delay_counter <= 20'd833333;	//20'd833333;
	    //frame_counter <= 4'd15;	//4'd15

       mole_1 <= M_Y_S;
 	    mole_2 <= M_Y_S;
	    mole_3 <= M_Y_S;
	    mole_4 <= M_Y_S;
	    
	    hammer <= 4'b0000;
	    hammer_to_draw <= 4'b0000;
	    score_reg <= 4'b0000;

	    sequence1 <= S1;
	    sequence2 <= S2;
	    sequence3 <= S3;
	    sequence4 <= S4;
	    direction <= 4'b0000;
        end

		  
		 if (m) begin
		     move<= 1'b0;
			  counter <= 8'd0;
		 end

	    if (update)begin  // update info
		   move <= 1'b0;
	    	hammer_to_draw <= hammer;
			hammer <= 4'd0;
			score <= score + score_reg[0] + score_reg[1] + score_reg[2] + score_reg[3];
			score_reg <= 4'd0;
		
		//update direction
		if(mole_1 == M_Y_S)begin
			direction[0] <= sequence1[23];
			sequence1 <= sequence1 << 1'b1;
		end
		else begin
			if(mole_1 == M_Y_E)
			    direction[0] <= 1'b0;
		end
		if(mole_2 == M_Y_S)begin
			direction[1] <= sequence2[23];
			sequence2 <= sequence2 << 1'b1;
		end
		else begin
			if(mole_2 == M_Y_E)
			    direction[1] <= 1'b0;
		end
		if(mole_3 == M_Y_S)begin
			direction[2] <= sequence3[23];
			sequence3 <= sequence3 << 1'b1;
		end
		else begin
			if(mole_3 == M_Y_E)
			    direction[2] <= 1'b0;
		end
		if(mole_4 == M_Y_S)begin
			direction[3] <= sequence4[23];
			sequence4 <= sequence4 << 1'b1;
		end
		else begin
			if(mole_4 == M_Y_E)
			    direction[3] <= 1'b0;
		end
		
		//update location
		if(direction[0] == 1) begin
			if(mole_1 > M_Y_E)
				mole_1 <= mole_1 -1'b1;
		end
		else if(direction[0] == 0)begin
			if(mole_1 < M_Y_S)
				mole_1 <= mole_1 + 1'b1;
		end
		if(direction[1] == 1) begin
			if(mole_2 > M_Y_E)
				mole_2 <= mole_2 -1'b1;
		end
		else if(direction[1] == 0)begin
			if(mole_2 < M_Y_S)
				mole_2 <= mole_2 + 1'b1;
		end
		if(direction[2] == 1) begin
			if(mole_3 > M_Y_E)
				mole_3 <= mole_3 -1'b1;
		end
		else if(direction[2] == 0) begin
			if(mole_3 < M_Y_S)
				mole_3 <= mole_3 + 1'b1;
		end
		if(direction[3] == 1) begin
			if(mole_4 > M_Y_E)
				mole_4 <= mole_4 - 1'b1;
		end
		else if(direction[3] == 0) begin
			if(mole_4 < M_Y_S)
				mole_4 <= mole_4 + 1'b1;
		end 	
	    end
	   
		
		if(update == 0)begin
		if(h[0] == 0) begin
			hammer[0] <= 1'b1;
			if(mole_1 == 7'd51) 
				score_reg[0] <= 1'b1;
	    	end
	    	if(h[1] == 0) begin
			hammer[1] <= 1'b1;
			if(mole_2 == 7'd51)
			score_reg[1] <= 1'b1;
	    	end
	    	if(h[2] == 0) begin
			hammer[2] <= 1'b1;
			if(mole_3 < 7'd52)
				score_reg[2] <= 1'b1;
	    	end
	    	if(h[3] == 0) begin
			hammer[3] <= 1'b1;
			if(mole_4 < 7'd52)
				score_reg[3] <= 1'b1;
	    	end
		end

         	
	 
	    if (clear) begin // clear and reset the screen
		if (y_counter < 60) begin//draw the sky
			rgb<= 3'b111;
		end 
		else begin
			rgb <= 3'b000;
		end

		x_counter <= x_counter + 8'd1;

		if (x_counter == 159)begin
			x_counter <= 0;
			y_counter <= y_counter+ 7'd1;
		end

		if (x_counter == 159 & y_counter == 119)begin
			y_counter <= 0;
			move <= 1'b1;
		end

		x<= x_counter;
		y<= y_counter;
	
	    end



	    if (draw_mole) begin  // draw a mole

	    if (counter[5:0] == 6'b111111)begin
			move <= 1'b1;
			counter <= 8'd0;
		 end
		 rgb <= 3'b110; // set base color to yellow
		 if (counter[2:0] == 3'd0)begin //first row
			if (counter[5:3] == 3'd0 ||counter[5:3] == 3'd3 ||counter[5:3] == 3'd4 ||counter[5:3] == 3'd7)
				rgb <= 3'b111;   	
		 end
		 if (counter[2:0] == 3'd2 || counter[2:0] == 3'd3)begin // 3rd and 4th row
			if (counter[5:3] == 3'd2 ||counter[5:3] == 3'd5)
				rgb <= 3'b000;   	
		 end
		 if (counter[2:0] == 3'd5)begin // 6th row
			if (counter[5:3] == 3'd3 ||counter[5:3] == 3'd4)
				rgb <= 3'b100;   	
		 end
		 if (counter[2:0] == 3'd6 ||counter[2:0] == 3'd7)begin // 7th and 8th row
				rgb <= 3'b000;   	
		 end
	    counter <= counter +8'd1;
		 x <= x_posi + counter[5:3];
		 y <= y_posi + counter [2:0];
	    end

	    if (draw_hammer) begin  // draw a mole
	        if (counter[3:0] == 4'b1111)begin
				move <= 1'b1;
				counter <= 8'd0;
			end
			if (hammer_to_draw[mole_id] == 1'b1)
				rgb <= 3'b011; // set base color to cyan
			else rgb <= 3'b000;
			counter <= counter +8'd1;
			x <= x_posi + counter[3:2];
			y <= y_posi + counter [1:0];
	    end
	    
	    if(erase) begin
			if(counter[7:0] == 8'd159)begin
				move <= 1'b1;
				counter <= 8'd0;
			end
			if (counter[7:3] < 5'd13) begin//draw the sky
				rgb<= 3'b111;
			end
			else begin
			rgb <= 3'b000;
			end
			counter <= counter + 8'd1;
			x <= x_posi + counter[2:0];
			y <= y_posi + counter[7:3];
			end
      end

    
    
    
endmodule



module delaycounter(clock, resetn, enable, en);
input clock, resetn, enable;
output en;
reg [20:0]q;

assign en = ((q == 833333) & enable) ? 1:0; //833333

always @(posedge clock, negedge resetn)
begin
  if(resetn == 1'b0)
    q<= 0;
  else if(enable == 1'b1)
  begin
    if(q == 833333) //833333
      q<= 0;
    else
      q<= q + 1'b1;
  end
end
endmodule

module framecounter(clock, resetn, frame, enable, en);
input clock, resetn, enable;
input [3:0] frame;
output en;
reg [4:0]q;

assign en = ((q == frame) & enable) ? 1:0; //14

always @(posedge clock, negedge resetn)
begin
  if(resetn == 1'b0)
    q<= 0;
  else if(enable == 1'b1)
  begin
    if(q == frame) //14
      q<= 0;
    else
      q<= q + 1'b1;
  end
end
endmodule


module hex_decoder(hex_digit, segments);
    input [3:0] hex_digit;
    output reg [6:0] segments;
   
    always @(*)
        case (hex_digit)
            4'h0: segments = 7'b100_0000;
            4'h1: segments = 7'b111_1001;
            4'h2: segments = 7'b010_0100;
            4'h3: segments = 7'b011_0000;
            4'h4: segments = 7'b001_1001;
            4'h5: segments = 7'b001_0010;
            4'h6: segments = 7'b000_0010;
            4'h7: segments = 7'b111_1000;
            4'h8: segments = 7'b000_0000;
            4'h9: segments = 7'b001_1000;
            4'hA: segments = 7'b000_1000;
            4'hB: segments = 7'b000_0011;
            4'hC: segments = 7'b100_0110;
            4'hD: segments = 7'b010_0001;
            4'hE: segments = 7'b000_0110;
            4'hF: segments = 7'b000_1110;   
            default: segments = 7'h7f;
        endcase
endmodule

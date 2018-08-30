module whac_a_mole_final(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
      KEY,
      SW,
		HEX0,
		HEX1,
		
		PS2_DAT,
		PS2_CLK,

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
	
	input PS2_DAT;
	input PS2_CLK;
	
	// Do not change the following outputs
	output	VGA_CLK;   				//	VGA Clock
	output	VGA_HS;					//	VGA H_SYNC
	output	VGA_VS;					//	VGA V_SYNC
	output	VGA_BLANK_N;				//	VGA BLANK
	output	VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   			//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 			//	VGA Green[9:0]
	output	[9:0]	VGA_B;   			//	VGA Blue[9:0]
	
	

	wire resetn, restart;
	assign resetn = SW[0];
	assign restart = SW[2];
	wire go;
	//assign go = SW[1];
	
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
	wire valid, makeBreak;
	wire [7:0]outCode;
 
	 
	keyboard_press_driver KEYBOARD(
		.CLOCK_50(CLOCK_50),
		.valid(valid), // 1 when a scan_code arrives from the inner driver
		.makeBreak(makeBreak),
		.outCode(outCode[7:0]), // most recent byte scan_code
		.PS2DAT(PS2_DAT), // PS2 data line
		.PS2CLK(PS2_CLK), // PS2 clock line
		.reset(~resetn)
		);
		
	keyboard_converter k0(
	.clk(CLOCK_50),
	.resetn(resetn),
	.valid(valid),
	.outCode(outCode[7:0]),
	.difficulty(difficulty[1:0]),
	.go(go)
	
);

	
	wire  draw_mole, draw_hammer, draw_n, clear, erase, update, count, clear_end;
	wire m;			//signal to set "move" back to 0
	wire f_en, f; //signal for delay and frame counter
	wire compare;
	wire finish;
	assign writeEn = draw_mole || draw_hammer || clear || erase || draw_n || clear_end; 
	
	wire [1:0]difficulty;

	wire move;			// a signal to move to next state
	wire [1:0] mole_id;
	wire [5:0] current_state;
	wire [5:0] frame;
	wire [3:0] id;
	wire [7:0] score, highscore;
	wire [3:0] num_id;
	
	// for number top module
	wire [19:0] segment_0,segment_1,segment_2,segment_3,segment_4, segment_5, segment_h1, segment_h2;



    // Instansiate datapath
        datapath d0(
			.resetn(resetn),
			.restart(restart),
		   .clk(CLOCK_50),
			.h(KEY[3:0]),    //hammer
			.update(update),
			.erase(erase),
			.clear(clear),
			
			.valid(valid), //keyboard input
			.outCode(outCode[7:0]), //keyboard input
			
			.clear_end(clear_end),
			.id(id),

			.draw_mole(draw_mole),
			.draw_hammer(draw_hammer),
			.draw_n(draw_n),    //draw number
			.mole_id(mole_id),
			.compare(compare),
			
			.segment_0(segment_0),
			.segment_1(segment_1),
			.segment_2(segment_2),
			.segment_3(segment_3),
			.segment_4(segment_4),
			.segment_5(segment_5),
			.segment_h1(segment_h1),
			.segment_h2(segment_h2),
	
			.num_id(num_id),
			.m(m),
			.x(x),
			.y(y),
			.move(move),

			.rgb(rgb),
			.score(score[7:0]),
			.highscore(highscore[7:0])

		);




    number_top n0(
	.CLOCK_50(CLOCK_50),
	.resetn(resetn),
	.go(go),
	.score(score),
	.highscore(highscore),
	.difficulty(difficulty),
	.restart(restart),
	.finish(finish),

	.segment_0(segment_0),
	.segment_1(segment_1),
	.segment_2(segment_2),
	.segment_3(segment_3),
	.segment_4(segment_4),
	.segment_5(segment_5),
	.segment_h1(segment_h1),
	.segment_h2(segment_h2)
);


    // Instansiate FSM control
        control c0(
			.resetn(resetn),
		   .clk(CLOCK_50),
			.go(go),
			.move(move),
			.count(count),
			.difficulty(difficulty),
			
			.id(id),
			.num_id(num_id),
			.frame(frame),
			.f(f),
			.m(m),
			.restart(restart),
			.finish(finish),
			
			.update(update),
			.compare(compare),
			.mole_id(mole_id),
			.erase(erase),
			.clear(clear),
			.clear_end(clear_end),
			.draw_mole(draw_mole),
			.draw_hammer(draw_hammer),
			.draw_n(draw_n),
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




module keyboard_converter(clk, resetn, valid, outCode, difficulty, go);
	 input clk;
	 input resetn;
	 input valid;
	 input [7:0]outCode;
	 output reg [1:0] difficulty;
	 output reg go;
	 
	 always@(*) begin
		if(valid == 1) begin
		  if (outCode[7:0] == 8'h16 || outCode[7:0] == 8'h1e || outCode[7:0] == 8'h26)
		     go = 1'b1;
		end
		else go = 1'b0;
	 end
	 
	 always@(posedge clk) begin
	   if(resetn == 0)begin
		  difficulty <= 2'b00;
		end
		else begin
		  if(valid) begin
			if (outCode[7:0] == 8'h16)
		    difficulty <= 2'b01;
			else if(outCode[7:0] == 8'h1e)
			difficulty <= 2'b10;
			else if(outCode[7:0] == 8'h1e)
			difficulty <= 2'b11;
		  end
		end
	 end
endmodule
               

module control(
    input clk,
    input resetn,
    input go,
    input move, f,
	 input finish, restart,
	 input [1:0]difficulty,
    output reg  draw_mole,draw_hammer, clear, erase, update, count, m, draw_n, clear_end, compare,
	 output reg [5:0]frame,
	 output reg [3:0] id,
    output reg [1:0]mole_id,
	 output reg [3:0]num_id,
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
		COUNT_WAIT= 6'd28,
		D_NUM_1 = 6'd29,
		D_NUM_2 = 6'd30,
		D_NUM_3 = 6'd31,
		D_NUM_4 = 6'd32,
		D_NUM_5 = 6'd33,
		D_NUM_6 = 6'd34,
		WAIT1N = 6'd35,
		WAIT2N = 6'd36,
		WAIT3N = 6'd37,
		WAIT4N= 6'd38,
		WAIT5N= 6'd39,
		WAIT6N= 6'd40,

		ENDGAME = 6'd41,
		CLEAR_END = 6'd42,
		ENDWAIT = 6'd43,
		D_ENDNUM_1 = 6'd44,
		D_ENDNUM_2 = 6'd45,
		D_ENDNUM_3 = 6'd46,
		D_ENDNUM_4 = 6'd47,
		
		ENDWAIT1 = 6'd48,
		ENDWAIT2 = 6'd49,
		ENDWAIT3 = 6'd50,
		ENDWAIT4 = 6'd51,
		RESTART = 6'd52;

		
	
	always@(*)
	begin
	 case(difficulty)
	   2'd1: frame = 6'd14;
		2'd2: frame = 6'd9;
		2'd3: frame = 6'd4;
		default: frame = 6'd14;
	endcase
	end
		

    // Next state logic aka our state table
    always@(*)
    begin: state_table 
            case (current_state)
		CLEAR: next_state = move ? WAIT : CLEAR; 
		
		
		WAIT: next_state = go ? D_NUM_1 : WAIT;
		
		D_NUM_1: next_state = move ? WAIT1N : D_NUM_1;
		WAIT1N:  next_state = D_NUM_2;
		D_NUM_2: next_state = move ? WAIT2N : D_NUM_2;
		WAIT2N:  next_state = D_NUM_3;
		D_NUM_3: next_state = move ? WAIT3N : D_NUM_3;
		WAIT3N:  next_state = D_NUM_4;
		D_NUM_4: next_state = move ? WAIT4N : D_NUM_4;
		WAIT4N:  next_state = D_NUM_5;
		D_NUM_5: next_state = move ? WAIT5N : D_NUM_5;
		WAIT5N:  next_state = D_NUM_6;
		D_NUM_6: next_state = move ? WAIT6N : D_NUM_6;
		WAIT6N:  next_state = D_MOLE_1;
		
		D_MOLE_1: next_state = move ? WAIT1 : D_MOLE_1;
		WAIT1: next_state = D_MOLE_2;
		D_MOLE_2: next_state = move ? WAIT2 : D_MOLE_2;
		WAIT2: next_state = D_MOLE_3;
		D_MOLE_3: next_state = move ? WAIT3 : D_MOLE_3;
		WAIT3: next_state = D_MOLE_4;
		D_MOLE_4: next_state = move ? WAIT4 : D_MOLE_4;
		WAIT4:next_state = COUNT_TIME;
		
		COUNT_TIME :  next_state = f ? COUNT_WAIT : COUNT_TIME;
		COUNT_WAIT: next_state = finish ? CLEAR_END : ERASE_1;
		
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
		HWAIT4: next_state = D_NUM_1;
		
		
		CLEAR_END: next_state = move ? ENDWAIT : CLEAR_END;
		ENDWAIT: next_state = D_ENDNUM_1;
		
		D_ENDNUM_1: next_state = move ? ENDWAIT1 : D_ENDNUM_1;
		ENDWAIT1:  next_state = D_ENDNUM_2;
		
		D_ENDNUM_2: next_state = move ? ENDWAIT2 : D_ENDNUM_2;
		ENDWAIT2:  next_state = D_ENDNUM_3;
		
		D_ENDNUM_3: next_state = move ? ENDWAIT3 : D_ENDNUM_3;
		ENDWAIT3:  next_state = D_ENDNUM_4;
		
		D_ENDNUM_4: next_state = move ? ENDWAIT4 : D_ENDNUM_4;
		ENDWAIT4:  next_state = restart ? ENDWAIT4 : RESTART;  //restart is active low signal
		
		RESTART: next_state = CLEAR;
	
		
      default:     next_state = CLEAR;
      endcase
    end // state_table
   

    // Output logic aka all of our datapath control signals
    always @(*)
    begin: enable_signals
        // By default make all our signals 0
	clear_end = 1'b0;
	erase = 1'b0;
   draw_mole = 1'b0;
	draw_hammer = 1'b0;
	draw_n = 1'b0;
	clear = 1'b0;
	update = 1'b0;
	count = 1'b0;
	m = 1'b1;    // when high reset move signal and counter to 0
	
	num_id = 4'd1;
	mole_id = 2'd0;
	id = 4'd0;
	compare = 1'b0;

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
		id = 4'd1;
				m = 1'b0;
                end
            D_MOLE_3: begin
		draw_mole = 1'b1;
		mole_id = 2'd2;
				id = 4'd2;
				m = 1'b0;
                end
            D_MOLE_4: begin
		draw_mole = 1'b1;
		mole_id = 2'd3;
				id = 4'd3;
				m = 1'b0;
                end
	    D_HAMMER_1: begin
		draw_hammer = 1'b1;
				m = 1'b0;
                end
            D_HAMMER_2: begin
		draw_hammer = 1'b1;
		mole_id = 2'd1;
				id = 4'd1;
				m = 1'b0;
                end
            D_HAMMER_3: begin
		draw_hammer = 1'b1;
		mole_id = 2'd2;
				id = 4'd2;
				m = 1'b0;
                end
            D_HAMMER_4: begin
		draw_hammer = 1'b1;
		mole_id = 2'd3;
				id = 4'd3;
				m = 1'b0;
						end
	    ERASE_1: begin
		erase = 1'b1;
				m = 1'b0;
		end
	    ERASE_2: begin
		erase = 1'b1;
		mole_id = 2'd1;
				id = 4'd1;
				m = 1'b0;
                end
            ERASE_3: begin
		erase = 1'b1;
		mole_id = 2'd2;
				id = 4'd2;
				m = 1'b0;
                end
            ERASE_4: begin
		erase = 1'b1;
		mole_id = 2'd3;
				id = 4'd3;
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
	    D_NUM_1: begin
		draw_n = 1'b1;
		num_id = 4'd1;
				id = 4'd4;
				m = 1'b0;
                end
	    D_NUM_2: begin
		draw_n = 1'b1;
		num_id = 4'd2;
				id = 4'd5;
				m = 1'b0;
                end
	    D_NUM_3: begin
		draw_n = 1'b1;
		num_id = 4'd3;
				id = 4'd6;
				m = 1'b0;
                end
	    D_NUM_4: begin
		draw_n = 1'b1;
		num_id = 4'd4;
				id = 4'd7;
				m = 1'b0;
                end
	    D_NUM_5: begin
		draw_n = 1'b1;
		num_id = 4'd5;
				id = 4'd8;
				m = 1'b0;
                end
	    D_NUM_6: begin
		draw_n = 1'b1;
		num_id = 4'd6;
				id = 4'd9;
				m = 1'b0;
                end

		CLEAR_END: begin
			clear_end = 1'b1;
			m = 1'b0;
		end
		
		D_ENDNUM_1: begin
			draw_n = 1'b1;
			num_id = 4'd7;    // segment number
				id = 4'd10; 
			m = 1'b0;
		end
		D_ENDNUM_2: begin
			draw_n = 1'b1;
			num_id = 4'd8;
				id = 4'd11;
			m = 1'b0;
		end
		D_ENDNUM_3: begin
			draw_n = 1'b1;
			num_id = 4'd9;
				id = 4'd10;
			m = 1'b0;
		end
		D_ENDNUM_4: begin
			draw_n = 1'b1;
			num_id = 4'd10;
				id = 4'd11;
			m = 1'b0;
		end
		
		ENDWAIT: begin
			compare = 1'b1;
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
    input resetn, restart,
	 input valid,
	 input [7:0]outCode,
    input draw_mole, draw_hammer, erase, clear, update, m, draw_n, clear_end, compare,
    input [1:0]mole_id,
    input [3:0] h,id,
	 input [3:0] num_id,
    input [19:0] segment_0,segment_1,segment_2,segment_3,segment_4, segment_5, segment_h1, segment_h2,
    output reg [7:0] x, //the exact position of pixel to be drawn
    output reg [6:0] y,
    output reg move,
    output reg [2:0]rgb,
    output reg [7:0]score,
	 output reg [7:0]highscore
    );
    
    reg [7:0] x_counter; //for bg
    reg [6:0] y_counter;
    reg [7:0] counter;  //counter for drawing a mole/hammer/erase


    reg [19:0] seq_20;
    reg [7:0] x_posi;
    reg [6:0] y_posi;
    reg [7:0] mole_1, mole_2, mole_3, mole_4; //y position of moles
    reg [3:0] score_reg;
    reg [3:0] hammer, hammer_to_draw, hammer_up, h_state;

    reg [31:0] sequence1, sequence2, sequence3, sequence4;
    reg [3:0] direction;
	 reg [4:0] i;

    localparam  M_X_1 = 8'd19, // 1st mole
		M_X_2 = 8'd43, // 2nd mole 
		M_X_3 = 8'd67, // 3rd mole 
		M_X_4 = 8'd91, // 4th mole 
		M_Y_S = 7'd59, // starting position of mole
		M_Y_E = 7'd51, // ending position of mole
		M_Y_H = 7'd45, // y position of hammer
		M_Y_H_2 = 7'd48, // y position of hammer
 		S1 = 24'b110000111100101100110000,
		S2 = 24'b110011000110011110110011,
		S3 = 24'b000110011011000111001100,
		S4 = 24'b001101100110110011011011,
		NUM_Y = 7'd13,
		END_NUM_Y_1 = 7'd45,
		END_NUM_Y_2 = 7'd59,
		NUM_X_1 = 8'd32,
		NUM_X_2 = 8'd38,
		NUM_X_3 = 8'd74,
		NUM_X_4 = 8'd80,
		NUM_X_5 = 8'd86,
		NUM_X_6 = 8'd134,
		END_NUM_X_1 = 8'd95,
		END_NUM_X_2 = 8'd101;

   // update x_posi of mole or num

   always @(*) begin
	case (id)
	  4'd0: x_posi = M_X_1;
	  4'd1: x_posi = M_X_2;
	  4'd2: x_posi = M_X_3;
	  4'd3: x_posi = M_X_4;
	  4'd4: x_posi = NUM_X_1;
	  4'd5: x_posi = NUM_X_2;
	  4'd6: x_posi = NUM_X_3;
	  4'd7: x_posi = NUM_X_4;
	  4'd8: x_posi = NUM_X_5;
	  4'd9: x_posi = NUM_X_6;
	  4'd10: x_posi = END_NUM_X_1;
	  4'd11: x_posi = END_NUM_X_2;
     default: x_posi = M_X_1;
	endcase
   end


  
	always @(*)begin
		case (num_id)
			4'd1: seq_20 = segment_0;
			4'd2: seq_20 = segment_1;
			4'd3: seq_20 = segment_2;
			4'd4: seq_20 = segment_3;
			4'd5: seq_20 = segment_4;
			4'd6: seq_20 = segment_5;
			4'd7: seq_20 = segment_0;
			4'd8: seq_20 = segment_1;
			4'd9: seq_20 = segment_h1;
			4'd10: seq_20 = segment_h2;
			default: seq_20 = segment_0;
	  endcase
	end


   always @(*) begin
	if(draw_hammer)begin
	   if (h_state[mole_id] ==0)begin
	   	y_posi = M_Y_H;		
	   end
	   else begin
	   	y_posi = M_Y_H_2;
	   end
	end
		
	else if (erase) begin
			y_posi = M_Y_H;
	end
	else if (draw_n) begin
		  case (num_id)
			4'd7:y_posi = END_NUM_Y_1;
			4'd8:y_posi = END_NUM_Y_1;
			4'd9: y_posi = END_NUM_Y_2;
			4'd10: y_posi = END_NUM_Y_2;
			default: y_posi = NUM_Y;
		  endcase
		  end
	
    else if(draw_mole) begin
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
		
		
	
    always @ (posedge clk) begin
        if (resetn == 0) begin
	    x <= 8'd0; 		//output to vga
	    y <= 7'd0;	 	//output to vga
       move <= 1'b0;  	// signal that returns to controler to move to next state
	    rgb <= 3'd0;
	    score <= 8'd0;
		 highscore <= 8'd0;
	    
	    x_counter <= 8'd0; //for bg
 	    y_counter <= 7'd25;
    	   counter <= 8'd0;  //8*8 or 8*8*3 counter
		 
		 i <= 5'd0;

       mole_1 <= M_Y_S;
 	    mole_2 <= M_Y_S;
	    mole_3 <= M_Y_S;
	    mole_4 <= M_Y_S;
	    
	    hammer <= 4'b0000;
	    hammer_to_draw <= 4'b0000;
		 hammer_up <= 4'b0000;
		 h_state <= 4'b0000;
	    score_reg <= 4'b0000;

	    sequence1 <= S1;
	    sequence2 <= S2;
	    sequence3 <= S3;
	    sequence4 <= S4;
	    direction <= 4'b0000;
        end
		  
		 if(restart == 0) begin
	    x <= 8'd0;		
	    y <= 7'd0;	
       move <= 1'b0; 
	    rgb <= 3'd0;
	    score <= 8'd0;  
	    
	    x_counter <= 8'd0; //for bg
 	    y_counter <= 7'd25;
    	   counter <= 8'd0;  //8*8 or 8*8*3 counter
		 
		 i <= 5'd0;

       mole_1 <= M_Y_S;
 	    mole_2 <= M_Y_S;
	    mole_3 <= M_Y_S;
	    mole_4 <= M_Y_S;
	    
	    hammer <= 4'b0000;
	    hammer_to_draw <= 4'b0000;
		 hammer_up <= 4'b0000;
		 h_state <= 4'b0000;
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
		 
		 if(compare) begin
		     if(score > highscore) begin
					highscore <= score;
				end
			end

	    if (update)begin  // update info
		   x_counter <= 8'd0; 
 	      y_counter <= 7'd25;
		   
			move <= 1'b0;
	    	hammer_to_draw <= hammer;
			hammer <= 4'd0;
			hammer_up <= hammer_to_draw;
			score <= score + score_reg[0] + score_reg[1] + score_reg[2] + score_reg[3];
			score_reg <= 4'd0;


		//update direction
		if(mole_1 == M_Y_S)begin
			direction[0] <= sequence1[23];
			sequence1 <= {sequence1[22 : 0], sequence1[23]};
		end
		else begin
			if(mole_1 == M_Y_E)
			    direction[0] <= 1'b0;
		end
		if(mole_2 == M_Y_S)begin
			direction[1] <= sequence2[23];
			sequence2 <= {sequence2[22 : 0], sequence2[23]};
		end
		else begin
			if(mole_2 == M_Y_E)
			    direction[1] <= 1'b0;
		end
		if(mole_3 == M_Y_S)begin
			direction[2] <= sequence3[23];
			sequence3 <= {sequence3[22 : 0], sequence3[23]};
		end
		else begin
			if(mole_3 == M_Y_E)
			    direction[2] <= 1'b0;
		end
		if(mole_4 == M_Y_S)begin
			direction[3] <= sequence4[23];
			sequence4 <= {sequence4[22 : 0], sequence4[23]};
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
	
		if(hammer_up[0] == 1) begin
			h_state[0] = 1'b1;
		end else h_state[0] = 1'b0;
		
		if(hammer_up[1] == 1) begin
			h_state[1] = 1'b1;
		end else h_state[1] = 1'b0;
		
	   if(hammer_up[2] == 1) begin
			h_state[2] = 1'b1;
		end else h_state[2] = 1'b0;
		
		if(hammer_up[3] == 1) begin
			h_state[3] = 1'b1;
		end else h_state[3] = 1'b0;
		end
	   
		
		if(update == 0)begin
			if(valid == 1 && outCode[7:0] == 8'h1b) begin
				hammer[0] <= 1'b1;
				if(mole_1 == 7'd51 || (mole_1 == 7'd52 && direction[0] == 1)) 
					score_reg[0] <= 1'b1;
	    	end
	    	if(valid == 1 && outCode[7:0] == 8'h23) begin
				hammer[1] <= 1'b1;
				if(mole_2 == 7'd51 || (mole_2 == 7'd52 && direction[1] == 1))
					score_reg[1] <= 1'b1;
	    	end
	    	if(valid == 1 && outCode[7:0] == 8'h2b) begin
				hammer[2] <= 1'b1;
				if(mole_3 == 7'd51 || (mole_3 == 7'd52 && direction[2] == 1))
					score_reg[2] <= 1'b1;
	    	end
	    	if(valid == 1 && outCode[7:0] == 8'h34) begin
				hammer[3] <= 1'b1;
				if(mole_4 == 7'd51 || (mole_4 == 7'd52 && direction[3] == 1))
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
			y_counter <= 7'd25;
			move <= 1'b1;
		end

		x<= x_counter;
		y<= y_counter;
	
	    end
		 
		
		if(clear_end) begin
		if (y_counter < 76) begin// between sky
			rgb <= 3'b111; //set base color to white
			if (y_counter == 28)begin
				rgb<= 3'b111;
				if ( x_counter >54 &&  x_counter <59)begin
					rgb <= 3'b000;
				end
				if ( x_counter ==61 || x_counter ==62 || x_counter ==69 || x_counter ==70|| x_counter ==74|| x_counter ==75|| x_counter ==87|| x_counter ==91)begin
					rgb <= 3'b000;
				end
				if ( x_counter ==65|| x_counter ==66 ||x_counter ==67 ||x_counter ==94 ||x_counter ==95 ||x_counter ==98 ||x_counter ==100 )begin
					rgb <= 3'b000;
				end
				if ( x_counter >81 &&  x_counter <85)begin
					rgb <= 3'b000;
				end
			end 
			if (y_counter == 29)begin
				if ( x_counter ==54 ||  x_counter ==58 ||  x_counter ==63)begin
					rgb <= 3'b000;
				end
				if ( x_counter ==71 || x_counter ==73 || x_counter ==76 || x_counter ==81|| x_counter ==85|| x_counter ==88|| x_counter ==90|| x_counter ==93)begin
					rgb <= 3'b000;
				end
				if ( x_counter ==65|| x_counter ==68 ||x_counter ==96 ||x_counter ==98 ||x_counter ==99 )begin
					rgb <= 3'b000;
				end
			end 
			if (y_counter == 30)begin
				if ( x_counter ==54 ||  x_counter ==58 ||  x_counter ==63 ||x_counter ==61 || x_counter ==62||x_counter ==74 || x_counter ==75)begin
					rgb <= 3'b000;
				end
				if ( x_counter ==71 || x_counter ==73 || x_counter ==76 || x_counter ==81|| x_counter ==85|| x_counter ==88|| x_counter ==90|| x_counter ==93)begin
					rgb <= 3'b000;
				end
				if ( x_counter ==65|| x_counter ==68  ||x_counter ==98 ||x_counter ==94 ||x_counter ==95)begin
					rgb <= 3'b000;
				end
			end 
			if (y_counter == 31)begin
				if ( x_counter ==54 ||  x_counter ==58 ||  x_counter ==63 ||x_counter ==60)begin
					rgb <= 3'b000;
				end
				if ( x_counter ==71 || x_counter ==73 || x_counter ==81|| x_counter ==85|| x_counter ==88|| x_counter ==90|| x_counter ==93)begin
					rgb <= 3'b000;
				end
				if ( x_counter ==65|| x_counter ==68 ||x_counter ==96 ||x_counter ==98  )begin
					rgb <= 3'b000;
				end
			end 
			if (y_counter == 32)begin
				if ( x_counter >54 &&  x_counter <59)begin
					rgb <= 3'b000;
				end
				if ( x_counter >60 &&  x_counter <64)begin
					rgb <= 3'b000;
				end
				if ( x_counter ==71 || x_counter ==74 || x_counter ==74|| x_counter ==75|| x_counter ==76|| x_counter ==89|| x_counter ==94)begin
					rgb <= 3'b000;
				end
				if ( x_counter ==65|| x_counter ==68 ||x_counter ==82 ||x_counter ==83|| x_counter ==84 ||x_counter ==96 ||x_counter ==98 ||x_counter ==95)begin
					rgb <= 3'b000;
				end
			end 
			if (y_counter == 33 && x_counter == 58)begin
					rgb <= 3'b000;
			end
			if (y_counter == 34)begin
				if ( x_counter >54 &&  x_counter <58)begin
					rgb <= 3'b000;
				end
			end  
			if (y_counter == 45)begin
				if ( x_counter >48 &&  x_counter <52)begin
					rgb <= 3'b000;
				end
				if ( x_counter ==42 || x_counter ==46 || x_counter ==54|| x_counter ==58|| x_counter ==60|| x_counter ==62)begin
					rgb <= 3'b000;
				end
			//----------------------------------------------------------------------------------------------------------------------
				if ( x_counter >66 &&  x_counter <70)begin
					rgb <= 3'b000;
				end
				if ( x_counter >71 &&  x_counter <75)begin
					rgb <= 3'b000;
				end
				if ( x_counter >76 &&  x_counter <80)begin
					rgb <= 3'b000;
				end
				if ( x_counter ==82|| x_counter ==84 ||x_counter ==87 ||x_counter ==88|| x_counter ==92)begin
					rgb <= 3'b000;
				end
			end 
			if (y_counter == 46)begin
				if ( x_counter ==43 || x_counter ==45 || x_counter ==48|| x_counter ==52|| x_counter ==54|| x_counter ==58|| x_counter ==60|| x_counter ==61 )begin
					rgb <= 3'b000;
				end
			//----------------------------------------------------------------------------------------------------------------------
				if ( x_counter ==86 ||  x_counter ==89 || x_counter ==92)begin
					rgb <= 3'b000;
				end
				if ( x_counter ==67|| x_counter ==71 ||x_counter ==76 ||x_counter ==80|| x_counter ==82|| x_counter ==83)begin
					rgb <= 3'b000;
				end
			end 	
			if (y_counter == 47)begin
				if ( x_counter ==43 || x_counter ==45 || x_counter ==48|| x_counter ==52|| x_counter ==54|| x_counter ==58|| x_counter ==60)begin
					rgb <= 3'b000;
				end
			//----------------------------------------------------------------------------------------------------------------------
				if ( x_counter ==86 ||  x_counter ==89 || x_counter ==87 || x_counter ==88)begin
					rgb <= 3'b000;
				end
				if ( x_counter ==68|| x_counter ==71 ||x_counter ==76 ||x_counter ==80|| x_counter ==82)begin
					rgb <= 3'b000;
				end
			end 		
			if (y_counter == 48)begin
				if ( x_counter ==43 || x_counter ==45 || x_counter ==48|| x_counter ==52|| x_counter ==54|| x_counter ==58|| x_counter ==60)begin
					rgb <= 3'b000;
				end
			//----------------------------------------------------------------------------------------------------------------------
				if ( x_counter ==86 ||  x_counter ==92)begin
					rgb <= 3'b000;
				end
				if ( x_counter ==69|| x_counter ==71 ||x_counter ==76 ||x_counter ==80|| x_counter ==82)begin
					rgb <= 3'b000;
				end
			end 		
			if (y_counter == 49)begin
				if ( x_counter >54 &&  x_counter <59)begin
					rgb <= 3'b000;
				end
				if ( x_counter ==44 || x_counter ==49 || x_counter ==50|| x_counter ==51|| x_counter ==60)begin
					rgb <= 3'b000;
				end
			//----------------------------------------------------------------------------------------------------------------------
				if ( x_counter >71 &&  x_counter <75)begin
					rgb <= 3'b000;
				end
				if ( x_counter >66 &&  x_counter <70)begin
					rgb <= 3'b000;
				end
				if ( x_counter >76 &&  x_counter <80)begin
					rgb <= 3'b000;
				end
				if ( x_counter ==82 ||  x_counter ==87 ||  x_counter ==88||  x_counter ==89||  x_counter ==92)begin
					rgb <= 3'b000;
				end
			end 	
			if (y_counter == 50 && x_counter == 44)begin
					rgb <= 3'b000;
			end 	
			if (y_counter == 51 && x_counter == 43)begin
					rgb <= 3'b000;
			end 	
			if (y_counter == 56)begin
				if ( x_counter ==32 || x_counter ==46)begin
					rgb <= 3'b000;
				end
			end 	
			if (y_counter == 57)begin
				if ( x_counter ==32 || x_counter ==46 ||x_counter ==38 || x_counter ==61)begin
					rgb <= 3'b000;
				end
			end 	
			if (y_counter == 58)begin
				if ( x_counter ==32 || x_counter ==46 || x_counter ==61)begin
					rgb <= 3'b000;
				end
			end 
			if (y_counter == 59)begin
				if ( x_counter >31 &&  x_counter <36)begin
					rgb <= 3'b000;
				end
				if ( x_counter >40 &&  x_counter <45)begin
					rgb <= 3'b000;
				end
				if ( x_counter >45 &&  x_counter <50)begin
					rgb <= 3'b000;
				end
				if ( x_counter >56 &&  x_counter <60)begin
					rgb <= 3'b000;
				end
				if ( x_counter ==38 || x_counter ==53 || x_counter ==54|| x_counter ==61|| x_counter ==62)begin
					rgb <= 3'b000;
				end
			//----------------------------------------------------------------------------------------------------------------------
				if ( x_counter >66 &&  x_counter <70)begin
					rgb <= 3'b000;
				end
				if ( x_counter >71 &&  x_counter <75)begin
					rgb <= 3'b000;
				end
				if ( x_counter >76 &&  x_counter <80)begin
					rgb <= 3'b000;
				end
				if ( x_counter ==82|| x_counter ==84 ||x_counter ==87 ||x_counter ==88|| x_counter ==92)begin
					rgb <= 3'b000;
				end
			end 
			if (y_counter == 60)begin
				if ( x_counter ==32 || x_counter ==36 || x_counter ==38|| x_counter ==40|| x_counter ==44)begin
					rgb <= 3'b000;
				end
				if ( x_counter ==46 || x_counter ==50 || x_counter ==52|| x_counter ==55|| x_counter ==57 || x_counter ==61)begin
					rgb <= 3'b000;
				end
			//----------------------------------------------------------------------------------------------------------------------
				if ( x_counter ==86 ||  x_counter ==89 || x_counter ==92)begin
					rgb <= 3'b000;
				end
				if ( x_counter ==67|| x_counter ==71 ||x_counter ==76 ||x_counter ==80|| x_counter ==82|| x_counter ==83)begin
					rgb <= 3'b000;
				end
			end 	
			if (y_counter == 61)begin
				if ( x_counter ==32 || x_counter ==36 || x_counter ==38|| x_counter ==40|| x_counter ==44|| x_counter ==53|| x_counter ==54)begin
					rgb <= 3'b000;
				end
				if ( x_counter ==46 || x_counter ==50 || x_counter ==52|| x_counter ==55|| x_counter ==58 || x_counter ==61)begin
					rgb <= 3'b000;
				end
			//----------------------------------------------------------------------------------------------------------------------
				if ( x_counter ==86 ||  x_counter ==89 || x_counter ==87 || x_counter ==88)begin
					rgb <= 3'b000;
				end
				if ( x_counter ==68|| x_counter ==71 ||x_counter ==76 ||x_counter ==80|| x_counter ==82)begin
					rgb <= 3'b000;
				end
			end 		
			if (y_counter == 62)begin
				if ( x_counter ==32 || x_counter ==36 || x_counter ==38|| x_counter ==40|| x_counter ==44)begin
					rgb <= 3'b000;
				end
				if ( x_counter ==46 || x_counter ==50 || x_counter ==52|| x_counter ==59 || x_counter ==61)begin
					rgb <= 3'b000;
				end
			//----------------------------------------------------------------------------------------------------------------------
				if ( x_counter ==86 ||  x_counter ==92)begin
					rgb <= 3'b000;
				end
				if ( x_counter ==69|| x_counter ==71 ||x_counter ==76 ||x_counter ==80|| x_counter ==82)begin
					rgb <= 3'b000;
				end
			end 		
			if (y_counter == 63)begin
				if ( x_counter ==32 || x_counter ==36 || x_counter ==38|| x_counter ==41|| x_counter ==44|| x_counter ==42|| x_counter ==43)begin
					rgb <= 3'b000;
				end
				if ( x_counter >52 &&  x_counter <56)begin
					rgb <= 3'b000;
				end
				if ( x_counter >56 &&  x_counter <60)begin
					rgb <= 3'b000;
				end
				if ( x_counter ==46 || x_counter ==50 ||  x_counter ==59 || x_counter ==62)begin
					rgb <= 3'b000;
				end
			//----------------------------------------------------------------------------------------------------------------------
				if ( x_counter >71 &&  x_counter <75)begin
					rgb <= 3'b000;
				end
				if ( x_counter >66 &&  x_counter <70)begin
					rgb <= 3'b000;
				end
				if ( x_counter >76 &&  x_counter <80)begin
					rgb <= 3'b000;
				end
				if ( x_counter ==82 ||  x_counter ==87 ||  x_counter ==88||  x_counter ==89||  x_counter ==92)begin
					rgb <= 3'b000;
				end
			end 	
			if (y_counter == 64 && x_counter == 44)begin
					rgb <= 3'b000;
			end
			if (y_counter == 65)begin
				if ( x_counter >40 &&  x_counter <44)begin
					rgb <= 3'b000;
				end
			end


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
			y_counter <= 7'd25;
			move <= 1'b1;
		end

		x<= x_counter;
		y<= y_counter;
		
		

	    end
		 
		

	    if (draw_n) begin  // draw a number
	        if (counter[4:0] == 5'd19)begin
				move <= 1'b1;
				counter <= 8'd0;
				end
				
		i <= counter[4:0];
		
		if (seq_20[i] == 1'b1) begin
			rgb <= 3'b000;
		end else rgb<= 3'b111;
		
		counter <= counter +8'd1;
		x <= x_posi + counter[1:0];
		y <= y_posi + counter [4:2];	
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
	        if (counter[4:0] == 5'b11111)begin
				move <= 1'b1;
				counter <= 8'd0;
			end
				if(hammer_to_draw[mole_id] == 1'b1 || hammer_up[mole_id] == 1'b1) begin
				 rgb <= 3'b011; // set base color to cyan ; 101 pink
				//else rgb <= 3'b000;
				 if (counter[4:2] == 3'd4 || counter[4:2]==3'd5|| counter[4:2]==3'd6|| counter[4:2]==3'd7)begin
					if (counter[1:0] == 2'd0 || counter[1:0] == 2'd3)begin
						rgb <= 3'b111;
					end
					if (counter[1:0] == 2'd1 || counter[1:0] == 2'd2)begin
						rgb <= 3'b101;
					end
				end
				end else rgb <= 3'b111;
			
			
				counter <= counter +8'd1;
				x <= x_posi + counter[4:2];
				y <= y_posi + counter [1:0];
	    end
		 
	    
	    if(erase) begin
			if(counter[7:0] == 8'd159)begin
				move <= 1'b1;
				counter <= 8'd0;
			end
			if (counter[7:3] < 5'd16) begin//draw the sky
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

assign en = ((q == 833333) && enable) ? 1:0; //833333

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
input [5:0] frame;
output en;
reg [5:0]q;

assign en = ((q == frame) && enable) ? 1:0; //14

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



module number_display(digit, segments);
    input [3:0] digit;
    output reg [19:0] segments;
   
    always @(*)
        case (digit)
            4'd0: segments = 20'b0111_0101_0101_0101_0111;
            4'd1: segments = 20'b0100_0100_0100_0100_0100;
            4'd2: segments = 20'b0111_0001_0111_0100_0111;
            4'd3: segments = 20'b0111_0100_0111_0100_0111;
            4'd4: segments = 20'b0100_0100_0111_0101_0101;
            4'd5: segments = 20'b0111_0100_0111_0001_0111;
            4'd6: segments = 20'b0111_0101_0111_0001_0111;
            4'd7: segments = 20'b0100_0100_0100_0100_0111;
            4'd8: segments = 20'b0111_0101_0111_0101_0111;
            4'd9: segments = 20'b0111_0100_0111_0101_0111;
            default: segments = 20'b0111_0101_0101_0101_0111;
        endcase
endmodule




module number_top(CLOCK_50, resetn, restart, go, score, highscore, difficulty, finish, segment_0,segment_1,segment_2,segment_3,segment_4, segment_5, segment_h1, segment_h2);
	input CLOCK_50, resetn, restart, go;
	input [1:0] difficulty;
	input [7:0]score, highscore;
   output[19:0] segment_0,segment_1,segment_2,segment_3,segment_4, segment_5, segment_h1, segment_h2;
	output reg finish;
	reg [7:0] timer;
	reg watch;
	wire [3:0] decade, unit, minute, second1, second2, decade_h, unit_h;
	wire en, frame_en;
	

delaycounter t1(
	.clock(CLOCK_50), 
	.resetn(resetn), 
	.enable(watch), 
	.en(frame_en)
);

framecounter t2(
	.clock(CLOCK_50), 
	.resetn(resetn), 
	.frame(6'd59), 
	.enable(frame_en),
	.en(en)
);


number_display n0(
	.digit(decade),
	.segments(segment_0)
);

number_display n1(
	.digit(unit),
	.segments(segment_1)
);

number_display n2(
	.digit(minute),
	.segments(segment_2)
);

number_display n3(
	.digit(second1),
	.segments(segment_3)
);

number_display n4(
	.digit(second2),
	.segments(segment_4)
);

number_display n5(
	.digit({2'b00, difficulty[1:0]}),
	.segments(segment_5)
);


number_display h1(
	.digit(decade_h),
	.segments(segment_h1)
);

number_display h2(
	.digit(unit_h),
	.segments(segment_h2)
);


always @(posedge CLOCK_50) begin
	if(resetn == 0 || restart == 0) begin
		timer <= 30;
		finish <= 1'b0;
		watch <= 1'b0;
	end
	else begin
	   if(go == 1) begin
			watch <= 1'b1;
		end
		if(watch == 1)begin 
			if(timer == 0) begin
				timer <= 30;
				finish <= 1'b1;
				watch <= 1'b0;
			end
			else begin
				if(en == 1)
					timer <= timer - 1'b1;
			end
		end
	end
end
	
	

assign	 decade = score / 10;
assign	 unit = score % 10;
assign	 minute = timer / 60;
assign	 second1 = (timer % 60) / 10;
assign    second2 = (timer % 60) % 10;
assign	 decade_h = highscore / 10;
assign 	 unit_h = highscore % 10;
	
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







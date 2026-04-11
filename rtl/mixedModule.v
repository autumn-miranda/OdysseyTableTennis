module mixMod (
   input         clk,
	input         reset,
	
	input         pal,
	input         scandouble,
	
	//input [15:0] direct_x,  	//left joystick
	//input [15:0] direct_y, 	   //right joystick
	
	input [3:0] direct,  	//bit 0: right, bit 1: left, bit 2: down, bit 3: up
	input [3:0] direct2, 	//player two movement
	input [1:0] wallDirect,	//wall movement
	input [3:0] english,
	input [1:0] serve,
	input [15:0] joy0,
	input [15:0] joy1,
	

	output reg    ce_pix,

	output reg    HBlank,
	output reg    HSync,
	output reg    VBlank,
	output reg    VSync,
	
	output [7:0] r,
   output [7:0] g,
   output [7:0] b

	//output  [7:0] video
);
					
// 640x400 70HZ VESA according to  http://tinyvga.com/vga-timing/640x400@70Hz
parameter H   = 640;    // width of visible area
parameter HFP = 16;     // unused time before hsync
parameter HS  = 96;     // width of hsync
parameter HBP = 48;     // unused time after hsync

parameter V   = 400;    // height of visible area
parameter VFP = 12;     // unused time before vsync
parameter VS  = 2;      // width of vsync
parameter VBP = 35;     // unused time after vsync

					
reg   [9:0] hc;
reg   [9:0] vc;
reg   [9:0] vvc;
reg  [63:0] rnd_reg;

wire  [5:0] rnd_c = {rnd_reg[0],rnd_reg[1],rnd_reg[2],rnd_reg[2],rnd_reg[2],rnd_reg[2]};
wire [63:0] rnd;

lfsr random(rnd);

always @(posedge clk) begin
	if(scandouble) ce_pix <= 1;
		else ce_pix <= ~ce_pix;

	if(reset) begin
		hc <= 0;
		vc <= 0;
	end
	else if(ce_pix) begin
		if(hc == 637) begin
			hc <= 0;
			if(vc == (pal ? (scandouble ? 623 : 311) : (scandouble ? 523 : 261))) begin 
				vc <= 0;
				vvc <= vvc + 9'd6;
			end else begin
				vc <= vc + 1'd1;
			end
		end else begin
			hc <= hc + 1'd1;
		end

		rnd_reg <= rnd;
	end
end

always @(posedge clk) begin
	if (hc == 529) HBlank <= 1;
		else if (hc == 0) HBlank <= 0;

	if (hc == 544) begin
		HSync <= 1;

		if(pal) begin
			if(vc == (scandouble ? 609 : 304)) VSync <= 1;
				else if (vc == (scandouble ? 617 : 308)) VSync <= 0;

			if(vc == (scandouble ? 601 : 300)) VBlank <= 1;
				else if (vc == 0) VBlank <= 0;
		end
		else begin
			if(vc == (scandouble ? 490 : 245)) VSync <= 1;
				else if (vc == (scandouble ? 496 : 248)) VSync <= 0;

			if(vc == (scandouble ? 480 : 240)) VBlank <= 1;
				else if (vc == 0) VBlank <= 0;
		end
	end
	
	if (hc == 590) HSync <= 0;
end




// read VRAM
reg [7:0] video_counter;
reg [7:0] pixel;						//the color of the pixel
reg de;									//data enable, low on blanking periods
reg [3:0] blank = 4'b0000;			//this is just an empty register we can use  to zero out values

wire [3:0] pix_ena;					//each spot generator gets one bit in this wire
wire [2:0] col_ena;					//[1:0]player collisions  [2]wall collision

wire [3:0] ballDirect;				//bit 0: right, bit 1: left, bit 2: down, bit 3: up
wire [2:0] ballHold;					//[2]:up or down [1]:add speed [0]:subtract speed
wire [3:0] player_speed;			//p1=[1:0] p2=[3:2] even bits true if player is moving in any direction
											//otherwise odd bits(reset) is true
											
reg [1:0] prev;
reg [10:0] player1Width = 11'sd40;
reg [10:0] player1Height = 11'sd40;
reg [10:0] ballWidth = 11'sd20;
reg [10:0] ballHeight = 11'sd20;

reg [7:0] joydirect;  	//bit 0: right, bit 1: left, bit 2: down, bit 3: up

reg [7:0] x_val;
reg [7:0] y_val;

/*Player Spots*/
r_spot #(.START_X(11'sd100), .START_Y(11'sd100), .SPEED(5'sd2), .START_SPEED(5'sd2)) player1(
.pclk(clk),
.direct(joydirect[3:0]),
.h_direct(joy0[7:0]),
.v_direct(joy0[15:8]),
.vs(VSync),
.h_cnt({1'b0,hc[9:0]}),
.v_cnt({1'b0,vc[9:0]}),
.speed_enable({player_speed[0], player_speed[1]}),
.spot_enable(pix_ena[0]),
.reset(blank[1]),
.width(player1Width), 
.height(player1Height)
);

r_spot #(.START_X(11'sd390), .START_Y(11'sd100), .SPEED(5'sd2), .START_SPEED(5'sd2)) player2(
.pclk(clk),
.direct(joydirect[7:4]),
.h_direct(joy1[7:0]),
.v_direct(joy1[15:8]),
.vs(VSync),
.h_cnt({1'b0,hc[9:0]}),
.v_cnt({1'b0,vc[9:0]}),
.speed_enable({player_speed[2], player_speed[3]}),
.spot_enable(pix_ena[1]),
.reset(blank[1]),
.width({player1Width - 3'd5}), 
.height(player1Height)
);

/*WALL SPOT*/
r_spotGen #(.START_X(10'sd250), .START_Y(10'sd0) ) wall(
.pclk(clk),
.direct({2'b0, wallDirect}),
.vs(VSync),
.h_cnt({1'b0,hc[9:0]}),
.v_cnt({1'b0,vc[9:0]}),
.speed_enable(blank),
.spot_enable(pix_ena[2]),
.reset(blank[1]),
.width(ballWidth),
.height(10'd500)
);

/*BALL SPOT*/
r_spotGen #(.START_X(11'sd150), .START_Y(10'sd100), .START_SPEED(10'sd0)) ball(
.pclk(clk),
.direct(ballDirect),
.vs(VSync),
.h_cnt({1'b0, hc[9:0]}),
.v_cnt({1'b0,vc[9:0]}),
.speed_enable(ballHold[1:0]),
.spot_enable(pix_ena[3]),
.reset(serve[0] || serve[1]),
.width(ballWidth), 
.height(ballHeight)
);
//reset is used to reset the ball position for a serve

//works by comparing the enabled pixels
//serves are also counted as collisions
r_gateMatrix collisions(
.p1_col((pix_ena[0] && pix_ena[3]) || serve[0]),
.p2_col((pix_ena[1] && pix_ena[3]) || serve[1]),
.wall_col(pix_ena[2] && pix_ena[3]),

.ena_player(col_ena[1:0]),

.flip_v(ballHold[2])

);

//when collision switches flip it to the other 

englishFlipFlop englishFF(
.pclk(VSync),
.d({english, col_ena[1:0]}), 
.enable(col_ena[1:0]),
.direct(ballHold[2]),
.p(ballHold[1:0]),
.q(ballDirect)
);


/*playerSpeed player1speed(
	.vs(VSync),
	.direct(joydirect[3:0]),
	.speed_enable(player_speed[0]),
	.speed_reset(player_speed[1])
);

playerSpeed player2speed(
	.vs(VSync),
	.direct(joydirect[7:4]),
	.speed_enable(player_speed[2]),
	.speed_reset(player_speed[3])
);*/

joystick_direction p1direct(
	.joystick(joy0),
	.clk(clk),
	
	.direction(joydirect[3:0])
);

joystick_direction p2direct(
	.joystick(joy1),
	.clk(clk),
	
	.direction(joydirect[7:4])

);


//basically our summer module
always@(posedge clk) begin
	// visible area?	
	
	if(HBlank + VBlank == 0) //if within visible area
			video_counter = hc + vc;
			
			
	if(|pix_ena) 
		pixel <= 8'b111_111_11; 
	else pixel <= 8'h00; 
end

assign r = { pixel[7:5],   pixel[7:5],  pixel[7:6]};
assign g = { pixel[4:2],  pixel[4:2], pixel[4:3] };
assign b = { 4{pixel[1:0]}};


endmodule

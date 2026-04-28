
//===========================================================================
// Based on:
// A simple system-on-a-chip (SoC) for the MiST
// (c) 2015 Till Harbaum
//
//  Main module for a Magnavox Odyssey Table Tennis Core
//  Copyright (c) 2023-2026 Autumn Miranda
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//
//============================================================================


module TableTennis (
   input         clk,
	input         reset,
	
	input         pal,
	input         scandouble,
	
	
	input [3:0] direct,  	//bit 0: right, bit 1: left, bit 2: down, bit 3: up
	input [3:0] direct2, 	//player two movement
	input [1:0] wallDirect,	//wall movement
	input [3:0] english,
	input [1:0] serve,
	input [1:0] pos_reset,
	input [23:0] joy0,
	input [23:0] joy1,
	input [3:0] ballSpeed,
	

	output reg    ce_pix,

	output reg    HBlank,
	output reg    HSync,
	output reg    VBlank,
	output reg    VSync,
	
	output [7:0] r,
   output [7:0] g,
   output [7:0] b

);

					
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




reg [7:0] pixel;						//the color of the pixel
reg de;									//data enable, low on blanking periods
reg [3:0] blank = 4'b0000;			//this is just an empty register we can use  to zero out values

wire [3:0] pix_ena;					//each spot generator gets one bit in this wire
wire [1:0] col_ena;					//[1:0]player collisions

wire [3:0] ballDirect;				//bit 0: right, bit 1: left, bit 2: down, bit 3: up
wire [2:0] ballHold;					//[2]:up or down [1]:add speed [0]:subtract speed
wire [7:0] player_speed;			//p1=[1:0] p2=[3:2] even bits true if player is moving in any direction
wire [7:0] ballJoy;					//otherwise odd bits(reset) is true
wire [7:0] englishDirect;
											
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
.spot_enable(pix_ena[0]),
.reset(pos_reset[0]),
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
.spot_enable(pix_ena[1]),
.reset(pos_reset[1]),
.width({player1Width - 3'd5}), 
.height(player1Height)
);

/*WALL SPOT*/
r_spotGen #(.START_X(10'sd250), .START_Y(10'sd0), .START_SPEED(10'sd0) ) wall(
.pclk(clk),
.direct({2'b0, wallDirect}),
.v_direct({blank, blank[2:0]}),
.vs(VSync),
.h_cnt({1'b0,hc[9:0]}),
.v_cnt({1'b0,vc[9:0]}),
.speed_enable(blank),
.speed(5'd3),
.spot_enable(pix_ena[2]),
.screen_blank(blank[1:0]),
.reset(blank[1]),
.width(ballWidth),
.height(10'd500)
);

/*BALL SPOT*/
r_spotGen #(.START_X(11'sd150), .START_Y(10'sd100), .START_SPEED(10'sd0), .SPEED(10'sd2)) ball(
.pclk(clk),
.direct(ballDirect),
.v_direct(ballJoy),
.vs(VSync),
.h_cnt({1'b0, hc[9:0]}),
.v_cnt({1'b0,vc[9:0]}),
.speed_enable(ballHold[1:0]),
.speed(ballSpeed),
.spot_enable(pix_ena[3]),
.screen_blank({VBlank, HBlank}),
.reset(serve[0] || serve[1]),
.width(ballWidth), 
.height(ballHeight)
);
//reset is used to reset the ball position for a serve


r_collisions collisions(
.p1_col((pix_ena[0] && pix_ena[3]) || serve[0]),
.p2_col((pix_ena[1] && pix_ena[3]) || serve[1]),

.ena_player(col_ena[1:0]),
.flip_v(ballHold[2])
);


/*englishFlipFlop englishFF(
.pclk(VSync),
.d({english, col_ena[1:0]}), 
.enable(col_ena[1:0]),
.direct(ballHold[2]),
.p(ballHold[1:0]),
.q(ballDirect)
);*/

r_englishFlipFlop englishFF(
.pclk(VSync),
.d_enable(english),
.eng_direct(englishDirect), 
.enable(col_ena[1:0]),
.p1_joy(joy0[23:8]),
.p2_joy(joy1[23:8]),
.p(ballDirect),
.q(ballJoy)
);




joystick_direction p1direct(
	.joystick(joy0),
	.block_enable(english[1:0]),
	.clk(clk),
	
	.direction(joydirect[3:0])
);

joystick_direction p2direct(
	.joystick(joy1),
	.block_enable(english[3:2]),
	.clk(clk),
	
	.direction(joydirect[7:4])

);

joystick_direction p1english(
	.joystick(joy0[23:8]),
	.block_enable(blank[3:2]),
	.clk(clk),
	
	.direction(englishDirect[3:0])
);


joystick_direction p2english(
	.joystick(joy1[23:8]),
	.block_enable(blank[1:0]),
	.clk(clk),
	
	.direction(englishDirect[7:4])

);

always@(posedge clk) begin
	if(|pix_ena) 
		pixel <= 8'b111_111_11; 
	else pixel <= 8'h00; 
end

assign r = { pixel[7:5],   pixel[7:5],  pixel[7:6]};
assign g = { pixel[4:2],  pixel[4:2], pixel[4:3] };
assign b = { 4{pixel[1:0]}};


endmodule

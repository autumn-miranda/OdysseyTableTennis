//============================================================================
//  Odyssey card revised modules
//  Copyright (c) 2023-2026 Autumn Miranda
//
//  The modules are loosely based on the description of the Odyssey's hardware from
//  https://www.odysseynow.org/Hardware.html
//  And from observations of the original system's behavior
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

      /*Wall and ball spot generator*/
module r_spotGen #(START_X = 10'sd0, START_Y = 10'sd0, SPEED = 5'sd1, START_SPEED = 10'sd1)
(
input pclk,
input [3:0] direct,
input [7:0] v_direct,
input vs,
input [10:0] h_cnt,
input [10:0] v_cnt,
input [2:0] speed_enable,			//0:decrease speed, 1: increase speed, 2: reset
input [3:0] speed,
input [1:0] screen_blank,
input reset,
input wire [10:0] width, height, 

output reg spot_enable

);

/*My variables*/
reg signed [10:0] h_move = START_X; 
reg signed [10:0] v_move = START_Y; 

reg signed [10:0] speed_v = START_SPEED;
reg signed [10:0] speed_h = SPEED;
reg [7:0] speedCounter = 8'b0;


always@(posedge vs) begin
	speed_h <= speed;

	if($signed(v_direct[7:0]) < -8'sd20)
			speed_v <= (($signed(v_direct[7:0]) * -8'sd1) >> 8'd4) | 8'd2;
		else if($signed(v_direct[7:0]) > 20)
			speed_v <= (v_direct[7:0] >> 8'd4) | 8'd2;
		else 
			speed_v <= 0;
			
			
	
	if(direct[0] == 1'b1 && h_move <= 11'sd590) h_move <= (h_move + speed_h);    //right
	if(direct[1] == 1'b1 && h_move >= -11'sd100) h_move <= (h_move - speed_h);  //left

	if(direct[2] == 1'b1 && v_move <= 11'sd500) v_move <= (v_move + speed_v);    //down
	if(direct[3] == 1'b1 && v_move >= -11'sd100) v_move <= (v_move - speed_v);  //up
	
	
	//reset is currently only used for the ball, not the wall
	if(reset) begin
		if(v_move >= 11'sd400 || v_move <= -11'sd50) begin	//off the top or bottom of screen
				v_move <= 11'd100;
			if (h_move >= 11'sd590 || h_move <= -11'sd50) begin // off the side of screen
				//reset speed back to one if it's higher, otherwise stay the same
				speed_v <= (speed_v[9:0] >= 10'sd2)? 11'sd1: speed_v;
			end
			else begin
				h_move <= (direct[0])? 11'sd590: -11'sd50;//go to side of screen if in the middle
				speed_v <= (speed_v[9:0] >= 10'sd2)? 11'sd1: speed_v;
			end
		end
	end
	
end
	 
always @(posedge pclk) begin 
	if(($signed(v_cnt) >= v_move) && $signed(v_cnt) <= $signed(height + v_move)) begin
			if(($signed(h_cnt) >= h_move) && ($signed(h_cnt) <= $signed(width + h_move))) begin
				spot_enable <= 1; 
			end
			else spot_enable <= 0;
	end
	else begin
		spot_enable <= 0;
	end
	
end


endmodule





      /*player spot generator*/
module r_spot #(START_X = 10'sd0, START_Y = 10'sd0, SPEED = 5'sd1, START_SPEED = 10'sd0)
(
input pclk,
input [3:0] direct,
input [7:0] h_direct,
input [7:0] v_direct,
input vs,
input [10:0] h_cnt,
input [10:0] v_cnt,
input reset,
input wire [10:0] width, height, 

output reg spot_enable

);

/*My variables*/
reg signed [10:0] h_move = START_X; 
reg signed [10:0] v_move = START_Y; 

reg signed [10:0] speed_v = START_SPEED;
reg signed [10:0] speed_h = START_SPEED;


always@(posedge vs) begin

	if($signed(h_direct[7:0]) < -20)
		speed_h <= (($signed(h_direct[7:0]) * -8'sd1) >> 8'd4) | 8'd2;
	else if($signed(h_direct[7:0]) > 20)
		speed_h <= (h_direct[7:0] >> 8'd4) | 8'd2;
	else 
		speed_h <= 0;
		
	
		
	if($signed(v_direct[7:0]) < -20)
			speed_v <= (($signed(v_direct[7:0]) * -8'sd1) >> 8'd4) | 8'd2;
		else if($signed(v_direct[7:0]) > 20)
			speed_v <= (v_direct[7:0] >> 8'd4) | 8'd2;
		else 
			speed_v <= (speed_v > 0)? speed_v - 1: 0;

		
	
	if(direct[0] == 1'b1 && h_move <= 11'sd590) h_move <= (h_move + speed_h);    //right
	if(direct[1] == 1'b1 && h_move >= -11'sd100) h_move <= (h_move - speed_h);  //left

	if(direct[2] == 1'b1 && v_move <= 11'sd500) v_move <= (v_move + speed_v);    //down
	if(direct[3] == 1'b1 && v_move >= -11'sd100) v_move <= (v_move - speed_v);  //up
	
	
	if(reset) begin
		h_move <= START_X;
		v_move <= START_Y;
	end
	
end
	 
always @(posedge pclk) begin 
	if(($signed(v_cnt) >= v_move) && $signed(v_cnt) <= $signed(v_move + height)) begin
			if(($signed(h_cnt) >= h_move) && $signed(h_cnt) <= $signed(h_move + width)) begin
				spot_enable <= 1; 
			end
			else spot_enable <= 0;
	end
	else begin
		spot_enable <= 0;
	end
	
end


endmodule





module joystick_direction
(
	input [15:0] joystick,
	input [1:0] block_enable,
	input clk,
	
	output reg [3:0] direction
);
always@(posedge clk) begin
	direction[0] <= (block_enable[1])? 0: ($signed(joystick[7:0]) > 20)? 1: 0;
	direction[1] <= (block_enable[1])? 0: ($signed(joystick[7:0]) < -20)? 1: 0;
	direction[2] <= (block_enable[0])? 0: ($signed(joystick[15:8]) > 20)? 1: 0;
	direction[3] <= (block_enable[0])? 0: ($signed(joystick[15:8]) < -20)? 1: 0;

end
endmodule




module r_collisions(
input p1_col,
input p2_col,

output reg [1:0] ena_player,
output reg flip_v
);

//collisions are dealt with only when either collision is High (true)
//otherwise they are ignored
always@(posedge p1_col, posedge p2_col) begin
	//check collision based on whether it last happened with p1 or p2
	//ex. can't collide with p1 again until p2 has been collided with
	ena_player[0] <= (p2_col)? 1'b0: 1'b1;
	ena_player[1] <= (p1_col)? 1'b0: 1'b1;
	
	flip_v = (p1_col)? 1'b1: 1'b0;//flip the vdirection of the ball after a collision
end


endmodule



//enable is collision
/*English flip flop - controls ball direction and which player has the english control*/
module r_englishFlipFlop(
input pclk,
input [3:0] d_enable, 
input [7:0] eng_direct,
input [1:0] enable,
input [15:0] p1_joy,
input [15:0] p2_joy,
input direct,
output reg [3:0] p,
output reg [7:0] q
);
	//d is the joystick controls for the english and the player/ball collision
	always@(d_enable, enable) begin
		
		p[1:0] <= enable;
		
		if(enable[0]) begin
			if(d_enable[0]) begin
				q <= p1_joy[7:0];
				p[3:2] <= eng_direct[3:2]; 
			end
				
			else if(d_enable[1]) begin
				q <= p1_joy[15:8];				
				p[3:2] <= eng_direct[1:0];
			end
			
			else begin
				q <= 8'd0;
				p[3:2] <= eng_direct[3:2];
			end
		end
		
		if(enable[1]) begin	
			if(d_enable[2]) begin
				q <= p2_joy[7:0];
				p[3:2] <= eng_direct[7:6];
			end
			
			else if(d_enable[3]) begin
				q <= p2_joy[15:8];
				p[3:2] <= eng_direct[5:4];	
			end
				
			else begin
				q <= 8'd0;
				p[3:2] <= eng_direct[7:6];
			end
		end
		
	end
	
endmodule
//p[1:0] - up, down
//p[3:2] - left, right




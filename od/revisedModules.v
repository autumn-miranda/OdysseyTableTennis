//============================================================================
//  Odyssey card modules
//  Copyright (c) 2023 Autumn
//
//  The modules are loosely based on the description of the Odyssey's hardware from
//  https://www.odysseynow.org/Hardware.html
//============================================================================

      /*Wall, ball, and Player genterator*/
		//parameters are the default values that the code is set up with. 
		//can be overwritten in instatiation
module r_spotGen #(START_X = 10'sd0, START_Y = 10'sd0, SPEED = 5'sd1, START_SPEED = 10'sd1)
(
input pclk,
input [3:0] direct,
input vs,
input [10:0] h_cnt,
input [10:0] v_cnt,
input [2:0] speed_enable,			//0:decrease speed, 1: increase speed, 2: reset
input reset,
input wire [10:0] width, height, 

output reg spot_enable

);

/*My variables*/
reg signed [10:0] h_move = START_X; //x position of the spot
reg signed [10:0] v_move = START_Y; //y position of the spot

reg signed [10:0] speed_v = START_SPEED;
reg signed [10:0] speed_h = SPEED;
reg [7:0] speedCounter = 8'b0;

always@(speed_v) begin
//What's with the size difference
//set horizontal move speed based on the vertical speed.
//This is mostly so that movement looks nicer and goes a bit slower
	speed_h <= (speed_v <= 10'sd2 || speed_v >= -10'sd2)? 5'sd2: SPEED;
end

always@(posedge vs) begin
	//I didn't want to increse the speed every vsync because then it moves too fast
	//the speed counter counts to 70
	speedCounter <= (speedCounter < 8'b01000110)?(speedCounter + 1'b1): 8'b0;
	//if the counter ends in 101, calc speed
	//3'b101 starts at 5 and is true every 8 vs
	if(speedCounter[2:0] == 3'b101) begin
	//currently 5 and -5 are the bounds of the speed.
	//so it doesn't get too fast
		if(speed_enable[1] && speed_v < 11'sd5) speed_v <= speed_v+SPEED;
		if(speed_enable[0] && speed_v > -11'sd5) speed_v <= speed_v-SPEED;
		if(speed_enable[2]) speed_v <= SPEED;
	end
	
	//if the direction key is being pressed and you aren't offscreen, move
	//I'm wondering if the arithmetic messes up eventually
	//since the game breaks if its left on too long
	if(direct[0] == 1'b1 && h_move <= 11'sd740) h_move <= (h_move + speed_h);    //right
	if(direct[1] == 1'b1 && h_move >= -11'sd200) h_move <= (h_move - speed_h);  //left

	if(direct[2] == 1'b1 && v_move <= 11'sd600) v_move <= (v_move + speed_v);    //down
	if(direct[3] == 1'b1 && v_move >= -11'sd200) v_move <= (v_move - speed_v);  //up
	
	
	//reset is currently only used for the ball
	if(reset) begin
		if(v_move >= 11'sd400 || v_move <= -11'sd50) begin	//off the top or bottom of screen
			if (h_move >= 11'sd640 || h_move <= -11'sd50) begin // off the side of screen
				v_move <= 11'd200;
				//reset speed back to one if it's higher, otherwise stay the same
				//what's with the size differences
				speed_v <= (speed_v[9:0] >= 10'sd2)? 11'sd1: speed_v;
				//i might have been trying to take the absolute value of speed_v but thats wrong
			end
			else begin
				h_move <= (h_move >= 11'sd300)? 11'sd640: -11'sd50;//go to side of screen if in the middle
				v_move <= 11'd200;
				speed_v <= (speed_v[9:0] >= 10'sd2)? 11'sd1: speed_v;
			end
		end
	end
	
end
	 
always @(posedge pclk) begin 
	//enable if in bounds of screen, otherwise do not
	//I think there should be a better way to determine this
	//verilog prefers unsigned numbers
	//if(vs) spot_enable <= 0;
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






module r_spot #(START_X = 10'sd0, START_Y = 10'sd0, SPEED = 5'sd1, START_SPEED = 10'sd0)
(
input pclk,
input [3:0] direct,
input vs,
input [10:0] h_cnt,
input [10:0] v_cnt,
input [2:0] speed_enable,			//0:decrease speed, 1: increase speed, 2: reset
input reset,
input wire [10:0] width, height, 

output reg spot_enable

);

/*My variables*/
reg signed [10:0] h_move = START_X; //x position of the spot
reg signed [10:0] v_move = START_Y; //y position of the spot

reg signed [10:0] speed_v = START_SPEED;
reg signed [10:0] speed_h = START_SPEED;
reg [7:0] speedCounter = 8'b0;

always@(speed_v) begin
//set horizontal move speed based on the vertical speed.
//This is mostly so that movement looks nicer and goes a bit slower
	speed_h <= (speed_v <= 10'sd2 || speed_v >= -10'sd2)? 5'sd2: SPEED;
end

always@(posedge vs) begin
	//I didn't want to increse the speed every vsync because then it moves too fast
	//the speed counter counts to 70
	speedCounter <= (speedCounter < 8'b01000110)?(speedCounter + 1'b1): 8'b0;
	//if the counter ends in 101, calc speed
	//3'b101 starts at 5 and is true every 8 vs
	if(speedCounter[2:0] == 3'b101) begin
	//currently 5 and -5 are the bounds of the speed.
	//so it doesn't get too fast
		if(speed_enable[1] && speed_v < 11'sd5) speed_v <= speed_v+SPEED;
		//if(speed_enable[0] && speed_v > -11'sd5) speed_v <= speed_v-SPEED;
		if(speed_enable[2]) speed_v <= 0;
	end
	
	//if the direction key is being pressed and you aren't offscreen, move
	//I'm wondering if the arithmetic messes up eventually
	//since the game breaks if its left on too long
	if(direct[0] == 1'b1 && h_move <= 11'sd740) h_move <= (h_move + speed_h);    //right
	if(direct[1] == 1'b1 && h_move >= -11'sd200) h_move <= (h_move - speed_h);  //left

	if(direct[2] == 1'b1 && v_move <= 11'sd600) v_move <= (v_move + speed_v);    //down
	if(direct[3] == 1'b1 && v_move >= -11'sd200) v_move <= (v_move - speed_v);  //up
	
	
	
	//reset is currently only used for the ball
	if(reset) begin
		if(v_move >= 11'sd400 || v_move <= -11'sd50) begin	//off the top or bottom of screen
			if (h_move >= 11'sd640 || h_move <= -11'sd50) begin // off the side of screen
				v_move <= 11'd200;
				//reset speed back to one if it's higher, otherwise stay the same
				speed_v <= (speed_v[9:0] >= 10'sd2)? 11'sd1: speed_v;
			end
			else begin
				h_move <= (h_move >= 11'sd300)? 11'sd640: -11'sd50;//go to side of screen if in the middle
				v_move <= 11'd200;
				speed_v <= (speed_v[9:0] >= 10'sd2)? 11'sd1: speed_v;
			end
		end
	end
	
end
	 
always @(posedge pclk) begin 
	//enable if in bounds of screen, otherwise do not
	//I think there should be a better way to determine this
	//verilog prefers unsigned numbers
	//if(vs) spot_enable <= 0;
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
















/*compares signals from spots to see if they collide. will activate other circuits*/
module r_gateMatrix(
input p1_col,
input p2_col,
input wall_col,

output reg [1:0] ena_player,
output reg ena_wall,
output reg flip_v
);

//collisions are dealt with only when either collision is High (true)
//otherwise they are ignored
always@(posedge p1_col, posedge p2_col) begin
	//check collision based on whether it last happened with p1 or p2
	//ex. can't collide with p1 again until p2 has been collided with
	ena_player[0] <= (p2_col)? 1'b0: 1'b1;
	ena_player[1] <= (p1_col)? 1'b0: 1'b1;
	
	//ena_wall <= (wall_col)? 1'b1: 1'b0;
	flip_v = (p1_col)? 1'b1: 1'b0;//flip the vdirection of the ball after a collision
end


endmodule



//enable is collision
//maybe I should modify so that speed is stored as a value
/*English flip flop - controls ball direction and which player has the english control*/
module r_englishFlipFlop(
input pclk,
input [5:0] d, 
input [1:0] enable,
input direct,
//input [1:0] prev_enable,
output reg [1:0] p,
output reg [3:0] q
);
	//d is the joystick controls for the english and the player/ball collision
	always@(d[5:4], d[3:2], enable) begin
		q[3:2] <= (direct)? 2'b10: 2'b01; // up, down
		q[1:0] <= d[1:0];
		
		//one AND for each set of controls
		if(direct) begin //going up
			p[1] <= ((d[4] && enable[1]) || (d[2] && enable[0]))? 1'b1: 1'b0; //add to speed
			p[0] <= ((d[5] && enable[1]) || (d[3] && enable[0]))? 1'b1: 1'b0; //subtract speed
		end
		else begin //going down
			p[0] <= ((d[4] && enable[1]) || (d[2] && enable[0]))? 1'b1: 1'b0;
			p[1] <= ((d[5] && enable[1]) || (d[3] && enable[0]))? 1'b1: 1'b0;
		end
	end
	
endmodule
//up, down, left, right


/* Who has control is determined by direct value, which is set in the gate matrix. 
	I don't have access to the speed of the ball from here, so I might want to change it so that I do. 
	I think I need to reorganize a bunch of stuff.
*/



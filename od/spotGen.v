//============================================================================
//  Odyssey card modules
//  Copyright (c) 2023-2026 autumn
//
//  The modules are loosely based on the description of the Odyssey's hardware from
//  https://www.odysseynow.org/Hardware.html
//============================================================================

      /*Wall, ball, and Player genterator*/
		//parameters are the default values that the code is set up with. 
		//can be overwritten in instatiation
module spotGen #(parameter WIDTH = 10'sd50, HEIGHT = 10'sd40, START_X = 10'sd0, START_Y = 10'sd0, SPEED = 5'sd1, START_SPEED = 10'sd1)
(
input pclk,
input [3:0] direct,
input vs,
input [10:0] h_cnt,
input [10:0] v_cnt,
input [2:0] speed_enable,			//0:decrease speed, 1: increase speed, 2: reset
input reset,

output reg spot_enable

);

/*My variables*/
reg signed [10:0] h_move = START_X; 
reg signed [10:0] v_move = START_Y; 

reg signed [10:0] speed_v = START_SPEED;
reg signed [10:0] speed_h = SPEED;
reg [7:0] speedCounter = 8'b0;

always@(speed_v) begin
	speed_h <= (speed_v <= 10'sd2 || speed_v >= -10'sd2)? 5'sd2: SPEED;
end

always@(posedge vs) begin
	speedCounter <= (speedCounter < 8'b01000110)?(speedCounter + 1'b1): 8'b0;
	if(speedCounter[2:0] == 3'b101) begin
		if(speed_enable[1] && speed_v < 11'sd5) speed_v <= speed_v+SPEED;
		if(speed_enable[0] && speed_v > -11'sd5) speed_v <= speed_v-SPEED;
		if(speed_enable[2]) speed_v <= SPEED;
	end
	
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
	if(($signed(v_cnt) >= v_move) && $signed(v_cnt) <= (HEIGHT + v_move)) begin
			if(($signed(h_cnt) >= h_move) && ($signed(h_cnt) <= (WIDTH + h_move))) begin
				spot_enable <= 1; 
			end
			else spot_enable <= 0;
	end
	else begin
		spot_enable <= 0;
	end
	
end


endmodule










/*English flip flop - controls ball direction and which player has the english control*/
module englishFlipFlop(
input pclk,
input [5:0] d, 
input [1:0] enable,
input direct,

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
			p[0] <= ((d[5] && enable[1]) || (d[3] && enable[0]))? 1'b1: 1'b0; //subtract speedd
		end
		else begin //going down
			p[0] <= ((d[4] && enable[1]) || (d[2] && enable[0]))? 1'b1: 1'b0;
			p[1] <= ((d[5] && enable[1]) || (d[3] && enable[0]))? 1'b1: 1'b0;
		end
	end
	
endmodule
//up, down, left, right









/*ball flip flop - negate part of english ff so that ball bounces off a wall*/
module ballFlipFlop(
input reset,
input d, 
input enable,
output reg q
);

always @(enable) begin
/*Not implemented, placeholder code here*/
	q <= (reset)? 1'b0: d;
end

endmodule







module playerSpeed(
input vs, 
input [2:0] direct,
output reg speed_enable,
output reg speed_reset
);

always @(vs) begin
	speed_enable = (|direct)? 1'b1: 1'b0;
	speed_reset = (~(|direct))? 1'b1: 1'b0;
end

endmodule







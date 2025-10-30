// A simple system-on-a-chip (SoC) for the MiST
// (c) 2015 Till Harbaum

// VGA controller generating 160x100 pixels. The VGA mode used is 640x400
// combining every 4 row and column

// http://tinyvga.com/vga-timing/640x400@70Hz

module JoystickPrototype (
   // pixel clock
   input  pclk,
	input ce_pix,
	input [7:0] color,
	input [15:0] direct_x,  	//left joystick
	input [15:0] direct_y, 	//right joystick
	//input reset[1:0],
   // VGA output
   output reg	hs,
   output reg 	vs,
   output [7:0] r,
   output [7:0] g,
   output [7:0] b,
	output VGA_DE        //data enable should be low in blanking interval
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


reg[9:0]  h_cnt;        // horizontal pixel counter
reg[9:0]  v_cnt;        // vertical pixel counter


reg hblank;
reg vblank;


// both counters count from the begin of the visible area

// horizontal pixel counter
always@(posedge pclk) begin
	if(h_cnt==H+HFP+HS+HBP-1)   h_cnt <= 10'b0; //h_cnt is the last pixel so reset
	else                        h_cnt <= h_cnt + 1'b1;

	// generate negative hsync signal - hsync has a negative polarity(low during sync)
	if(h_cnt == H+HFP)    hs <= 1'b0;
	if(h_cnt == H+HFP+HS) hs <= 1'b1;
	if(h_cnt == H+HFP+HS) hblank <= 1'b1; else hblank<=1'b0;

end

// veritical pixel counter
always@(posedge pclk) begin
	// the vertical counter is processed at the begin of each hsync
	if(h_cnt == H+HFP) begin
		if(v_cnt==VS+VBP+V+VFP-1)  v_cnt <= 10'b0; //v_cnt is at the last pixel so reset
		else							   v_cnt <= v_cnt + 1'b1;

	        // generate positive vsync signal - vsync has a positive polarity(high during sync)
		if(v_cnt == V+VFP)    vs <= 1'b1;
		if(v_cnt == V+VFP+VS) vs <= 1'b0;
		if(v_cnt == V+VFP+VS) vblank <= 1'b1; else vblank<=1'b0;
	end
end



// read VRAM
reg [13:0] video_counter;
reg [7:0] pixel;						//the color of the pixel
reg de;									//data enable, low on blanking periods
reg [2:0] blank = 3'b000;			//this is just an empty register we can use  to zero out values
											//why use that and not just a literal? I think it was just for clarity

reg [3:0] pix_ena;					//each spot generator gets one bit in this wire
wire [2:0] col_ena;					//[1:0]player collisions  [2]wall collision

wire [3:0] ballDirect;				//bit 0: right, bit 1: left, bit 2: down, bit 3: up
wire [2:0] ballHold;					//[2]:up or down [1]:add speed [0]:subtract speed
wire [3:0] player_speed;			//p1=[1:0] p2=[3:2] even bits true if player is moving in any direction
											//otherwise odd bits(reset) is true
											
reg [1:0] prev;
reg [10:0] player1Width = 11'sd40;
reg [10:0] player1Height = 11'sd40;
reg [10:0] player2Width = 11'sd40;
reg [10:0] player2Height = 11'sd40;

reg [7:0] x_val;
reg [7:0] y_val;


/*pix_ena[2] = (v_cnt < (direct_x + player1Width)) && (v_cnt > direct_x);
pix_ena[3] = (h_cnt < (direct_y + player1Height)) && (h_cnt > direct_y);*/

//basically our summer module
always@(posedge pclk) begin
        // The video counter is being reset at the begin of each vsync.
		  y_val = 7'd254 + direct_x[15:8];
		  x_val = 7'd254 + direct_x[7:0];
		  
	pix_ena[0] = (v_cnt < (y_val + player1Width)) && (v_cnt > y_val); //works but axis is sideways?
	pix_ena[1] = (h_cnt < (x_val + player1Height)) && (h_cnt > x_val);//doesn't work

	// visible area?
	if((v_cnt < V) && (h_cnt < H)) begin //if within visible area
		//if(h_cnt[1:0] == 2'b11)
			video_counter <= video_counter + 14'd1;
		
		//if(pix_ena[0] and ball){flip flop ball direction}
		if(pix_ena[1] && pix_ena[0]) //bitwise OR enabled pixels (returns true if any bit is 1)
			pixel <= 8'b111_111_11;//turn enabled pixel white
		else if( v_cnt || h_cnt == 10'd200) pixel = 8'b101_001_11;
		else pixel <= 8'h00; 
		de<=1;
	end else begin
		if(h_cnt == H+HFP) begin //if h_cnt is at the start of the hsync range
			if(v_cnt == V+VFP) //if v_cnt is at the start of the vsync range
				video_counter <= 14'd0;//reset to 0
			else if((v_cnt < V) && (v_cnt[1:0] != 2'b11))
			//reset video counter to beginning of line
				video_counter <= video_counter - 14'd640;
		de<=0;
		end
			
		pixel <= 8'h00;   //blanks screen to black
	end
end

// seperate 8 bits into three colors (332)
assign r = { pixel[7:5],   pixel[7:5],  pixel[7:6]};
assign g = { pixel[4:2],  pixel[4:2], pixel[4:3] };
assign b = { 4{pixel[1:0]}};

//assign VGA_DE  = ~(hblank | vblank);
assign VGA_DE = de;

endmodule



module mycore
(
	input         clk,
	input         reset,
	
	input         pal,
	input         scandouble,
	
	input [15:0] direct_x,  	//left joystick
	input [15:0] direct_y, 	   //right joystick

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

/*reg  [7:0] cos_out;
wire [5:0] cos_g = cos_out[7:3]+6'd32;
cos cos(vvc + {vc>>scandouble, 2'b00}, cos_out);*/

reg [7:0] pixel;
reg [3:0] pix_ena;				

reg [10:0] player1Width = 11'sd40;
reg [10:0] player1Height = 11'sd40;

reg signed [7:0] x_val;
reg signed [7:0] y_val;

//assign y_val = (direct_y > -7'sd127)? 7'd254 + direct_y[15:8]: y_val;
//assign x_val = (direct_x > -7'sd127)? 7'd254 + direct_x[7:0]: x_val;


//assign y_val = 7'd254 + direct_y[15:8];
//assign x_val = 7'd254 + direct_x[7:0];

assign y_val = 7'd200 + direct_y[15:8];
assign x_val = direct_x[7:0];
//changing x_val addition had no effect on dot pos

//assign video = (direct_x + direct_y > 0)? 8'd1:(cos_g >= rnd_c) ? {cos_g - rnd_c, 2'b00} : 8'd0;

always @(posedge clk) begin
	//Should width and height be the other way around?
	pix_ena[0] = (vc < (y_val + player1Width) ) && (vc > y_val);
	pix_ena[1] = (hc < (x_val + player1Height)) && (hc > x_val);
	
	
	if(pix_ena[1] && pix_ena[0]) //bitwise OR enabled pixels (returns true if any bit is 1)
			pixel <= 8'b111_101_11;//turn enabled pixel white
	else if( vc && hc == 10'd200) pixel = 8'b101_001_11;
	else pixel <= 8'h00; 

end

// seperate 8 bits into three colors (332)
assign r = { pixel[7:5],   pixel[7:5],  pixel[7:6]};
assign g = { pixel[4:2],  pixel[4:2], pixel[4:3] };
assign b = { 4{pixel[1:0]}};


endmodule


`timescale 1ps / 1ps

//fixed point adder without ECC, delay = 2
module E1_qadd #(
	//Parameterized values
		parameter Q = 15,
		parameter N = 64
	)
	(
		input clk,
		input rst,
		input [N-1:0] a,
		input a_en,
		input [N-1:0] b,
		input b_en,
		output [N-1:0] c,
		output c_valid
    );

reg [N-1:0] res;

reg [N-1:0] a_r;
reg [N-1:0] b_r;

wire input_en;

reg input_en_d1;
reg input_en_d2;

assign input_en = a_en & b_en;

assign c_valid = input_en_d2;

always @(posedge clk) begin
	if (rst) begin
		input_en_d1 <= 0;
		input_en_d2 <= 0;
	end else begin
		input_en_d1 <= input_en;
		input_en_d2 <= input_en_d1;
	end
end

assign c = res;


always @(posedge clk) begin
	if (rst) begin
		a_r <= 0;
	end else if (a_en) begin
		a_r <= a;
	end
end

always @(posedge clk) begin
	if (rst) begin
		b_r <= 0;
	end else if (b_en) begin
		b_r <= b;
	end
end

always @(posedge clk) begin
	if (rst) begin
		res <= 0;
	end else begin
		res <= a_r + b_r;
	end
end	

// always @(posedge clk) begin
// 	if (rst) begin
// 		res[N-2:0] = 0;
// 		res[N-1] = 0; 
// 	end else if(a_r[N-1] == b_r[N-1]) begin						
// 		res[N-2:0] = a_r[N-2:0] + b_r[N-2:0];		
// 		res[N-1] = a_r[N-1];																		
// 	end	else if(a_r[N-1] == 0 && b_r[N-1] == 1) begin		
// 		// if( a_r[N-2:0] > b_r[N-2:0] ) begin					
// 		// 	res[N-2:0] = a_r[N-2:0] - b_r[N-2:0];			
// 		// 	res[N-1] = 0;										
// 		// end else begin												
// 		// 	res[N-2:0] = b_r[N-2:0] - a_r[N-2:0];			
// 		// 	if (res[N-2:0] == 0)
// 		// 		res[N-1] = 0;										
// 		// 	else
// 		// 		res[N-1] = 1;										
// 		// 	end
// 		res = a_r + b_r;
		
// 	end else begin												
// 		if( a_r[N-2:0] > b_r[N-2:0] ) begin					
// 			res[N-2:0] = a_r[N-2:0] - b_r[N-2:0];			
// 			if (res[N-2:0] == 0)
// 				res[N-1] = 0;										
// 			else
// 				res[N-1] = 1;										
// 		end else begin												
// 			res[N-2:0] = b_r[N-2:0] - a_r[N-2:0];			
// 			res[N-1] = 0;										
// 		end
// 	end
// end

endmodule

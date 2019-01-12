module register_file( data_in, writenum, readnum, write, clk, data_out);
	`define REG_SIZE 16
	
	`define R0_HOT 8'b_00_000_001
	`define R1_HOT 8'b_00_000_010
	`define R2_HOT 8'b_00_000_100
	`define R3_HOT 8'b_00_001_000
	`define R4_HOT 8'b_00_010_000
	`define R5_HOT 8'b_00_100_000
	`define R6_HOT 8'b_01_000_000
	`define R7_HOT 8'b_10_000_000
	
	input [`REG_SIZE - 1:0] data_in;
	input [2:0] writenum, readnum;
	input write, clk;
	output [`REG_SIZE - 1:0] data_out;
		
		
	wire [7:0] put_reg, get_reg;
	wire signed [`REG_SIZE - 1:0] R0, R1, R2, R3, R4, R5, R6, R7; 
		
	//Firgure out which register we would like to access
	decoder_m_to_n #(3,8) d1 (.bin_in(writenum), .hot_out(put_reg));
	decoder_m_to_n #(3,8) d2 (.bin_in(readnum),  .hot_out(get_reg));
	
	//Instantiation of all 8 load-enabled registers
	vDFFE #(`REG_SIZE) Rg0 (.clk(clk), .enable(write & put_reg[0]), .in(data_in), .out(R0));
	vDFFE #(`REG_SIZE) Rg1 (.clk(clk), .enable(write & put_reg[1]), .in(data_in), .out(R1));
 	vDFFE #(`REG_SIZE) Rg2 (.clk(clk), .enable(write & put_reg[2]), .in(data_in), .out(R2));
	vDFFE #(`REG_SIZE) Rg3 (.clk(clk), .enable(write & put_reg[3]), .in(data_in), .out(R3));
	vDFFE #(`REG_SIZE) Rg4 (.clk(clk), .enable(write & put_reg[4]), .in(data_in), .out(R4));
	vDFFE #(`REG_SIZE) Rg5 (.clk(clk), .enable(write & put_reg[5]), .in(data_in), .out(R5));
	vDFFE #(`REG_SIZE) Rg6 (.clk(clk), .enable(write & put_reg[6]), .in(data_in), .out(R6));
	vDFFE #(`REG_SIZE) Rg7 (.clk(clk), .enable(write & put_reg[7]), .in(data_in), .out(R7));
		
	//Instantiation of the multiplexer
	multiplex m1 ( .hot_in(get_reg), .reg_in({R7, R6, R5, R4, R3, R2, R1, R0}), .out(data_out));
	
endmodule

	//Take a binary input and turn it into a one-hot code
module decoder_m_to_n(bin_in, hot_out);
	parameter m = 3;
	parameter n = 8;
	input  [m - 1:0] bin_in;
	output [n - 1:0] hot_out;
		
	wire [n - 1:0] hot_out = 1 << bin_in;
endmodule


	//Determine which input to let out of the register file
module multiplex (hot_in, reg_in, out);
	
	input [7:0] hot_in;
	input [`REG_SIZE * 8 - 1:0] reg_in;
	output reg [`REG_SIZE - 1:0] out;
	
	always @(*) begin
		case(hot_in)
			`R0_HOT: out = reg_in[15:0];
			`R1_HOT: out = reg_in[31:16];
			`R2_HOT: out = reg_in[47:32];
			`R3_HOT: out = reg_in[63:48];
			`R4_HOT: out = reg_in[79:64];
			`R5_HOT: out = reg_in[95:80];
			`R6_HOT: out = reg_in[111:96];
			`R7_HOT: out = reg_in[127:112];
			default out = {`REG_SIZE{1'b_x}};
		endcase
	end
endmodule

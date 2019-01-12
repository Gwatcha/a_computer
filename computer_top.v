
//Memory CMDS, Not sure if this is complete.
`define M_NONE	2'b_00
`define M_READ 	2'b_01
`define M_WRITE	2'b_10

//I/o Address'
`define SW_BASE 9'h140
`define LED_BASE 9'h100

module computer_top(KEY,SW,LEDR,HEX0,HEX1,HEX2,HEX3,HEX4,HEX5, CLOCK_50);  
	input [3:0] KEY;
	input [9:0] SW;
	input CLOCK_50;
	output [9:0] LEDR;
	output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5; //Don't change anything above here.
	
	//Outputs and inputs to cpu (apart from reset).
	wire [1:0] mem_cmd;
	wire [8:0] mem_addr;
	wire [15:0] read_data, write_data;
	
	// For I/O Logic
	wire [1:0] sw_enable;
	assign sw_enable[1] = (mem_cmd == `M_READ) ? 1'b1 : 1'b0;
	assign sw_enable[0] = (mem_addr == `SW_BASE) ? 1'b1 : 1'b0;
	
	wire [1:0] led_enable;
	wire led_reg_enable;
	assign led_enable[1] = (mem_cmd == `M_WRITE) ? 1'b1 : 1'b0;
	assign led_enable[0] = (mem_addr == `LED_BASE) ? 1'b1 : 1'b0;
	assign led_reg_enable = (led_enable == 2'b11) ? 1'b1 : 1'b0;
	
	vDFFE #(8)  ledreg(CLOCK_50, led_reg_enable, write_data[7:0], LEDR[7:0]);

	//For the logic underneath RAM
	wire [15:0] dout;
	wire write, inverter_enable, msel, check_read, check_write;
	assign check_read = (`M_READ == mem_cmd) ? 1'b1 : 1'b0;
	assign check_write = (`M_WRITE == mem_cmd) ? 1'b1 : 1'b0;
	assign msel =(1'b0 == mem_addr[8:8]) ? 1'b1 : 1'b0;
	assign inverter_enable = msel && check_read;
	
		//Changed read data & write in case address's overlap.
		// Switches and LEDS come first.
		assign read_data = (sw_enable == 2'b11) ?  SW[7:0]  : (inverter_enable ? dout : 16'bz);
		assign write = (mem_addr == `LED_BASE) ? 1'b0 : msel && check_write;
			
	//Initialize modules.
	RAM #(16, 8) MEM(
				.clk(CLOCK_50),
				.read_address(mem_addr[7:0]),
				.write_address(mem_addr[7:0]),
				.write(write),
				.din(write_data),
				.dout(dout)
			);
			
	cpu 	CPU(
				.clk(CLOCK_50),
				.reset(~KEY[1]),
				.read_data(read_data),
				.write_data(write_data),
				.mem_cmd(mem_cmd),
				.mem_addr(mem_addr),
				.halt(LEDR[8]));
				
				
	//I/O Circuits
	


	
endmodule

module vDFF(clk,D,Q);
  parameter n=1;
  input clk;
  input [n-1:0] D;
  output [n-1:0] Q;
  reg [n-1:0] Q;
  always @(posedge clk)
    Q <= D;
endmodule

//N-bit load-enabled register
module vDFFE(clk,enable,in,out);
  parameter n=16;
  input clk, enable;
  input [n-1:0] in;
  output reg [n-1:0] out;
  wire [n-1:0] next_out;
  
  assign next_out = enable ? in : out;

  always @(posedge clk)
    out <= next_out;
endmodule


`define hex_0 7'b_1_000_000
`define hex_1 7'b_1_111_001
`define hex_2 7'b_0_100_100
`define hex_3 7'b_0_110_000
`define hex_4 7'b_0_011_001
`define hex_5 7'b_0_010_010
`define hex_6 7'b_0_000_010
`define hex_7 7'b_1_111_000
`define hex_8 7'b_0_000_000
`define hex_9 7'b_0_011_000
`define hex_A 7'b_0_001_000
`define hex_b 7'b_0_000_011
`define hex_C 7'b_1_000_110
`define hex_d 7'b_0_100_001
`define hex_E 7'b_0_000_110
`define hex_F 7'b_0_001_110

module sseg(in,segs);
  input [3:0] in;
  output reg [6:0] segs;

  always @(*) begin
	case(in)
		4'b_0000: segs = `hex_0;
		4'b_0001: segs = `hex_1;
		4'b_0010: segs = `hex_2;
		4'b_0011: segs = `hex_3;
		4'b_0100: segs = `hex_4;
		4'b_0101: segs = `hex_5;
		4'b_0110: segs = `hex_6;
		4'b_0111: segs = `hex_7;
		4'b_1000: segs = `hex_8;
		4'b_1001: segs = `hex_9;
		4'b_1010: segs = `hex_A;
		4'b_1011: segs = `hex_b;
		4'b_1100: segs = `hex_C;
		4'b_1101: segs = `hex_d;
		4'b_1110: segs = `hex_E;
		4'b_1111: segs = `hex_F;
	endcase  
  end
endmodule

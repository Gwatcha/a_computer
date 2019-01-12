// To work with our autograder you MUST be able to get your cpu.v to work
// without making ANY changes to this file.  Refer to Section 4 in the Lab
// 6 handout for more details.

module cpu_tb;
  reg clk, reset;
  reg [15:0] read_data;
  wire [15:0] write_data;
  
  wire N,V,Z;
  wire [8:0] mem_addr;
  wire [1:0] mem_cmd;

  reg err;

  cpu DUT(clk,reset, read_data, write_data, N,V,Z, mem_cmd, mem_addr);

  initial begin
    clk = 0; #5;
    forever begin
      clk = 1; #5;
      clk = 0; #5;
    end
  end
  
  initial begin
    
	
    if (~err) $display("CPU TESTBENCH PASSED");
    $stop;
  end
endmodule
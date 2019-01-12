module alu(ain, bin, ALUop, out, status);
	`define REG_SIZE 16
	
	`define ALU_ADD 2'b_00
	`define ALU_SUB 2'b_01
	`define ALU_AND 2'b_10
	`define ALU_NOT 2'b_11
	
	input  [`REG_SIZE - 1:0] ain, bin;
	input [1:0] ALUop;
	output reg [`REG_SIZE - 1:0] out;
	output reg [2:0] status;
	/*
	2-N
	1-V
	0-Z
	*/
	
	always @(*) begin
		//So that status is always defined
		status = 3'b_000;
		case(ALUop)
			`ALU_ADD: out = ain + bin;
			`ALU_SUB: begin
				out = ain - bin;
				//If out is positive
				if(out[15] == 0)
				//And we did [-] - [+]
					if(ain[15] == 1 && bin[15] == 0)
					//We oVerflowed 
						status[1] = 1'b1;
			end
			`ALU_AND: out = ain & bin;
			`ALU_NOT: out = ~bin;
			default: out = {`REG_SIZE {1'b_x}};
		endcase
		//if out is 0, set flag
		if(out == 0) 
			status[0] = 1'b1;
		
		//if out is negative, set flag
		if(out[15] == 1) 
			status[2] = 1'b1;
		
	end
endmodule
/*must edit for the larger status*/
	
module inst_decoder (in, nsel, opcode, ALUop, sximm5, sximm8, shift, read_write_num);
	input [15:0] in;
	input [2:0] nsel;
	output [2:0] opcode, read_write_num;
	output [1:0] ALUop, shift;
	output [15:0] sximm5, sximm8;
	
	//The following breaks the input bus into smaller, more managable wires
	assign opcode = in[15:13];
	assign ALUop = in[12:11];
	//Sign extend the lower 5 bits
	assign sximm5 = {{11{in[4]}}, in[4:0]};
	//Sign extend the lower 8 bits
	assign sximm8 = {{8{in[7]}}, in[7:0]};
	assign shift = in[4:3];

	assign read_write_num = (nsel[2] == 1) ? in[10:8] : (nsel[1] == 1) ? in[7:5] : in[2:0];

endmodule
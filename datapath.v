module datapath (ALUop, sximm5, sximm8, shift, read_write_num, write, vsel, loads, loadc, loadb, loada, out, N, V, Z, mdata, PC, clk, asel, bsel);

`define REG_SIZE 16

   input [15:0] sximm5, sximm8, mdata;
   input [8:0]  PC;
   input [2:0]  read_write_num;
   input [1:0]  shift, ALUop, vsel;
   input        write, loada, loadb, asel, bsel, loadc, loads, clk;

   output [15:0] out;
   wire          wN, wV, wZ;
   output        N, V, Z;

   wire [`REG_SIZE - 1:0] reg_data_in, reg_data_out;
   wire [`REG_SIZE - 1:0] reg_a_out, reg_b_out;
   wire [`REG_SIZE - 1:0] shift_out;
   wire [`REG_SIZE - 1:0] Ain, Bin;
   wire [`REG_SIZE - 1:0] alu_out;

   //Mux to select from a variety of inputs
   dp_in_mux dataplex_in (
                          .bin_in(vsel),
                          .in_0(mdata),
                          .in_1(sximm8),
                          .in_2({7'b0, PC}), //This is current PC + 1.
                          .in_3(out),
                          .out(reg_data_in));

   //The memory
   register_file REGFILE (
                          .data_in(reg_data_in),
                          .writenum(read_write_num),
                          .readnum(read_write_num),
                          .write(write),
                          .clk(clk),
                          .data_out(reg_data_out));

   //The first intermediate register before the ALU
   vDFFE reg_a (.clk(clk),
                .enable(loada),
                .in(reg_data_out),
                .out(reg_a_out));

   //The second intermediate register, parallel to reg_a
   vDFFE reg_b (.clk(clk),
                .enable(loadb),
                .in(reg_data_out),
                .out(reg_b_out));

   //Used to shift the bits stored in reg_b before going to the ALU
   shifter shift_b (.in(reg_b_out),
                    .shift(shift),
                    .out(shift_out));


   //Do we use the values stored in reg_a/b or some new inputs
   multiplexer reg_a_plex (.hot_in(asel),
                           .in_0(reg_a_out),
                           .in_1(16'b_0),
                           .out(Ain));

   multiplexer reg_b_plex (.hot_in(bsel),
                           .in_0(shift_out),
                           .in_1(sximm5),
                           .out(Bin));

   //ALU = math
   alu ALU (.ain(Ain),
            .bin(Bin),
            .ALUop(ALUop),
            .out(alu_out),
            .status({wN, wV, wZ}));

   //Output and status registers, to be used more later
   vDFFE reg_c(.clk(clk),
               .enable(loadc),
               .in(alu_out),
               .out(out));

   vDFFE #(3) reg_status (.clk(clk),
                          .enable(loads),
                          .in({wN, wV, wZ}),
                          .out({N, V, Z}));
endmodule

module multiplexer(hot_in, in_0, in_1, out);
   input hot_in;
   input [`REG_SIZE - 1:0] in_1, in_0;
   output reg [`REG_SIZE - 1:0] out;

   always @(*) begin
		  case(hot_in)
			  0: out = in_0;
			  1: out = in_1;
			  default out = {`REG_SIZE{1'b_x}};
		  endcase
	 end
endmodule

module dp_in_mux (bin_in, in_0, in_1, in_2, in_3, out);
	 input [1:0] bin_in;
	 input [15:0] in_0, in_1, in_2, in_3;
	 output reg [15:0] out;

	 always @(*)
		 case(bin_in)
			 2'b_00: out = in_0;
			 2'b_01: out = in_1;
			 2'b_10: out = in_2;
			 2'b_11: out = in_3;
		 endcase
endmodule

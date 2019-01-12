
module cpu(clk,reset, read_data, write_data, mem_cmd, mem_addr, halt);
	input clk, reset;
	input [15:0] read_data;
	output [15:0] write_data;
	output halt; //controls led8

	//Memory and adress.
	output [1:0] mem_cmd;
	output [8:0] mem_addr;

	wire [15:0] inst_reg_out;
	wire [2:0] nsel; //FROM FSM TO DECODER
	wire [2:0] opcode; //FROM inst_decoder to FSM
	wire [1:0] ALUop, shift; //FROM inst_decoder to FSM (op only) and DP
	wire [15:0] sximm5, sximm8; //FROM inst_decoder to DP
	wire [2:0] read_write_num; //FROM inst_decoder to DP
	
	wire [8:0] fsm_to_dp_data;
	
	//State machine program control outputs. +Status
	wire load_ir, addr_sel, load_pc, reset_pc, load_addr;
	wire [2:0] status; // {N, V, Z}, from DP to FSM.
	
	//vDFFE and state logic for program counter and choosing memory address.
	wire [8:0] next_pc, PC, data_address_out;
	wire [3:0] pc_sel;
	assign mem_addr = addr_sel ? PC : data_address_out;
	
	mux_pc PC_MUX(9'b0, write_data[8:0], (PC+sximm8[8:0]), (PC+1'b1), pc_sel, next_pc);
	
	//Copies in through the register at posedge clk
	vDFFE  #(16) instruction_reg (
									.clk(clk),
									.enable(load_ir),
									.in(read_data),
									.out(inst_reg_out));
			
	//For the Program Counter		
	vDFFE  #(9) pc (
									.clk(clk),
									.enable(load_pc),
									.in(next_pc),
									.out(PC));
								
	//For holding the Data Address
	vDFFE  #(9) data_address (
									.clk(clk),
									.enable(load_addr),
									.in(write_data[8:0]),
									.out(data_address_out));									
	
	
	//Decodes instruction from the instruction register
	inst_decoder dec_inst (
							.in(inst_reg_out),
							.nsel(nsel), 
							.opcode(opcode),
							.ALUop(ALUop),
							.sximm5(sximm5),
							.sximm8(sximm8),
							.shift(shift),
							.read_write_num(read_write_num));
	
	//State machine to tell us where we are in the cycle
	fsm FSM (
				//		.s(s),
						.clk(clk),
						.reset(reset),
						.opcode(opcode),
						.op(ALUop),
				//	.w(w),
						.nsel(nsel),
						.to_dp(fsm_to_dp_data),
				//Start lab7
						.load_pc(load_pc),
						.addr_sel(addr_sel),
						.mem_cmd(mem_cmd),
						.cond(inst_reg_out[10:8]),
						.load_ir(load_ir),
						.load_addr(load_addr),
						.pc_sel(pc_sel),
						.status(status),
						.halt(halt)
						);
						
						/*fsm_to_dp_data
						[8] asel
						[7] bsel
						[6] write
						[5:4] vsel
						[3] loads
						[2] loadc
						[1] loadb
						[0] loada						
						*/
	
	//Same datapath as from lab 5, with minor enhancements					
	datapath DP (
					.ALUop(ALUop),
					.sximm5(sximm5),
					.sximm8(sximm8),
					.shift(shift),
					.read_write_num(read_write_num),
					.write(fsm_to_dp_data[6]),
					.vsel(fsm_to_dp_data[5:4]),
					.loads(fsm_to_dp_data[3]),
					.loadc(fsm_to_dp_data[2]),
					.loadb(fsm_to_dp_data[1]),
					.loada(fsm_to_dp_data[0]),
					.out(write_data),
					.N(status[2]),
					.V(status[1]),
					.Z(status[0]),
					.mdata(read_data),
					.PC(PC),
					.clk(clk),
					.asel(fsm_to_dp_data[8]),
					.bsel(fsm_to_dp_data[7]));
endmodule

//4bit one hot select for choosing next pc instruction.
module mux_pc(a, b, c, d, sel, out);
	input [8:0] a, b, c, d;
	input [3:0] sel;
 	output reg [8:0] out;
	
	always @(*) begin
		case (sel) 
			4'b1000 : out = a;
			4'b0100 : out = b;
			4'b0010 : out = c;
			4'b0001 : out = d;
			default: out = 4'bxxxx;
		endcase
	end
endmodule

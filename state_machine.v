module fsm (clk, reset, opcode, status, op, cond, nsel, to_dp, pc_sel, load_pc, addr_sel, mem_cmd, load_ir, load_addr, halt);
   input clk, reset;
   input [2:0] opcode, status, cond;
   input [1:0] op;

   output      load_pc, addr_sel, load_ir, load_addr, halt;
   output reg [3:0] pc_sel;
   output reg [2:0] nsel;
   output reg [8:0] to_dp;
   output reg [1:0] mem_cmd;

   //Memory CMDS, Not sure if this is complete.
`define M_NONE	2'b_00
`define M_READ 	2'b_01
`define M_WRITE	2'b_10

   //List of states
`define RESET 	   5'b_00000 //Used to be "WAIT", I changed it to RESET along with the correct output.
`define DECODE 	   5'b_00001
`define GET_A 	   5'b_00010
`define GET_B 	   5'b_00011
`define MATH 	   5'b_00100
`define WRITE_BACK 5'b_00101
`define WRITE_IMM  5'b_00110
`define USE_ZERO   5'b_00111
`define CMP        5'b_01000
`define AND		   5'b_01001
`define MVN		   5'b_01010

   //New Lab7 States
`define IF1 				 5'b_01011
`define IF2 				 5'b_01100
`define UPDATE_PC	 5'b_01101
`define HALT			5'b_01110

   //Memory Instruction States
`define MEM 			5'b_01111
`define MEM2			5'b_10000
`define LDR			 	5'b_10001
`define LDR2			5'b_10010
`define STR				5'b_10011
`define STR2			5'b_10100
`define STR3			5'b_10101

   //Branches & Functions
`define BR_COND     		  5'b_10110
`define BR_CALL_DIR     5'b_10111
`define BR_CALL_INDIR  5'b_11000
`define BR_RETURN     	  5'b_11001
`define BR_RETURN2      5'b_11010
`define BR_RETURN3      5'b_11011

   wire [4:0]       state_now, next_or_reset_state;
   reg [4:0]        next_state;

   //To simplify things, concatenate 		{load_pc, addr_sel, load_ir, load_addr}
   //Into program_control, positioning: 		[3]         [2]          [1]     	   [0]
   reg [3:0]        program_control;
   assign load_pc     = program_control[3];
   assign addr_sel    = program_control[2];
   assign load_ir      = program_control[1];
   assign load_addr  = program_control[0];

   vDFF #(5) State( .clk(clk), .D(next_or_reset_state), .Q(state_now));

   //reset the state machine if so, otherwise, give it next_state.
   assign next_or_reset_state = reset ? `RESET : next_state;

   //Display 1 on led8.
   assign halt = state_now == `HALT ? 1'b1 : 1'b0;

   /*to_dp_data
    [8] asel
    [7] bsel
    [6] write
    [5:4] vsel
    [3] loads
    [2] loadc
    [1] loadb
    [0] loada
    format: xx_x_xx_xxxx
    */

   /* NEW: TOTAL: 23
    For the current state, assign values to	    {5'b next_state,  		9'b to_dp,	 			   3'b nsel, 						4'b pc_sel		         									4'b program_control			 						2'b mem_cmd}
    `STATE	        (see to_dp_data)      	(Rn, Rd, Rm)	   	(0	, datapath_out, sximm8+pc , pc+1)		{load_pc, addr_sel, load_ir, load_addr }			`MEMCMD
    [2]  [1]  [0]     	 [3]		[2]    				[1]			[0]				[3] 		  [2]          [1]         [0]
    */

   //Template for new:
   // 	`STATE:   	 		{to_dp, nsel, pc_sel, program_control, mem_cmd} = {9'b_00_0_00_0000, 3'b_000, 4'b_0001, 4'b_0000, `MEMCMD};

   //get the next state and output for currentstate.
   always@(*) begin
      case (state_now)
        //ResetPC if reset is asserted.
        `RESET:   	 		{to_dp, nsel, pc_sel, program_control, mem_cmd} = { 9'b_00_0_00_0000, 3'b_000, 4'b_1000, 4'b_1000, `M_NONE};

        //Instruction Fetch 1 & 2. Together, they fetch an instruction from the RAM at the Program Counter address,
        //If the PC was just reset, it starts at address 9'b0.
        // The reason there is two is because it takes two clk cycles to read from RAM with FPGA memory.
        `IF1:   	 		{to_dp, nsel, pc_sel, program_control, mem_cmd} = {9'b_00_0_00_0000, 3'b_000, 4'b_0001, 4'b_0100, `M_READ};
        `IF2:   	 		{to_dp, nsel, pc_sel, program_control, mem_cmd} = {9'b_00_0_00_0000, 3'b_000, 4'b_0001, 4'b_0110, `M_READ};

        //Enables the updating of PC to PC+1.
        `UPDATE_PC:   {to_dp, nsel, pc_sel, program_control, mem_cmd} = {9'b_00_0_00_0000, 3'b_000, 4'b_0001, 4'b_1000, `M_NONE};

        //Halt state, set LED[8] to 1. Loops unless state machine is reset.
        `HALT:   	 		{to_dp, nsel, pc_sel, program_control, mem_cmd} = {9'b_00_0_00_0000, 3'b_000, 4'b_0001, 4'b_0000, `M_NONE};

        //After getting A, execute these two states if it is a memory instruction. First, loadc with sximm5 + regA. Then store it in the Data Address Register.
        `MEM:   	 	 {to_dp, nsel, pc_sel, program_control, mem_cmd} = {9'b_01_0_00_0100, 3'b_000, 4'b_0001, 4'b_0000, `M_NONE};//Data Address now stored.
        `MEM2:   	 		{to_dp, nsel, pc_sel, program_control, mem_cmd} = {9'b_00_0_00_0000, 3'b_000, 4'b_0001, 4'b_0001, `M_NONE};//After MEM and MEM2, read the data. (altered IF1)
        `LDR:   	 		{to_dp, nsel, pc_sel, program_control, mem_cmd} = {9'b_00_0_00_0000, 3'b_000, 4'b_0001, 4'b_0000, `M_READ};
        // (altered IF2) Write mdata into Rd then fetch next instruction.
        `LDR2:   	 		{to_dp, nsel, pc_sel, program_control, mem_cmd} = {9'b_00_1_00_0000, 3'b_010, 4'b_0001, 4'b_0000, `M_READ};
        //Read Rd into regB.
        `STR:   	 		{to_dp, nsel, pc_sel, program_control, mem_cmd} = {9'b_00_0_00_0010, 3'b_010, 4'b_0001, 4'b_0000, `M_NONE};
        //Pass it to regC (might be shifted)
        `STR2:   	 		{to_dp, nsel, pc_sel, program_control, mem_cmd} = {9'b_10_0_00_0100, 3'b_000, 4'b_0001, 4'b_0000, `M_WRITE};
        //Write datapath_out to address, then fetch the next instrucition.
        `STR3:   	 		{to_dp, nsel, pc_sel, program_control, mem_cmd} = {9'b_00_0_00_0000, 3'b_000, 4'b_0001, 4'b_0000, `M_WRITE};

        //Conditional Branch state. pc_sel on end, checks each condition supported. load_pc = 1. After fetching this instruction, next PC is = PC + 1, so don't +1.
        `BR_COND:      {to_dp, nsel,  mem_cmd, pc_sel, program_control} = {9'b_00_0_00_0000, 3'b_000, 4'b_1000, `M_NONE,
                                                                           ( cond == 3'b000 ? 																			  8'b0010_1000  :     //B
                                                                             cond == 3'b001 ? (status[0] == 1 ? 							   8'b0010_1000 : 8'b0001_0000) : 	//BEQ
                                                                             cond == 3'b010 ? (status[0] == 0 ? 							   8'b0010_1000 : 8'b0001_0000) : 	//BNE
                                                                             cond == 3'b011 ? (status[2] != status[1] ? 				   8'b0010_1000 : 8'b0001_0000) :	//BLT
                                                                             cond == 3'b100 ? (status[2] != status[1] || status[0] ? 8'b0010_1000 : 8'b0001_0000) :   //BLE
                                                                             4'b0001 ) //Default is for PC not to be updated.
                                                                           };
        //These states occur after PC is updated to PC+1!
        //Writes PC into R7 (Rn) and also updates PC to PC=PC+sx(im8). Goes to IF1 after.
        `BR_CALL_DIR:	{to_dp, nsel, pc_sel, program_control, mem_cmd} = {9'b_00_1_10_0000, 3'b_100, 4'b_0010, 4'b_1000, `M_NONE};
        //Writes PC+1 into R7 (Rn). Goes to BR_RETURN after.
        `BR_CALL_INDIR:	{to_dp, nsel, pc_sel, program_control, mem_cmd} = {9'b_00_1_10_0000, 3'b_100, 4'b_0001, 4'b_0000, `M_NONE};

        //Come here after call if it's an indirect call. After these 3, PC = Rd.
        `BR_RETURN: {to_dp, nsel, pc_sel, program_control, mem_cmd} = {9'b_00_0_00_0010, 3'b_010, 4'b_0001, 4'b_0000, `M_NONE}; //loadB w/ Rd after state
        `BR_RETURN2: {to_dp, nsel, pc_sel, program_control, mem_cmd} = {9'b_10_0_00_0100, 3'b_000, 4'b_0001, 4'b_0000, `M_NONE}; //loadC w/Rd after state
        `BR_RETURN3: {to_dp, nsel, pc_sel, program_control, mem_cmd} = {9'b_00_0_00_0000, 3'b_000, 4'b_0100, 4'b_1000, `M_NONE}; //loadPC w/Rd after state

        //Lab 6 States.
        `DECODE:   	 		{to_dp, nsel, pc_sel, program_control, mem_cmd} = {9'b_00_0_00_0000, 3'b_000, 4'b_0001, 4'b_0000, `M_NONE};
        //Load a value into reg_a, then go GET_B.
        `GET_A:   	 		{to_dp, nsel, pc_sel, program_control, mem_cmd} = {9'b_00_0_00_0001, 3'b_100, 4'b_0001, 4'b_0000, `M_NONE};
        //If we are copying or negating a register, we will want to use a 16'b0 from the reg_a side
        //Otherwise, we want to proceed to the standard math state (+, -, &)
        `GET_B:   	 		{to_dp, nsel, pc_sel, program_control, mem_cmd} = {9'b_00_0_00_0010, 3'b_001, 4'b_0001, 4'b_0000, `M_NONE};
        //If we are doing a CMP, we do not want to write back into a register, hence go to WAIT
        //Otherwise prepare to writeback the result
        `MATH:   	 		{to_dp, nsel, pc_sel, program_control, mem_cmd} = {9'b_00_0_00_1100, 3'b_000, 4'b_0001, 4'b_0000, `M_NONE};
        //Use asel = 1 to allow the b-side to go through the ALU solo, prepare for writeback
        `USE_ZERO:   	 		{to_dp, nsel, pc_sel, program_control, mem_cmd} = {9'b_10_0_00_1100, 3'b_000, 4'b_0001, 4'b_0000, `M_NONE};
        //Writeback and then wait
        `WRITE_BACK:   	 		{to_dp, nsel, pc_sel, program_control, mem_cmd} = {9'b_00_1_11_0000, 3'b_010, 4'b_0001, 4'b_0000, `M_NONE};
        //Write into the register and then wait
        `WRITE_IMM:   	 		{to_dp, nsel, pc_sel, program_control, mem_cmd} = {9'b_00_1_01_0000, 3'b_100, 4'b_0001, 4'b_0000, `M_NONE};
        //Pray to God we do not get here
        default:    {to_dp, nsel, pc_sel, program_control, mem_cmd} = 22'bx;
      endcase
   end

   //This always block determines the next state.
   always@(*) begin
      case (state_now)
        `RESET:   	 		next_state = `IF1;

        `IF1:   	 			next_state = `IF2;
        `IF2:   	 			next_state = `UPDATE_PC;

        `UPDATE_PC:    next_state = `DECODE;

        //Halt state always goes to halt state.
        `HALT:   	 		next_state = `HALT;

        //After getting A, execute these two states if it is a memory instruction.
        `MEM:   	 		next_state = `MEM2;
        `MEM2:   	 		next_state = opcode == 3'b011 ? `LDR : `STR; //Branch to either load or store.

        `LDR:   	 			next_state = `LDR2;
        `LDR2:   	 		next_state = `IF1;

        `STR:   	 			next_state = `STR2;
        `STR2:   	 		next_state = `STR3;
        `STR3:   	 		next_state = `IF1;

        //If the opcode and op are right, go to the immediate write stage (write into a register), or stay in HALT if 3'b111.
        //There is also the possibility of copying one register to another (through the USE_ZERO state)
        //If neither of those, simply go and GET_A
        `DECODE:   	 	next_state = opcode == 3'b111 ? `HALT : opcode == 3'b_110 ? (op == 2'b_10 ? `WRITE_IMM :  `GET_B) :
                                   opcode == 3'b001  ? `BR_COND :
                                   opcode == 3'b010  ?  (op == 2'b11 ? `BR_CALL_DIR : (op == 2'b10 ? `BR_CALL_INDIR :`BR_RETURN)) :
                                   `GET_A ;

        //Load a value into reg_a, then go GET_B if it's an ALU instruction. If not, go to memory instructions
        `GET_A:   	 	next_state = opcode == 3'b101 ? `GET_B : `MEM;
        //If we are copying or negating a register, we will want to use a 16'b0 from the reg_a side
        //Otherwise, we want to proceed to the standard math state (+, -, &)
        `GET_B:   	 		next_state = {opcode,op} == 5'b_11000 || {opcode,op} == 5'b_10111 ? `USE_ZERO : `MATH;
        //If we are doing a CMP, we do not want to write back into a register, hence go to WAIT
        //Otherwise prepare to writeback the result
        `MATH:   	 		next_state = {opcode,op} == 5'b_10101 ? `IF1 : `WRITE_BACK;

        `USE_ZERO:   	 next_state = `WRITE_BACK;
        //Writeback and then wait
        `WRITE_BACK:   next_state = `IF1;
        //Write into the register and then wait
        `WRITE_IMM:   	 next_state = `IF1;

        //In the BR_COND state, the next input for PC is determined then we go to fetch it.
        `BR_COND:		next_state = `IF1;

        //If it's a direct call, go to IF1. If it's a direct call, start writing PC=Rd by executing BX afterwards.
        `BR_CALL_DIR: next_state = `IF1;
        `BR_CALL_INDIR: next_state = `BR_RETURN;

        `BR_RETURN:   next_state = `BR_RETURN2;
        `BR_RETURN2: next_state = `BR_RETURN3;
        `BR_RETURN3:   next_state = `IF1;

        default:   		   next_state = `HALT;
      endcase
   end

endmodule

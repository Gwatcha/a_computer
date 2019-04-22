module shifter (in, shift, out);
`define REG_SIZE 16
`define SHIFT_NO         2'b_00
`define SHIFT_LEFT_ZERO  2'b_01
`define SHIFT_RIGHT_ZERO 2'b_10
`define SHIFT_RIGHT_COPY 2'b_11

   input [`REG_SIZE - 1:0] in;
   input [1:0]             shift;
   output reg [`REG_SIZE - 1:0] out;

   always @(*) begin
      case(shift)
        `SHIFT_NO: out = in;
        `SHIFT_LEFT_ZERO: out = in << 1;
        `SHIFT_RIGHT_ZERO: out = in >> 1;
        `SHIFT_RIGHT_COPY: out = {in[`REG_SIZE - 1], in[`REG_SIZE - 1:1]};
        default: out = {`REG_SIZE {1'b_x}};
      endcase
   end
endmodule

module ffD_p_lfsr (
  input wire clk,
  input wire rst_n,
  input wire [3:0] nivel_out
);
// registrador ff tipo D
reg [3:0] d_reg;
//
// para o meu primeiro registrador não ficar com 0 e travar
// precisa colocar um fio de realimentação nele, eu coloco o
// fio pegando as saidas do registrador 3 e 2 passa por uma xor
// e entra no registrador 0 então  ele não trava
//
wire feedback;
//
assign feedback = d_reg[3]^d_reg[2];
//
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) begin
    d_reg <= 4'b0001';
  end else begin
    d_reg <= {d_reg[2:0], feedback};
  end
end
//
assign nivel_out = d_reg;
//
endmodule

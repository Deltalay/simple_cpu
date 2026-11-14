module program_memory #(
    parameter DEPTH = 128
)(
    input        clk,
    input  [7:0] r_addr,
    output reg [15:0] r_data
);

reg [15:0] memory [0:DEPTH-1];
initial begin
    $readmemh("program.asm.bin", memory);
end
always @(posedge clk) begin
    r_data <= memory[r_addr];
end

endmodule

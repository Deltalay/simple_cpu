module s_memory #(
    parameter DEPTH = 64
)(
    input clk,
    input write_en,
    input read_en,
    input [7:0] w_addr,
    input [7:0] r_addr,
    input [7:0] w_data,
    output     [5:0]  led_byte,
    output reg[7:0] r_data
);
reg [7:0] memory[0:DEPTH-1];
always @(posedge clk) begin
    if (write_en == 1'b1) begin
        memory[w_addr] <= w_data;
    end
    if (read_en == 1'b1) begin
        r_data <= memory[r_addr];
    end
end
assign led_byte = memory[DEPTH-1][5:0];

endmodule

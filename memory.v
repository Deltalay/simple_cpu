module s_memory #(
    parameter DEPTH = 8'd64,
    parameter LED_ADDR = 16'hFF
)(
    input clk,
    input write_en,
    input read_en,
    input [15:0] w_addr,
    input [15:0] r_addr,
    input [7:0] w_data,
    output     [5:0]  led_byte,
    output reg[7:0] r_data
);
reg [7:0] memory[0:DEPTH-1];
reg [7:0] led_reg;
always @(posedge clk) begin
    if (write_en) begin
        if (w_addr == LED_ADDR) begin
            led_reg <= w_data;
        end
        else if (w_addr < DEPTH) begin
            memory[w_addr] <= w_data;
        end
    end

    if (read_en) begin
        if (r_addr == LED_ADDR) begin
            r_data <= led_reg;
        end
        else if (r_addr < DEPTH) begin
            r_data <= memory[r_addr];
        end
        else begin
            r_data <= 8'h00;
        end
    end
end
assign led_byte = led_reg[5:0];


endmodule

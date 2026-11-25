module central_bus (
    input        clk,
    input        write_en,
    input        read_en,
    input [15:0] w_addr,
    input [15:0] r_addr,
    input [ 7:0] w_data,

    input        uart_rx,
    output [5:0] on_board_led,
    output       uart_tx,

    output reg [7:0] r_data
);
    wire cs_ram;
    wire cs_uart;
    wire cs_gpio;
    wire [7:0] ram_rdata;
    wire [7:0] uart_rdata;
    wire [7:0] gpio_rdata;


endmodule

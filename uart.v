// My idea here is that
// UART itself will handle it part, yet
// expose a memory like interface for the cpu
// to access it.
// like: when we select write_en
// then we write w_data to address.
// which uart module will use that data to do it operation
// and we can read the status of that data via the r_addr.
module uart_mod (
    input clk,
    input write_en,
    input read_en,
    input cs_uart,
    input [7:0] w_data,
    input [15:0] w_addr,
    input [15:0] r_addr,
    output reg [7:0] r_data,
    input uart_rx,
    output uart_tx
);

endmodule

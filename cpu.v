module top(
    input clk,
    input rst,
    output [5:0] led
);
    reg zero_flag = 0;
    reg negative_flag = 0;
    reg overflow_flag = 0;

    reg[7:0] registers [0:3];
    localparam PROGRAM_SIZE = 256;
    localparam MEMORY_SIZE = 128;
    localparam STACK_SIZE = 64;
    reg[7:0] STACK[0:STACK_SIZE];
    reg [6:0] SP;
    localparam CPU_FETCH           = 2'b00;
    localparam CPU_FETCH_WAIT      = 2'b01;
    localparam CPU_MEMORY_LOAD_REG = 2'b10;
    localparam CPU_EXECUTE         = 2'b11;

    reg [1:0] CPU_STATE = CPU_FETCH;
    reg rst_sync_0 = 1'b1;
    reg rst_sync_1 = 1'b1;
    reg rst_prev   = 1'b1;
    wire rst_pressed = rst_prev && !rst_sync_1;
    reg [15:0] instruction;
    reg [7:0] PC = 0;
    wire [7:0] r_addr = PC;
    reg[15:0] r_data;
    program_memory #(
    	.DEPTH(PROGRAM_SIZE)
        ) programs (
    	.clk   (clk),
    	.r_addr(r_addr),
    	.r_data(r_data)
    );
    reg mem_write_en = 1;
    reg mem_read_en = 1;
    reg [15:0] memory_write_addr;
    reg [15:0] memory_read_addr;
    reg [7:0] memory_write_data;
    wire [5:0] led_direct;
    reg [7:0] memory_read_data;
    wire [5:0] opcode;
    wire [1:0] rd;
    wire [1:0] rs;
    wire [1:0] rsH;

    wire [7:0] immediate;

    localparam NOP = 6'b000000;
    localparam LDI = 6'b000001;
    localparam LDM = 6'b000010;
    localparam STR = 6'b000011;
    localparam LDID = 6'b000100;
    localparam STRID = 6'b000101;
    localparam LDMW = 6'b000110;
    localparam STRW = 6'b000111;

    localparam ADD = 6'b001010;
    localparam SUB = 6'b001011;
    localparam MUL = 6'b001100;

    localparam SLI = 6'b010000;
    localparam SRI = 6'b010001;
    localparam SHL = 6'b010010;
    localparam SHR = 6'b010011;

    localparam AND = 6'b011000;
    localparam OR = 6'b011001;
    localparam XOR = 6'b011010;
    localparam NOT = 6'b011011;

    localparam JMP = 6'b100000;
    localparam JZ = 6'b100001;
    localparam JN = 6'b100010;
    localparam JO = 6'b100011;

    localparam CMP = 6'b100110;

    localparam CLN = 6'b101000;
    localparam CLZ = 6'b101001;
    localparam CLO = 6'b101010;

    localparam CALL = 6'b101110;
    localparam RET = 6'b101111;
    localparam PUSH = 6'b110000;
    localparam POP = 6'b110001;

    assign opcode = instruction[15:10];
    assign rd = instruction[9:8];
    assign rs = instruction[1:0];
    assign rsH = instruction[3:2];
    assign immediate = instruction[7:0];


    reg [15:0] result = 0;

    reg[3:0] clockCounter = 0;
    localparam [3:0]clock = 4;
    s_memory #(
    	.DEPTH(MEMORY_SIZE)
        ) memory (
    	.clk     (clk),
    	.write_en(mem_write_en),
    	.read_en (mem_read_en),
    	.w_addr  (memory_write_addr),
    	.r_addr  (memory_read_addr),
    	.w_data  (memory_write_data),
    	.r_data  (memory_read_data),
        .led_byte(led_direct)
    );
    always @(posedge clk) begin
        rst_sync_0 <= rst;
        rst_sync_1 <= rst_sync_0;
        rst_prev   <= rst_sync_1;
    end
    always @(posedge clk) begin
        if (rst_pressed == 1'b1) begin
            PC <= 0;
            registers[0] <= 0;
            registers[1] <= 0;
            registers[2] <= 0;
            registers[3] <= 0;
            zero_flag <= 0;
            negative_flag<= 0;
            SP <= 0;
            overflow_flag<=0;
            CPU_STATE <= CPU_FETCH;
        end
        else begin
            if (clockCounter == clock) begin
                case (CPU_STATE)
                    CPU_FETCH: begin
                        mem_read_en <= 0;
                        mem_write_en <= 0;
                        CPU_STATE <= CPU_FETCH_WAIT;
                    end
                    CPU_FETCH_WAIT: begin
                        instruction <= r_data;
                        CPU_STATE <= CPU_EXECUTE;
                    end
                    CPU_MEMORY_LOAD_REG: begin
                        registers[rd] <= memory_read_data;
                        PC <= PC + 1;
                        CPU_STATE <= CPU_FETCH;
                    end
                    CPU_EXECUTE: begin
                        case (opcode)
                            LDI: begin
                                registers[rd] <= immediate;
                                PC <= PC + 1;
                                CPU_STATE <= CPU_FETCH;

                            end
                            LDM: begin
                                mem_read_en <= 1;
                                memory_read_addr <= {8'h00, immediate};
                                CPU_STATE <= CPU_MEMORY_LOAD_REG;
                            end
                            STR: begin
                                mem_write_en <= 1;
                                memory_write_addr <= {8'h00, immediate};
                                memory_write_data <= registers[rd];
                                PC <= PC + 1;
                                CPU_STATE <= CPU_FETCH;

                            end
                            LDMW: begin
                                mem_read_en <= 1;
                                memory_read_addr <= (registers[rsH] << 8 | registers[rs]);
                                CPU_STATE <= CPU_MEMORY_LOAD_REG;
                            end
                            STRW: begin
                                mem_write_en <= 1;
                                memory_write_addr <= (registers[rsH] << 8 | registers[rs]);
                                memory_write_data <= registers[rd];
                                PC <= PC + 1;
                                CPU_STATE <= CPU_FETCH;
                            end
                            LDID: begin
                                mem_read_en <= 1;
                                memory_read_addr <= {8'h00, registers[rs]};
                                CPU_STATE <= CPU_MEMORY_LOAD_REG;

                            end
                            STRID:begin
                                mem_write_en <= 1;
                                memory_write_addr <= {8'h00, registers[rs]};
                                memory_write_data <= registers[rd];
                                PC <= PC + 1;
                                CPU_STATE <= CPU_FETCH;

                            end
                            ADD: begin
                                result = registers[rd] + registers[rs];
                                registers[rd] <= result[7:0];
                                if (result[9:8] != 0)
                                    overflow_flag <= 1;

                                PC <= PC + 1;
                                CPU_STATE <= CPU_FETCH;

                            end
                            SUB: begin

                                registers[rd] <= registers[rd] - registers[rs];
                                zero_flag <= (registers[rd] - registers[rs] == 8'h00);
                                negative_flag <= (registers[rd] < registers[rs]);
                                PC <= PC + 1;
                                CPU_STATE <= CPU_FETCH;

                            end
                            MUL: begin

                                result = registers[rd] * registers[rs];
                                registers[rd] <= result[7:0];
                                if (result[15:8] != 0)
                                    overflow_flag <= 1;

                                PC <= PC + 1;
                                CPU_STATE <= CPU_FETCH;
                            end
                            SLI: begin
                                registers[rd] <= registers[rd] << immediate;
                                overflow_flag <= (((registers[rd] << immediate) >> immediate) != registers[rd]);
                                PC <= PC + 1;
                                CPU_STATE <= CPU_FETCH;

                            end
                            SRI: begin

                                registers[rd] <= registers[rd] >> immediate;
                                overflow_flag <= (((registers[rd] >> immediate) << immediate) != registers[rd]);
                                PC <= PC + 1;
                                CPU_STATE <= CPU_FETCH;

                            end
                            SHL: begin
                                registers[rd] <= registers[rd] << registers[rs];
                                if ((
                                    (registers[rd] << registers[rs]) >>
                                    registers[rs]) != registers[rd]) begin
                                    overflow_flag <= 1;
                                end
                                PC <= PC + 1;
                                CPU_STATE <= CPU_FETCH;

                            end
                            SHR: begin
                                registers[rd] <= registers[rd] >> registers[rs];
                                if (((registers[rd] >> registers[rs]) << registers[rs]) != registers[rd]) begin
                                    overflow_flag <= 1;
                                end
                                PC <= PC + 1;
                                CPU_STATE <= CPU_FETCH;

                            end
                            AND: begin
                                registers[rd] <= registers[rd] & immediate;
                                if ((registers[rd] & immediate) == 0) begin
                                    zero_flag <= 1;
                                end else zero_flag <= 0;
                                PC <= PC + 1;
                                CPU_STATE <= CPU_FETCH;
                            end
                            OR: begin
                                registers[rd] <= registers[rd] | immediate;
                                if ((registers[rd] | immediate) == 0) begin
                                    zero_flag <= 1;
                                end else zero_flag <= 0;
                                PC <= PC + 1;
                                CPU_STATE <= CPU_FETCH;
                            end
                            XOR: begin
                                registers[rd] <= registers[rd] ^ immediate;
                                if ((registers[rd] ^ immediate) == 0) begin
                                    zero_flag <= 1;
                                end else zero_flag <= 0;
                                PC <= PC + 1;
                                CPU_STATE <= CPU_FETCH;
                            end
                            NOT: begin
                                registers[rd] <= ~registers[rd];
                                if ((~registers[rd]) == 0) begin
                                    zero_flag <= 1;
                                end else zero_flag <= 0;
                                PC <= PC + 1;
                                CPU_STATE <= CPU_FETCH;
                            end
                            JMP: begin
                                PC <= immediate;
                                CPU_STATE <= CPU_FETCH;

                            end
                            JZ: begin
                                if (zero_flag) PC <= immediate;
                                else PC <= PC + 1;
                                CPU_STATE <= CPU_FETCH;

                            end
                            JN: begin
                                if (negative_flag) PC <= immediate;
                                else PC <= PC + 1;
                                CPU_STATE <= CPU_FETCH;

                            end
                            JO: begin
                                if (overflow_flag) PC <= immediate;
                                else PC <= PC + 1;
                                CPU_STATE <= CPU_FETCH;

                            end
                            CMP: begin
                                zero_flag    <= (registers[rd] == registers[rs]);
                                negative_flag <= (registers[rd] < registers[rs]);
                                PC <= PC + 1;
                                CPU_STATE <= CPU_FETCH;

                            end
                            CLO: begin
                                overflow_flag <= 0;
                                PC <= PC + 1;
                                CPU_STATE <= CPU_FETCH;

                            end
                            CLN: begin
                                negative_flag <= 0;
                                PC <= PC + 1;
                                CPU_STATE <= CPU_FETCH;

                            end
                            CLZ: begin
                                zero_flag <= 0;
                                PC <= PC + 1;
                                CPU_STATE <= CPU_FETCH;

                            end
                            NOP: begin
                                PC <= PC + 1;
                                CPU_STATE <= CPU_FETCH;

                            end
                            CALL: begin
                                STACK[SP] <= PC + 1;
                                SP <= SP + 1;
                                PC <=immediate;
                                CPU_STATE <= CPU_FETCH;
                            end
                            RET: begin
                                PC <= STACK[SP-1];
                                SP <= SP - 1;
                                CPU_STATE <= CPU_FETCH;
                            end
                            PUSH: begin
                                STACK[SP] <= registers[rd];
                                SP <= SP + 1;
                                PC <= PC + 1;
                                CPU_STATE <= CPU_FETCH;
                            end
                            POP: begin
                                registers[rd] <= STACK[SP-1];
                                SP <= SP - 1;
                                PC <= PC + 1;
                                CPU_STATE <= CPU_FETCH;
                            end
                            default: begin
                            PC <= PC + 1;
                            CPU_STATE <= CPU_FETCH;

                            end
                        endcase
                    end
                    default: begin
                        CPU_STATE <= CPU_FETCH;
                    end
                endcase
                clockCounter <= 0;
            end else clockCounter <= clockCounter + 1;
        end
    end
    assign led = ~led_direct;
endmodule

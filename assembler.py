import re
import sys

MEMORY_SIZE = 256
FLASH_SIZE = 256
OPCODES = {
    "NOP": 0b000000,
    "LDI": 0b000001,
    "LDM": 0b000010,
    "STR": 0b000011,
    "LDID": 0b000100,
    "STRID": 0b000101,
    "ADD": 0b001010,
    "SUB": 0b001011,
    "SLI": 0b010000,
    "SRI": 0b010001,
    "SHL": 0b010010,
    "SHR": 0b010011,
    "AND": 0b011000,
    "OR": 0b011001,
    "XOR": 0b011010,
    "NOT": 0b011011,
    "JMP": 0b100000,
    "JZ": 0b100001,
    "JN": 0b100010,
    "JO": 0b100011,
    "CMP": 0b100110,
    "CLN": 0b101000,
    "CLZ": 0b101001,
    "CLO": 0b101010,
    "CALL": 0b101110,
    "RET": 0b101111,
    "PUSH": 0b110000,
    "POP": 0b110001,
}
REGISTERS = {
    "r0": 0,
    "r1": 1,
    "r2": 2,
    "r3": 3,
}


def parse_number(value):
    value = value.strip()

    try:
        return int(value, 0)
    except ValueError:
        raise ValueError(f"Invalid number: {value}")


def parse_register(value):
    value = value.strip().lower()

    if value not in REGISTERS:
        raise ValueError(f"Invalid register: {value}")

    return REGISTERS[value]


def remove_comment(line):
    line = line.split(";", 1)[0]
    line = line.split("#", 1)[0]
    line = line.split("/", 1)[0]

    return line.strip()


def parse_source(source):
    instructions = []

    for line_number, raw_line in enumerate(source.splitlines(), 1):
        line = remove_comment(raw_line)

        if not line:
            continue

        # Label:
        if line.endswith(":"):
            label = line[:-1].strip()

            if not re.match(r"^[A-Za-z_][A-Za-z0-9_]*$", label):
                raise ValueError(f"Line {line_number}: invalid label '{label}'")

            instructions.append(("label", label))
            continue

        match = re.match(r"^([A-Za-z_][A-Za-z0-9_]*):\s*(.*)$", line)

        if match:
            label = match.group(1)
            remainder = match.group(2)

            instructions.append(("label", label))

            if not remainder:
                continue

            line = remainder

        parts = line.split(None, 1)

        mnemonic = parts[0].upper()

        if len(parts) == 1:
            operands = []
        else:
            operands = [x.strip() for x in parts[1].split(",")]

        instructions.append((mnemonic, operands))

    return instructions


def first_pass(parsed):
    labels = {}
    pc = 0

    for item in parsed:
        if item[0] == "label":
            label = item[1]

            if label in labels:
                raise ValueError(f"Duplicate label: {label}")

            labels[label] = pc

        else:
            mnemonic = item[0]

            if mnemonic not in OPCODES:
                raise ValueError(f"Unknown instruction: {mnemonic}")

            pc += 1

    return labels


def resolve_register(value):
    value = value.strip()
    value = value[1:3]
    return parse_register(value)


def resolve_value(value, labels):
    value = value.strip()

    # Label
    if value in labels:
        return labels[value]

    # Number
    return parse_number(value)


def assemble_instruction(mnemonic, operands, labels):

    mnemonic = mnemonic.upper()

    if mnemonic not in OPCODES:
        raise ValueError(f"Unknown instruction: {mnemonic}")

    opcode = OPCODES[mnemonic]

    if mnemonic in (
        "NOP",
        "CLZ",
        "CLN",
        "CLO",
        "RET"
    ):
        if operands:
            raise ValueError(f"{mnemonic} takes no operands")

        return [opcode << 2, 0]
    if mnemonic in ("NOT", "POP", "PUSH"):
        if len(operands) != 1:
            raise ValueError(f"{mnemonic} takes no operands")

        rd = parse_register(operands[0])
        byte0 = (opcode << 2) | rd
        return [byte0, 0]
    if mnemonic in ("LDI", "SLI", "SRI", "AND", "OR", "XOR"):
        if len(operands) != 2:
            raise ValueError(f"{mnemonic} requires: {mnemonic} rd, value")

        rd = parse_register(operands[0])

        value = resolve_value(operands[1], labels)

        if not 0 <= value <= 255:
            raise ValueError(f"{mnemonic} value must be 0..255")

        byte0 = (opcode << 2) | rd
        byte1 = value

        return [byte0, byte1]

    if mnemonic == "LDM":
        if len(operands) != 2:
            raise ValueError("LDM requires: LDM rd, address")

        rd = parse_register(operands[0])
        address = resolve_value(operands[1], labels)

        if not 0 <= address <= MEMORY_SIZE - 1:
            raise ValueError(f"Memory address must be 0..{MEMORY_SIZE - 1}")

        byte0 = (opcode << 2) | rd

        return [byte0, address]

    if mnemonic == "LDID":
        if len(operands) != 2:
            raise ValueError("LDID requires: LDID rd, [rs]")

        rd = parse_register(operands[0])
        address = resolve_register(
            operands[1],
        )

        byte0 = (opcode << 2) | rd

        return [byte0, address]

    if mnemonic == "STR":
        if len(operands) != 2:
            raise ValueError("STR requires: STR rd, address")

        rd = parse_register(operands[0])
        address = resolve_value(operands[1], labels)

        if not 0 <= address <= MEMORY_SIZE - 1:
            raise ValueError(f"Memory address must be 0..{MEMORY_SIZE - 1}")

        byte0 = (opcode << 2) | rd

        return [byte0, address]

    if mnemonic == "STRID":
        if len(operands) != 2:
            raise ValueError("STRID requires: STRID rd, [rs]")

        rd = parse_register(operands[0])
        address = resolve_register(
            operands[1],
        )

        byte0 = (opcode << 2) | rd

        return [byte0, address]
    if mnemonic in ("ADD", "SUB", "SHL", "SHR", "CMP"):
        if len(operands) != 2:
            raise ValueError(f"{mnemonic} requires: {mnemonic} rd, rs")

        rd = parse_register(operands[0])
        rs = parse_register(operands[1])

        byte0 = (opcode << 2) | rd
        byte1 = rs

        return [byte0, byte1]

    if mnemonic in ("JMP", "JZ", "JN", "JO", "CALL"):
        if len(operands) != 1:
            raise ValueError(f"{mnemonic} requires: {mnemonic} address")

        address = resolve_value(operands[0], labels)

        if not 0 <= address <= FLASH_SIZE - 1:
            raise ValueError(f"Jump address must be 0..{FLASH_SIZE - 1}")

        byte0 = opcode << 2

        return [byte0, address]

    raise ValueError(f"Assembler does not support {mnemonic}")


def compile_program(source):

    parsed = parse_source(source)

    # Find labels
    labels = first_pass(parsed)

    program = []

    for item in parsed:
        if item[0] == "label":
            continue

        mnemonic = item[0]
        operands = item[1]

        bytes_ = assemble_instruction(mnemonic, operands, labels)

        program.extend(bytes_)

    if len(program) > FLASH_SIZE - 1:
        raise ValueError(
            f"Program is {len(program)} bytes, but CPU only has {FLASH_SIZE - 1} program bytes"
        )

    return program, labels


def print_binary(program):

    for i, byte in enumerate(program):
        print(f"programs[{i}] = 8'b{byte:08b};")


def print_hex(program):

    for i, byte in enumerate(program):
        print(f"programs[{i}] = 8'h{byte:02X};")


def print_verilog(program):

    print("initial begin")

    for i, byte in enumerate(program):
        print(f"    programs[{i}] = 8'h{byte:02X};")

    # Fill remaining memory
    for i in range(len(program), FLASH_SIZE):
        print(f"    programs[{i}] = 8'h00;")

    print("end")


def main():

    if len(sys.argv) != 2:
        print("Usage: python compiler.py program.asm")
        sys.exit(1)

    filename = sys.argv[1]

    try:
        with open(filename, "r") as f:
            source = f.read()

        program, labels = compile_program(source)

        print("Labels:")
        for name, address in labels.items():
            print(f"  {name} = {address}")

        print()
        with open(f"{filename}.bin", "w") as f:
            for i, byte in enumerate(program):
                if i == 0 or i % 2 != 0:
                    f.write(f"{byte:02X}")
                else:
                    f.write(f" {byte:02X}")

    except Exception as e:  # noqa: BLE001
        print(f"Error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()

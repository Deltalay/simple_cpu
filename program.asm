start:
    LDI r0, 0x01
    LDI r2, 0x01

loop:
    STR r0, 255

    LDI r1, 0x05

delay:
    SUB r1, r2
    JZ next
    JMP delay

next:
    SHL r0, r2

    LDI r1, 0x40
    CMP r0, r1
    JZ reset
    JMP loop

reset:
    LDI r0, 0x01
    JMP loop
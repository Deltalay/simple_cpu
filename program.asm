
start:
    LDI r0, 0x01
    LDI r2, 0x00
    STR r2, 0x01
    LDI r2, 0x01

loop:
    STR r0, 255

    PUSH r1
    CALL delay
    POP r1

direction_check:
    LDM r2, 0x01
    CLO
    SRI r2, 0x01
    JO reverse
    JMP next

next:
    SLI r0, 1
    LDI r1, 0x20
    CMP r0, r1
    JZ turn_reverse
    JMP loop

turn_reverse:
    LDI r2, 1
    STR r2, 0x01
    JMP loop

reverse:
    SRI r0, 1

    LDI r1, 0x01
    CMP r0, r1
    JZ turn_forward
    JMP loop

turn_forward:
    LDI r2, 0
    STR r2, 0x01
    JMP loop


; Delay subroutine
delay:
    LDI r3, 0xBF
    LDI r1, 0xFF

delay_loop:
    LDI r2, 0x01
    SUB r1, r2
    JZ delay_outer
    JMP delay_loop

delay_outer:
    LDI r2, 0x01
    SUB r3, r2
    JZ delay_done

    LDI r1, 0xFF
    JMP delay_loop

delay_done:
    RET

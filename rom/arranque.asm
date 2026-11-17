; ============================================================================
; La Geste d'Artillac - versión ROM ASCII16: arranque (banco 0, página 1)
; Claude para araubi, 2026.
; ============================================================================
SLOTROM   equ 8380h
V_BANCO   equ 8383h
V_DIR     equ 8384h
RSLREG    equ 0138h
EXPTBL    equ 0FCC1h

        org 4000h
        db "AB"
        dw inicio
        dw 0,0,0
        ds 6
inicio:
        di
        call RSLREG             ; slot de la página 1 = el nuestro
        rrca
        rrca
        and 3
        ld c,a
        ld b,0
        ld hl,EXPTBL
        add hl,bc
        ld a,(hl)
        and 80h
        or c
        ld c,a
        jp p,no_exp
        inc hl
        inc hl
        inc hl
        inc hl
        ld a,(hl)               ; SLTTBL: subslot de la página 1 en los bits 2-3
        and 0Ch
        or c
        ld c,a
no_exp: ld a,c
        ld (SLOTROM),a
        ld a,(002Bh)            ; BIOS: bit 7 = 1 si es de 50 Hz
        rlca
        ld a,0
        jr c,es50
        ld a,6
es50:   ld (838Ch),a            ; HZ60 del lector (gancho de la música)
        xor a
        ld (838Dh),a            ; N_BLOQUE del lector (espera tecla en Infogrames y título)
        ld hl,LECTOR            ; lector a 8400h
        ld de,8400h
        ld bc,FIN_LECTOR-LECTOR
        ldir
        ld hl,ETAPA2            ; etapa 2 del cargador (ya descifrada) a 8000h
        ld de,8000h
        ld bc,02CAh
        ldir
        ld hl,8400h             ; su carga_bloque (806Eh) pasa a leer de la ROM
        ld (806Fh),hl
        ld a,0C3h
        ld (806Eh),a
        ld a,1                  ; el flujo de bloques empieza en el banco 1, 4000h
        ld (V_BANCO),a
        ld hl,4000h
        ld (V_DIR),hl
        jp 8003h                ; como si la etapa 1 la hubiera cargado de cinta

        ; firmas para que openMSX y BlueMSX reconozcan ASCII16 (nunca se ejecutan)
        ld (77FFh),a
        ld (77FFh),a
        ld (77FFh),a
        ld (77FFh),a
        ld (77FFh),a
        ld (7000h),a
LECTOR:
        incbin "lector.bin"
FIN_LECTOR:
ETAPA2:
        incbin "etapa2.bin"

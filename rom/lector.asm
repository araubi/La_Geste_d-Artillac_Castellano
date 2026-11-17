; ============================================================================
; La Geste d'Artillac - versión ROM (ASCII16): lector de la ROM que sustituye a la cinta
; Se copia a la RAM en 8400h (página 2, libre durante todo el juego: la etapa 2
; ocupa 8000h-836Fh y la pila baja desde 9000h).
; Claude para araubi, 2026.
; ============================================================================
SLOTROM   equ 8380h        ; slot de la ROM (formato F000SSPP)
GUARDA_A8 equ 8381h
GUARDA_SUB equ 8382h
V_BANCO   equ 8383h        ; banco ASCII16 del dato que se lee
V_DIR     equ 8384h        ; dirección dentro de la ventana 4000h-7FFFh
V_DEST    equ 8386h
V_LONG    equ 8388h
V_TROZO   equ 838Ah
BUF       equ 8E00h        ; 256 bytes de paso
BANCOREG  equ 6000h        ; registro del banco de la página 1 (ASCII16)

        org 8400h
; ---- entrada 1: sustituye a carga_bloque (806Eh) de la etapa 2 ----
; HL = destino, DE = longitud. Lee el siguiente bloque del flujo, en orden.
lee_bloque:
        jp bloque_espera
; ---- entrada 2: sustituye a carga_canto (9803h) del motor ----
; A = número de canto (1-11). Lo copia en 0100h.
lee_canto:
        dec a
        ld l,a
        ld h,0
        add hl,hl
        add hl,hl               ; 4 bytes por canto: banco, dirección (2), ...
        ld de,TABLA_CANTOS
        add hl,de
        ld a,(hl)
        ld (V_BANCO),a
        inc hl
        ld e,(hl)
        inc hl
        ld d,(hl)
        ld (V_DIR),de
        ld a,(0AF7Bh)           ; longitud del canto (la tabla del motor ya está en AF75h)
        ld e,a
        ld a,(0AF7Ch)
        ld d,a
        ld hl,0100h
        call copia
        and a                   ; acarreo a 0 = carga correcta
        ret

; ---- copia DE bytes de la ROM (V_BANCO:V_DIR) a HL, por trozos de 256 bytes ----
copia:
        ld (V_DEST),hl
        ld (V_LONG),de
cp_bucle:
        ld hl,(V_LONG)
        ld a,h
        or l
        jr z,cp_fin
        ld bc,256               ; trozo = mín(256, longitud, lo que queda del banco)
        or a
        sbc hl,bc
        jr nc,cp_t1
        ld bc,(V_LONG)
cp_t1:  ld hl,8000h
        ld de,(V_DIR)
        or a
        sbc hl,de               ; HL = lo que queda en la ventana
        or a
        sbc hl,bc
        jr nc,cp_t2
        add hl,bc
        ld b,h
        ld c,l
cp_t2:  ld (V_TROZO),bc
        di
        call rom_on
        ld a,(V_BANCO)
        ld (BANCOREG),a
        ld hl,(V_DIR)
        ld de,BUF
        ld bc,(V_TROZO)
        ldir
        call rom_off
        ld a,h                  ; ¿fin de la ventana? -> banco siguiente
        cp 80h
        jr nz,cp_t3
        ld h,40h
        ld a,(V_BANCO)
        inc a
        ld (V_BANCO),a
cp_t3:  ld (V_DIR),hl
        ld hl,BUF
        ld de,(V_DEST)
        ld bc,(V_TROZO)
        ldir
        ld (V_DEST),de
        ld hl,(V_LONG)
        ld bc,(V_TROZO)
        or a
        sbc hl,bc
        ld (V_LONG),hl
        jr cp_bucle
cp_fin: ei
        ret

; ---- pone el slot de la ROM en la página 1 (con interrupciones cortadas) ----
rom_on:
        in a,(0A8h)
        ld (GUARDA_A8),a
        ld a,(SLOTROM)
        ld b,a
        and 3
        ld c,a                  ; C = slot primario de la ROM
        rlca
        rlca
        ld d,a
        ld a,(GUARDA_A8)
        and 0F3h
        or d
        ld e,a                  ; E = A8 con la ROM en la página 1
        bit 7,b
        jr z,ro_prim
        ld a,c                  ; slot expandido: página 3 al primario para tocar FFFFh
        rrca
        rrca
        ld d,a
        ld a,(GUARDA_A8)
        and 3Fh
        or d
        out (0A8h),a
        ld a,(0FFFFh)
        cpl
        ld (GUARDA_SUB),a
        and 0F3h
        ld d,a
        ld a,b
        and 0Ch
        or d
        ld (0FFFFh),a
ro_prim:
        ld a,e
        out (0A8h),a
        ret

; ---- deja la página 1 como estaba ----
rom_off:
        ld a,(SLOTROM)
        bit 7,a
        jr z,rf_prim
        and 3
        rrca
        rrca
        ld d,a
        ld a,(GUARDA_A8)
        and 3Fh
        or d
        out (0A8h),a
        ld a,(GUARDA_SUB)
        ld (0FFFFh),a
rf_prim:
        ld a,(GUARDA_A8)
        out (0A8h),a
        ret

TABLA_CANTOS:                   ; la rellena build_rom.py: banco, dirección, 0
        ds 4*11
fin_lector:
; ---- gancho de la música de la creación (H.KEYI): a 60 Hz se salta 1 de cada 6 interrupciones
; para que suene al tempo de 50 Hz (idea del reproductor de MSXlib, Néstor Sancho). HZ60: 0 = 50 Hz.
HZ60      equ 838Ch
musica_hook:
        ld hl,HZ60
        ld a,(hl)
        or a
        jp z,0A13Ah             ; 50 Hz: reproductor original
        dec (hl)
        jp nz,0A13Ah
        ld (hl),6               ; 1 de cada 6: no avanza la música
        ret

; ---- antes de leer el 2.º bloque (título) y el 3.º (creación) espera una tecla:
; así la pantalla de Infogrames y la del título no se van solas (en cinta duraban la carga) ----
N_BLOQUE  equ 838Dh
bloque_espera:
        push hl
        push de
        ld hl,N_BLOQUE
        inc (hl)
        ld a,(hl)
        cp 2
        jr z,be_tecla
        cp 3
        jr nz,be_sigue
be_tecla:
        ld ix,0156h             ; KILBUF
        call 8000h              ; llama_bios_ix de la etapa 2
        ld ix,009Fh             ; CHGET
        call 8000h
        ld ix,0156h
        call 8000h
be_sigue:
        pop de
        pop hl
        jp copia

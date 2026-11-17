; ============================================================================
; La Geste d'Artillac (Infogrames, 1985) - MSX - cinta 1 «Liminaire»
; Etapa 2 del cargador: bloque 2 de la cinta, 8000h-82C9h, cifrado con XOR 76h.
; Lo carga la etapa 1 (32 bytes que el BLOAD deja en FF07h = gancho H.READ).
; - busca RAM en los cuatro slots y la pone en las páginas 0 y 1
; - cambia la interrupción 0038h a 82BDh, que llama a la BIOS entre slots
; - carga y descomprime la pantalla de Infogrames y la del título (RLE a VRAM)
; - carga la creación del personaje (9000h), la ejecuta y carga el motor
; El código original es (c) Infogrames 1985. Comentarios: Claude para araubi (2026).
;
; REPOSITORIO: sin datos del juego. Cada «defb» original es aquí «defs n,RELLENO»; build.py
; ensambla con RELLENO=00h y FFh y rellena esos huecos con los bytes de las cintas del usuario.
; Licencia del desensamblado (comentarios, etiquetas y estructura): CC BY-NC-SA 4.0, araubi 2026.
; El código y los datos originales son de Infogrames; ninguna licencia de este repositorio los cubre.
; ============================================================================


	org	08000h
l82cah:	equ 0x82ca


; BLOCK 'codigo0' (start 0x8000 end 0x81b2)
llama_bios_ix:
	jp bios_entre_slots		;8000
				; >>> entrada desde la etapa 1
	di			;8003
	call busca_ram		;8004
				; >>> interrupción -> 82BDh
	ld a,0c3h		;8007
	ld (00038h),a		;8009
	ld hl,interrupcion		;800c
	ld (00039h),hl		;800f
	ld sp,09000h		;8012
	ei			;8015
				; >>> bloque 3: pantalla de Infogrames (RLE)
	ld hl,09000h		;8016
	ld de,00796h		;8019
	call carga_bloque		;801c
	ld a,001h		;801f
	ld (0f3ebh),a		;8021
				; >>> INIGRP: SCREEN 2
	ld ix,00072h		;8024
	call bios_entre_slots		;8028
	ld ix,00041h		;802b
	call bios_entre_slots		;802f
	call rle_a_vram		;8032
	ld ix,00044h		;8035
	call bios_entre_slots		;8039
				; >>> bloque 4: pantalla del título (RLE)
	ld hl,09000h		;803c
	ld de,01c1ah		;803f
	call carga_bloque		;8042
	ld ix,00041h		;8045
	call bios_entre_slots		;8049
	call rle_a_vram		;804c
	ld ix,00044h		;804f
	call bios_entre_slots		;8053
				; >>> bloque 5: creación del personaje, se ejecuta
	ld hl,09000h		;8056
	ld de,01c30h		;8059
	call carga_bloque		;805c
	call 09000h		;805f
				; >>> bloque 6: el motor
	ld hl,09000h		;8062
	ld de,02dd0h		;8065
	call carga_bloque		;8068
	jp 09000h		;806b
carga_bloque:
				; >>> carga DE bytes en HL con TAPION/TAPIN, XOR 76h
	push de			;806e
	push hl			;806f
	ld ix,000e1h		;8070
	call bios_entre_slots		;8074
	ld ix,000e4h		;8077
l807bh:
	call bios_entre_slots		;807b
	pop hl			;807e
	pop de			;807f
	jr c,error_reinicia		;8080
	xor 076h		;8082
	ld (hl),a			;8084
	inc hl			;8085
	dec de			;8086
	ld a,d			;8087
	or e			;8088
	jr z,l808fh		;8089
	push de			;808b
	push hl			;808c
	jr l807bh		;808d
l808fh:
	ld ix,000e7h		;808f
	call bios_entre_slots		;8093
	ret			;8096
error_reinicia:
				; >>> error de cinta: borra la memoria y salta a 0000h
	ld ix,000e7h		;8097
	call bios_entre_slots		;809b
	di			;809e
	ld hl,080a9h		;809f
	ld de,080adh		;80a2
	ld bc,00000h		;80a5
	ld (hl),000h		;80a8
	ldir		;80aa
	jp 00000h		;80ac
rle_a_vram:
				; >>> RLE: pares (valor, cuenta); cuenta 0 = fin. Patrones en 0000h y colores en 2000h
	ld ix,09000h		;80af
	ld hl,00000h		;80b3
	call rle_trozo		;80b6
	ld hl,02000h		;80b9
	call rle_trozo		;80bc
	ret			;80bf
rle_trozo:
	ld a,(ix+001h)		;80c0
	and a			;80c3
	jr z,l80dfh		;80c4
	ld b,a			;80c6
	ld c,(ix+000h)		;80c7
	push ix		;80ca
	ld ix,0004dh		;80cc
l80d0h:
	ld a,c			;80d0
	call bios_entre_slots		;80d1
	inc hl			;80d4
	djnz l80d0h		;80d5
	pop ix		;80d7
	inc ix		;80d9
	inc ix		;80db
	jr rle_trozo		;80dd
l80dfh:
	inc ix		;80df
	inc ix		;80e1
	ret			;80e3
guarda_slots:
	ld a,(0ffffh)		;80e4
	cpl			;80e7
	ld (l82cah),a		;80e8
	in a,(0a8h)		;80eb
	ld (v_a8),a		;80ed
	ret			;80f0
busca_ram:
	di			;80f1
	ld de,082cdh		;80f2
	ld b,004h		;80f5
	call guarda_slots		;80f7
l80fah:
	push bc			;80fa
	ld a,0c5h		;80fb
	sub b			;80fd
	ld c,a			;80fe
	ld b,0fch		;80ff
	ld a,(bc)			;8101
	or a			;8102
	ld hl,l8288h		;8103
	jr z,l810bh		;8106
	ld hl,l828dh		;8108
l810bh:
	ld bc,00005h		;810b
	ldir		;810e
	pop bc			;8110
	djnz l80fah		;8111
	ld hl,082cdh		;8113
	ld bc,0008ch		;8116
	ldir		;8119
	ld hl,00000h		;811b
	ld (082cdh),hl		;811e
	ld (082e1h),hl		;8121
	ld (082f5h),hl		;8124
	ld (08309h),hl		;8127
	ld bc,05000h		;812a
	ld hl,082cdh		;812d
	call l81c7h		;8130
	ld hl,082cdh		;8133
	ld c,000h		;8136
	call sub_818bh		;8138
	jr nz,l8143h		;813b
	ld hl,04000h		;813d
	ld (082cbh),hl		;8140
l8143h:
	call guarda_slots		;8143
	ld hl,082f5h		;8146
	ld c,028h		;8149
	call sub_818bh		;814b
	jr nz,l8156h		;814e
	ld hl,llama_bios_ix		;8150
	ld (082cbh),hl		;8153
l8156h:
	call guarda_slots		;8156
	ld a,(082cch)		;8159
	cp 001h		;815c
	jr nz,l8187h		;815e
	ld hl,l81b2h		;8160
	ld de,00100h		;8163
	ld bc,000afh		;8166
	ldir		;8169
	ld hl,00153h		;816b
	ld (00128h),hl		;816e
	call 00100h		;8171
	ld c,050h		;8174
	ld hl,0831dh		;8176
	call sub_818bh		;8179
	ld c,078h		;817c
	call guarda_slots		;817e
	ld hl,08345h		;8181
	call sub_818bh		;8184
l8187h:
	call guarda_slots		;8187
	ret			;818a
sub_818bh:
	ld b,028h		;818b
l818dh:
	ld a,(hl)			;818d
	inc hl			;818e
	inc c			;818f
	or a			;8190
	jr nz,l8196h		;8191
	djnz l818dh		;8193
	ret			;8195
l8196h:
	ld de,00013h		;8196
	add hl,de			;8199
	ld a,(hl)			;819a
	sbc hl,de		;819b
	or a			;819d
	jr z,l818dh		;819e
	dec hl			;81a0
	ld (hl),003h		;81a1
	add hl,de			;81a3
	inc hl			;81a4
	ld (hl),003h		;81a5
	dec c			;81a7
	ld e,c			;81a8
	ld hl,00000h		;81a9
	call pon_slot		;81ac
	or 001h		;81af
	ret			;81b1

; BLOCK 'datos1' (start 0x81b2 end 0x81c7)
l81b2h:
	defs 16,RELLENO	;81b2
	defs 5,RELLENO	;81c2

; BLOCK 'codigo2' (start 0x81c7 end 0x827c)
l81c7h:
prueba_ram:
	ld a,(hl)			;81c7
	or a			;81c8
	jr z,l8200h		;81c9
	ld a,(l82cah)		;81cb
	push af			;81ce
	ld a,(v_a8)		;81cf
	push af			;81d2
	push bc			;81d3
	push hl			;81d4
	ld hl,00000h		;81d5
	ld e,c			;81d8
	call pon_slot		;81d9
	ld de,01fffh		;81dc
l81dfh:
	ld a,(hl)			;81df
	ld b,a			;81e0
	cpl			;81e1
	ld (hl),a			;81e2
	ld a,(hl)			;81e3
	cpl			;81e4
	ld (hl),a			;81e5
	cp b			;81e6
	jr nz,l81f3h		;81e7
	inc hl			;81e9
	dec de			;81ea
	ld a,d			;81eb
	or e			;81ec
	jr nz,l81dfh		;81ed
	ld a,001h		;81ef
	jr l81f5h		;81f1
l81f3h:
	ld a,000h		;81f3
l81f5h:
	pop hl			;81f5
	pop bc			;81f6
	ld d,a			;81f7
	pop af			;81f8
	out (0a8h),a		;81f9
	pop af			;81fb
	ld (0ffffh),a		;81fc
	ld (hl),d			;81ff
l8200h:
	inc c			;8200
	inc hl			;8201
	djnz l81c7h		;8202
	ret			;8204
pon_slot:
	ld b,000h		;8205
	ld c,000h		;8207
	ld d,000h		;8209
l820bh:
	ld a,d			;820b
	cp e			;820c
	jr z,l8226h		;820d
	inc d			;820f
	inc b			;8210
	ld a,b			;8211
	cp 005h		;8212
	jr nz,l820bh		;8214
	ld b,000h		;8216
	inc c			;8218
	ld a,c			;8219
	cp 004h		;821a
	jr nz,l820bh		;821c
	ld c,000h		;821e
	ld a,h			;8220
	add a,020h		;8221
	ld h,a			;8223
	jr l820bh		;8224
l8226h:
	ld a,c			;8226
	call sub_8261h		;8227
	ld c,a			;822a
	ld a,h			;822b
	call sub_826fh		;822c
	ld d,a			;822f
	ld a,(v_a8)		;8230
	ld i,a		;8233
	ld a,b			;8235
	or a			;8236
	jr z,l8255h		;8237
	dec a			;8239
	call sub_8261h		;823a
	ld b,a			;823d
	ld a,i		;823e
	and 03fh		;8240
	ld e,a			;8242
	ld a,c			;8243
	and 0c0h		;8244
	or e			;8246
	out (0a8h),a		;8247
	ld a,(0ffffh)		;8249
	or d			;824c
	cpl			;824d
	ld e,a			;824e
	ld a,b			;824f
	and d			;8250
	or e			;8251
	ld (0ffffh),a		;8252
l8255h:
	ld a,i		;8255
	cpl			;8257
	or d			;8258
	cpl			;8259
	ld e,a			;825a
	ld a,c			;825b
	and d			;825c
	or e			;825d
	out (0a8h),a		;825e
	ret			;8260
sub_8261h:
	push hl			;8261
	ld hl,l827ch		;8262
	or a			;8265
	jr z,l826ch		;8266
l8268h:
	dec a			;8268
	inc hl			;8269
	jr nz,l8268h		;826a
l826ch:
	ld a,(hl)			;826c
	pop hl			;826d
	ret			;826e
sub_826fh:
	push hl			;826f
	ld hl,l8280h		;8270
	and 0c0h		;8273
l8275h:
	jr z,l826ch		;8275
	inc hl			;8277
	sub 020h		;8278
	jr l8275h		;827a

; BLOCK 'datos3' (start 0x827c end 0x8292)
l827ch:
	defs 4,RELLENO	;827c
l8280h:
	defs 8,RELLENO	;8280
l8288h:
	defs 5,RELLENO	;8288
l828dh:
	defs 5,RELLENO	;828d

; BLOCK 'codigo4' (start 0x8292 end 0x82c9)
bios_entre_slots:
				; >>> llama a la rutina BIOS de IX con la BIOS en las páginas 0-1 y luego deja la RAM
	push af			;8292
	ld a,(v_a8)		;8293
	and 03fh		;8296
	out (0a8h),a		;8298
	ld a,(l82cah)		;829a
	and 0f0h		;829d
	ld (0ffffh),a		;829f
	ld a,(v_a8)		;82a2
	and 0f0h		;82a5
	out (0a8h),a		;82a7
	pop af			;82a9
	call sub_82bbh		;82aa
	push af			;82ad
	ld a,(v_a8)		;82ae
	out (0a8h),a		;82b1
	ld a,(l82cah)		;82b3
	ld (0ffffh),a		;82b6
	pop af			;82b9
	ret			;82ba
sub_82bbh:
	jp (ix)		;82bb
interrupcion:
	push ix		;82bd
	ld ix,00038h		;82bf
	call bios_entre_slots		;82c3
	pop ix		;82c6
	ret			;82c8

; BLOCK 'datos5' (start 0x82c9 end 0x82ca)
v_a8:
	defs 1,RELLENO	;82c9


; ============================================================================
; La Geste d'Artillac (Infogrames, 1985) - MSX - versión francesa en cinta
; Bloque 6 de la cinta 1 («Liminaire»): MOTOR DEL JUEGO, 9000h-BDCFh (11.728 bytes)
; En la cinta va cifrado con XOR 76h; aquí está ya descifrado.
; Desensamblado y comentado por Claude para araubi (2026). Reensambla idéntico
; con sjasmplus o pasmo.  El código original es (c) Infogrames 1985.
;
; Mapa de memoria durante la partida:
;   0000h-00FFh  RAM: vector de interrupción 0038h -> JP 82BDh (puesto por la etapa 2)
;   0100h-5FFFh  RAM: el «Chant» (canto) cargado de la cinta 2 (hasta 24 KB)
;        0100h  fichas de párrafo, 8 bytes cada una (párrafo n en 0100h+8n)
;        0280h  listas de 4 opciones (4 bytes)      0300h  listas de 8 opciones (8 bytes)
;        0380h  opciones simples: pares (texto, destino)
;        0480h  opciones con condiciones, 16 bytes cada una
;        0790h  textos de párrafo, cadenas terminadas en 7Fh, en orden
;        [AF75h] textos de las opciones   [AF77h] dibujos grandes   [AF79h] dibujos laterales
;   8000h-82C9h  etapa 2 del cargador (sigue en uso: llamadas a la BIOS entre slots)
;   9000h-BDCFh  este motor;  pila por debajo de 9000h
;   E000h-E0B2h  hoja del personaje (lo que se graba en «à suivre»)
;        E000-E007 características (Force, Dextérité, Chance, Intelligence,
;                  Volonté, Charisme, Habileté, Défense)   E008 puntos de vida
;        E009 canto actual  E00A párrafo actual  E00B/E00C párrafos anteriores
;        E00D hambre  E00E comidas (repas)  E00F  E010 peso cargado
;        E011+n situación del objeto n (54 objetos)   E047+n datos del objeto n
;   E200h        1 = arrancar cargando un personaje grabado
;
; REPOSITORIO: sin datos del juego. Cada «defb» original es aquí «defs n,RELLENO»; build.py
; ensambla con RELLENO=00h y FFh y rellena esos huecos con los bytes de las cintas del usuario.
; Licencia del desensamblado (comentarios, etiquetas y estructura): CC BY-NC-SA 4.0, araubi 2026.
; El código y los datos originales son de Infogrames; ninguna licencia de este repositorio los cubre.
; ============================================================================


	org	09000h


; BLOCK 'codigo0' (start 0x9000 end 0x9f4b)
inicio_motor:
				; >>> arranque: pantalla, marco y ventanas
	call inicia_pantalla		;9000
	call dibuja_marco		;9003
				; >>> ¿se pidió cargar un personaje desde el menú de creación?
	ld a,(0e200h)		;9006
	and a			;9009
	jr z,comprueba_canto		;900a
	ld a,001h		;900c
	ld (0e009h),a		;900e
	push hl			;9011
	push hl			;9012
	jp carga_personaje		;9013
comprueba_canto:
				; >>> ¿está en memoria el canto en el que está el personaje?
	ld a,(0e009h)		;9016
	ld hl,v_canto_cargado		;9019
	cp (hl)			;901c
	jp nz,cambia_canto		;901d
bucle_parrafo:
				; >>> --- BUCLE PRINCIPAL: muestra el párrafo [E00A] del canto actual ---
	xor a			;9020
	ld (lafd9h),a		;9021
	ld (lafd6h),a		;9024
	ld a,003h		;9027
	call imprime_mensaje		;9029
				; >>> IX = ficha de 8 bytes del párrafo: 0100h + 8*párrafo
	ld a,(0e00ah)		;902c
	ld h,000h		;902f
	ld l,a			;9031
	add hl,hl			;9032
	add hl,hl			;9033
	add hl,hl			;9034
	ld (lafe2h),hl		;9035
	ld de,00100h		;9038
	add hl,de			;903b
	ld (lafe6h),hl		;903c
	ld ix,(lafe6h)		;903f
	ld hl,lafdfh		;9043
				; >>> +5: dibujo lateral (bits 0-5)
	ld a,(ix+005h)		;9046
	and 03fh		;9049
	cp (hl)			;904b
	jr z,l9077h		;904c
	ld (hl),a			;904e
	and a			;904f
	jr z,l9069h		;9050
	ld a,000h		;9052
	call imprime_mensaje		;9054
	ld hl,lbccfh		;9057
	ld (v_dibujos),hl		;905a
	ld hl,(laf79h)		;905d
	ld a,(lafdfh)		;9060
	dec a			;9063
	call dibuja_dibujo_n		;9064
	jr l9077h		;9067
l9069h:
	ld hl,dibujos_marco		;9069
	ld (v_dibujos),hl		;906c
	ld hl,00000h		;906f
	ld a,002h		;9072
	call dibuja_baldosas		;9074
l9077h:
				; >>> +4: animación del recuadro lateral
	ld a,(ix+004h)		;9077
	call animacion_lateral		;907a
	ld ix,(lafe6h)		;907d
	ld a,(0e00ah)		;9081
	call texto_parrafo		;9084
				; >>> +2 = 10h: párrafo que pide el código (PANOS)
	ld a,(ix+002h)		;9087
	cp 010h		;908a
	jp z,parrafo_codigo		;908c
				; >>> +1 bit 7: el párrafo mata
	ld a,(ix+001h)		;908f
	add a,a			;9092
	add a,a			;9093
	jr nc,l909bh		;9094
	ld a,003h		;9096
	jp muerte		;9098
l909bh:
				; >>> +0: cambio de característica (bits 7-5 cuál, 4-1 cuánto, bit 0 signo)
	ld a,(ix+000h)		;909b
	ld c,a			;909e
	srl a		;909f
	srl a		;90a1
	srl a		;90a3
	srl a		;90a5
	srl a		;90a7
	ld e,a			;90a9
	ld d,000h		;90aa
	ld hl,0e000h		;90ac
	add hl,de			;90af
	ld a,c			;90b0
	and 01fh		;90b1
	srl a		;90b3
	jr nc,l90b9h		;90b5
	neg		;90b7
l90b9h:
	add a,(hl)			;90b9
	jp p,l90c3h		;90ba
	xor a			;90bd
	ld (hl),a			;90be
	xor a			;90bf
	jp muerte		;90c0
l90c3h:
	cp 010h		;90c3
	jr c,l90c9h		;90c5
	ld a,00fh		;90c7
l90c9h:
	ld (hl),a			;90c9
				; >>> +1: cambio de puntos de vida (bits 5-1 cuánto, bit 0 signo)
	ld a,(ix+001h)		;90ca
	and 03fh		;90cd
	srl a		;90cf
	jr nc,l90d5h		;90d1
	neg		;90d3
l90d5h:
	ld iy,0e000h		;90d5
	add a,(iy+008h)		;90d9
	jp p,l90e0h		;90dc
	xor a			;90df
l90e0h:
	cp 020h		;90e0
	jr c,l90e6h		;90e2
	ld a,01fh		;90e4
l90e6h:
	ld (iy+008h),a		;90e6
	and a			;90e9
	jr nz,l910eh		;90ea
	ld a,(ix+002h)		;90ec
	and 00fh		;90ef
	jr z,l9109h		;90f1
	ld (0e00ah),a		;90f3
	ld hl,(laf75h)		;90f6
	ld (v_cadena),hl		;90f9
	call imprime		;90fc
l90ffh:
	call espera_tecla		;90ff
	cp 00dh		;9102
	jr nz,l90ffh		;9104
	jp bucle_parrafo		;9106
l9109h:
	ld a,001h		;9109
	jp muerte		;910b
l910eh:
				; >>> +6: hambre
	ld a,(ix+006h)		;910e
	and 03fh		;9111
	ld hl,0e00dh		;9113
	add a,(hl)			;9116
	cp 020h		;9117
	jr c,l912eh		;9119
	ld hl,0e008h		;911b
	dec (hl)			;911e
	jp z,l9109h		;911f
	ld a,(0e00fh)		;9122
	cp 004h		;9125
	jr z,l912dh		;9127
	inc a			;9129
	ld (0e00fh),a		;912a
l912dh:
	xor a			;912d
l912eh:
	ld (0e00dh),a		;912e
	ld a,(0e008h)		;9131
	and a			;9134
	jr nz,l913ah		;9135
	jp l9109h		;9137
l913ah:
				; >>> +7: comidas
	ld a,(0e00eh)		;913a
	add a,(ix+007h)		;913d
	ld (0e00eh),a		;9140
	jp p,l914ah		;9143
	xor a			;9146
	ld (0e00eh),a		;9147
l914ah:
	ld a,(ix+001h)		;914a
	add a,a			;914d
	jr nc,l9160h		;914e
	ld a,(ix+003h)		;9150
	ld (v_opcion),a		;9153
l9156h:
	call muestra_opcion		;9156
	cp 00dh		;9159
	jr nz,l9156h		;915b
	jp l91d3h		;915d
l9160h:
				; >>> +3: lista de opciones (bit 7: lista de 8 en 0300h; si no, de 4 en 0280h)
	ld a,(ix+003h)		;9160
	ld (lafe2h),a		;9163
	add a,a			;9166
	jr nc,l916dh		;9167
	ld a,008h		;9169
	jr l916fh		;916b
l916dh:
	ld a,004h		;916d
l916fh:
	ld (lafdah),a		;916f
	ld a,(lafe2h)		;9172
	and 07fh		;9175
	ld h,000h		;9177
	ld l,a			;9179
	add hl,hl			;917a
	add hl,hl			;917b
	ld a,(lafdah)		;917c
	cp 004h		;917f
	jr z,l918ah		;9181
	add hl,hl			;9183
	ld de,00300h		;9184
	add hl,de			;9187
	jr l918eh		;9188
l918ah:
	ld de,00280h		;918a
	add hl,de			;918d
l918eh:
	ld (lafe8h),hl		;918e
	ld a,01fh		;9191
	ld (lafdbh),a		;9193
l9196h:
	ld a,(lafd9h)		;9196
	and a			;9199
	jp p,l91a4h		;919a
	ld a,(lafdah)		;919d
	dec a			;91a0
	ld (lafd9h),a		;91a1
l91a4h:
	ld hl,lafdah		;91a4
	cp (hl)			;91a7
	jr nz,l91aeh		;91a8
	xor a			;91aa
	ld (lafd9h),a		;91ab
l91aeh:
	ld b,000h		;91ae
	ld c,a			;91b0
	ld hl,(lafe8h)		;91b1
	add hl,bc			;91b4
	ld a,(hl)			;91b5
	and a			;91b6
	jr nz,l91c9h		;91b7
	ld hl,lafd9h		;91b9
	ld a,(lafdbh)		;91bc
	cp 01eh		;91bf
	jr nz,l91c6h		;91c1
	dec (hl)			;91c3
	jr l9196h		;91c4
l91c6h:
	inc (hl)			;91c6
	jr l9196h		;91c7
l91c9h:
	ld (v_opcion),a		;91c9
	call muestra_opcion		;91cc
	cp 00dh		;91cf
	jr nz,l9196h		;91d1
l91d3h:
	ld a,(v_opcion)		;91d3
	add a,a			;91d6
	jr c,l91e5h		;91d7
	inc a			;91d9
	ld c,a			;91da
	ld b,000h		;91db
	ld hl,00380h		;91dd
	add hl,bc			;91e0
	ld a,(hl)			;91e1
	jp l92d6h		;91e2
l91e5h:
	ld ix,(lafeah)		;91e5
	ld a,(ix+005h)		;91e9
	ld (lafddh),a		;91ec
	ld a,(ix+008h)		;91ef
	and 00fh		;91f2
	ld (lafdch),a		;91f4
	call sub_96a8h		;91f7
	ld a,(ix+006h)		;91fa
	ld (lafddh),a		;91fd
	ld a,(ix+008h)		;9200
	srl a		;9203
	srl a		;9205
	srl a		;9207
	srl a		;9209
	ld (lafdch),a		;920b
	call sub_96a8h		;920e
	ld a,(ix+007h)		;9211
	ld (lafddh),a		;9214
	ld a,(ix+00bh)		;9217
	and 00fh		;921a
	ld (lafdch),a		;921c
	call sub_96a8h		;921f
	ld a,(ix+009h)		;9222
	and 003h		;9225
	cp 003h		;9227
	jr z,l9236h		;9229
	cp 002h		;922b
	jr z,l9275h		;922d
	cp 001h		;922f
	jr z,l929eh		;9231
	jp l92bch		;9233
l9236h:
	ld a,(ix+00ah)		;9236
	call iy_objeto		;9239
	bit 7,(ix+00ah)		;923c
	jr z,l926dh		;9240
	ld a,(0e00ah)		;9242
	cp (iy-036h)		;9245
	jr nz,l92b7h		;9248
	ld a,(iy+000h)		;924a
	srl a		;924d
	srl a		;924f
	srl a		;9251
	srl a		;9253
	ld hl,0e009h		;9255
	cp (hl)			;9258
	jr nz,l92b7h		;9259
l925bh:
	ld a,(ix+00bh)		;925b
	srl a		;925e
	srl a		;9260
	srl a		;9262
	srl a		;9264
	call comprueba_bandera		;9266
	jr z,l92bch		;9269
	jr l92b7h		;926b
l926dh:
	ld a,(iy-036h)		;926d
	and a			;9270
	jr nz,l92b7h		;9271
	jr l925bh		;9273
l9275h:
	ld a,(ix+00ah)		;9275
	ld b,a			;9278
	srl a		;9279
	srl a		;927b
	srl a		;927d
	srl a		;927f
	srl a		;9281
	ld d,000h		;9283
	ld e,a			;9285
	ld hl,0e000h		;9286
	add hl,de			;9289
	ld a,b			;928a
	and 01fh		;928b
	srl a		;928d
	ld b,a			;928f
	ld a,(hl)			;9290
	jr nc,l9298h		;9291
	cp b			;9293
	jr nc,l92b7h		;9294
	jr l92bch		;9296
l9298h:
	dec a			;9298
	cp b			;9299
	jr c,l92b7h		;929a
	jr l92bch		;929c
l929eh:
	ld hl,0e008h		;929e
	ld a,(ix+00ah)		;92a1
	and 03fh		;92a4
	srl a		;92a6
	ld b,a			;92a8
	ld a,(hl)			;92a9
	jr nc,l92b1h		;92aa
	cp b			;92ac
	jr nc,l92b7h		;92ad
	jr l92bch		;92af
l92b1h:
	dec a			;92b1
	cp b			;92b2
	jr c,l92b7h		;92b3
	jr l92bch		;92b5
l92b7h:
	ld a,(ix+00fh)		;92b7
	jr l92d6h		;92ba
l92bch:
	ld a,(ix+009h)		;92bc
	add a,a			;92bf
	jr c,l92c7h		;92c0
	ld a,(ix+00ch)		;92c2
	jr l92d6h		;92c5
l92c7h:
	ld a,(ix+009h)		;92c7
	and 07fh		;92ca
	srl a		;92cc
	srl a		;92ce
	call salida_al_azar		;92d0
	ld a,(ix+00ch)		;92d3
l92d6h:
				; >>> destino: bit 7 = otro canto; 7Fh = repetir; 7Eh/7Dh = volver atrás
	bit 7,a		;92d6
	jr nz,cambia_canto		;92d8
	cp 07fh		;92da
	jp z,bucle_parrafo		;92dc
	cp 07eh		;92df
	jr nz,l92f6h		;92e1
	ld a,(0e00bh)		;92e3
	ld (0e00ah),a		;92e6
	ld a,(0e00ch)		;92e9
	ld (0e00bh),a		;92ec
	xor a			;92ef
	ld (0e00ch),a		;92f0
	jp bucle_parrafo		;92f3
l92f6h:
	cp 07dh		;92f6
	jr nz,l930ah		;92f8
	ld a,(0e00ch)		;92fa
	ld (0e00ah),a		;92fd
	xor a			;9300
	ld (0e00bh),a		;9301
	ld (0e00ch),a		;9304
	jp bucle_parrafo		;9307
l930ah:
	ld b,a			;930a
	ld a,(0e00bh)		;930b
	ld (0e00ch),a		;930e
	ld a,(0e00ah)		;9311
	ld (0e00bh),a		;9314
	ld a,b			;9317
	ld (0e00ah),a		;9318
	jp bucle_parrafo		;931b
cambia_canto:
				; >>> --- cambio de canto: pide la cinta y carga el canto (A & 7Fh) ---
	res 7,a		;931e
	ld (0e009h),a		;9320
	ld (v_canto_cargado),a		;9323
	call datos_canto		;9326
l9329h:
	call carga_canto		;9329
	jr c,l933ch		;932c
	ld a,001h		;932e
	ld (0e00ah),a		;9330
	ld (0e00bh),a		;9333
	ld (0e00ch),a		;9336
	jp bucle_parrafo		;9339
l933ch:
	call espera_tecla		;933c
	jr l9329h		;933f
salta_cadenas:
	and a			;9341
	ret z			;9342
	ld b,a			;9343
l9344h:
	ld a,(hl)			;9344
	inc hl			;9345
	cp 07fh		;9346
	jr nz,l9344h		;9348
	djnz l9344h		;934a
	ret			;934c
sub_934dh:
	xor a			;934d
	ld (iy-036h),a		;934e
	ret			;9351
objeto_aqui:
	ld a,(0e00ah)		;9352
	ld (iy-036h),a		;9355
	ld a,(0e009h)		;9358
	add a,a			;935b
	add a,a			;935c
	add a,a			;935d
	add a,a			;935e
	ld b,a			;935f
	ld a,(iy+000h)		;9360
	and 00fh		;9363
	or b			;9365
	ld (iy+000h),a		;9366
	ret			;9369
sub_936ah:
	ld a,(iy+000h)		;936a
	and 003h		;936d
	cp 003h		;936f
	ret nz			;9371
	ld (iy-036h),07fh		;9372
	ret			;9376
salida_al_azar:
	ld hl,laff2h		;9377
	ld d,000h		;937a
	ld e,a			;937c
	add hl,de			;937d
	add hl,de			;937e
	ld a,(hl)			;937f
	ld b,a			;9380
	inc hl			;9381
	ld a,(hl)			;9382
	ld c,a			;9383
				; >>> número al azar con el registro R
	ld a,r		;9384
	and 00fh		;9386
	cp b			;9388
	ret c			;9389
	inc ix		;938a
	cp c			;938c
	ret c			;938d
	inc ix		;938e
	ret			;9390
l9391h:
	ld a,004h		;9391
	call imprime_mensaje		;9393
	call reimprime_parrafo		;9396
	xor a			;9399
	ld (lafdbh),a		;939a
	jp muestra_opcion		;939d
animacion_lateral:
	push af			;93a0
	ld hl,dibujos_marco		;93a1
	ld (v_dibujos),hl		;93a4
	ld hl,00000h		;93a7
	xor a			;93aa
	call dibuja_baldosas		;93ab
	pop af			;93ae
	and 007h		;93af
	jr z,l93eeh		;93b1
	cp 001h		;93b3
	jr z,l93cch		;93b5
	cp 002h		;93b7
	ret z			;93b9
	cp 003h		;93ba
	jr z,l93d2h		;93bc
	cp 004h		;93be
	jr z,l93e2h		;93c0
	cp 005h		;93c2
	jr z,l93deh		;93c4
	cp 006h		;93c6
	jr z,l93e6h		;93c8
	jr l93eah		;93ca
l93cch:
	ld a,001h		;93cc
	ld (lafd6h),a		;93ce
	ret			;93d1
l93d2h:
	ld a,r		;93d2
	and 003h		;93d4
	jr z,l93e2h		;93d6
	dec a			;93d8
	jr z,l93e6h		;93d9
	dec a			;93db
	jr z,l93eah		;93dc
l93deh:
	ld a,008h		;93de
	jr l93f1h		;93e0
l93e2h:
	ld a,005h		;93e2
	jr l93f1h		;93e4
l93e6h:
	ld a,006h		;93e6
	jr l93f1h		;93e8
l93eah:
	ld a,007h		;93ea
	jr l93f1h		;93ec
l93eeh:
	ld a,(lafd7h)		;93ee
l93f1h:
	ld (lafd7h),a		;93f1
	ld hl,dibujos_marco		;93f4
	ld (v_dibujos),hl		;93f7
	ld hl,00000h		;93fa
	call dibuja_baldosas		;93fd
	ret			;9400
muestra_opcion:
	ld a,(v_opcion)		;9401
	add a,a			;9404
	jr c,l9412h		;9405
	ld hl,00380h		;9407
	ld d,000h		;940a
	ld e,a			;940c
	add hl,de			;940d
	ld a,(hl)			;940e
	jp muestra_opcion_texto		;940f
l9412h:
	ld a,(v_opcion)		;9412
	and 07fh		;9415
	ld h,000h		;9417
	ld l,a			;9419
	add hl,hl			;941a
	add hl,hl			;941b
	add hl,hl			;941c
	add hl,hl			;941d
	ld de,00480h		;941e
	add hl,de			;9421
	ld (lafeah),hl		;9422
	ld ix,(lafeah)		;9425
	ld a,(ix+001h)		;9429
	and a			;942c
	jr z,l9455h		;942d
	ld b,a			;942f
	srl a		;9430
	srl a		;9432
	srl a		;9434
	srl a		;9436
	srl a		;9438
	ld e,a			;943a
	ld d,000h		;943b
	ld hl,0e000h		;943d
	add hl,de			;9440
	ld a,b			;9441
	and 01fh		;9442
	srl a		;9444
	ld c,a			;9446
	ld a,(hl)			;9447
	jr nc,l9450h		;9448
	cp c			;944a
	jp nc,l94cdh		;944b
	jr l9455h		;944e
l9450h:
	dec a			;9450
	cp c			;9451
	jp c,l94cdh		;9452
l9455h:
	ld a,(ix+002h)		;9455
	and a			;9458
	jr z,l948dh		;9459
	call iy_objeto		;945b
	bit 7,(ix+002h)		;945e
	jr nz,l9474h		;9462
	ld a,(iy-036h)		;9464
	and a			;9467
	jr nz,l94cdh		;9468
l946ah:
	ld a,(ix+004h)		;946a
	call comprueba_bandera		;946d
	jr z,l948dh		;9470
	jr l94cdh		;9472
l9474h:
	ld a,(iy-036h)		;9474
	ld hl,0e00ah		;9477
	cp (hl)			;947a
	jr nz,l94cdh		;947b
	ld a,(0e009h)		;947d
	add a,a			;9480
	add a,a			;9481
	add a,a			;9482
	add a,a			;9483
	xor (iy+000h)		;9484
	and 0f0h		;9487
	jr nz,l94cdh		;9489
	jr l946ah		;948b
l948dh:
	ld a,(ix+003h)		;948d
	and a			;9490
	jr z,l94dah		;9491
	call iy_objeto		;9493
	bit 7,(ix+003h)		;9496
	jr nz,l94b4h		;949a
	ld a,(iy-036h)		;949c
	and a			;949f
	jr nz,l94cdh		;94a0
l94a2h:
	ld a,(ix+004h)		;94a2
	srl a		;94a5
	srl a		;94a7
	srl a		;94a9
	srl a		;94ab
	call comprueba_bandera		;94ad
	jr z,l94dah		;94b0
	jr l94cdh		;94b2
l94b4h:
	ld a,(iy-036h)		;94b4
	ld hl,0e00ah		;94b7
	cp (hl)			;94ba
	jr nz,l94cdh		;94bb
	ld a,(0e009h)		;94bd
	add a,a			;94c0
	add a,a			;94c1
	add a,a			;94c2
	add a,a			;94c3
	xor (iy+000h)		;94c4
	and 0f0h		;94c7
	jr nz,l94cdh		;94c9
	jr l94a2h		;94cb
l94cdh:
	ld hl,lafd9h		;94cd
	ld a,(lafdbh)		;94d0
	dec (hl)			;94d3
	cp 01eh		;94d4
	ret z			;94d6
	inc (hl)			;94d7
	inc (hl)			;94d8
	ret			;94d9
l94dah:
	ld b,000h		;94da
	ld a,(ix+008h)		;94dc
	and 00fh		;94df
	ld (lafdch),a		;94e1
	ld a,(ix+005h)		;94e4
	ld (lafddh),a		;94e7
	call sub_95c3h		;94ea
	ld a,(ix+008h)		;94ed
	srl a		;94f0
	srl a		;94f2
	srl a		;94f4
	srl a		;94f6
	ld (lafdch),a		;94f8
	ld a,(ix+006h)		;94fb
	ld (lafddh),a		;94fe
	call sub_95c3h		;9501
	ld a,(ix+00bh)		;9504
	and 00fh		;9507
	ld (lafdch),a		;9509
	ld a,(ix+007h)		;950c
	ld (lafddh),a		;950f
	call sub_95c3h		;9512
	ld a,(0e010h)		;9515
	add a,b			;9518
	cp 040h		;9519
	jr nc,l94cdh		;951b
	ld hl,(lafeah)		;951d
	ld a,(hl)			;9520
muestra_opcion_texto:
	call texto_opcion		;9521
l9524h:
	call espera_tecla_anim		;9524
	ld (lafdbh),a		;9527
	cp 048h		;952a
	jp z,menu_h		;952c
	cp 049h		;952f
	jp z,l9620h		;9531
	cp 042h		;9534
	call z,gira_brujula		;9536
	ld a,(lafdbh)		;9539
	ld hl,lafd9h		;953c
	cp 01eh		;953f
	jr nz,l9545h		;9541
	dec (hl)			;9543
	ret			;9544
l9545h:
	cp 01fh		;9545
	jr nz,l954bh		;9547
	inc (hl)			;9549
	ret			;954a
l954bh:
	cp 00dh		;954b
	jr nz,l9524h		;954d
	ret			;954f
gira_brujula:
	ld hl,lb025h		;9550
	ld a,(hl)			;9553
	ld hl,lb029h		;9554
	ld b,(hl)			;9557
	ld (hl),a			;9558
	ld hl,lb02dh		;9559
	ld a,(hl)			;955c
	ld (hl),b			;955d
	ld hl,lb031h		;955e
	ld b,(hl)			;9561
	ld (hl),a			;9562
	ld hl,lb025h		;9563
	ld (hl),b			;9566
	ld hl,lb01eh		;9567
	ld (v_cadena),hl		;956a
	call imprime		;956d
	ld hl,dibujos_marco		;9570
	ld (v_dibujos),hl		;9573
	ld hl,00000h		;9576
	xor a			;9579
	call dibuja_baldosas		;957a
	ret			;957d
comprueba_bandera:
	ld b,a			;957e
	and 00fh		;957f
	ret z			;9581
	and 003h		;9582
	jr z,l958ch		;9584
	xor (iy+000h)		;9586
	and 003h		;9589
	ret nz			;958b
l958ch:
	ld a,b			;958c
	and 00ch		;958d
	ret z			;958f
	xor (iy+000h)		;9590
	and 00ch		;9593
	ret			;9595
sub_9596h:
	ld a,(lafdch)		;9596
	ld b,a			;9599
	and 00fh		;959a
	ret z			;959c
	ld a,b			;959d
	and 003h		;959e
	jr z,l95b0h		;95a0
	res 0,(iy+000h)		;95a2
	res 1,(iy+000h)		;95a6
	or (iy+000h)		;95aa
	ld (iy+000h),a		;95ad
l95b0h:
	ld a,b			;95b0
	and 00ch		;95b1
	ret z			;95b3
	res 2,(iy+000h)		;95b4
	res 3,(iy+000h)		;95b8
	or (iy+000h)		;95bc
	ld (iy+000h),a		;95bf
	ret			;95c2
sub_95c3h:
	ld a,(lafddh)		;95c3
	and a			;95c6
	ret z			;95c7
	call iy_objeto		;95c8
	ld a,(lafdch)		;95cb
	and 003h		;95ce
	cp 003h		;95d0
	jr z,l95e8h		;95d2
	ld a,(lafddh)		;95d4
	bit 7,a		;95d7
	jr nz,l95e8h		;95d9
	ld a,(iy-036h)		;95db
	and a			;95de
	ret z			;95df
	ld a,(iy+036h)		;95e0
	and 03fh		;95e3
	add a,b			;95e5
	ld b,a			;95e6
	ret			;95e7
l95e8h:
	ld a,(iy-036h)		;95e8
	and a			;95eb
	ret nz			;95ec
	ld a,(iy+036h)		;95ed
	and 03fh		;95f0
	sub b			;95f2
	neg		;95f3
	ld b,a			;95f5
	ret			;95f6
texto_parrafo:
	dec a			;95f7
	ld hl,00790h		;95f8
	call salta_cadenas		;95fb
	ld (lafech),hl		;95fe
	ld a,(lafdeh)		;9601
	xor (ix+004h)		;9604
	and 078h		;9607
	jr nz,l961ah		;9609
reimprime_parrafo:
	ld a,002h		;960b
	call imprime_mensaje		;960d
	ld hl,(lafech)		;9610
	ld (v_cadena),hl		;9613
	call imprime		;9616
	ret			;9619
l961ah:
	ld a,(ix+004h)		;961a
	ld (lafdeh),a		;961d
l9620h:
	ld a,002h		;9620
	call imprime_mensaje		;9622
	ld hl,lbb89h		;9625
	ld (v_dibujos),hl		;9628
	ld hl,(laf77h)		;962b
	ld a,(lafdeh)		;962e
	and 078h		;9631
	srl a		;9633
	srl a		;9635
	srl a		;9637
	call dibuja_dibujo_n		;9639
	xor a			;963c
	call texto_opcion		;963d
	call espera_tecla		;9640
	jr reimprime_parrafo		;9643
texto_opcion:
	push af			;9645
	ld a,003h		;9646
	call imprime_mensaje		;9648
	pop af			;964b
	and a			;964c
	jr z,l9660h		;964d
	ld hl,(laf75h)		;964f
	dec a			;9652
	call salta_cadenas		;9653
	ld (lafeeh),hl		;9656
l9659h:
	ld (v_cadena),hl		;9659
	call imprime		;965c
	ret			;965f
l9660h:
	ld hl,lb2edh		;9660
	jr l9659h		;9663
iy_objeto:
	ld iy,0e047h		;9665
	and 07fh		;9669
	cp 036h		;966b
	ret nc			;966d
	ld d,000h		;966e
	ld e,a			;9670
	add iy,de		;9671
	ret			;9673
menu_h:
	ld a,001h		;9674
	call imprime_mensaje		;9676
l9679h:
	call espera_tecla		;9679
	cp 048h		;967c
	jp z,l9391h		;967e
	cp 031h		;9681
	jp c,l9679h		;9683
	cp 039h		;9686
	jp nc,l9679h		;9688
	sub 031h		;968b
	add a,a			;968d
	ld hl,tabla_menu_h		;968e
	ld b,000h		;9691
	ld c,a			;9693
	add hl,bc			;9694
	ld a,(hl)			;9695
	ld (096a4h),a		;9696
	inc hl			;9699
	ld a,(hl)			;969a
	ld (096a5h),a		;969b
	ld a,004h		;969e
	call imprime_mensaje		;96a0
	call 00000h		;96a3
	jr menu_h		;96a6
sub_96a8h:
	ld a,(lafddh)		;96a8
	and a			;96ab
	ret z			;96ac
	call iy_objeto		;96ad
	ld a,(iy-036h)		;96b0
	and a			;96b3
	jr z,l96d5h		;96b4
	ld a,(lafddh)		;96b6
	bit 7,a		;96b9
	jr z,l96c7h		;96bb
	call objeto_aqui		;96bd
	call sub_9596h		;96c0
	call sub_936ah		;96c3
	ret			;96c6
l96c7h:
	call sub_934dh		;96c7
	call sub_9596h		;96ca
	call sub_936ah		;96cd
	ret z			;96d0
	call sub_96f4h		;96d1
	ret			;96d4
l96d5h:
	ld a,(lafddh)		;96d5
	bit 7,a		;96d8
	jr z,l96e9h		;96da
	call objeto_aqui		;96dc
	call sub_9596h		;96df
	call sub_936ah		;96e2
	call sub_96ffh		;96e5
	ret			;96e8
l96e9h:
	call sub_9596h		;96e9
	call sub_936ah		;96ec
	ret nz			;96ef
	call sub_96ffh		;96f0
	ret			;96f3
sub_96f4h:
	ld a,(iy+036h)		;96f4
	and 03fh		;96f7
	ld hl,0e010h		;96f9
	add a,(hl)			;96fc
	ld (hl),a			;96fd
	ret			;96fe
sub_96ffh:
	ld a,(iy+036h)		;96ff
	and 03fh		;9702
	ld hl,0e010h		;9704
	sub (hl)			;9707
	neg		;9708
	ld (hl),a			;970a
	ret			;970b
datos_canto:
	ld hl,laf7dh		;970c
	dec a			;970f
	jr z,l9719h		;9710
	add a,a			;9712
	add a,a			;9713
	add a,a			;9714
	ld e,a			;9715
	ld d,000h		;9716
	add hl,de			;9718
l9719h:
	ld bc,00008h		;9719
	ld de,laf75h		;971c
	ldir		;971f
	ret			;9721
parrafo_codigo:
				; >>> párrafo especial: lee 5 letras y las compara con «PANOS» (B8BCh)
	ld hl,lb15fh		;9722
	ld (hl),020h		;9725
	ld de,lb160h		;9727
	ld bc,00005h		;972a
	ldir		;972d
	ld hl,lb15fh		;972f
	ld b,005h		;9732
l9734h:
	push bc			;9734
	push hl			;9735
	call espera_tecla		;9736
	pop hl			;9739
	pop bc			;973a
	ld (hl),a			;973b
	inc hl			;973c
	djnz l9734h		;973d
	ld hl,lb15fh		;973f
	ld de,codigo_panos		;9742
	ld b,005h		;9745
l9747h:
	ld a,(de)			;9747
	cp (hl)			;9748
	jr nz,l9761h		;9749
	inc hl			;974b
	inc de			;974c
	djnz l9747h		;974d
				; >>> código bueno -> párrafo 24h; malo -> 23h
	ld a,024h		;974f
l9751h:
	ld hl,lb15fh		;9751
	ld (hl),020h		;9754
	ld de,lb160h		;9756
	ld bc,00005h		;9759
	ldir		;975c
	jp l92d6h		;975e
l9761h:
	ld a,023h		;9761
	jr l9751h		;9763
menu1_retour_futur:
	call confirma_enter		;9765
	ret nz			;9768
carga_personaje:
				; >>> carga un personaje grabado: nombre de 1 letra/cifra, 0B3h bytes en E000h
	ld hl,lb15fh		;9769
	ld (hl),020h		;976c
	ld de,lb160h		;976e
	ld bc,00005h		;9771
	ldir		;9774
	ld hl,0e000h		;9776
	ld (v_cinta_destino),hl		;9779
	ld hl,lb033h		;977c
	ld (v_cadena),hl		;977f
	call imprime		;9782
l9785h:
	call espera_tecla		;9785
	cp 030h		;9788
	jr c,l9785h		;978a
	cp 03ah		;978c
	jr c,l9798h		;978e
	cp 041h		;9790
	jr c,l9785h		;9792
	cp 05bh		;9794
	jr nc,l9785h		;9796
l9798h:
	ld (lb15fh),a		;9798
	ld hl,lb15fh		;979b
	ld (v_cadena),hl		;979e
	call imprime		;97a1
	ld a,(0e009h)		;97a4
	ld (v_canto_cargado),a		;97a7
	ld hl,lb135h		;97aa
	ld (v_cadena),hl		;97ad
	call imprime		;97b0
	ld hl,lb15fh		;97b3
	ld (v_cadena),hl		;97b6
	call imprime		;97b9
	ld hl,000b3h		;97bc
	ld (v_cinta_longitud),hl		;97bf
	call lee_cinta		;97c2
	jr nc,l97d7h		;97c5
	call espera_tecla		;97c7
	ld a,003h		;97ca
	call imprime_mensaje		;97cc
	ld a,(v_canto_cargado)		;97cf
	ld (0e009h),a		;97d2
	jr carga_personaje		;97d5
l97d7h:
	xor a			;97d7
	ld (0e200h),a		;97d8
	ld a,(0e009h)		;97db
	ld hl,v_canto_cargado		;97de
	cp (hl)			;97e1
	jr nz,l97e9h		;97e2
	pop hl			;97e4
	pop hl			;97e5
	jp inicio_motor		;97e6
l97e9h:
	ld (v_canto_cargado),a		;97e9
	call datos_canto		;97ec
l97efh:
	call carga_canto		;97ef
	jr c,l97f9h		;97f2
	pop hl			;97f4
	pop hl			;97f5
	jp inicio_motor		;97f6
l97f9h:
	call espera_tecla		;97f9
	ld a,003h		;97fc
	call imprime_mensaje		;97fe
	jr l97efh		;9801
carga_canto:
				; >>> pide «Prépare la cassette positionnée sur Cn» y carga el canto en 0100h
	ld a,002h		;9803
	ld hl,lb2a7h		;9805
	ld (v_cadena),hl		;9808
	call imprime		;980b
	ld hl,lb15fh		;980e
	ld (hl),020h		;9811
	ld de,lb160h		;9813
	ld bc,00005h		;9816
	ldir		;9819
	ld hl,v_numero		;981b
	ld de,v_canto_cargado		;981e
	call a_decimal		;9821
	ld hl,lb15fh		;9824
	ld (hl),043h		;9827
	inc hl			;9829
	ld de,v_numero		;982a
l982dh:
	ld a,(de)			;982d
	cp 020h		;982e
	inc de			;9830
	jr z,l982dh		;9831
	cp 07fh		;9833
	jr z,l983bh		;9835
	ld (hl),a			;9837
	inc hl			;9838
	jr l982dh		;9839
l983bh:
	ld hl,lb15fh		;983b
	ld (v_cadena),hl		;983e
	call imprime		;9841
	ld hl,lb135h		;9844
	ld (v_cadena),hl		;9847
	call imprime		;984a
	ld hl,lb15fh		;984d
	ld (v_cadena),hl		;9850
	call imprime		;9853
				; >>> longitud del canto (tabla AF7Dh)
	ld hl,(laf7bh)		;9856
	ld (v_cinta_longitud),hl		;9859
	ld hl,00100h		;985c
	ld (v_cinta_destino),hl		;985f
	call lee_cinta		;9862
	ret			;9865
confirma_enter:
	ld hl,lb119h		;9866
	ld (v_cadena),hl		;9869
	call imprime		;986c
	call espera_tecla		;986f
	cp 00dh		;9872
	push af			;9874
	ld a,003h		;9875
	call imprime_mensaje		;9877
	pop af			;987a
	ret			;987b
menu2_a_suivre:
	call confirma_enter		;987c
	ret nz			;987f
	ld hl,lb15fh		;9880
	ld (hl),020h		;9883
	ld de,lb160h		;9885
	ld bc,00005h		;9888
	ldir		;988b
	ld hl,lb033h		;988d
	ld (v_cadena),hl		;9890
	call imprime		;9893
l9896h:
	call espera_tecla		;9896
	cp 031h		;9899
	jr c,l9896h		;989b
	cp 03ah		;989d
	jr c,l98a9h		;989f
	cp 041h		;98a1
	jr c,l9896h		;98a3
	cp 05bh		;98a5
	jr nc,l9896h		;98a7
l98a9h:
	ld (lb15fh),a		;98a9
	ld hl,lb15fh		;98ac
	ld (v_cadena),hl		;98af
	call imprime		;98b2
	ld hl,0e000h		;98b5
	ld (v_cinta_origen),hl		;98b8
	ld hl,000b3h		;98bb
	ld (v_cinta_longitud),hl		;98be
	call graba_cinta		;98c1
	call c,espera_tecla		;98c4
	ret			;98c7
l98c8h:
	ld a,035h		;98c8
	ld (lafddh),a		;98ca
	jr l98dfh		;98cd
l98cfh:
	ld a,035h		;98cf
	ld (lafddh),a		;98d1
	jr l993ch		;98d4
menu3_bazar:
	xor a			;98d6
	ld (lafddh),a		;98d7
	ld a,01fh		;98da
	ld (lafdbh),a		;98dc
l98dfh:
	ld a,(lafddh)		;98df
	call iy_objeto		;98e2
	ld a,(iy-036h)		;98e5
	and a			;98e8
	jr nz,l991dh		;98e9
	bit 7,(iy+036h)		;98eb
	jr nz,l991dh		;98ef
	ld hl,lb255h		;98f1
	ld (v_cadena),hl		;98f4
	call imprime		;98f7
	ld a,(lafddh)		;98fa
	ld hl,lb8c1h		;98fd
	call salta_cadenas		;9900
	ld (v_cadena),hl		;9903
	call imprime		;9906
	call espera_enter_flechas		;9909
	cp 00dh		;990c
	jr nz,l991dh		;990e
	bit 6,(iy+036h)		;9910
	jp nz,l99dbh		;9914
	call objeto_aqui		;9917
	call sub_96ffh		;991a
l991dh:
	ld a,(lafdbh)		;991d
	ld hl,lafddh		;9920
	cp 01eh		;9923
	jr nz,l992ah		;9925
	dec (hl)			;9927
	jr l992bh		;9928
l992ah:
	inc (hl)			;992a
l992bh:
	ld a,(hl)			;992b
	cp 036h		;992c
	jr c,l98dfh		;992e
	jp m,l99b3h		;9930
	xor a			;9933
	ld (lafddh),a		;9934
	ld a,01fh		;9937
	ld (lafdbh),a		;9939
l993ch:
	ld a,(lafddh)		;993c
	call iy_objeto		;993f
	ld hl,0e00ah		;9942
	ld a,(iy-036h)		;9945
	cp (hl)			;9948
	jr nz,l999ch		;9949
	ld hl,0e009h		;994b
	ld a,(iy+000h)		;994e
	srl a		;9951
	srl a		;9953
	srl a		;9955
	srl a		;9957
	cp (hl)			;9959
	jr nz,l999ch		;995a
	bit 7,(iy+036h)		;995c
	jr nz,l999ch		;9960
	ld hl,lb26dh		;9962
	ld (v_cadena),hl		;9965
	call imprime		;9968
	ld a,(lafddh)		;996b
	ld hl,lb8c1h		;996e
	call salta_cadenas		;9971
	ld (v_cadena),hl		;9974
	call imprime		;9977
	call espera_enter_flechas		;997a
	cp 00dh		;997d
	jr nz,l999ch		;997f
	bit 6,(iy+036h)		;9981
	jp nz,l99eah		;9985
	ld hl,0e010h		;9988
	ld a,(iy+036h)		;998b
	and 03fh		;998e
	add a,(hl)			;9990
	cp 040h		;9991
	jp nc,l99f9h		;9993
	call sub_934dh		;9996
	call sub_96f4h		;9999
l999ch:
	ld hl,lafddh		;999c
	ld a,(lafdbh)		;999f
	cp 01eh		;99a2
	jr nz,l99a9h		;99a4
	dec (hl)			;99a6
	jr l99aah		;99a7
l99a9h:
	inc (hl)			;99a9
l99aah:
	ld a,(hl)			;99aa
	cp 036h		;99ab
	jp c,l993ch		;99ad
	jp m,l98c8h		;99b0
l99b3h:
	ld hl,lb284h		;99b3
	ld (v_cadena),hl		;99b6
	call imprime		;99b9
	call espera_enter_flechas		;99bc
	cp 00dh		;99bf
	ret z			;99c1
	cp 01fh		;99c2
	jp z,menu3_bazar		;99c4
	jp l98cfh		;99c7
espera_enter_flechas:
	call espera_tecla		;99ca
	ld (lafdbh),a		;99cd
	cp 00dh		;99d0
	ret z			;99d2
	cp 01eh		;99d3
	ret z			;99d5
	cp 01fh		;99d6
	ret z			;99d8
	jr espera_enter_flechas		;99d9
l99dbh:
	ld hl,lb3a6h		;99db
	ld (v_cadena),hl		;99de
	call imprime		;99e1
	call espera_enter_flechas		;99e4
	jp l991dh		;99e7
l99eah:
	ld hl,lb3ebh		;99ea
l99edh:
	ld (v_cadena),hl		;99ed
	call imprime		;99f0
	call espera_enter_flechas		;99f3
	jp l999ch		;99f6
l99f9h:
	ld hl,lb420h		;99f9
	jr l99edh		;99fc
menu4_pub:
	ld hl,lb644h		;99fe
	ld (v_cadena),hl		;9a01
	call imprime		;9a04
	call espera_enter_flechas		;9a07
	call imprime		;9a0a
	call espera_tecla		;9a0d
	ret			;9a10
menu5_gag:
	ld hl,lb5c6h		;9a11
	ld (v_cadena),hl		;9a14
	call imprime		;9a17
	call espera_tecla		;9a1a
	ret			;9a1d
menu6_cariotype:
	ld hl,lb070h		;9a1e
	ld (v_cadena),hl		;9a21
	call imprime		;9a24
	ld hl,lb111h		;9a27
	ld (v_cadena),hl		;9a2a
	call imprime		;9a2d
	ld de,0e000h		;9a30
	ld b,008h		;9a33
l9a35h:
	push bc			;9a35
	ld hl,v_numero		;9a36
	call a_decimal		;9a39
	inc de			;9a3c
	ld hl,l9f7ah		;9a3d
	ld (v_cadena),hl		;9a40
	push de			;9a43
	call imprime		;9a44
	call baja_linea		;9a47
	call baja_linea		;9a4a
	call sub_a339h		;9a4d
	call sub_a339h		;9a50
	pop de			;9a53
	pop bc			;9a54
	djnz l9a35h		;9a55
	call espera_tecla		;9a57
	ret			;9a5a
menu7_bilan_sante:
	ld hl,lb450h		;9a5b
	ld (v_cadena),hl		;9a5e
	call imprime		;9a61
	ld de,0e008h		;9a64
	ld hl,v_numero		;9a67
	call a_decimal		;9a6a
	ld hl,l9f7ah		;9a6d
	ld (v_cadena),hl		;9a70
	call imprime		;9a73
	ld hl,lb4adh		;9a76
	ld (v_cadena),hl		;9a79
	call imprime		;9a7c
	call espera_tecla		;9a7f
	ret			;9a82
menu8_a_table:
	ld hl,lb398h		;9a83
	ld (v_cadena),hl		;9a86
	call imprime		;9a89
	ld hl,v_numero		;9a8c
	ld de,0e010h		;9a8f
	call a_decimal		;9a92
	ld hl,l9f7ah		;9a95
	ld (v_cadena),hl		;9a98
	call imprime		;9a9b
	ld hl,lb540h		;9a9e
	ld (v_cadena),hl		;9aa1
	call imprime		;9aa4
	ld de,0e00eh		;9aa7
	ld hl,v_numero		;9aaa
	call a_decimal		;9aad
	ld hl,l9f7ah		;9ab0
	ld (v_cadena),hl		;9ab3
	call imprime		;9ab6
	ld hl,lb558h		;9ab9
	ld (v_cadena),hl		;9abc
	call imprime		;9abf
	ld a,(0e00eh)		;9ac2
	and a			;9ac5
	jr z,l9b0bh		;9ac6
	ld a,(0e00fh)		;9ac8
	and a			;9acb
	jr z,l9afeh		;9acc
	ld hl,lb561h		;9ace
	ld (v_cadena),hl		;9ad1
	call imprime		;9ad4
	call espera_enter_flechas		;9ad7
	cp 00dh		;9ada
	jr nz,l9aedh		;9adc
	ld hl,0e00eh		;9ade
	dec (hl)			;9ae1
	ld hl,0e00fh		;9ae2
	dec (hl)			;9ae5
	ld hl,0e008h		;9ae6
	inc (hl)			;9ae9
	inc (hl)			;9aea
	jr menu8_a_table		;9aeb
l9aedh:
	ld hl,lb284h		;9aed
	ld (v_cadena),hl		;9af0
	call imprime		;9af3
	call espera_enter_flechas		;9af6
	cp 00dh		;9af9
	ret z			;9afb
	jr menu8_a_table		;9afc
l9afeh:
	ld hl,lb59bh		;9afe
	ld (v_cadena),hl		;9b01
	call imprime		;9b04
	call espera_tecla		;9b07
	ret			;9b0a
l9b0bh:
	ld hl,lb571h		;9b0b
	ld (v_cadena),hl		;9b0e
	call imprime		;9b11
	call espera_tecla		;9b14
	ret			;9b17
graba_cinta:
				; >>> graba en cinta: 10 x 0D0h + nombre de 6 letras, pausa, datos y suma
	di			;9b18
	ld a,001h		;9b19
	ld ix,000eah		;9b1b
	call bios		;9b1f
	jp c,error_cinta		;9b22
	ld b,00ah		;9b25
l9b27h:
	push bc			;9b27
	ld a,0d0h		;9b28
	ld ix,000edh		;9b2a
	call bios		;9b2e
	pop bc			;9b31
	jp c,error_cinta		;9b32
	djnz l9b27h		;9b35
	ld hl,lb15fh		;9b37
	ld iy,la703h		;9b3a
	ld (iy+000h),000h		;9b3e
	ld b,006h		;9b42
l9b44h:
	push bc			;9b44
	push hl			;9b45
	ld a,(hl)			;9b46
	ld ix,000edh		;9b47
	call bios		;9b4b
	pop hl			;9b4e
	pop bc			;9b4f
	jp c,error_cinta		;9b50
	inc hl			;9b53
	djnz l9b44h		;9b54
	ld a,0ffh		;9b56
l9b58h:
	ld b,0ffh		;9b58
l9b5ah:
	ex de,hl			;9b5a
	ex de,hl			;9b5b
	djnz l9b5ah		;9b5c
	dec a			;9b5e
	jp nz,l9b58h		;9b5f
	ld a,000h		;9b62
	ld ix,000eah		;9b64
	call bios		;9b68
	jp c,error_cinta		;9b6b
	ld hl,(v_cinta_origen)		;9b6e
	ld de,(v_cinta_longitud)		;9b71
l9b75h:
	push hl			;9b75
	push de			;9b76
	ld a,(hl)			;9b77
	add a,(iy+000h)		;9b78
	ld (iy+000h),a		;9b7b
	ld a,(hl)			;9b7e
	ld ix,000edh		;9b7f
	call bios		;9b83
	pop de			;9b86
	pop hl			;9b87
	jp c,error_cinta		;9b88
	dec de			;9b8b
	ld a,d			;9b8c
	or e			;9b8d
	inc hl			;9b8e
	jr nz,l9b75h		;9b8f
	ld a,(iy+000h)		;9b91
	ld ix,000edh		;9b94
	call bios		;9b98
	jp c,error_cinta		;9b9b
	ld ix,000f0h		;9b9e
	call bios		;9ba2
	ei			;9ba5
	and a			;9ba6
	ret			;9ba7
lee_cinta:
				; >>> lee de cinta: busca la cabecera 0D0h x 10 con el nombre de B15Fh
	ld hl,lb166h		;9ba8
	ld (hl),020h		;9bab
	ld de,lb167h		;9bad
	ld bc,00005h		;9bb0
	ldir		;9bb3
	di			;9bb5
	ld ix,000e1h		;9bb6
	call bios		;9bba
	jp c,error_cinta		;9bbd
	ld b,00ah		;9bc0
l9bc2h:
	push bc			;9bc2
	ld ix,000e4h		;9bc3
	call bios		;9bc7
	pop bc			;9bca
	jp c,error_cinta		;9bcb
	cp 0d0h		;9bce
	jr nz,lee_cinta		;9bd0
	djnz l9bc2h		;9bd2
	ld b,006h		;9bd4
	ld hl,lb166h		;9bd6
l9bd9h:
	push bc			;9bd9
	push hl			;9bda
	ld ix,000e4h		;9bdb
	call bios		;9bdf
	pop hl			;9be2
	pop bc			;9be3
	jp c,error_cinta		;9be4
	ld (hl),a			;9be7
	inc hl			;9be8
	djnz l9bd9h		;9be9
	ld hl,lb15fh		;9beb
	ld de,lb166h		;9bee
	ld b,006h		;9bf1
l9bf3h:
	ld a,(de)			;9bf3
	cp (hl)			;9bf4
	jp nz,msg_otro_bloque		;9bf5
	inc hl			;9bf8
	inc de			;9bf9
	djnz l9bf3h		;9bfa
	call msg_encontrado		;9bfc
	ld iy,la703h		;9bff
	ld (iy+000h),000h		;9c03
	ld ix,000e1h		;9c07
	call bios		;9c0b
	jp c,error_cinta		;9c0e
	ld de,(v_cinta_longitud)		;9c11
	ld hl,(v_cinta_destino)		;9c15
l9c18h:
	push hl			;9c18
	push de			;9c19
	ld ix,000e4h		;9c1a
	call bios		;9c1e
	pop de			;9c21
	pop hl			;9c22
	jp c,error_cinta		;9c23
	ld (hl),a			;9c26
	add a,(iy+000h)		;9c27
	ld (iy+000h),a		;9c2a
	dec de			;9c2d
	ld a,d			;9c2e
	or e			;9c2f
	inc hl			;9c30
	jr nz,l9c18h		;9c31
	ld ix,000e4h		;9c33
	call bios		;9c37
	jp c,error_cinta		;9c3a
				; >>> comprueba la suma de los datos
	cp (iy+000h)		;9c3d
	jp nz,error_cinta		;9c40
	ld ix,000e7h		;9c43
	call bios		;9c47
	ei			;9c4a
	and a			;9c4b
	ret			;9c4c
dibuja_baldosas:
				; >>> dibuja un dibujo hecho de baldosas de 8x8 (patrón + color)
	push ix		;9c4d
	push iy		;9c4f
	ld ix,(v_dibujos)		;9c51
	and a			;9c55
	jr z,l9c75h		;9c56
	ld b,a			;9c58
	ld a,005h		;9c59
	ld (la708h),a		;9c5b
l9c5eh:
	ld a,(ix+000h)		;9c5e
	ld (la707h),a		;9c61
	ld iy,la707h		;9c64
	call multiplica8x8		;9c68
	ld de,(la72ah)		;9c6b
	add ix,de		;9c6f
	inc ix		;9c71
	djnz l9c5eh		;9c73
l9c75h:
	ld a,(la705h)		;9c75
	push af			;9c78
	ld a,(ix+000h)		;9c79
	ld b,a			;9c7c
	inc ix		;9c7d
l9c7fh:
	push bc			;9c7f
	ld a,(ix+001h)		;9c80
	and a			;9c83
	jr z,l9cb9h		;9c84
	push hl			;9c86
	ld e,a			;9c87
	ld a,068h		;9c88
	call dir_pixel		;9c8a
	ld (l9f4bh),hl		;9c8d
	ld a,(ix+004h)		;9c90
	ld (la727h),a		;9c93
	ld a,(ix+000h)		;9c96
	ld e,(ix+001h)		;9c99
	call dir_pixel		;9c9c
	ld (la709h),hl		;9c9f
	ld e,(ix+002h)		;9ca2
	ld d,(ix+003h)		;9ca5
	pop hl			;9ca8
	push hl			;9ca9
	add hl,de			;9caa
	ex de,hl			;9cab
	push ix		;9cac
	call dibuja_bloque		;9cae
	pop ix		;9cb1
	pop hl			;9cb3
	ld bc,00005h		;9cb4
	add ix,bc		;9cb7
l9cb9h:
	pop bc			;9cb9
	djnz l9c7fh		;9cba
	pop af			;9cbc
	ld (la705h),a		;9cbd
	pop iy		;9cc0
	pop ix		;9cc2
	ret			;9cc4
dibuja_dibujo_n:
	push af			;9cc5
	push hl			;9cc6
	ld hl,(v_dibujos)		;9cc7
	ld a,(0e009h)		;9cca
	dec a			;9ccd
	jr z,l9cd7h		;9cce
	ld b,a			;9cd0
l9cd1h:
	ld e,(hl)			;9cd1
	ld d,000h		;9cd2
	add hl,de			;9cd4
	djnz l9cd1h		;9cd5
l9cd7h:
	inc hl			;9cd7
	ld (v_dibujos),hl		;9cd8
	pop hl			;9cdb
	pop af			;9cdc
	call dibuja_baldosas		;9cdd
	ret			;9ce0
dibuja_bloque:
	ld a,(de)			;9ce1
	ld (la707h),a		;9ce2
	inc de			;9ce5
	ld a,(de)			;9ce6
	inc de			;9ce7
	ld (la708h),a		;9ce8
	ld iy,la707h		;9ceb
	call multiplica8x8		;9cef
	ld hl,(la72ah)		;9cf2
	add hl,hl			;9cf5
	add hl,de			;9cf6
	ld (la717h),hl		;9cf7
	ld hl,(la709h)		;9cfa
	push de			;9cfd
	ld a,(la708h)		;9cfe
	ld b,a			;9d01
	ld iy,la70fh		;9d02
l9d06h:
	push hl			;9d06
	push bc			;9d07
	ld a,(la707h)		;9d08
	ld b,a			;9d0b
l9d0ch:
	push bc			;9d0c
	ld a,(de)			;9d0d
	inc de			;9d0e
	ld (la705h),a		;9d0f
	ld a,(de)			;9d12
	inc de			;9d13
	ld (la711h),de		;9d14
	ex de,hl			;9d18
	ld (la70fh),a		;9d19
	ld a,008h		;9d1c
	ld (la710h),a		;9d1e
	call multiplica8x8		;9d21
	ld hl,(la717h)		;9d24
	ld bc,(la72ah)		;9d27
	add hl,bc			;9d2b
	ex de,hl			;9d2c
	ld b,008h		;9d2d
l9d2fh:
	ld a,(de)			;9d2f
	call vpoke		;9d30
	call pone_color		;9d33
	inc hl			;9d36
	inc de			;9d37
	djnz l9d2fh		;9d38
	ld de,(la711h)		;9d3a
	pop bc			;9d3e
	djnz l9d0ch		;9d3f
	pop bc			;9d41
	pop hl			;9d42
	inc h			;9d43
	djnz l9d06h		;9d44
	pop de			;9d46
	ld hl,(la709h)		;9d47
				; >>> si el dibujo es simétrico, dibuja la otra mitad reflejada
	ld a,(la727h)		;9d4a
	and a			;9d4d
	ret z			;9d4e
	ld bc,(l9f4bh)		;9d4f
	and a			;9d53
	sbc hl,bc		;9d54
	ld bc,00008h		;9d56
	add hl,bc			;9d59
	push hl			;9d5a
	pop bc			;9d5b
	ld hl,(l9f4bh)		;9d5c
	and a			;9d5f
	sbc hl,bc		;9d60
	ld a,(la708h)		;9d62
	ld b,a			;9d65
l9d66h:
	push hl			;9d66
	push bc			;9d67
	ld a,(la707h)		;9d68
	ld b,a			;9d6b
l9d6ch:
	push bc			;9d6c
	ld a,(de)			;9d6d
	inc de			;9d6e
	ld (la705h),a		;9d6f
	ld a,(de)			;9d72
	inc de			;9d73
	ld (la711h),de		;9d74
	ex de,hl			;9d78
	ld (la70fh),a		;9d79
	ld a,008h		;9d7c
	ld (la710h),a		;9d7e
	call multiplica8x8		;9d81
	ld hl,(la717h)		;9d84
	ld bc,(la72ah)		;9d87
	add hl,bc			;9d8b
	ex de,hl			;9d8c
	ld b,008h		;9d8d
l9d8fh:
				; >>> invierte el byte (espejo horizontal)
	ld a,(de)			;9d8f
	ld c,a			;9d90
	sla c		;9d91
	rra			;9d93
	sla c		;9d94
	rra			;9d96
	sla c		;9d97
	rra			;9d99
	sla c		;9d9a
	rra			;9d9c
	sla c		;9d9d
	rra			;9d9f
	sla c		;9da0
	rra			;9da2
	sla c		;9da3
	rra			;9da5
	sla c		;9da6
	rra			;9da8
	call vpoke		;9da9
	call pone_color		;9dac
	inc hl			;9daf
	inc de			;9db0
	djnz l9d8fh		;9db1
	ld bc,00010h		;9db3
	and a			;9db6
	sbc hl,bc		;9db7
	ld de,(la711h)		;9db9
	pop bc			;9dbd
	djnz l9d6ch		;9dbe
	pop bc			;9dc0
	pop hl			;9dc1
	inc h			;9dc2
	djnz l9d66h		;9dc3
	ret			;9dc5
error_cinta:
	ld ix,000f0h		;9dc6
	call bios		;9dca
	ld ix,000e7h		;9dcd
	call bios		;9dd1
	ei			;9dd4
	ld hl,(v_cadena)		;9dd5
	push hl			;9dd8
	ld hl,lb17fh		;9dd9
	ld (v_cadena),hl		;9ddc
	call imprime		;9ddf
	pop hl			;9de2
	ld (v_cadena),hl		;9de3
	scf			;9de6
	ret			;9de7
multiplica8x8:
	push hl			;9de8
	push bc			;9de9
	push de			;9dea
	ld h,(iy+000h)		;9deb
	ld e,(iy+001h)		;9dee
	ld d,000h		;9df1
	ld l,000h		;9df3
	ld b,008h		;9df5
l9df7h:
	add hl,hl			;9df7
	jr nc,l9dfbh		;9df8
	add hl,de			;9dfa
l9dfbh:
	djnz l9df7h		;9dfb
	ld (la72ah),hl		;9dfd
	pop de			;9e00
	pop bc			;9e01
	pop hl			;9e02
	ret			;9e03
msg_encontrado:
	ld hl,lb149h		;9e04
	ld (v_cadena),hl		;9e07
	call imprime		;9e0a
	ret			;9e0d
msg_otro_bloque:
	ei			;9e0e
	ld hl,lb16dh		;9e0f
	ld (v_cadena),hl		;9e12
	call imprime		;9e15
	ld hl,lb166h		;9e18
	ld (v_cadena),hl		;9e1b
	call imprime		;9e1e
	jp lee_cinta		;9e21
borra_ventana:
	add a,a			;9e24
	ld ix,tabla_ventanas		;9e25
	ld (09e32h),a		;9e29
	inc a			;9e2c
	ld (09e35h),a		;9e2d
	ld l,(ix+000h)		;9e30
	ld h,(ix+000h)		;9e33
	jp (hl)			;9e36
dibuja_marco:
	call dibuja_cajas_2		;9e37
	call dibuja_cajas_1		;9e3a
	ld hl,lb01eh		;9e3d
	ld (v_cadena),hl		;9e40
	call imprime		;9e43
	ld hl,dibujos_marco		;9e46
	ld (v_dibujos),hl		;9e49
	ld hl,00000h		;9e4c
	ld a,000h		;9e4f
	call dibuja_baldosas		;9e51
	ld a,001h		;9e54
	call dibuja_baldosas		;9e56
	ld a,002h		;9e59
	call dibuja_baldosas		;9e5b
	ld a,004h		;9e5e
	call dibuja_baldosas		;9e60
	ld hl,l9f57h		;9e63
	ld de,la6fdh		;9e66
	ld bc,00004h		;9e69
	ldir		;9e6c
	ret			;9e6e
	ld hl,l9f6bh		;9e6f
	ld de,la6fdh		;9e72
	ld bc,00004h		;9e75
	ldir		;9e78
	call caja		;9e7a
	call dibuja_cajas_1		;9e7d
	ld hl,l9f57h		;9e80
	ld de,la6fdh		;9e83
	ld bc,00004h		;9e86
	ldir		;9e89
	ret			;9e8b
	ld hl,l9f57h		;9e8c
	ld de,la6fdh		;9e8f
	ld bc,00004h		;9e92
	ldir		;9e95
	call caja		;9e97
	ld hl,l9f67h		;9e9a
	ld de,la6fdh		;9e9d
	ld bc,00004h		;9ea0
	ldir		;9ea3
	call caja		;9ea5
	ld hl,l9f5bh		;9ea8
	ld de,la6fdh		;9eab
	ld bc,00004h		;9eae
	ldir		;9eb1
	call caja		;9eb3
	ld hl,l9f6bh		;9eb6
	ld de,la6fdh		;9eb9
	ld bc,00004h		;9ebc
	ldir		;9ebf
	ld hl,dibujos_marco		;9ec1
	ld (v_dibujos),hl		;9ec4
	ld hl,00000h		;9ec7
	ld a,003h		;9eca
	call dibuja_baldosas		;9ecc
	call l9f7dh		;9ecf
	ld hl,lb195h		;9ed2
	ld (v_cadena),hl		;9ed5
	call imprime		;9ed8
	ret			;9edb
	ld hl,l9f57h		;9edc
	ld de,la6fdh		;9edf
	ld bc,00004h		;9ee2
	ldir		;9ee5
	call caja		;9ee7
	ret			;9eea
	ld hl,l9f5bh		;9eeb
	ld de,la6fdh		;9eee
	ld bc,00004h		;9ef1
	ldir		;9ef4
	call caja		;9ef6
	ret			;9ef9
	ld hl,(la6fdh)		;9efa
	ld de,(la6ffh)		;9efd
	push hl			;9f01
	push de			;9f02
	ld hl,l9f63h		;9f03
	ld de,la6fdh		;9f06
	ld bc,00004h		;9f09
	ldir		;9f0c
	call caja		;9f0e
	pop de			;9f11
	pop hl			;9f12
	ld (la6fdh),hl		;9f13
	ld (la6ffh),de		;9f16
	ret			;9f1a
a_decimal:
	xor a			;9f1b
	ld (la707h),a		;9f1c
	ld a,(de)			;9f1f
	ld c,09ch		;9f20
	call sub_9f2ch		;9f22
	ld c,0f6h		;9f25
	call sub_9f2ch		;9f27
	ld c,0ffh		;9f2a
sub_9f2ch:
	ld b,02fh		;9f2c
l9f2eh:
	inc b			;9f2e
	add a,c			;9f2f
	jr c,l9f2eh		;9f30
	sbc a,c			;9f32
	push af			;9f33
	ld a,030h		;9f34
	cp b			;9f36
	jp z,l9f41h		;9f37
	ld (la707h),a		;9f3a
l9f3dh:
	pop af			;9f3d
	ld (hl),b			;9f3e
	inc hl			;9f3f
	ret			;9f40
l9f41h:
	ld a,(la707h)		;9f41
	and a			;9f44
	jr nz,l9f3dh		;9f45
	ld b,020h		;9f47
	jr l9f3dh		;9f49

; BLOCK 'datos1' (start 0x9f4b end 0x9f7d)
l9f4bh:
	defs 2,RELLENO	;9f4b
v_cinta_origen:
	defs 4,RELLENO	;9f4d
v_cinta_destino:
	defs 4,RELLENO	;9f51
v_cinta_longitud:
	defs 2,RELLENO	;9f55
l9f57h:
	defs 4,RELLENO	;9f57
l9f5bh:
	defs 8,RELLENO	;9f5b
l9f63h:
	defs 4,RELLENO	;9f63
l9f67h:
	defs 4,RELLENO	;9f67
l9f6bh:
	defs 4,RELLENO	;9f6b
tabla_ventanas:
	defs 10,RELLENO	;9f6f
v_numero:
	defs 1,RELLENO	;9f79
l9f7ah:
	defs 3,RELLENO	;9f7a

; BLOCK 'codigo2' (start 0x9f7d end 0xa6f5)
l9f7dh:
dibuja_casillas_menu:
	ld ix,la7cah		;9f7d
	call dibuja_poligono		;9f81
	ld ix,la7d8h		;9f84
	call dibuja_poligono		;9f88
	ld ix,la7e6h		;9f8b
	call dibuja_poligono		;9f8f
	ld ix,la7f4h		;9f92
	call dibuja_poligono		;9f96
	ld ix,la802h		;9f99
	call dibuja_poligono		;9f9d
	ld ix,la810h		;9fa0
	call dibuja_poligono		;9fa4
	ld ix,la81eh		;9fa7
	call dibuja_poligono		;9fab
	ld ix,la82ch		;9fae
	call dibuja_poligono		;9fb2
	ld ix,la83ah		;9fb5
	call dibuja_poligono		;9fb9
	ret			;9fbc
dibuja_cajas_1:
	ld ix,la792h		;9fbd
	call dibuja_poligono		;9fc1
	ld ix,la7a0h		;9fc4
	call dibuja_poligono		;9fc8
	ret			;9fcb
dibuja_cajas_2:
	ld ix,la784h		;9fcc
	call dibuja_poligono		;9fd0
	ld ix,la7aeh		;9fd3
	call dibuja_poligono		;9fd7
	ld ix,la7bch		;9fda
	call dibuja_poligono		;9fde
	ret			;9fe1
espera_tecla:
	push ix		;9fe2
	ld ix,00156h		;9fe4
	call bios		;9fe8
	ld ix,0009fh		;9feb
	call bios		;9fef
	pop ix		;9ff2
	ret			;9ff4
espera_tecla_anim:
	push ix		;9ff5
	ld ix,00156h		;9ff7
	call bios		;9ffb
l9ffeh:
	ld ix,0009ch		;9ffe
	call bios		;a002
	jr nz,la020h		;a005
	ld a,(lafd6h)		;a007
	and a			;a00a
	jr z,l9ffeh		;a00b
	call pausa		;a00d
	call pausa		;a010
	call pausa		;a013
	call pausa		;a016
	ld a,001h		;a019
	call gira_brujula		;a01b
	jr l9ffeh		;a01e
la020h:
	ld ix,0009fh		;a020
	call bios		;a024
	pop ix		;a027
	ret			;a029
pausa:
	ld bc,000ffh		;a02a
la02dh:
	ex de,hl			;a02d
	ex de,hl			;a02e
	dec bc			;a02f
	ld a,b			;a030
	or c			;a031
	jr nz,la02dh		;a032
	ret			;a034
inicia_pantalla:
	xor a			;a035
	ld (la6fdh),a		;a036
	ld (la6feh),a		;a039
	ld (v_columna),a		;a03c
	ld (v_fila),a		;a03f
	ld a,017h		;a042
	ld (la700h),a		;a044
	ld a,027h		;a047
	ld (la6ffh),a		;a049
	ld a,001h		;a04c
	ld (0f3ebh),a		;a04e
	call borra_vram		;a051
	ret			;a054
borra_vram:
	ld a,000h		;a055
	ld hl,00000h		;a057
	ld bc,01800h		;a05a
	ld ix,00056h		;a05d
	call bios		;a061
	ld a,(v_color)		;a064
	ld hl,02000h		;a067
	ld bc,01800h		;a06a
	ld ix,00056h		;a06d
	call bios		;a071
	ret			;a074
pinta_letra:
				; >>> pinta la letra A en (columna, fila); x = 6*columna + 10
	ld h,000h		;a075
	ld l,a			;a077
	ld a,(v_columna)		;a078
	cp 01eh		;a07b
	ret z			;a07d
	ld bc,fuente		;a07e
	add hl,hl			;a081
	add hl,hl			;a082
	add hl,hl			;a083
	add hl,bc			;a084
	ld a,(la6f9h)		;a085
	cp 001h		;a088
	jr nc,la09ch		;a08a
	ld de,la707h		;a08c
	ld bc,00008h		;a08f
	ldir		;a092
	ld ix,la707h		;a094
	call pinta_glifo		;a098
	ret			;a09b
la09ch:
	push hl			;a09c
	pop ix		;a09d
	ld hl,la707h		;a09f
	cp 002h		;a0a2
	jr nc,la0d3h		;a0a4
	ld b,002h		;a0a6
la0a8h:
	push bc			;a0a8
	ld b,004h		;a0a9
la0abh:
	ld a,(ix+000h)		;a0ab
	ld (hl),a			;a0ae
	inc hl			;a0af
	ld (hl),a			;a0b0
	inc hl			;a0b1
	inc ix		;a0b2
	djnz la0abh		;a0b4
	pop bc			;a0b6
	ld hl,la70fh		;a0b7
	djnz la0a8h		;a0ba
	ld hl,v_fila		;a0bc
	dec (hl)			;a0bf
	ld ix,la707h		;a0c0
	call pinta_glifo		;a0c4
	ld hl,v_fila		;a0c7
	inc (hl)			;a0ca
	ld ix,la70fh		;a0cb
	call pinta_glifo		;a0cf
	ret			;a0d2
la0d3h:
	cp 003h		;a0d3
	jr z,la11dh		;a0d5
	ld b,008h		;a0d7
la0d9h:
	push bc			;a0d9
	ld a,(ix+000h)		;a0da
	ld b,008h		;a0dd
la0dfh:
	rlca			;a0df
	rl e		;a0e0
	rl d		;a0e2
	rrca			;a0e4
	rlca			;a0e5
	rl e		;a0e6
	rl d		;a0e8
	djnz la0dfh		;a0ea
	ld a,0fch		;a0ec
	and d			;a0ee
	ld (hl),a			;a0ef
	ld bc,00008h		;a0f0
	add hl,bc			;a0f3
	rr d		;a0f4
	rr e		;a0f6
	rr d		;a0f8
	rr e		;a0fa
	ld (hl),e			;a0fc
	and a			;a0fd
	sbc hl,bc		;a0fe
	pop bc			;a100
	inc ix		;a101
	inc hl			;a103
	djnz la0d9h		;a104
	ld ix,la707h		;a106
	call pinta_glifo		;a10a
	ld hl,v_columna		;a10d
	inc (hl)			;a110
	ld ix,la70fh		;a111
	call pinta_glifo		;a115
	ld hl,v_columna		;a118
	dec (hl)			;a11b
	ret			;a11c
la11dh:
	ld b,002h		;a11d
la11fh:
	push bc			;a11f
	ld b,004h		;a120
la122h:
	push bc			;a122
	ld b,008h		;a123
	ld a,(ix+000h)		;a125
la128h:
	rlca			;a128
	rl e		;a129
	rl d		;a12b
	rrca			;a12d
	rlca			;a12e
	rl e		;a12f
	rl d		;a131
	djnz la128h		;a133
	ld a,0fch		;a135
	and d			;a137
	ld (hl),a			;a138
	inc hl			;a139
	ld (hl),a			;a13a
	ld bc,00007h		;a13b
	add hl,bc			;a13e
	rr d		;a13f
	rr e		;a141
	rr d		;a143
	rr e		;a145
	ld (hl),e			;a147
	inc hl			;a148
	ld (hl),e			;a149
	and a			;a14a
	sbc hl,bc		;a14b
	pop bc			;a14d
	inc ix		;a14e
	djnz la122h		;a150
	ld hl,la717h		;a152
	pop bc			;a155
	djnz la11fh		;a156
	ld hl,v_fila		;a158
	dec (hl)			;a15b
	ld ix,la707h		;a15c
	call pinta_glifo		;a160
	ld hl,v_columna		;a163
	inc (hl)			;a166
	ld ix,la70fh		;a167
	call pinta_glifo		;a16b
	ld hl,v_columna		;a16e
	dec (hl)			;a171
	ld hl,v_fila		;a172
	inc (hl)			;a175
	ld ix,la717h		;a176
	call pinta_glifo		;a17a
	ld ix,la71fh		;a17d
	ld hl,v_columna		;a181
	inc (hl)			;a184
	call pinta_glifo		;a185
	ld hl,v_columna		;a188
	dec (hl)			;a18b
	ret			;a18c
pinta_glifo:
	ld a,(la6fah)		;a18d
	and a			;a190
	jr nz,la1f4h		;a191
	ld (la1b6h),a		;a193
	ld a,0a7h		;a196
	ld (la1bdh),a		;a198
la19bh:
	ld a,(v_fila)		;a19b
	add a,a			;a19e
	add a,a			;a19f
	add a,a			;a1a0
	ld e,a			;a1a1
	ld a,(v_columna)		;a1a2
	ld b,a			;a1a5
	add a,a			;a1a6
	add a,b			;a1a7
	add a,a			;a1a8
	add a,00ah		;a1a9
	call dir_pixel		;a1ab
	push ix		;a1ae
	ld e,b			;a1b0
	ld b,008h		;a1b1
la1b3h:
	ld a,(ix+000h)		;a1b3
la1b6h:
	nop			;a1b6
	ld d,e			;a1b7
	scf			;a1b8
	rr d		;a1b9
	ld c,000h		;a1bb
la1bdh:
	and a			;a1bd
	rla			;a1be
	rl c		;a1bf
	scf			;a1c1
	rr d		;a1c2
	jr nc,la1bdh		;a1c4
	ld (ix+000h),a		;a1c6
	call vpeek		;a1c9
la1cch:
	and e			;a1cc
la1cdh:
	or c			;a1cd
	call vpoke		;a1ce
	call pone_color		;a1d1
	inc hl			;a1d4
	inc ix		;a1d5
	djnz la1b3h		;a1d7
	pop ix		;a1d9
	xor a			;a1db
	cp e			;a1dc
	ret z			;a1dd
	ld b,008h		;a1de
la1e0h:
	call vpeek		;a1e0
	ld c,a			;a1e3
	ld a,(ix+000h)		;a1e4
la1e7h:
	or c			;a1e7
	call vpoke		;a1e8
	call pone_color		;a1eb
	inc hl			;a1ee
	inc ix		;a1ef
	djnz la1e0h		;a1f1
	ret			;a1f3
la1f4h:
	ld a,02fh		;a1f4
	ld (la1b6h),a		;a1f6
	ld a,037h		;a1f9
	ld (la1bdh),a		;a1fb
	jp la19bh		;a1fe
pone_color:
	ld a,h			;a201
	add a,020h		;a202
	ld h,a			;a204
	ld a,(la705h)		;a205
	call vpoke		;a208
	ld a,h			;a20b
	sub 020h		;a20c
	ld h,a			;a20e
	ret			;a20f
procesa_caracter:
				; >>> carácter: <0Ah mensaje; 16h/19h acento; 1Bh orden; 1Fh situar; 7Fh fin
	cp 080h		;a210
	ret nc			;a212
	cp 00ah		;a213
	jp c,imprime_mensaje_n		;a215
	cp 016h		;a218
	jp z,acento		;a21a
	cp 019h		;a21d
	jp z,acento		;a21f
	cp 01bh		;a222
	jp z,escape_1b		;a224
	cp 020h		;a227
	ret c			;a229
la22ah:
	call pinta_letra		;a22a
	ld a,(la6fbh)		;a22d
	and a			;a230
	jr nz,la254h		;a231
	ld (la6fch),a		;a233
	ld (0a1bch),a		;a236
	ld a,0b1h		;a239
	ld (la1cdh),a		;a23b
	ld (la1e7h),a		;a23e
	ld a,0a3h		;a241
	ld (la1cch),a		;a243
	ld a,0afh		;a246
	ld (la1e0h),a		;a248
	ld hl,00000h		;a24b
	ld (la1e0h+1),hl		;a24e
	jp avanza_columna		;a251
la254h:
	xor a			;a254
	ld (la6fbh),a		;a255
	ld a,001h		;a258
	ld (la6fch),a		;a25a
	xor a			;a25d
	ld (la1cch),a		;a25e
	ld a,0cdh		;a261
	ld (la1e0h),a		;a263
	ld hl,vpeek		;a266
	ld (la1e0h+1),hl		;a269
	ld a,(la6fah)		;a26c
	and a			;a26f
	ret z			;a270
	ld a,0a1h		;a271
	ld (la1cdh),a		;a273
	ld (la1e7h),a		;a276
	ld a,0ffh		;a279
	ld (0a1bch),a		;a27b
	ret			;a27e
acento:
				; >>> acento: A grave, B agudo, C circunflejo, H diéresis, K cedilla; se pinta y luego se superpone la letra
	ld a,001h		;a27f
	ld (la6fbh),a		;a281
	ld hl,(v_cadena)		;a284
	inc hl			;a287
	ld a,(hl)			;a288
	cp 041h		;a289
	call z,sub_a2adh		;a28b
	cp 042h		;a28e
	call z,sub_a2b0h		;a290
	cp 043h		;a293
	call z,sub_a2b3h		;a295
	cp 048h		;a298
	call z,sub_a2b6h		;a29a
	cp 04bh		;a29d
	call z,sub_a2b9h		;a29f
	cp 02dh		;a2a2
	call z,sub_a2bch		;a2a4
	ld (v_cadena),hl		;a2a7
	jp la22ah		;a2aa
sub_a2adh:
	ld a,03ch		;a2ad
	ret			;a2af
sub_a2b0h:
	ld a,03dh		;a2b0
	ret			;a2b2
sub_a2b3h:
	ld a,03eh		;a2b3
	ret			;a2b5
sub_a2b6h:
	ld a,040h		;a2b6
	ret			;a2b8
sub_a2b9h:
	ld a,060h		;a2b9
	ret			;a2bb
sub_a2bch:
	ld a,02ah		;a2bc
	ret			;a2be
escape_1b:
				; >>> 1Bh + 40h..5Dh: tabla A72Ch (colores 41-47/51-57, tamaño 4C-4F)
	ld ix,tabla_escapes		;a2bf
	inc hl			;a2c3
	ld a,(hl)			;a2c4
	ld (v_cadena),hl		;a2c5
	sub 040h		;a2c8
	add a,a			;a2ca
	ld (0a2d4h),a		;a2cb
	inc a			;a2ce
	ld (0a2d7h),a		;a2cf
	ld l,(ix+000h)		;a2d2
	ld h,(ix+000h)		;a2d5
	jp (hl)			;a2d8
	ld a,(la705h)		;a2d9
	ld (la706h),a		;a2dc
	and 00fh		;a2df
	ld b,080h		;a2e1
	jp la334h		;a2e3
	ld a,(la705h)		;a2e6
	ld (la706h),a		;a2e9
	and 00fh		;a2ec
	ld b,020h		;a2ee
	jp la334h		;a2f0
	ld a,(la705h)		;a2f3
	ld (la706h),a		;a2f6
	and 00fh		;a2f9
	ld b,0a0h		;a2fb
	jp la334h		;a2fd
	ld a,(la705h)		;a300
	ld (la706h),a		;a303
	and 00fh		;a306
	ld b,040h		;a308
	jp la334h		;a30a
	ld a,(la705h)		;a30d
	ld (la706h),a		;a310
	and 00fh		;a313
	ld b,0d0h		;a315
	jp la334h		;a317
	ld a,(la705h)		;a31a
	ld (la706h),a		;a31d
	and 00fh		;a320
	ld b,070h		;a322
	jp la334h		;a324
	ld a,(la705h)		;a327
	ld (la706h),a		;a32a
	and 00fh		;a32d
	ld b,0f0h		;a32f
	jp la334h		;a331
la334h:
	or b			;a334
	ld (la705h),a		;a335
	ret			;a338
sub_a339h:
	ld hl,v_columna		;a339
	ld a,(la6fdh)		;a33c
la33fh:
	nop			;a33f
	cp (hl)			;a340
	jr z,la34ch		;a341
	dec (hl)			;a343
	ld a,(la6f9h)		;a344
	cp 002h		;a347
	ret c			;a349
	dec (hl)			;a34a
	ret			;a34b
la34ch:
	call sub_a37fh		;a34c
	ld a,(la6ffh)		;a34f
	ld (hl),a			;a352
	ret			;a353
avanza_columna:
	ld hl,v_columna		;a354
	ld a,(la6ffh)		;a357
la35ah:
	nop			;a35a
	cp (hl)			;a35b
	jp z,la368h		;a35c
	inc (hl)			;a35f
	ld a,(la6f9h)		;a360
	cp 002h		;a363
	ret c			;a365
	inc (hl)			;a366
	ret			;a367
la368h:
	call baja_linea		;a368
	call sub_a44ch		;a36b
	ret			;a36e
baja_linea:
	ld hl,v_fila		;a36f
	ld a,(la700h)		;a372
	cp (hl)			;a375
	jr z,la37ah		;a376
	inc (hl)			;a378
	ret			;a379
la37ah:
	ld a,(la6feh)		;a37a
	ld (hl),a			;a37d
	ret			;a37e
sub_a37fh:
	ld hl,v_fila		;a37f
	ld a,(la6feh)		;a382
	cp (hl)			;a385
	jr z,la38ah		;a386
	dec (hl)			;a388
	ret			;a389
la38ah:
	ld a,(la700h)		;a38a
	ld (hl),a			;a38d
	ret			;a38e
caja:
	ld a,(la705h)		;a38f
	push af			;a392
	ld b,040h		;a393
	ld a,(v_color)		;a395
	and 00fh		;a398
	or b			;a39a
	ld (la705h),a		;a39b
	ld hl,la77ch		;a39e
	ld (0a6ddh),hl		;a3a1
	ld hl,(la6fdh)		;a3a4
	call sub_a67eh		;a3a7
	ld (v_linea),hl		;a3aa
	ld a,h			;a3ad
	ld (la6f8h),a		;a3ae
	ld hl,(la6ffh)		;a3b1
	call sub_a67eh		;a3b4
	add a,005h		;a3b7
	ld (la6f7h),a		;a3b9
	ld a,h			;a3bc
	add a,007h		;a3bd
	ld (la70fh),a		;a3bf
	ld a,(la6ffh)		;a3c2
	cp 01eh		;a3c5
	call z,sub_a446h		;a3c7
	ld a,(la6fdh)		;a3ca
	cp 020h		;a3cd
	call z,sub_a43bh		;a3cf
la3d2h:
	ld hl,v_linea		;a3d2
	ld a,(hl)			;a3d5
	inc hl			;a3d6
	ld e,(hl)			;a3d7
	call dir_pixel		;a3d8
	push hl			;a3db
	ld d,b			;a3dc
	ld hl,la6f7h		;a3dd
	ld a,(hl)			;a3e0
	inc hl			;a3e1
	ld e,(hl)			;a3e2
	call dir_pixel		;a3e3
	ld a,b			;a3e6
	ld (la707h),a		;a3e7
	ld b,d			;a3ea
	ex de,hl			;a3eb
	pop hl			;a3ec
	ld c,0ffh		;a3ed
la3efh:
	sla c		;a3ef
	srl b		;a3f1
	jr nc,la3efh		;a3f3
	call vpeek		;a3f5
	and c			;a3f8
la3f9h:
	call vpoke		;a3f9
	call pone_color		;a3fc
	ld c,008h		;a3ff
	add hl,bc			;a401
	call sub_a6e3h		;a402
	ld a,000h		;a405
	jr c,la3f9h		;a407
	ld a,(la707h)		;a409
	ld d,0ffh		;a40c
la40eh:
	srl d		;a40e
	rla			;a410
	jr nc,la40eh		;a411
	call vpeek		;a413
	and d			;a416
	call vpoke		;a417
	call pone_color		;a41a
	ld hl,la6f6h		;a41d
	inc (hl)			;a420
	inc hl			;a421
	inc hl			;a422
	inc (hl)			;a423
	ld a,(la70fh)		;a424
	cp (hl)			;a427
	jr nc,la3d2h		;a428
	ld hl,la774h		;a42a
	ld (0a6ddh),hl		;a42d
	pop af			;a430
	ld (la705h),a		;a431
	call sub_a4a0h		;a434
	call sub_a468h		;a437
	ret			;a43a
sub_a43bh:
	ld a,0c8h		;a43b
	ld (v_linea),a		;a43d
	ld a,0f7h		;a440
	ld (la6f7h),a		;a442
	ret			;a445
sub_a446h:
	ld a,0bfh		;a446
	ld (la6f7h),a		;a448
	ret			;a44b
sub_a44ch:
	ld a,(la6fdh)		;a44c
	ld (v_columna),a		;a44f
	ret			;a452
	xor a			;a453
	ld (la6fah),a		;a454
	ret			;a457
	ld a,001h		;a458
	ld (la6fah),a		;a45a
	ret			;a45d
	ld a,(la706h)		;a45e
	and 0f0h		;a461
	ld b,001h		;a463
	jp la334h		;a465
sub_a468h:
				; >>> 4Ch tamaño normal; 4Dh doble alto; 4Eh doble ancho; 4Fh doble alto y ancho
	xor a			;a468
	ld (la6f9h),a		;a469
	ld (la33fh),a		;a46c
	ld (la35ah),a		;a46f
	ret			;a472
	ld a,001h		;a473
	ld (la6f9h),a		;a475
	xor a			;a478
	ld (la33fh),a		;a479
	ld (la35ah),a		;a47c
	ret			;a47f
	ld a,002h		;a480
	ld (la6f9h),a		;a482
	ld a,03dh		;a485
	ld (la35ah),a		;a487
	ld a,03ch		;a48a
	ld (la33fh),a		;a48c
	ret			;a48f
	ld a,003h		;a490
	ld (la6f9h),a		;a492
	ld a,03dh		;a495
	ld (la35ah),a		;a497
	ld a,03ch		;a49a
	ld (la33fh),a		;a49c
	ret			;a49f
sub_a4a0h:
	ld a,(la6feh)		;a4a0
	ld (v_fila),a		;a4a3
	ld a,(la6fdh)		;a4a6
	ld (v_columna),a		;a4a9
	ret			;a4ac
	ret			;a4ad
imprime:
	push ix		;a4ae
	push iy		;a4b0
	call imprime_bucle		;a4b2
	pop iy		;a4b5
	pop ix		;a4b7
	ret			;a4b9
imprime_bucle:
	ld hl,(v_cadena)		;a4ba
	ld a,(hl)			;a4bd
	cp 01fh		;a4be
	jr z,la4d7h		;a4c0
	cp 07fh		;a4c2
	jr z,la4d2h		;a4c4
	call procesa_caracter		;a4c6
	ld hl,(v_cadena)		;a4c9
	inc hl			;a4cc
	ld (v_cadena),hl		;a4cd
	jr imprime_bucle		;a4d0
la4d2h:
	inc hl			;a4d2
	ld (v_cadena),hl		;a4d3
	ret			;a4d6
la4d7h:
	inc hl			;a4d7
	ld a,(hl)			;a4d8
	sub 03fh		;a4d9
	ld (v_fila),a		;a4db
	inc hl			;a4de
	ld a,(hl)			;a4df
	sub 040h		;a4e0
	ld (v_columna),a		;a4e2
	inc hl			;a4e5
	ld (v_cadena),hl		;a4e6
	jr imprime_bucle		;a4e9
imprime_mensaje:
	push ix		;a4eb
	push iy		;a4ed
	call imprime_mensaje_n		;a4ef
	pop iy		;a4f2
	pop ix		;a4f4
	ret			;a4f6
imprime_mensaje_n:
	cp 005h		;a4f7
	jp c,borra_ventana		;a4f9
	sub 005h		;a4fc
	ld ix,tabla_mensajes		;a4fe
	add a,a			;a502
	ld (0a50ch),a		;a503
	inc a			;a506
	ld (0a50fh),a		;a507
	ld l,(ix+000h)		;a50a
	ld h,(ix+000h)		;a50d
	ld (v_cadena),hl		;a510
	jp imprime_bucle		;a513
dibuja_poligono:
				; >>> polígono: 7 vértices (marcos y cajas de la pantalla)
	ld a,(la705h)		;a516
	push af			;a519
	ld a,(v_color)		;a51a
	and 00fh		;a51d
	or 040h		;a51f
	ld (la705h),a		;a521
	ld hl,la77ch		;a524
	ld (0a6ddh),hl		;a527
	ld l,(ix+000h)		;a52a
	ld h,(ix+001h)		;a52d
	ld (v_linea),hl		;a530
	ld l,(ix+002h)		;a533
	ld h,(ix+003h)		;a536
	ld (la6f7h),hl		;a539
	call linea		;a53c
	ld a,(ix+004h)		;a53f
	ld (la6f8h),a		;a542
	call linea		;a545
	ld a,(ix+005h)		;a548
	ld (la6f7h),a		;a54b
	call linea		;a54e
	ld a,(ix+006h)		;a551
	ld (la6f8h),a		;a554
	call linea		;a557
	ld l,(ix+007h)		;a55a
	ld h,(ix+008h)		;a55d
	ld (v_linea),hl		;a560
	ld l,(ix+009h)		;a563
	ld h,(ix+00ah)		;a566
	ld (la6f7h),hl		;a569
	call linea		;a56c
	ld a,(ix+00bh)		;a56f
	ld (la6f8h),a		;a572
	call linea		;a575
	ld a,(ix+00ch)		;a578
	ld (la6f7h),a		;a57b
	call linea		;a57e
	ld a,(ix+00dh)		;a581
	ld (la6f8h),a		;a584
	call linea		;a587
	ld hl,la774h		;a58a
	ld (0a6ddh),hl		;a58d
	pop af			;a590
	ld (la705h),a		;a591
	ret			;a594
linea:
	ld hl,v_linea		;a595
	ld a,(hl)			;a598
	inc hl			;a599
	inc hl			;a59a
	cp (hl)			;a59b
	jp z,la617h		;a59c
	dec hl			;a59f
	ld a,(hl)			;a5a0
	inc hl			;a5a1
	inc hl			;a5a2
	cp (hl)			;a5a3
	jr z,la5a7h		;a5a4
	ret			;a5a6
la5a7h:
	ld hl,v_linea		;a5a7
	ld a,(hl)			;a5aa
	inc hl			;a5ab
	inc hl			;a5ac
	cp (hl)			;a5ad
	jr nc,la5bah		;a5ae
	call sub_a5c5h		;a5b0
la5b3h:
	ld a,(la6f7h)		;a5b3
	ld (v_linea),a		;a5b6
	ret			;a5b9
la5bah:
	call sub_a66fh		;a5ba
	call sub_a5c5h		;a5bd
	call sub_a66fh		;a5c0
	jr la5b3h		;a5c3
sub_a5c5h:
	ld hl,v_linea		;a5c5
	ld a,(hl)			;a5c8
	inc hl			;a5c9
	ld e,(hl)			;a5ca
	call dir_pixel		;a5cb
	push hl			;a5ce
	push bc			;a5cf
	ld hl,la6f7h		;a5d0
	ld a,(hl)			;a5d3
	inc hl			;a5d4
	ld e,(hl)			;a5d5
	call dir_pixel		;a5d6
	ex de,hl			;a5d9
	ld a,b			;a5da
	ld (la707h),a		;a5db
	pop bc			;a5de
	pop hl			;a5df
	call sub_a6e3h		;a5e0
	jr z,la616h		;a5e3
	ld c,0ffh		;a5e5
la5e7h:
	srl c		;a5e7
	sla b		;a5e9
	jr nc,la5e7h		;a5eb
	call vpeek		;a5ed
	or c			;a5f0
la5f1h:
	call vpoke		;a5f1
	call pone_color		;a5f4
	ld c,008h		;a5f7
	add hl,bc			;a5f9
	call sub_a6e3h		;a5fa
	ld a,0ffh		;a5fd
	jr c,la5f1h		;a5ff
	ld a,(la707h)		;a601
	ld d,0ffh		;a604
la606h:
	sla d		;a606
	rra			;a608
	jr nc,la606h		;a609
	call vpeek		;a60b
	or d			;a60e
	call vpoke		;a60f
	call pone_color		;a612
	ret			;a615
la616h:
	ret			;a616
la617h:
	ld hl,la6f6h		;a617
	ld a,(hl)			;a61a
	inc hl			;a61b
	inc hl			;a61c
	cp (hl)			;a61d
	jr nc,la62ah		;a61e
	call sub_a635h		;a620
la623h:
	ld a,(la6f8h)		;a623
	ld (la6f6h),a		;a626
	ret			;a629
la62ah:
	call sub_a66fh		;a62a
	call sub_a635h		;a62d
	call sub_a66fh		;a630
	jr la623h		;a633
sub_a635h:
	ld hl,v_linea		;a635
	ld a,(hl)			;a638
	inc hl			;a639
	ld e,(hl)			;a63a
	call dir_pixel		;a63b
	push hl			;a63e
	ld hl,la6f7h		;a63f
	ld a,(hl)			;a642
	inc hl			;a643
	ld e,(hl)			;a644
	call dir_pixel		;a645
	ex de,hl			;a648
	pop hl			;a649
la64ah:
	call vpeek		;a64a
	or b			;a64d
	call vpoke		;a64e
	call pone_color		;a651
	call sub_a6e3h		;a654
	ret nc			;a657
	inc hl			;a658
	call sub_a666h		;a659
	jr nz,la64ah		;a65c
	push de			;a65e
	ld de,000f8h		;a65f
	add hl,de			;a662
	pop de			;a663
	jr la64ah		;a664
sub_a666h:
	bit 0,l		;a666
	ret nz			;a668
	bit 1,l		;a669
	ret nz			;a66b
	bit 2,l		;a66c
	ret			;a66e
sub_a66fh:
	ld hl,(v_linea)		;a66f
	ld de,(la6f7h)		;a672
	ld (v_linea),de		;a676
	ld (la6f7h),hl		;a67a
	ret			;a67d
sub_a67eh:
	sla h		;a67e
	sla h		;a680
	sla h		;a682
	ld a,l			;a684
	add a,a			;a685
	add a,l			;a686
	add a,a			;a687
	add a,00ah		;a688
	ld l,a			;a68a
	ret			;a68b
vpoke:
	push af			;a68c
	ld a,l			;a68d
	di			;a68e
	out (099h),a		;a68f
	ld a,h			;a691
	and 03fh		;a692
	or 040h		;a694
	out (099h),a		;a696
	pop af			;a698
	out (098h),a		;a699
	ei			;a69b
	ret			;a69c
vpeek:
	ld a,l			;a69d
	di			;a69e
	out (099h),a		;a69f
	ld a,h			;a6a1
	and 03fh		;a6a2
	out (099h),a		;a6a4
	sla a		;a6a6
	sla a		;a6a8
	in a,(098h)		;a6aa
	ei			;a6ac
	ret			;a6ad
	ex de,hl			;a6ae
	ld a,l			;a6af
	di			;a6b0
	out (099h),a		;a6b1
	ld a,h			;a6b3
	and 03fh		;a6b4
	or 040h		;a6b6
	out (099h),a		;a6b8
	ei			;a6ba
la6bbh:
	ld a,(de)			;a6bb
	out (098h),a		;a6bc
	inc de			;a6be
	dec bc			;a6bf
	ld a,c			;a6c0
	or b			;a6c1
	jr nz,la6bbh		;a6c2
	ret			;a6c4
dir_pixel:
	ld c,a			;a6c5
	ld h,e			;a6c6
	srl h		;a6c7
	srl h		;a6c9
	srl h		;a6cb
	and 0f8h		;a6cd
	ld l,a			;a6cf
	ld a,e			;a6d0
	and 007h		;a6d1
	or l			;a6d3
	ld l,a			;a6d4
	ld a,c			;a6d5
	and 007h		;a6d6
	ld (0a6e1h),a		;a6d8
	ld iy,la774h		;a6db
	ld b,(iy+000h)		;a6df
	ret			;a6e2
sub_a6e3h:
	ld a,h			;a6e3
	sub d			;a6e4
	ret nz			;a6e5
	ld a,l			;a6e6
	sub e			;a6e7
	ret			;a6e8
bios:
				; >>> llama a la BIOS a través de la etapa 2 (8000h -> 8292h)
	push iy		;a6e9
	ld iy,00000h		;a6eb
	call 08000h		;a6ef
	pop iy		;a6f2
	ret			;a6f4

; BLOCK 'datos3' (start 0xa6f5 end 0xa848)
v_linea:
	defs 1,RELLENO	;a6f5
la6f6h:
	defs 1,RELLENO	;a6f6
la6f7h:
	defs 1,RELLENO	;a6f7
la6f8h:
	defs 1,RELLENO	;a6f8
la6f9h:
	defs 1,RELLENO	;a6f9
la6fah:
	defs 1,RELLENO	;a6fa
la6fbh:
	defs 1,RELLENO	;a6fb
la6fch:
	defs 1,RELLENO	;a6fc
la6fdh:
	defs 1,RELLENO	;a6fd
la6feh:
	defs 1,RELLENO	;a6fe
la6ffh:
	defs 1,RELLENO	;a6ff
la700h:
	defs 1,RELLENO	;a700
v_columna:
	defs 1,RELLENO	;a701
v_fila:
	defs 1,RELLENO	;a702
la703h:
	defs 1,RELLENO	;a703
v_color:
	defs 1,RELLENO	;a704
la705h:
	defs 1,RELLENO	;a705
la706h:
	defs 1,RELLENO	;a706
la707h:
	defs 1,RELLENO	;a707
la708h:
	defs 1,RELLENO	;a708
la709h:
	defs 6,RELLENO	;a709
la70fh:
	defs 1,RELLENO	;a70f
la710h:
	defs 1,RELLENO	;a710
la711h:
	defs 6,RELLENO	;a711
la717h:
	defs 8,RELLENO	;a717
la71fh:
	defs 8,RELLENO	;a71f
la727h:
	defs 1,RELLENO	;a727
v_cadena:
	defs 2,RELLENO	;a728
la72ah:
	defs 2,RELLENO	;a72a
tabla_escapes:
	defs 16,RELLENO	;a72c
	defs 16,RELLENO	;a73c
	defs 16,RELLENO	;a74c
	defs 12,RELLENO	;a75c
tabla_mensajes:
	defb 0EDh,0B2h,0Dh,0B3h,2Bh,0B3h,0A9h,0B7h,48h,0B8h,7Ch,0B8h	;a768
la774h:
	defs 8,RELLENO	;a774
la77ch:
	defs 8,RELLENO	;a77c
la784h:
	defs 14,RELLENO	;a784
la792h:
	defs 14,RELLENO	;a792
la7a0h:
	defs 14,RELLENO	;a7a0
la7aeh:
	defs 14,RELLENO	;a7ae
la7bch:
	defs 14,RELLENO	;a7bc
la7cah:
	defs 14,RELLENO	;a7ca
la7d8h:
	defs 14,RELLENO	;a7d8
la7e6h:
	defs 14,RELLENO	;a7e6
la7f4h:
	defs 14,RELLENO	;a7f4
la802h:
	defs 14,RELLENO	;a802
la810h:
	defs 14,RELLENO	;a810
la81eh:
	defs 14,RELLENO	;a81e
la82ch:
	defs 14,RELLENO	;a82c
la83ah:
	defs 14,RELLENO	;a83a

; BLOCK 'codigo4' (start 0xa848 end 0xa88a)
muerte:
				; >>> muerte: A = causa (0 característica a 0, 1 vida a 0, 3 párrafo mortal)
	push af			;a848
	ld a,003h		;a849
	call imprime_mensaje		;a84b
	xor a			;a84e
	call texto_opcion		;a84f
la852h:
	call espera_tecla		;a852
	cp 00dh		;a855
	jr nz,la852h		;a857
	ld a,002h		;a859
	call imprime_mensaje		;a85b
	ld a,008h		;a85e
	call imprime_mensaje		;a860
	ld a,003h		;a863
	call imprime_mensaje		;a865
	pop af			;a868
	cp 003h		;a869
	jr nc,la872h		;a86b
	add a,009h		;a86d
	call imprime_mensaje		;a86f
la872h:
	call espera_tecla		;a872
	cp 048h		;a875
	jr z,la87bh		;a877
	jr la872h		;a879
la87bh:
	ld hl,lb7a9h		;a87b
	ld (lafech),hl		;a87e
	xor a			;a881
	ld (v_opcion),a		;a882
	call menu_h		;a885
	jr la872h		;a888

; BLOCK 'datos5' (start 0xa88a end 0xbdd0)
dibujos_marco:
				; >>> --- DATOS ---
	defs 16,RELLENO	;a88a
	defs 16,RELLENO	;a89a
	defs 16,RELLENO	;a8aa
	defs 16,RELLENO	;a8ba
	defs 16,RELLENO	;a8ca
	defs 16,RELLENO	;a8da
	defs 16,RELLENO	;a8ea
	defs 16,RELLENO	;a8fa
	defs 16,RELLENO	;a90a
	defs 16,RELLENO	;a91a
	defs 16,RELLENO	;a92a
	defs 16,RELLENO	;a93a
	defs 16,RELLENO	;a94a
	defs 16,RELLENO	;a95a
	defs 16,RELLENO	;a96a
	defs 16,RELLENO	;a97a
	defs 16,RELLENO	;a98a
	defs 16,RELLENO	;a99a
	defs 16,RELLENO	;a9aa
	defs 16,RELLENO	;a9ba
	defs 16,RELLENO	;a9ca
	defs 16,RELLENO	;a9da
	defs 16,RELLENO	;a9ea
	defs 16,RELLENO	;a9fa
	defs 16,RELLENO	;aa0a
	defs 16,RELLENO	;aa1a
	defs 16,RELLENO	;aa2a
	defs 16,RELLENO	;aa3a
	defs 16,RELLENO	;aa4a
	defs 16,RELLENO	;aa5a
	defs 16,RELLENO	;aa6a
	defs 16,RELLENO	;aa7a
	defs 16,RELLENO	;aa8a
	defs 16,RELLENO	;aa9a
	defs 16,RELLENO	;aaaa
	defs 16,RELLENO	;aaba
	defs 16,RELLENO	;aaca
	defs 16,RELLENO	;aada
	defs 16,RELLENO	;aaea
	defs 16,RELLENO	;aafa
	defs 16,RELLENO	;ab0a
	defs 16,RELLENO	;ab1a
	defs 16,RELLENO	;ab2a
	defs 16,RELLENO	;ab3a
	defs 16,RELLENO	;ab4a
	defs 16,RELLENO	;ab5a
	defs 16,RELLENO	;ab6a
	defs 16,RELLENO	;ab7a
	defs 16,RELLENO	;ab8a
	defs 3,RELLENO	;ab9a
fuente:
				; >>> fuente de 8x8 (se usan 6 columnas); carácter n en AB9Dh+8n
	defs 16,RELLENO	;ab9d
	defs 16,RELLENO	;abad
	defs 16,RELLENO	;abbd
	defs 16,RELLENO	;abcd
	defs 16,RELLENO	;abdd
	defs 16,RELLENO	;abed
	defs 16,RELLENO	;abfd
	defs 16,RELLENO	;ac0d
	defs 16,RELLENO	;ac1d
	defs 16,RELLENO	;ac2d
	defs 16,RELLENO	;ac3d
	defs 16,RELLENO	;ac4d
	defs 16,RELLENO	;ac5d
	defs 16,RELLENO	;ac6d
	defs 16,RELLENO	;ac7d
	defs 16,RELLENO	;ac8d
	defs 16,RELLENO	;ac9d
	defs 16,RELLENO	;acad
	defs 16,RELLENO	;acbd
	defs 16,RELLENO	;accd
	defs 16,RELLENO	;acdd
	defs 16,RELLENO	;aced
	defs 16,RELLENO	;acfd
	defs 16,RELLENO	;ad0d
	defs 16,RELLENO	;ad1d
	defs 16,RELLENO	;ad2d
	defs 16,RELLENO	;ad3d
	defs 16,RELLENO	;ad4d
	defs 16,RELLENO	;ad5d
	defs 16,RELLENO	;ad6d
	defs 16,RELLENO	;ad7d
	defs 16,RELLENO	;ad8d
	defs 16,RELLENO	;ad9d
	defs 16,RELLENO	;adad
	defs 16,RELLENO	;adbd
	defs 16,RELLENO	;adcd
	defs 16,RELLENO	;addd
	defs 16,RELLENO	;aded
	defs 16,RELLENO	;adfd
	defs 16,RELLENO	;ae0d
	defs 16,RELLENO	;ae1d
	defs 16,RELLENO	;ae2d
	defs 16,RELLENO	;ae3d
	defs 16,RELLENO	;ae4d
	defs 16,RELLENO	;ae5d
	defs 16,RELLENO	;ae6d
	defs 16,RELLENO	;ae7d
	defs 16,RELLENO	;ae8d
	defs 16,RELLENO	;ae9d
	defs 16,RELLENO	;aead
	defs 16,RELLENO	;aebd
	defs 16,RELLENO	;aecd
	defs 16,RELLENO	;aedd
	defs 16,RELLENO	;aeed
	defs 16,RELLENO	;aefd
	defs 16,RELLENO	;af0d
	defs 16,RELLENO	;af1d
	defs 16,RELLENO	;af2d
	defs 16,RELLENO	;af3d
	defs 16,RELLENO	;af4d
	defs 16,RELLENO	;af5d
	defs 8,RELLENO	;af6d
laf75h:
				; >>> datos del canto actual: textos de opciones, dibujos, laterales, longitud
	defs 2,RELLENO	;af75
laf77h:
	defs 2,RELLENO	;af77
laf79h:
	defs 2,RELLENO	;af79
laf7bh:
	defs 2,RELLENO	;af7b
laf7dh:
				; >>> tabla de los cantos C1..C11 (8 bytes cada uno); C6 está vacío
	defs 16,RELLENO	;af7d
	defs 16,RELLENO	;af8d
	defs 16,RELLENO	;af9d
	defs 16,RELLENO	;afad
	defs 16,RELLENO	;afbd
	defs 8,RELLENO	;afcd
v_canto_cargado:
	defs 1,RELLENO	;afd5
lafd6h:
	defs 1,RELLENO	;afd6
lafd7h:
	defs 1,RELLENO	;afd7
v_opcion:
	defs 1,RELLENO	;afd8
lafd9h:
	defs 1,RELLENO	;afd9
lafdah:
	defs 1,RELLENO	;afda
lafdbh:
	defs 1,RELLENO	;afdb
lafdch:
	defs 1,RELLENO	;afdc
lafddh:
	defs 1,RELLENO	;afdd
lafdeh:
	defs 1,RELLENO	;afde
lafdfh:
	defs 3,RELLENO	;afdf
lafe2h:
	defs 2,RELLENO	;afe2
v_dibujos:
	defs 2,RELLENO	;afe4
lafe6h:
	defs 2,RELLENO	;afe6
lafe8h:
	defs 2,RELLENO	;afe8
lafeah:
	defs 2,RELLENO	;afea
lafech:
	defs 2,RELLENO	;afec
lafeeh:
	defs 4,RELLENO	;afee
laff2h:
	defs 16,RELLENO	;aff2
	defs 12,RELLENO	;b002
tabla_menu_h:
				; >>> menú H: 1 Retour vers le futur, 2 à suivre, 3 Bazar, 4 Pub, 5 Gag, 6 Cario Type, 7 Bilan Santé, 8 à Table
	defs 16,RELLENO	;b00e
lb01eh:
				; «E / S / O / N»
	defs 7,RELLENO	;b01e
lb025h:
	defs 4,RELLENO	;b025
lb029h:
	defb 53h,1Fh,53h,60h	;b029
lb02dh:
	defs 4,RELLENO	;b02d
lb031h:
	defb 4Eh,7Fh	;b031
lb033h:
				; «Prépare la cassette Hénerim / Code ?»
	defs 16,RELLENO	;b033
	defs 16,RELLENO	;b043
	defs 16,RELLENO	;b053
	defs 13,RELLENO	;b063
lb070h:
				; «Force / Dextérité / Chance / Intelligence / Volonté / Charisme / Habileté / Défense»
	defs 16,RELLENO	;b070
	defs 16,RELLENO	;b080
	defs 16,RELLENO	;b090
	defs 16,RELLENO	;b0a0
	defs 16,RELLENO	;b0b0
	defs 16,RELLENO	;b0c0
	defs 16,RELLENO	;b0d0
	defs 16,RELLENO	;b0e0
	defs 16,RELLENO	;b0f0
	defs 16,RELLENO	;b100
	defs 1,RELLENO	;b110
lb111h:
				; «»
	defs 8,RELLENO	;b111
lb119h:
				; «(enter) pour valider»
	defs 16,RELLENO	;b119
	defs 12,RELLENO	;b129
lb135h:
				; «Je cherche»
	defs 16,RELLENO	;b135
	defs 4,RELLENO	;b145
lb149h:
				; «J'ai trouvé»
	defs 16,RELLENO	;b149
	defs 6,RELLENO	;b159
lb15fh:
	defs 1,RELLENO	;b15f
lb160h:
	defs 6,RELLENO	;b160
lb166h:
				; «»
	defs 1,RELLENO	;b166
lb167h:
	defs 6,RELLENO	;b167
lb16dh:
				; «Je passe»
	defs 16,RELLENO	;b16d
	defs 2,RELLENO	;b17d
lb17fh:
				; «Erreur cassette»
	defs 16,RELLENO	;b17f
	defs 6,RELLENO	;b18f
lb195h:
				; «1 / 2 / 3 / 4 / 5 / 6 / 7 / 8 / Retour / vers / le / Futur / à / suivre / Bazar / P u b / G a g / Cario / Type / Bilan / Santé / à / Table»
	defs 16,RELLENO	;b195
	defs 16,RELLENO	;b1a5
	defs 16,RELLENO	;b1b5
	defs 16,RELLENO	;b1c5
	defs 16,RELLENO	;b1d5
	defs 16,RELLENO	;b1e5
	defs 16,RELLENO	;b1f5
	defs 16,RELLENO	;b205
	defs 16,RELLENO	;b215
	defs 12,RELLENO	;b225
				; «̄UA? / chant suivant.»
	defs 16,RELLENO	;b231
	defs 16,RELLENO	;b241
	defs 4,RELLENO	;b251
lb255h:
				; «Tu laisses»
	defs 16,RELLENO	;b255
	defs 8,RELLENO	;b265
lb26dh:
				; «Tu prends»
	defs 16,RELLENO	;b26d
	defs 7,RELLENO	;b27d
lb284h:
				; «Tu retournes à la Geste.»
	defs 16,RELLENO	;b284
	defs 16,RELLENO	;b294
	defs 3,RELLENO	;b2a4
lb2a7h:
				; «Prépare la cassette  Chants / positionnée sur»
	defs 16,RELLENO	;b2a7
	defs 16,RELLENO	;b2b7
	defs 16,RELLENO	;b2c7
	defs 16,RELLENO	;b2d7
	defs 6,RELLENO	;b2e7
lb2edh:
				; «Et la Geste continue...»
	defs 16,RELLENO	;b2ed
	defs 16,RELLENO	;b2fd
				; «Caracteristique à 0»
	defs 16,RELLENO	;b30d
	defs 14,RELLENO	;b31d
				; «Points de vie à 0»
	defs 16,RELLENO	;b32b
	defs 12,RELLENO	;b33b
				; «Veux-tu : / 1. quitter la Geste / 2. Retour vers le futur»
	defs 16,RELLENO	;b347
	defs 16,RELLENO	;b357
	defs 16,RELLENO	;b367
	defs 16,RELLENO	;b377
	defs 16,RELLENO	;b387
	defs 1,RELLENO	;b397
lb398h:
				; «Poids :»
	defs 14,RELLENO	;b398
lb3a6h:
				; «Voyons, un Artillac / ne se sépare jamais / d'un tel objet !»
	defs 16,RELLENO	;b3a6
	defs 16,RELLENO	;b3b6
	defs 16,RELLENO	;b3c6
	defs 16,RELLENO	;b3d6
	defs 5,RELLENO	;b3e6
lb3ebh:
				; «allons, cet objet ne te / servirait à rien !»
	defs 16,RELLENO	;b3eb
	defs 16,RELLENO	;b3fb
	defs 16,RELLENO	;b40b
	defs 5,RELLENO	;b41b
lb420h:
				; «impossible, tu serais / trop chargé !»
	defs 16,RELLENO	;b420
	defs 16,RELLENO	;b430
	defs 16,RELLENO	;b440
lb450h:
				; «Si tu voulais mesurer la / vie en termes d'unités, le / fou te crierait : "»
	defs 16,RELLENO	;b450
	defs 16,RELLENO	;b460
	defs 16,RELLENO	;b470
	defs 16,RELLENO	;b480
	defs 16,RELLENO	;b490
	defs 13,RELLENO	;b4a0
lb4adh:
				; «points / de santé !". Mais le sage / te dirait doucement que le / mirroir de l'illusion a déjà / piégé plus d'une alouette...»
	defs 16,RELLENO	;b4ad
	defs 16,RELLENO	;b4bd
	defs 16,RELLENO	;b4cd
	defs 16,RELLENO	;b4dd
	defs 16,RELLENO	;b4ed
	defs 16,RELLENO	;b4fd
	defs 16,RELLENO	;b50d
	defs 16,RELLENO	;b51d
	defs 16,RELLENO	;b52d
	defs 3,RELLENO	;b53d
lb540h:
				; «Tu possèdes»
	defs 16,RELLENO	;b540
	defs 8,RELLENO	;b550
lb558h:
				; «repas»
	defs 9,RELLENO	;b558
lb561h:
				; «Tu manges»
	defs 16,RELLENO	;b561
lb571h:
				; «Tu n'as plus rien  / à manger !»
	defs 16,RELLENO	;b571
	defs 16,RELLENO	;b581
	defs 10,RELLENO	;b591
lb59bh:
				; «Tu as assez mangé / comme ça !»
	defs 16,RELLENO	;b59b
	defs 16,RELLENO	;b5ab
	defs 11,RELLENO	;b5bb
lb5c6h:
				; «la / Geste / d' / Artillac / est / Géniale / et tu ne connais encore / que le premier conte...»
	defs 16,RELLENO	;b5c6
	defs 16,RELLENO	;b5d6
	defs 16,RELLENO	;b5e6
	defs 16,RELLENO	;b5f6
	defs 16,RELLENO	;b606
	defs 16,RELLENO	;b616
	defs 16,RELLENO	;b626
	defs 14,RELLENO	;b636
lb644h:
				; «La Geste d'Artillac / un poème arc-en-ciel / des contes merveilleux / La Geste d'Artillac»
	defs 16,RELLENO	;b644
	defs 16,RELLENO	;b654
	defs 16,RELLENO	;b664
	defs 16,RELLENO	;b674
	defs 16,RELLENO	;b684
	defs 16,RELLENO	;b694
	defs 16,RELLENO	;b6a4
	defs 16,RELLENO	;b6b4
	defs 3,RELLENO	;b6c4
				; «une épopée féérique / composée par / André le Conteur / François le Rêveur / Philippe le Jongleur / Thierry le Baladin / et la compagnie du  Tatou»
	defs 16,RELLENO	;b6c7
	defs 16,RELLENO	;b6d7
	defs 16,RELLENO	;b6e7
	defs 16,RELLENO	;b6f7
	defs 16,RELLENO	;b707
	defs 16,RELLENO	;b717
	defs 16,RELLENO	;b727
	defs 16,RELLENO	;b737
	defs 16,RELLENO	;b747
	defs 16,RELLENO	;b757
	defs 16,RELLENO	;b767
	defs 11,RELLENO	;b777
				; «l'éternité n'attends pas...»
	defs 16,RELLENO	;b782
	defs 16,RELLENO	;b792
	defs 7,RELLENO	;b7a2
lb7a9h:
				; «La Geste a perdu son Héros. / Seule la résurrection / permettra de chanter / à nouveau l'épopée / d'Hénerim d'Artillac !»
	defs 16,RELLENO	;b7a9
	defs 16,RELLENO	;b7b9
	defs 16,RELLENO	;b7c9
	defs 16,RELLENO	;b7d9
	defs 16,RELLENO	;b7e9
	defs 16,RELLENO	;b7f9
	defs 16,RELLENO	;b809
	defs 16,RELLENO	;b819
	defs 16,RELLENO	;b829
	defs 15,RELLENO	;b839
				; «ton cariotype te réserve / une surprise !»
	defs 16,RELLENO	;b848
	defs 16,RELLENO	;b858
	defs 16,RELLENO	;b868
	defs 4,RELLENO	;b878
				; «bien vain est l'exploit / où tu laisses la santé...»
	defs 16,RELLENO	;b87c
	defs 16,RELLENO	;b88c
	defs 16,RELLENO	;b89c
	defs 16,RELLENO	;b8ac
codigo_panos:
				; >>> código secreto del canto 10
				; «PANOSle grand portrait / de ton père»
	defs 5,RELLENO	;b8bc
lb8c1h:
	defs 16,RELLENO	;b8c1
	defs 16,RELLENO	;b8d1
	defs 16,RELLENO	;b8e1
	defs 16,RELLENO	;b8f1
	defs 16,RELLENO	;b901
	defs 16,RELLENO	;b911
	defs 16,RELLENO	;b921
	defs 16,RELLENO	;b931
	defs 16,RELLENO	;b941
	defs 16,RELLENO	;b951
	defs 16,RELLENO	;b961
	defs 16,RELLENO	;b971
	defs 16,RELLENO	;b981
	defs 16,RELLENO	;b991
	defs 16,RELLENO	;b9a1
	defs 16,RELLENO	;b9b1
	defs 16,RELLENO	;b9c1
	defs 16,RELLENO	;b9d1
	defs 16,RELLENO	;b9e1
	defs 16,RELLENO	;b9f1
	defs 16,RELLENO	;ba01
	defs 16,RELLENO	;ba11
	defs 16,RELLENO	;ba21
	defs 16,RELLENO	;ba31
	defs 16,RELLENO	;ba41
	defs 16,RELLENO	;ba51
	defs 16,RELLENO	;ba61
	defs 16,RELLENO	;ba71
	defs 16,RELLENO	;ba81
	defs 16,RELLENO	;ba91
	defs 16,RELLENO	;baa1
	defs 16,RELLENO	;bab1
	defs 16,RELLENO	;bac1
	defs 16,RELLENO	;bad1
	defs 16,RELLENO	;bae1
	defs 16,RELLENO	;baf1
	defs 16,RELLENO	;bb01
	defs 16,RELLENO	;bb11
	defs 16,RELLENO	;bb21
	defs 16,RELLENO	;bb31
	defs 16,RELLENO	;bb41
	defs 16,RELLENO	;bb51
	defs 16,RELLENO	;bb61
	defs 16,RELLENO	;bb71
	defs 8,RELLENO	;bb81
lbb89h:
	defs 16,RELLENO	;bb89
	defs 16,RELLENO	;bb99
	defs 16,RELLENO	;bba9
	defs 16,RELLENO	;bbb9
	defs 16,RELLENO	;bbc9
	defs 16,RELLENO	;bbd9
	defs 16,RELLENO	;bbe9
	defs 16,RELLENO	;bbf9
	defs 16,RELLENO	;bc09
	defs 16,RELLENO	;bc19
	defs 16,RELLENO	;bc29
	defs 16,RELLENO	;bc39
	defs 16,RELLENO	;bc49
	defs 16,RELLENO	;bc59
	defs 16,RELLENO	;bc69
	defs 16,RELLENO	;bc79
	defs 16,RELLENO	;bc89
	defs 16,RELLENO	;bc99
	defs 16,RELLENO	;bca9
	defs 16,RELLENO	;bcb9
	defs 6,RELLENO	;bcc9
lbccfh:
	defs 16,RELLENO	;bccf
	defs 16,RELLENO	;bcdf
	defs 16,RELLENO	;bcef
	defs 16,RELLENO	;bcff
	defs 16,RELLENO	;bd0f
	defs 16,RELLENO	;bd1f
	defs 16,RELLENO	;bd2f
	defs 16,RELLENO	;bd3f
	defs 16,RELLENO	;bd4f
	defs 16,RELLENO	;bd5f
	defs 16,RELLENO	;bd6f
	defs 16,RELLENO	;bd7f
	defs 16,RELLENO	;bd8f
	defs 16,RELLENO	;bd9f
	defs 16,RELLENO	;bdaf
	defs 16,RELLENO	;bdbf
	defs 1,RELLENO	;bdcf


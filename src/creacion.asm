; ============================================================================
; La Geste d'Artillac (Infogrames, 1985) - MSX - cinta 1 «Liminaire»
; Bloque 5: CREACIÓN DEL PERSONAJE, 9000h-AC2Fh, cifrado con XOR 76h.
; Menú «Hénerim selon 1 la Geste / 2 tes goûts / 3 retour vers le futur»,
; elección de uno de los 4 Hénerim (malin, puissant, fort, équilibré) o reparto
; propio, Expert/Novice y la hoja inicial en E000h. Vuelve a la etapa 2.
; El código original es (c) Infogrames 1985. Comentarios: Claude para araubi (2026).
;
; REPOSITORIO: sin datos del juego. Cada «defb» original es aquí «defs n,RELLENO»; build.py
; ensambla con RELLENO=00h y FFh y rellena esos huecos con los bytes de las cintas del usuario.
; Licencia del desensamblado (comentarios, etiquetas y estructura): CC BY-NC-SA 4.0, araubi 2026.
; El código y los datos originales son de Infogrames; ninguna licencia de este repositorio los cubre.
; ============================================================================


	org	09000h


; BLOCK 'codigo0' (start 0x9000 end 0x930c)
	di			;9000
	call la100h		;9001
	ei			;9004
	call l95e4h		;9005
	xor a			;9008
	ld (0e200h),a		;9009
menu_inicial:
	ld hl,l9bd3h		;900c
	ld (l9b5dh),hl		;900f
	call l9a63h		;9012
l9015h:
	call espera_tecla		;9015
	cp 031h		;9018
	jr z,opcion1_la_geste		;901a
	cp 032h		;901c
	jp z,opcion2_tes_gouts		;901e
	cp 033h		;9021
	jp z,opcion3_retour_futur		;9023
	jr l9015h		;9026
opcion1_la_geste:
	xor a			;9028
	ld (l9badh),a		;9029
	call sub_961dh		;902c
	ld hl,l9c4bh		;902f
	ld (l9b5dh),hl		;9032
	call l9a63h		;9035
	call l98f0h		;9038
	call l9a1dh		;903b
	ld de,l9ef6h		;903e
	ld b,004h		;9041
	ld hl,l9bbbh		;9043
l9046h:
	push bc			;9046
	push hl			;9047
	ld (l9b5dh),hl		;9048
	call sub_919eh		;904b
	pop hl			;904e
	ld bc,00004h		;904f
	add hl,bc			;9052
	pop bc			;9053
	djnz l9046h		;9054
	ld hl,l9ef6h		;9056
	ld (l9bb9h),hl		;9059
	ld hl,l9dc9h		;905c
	ld de,l9b2ch		;905f
	ld bc,00004h		;9062
	ldir		;9065
	jp l9103h		;9067
elige_personaje:
	call espera_tecla		;906a
	cp 031h		;906d
	jp z,l9103h		;906f
	cp 032h		;9072
	jp z,l9123h		;9074
	cp 033h		;9077
	jp z,l914ch		;9079
	cp 034h		;907c
	jp z,l9175h		;907e
	cp 00dh		;9081
	jr nz,elige_personaje		;9083
	call sub_960bh		;9085
expert_novice:
	xor a			;9088
	ld (l9bb8h),a		;9089
	ld hl,l9d50h		;908c
	ld (l9b5dh),hl		;908f
	call l9a63h		;9092
l9095h:
	call espera_tecla		;9095
	cp 045h		;9098
	jp z,l90fbh		;909a
	cp 04eh		;909d
	jp nz,l9095h		;909f
l90a2h:
	ld hl,l9d7fh		;90a2
	ld (l9b5dh),hl		;90a5
	call l9a63h		;90a8
	call espera_tecla		;90ab
	cp 04fh		;90ae
	jp z,l90beh		;90b0
	cp 04eh		;90b3
	jp nz,l90a2h		;90b5
	call sub_961dh		;90b8
	jp menu_inicial		;90bb
l90beh:
	ld hl,(l9bb9h)		;90be
	ld de,l9f16h		;90c1
	ld bc,00008h		;90c4
	ldir		;90c7
	ld a,(l9bb8h)		;90c9
	and a			;90cc
	jp z,l90d5h		;90cd
	ld a,00ah		;90d0
	ld (l9f1eh),a		;90d2
l90d5h:
	call sub_961dh		;90d5
				; >>> copia la hoja del personaje a E000h (0B4h bytes)
	ld hl,l9f16h		;90d8
	ld de,0e000h		;90db
	ld bc,000b4h		;90de
	ldir		;90e1
	ld hl,l9e9bh		;90e3
	ld (l9b5dh),hl		;90e6
	call l9a63h		;90e9
	di			;90ec
				; >>> H.KEYI = RET
	ld a,0c9h		;90ed
	ld (0fd9ah),a		;90ef
	ld ix,00090h		;90f2
	call bios		;90f6
	ei			;90f9
	ret			;90fa
l90fbh:
	ld a,001h		;90fb
	ld (l9bb8h),a		;90fd
	jp l90a2h		;9100
l9103h:
	call sub_9965h		;9103
	ld hl,l9ef6h		;9106
	ld (l9bb9h),hl		;9109
	ld hl,l9daeh		;910c
	ld (l9b5dh),hl		;910f
	call l9a63h		;9112
	ld hl,l9dc9h		;9115
	ld de,l9b2ch		;9118
	ld bc,00004h		;911b
	ldir		;911e
	jp elige_personaje		;9120
l9123h:
	call sub_9965h		;9123
	ld hl,l9efeh		;9126
	ld (l9bb9h),hl		;9129
	ld hl,l9dbdh		;912c
	ld (l9b5dh),hl		;912f
	call l9a63h		;9132
	ld hl,l9db1h		;9135
	ld (l9b5dh),hl		;9138
	call l9a63h		;913b
	ld hl,l9dcdh		;913e
	ld de,l9b2ch		;9141
	ld bc,00004h		;9144
	ldir		;9147
	jp elige_personaje		;9149
l914ch:
	call sub_9965h		;914c
	ld hl,l9f06h		;914f
	ld (l9bb9h),hl		;9152
	ld hl,l9dc1h		;9155
	ld (l9b5dh),hl		;9158
	call l9a63h		;915b
	ld hl,l9db1h		;915e
	ld (l9b5dh),hl		;9161
	call l9a63h		;9164
	ld hl,l9dd1h		;9167
	ld de,l9b2ch		;916a
	ld bc,00004h		;916d
	ldir		;9170
	jp elige_personaje		;9172
l9175h:
	call sub_9965h		;9175
	ld hl,l9f0eh		;9178
	ld (l9bb9h),hl		;917b
	ld hl,l9dc5h		;917e
	ld (l9b5dh),hl		;9181
	call l9a63h		;9184
	ld hl,l9db1h		;9187
	ld (l9b5dh),hl		;918a
	call l9a63h		;918d
	ld hl,l9dd5h		;9190
	ld de,l9b2ch		;9193
	ld bc,00004h		;9196
	ldir		;9199
	jp elige_personaje		;919b
sub_919eh:
	push de			;919e
	call l9a63h		;919f
	pop de			;91a2
	ld b,008h		;91a3
l91a5h:
	push bc			;91a5
	ld hl,l9bcbh		;91a6
	call sub_92dah		;91a9
	inc de			;91ac
	ld hl,l9bcch		;91ad
	ld (l9b5dh),hl		;91b0
	push de			;91b3
	call l9a63h		;91b4
	ld a,(l9badh)		;91b7
	and a			;91ba
	call nz,sub_9945h		;91bb
	call sub_9945h		;91be
	call sub_990fh		;91c1
	call sub_990fh		;91c4
	pop de			;91c7
	pop bc			;91c8
	djnz l91a5h		;91c9
	ret			;91cb
opcion2_tes_gouts:
	ld a,014h		;91cc
	ld (l9baeh),a		;91ce
	ld a,018h		;91d1
	ld (l9bafh),a		;91d3
	ld a,001h		;91d6
	ld (l9badh),a		;91d8
	call sub_961dh		;91db
	ld hl,l9dd9h		;91de
	ld (l9b5dh),hl		;91e1
	call l9a63h		;91e4
	ld hl,l9bb0h		;91e7
	ld de,03800h		;91ea
	ld bc,00008h		;91ed
	call sub_9addh		;91f0
	ld a,007h		;91f3
	ld hl,01b03h		;91f5
	call sub_9abbh		;91f8
	ld hl,l9f16h		;91fb
	ld iy,l9baeh		;91fe
l9202h:
	push hl			;9202
	push iy		;9203
	ld de,l9f16h		;9205
	ld hl,l9bcfh		;9208
	ld (l9b5dh),hl		;920b
	call sub_919eh		;920e
	pop iy		;9211
	pop hl			;9213
l9214h:
	ld a,(iy+001h)		;9214
	cp 018h		;9217
	call c,sub_92a2h		;9219
	cp 089h		;921c
	call nc,sub_92abh		;921e
	push hl			;9221
	ld hl,01b00h		;9222
	ld a,(iy+001h)		;9225
	halt			;9228
	call sub_9abbh		;9229
	ld a,(iy+000h)		;922c
	inc hl			;922f
	call sub_9abbh		;9230
	pop hl			;9233
l9234h:
	call espera_tecla		;9234
	cp 01ch		;9237
	jp z,l9272h		;9239
	cp 01dh		;923c
	jp z,l927eh		;923e
	cp 01eh		;9241
	jp z,l9296h		;9243
	cp 01fh		;9246
	jp z,l928ah		;9248
	cp 00dh		;924b
	jp nz,l9234h		;924d
	push hl			;9250
	ld hl,l9f16h		;9251
	xor a			;9254
	ld b,008h		;9255
l9257h:
	add a,(hl)			;9257
	inc hl			;9258
	djnz l9257h		;9259
	pop hl			;925b
	cp 041h		;925c
	jp nc,l9202h		;925e
	ld a,0cfh		;9261
	ld hl,01b00h		;9263
	call sub_9abbh		;9266
	ld hl,l9f16h		;9269
	ld (l9bb9h),hl		;926c
	jp expert_novice		;926f
l9272h:
	inc (hl)			;9272
	ld a,00fh		;9273
	cp (hl)			;9275
	jp nc,l9202h		;9276
	ld (hl),001h		;9279
	jp l9202h		;927b
l927eh:
	dec (hl)			;927e
	ld a,000h		;927f
	cp (hl)			;9281
	jp c,l9202h		;9282
	ld (hl),00fh		;9285
	jp l9202h		;9287
l928ah:
	ld a,(iy+001h)		;928a
	add a,010h		;928d
	ld (iy+001h),a		;928f
	inc hl			;9292
	jp l9214h		;9293
l9296h:
	ld a,(iy+001h)		;9296
	sub 010h		;9299
	ld (iy+001h),a		;929b
	dec hl			;929e
	jp l9214h		;929f
sub_92a2h:
	ld (iy+001h),088h		;92a2
	ld bc,00008h		;92a6
	add hl,bc			;92a9
	ret			;92aa
sub_92abh:
	ld (iy+001h),018h		;92ab
	ld bc,00008h		;92af
	and a			;92b2
	sbc hl,bc		;92b3
	ret			;92b5
opcion3_retour_futur:
	ld hl,l9d7fh		;92b6
	ld (l9b5dh),hl		;92b9
	call l9a63h		;92bc
l92bfh:
	call espera_tecla		;92bf
	cp 04fh		;92c2
	jp z,l92d2h		;92c4
	cp 04eh		;92c7
	jp nz,l92bfh		;92c9
	call sub_961dh		;92cc
	jp menu_inicial		;92cf
l92d2h:
	ld a,0ffh		;92d2
	ld (0e200h),a		;92d4
	jp l90d5h		;92d7
sub_92dah:
	xor a			;92da
	ld (l9b3dh),a		;92db
	ld a,(de)			;92de
	ld c,09ch		;92df
	call sub_92ebh		;92e1
	ld c,0f6h		;92e4
	call sub_92ebh		;92e6
	ld c,0ffh		;92e9
sub_92ebh:
	ld b,02fh		;92eb
l92edh:
	inc b			;92ed
	add a,c			;92ee
	jr c,l92edh		;92ef
	sbc a,c			;92f1
	push af			;92f2
	ld a,030h		;92f3
	cp b			;92f5
	jp z,l9300h		;92f6
	ld (l9b3dh),a		;92f9
l92fch:
	pop af			;92fc
	ld (hl),b			;92fd
	inc hl			;92fe
	ret			;92ff
l9300h:
	ld a,(l9b3dh)		;9300
	and a			;9303
	jp nz,l92fch		;9304
	ld b,020h		;9307
	jp l92fch		;9309

; BLOCK 'datos1' (start 0x930c end 0x95e4)
l930ch:
	defs 16,RELLENO	;930c
	defs 16,RELLENO	;931c
	defs 16,RELLENO	;932c
	defs 16,RELLENO	;933c
	defs 16,RELLENO	;934c
	defs 16,RELLENO	;935c
	defs 16,RELLENO	;936c
	defs 16,RELLENO	;937c
	defs 16,RELLENO	;938c
	defs 16,RELLENO	;939c
	defs 16,RELLENO	;93ac
	defs 16,RELLENO	;93bc
	defs 16,RELLENO	;93cc
	defs 16,RELLENO	;93dc
	defs 16,RELLENO	;93ec
	defs 16,RELLENO	;93fc
	defs 16,RELLENO	;940c
	defs 16,RELLENO	;941c
	defs 16,RELLENO	;942c
	defs 16,RELLENO	;943c
	defs 16,RELLENO	;944c
	defs 16,RELLENO	;945c
	defs 16,RELLENO	;946c
	defs 16,RELLENO	;947c
	defs 16,RELLENO	;948c
	defs 16,RELLENO	;949c
	defs 16,RELLENO	;94ac
	defs 16,RELLENO	;94bc
	defs 16,RELLENO	;94cc
	defs 16,RELLENO	;94dc
	defs 16,RELLENO	;94ec
	defs 16,RELLENO	;94fc
	defs 16,RELLENO	;950c
	defs 16,RELLENO	;951c
	defs 16,RELLENO	;952c
	defs 16,RELLENO	;953c
	defs 16,RELLENO	;954c
	defs 16,RELLENO	;955c
	defs 16,RELLENO	;956c
	defs 16,RELLENO	;957c
	defs 16,RELLENO	;958c
	defs 16,RELLENO	;959c
	defs 16,RELLENO	;95ac
	defs 16,RELLENO	;95bc
	defs 16,RELLENO	;95cc
	defs 8,RELLENO	;95dc

; BLOCK 'codigo2' (start 0x95e4 end 0x98af)
l95e4h:
	ld a,0ffh		;95e4
	ld (0fcabh),a		;95e6
	ld hl,l930ch		;95e9
	call sub_95f8h		;95ec
	ret			;95ef
espera_tecla:
	ld ix,0009fh		;95f0
	call bios		;95f4
	ret			;95f7
sub_95f8h:
	call sub_960bh		;95f8
	xor a			;95fb
	ld (l9b30h),a		;95fc
	ld (l9b31h),a		;95ff
	ld a,001h		;9602
	ld (0f3ebh),a		;9604
	call sub_961dh		;9607
	ret			;960a
sub_960bh:
	xor a			;960b
	ld (l9b2ch),a		;960c
	ld (l9b2dh),a		;960f
	ld a,017h		;9612
	ld (l9b2fh),a		;9614
	ld a,027h		;9617
	ld (l9b2eh),a		;9619
	ret			;961c
sub_961dh:
	ld a,000h		;961d
	ld hl,00000h		;961f
	ld bc,01800h		;9622
	ld ix,00056h		;9625
	call bios		;9629
	ld a,(l9b32h)		;962c
	ld hl,02000h		;962f
	ld bc,01800h		;9632
	ld ix,00056h		;9635
	call bios		;9639
	ret			;963c
sub_963dh:
	ld h,000h		;963d
	ld l,a			;963f
	ld bc,0920ch		;9640
	add hl,hl			;9643
	add hl,hl			;9644
	add hl,hl			;9645
	add hl,bc			;9646
	ld a,(l9b28h)		;9647
	cp 001h		;964a
	jr nc,l965eh		;964c
	ld de,l9b3dh		;964e
	ld bc,00008h		;9651
	ldir		;9654
	ld ix,l9b3dh		;9656
	call sub_974fh		;965a
	ret			;965d
l965eh:
	push hl			;965e
	pop ix		;965f
	ld hl,l9b3dh		;9661
	cp 002h		;9664
	jr nc,l9695h		;9666
	ld b,002h		;9668
l966ah:
	push bc			;966a
	ld b,004h		;966b
l966dh:
	ld a,(ix+000h)		;966d
	ld (hl),a			;9670
	inc hl			;9671
	ld (hl),a			;9672
	inc hl			;9673
	inc ix		;9674
	djnz l966dh		;9676
	pop bc			;9678
	ld hl,l9b45h		;9679
	djnz l966ah		;967c
	ld hl,l9b31h		;967e
	dec (hl)			;9681
	ld ix,l9b3dh		;9682
	call sub_974fh		;9686
	ld hl,l9b31h		;9689
	inc (hl)			;968c
	ld ix,l9b45h		;968d
	call sub_974fh		;9691
	ret			;9694
l9695h:
	cp 003h		;9695
	jr z,l96dfh		;9697
	ld b,008h		;9699
l969bh:
	push bc			;969b
	ld a,(ix+000h)		;969c
	ld b,008h		;969f
l96a1h:
	rlca			;96a1
	rl e		;96a2
	rl d		;96a4
	rrca			;96a6
	rlca			;96a7
	rl e		;96a8
	rl d		;96aa
	djnz l96a1h		;96ac
	ld a,0fch		;96ae
	and d			;96b0
	ld (hl),a			;96b1
	ld bc,00008h		;96b2
	add hl,bc			;96b5
	rr d		;96b6
	rr e		;96b8
	rr d		;96ba
	rr e		;96bc
	ld (hl),e			;96be
	and a			;96bf
	sbc hl,bc		;96c0
	pop bc			;96c2
	inc ix		;96c3
	inc hl			;96c5
	djnz l969bh		;96c6
	ld ix,l9b3dh		;96c8
	call sub_974fh		;96cc
	ld hl,l9b30h		;96cf
	inc (hl)			;96d2
	ld ix,l9b45h		;96d3
	call sub_974fh		;96d7
	ld hl,l9b30h		;96da
	dec (hl)			;96dd
	ret			;96de
l96dfh:
	ld b,002h		;96df
l96e1h:
	push bc			;96e1
	ld b,004h		;96e2
l96e4h:
	push bc			;96e4
	ld b,008h		;96e5
	ld a,(ix+000h)		;96e7
l96eah:
	rlca			;96ea
	rl e		;96eb
	rl d		;96ed
	rrca			;96ef
	rlca			;96f0
	rl e		;96f1
	rl d		;96f3
	djnz l96eah		;96f5
	ld a,0fch		;96f7
	and d			;96f9
	ld (hl),a			;96fa
	inc hl			;96fb
	ld (hl),a			;96fc
	ld bc,00007h		;96fd
	add hl,bc			;9700
	rr d		;9701
	rr e		;9703
	rr d		;9705
	rr e		;9707
	ld (hl),e			;9709
	inc hl			;970a
	ld (hl),e			;970b
	and a			;970c
	sbc hl,bc		;970d
	pop bc			;970f
	inc ix		;9710
	djnz l96e4h		;9712
	ld hl,l9b4dh		;9714
	pop bc			;9717
	djnz l96e1h		;9718
	ld hl,l9b31h		;971a
	dec (hl)			;971d
	ld ix,l9b3dh		;971e
	call sub_974fh		;9722
	ld hl,l9b30h		;9725
	inc (hl)			;9728
	ld ix,l9b45h		;9729
	call sub_974fh		;972d
	ld hl,l9b30h		;9730
	dec (hl)			;9733
	ld hl,l9b31h		;9734
	inc (hl)			;9737
	ld ix,l9b4dh		;9738
	call sub_974fh		;973c
	ld ix,l9b55h		;973f
	ld hl,l9b30h		;9743
	inc (hl)			;9746
	call sub_974fh		;9747
	ld hl,l9b30h		;974a
	dec (hl)			;974d
	ret			;974e
sub_974fh:
	ld a,(l9b29h)		;974f
	and a			;9752
	jr nz,l97b6h		;9753
	ld (l9778h),a		;9755
	ld a,0a7h		;9758
	ld (l977fh),a		;975a
l975dh:
	ld a,(l9b31h)		;975d
	add a,a			;9760
	add a,a			;9761
	add a,a			;9762
	ld e,a			;9763
	ld a,(l9b30h)		;9764
	ld b,a			;9767
	add a,a			;9768
	add a,b			;9769
	add a,a			;976a
	add a,00ah		;976b
	call sub_9af4h		;976d
	push ix		;9770
	ld e,b			;9772
	ld b,008h		;9773
l9775h:
	ld a,(ix+000h)		;9775
l9778h:
	nop			;9778
	ld d,e			;9779
	scf			;977a
	rr d		;977b
	ld c,000h		;977d
l977fh:
	and a			;977f
	rla			;9780
	rl c		;9781
	scf			;9783
	rr d		;9784
	jr nc,l977fh		;9786
	ld (ix+000h),a		;9788
	call sub_9acch		;978b
l978eh:
	and e			;978e
l978fh:
	or c			;978f
	call sub_9abbh		;9790
	call sub_97c3h		;9793
	inc hl			;9796
	inc ix		;9797
	djnz l9775h		;9799
	pop ix		;979b
	xor a			;979d
	cp e			;979e
	ret z			;979f
	ld b,008h		;97a0
l97a2h:
	call sub_9acch		;97a2
	ld c,a			;97a5
	ld a,(ix+000h)		;97a6
l97a9h:
	or c			;97a9
	call sub_9abbh		;97aa
	call sub_97c3h		;97ad
	inc hl			;97b0
	inc ix		;97b1
	djnz l97a2h		;97b3
	ret			;97b5
l97b6h:
	ld a,02fh		;97b6
	ld (l9778h),a		;97b8
	ld a,037h		;97bb
	ld (l977fh),a		;97bd
	jp l975dh		;97c0
sub_97c3h:
	ld a,h			;97c3
	add a,020h		;97c4
	ld h,a			;97c6
	ld a,(l9b33h)		;97c7
	call sub_9abbh		;97ca
	ld a,h			;97cd
	sub 020h		;97ce
	ld h,a			;97d0
	ret			;97d1
sub_97d2h:
	cp 080h		;97d2
	ret nc			;97d4
	cp 008h		;97d5
	jp z,sub_990fh		;97d7
	cp 009h		;97da
	jp z,l992ah		;97dc
	cp 00ah		;97df
	jp z,sub_9945h		;97e1
	cp 00dh		;97e4
	jp z,l9a01h		;97e6
	cp 00bh		;97e9
	jp z,l9955h		;97eb
	cp 016h		;97ee
	jp z,l9855h		;97f0
	cp 019h		;97f3
	jp z,l9855h		;97f5
	cp 01bh		;97f8
	jp z,l9895h		;97fa
	cp 020h		;97fd
	ret c			;97ff
l9800h:
	call sub_963dh		;9800
	ld a,(l9b2ah)		;9803
	and a			;9806
	jr nz,l982ah		;9807
	ld (l9b2bh),a		;9809
	ld (0977eh),a		;980c
	ld a,0b1h		;980f
	ld (l978fh),a		;9811
	ld (l97a9h),a		;9814
	ld a,0a3h		;9817
	ld (l978eh),a		;9819
	ld a,0afh		;981c
	ld (l97a2h),a		;981e
	ld hl,00000h		;9821
	ld (l97a2h+1),hl		;9824
	jp l992ah		;9827
l982ah:
	xor a			;982a
	ld (l9b2ah),a		;982b
	ld a,001h		;982e
	ld (l9b2bh),a		;9830
	xor a			;9833
	ld (l978eh),a		;9834
	ld a,0cdh		;9837
	ld (l97a2h),a		;9839
	ld hl,sub_9acch		;983c
	ld (l97a2h+1),hl		;983f
	ld a,(l9b29h)		;9842
	and a			;9845
	ret z			;9846
	ld a,0a1h		;9847
	ld (l978fh),a		;9849
	ld (l97a9h),a		;984c
	ld a,0ffh		;984f
	ld (0977eh),a		;9851
	ret			;9854
l9855h:
	ld a,001h		;9855
	ld (l9b2ah),a		;9857
	ld hl,(l9b5dh)		;985a
	inc hl			;985d
	ld a,(hl)			;985e
	cp 041h		;985f
	call z,sub_9883h		;9861
	cp 042h		;9864
	call z,sub_9886h		;9866
	cp 043h		;9869
	call z,sub_9889h		;986b
	cp 048h		;986e
	call z,sub_988ch		;9870
	cp 04bh		;9873
	call z,sub_988fh		;9875
	cp 02dh		;9878
	call z,sub_9892h		;987a
	ld (l9b5dh),hl		;987d
	jp l9800h		;9880
sub_9883h:
	ld a,03ch		;9883
	ret			;9885
sub_9886h:
	ld a,03dh		;9886
	ret			;9888
sub_9889h:
	ld a,03eh		;9889
	ret			;988b
sub_988ch:
	ld a,040h		;988c
	ret			;988e
sub_988fh:
	ld a,060h		;988f
	ret			;9891
sub_9892h:
	ld a,02ah		;9892
	ret			;9894
l9895h:
	ld ix,l9b61h		;9895
	inc hl			;9899
	ld a,(hl)			;989a
	ld (l9b5dh),hl		;989b
	sub 040h		;989e
	add a,a			;98a0
	ld (098aah),a		;98a1
	inc a			;98a4
	ld (098adh),a		;98a5
	ld l,(ix+000h)		;98a8
	ld h,(ix+000h)		;98ab
	jp (hl)			;98ae

; BLOCK 'datos3' (start 0x98af end 0x98f0)
	defs 16,RELLENO	;98af
	defs 16,RELLENO	;98bf
	defs 16,RELLENO	;98cf
	defs 16,RELLENO	;98df
	defs 1,RELLENO	;98ef

; BLOCK 'codigo4' (start 0x98f0 end 0x98fd)
l98f0h:
	ld a,(l9b33h)		;98f0
	ld (l9b34h),a		;98f3
	and 00fh		;98f6
	ld b,070h		;98f8
	jp l990ah		;98fa

; BLOCK 'datos5' (start 0x98fd end 0x990a)
	defs 13,RELLENO	;98fd

; BLOCK 'codigo6' (start 0x990a end 0x9a08)
l990ah:
	or b			;990a
	ld (l9b33h),a		;990b
	ret			;990e
sub_990fh:
	ld hl,l9b30h		;990f
	ld a,(l9b2ch)		;9912
l9915h:
	nop			;9915
	cp (hl)			;9916
	jr z,l9922h		;9917
	dec (hl)			;9919
	ld a,(l9b28h)		;991a
	cp 002h		;991d
	ret c			;991f
	dec (hl)			;9920
	ret			;9921
l9922h:
	call l9955h		;9922
	ld a,(l9b2eh)		;9925
	ld (hl),a			;9928
	ret			;9929
l992ah:
	ld hl,l9b30h		;992a
	ld a,(l9b2eh)		;992d
l9930h:
	nop			;9930
	cp (hl)			;9931
	jp z,l993eh		;9932
	inc (hl)			;9935
	ld a,(l9b28h)		;9936
	cp 002h		;9939
	ret c			;993b
	inc (hl)			;993c
	ret			;993d
l993eh:
	call sub_9945h		;993e
	call l9a01h		;9941
	ret			;9944
sub_9945h:
	ld hl,l9b31h		;9945
	ld a,(l9b2fh)		;9948
	cp (hl)			;994b
	jr z,l9950h		;994c
	inc (hl)			;994e
	ret			;994f
l9950h:
	ld a,(l9b2dh)		;9950
	ld (hl),a			;9953
	ret			;9954
l9955h:
	ld hl,l9b31h		;9955
	ld a,(l9b2dh)		;9958
	cp (hl)			;995b
	jr z,l9960h		;995c
	dec (hl)			;995e
	ret			;995f
l9960h:
	ld a,(l9b2fh)		;9960
	ld (hl),a			;9963
	ret			;9964
sub_9965h:
	ld a,(l9b33h)		;9965
	push af			;9968
	ld b,040h		;9969
	ld a,(l9b32h)		;996b
	and 00fh		;996e
	or b			;9970
	ld (l9b33h),a		;9971
	ld hl,l9ba5h		;9974
	ld (09b0ch),hl		;9977
	ld hl,(l9b2ch)		;997a
	call l9aadh		;997d
	ld (l9b24h),hl		;9980
	ld a,h			;9983
	ld (l9b27h),a		;9984
	ld hl,(l9b2eh)		;9987
	call l9aadh		;998a
	add a,005h		;998d
	ld (l9b26h),a		;998f
	ld a,h			;9992
	add a,007h		;9993
	ld (l9b45h),a		;9995
l9998h:
	ld hl,l9b24h		;9998
	ld a,(hl)			;999b
	inc hl			;999c
	ld e,(hl)			;999d
	call sub_9af4h		;999e
	push hl			;99a1
	ld d,b			;99a2
	ld hl,l9b26h		;99a3
	ld a,(hl)			;99a6
	inc hl			;99a7
	ld e,(hl)			;99a8
	call sub_9af4h		;99a9
	ld a,b			;99ac
	ld (l9b3dh),a		;99ad
	ld b,d			;99b0
	ex de,hl			;99b1
	pop hl			;99b2
	ld c,0ffh		;99b3
l99b5h:
	sla c		;99b5
	srl b		;99b7
	jr nc,l99b5h		;99b9
	call sub_9acch		;99bb
	and c			;99be
l99bfh:
	call sub_9abbh		;99bf
	call sub_97c3h		;99c2
	ld c,008h		;99c5
	add hl,bc			;99c7
	call sub_9b12h		;99c8
	ld a,000h		;99cb
	jr c,l99bfh		;99cd
	ld a,(l9b3dh)		;99cf
	ld d,0ffh		;99d2
l99d4h:
	srl d		;99d4
	rla			;99d6
	jr nc,l99d4h		;99d7
	call sub_9acch		;99d9
	and d			;99dc
	call sub_9abbh		;99dd
	call sub_97c3h		;99e0
	ld hl,l9b25h		;99e3
	inc (hl)			;99e6
	inc hl			;99e7
	inc hl			;99e8
	inc (hl)			;99e9
	ld a,(l9b45h)		;99ea
	cp (hl)			;99ed
	jr nc,l9998h		;99ee
	ld hl,l9b9dh		;99f0
	ld (09b0ch),hl		;99f3
	pop af			;99f6
	ld (l9b33h),a		;99f7
	call l9a55h		;99fa
	call l9a1dh		;99fd
	ret			;9a00
l9a01h:
	ld a,(l9b2ch)		;9a01
	ld (l9b30h),a		;9a04
	ret			;9a07

; BLOCK 'datos7' (start 0x9a08 end 0x9a1d)
	defs 16,RELLENO	;9a08
	defs 5,RELLENO	;9a18

; BLOCK 'codigo8' (start 0x9a1d end 0x9a28)
l9a1dh:
	xor a			;9a1d
	ld (l9b28h),a		;9a1e
	ld (l9915h),a		;9a21
	ld (l9930h),a		;9a24
	ret			;9a27

; BLOCK 'datos9' (start 0x9a28 end 0x9a55)
	defs 16,RELLENO	;9a28
	defs 16,RELLENO	;9a38
	defs 13,RELLENO	;9a48

; BLOCK 'codigo10' (start 0x9a55 end 0x9a62)
l9a55h:
	ld a,(l9b2dh)		;9a55
	ld (l9b31h),a		;9a58
	ld a,(l9b2ch)		;9a5b
	ld (l9b30h),a		;9a5e
	ret			;9a61

; BLOCK 'datos11' (start 0x9a62 end 0x9a63)
	defs 1,RELLENO	;9a62

; BLOCK 'codigo12' (start 0x9a63 end 0x9a95)
l9a63h:
imprime:
	ld hl,(l9b5dh)		;9a63
	ld a,(hl)			;9a66
	cp 01fh		;9a67
	jr z,l9a80h		;9a69
	cp 07fh		;9a6b
	jr z,l9a7bh		;9a6d
	call sub_97d2h		;9a6f
	ld hl,(l9b5dh)		;9a72
	inc hl			;9a75
	ld (l9b5dh),hl		;9a76
	jr l9a63h		;9a79
l9a7bh:
	inc hl			;9a7b
	ld (l9b5dh),hl		;9a7c
	ret			;9a7f
l9a80h:
	inc hl			;9a80
	ld a,(hl)			;9a81
	sub 040h		;9a82
	ld (l9b31h),a		;9a84
	inc hl			;9a87
	ld a,(hl)			;9a88
	sub 040h		;9a89
	ld (l9b30h),a		;9a8b
	inc hl			;9a8e
	ld (l9b5dh),hl		;9a8f
	jp l9a63h		;9a92

; BLOCK 'datos13' (start 0x9a95 end 0x9aad)
	defs 16,RELLENO	;9a95
	defs 8,RELLENO	;9aa5

; BLOCK 'codigo14' (start 0x9aad end 0x9b24)
l9aadh:
	sla h		;9aad
	sla h		;9aaf
	sla h		;9ab1
	ld a,l			;9ab3
	add a,a			;9ab4
	add a,l			;9ab5
	add a,a			;9ab6
	add a,00ah		;9ab7
	ld l,a			;9ab9
	ret			;9aba
sub_9abbh:
	push af			;9abb
	ld a,l			;9abc
	di			;9abd
	out (099h),a		;9abe
	ld a,h			;9ac0
	and 03fh		;9ac1
	or 040h		;9ac3
	out (099h),a		;9ac5
	pop af			;9ac7
	out (098h),a		;9ac8
	ei			;9aca
	ret			;9acb
sub_9acch:
	ld a,l			;9acc
	di			;9acd
	out (099h),a		;9ace
	ld a,h			;9ad0
	and 03fh		;9ad1
	out (099h),a		;9ad3
	sla a		;9ad5
	sla a		;9ad7
	in a,(098h)		;9ad9
	ei			;9adb
	ret			;9adc
sub_9addh:
	ex de,hl			;9add
	ld a,l			;9ade
	di			;9adf
	out (099h),a		;9ae0
	ld a,h			;9ae2
	and 03fh		;9ae3
	or 040h		;9ae5
	out (099h),a		;9ae7
	ei			;9ae9
l9aeah:
	ld a,(de)			;9aea
	out (098h),a		;9aeb
	inc de			;9aed
	dec bc			;9aee
	ld a,c			;9aef
	or b			;9af0
	jr nz,l9aeah		;9af1
	ret			;9af3
sub_9af4h:
	ld c,a			;9af4
	ld h,e			;9af5
	srl h		;9af6
	srl h		;9af8
	srl h		;9afa
	and 0f8h		;9afc
	ld l,a			;9afe
	ld a,e			;9aff
	and 007h		;9b00
	or l			;9b02
	ld l,a			;9b03
	ld a,c			;9b04
	and 007h		;9b05
	ld (09b10h),a		;9b07
	ld iy,l9b9dh		;9b0a
	ld b,(iy+000h)		;9b0e
	ret			;9b11
sub_9b12h:
	ld a,h			;9b12
	sub d			;9b13
	ret nz			;9b14
	ld a,l			;9b15
	sub e			;9b16
	ret			;9b17
bios:
	push iy		;9b18
	ld iy,00000h		;9b1a
	call 08000h		;9b1e
	pop iy		;9b21
	ret			;9b23

; BLOCK 'datos15' (start 0x9b24 end 0xa100)
l9b24h:
	defs 1,RELLENO	;9b24
l9b25h:
	defs 1,RELLENO	;9b25
l9b26h:
	defs 1,RELLENO	;9b26
l9b27h:
	defs 1,RELLENO	;9b27
l9b28h:
	defs 1,RELLENO	;9b28
l9b29h:
	defs 1,RELLENO	;9b29
l9b2ah:
	defs 1,RELLENO	;9b2a
l9b2bh:
	defs 1,RELLENO	;9b2b
l9b2ch:
	defs 1,RELLENO	;9b2c
l9b2dh:
	defs 1,RELLENO	;9b2d
l9b2eh:
	defs 1,RELLENO	;9b2e
l9b2fh:
	defs 1,RELLENO	;9b2f
l9b30h:
	defs 1,RELLENO	;9b30
l9b31h:
	defs 1,RELLENO	;9b31
l9b32h:
	defs 1,RELLENO	;9b32
l9b33h:
	defs 1,RELLENO	;9b33
l9b34h:
	defs 9,RELLENO	;9b34
l9b3dh:
	defs 8,RELLENO	;9b3d
l9b45h:
	defs 8,RELLENO	;9b45
l9b4dh:
	defs 8,RELLENO	;9b4d
l9b55h:
	defs 8,RELLENO	;9b55
l9b5dh:
	defs 4,RELLENO	;9b5d
l9b61h:
	defs 16,RELLENO	;9b61
	defs 16,RELLENO	;9b71
	defs 16,RELLENO	;9b81
	defs 12,RELLENO	;9b91
l9b9dh:
	defs 8,RELLENO	;9b9d
l9ba5h:
	defs 8,RELLENO	;9ba5
l9badh:
	defs 1,RELLENO	;9bad
l9baeh:
	defs 1,RELLENO	;9bae
l9bafh:
	defs 1,RELLENO	;9baf
l9bb0h:
	defs 8,RELLENO	;9bb0
l9bb8h:
	defs 1,RELLENO	;9bb8
l9bb9h:
	defs 2,RELLENO	;9bb9
l9bbbh:
	defs 16,RELLENO	;9bbb
l9bcbh:
	defs 1,RELLENO	;9bcb
l9bcch:
	defs 3,RELLENO	;9bcc
l9bcfh:
	defs 4,RELLENO	;9bcf
l9bd3h:
	defs 16,RELLENO	;9bd3
	defs 16,RELLENO	;9be3
	defs 16,RELLENO	;9bf3
	defs 16,RELLENO	;9c03
	defs 16,RELLENO	;9c13
	defs 16,RELLENO	;9c23
	defs 16,RELLENO	;9c33
	defs 8,RELLENO	;9c43
l9c4bh:
	defs 16,RELLENO	;9c4b
	defs 16,RELLENO	;9c5b
	defs 16,RELLENO	;9c6b
	defs 16,RELLENO	;9c7b
	defs 16,RELLENO	;9c8b
	defs 16,RELLENO	;9c9b
	defs 16,RELLENO	;9cab
	defs 16,RELLENO	;9cbb
	defs 16,RELLENO	;9ccb
	defs 16,RELLENO	;9cdb
	defs 16,RELLENO	;9ceb
	defs 16,RELLENO	;9cfb
	defs 16,RELLENO	;9d0b
	defs 16,RELLENO	;9d1b
	defs 16,RELLENO	;9d2b
	defs 16,RELLENO	;9d3b
	defs 5,RELLENO	;9d4b
l9d50h:
	defs 16,RELLENO	;9d50
	defs 16,RELLENO	;9d60
	defs 15,RELLENO	;9d70
l9d7fh:
	defs 16,RELLENO	;9d7f
	defs 16,RELLENO	;9d8f
	defs 15,RELLENO	;9d9f
l9daeh:
	defs 3,RELLENO	;9dae
l9db1h:
	defs 12,RELLENO	;9db1
l9dbdh:
	defs 4,RELLENO	;9dbd
l9dc1h:
	defs 4,RELLENO	;9dc1
l9dc5h:
	defs 4,RELLENO	;9dc5
l9dc9h:
	defs 4,RELLENO	;9dc9
l9dcdh:
	defs 4,RELLENO	;9dcd
l9dd1h:
	defs 4,RELLENO	;9dd1
l9dd5h:
	defs 4,RELLENO	;9dd5
l9dd9h:
	defs 16,RELLENO	;9dd9
	defs 16,RELLENO	;9de9
	defs 16,RELLENO	;9df9
	defs 16,RELLENO	;9e09
	defs 16,RELLENO	;9e19
	defs 16,RELLENO	;9e29
	defs 16,RELLENO	;9e39
	defs 16,RELLENO	;9e49
	defs 16,RELLENO	;9e59
	defs 16,RELLENO	;9e69
	defs 16,RELLENO	;9e79
	defs 16,RELLENO	;9e89
	defs 2,RELLENO	;9e99
l9e9bh:
	defs 16,RELLENO	;9e9b
	defs 16,RELLENO	;9eab
	defs 16,RELLENO	;9ebb
	defs 16,RELLENO	;9ecb
	defs 16,RELLENO	;9edb
	defs 11,RELLENO	;9eeb
l9ef6h:
	defs 8,RELLENO	;9ef6
l9efeh:
	defs 8,RELLENO	;9efe
l9f06h:
	defs 8,RELLENO	;9f06
l9f0eh:
	defs 8,RELLENO	;9f0e
l9f16h:
	defs 8,RELLENO	;9f16
l9f1eh:
	defs 16,RELLENO	;9f1e
	defs 16,RELLENO	;9f2e
	defs 16,RELLENO	;9f3e
	defs 16,RELLENO	;9f4e
	defs 16,RELLENO	;9f5e
	defs 16,RELLENO	;9f6e
	defs 16,RELLENO	;9f7e
	defs 16,RELLENO	;9f8e
	defs 16,RELLENO	;9f9e
	defs 16,RELLENO	;9fae
	defs 16,RELLENO	;9fbe
	defs 16,RELLENO	;9fce
	defs 16,RELLENO	;9fde
	defs 16,RELLENO	;9fee
	defs 16,RELLENO	;9ffe
	defs 16,RELLENO	;a00e
	defs 16,RELLENO	;a01e
	defs 16,RELLENO	;a02e
	defs 16,RELLENO	;a03e
	defs 16,RELLENO	;a04e
	defs 16,RELLENO	;a05e
	defs 16,RELLENO	;a06e
	defs 16,RELLENO	;a07e
	defs 16,RELLENO	;a08e
	defs 16,RELLENO	;a09e
	defs 16,RELLENO	;a0ae
	defs 16,RELLENO	;a0be
	defs 16,RELLENO	;a0ce
	defs 16,RELLENO	;a0de
	defs 16,RELLENO	;a0ee
	defs 2,RELLENO	;a0fe

; BLOCK 'codigo16' (start 0xa100 end 0xa13a)
la100h:
	ld hl,la200h		;a100
	ld (la1fbh),hl		;a103
	ld hl,00001h		;a106
	ld (la1fdh),hl		;a109
	ld a,007h		;a10c
	ld e,038h		;a10e
	call la1c0h		;a110
	ld a,008h		;a113
	ld e,00fh		;a115
	call la1c0h		;a117
	ld a,009h		;a11a
	ld e,00bh		;a11c
	call la1c0h		;a11e
	ld a,00ah		;a121
	ld e,00bh		;a123
	call la1c0h		;a125
	xor a			;a128
	ld (la1c8h),a		;a129
	di			;a12c
	ld hl,la13ah		;a12d
	ld (0fd9bh),hl		;a130
	ld a,0c3h		;a133
	ld (0fd9ah),a		;a135
	ei			;a138
	ret			;a139

; BLOCK 'datos17' (start 0xa13a end 0xa1c0)
la13ah:
	defs 16,RELLENO	;a13a
	defs 16,RELLENO	;a14a
	defs 16,RELLENO	;a15a
	defs 16,RELLENO	;a16a
	defs 16,RELLENO	;a17a
	defs 16,RELLENO	;a18a
	defs 16,RELLENO	;a19a
	defs 16,RELLENO	;a1aa
	defs 6,RELLENO	;a1ba

; BLOCK 'codigo18' (start 0xa1c0 end 0xa1c8)
la1c0h:
	out (0a0h),a		;a1c0
	push af			;a1c2
	ld a,e			;a1c3
	out (0a1h),a		;a1c4
	pop af			;a1c6
	ret			;a1c7

; BLOCK 'datos19' (start 0xa1c8 end 0xac30)
la1c8h:
	defs 16,RELLENO	;a1c8
	defs 16,RELLENO	;a1d8
	defs 16,RELLENO	;a1e8
	defs 3,RELLENO	;a1f8
la1fbh:
	defs 2,RELLENO	;a1fb
la1fdh:
	defs 3,RELLENO	;a1fd
la200h:
	defs 16,RELLENO	;a200
	defs 16,RELLENO	;a210
	defs 16,RELLENO	;a220
	defs 16,RELLENO	;a230
	defs 16,RELLENO	;a240
	defs 16,RELLENO	;a250
	defs 16,RELLENO	;a260
	defs 16,RELLENO	;a270
	defs 16,RELLENO	;a280
	defs 16,RELLENO	;a290
	defs 16,RELLENO	;a2a0
	defs 16,RELLENO	;a2b0
	defs 16,RELLENO	;a2c0
	defs 16,RELLENO	;a2d0
	defs 16,RELLENO	;a2e0
	defs 16,RELLENO	;a2f0
	defs 16,RELLENO	;a300
	defs 16,RELLENO	;a310
	defs 16,RELLENO	;a320
	defs 16,RELLENO	;a330
	defs 16,RELLENO	;a340
	defs 16,RELLENO	;a350
	defs 16,RELLENO	;a360
	defs 16,RELLENO	;a370
	defs 16,RELLENO	;a380
	defs 16,RELLENO	;a390
	defs 16,RELLENO	;a3a0
	defs 16,RELLENO	;a3b0
	defs 16,RELLENO	;a3c0
	defs 16,RELLENO	;a3d0
	defs 16,RELLENO	;a3e0
	defs 16,RELLENO	;a3f0
	defs 16,RELLENO	;a400
	defs 16,RELLENO	;a410
	defs 16,RELLENO	;a420
	defs 16,RELLENO	;a430
	defs 16,RELLENO	;a440
	defs 16,RELLENO	;a450
	defs 16,RELLENO	;a460
	defs 16,RELLENO	;a470
	defs 16,RELLENO	;a480
	defs 16,RELLENO	;a490
	defs 16,RELLENO	;a4a0
	defs 16,RELLENO	;a4b0
	defs 16,RELLENO	;a4c0
	defs 16,RELLENO	;a4d0
	defs 16,RELLENO	;a4e0
	defs 16,RELLENO	;a4f0
	defs 16,RELLENO	;a500
	defs 16,RELLENO	;a510
	defs 16,RELLENO	;a520
	defs 16,RELLENO	;a530
	defs 16,RELLENO	;a540
	defs 16,RELLENO	;a550
	defs 16,RELLENO	;a560
	defs 16,RELLENO	;a570
	defs 16,RELLENO	;a580
	defs 16,RELLENO	;a590
	defs 16,RELLENO	;a5a0
	defs 16,RELLENO	;a5b0
	defs 16,RELLENO	;a5c0
	defs 16,RELLENO	;a5d0
	defs 16,RELLENO	;a5e0
	defs 16,RELLENO	;a5f0
	defs 16,RELLENO	;a600
	defs 16,RELLENO	;a610
	defs 16,RELLENO	;a620
	defs 16,RELLENO	;a630
	defs 16,RELLENO	;a640
	defs 16,RELLENO	;a650
	defs 16,RELLENO	;a660
	defs 16,RELLENO	;a670
	defs 16,RELLENO	;a680
	defs 16,RELLENO	;a690
	defs 16,RELLENO	;a6a0
	defs 16,RELLENO	;a6b0
	defs 16,RELLENO	;a6c0
	defs 16,RELLENO	;a6d0
	defs 16,RELLENO	;a6e0
	defs 16,RELLENO	;a6f0
	defs 16,RELLENO	;a700
	defs 16,RELLENO	;a710
	defs 16,RELLENO	;a720
	defs 16,RELLENO	;a730
	defs 16,RELLENO	;a740
	defs 16,RELLENO	;a750
	defs 16,RELLENO	;a760
	defs 16,RELLENO	;a770
	defs 16,RELLENO	;a780
	defs 16,RELLENO	;a790
	defs 16,RELLENO	;a7a0
	defs 16,RELLENO	;a7b0
	defs 16,RELLENO	;a7c0
	defs 16,RELLENO	;a7d0
	defs 16,RELLENO	;a7e0
	defs 16,RELLENO	;a7f0
	defs 16,RELLENO	;a800
	defs 16,RELLENO	;a810
	defs 16,RELLENO	;a820
	defs 16,RELLENO	;a830
	defs 16,RELLENO	;a840
	defs 16,RELLENO	;a850
	defs 16,RELLENO	;a860
	defs 16,RELLENO	;a870
	defs 16,RELLENO	;a880
	defs 16,RELLENO	;a890
	defs 16,RELLENO	;a8a0
	defs 16,RELLENO	;a8b0
	defs 16,RELLENO	;a8c0
	defs 16,RELLENO	;a8d0
	defs 16,RELLENO	;a8e0
	defs 16,RELLENO	;a8f0
	defs 16,RELLENO	;a900
	defs 16,RELLENO	;a910
	defs 16,RELLENO	;a920
	defs 16,RELLENO	;a930
	defs 16,RELLENO	;a940
	defs 16,RELLENO	;a950
	defs 16,RELLENO	;a960
	defs 16,RELLENO	;a970
	defs 16,RELLENO	;a980
	defs 16,RELLENO	;a990
	defs 16,RELLENO	;a9a0
	defs 16,RELLENO	;a9b0
	defs 16,RELLENO	;a9c0
	defs 16,RELLENO	;a9d0
	defs 16,RELLENO	;a9e0
	defs 16,RELLENO	;a9f0
	defs 16,RELLENO	;aa00
	defs 16,RELLENO	;aa10
	defs 16,RELLENO	;aa20
	defs 16,RELLENO	;aa30
	defs 16,RELLENO	;aa40
	defs 16,RELLENO	;aa50
	defs 16,RELLENO	;aa60
	defs 16,RELLENO	;aa70
	defs 16,RELLENO	;aa80
	defs 16,RELLENO	;aa90
	defs 16,RELLENO	;aaa0
	defs 16,RELLENO	;aab0
	defs 16,RELLENO	;aac0
	defs 16,RELLENO	;aad0
	defs 16,RELLENO	;aae0
	defs 16,RELLENO	;aaf0
	defs 16,RELLENO	;ab00
	defs 16,RELLENO	;ab10
	defs 16,RELLENO	;ab20
	defs 16,RELLENO	;ab30
	defs 16,RELLENO	;ab40
	defs 16,RELLENO	;ab50
	defs 16,RELLENO	;ab60
	defs 16,RELLENO	;ab70
	defs 16,RELLENO	;ab80
	defs 16,RELLENO	;ab90
	defs 16,RELLENO	;aba0
	defs 16,RELLENO	;abb0
	defs 16,RELLENO	;abc0
	defs 16,RELLENO	;abd0
	defs 16,RELLENO	;abe0
	defs 16,RELLENO	;abf0
	defs 16,RELLENO	;ac00
	defs 16,RELLENO	;ac10
	defs 16,RELLENO	;ac20


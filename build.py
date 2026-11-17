#!/usr/bin/env python3
"""La Geste d'Artillac (Infogrames 1985) en castellano: monta la MegaROM ASCII16 de 256 KB.

  python3 build.py

1. Si falta datos/, saca de las cintas originales (originales/*.cas) lo que el repositorio no
   lleva: los programas de la cinta 1, las dos pantallas y los cantos (tools/extrae_originales.py).
2. Ensambla src/etapa2.asm, src/creacion.asm y src/motor.asm (desensamblado sin datos: cada
   «defs n,RELLENO» se rellena con los bytes de la cinta) y comprueba que salen idénticos al original.
3. Monta la traducción de traduccion/:
     motor_es.txt, creacion_es.txt   textos del motor y de la creación (tools/motor_textos.py)
     Cnn_es.txt                      cantos traducidos (tools/canto.py)
   añade ñ ¿ ¡ a las dos fuentes, cambia la tecla (O)ui por (S)í, recalcula la tabla de cantos
   del motor (AF7Dh) y la longitud del motor en la etapa 2, y escribe salida/GesteArtillac_ES.rom.
Ensamblador: sjasmplus o, si no está, pasmo.
"""
import os,sys,struct,subprocess,shutil,hashlib
R=os.path.dirname(os.path.abspath(__file__)); H=os.path.join(R,'tools'); sys.path.insert(0,H)
import canto,motor_textos,huecos,extrae_originales
T=os.path.join(R,'traduccion'); SES=os.path.join(R,'salida','src_es'); SAL=os.path.join(R,'salida'); D=os.path.join(R,'datos'); RO=os.path.join(R,'rom')
os.makedirs(SES,exist_ok=True)
rd=lambda f: open(f,'rb').read()
def asm(f,o,cwd): return huecos.ensambla_simple(f,o,cwd)
os.makedirs(SAL,exist_ok=True)

# ---- 1. datos originales desde las cintas del usuario ----
if not all(os.path.exists(os.path.join(D,f)) for f in list(extrae_originales.P1)+['C%02d.bin'%n for n in extrae_originales.CANTOS]):
    extrae_originales.extrae()

# ---- 2. el original, reensamblado desde src/ y comprobado ----
HUECOS={}
for nom in ('etapa2','creacion','motor'):
    b,h=huecos.ensambla(nom+'.asm',os.path.join(R,'src')); orig=rd(os.path.join(D,'orig_%s.bin'%nom))
    huecos.rellena(b,h,orig); HUECOS[nom]=h
    assert b==orig, 'src/%s.asm no reensambla idéntico al original'%nom
    open(os.path.join(SAL,nom+'.bin'),'wb').write(b)
print('Original reensamblado idéntico (etapa 2, creación y motor).')
def asm_es(nom,asmf):
    b,h=huecos.ensambla(asmf,SES); z=motor_textos.BLOQUES[nom]
    return huecos.rellena(b,h,rd(os.path.join(D,'orig_%s.bin'%nom)),HUECOS[nom],(z[1]-0x9000,z[2]-0x9000))

# ---- glifos nuevos (8x8, se ven 6 columnas), en el estilo de la fuente del juego ----
GLIFOS={0x23:[0x20,0x00,0x20,0x40,0x80,0x88,0x70,0x00],   # ¿  (el ? del juego invertido)
        0x24:[0x68,0xB0,0x00,0x00,0x00,0x00,0x00,0x00],   # ~  tilde para la ñ (16h 24h n)
        0x26:[0x10,0x00,0x10,0x10,0x10,0x10,0x10,0x00]}   # ¡  (el ! del juego invertido)
def pon_glifos(b,base_fuente,org=0x9000):
    for c,g in GLIFOS.items():
        a=base_fuente-org+8*c
        assert b[a:a+8]==bytes(8), 'el hueco del carácter %02Xh no está vacío'%c
        b[a:a+8]=bytes(g)

# ---- motor ----
motor_textos.bloque('motor'); motor_textos.monta(os.path.join(T,'motor_es.txt'),os.path.join(SES,'motor_es.asm'))
# brújula: N y S centrados sobre la flecha. Las letras de arriba y abajo usan copias de N S E O
# desplazadas a la derecha (5Bh-5Eh); al girar, cada letra cambia de copia (brujula_t)
BRU_DESP=int(os.environ.get('BRU_DESP','3'))
sm=open(os.path.join(SES,'motor_es.asm'),encoding='utf-8').read()
G0=sm.index('gira_brujula:\n'); G1=sm.index('\tld hl,lb01eh',G0)
v='gira_brujula:\n\tld hl,lb025h\t\t;9550\n'; assert sm[G0:G0+len(v)]==v
sm=sm[:G0]+'gira_brujula:\n\tjp brujula_gira\t\t;9550 (traducción: misma longitud)\n'+sm[G0+len(v):G1]+'gira_brujula_pinta:\n'+sm[G1:]
sm=sm.rstrip('\n')+"""
; --- traducción: brújula con N y S centradas ---
brujula_gira:
\tld hl,lb025h
\tld a,(hl)
\tcall brujula_t
\tld c,a
\tld hl,lb029h
\tld a,(hl)
\tcall brujula_t
\tld b,a
\tld (hl),c
\tld hl,lb02dh
\tld a,(hl)
\tcall brujula_t
\tld c,a
\tld (hl),b
\tld hl,lb031h
\tld a,(hl)
\tcall brujula_t
\tld b,a
\tld (hl),c
\tld hl,lb025h
\tld (hl),b
\tjp gira_brujula_pinta
brujula_t:\t\t; N S E O <-> sus copias desplazadas
\tpush hl
\tpush bc
\tld hl,brujula_tab
\tld b,8
brujula_t1:
\tcp (hl)
\tinc hl
\tjr z,brujula_t2
\tinc hl
\tdjnz brujula_t1
\tjr brujula_t3
brujula_t2:
\tld a,(hl)
brujula_t3:
\tpop bc
\tpop hl
\tret
brujula_tab:
\tdefb 4Eh,5Bh,53h,5Ch,45h,5Dh,4Fh,5Eh,5Bh,4Eh,5Ch,53h,5Dh,45h,5Eh,4Fh
"""
for a,b in (('\tdefb 53h,1Fh,53h,60h\t;b029','\tdefb 5Ch,1Fh,53h,60h\t;b029 (S desplazada)'),('\tdefb 4Eh,7Fh\t;b031','\tdefb 5Bh,7Fh\t;b031 (N desplazada)')):
    assert a in sm; sm=sm.replace(a,b)
open(os.path.join(SES,'motor_es.asm'),'w',encoding='utf-8').write(sm)
motor=asm_es('motor','motor_es.asm')
pon_glifos(motor,0xAB9D)
for c,d in zip(b'NSEO',range(0x5B,0x5F)):
    a=0xAB9D-0x9000; g=motor[a+8*c:a+8*c+8]; assert motor[a+8*d:a+8*d+8]==bytes(8)
    motor[a+8*d:a+8*d+8]=bytes(x>>BRU_DESP for x in g)
assert 0x9000+len(motor)<=0xE000, 'el motor pisa la hoja del personaje (E000h)'
# ---- creación (tamaño fijo) ----
motor_textos.bloque('creacion'); motor_textos.monta(os.path.join(T,'creacion_es.txt'),os.path.join(SES,'creacion_es.asm'))
src=open(os.path.join(SES,'creacion_es.asm'),encoding='utf-8').read()
for dir_ in ('90ae','92c2'):        # «En route : (O)ui - (N)on» -> «(S)í - (N)o»
    viejo='\tcp 04fh\t\t;%s'%dir_; assert viejo in src; src=src.replace(viejo,'\tcp 053h\t\t;%s (S de sí; el original, O de oui)'%dir_)
open(os.path.join(SES,'creacion_es.asm'),'w',encoding='utf-8').write(src)
creacion=asm_es('creacion','creacion_es.asm')
pon_glifos(creacion,0x920C)
assert len(creacion)==len(rd(os.path.join(SAL,'creacion.bin')))

# ---- cantos ----
cantos={}; tabla=[]
for n in range(1,12):
    if n==6: tabla.append((0,0,0,0)); continue
    f=os.path.join(T,'C%02d_es.txt'%n)
    if os.path.exists(f):
        _,d,t=canto.monta(f); cantos[n]=d; tabla.append(t); print('C%d: español, %d bytes'%(n,len(d)))
    else:
        cantos[n]=rd(os.path.join(D,'C%02d.bin'%n)); tabla.append(tuple(canto.tabla_motor(rd(os.path.join(SAL,'motor.bin')),n)))
for i,t in enumerate(tabla): motor[0xAF7D-0x9000+8*i:0xAF7D-0x9000+8*i+8]=struct.pack('<4H',*t)
open(os.path.join(SES,'motor_es.bin'),'wb').write(motor); open(os.path.join(SES,'creacion_es.bin'),'wb').write(creacion)

# ---- ROM ----
etapa2=bytearray(rd(os.path.join(SAL,'etapa2.bin')))
assert etapa2[0x65:0x68]==bytes([0x11,0xD0,0x2D]); etapa2[0x66:0x68]=struct.pack('<H',len(motor))
assert motor[0x803:0x805]==bytes([0x3e,0x02])
motor[0x803:0x80a]=bytes([0x3a,0xd5,0xaf,0xcd,0x03,0x84,0xc9])   # carga_canto -> lector de la ROM
flujo=bytearray()
for b in (rd(os.path.join(D,'pantalla_infogrames.rle')),rd(os.path.join(D,'pantalla_titulo.rle')),creacion,motor): flujo+=b
tc=[]
for n in range(1,12):
    if n==6: tc.append((0,0)); continue
    off=len(flujo); tc.append((1+off//16384,0x4000+off%16384)); flujo+=cantos[n]
tam=262144 if len(flujo)<=262144-16384 else 524288
assert len(flujo)<=tam-16384
B=os.path.join(SES,'rom'); os.makedirs(B,exist_ok=True)
for f in ('arranque.asm','lector.asm'): shutil.copy(os.path.join(RO,f),B)
lec=asm('lector.asm','lector.bin',B)
HOOK=0x8400+0x100+4*11       # musica_hook va justo detrás de TABLA_CANTOS
assert lec[HOOK-0x8400:HOOK-0x8400+3]==bytes([0x21,0x8C,0x83])
fl=bytearray(flujo); oc=len(rd(os.path.join(D,'pantalla_infogrames.rle')))+len(rd(os.path.join(D,'pantalla_titulo.rle')))+0x112D
assert fl[oc:oc+3]==bytes([0x21,0x3A,0xA1]); fl[oc+1:oc+3]=struct.pack('<H',HOOK); flujo=fl   # H.KEYI -> musica_hook
for i,(b,a) in enumerate(tc): lec[0x100+4*i:0x104+4*i]=bytes([b,a&255,a>>8,0])
open(os.path.join(B,'lector.bin'),'wb').write(lec); open(os.path.join(B,'etapa2.bin'),'wb').write(etapa2)
arr=asm('arranque.asm','arranque.bin',B)
rom=bytearray(b'\xff'*tam); rom[:len(arr)]=arr; rom[16384:16384+len(flujo)]=flujo
out=os.path.join(SAL,'GesteArtillac_ES.rom'); open(out,'wb').write(rom)
print('ROM %s: %d KB, motor %d bytes (hasta %04Xh), flujo %d (libres %d), sha1 %s'%(out,tam//1024,len(motor),0x9000+len(motor)-1,len(flujo),tam-16384-len(flujo),hashlib.sha1(rom).hexdigest()))
REL=os.path.join(R,'releases','GesteArtillac_ES_v1.0.rom')
if os.path.exists(REL): print('Igual que releases/GesteArtillac_ES_v1.0.rom' if rd(REL)==bytes(rom) else '¡DISTINTA de releases/GesteArtillac_ES_v1.0.rom!')

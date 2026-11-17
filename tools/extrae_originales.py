#!/usr/bin/env python3
"""Saca de las cintas originales del usuario (originales/*.cas) los datos que el repositorio
no lleva: los tres programas de la cinta 1 (descifrados), las dos pantallas y los cantos.
Cada pieza se comprueba por su SHA-1. Uso: python3 tools/extrae_originales.py"""
import os,sys,glob,hashlib
R=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
O=os.path.join(R,'originales'); D=os.path.join(R,'datos')
CASH=bytes([0x1F,0xA6,0xDE,0xBA,0xCC,0x13,0x7D,0x74])
# pieza: (cinta, bloque tras la cabecera, desplazamiento, longitud, XOR 76h, SHA-1)
P1={'orig_etapa2.bin':(1,714,'354248c705aade046acf90ed99561bbb8277ddb3'),
    'pantalla_infogrames.rle':(2,1942,'b7b2a06162fa81f6a1bc88eee08fbe177c7d3eb8'),
    'pantalla_titulo.rle':(3,7194,'dc536f9d5aee6aba574de74c30afd32d929a739a'),
    'orig_creacion.bin':(4,7216,'0dc80705947da3ed2cca131b9cc14b15c36e8b76'),
    'orig_motor.bin':(5,11728,'6dd903caadb1a1b48a71deb3c0f0663682dc1270')}
CANTOS={1:(23920,'a821e4bf0585ef53c6290e40cb4b5bc9ff794705'),2:(19216,'7aec06279c783b09250cc8b1c3a9acf4abb358a4'),
        3:(22776,'5586840db521913ebb0584fbdf377c84b2bd1020'),4:(23962,'f04fd79081ae01ed638e1650f3248a3fd752aa7b'),
        5:(17088,'db6ad7a60d509ea8973983ad1511153f49f6cce8'),7:(15384,'93a46d65287665d5ad91d731e487b685139e8510'),
        8:(19464,'71a1140530ff4a656e36cf8854479bde8d0f1a0d'),9:(21440,'6b84bb1cf6af75551f570b2e9f7f1af2f869f6ac'),
        10:(24136,'3f41a76e758d37748d2ccaafef19225d52c282ce'),11:(23496,'b16d3052bf31eca3e02e91656604a54fbaaa6011')}
def bloques(d):
    pos=[i for i in range(0,len(d)-7,8) if d[i:i+8]==CASH]
    return [d[a+8:b] for a,b in zip(pos,pos[1:]+[len(d)])]
def nombre(b): return b[10:16].decode('latin-1').strip() if len(b)>=16 and b[:10]==bytes([0xD0]*10) else None
def extrae():
    cintas=sorted(glob.glob(os.path.join(O,'*.cas'))+glob.glob(os.path.join(O,'*.CAS')))
    if not cintas: sys.exit('Pon en originales/ las cintas .cas de La Geste d\'Artillac (ver originales/LEEME.md).')
    por_nombre={}
    for f in cintas:
        bl=bloques(open(f,'rb').read())
        for i,b in enumerate(bl):
            n=nombre(b)
            if n and i+1<len(bl): por_nombre[n]=bl[i+1:]
    os.makedirs(D,exist_ok=True); falta=[]
    def guarda(f,d,sha):
        if hashlib.sha1(d).hexdigest()!=sha: falta.append(f); return
        open(os.path.join(D,f),'wb').write(d)
    t1=por_nombre.get('ART')
    for f,(k,n,sha) in P1.items():
        if not t1 or len(t1)<=k: falta.append(f); continue
        guarda(f,bytes(x^0x76 for x in t1[k][:n]),sha)
    for c,(n,sha) in CANTOS.items():
        b=por_nombre.get('C%d'%c)
        if not b: falta.append('C%02d.bin'%c); continue
        guarda('C%02d.bin'%c,b[0][:n],sha)
    if falta: sys.exit('No encuentro o no coinciden (SHA-1): '+', '.join(falta)+'.\nHacen falta las cintas de la versión francesa (ver originales/LEEME.md).')
    print('Datos originales extraídos en datos/: %d piezas comprobadas.'%(len(P1)+len(CANTOS)))
if __name__=='__main__': extrae()

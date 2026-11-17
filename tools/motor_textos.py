#!/usr/bin/env python3
"""Textos del motor (9000h-BDCFh) de La Geste d'Artillac en un fichero editable.

  motor_textos.py motor|creacion exporta salida.txt         -> textos de B033h-BB88h tal como están (francés)
  motor_textos.py motor|creacion monta textos.txt asm_dest  -> escribe salida/src_es/motor_es.asm: copia de src/motor.asm
                                                con esa zona sustituida por los textos del fichero
                                                (las etiquetas se recolocan solas al ensamblar)

Formato: «== etiqueta» abre una entrada (las etiquetas son las del fuente: el código las usa).
Dentro, las cadenas van separadas por «--»; cada una acaba en 7Fh, salvo la última de una
entrada marcada «== etiqueta abierta» (sigue en la entrada siguiente, p. ej. el nombre de cinta).
Cada línea: «@fila,col texto» o texto que sigue; {xx}=1Bh xx, {#xx}=byte, '|' final guarda espacios.
"""
import os,sys,re
sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))
import canto
R=canto.R
# zona de textos de cada bloque: (fuente, binario, inicio, fin, etiquetas añadidas, ¿tamaño fijo?)
BLOQUES={'motor':('motor',0xB033,0xBB89,{0xB30D:'lb30dh',0xB32B:'lb32bh',0xB848:'lb848h',0xB87C:'lb87ch'},False),
         'creacion':('creacion',0x9BD3,0x9EF6,{},True)}   # la creación no se recoloca: rellena hasta su tamaño
def bloque(nombre):
    global INI,FIN,EXTRA,FIJO,SRC
    SRC,INI,FIN,EXTRA,FIJO=BLOQUES[nombre]
def etiquetas(asm):
    lab={}; pend=None
    for l in open(asm,encoding='utf-8'):
        m=re.match(r'^([A-Za-z_][\w]*):',l)
        if m: pend=m.group(1); continue
        m=re.search(r';([0-9a-f]{4})\s*$',l)
        if m and pend and l.strip().startswith('defb'): lab[int(m.group(1),16)]=pend; pend=None
        elif l.strip() and not l.strip().startswith(';'): pend=None if not l.strip().startswith('defb') else pend
    return lab
def exporta(dest):
    m=open(os.path.join(R,'salida',SRC+'.bin'),'rb').read(); lab=etiquetas(os.path.join(R,'src',SRC+'.asm'))
    lab.update(EXTRA)
    cortes=sorted(a for a in lab if INI<=a<FIN)+[FIN]
    L=['# Textos de %s de La Geste d\'Artillac (%04Xh-%04Xh). Formato: tools/motor_textos.py'%(SRC,INI,FIN-1),'']
    for a,b in zip(cortes,cortes[1:]):
        seg=m[a-0x9000:b-0x9000]; abierta=not seg.endswith(b'\x7f')
        L.append('== %s%s'%(lab[a],' abierta' if abierta else ''))
        d=seg+(b'\x7f' if abierta else b''); i=0; prim=True
        while i<len(d):
            ls,i=canto.cadena_a_lineas(d,i)
            if not prim: L.append('--')
            L+=ls if ls else []; prim=False
        L.append('')
    open(dest,'w',encoding='utf-8').write('\n'.join(L)+'\n')
def lee(f):
    E=[]
    for raw in open(f,encoding='utf-8').read().split('\n'):
        if raw.startswith('#'): continue
        if raw.startswith('== '):
            p=raw[3:].split(); E.append([p[0],'abierta' in p[1:],[[]]]); continue
        if raw.strip()=='': continue
        if raw.strip()=='--': E[-1][2].append([]); continue
        t=raw[:-1] if raw.endswith('|') else raw
        mm=re.match(r'^@(-?\d+),(-?\d+) ?(.*)$',t)
        E[-1][2][-1].append(((int(mm.group(1)),int(mm.group(2))),mm.group(3)) if mm else (None,t))
    return E
def bytes_entradas(f,err):
    out=[]
    for nom,abierta,cads in lee(f):
        d=b''.join(canto.cadena_bytes(c,err) for c in cads)
        if abierta: d=d[:-1]
        out.append((nom,d))
    return out
def monta(f,dest):
    err=[]; ent=bytes_entradas(f,err)
    if err: print('\n'.join(sorted(set(err)))); sys.exit(1)
    inc=['; --- textos generados por tools/motor_textos.py desde %s ---'%os.path.basename(f)]
    tam=sum(len(d) for _,d in ent)
    if FIJO:
        if tam>FIN-INI: print('¡Los textos de %s no caben! %d bytes de %d'%(SRC,tam,FIN-INI)); sys.exit(1)
        ent=ent[:-1]+[(ent[-1][0],ent[-1][1]+bytes(FIN-INI-tam))]
    for nom,d in ent:
        inc.append('%s:'%nom)
        for k in range(0,len(d),16): inc.append('\tdefb '+','.join('%03Xh'%x for x in d[k:k+16]))
    src=open(os.path.join(R,'src',SRC+'.asm'),encoding='utf-8').read().split('\n')
    i0=src.index(ent[0][0]+':'); i1=src.index('l%04xh:'%FIN)
    src=src[:i0]+inc+src[i1:]
    if SRC=='motor':
        j=src.index('tabla_mensajes:')
        assert src[j+1].strip().startswith('defb 0EDh,0B2h')
        src[j+1]='\tdefw lb2edh,lb30dh,lb32bh,lb7a9h,lb848h,lb87ch\t;a768 (en el original, punteros fijos)'
    os.makedirs(os.path.dirname(dest),exist_ok=True)
    open(dest,'w',encoding='utf-8').write('\n'.join(src))
    print('textos de %s: %d bytes (original %d, diferencia %+d)'%(SRC,tam,FIN-INI,tam-(FIN-INI)))
if __name__=='__main__':
    a=sys.argv[1:]
    bloque(a.pop(0))
    if a[0]=='exporta': exporta(a[1])
    elif a[0]=='monta': monta(a[1],a[2])

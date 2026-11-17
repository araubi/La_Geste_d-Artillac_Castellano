#!/usr/bin/env python3
"""Ensambla un fuente sin datos («defs n,RELLENO») y rellena los huecos con los bytes originales.
Se ensambla dos veces, con RELLENO 00h y FFh: los bytes que cambian son los huecos."""
import os,subprocess,shutil
def ensambla_simple(asm,out,cwd):
    if shutil.which('sjasmplus'): subprocess.run(['sjasmplus','--nologo','--raw='+out,asm],check=True,cwd=cwd,stdout=subprocess.DEVNULL)
    else: subprocess.run(['pasmo','--bin',asm,out],check=True,cwd=cwd)
    return bytearray(open(os.path.join(cwd,out),'rb').read())
def ensambla(asm,cwd):
    """Devuelve (binario con huecos a 00h, lista de huecos (inicio, longitud))."""
    texto=open(os.path.join(cwd,asm),encoding='utf-8').read(); b=[]
    for v in (0x00,0xFF):
        t='_relleno_%02x.asm'%v
        open(os.path.join(cwd,t),'w',encoding='utf-8').write('RELLENO\tequ 0%02Xh\n'%v+texto)
        b.append(ensambla_simple(t,'_relleno_%02x.bin'%v,cwd))
        for f in (t,'_relleno_%02x.bin'%v): os.remove(os.path.join(cwd,f))
    assert len(b[0])==len(b[1])
    huecos=[]; i=0
    while i<len(b[0]):
        if b[0][i]!=b[1][i]:
            j=i
            while j<len(b[0]) and b[0][j]!=b[1][j]: j+=1
            huecos.append((i,j-i)); i=j
        else: i+=1
    return b[0],huecos
def rellena(b,huecos,orig,huecos_orig=None,quitar=None):
    """Copia en b los bytes de orig. Si el fuente cambió de tamaño (traducción), los huecos se
    emparejan en orden con los del original (huecos_orig), saltando los del intervalo quitar."""
    if huecos_orig is None: huecos_orig=huecos
    if quitar:              # se quita lo que cae dentro del intervalo (textos sustituidos)
        q0,q1=quitar; h=[]
        for a,n in huecos_orig:
            if a<q0: h.append((a,min(a+n,q0)-a))
            if a+n>q1: h.append((max(a,q1),a+n-max(a,q1)))
        huecos_orig=h
    assert [n for _,n in huecos]==[n for _,n in huecos_orig], 'los huecos no casan con el original'
    for (a,n),(o,_) in zip(huecos,huecos_orig): b[a:a+n]=orig[o:o+n]
    return b

#!/usr/bin/env python3
"""Quita los datos originales de un fuente del desensamblado: cada «defb ...» pasa a
«defs n,RELLENO». Así el repositorio no lleva datos del juego; build.py los recupera de las
cintas del usuario (ensambla con RELLENO 00h y FFh y rellena lo que cambia).
Uso: quita_datos.py entrada.asm salida.asm [direcciones que se dejan, p. ej. b029 b031]"""
import re,sys
def quita(texto,dejar=()):
    out=[]; n=0
    for l in texto.split('\n'):
        m=re.match(r'^(\s*)defb\s+([0-9A-Fa-f]+h(?:\s*,\s*[0-9A-Fa-f]+h)*)\s*(;.*)?$',l)
        if m and not any(re.search(r';%s\b'%d,l) for d in dejar):
            k=len(m.group(2).split(',')); n+=k
            l='%sdefs %d,RELLENO%s'%(m.group(1),k,'\t'+m.group(3) if m.group(3) else '')
        elif re.match(r'^\s*defb\b',l) and not any(re.search(r';%s\b'%d,l) for d in dejar):
            raise SystemExit('línea defb no reconocida: '+l)
        out.append(l)
    return '\n'.join(out),n
if __name__=='__main__':
    t,n=quita(open(sys.argv[1],encoding='utf-8').read(),sys.argv[3:])
    open(sys.argv[2],'w',encoding='utf-8').write(t); print('%s: %d bytes de datos quitados'%(sys.argv[2],n))

#!/usr/bin/env python3
"""Formato editable de los cantos de La Geste d'Artillac y montaje.

  canto.py exporta N fichero.txt     canto N (datos/CNN.bin) -> formato editable
  canto.py monta fichero.txt salida.bin    -> canto binario (y escribe salida.bin.tabla con w0,w1,w2,long)
  canto.py comprueba N               exporta y vuelve a montar: debe salir idéntico

Formato: una cadena empieza con «== P<n>» (párrafo) u «== O<n>» (opción). Cada línea
siguiente es un trozo situado: «@fila,col texto». Una línea sin @ sigue la anterior sin
situar. En el texto: {xx} = orden 1Bh xx (4C-4F tamaño, 41-47/51-57 color);
{#xx} = byte xx tal cual; las vocales con acento francés o español se escriben con su
letra (é = 16h 42h 'e'); ñ = 16h 24h 'n' (tilde nueva en 24h); ¿ = 23h; ¡ = 26h.
Si una línea acaba en espacios, se cierra con «|» para que no se pierdan.
Las líneas que empiezan por «#» son comentarios."""
import sys,os,struct,unicodedata,re
R=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ACC={0x41:'̀',0x42:'́',0x43:'̂',0x48:'̈',0x4b:'̧',0x24:'̃'}
INV={v:k for k,v in ACC.items()}
ESPECIAL={'¿':0x23,'¡':0x26}
ESPECIAL_INV={v:k for k,v in ESPECIAL.items()}
LIBRES='{}|@#$&'   # caracteres que hay que escapar en el texto
def tabla_motor(motor,n):
    a=0xaf7d+(n-1)*8-0x9000
    return list(struct.unpack('<4H',motor[a:a+8]))
def lee_motor():
    return open(os.path.join(R,'salida','motor.bin'),'rb').read()

def cadena_a_lineas(d,i):
    out=[]; cur=None
    def emite(s):
        nonlocal cur
        if cur is None: cur=''
        cur+=s
    while True:
        b=d[i]; i+=1
        if b==0x7f: break
        if b==0x1f:
            if cur is not None: out.append(cur)
            cur='@%d,%d '%(d[i]-0x3f,d[i+1]-0x40); i+=2; continue
        if b==0x1b: emite('{%02X}'%d[i]); i+=1; continue
        if b==0x16 and d[i] in ACC and 0x20<=d[i+1]<0x7f:
            ch=unicodedata.normalize('NFC',chr(d[i+1])+ACC[d[i]])
            if len(ch)==1 and ch not in LIBRES and ord(ch)>=0x80:
                emite(ch); i+=2; continue
        if 0x20<=b<0x7f and chr(b) not in LIBRES and b not in ESPECIAL_INV:
            emite(chr(b)); continue
        emite('{#%02X}'%b)
    if cur is not None: out.append(cur)
    out=[l+'|' if l.endswith(' ') else l for l in out]
    return out,i

def exporta(n,dest):
    motor=lee_motor(); w0,w1,w2,ln=tabla_motor(motor,n)
    m=bytes(0x100)+open(os.path.join(R,'datos','C%02d.bin'%n),'rb').read()
    L=['# Canto %d de La Geste d\'Artillac. Formato: ver tools/canto.py'%n,'#canto %d'%n,'']
    for nombre,a,b in (('P',0x790,w0),('O',w0,w1)):
        i=a;k=1
        while i<b:
            if cadena_a_lineas(m,i)[1]>b:   # relleno sin terminar antes del final de la zona
                L.append('== X'); L.append(''.join('{#%02X}'%x for x in m[i:b])); L.append(''); i=b; break
            ls,i=cadena_a_lineas(m,i)
            L.append('== %s%d'%(nombre,k)); L+=ls; L.append(''); k+=1
    open(dest,'w').write('\n'.join(L)+'\n')

def linea_a_bytes(t,err):
    o=bytearray(); j=0
    while j<len(t):
        c=t[j]
        if c=='{':
            k=t.index('}',j); x=t[j+1:k]; j=k+1
            if x.startswith('#'): o.append(int(x[1:],16))
            else: o+=bytes([0x1b,int(x,16)])
            continue
        j+=1
        if c in ESPECIAL: o.append(ESPECIAL[c]); continue
        if ord(c)<0x7f and 0x20<=ord(c): o.append(ord(c)); continue
        dd=unicodedata.normalize('NFD',c)
        if len(dd)==2 and dd[1] in INV and ord(dd[0])<0x7f:
            o+=bytes([0x16,INV[dd[1]],ord(dd[0])]); continue
        err.append('carácter no admitido: %r'%c)
    return o

def lee_texto(f):
    """Devuelve (n, lista de párrafos, lista de opciones) con cada cadena como lista de (pos, texto)."""
    n=None; P=[]; O=[]; cur=None; zona=P
    for raw in open(f,encoding='utf-8').read().split('\n'):
        if raw.startswith('#canto'): n=int(raw.split()[1]); continue
        if raw.startswith('#'): continue
        if raw.startswith('== '):
            cur=[]; cur_x=raw[3]=='X'
            if cur_x: cur.append('X')
            if raw[3]=='O': zona=O
            elif raw[3]=='P': zona=P
            zona.append(cur); continue
        if raw.strip()=='' : continue
        t=raw[:-1] if raw.endswith('|') else raw
        m=re.match(r'^@(-?\d+),(-?\d+) ?(.*)$',t)
        if m: cur.append(((int(m.group(1)),int(m.group(2))),m.group(3)))
        else: cur.append((None,t))
    return n,P,O

def cadena_bytes(trozos,err):
    o=bytearray(); fin=b'\x7f'
    if trozos and trozos[0]=='X': trozos=trozos[1:]; fin=b''
    for pos,t in trozos:
        if pos is not None: o+=bytes([0x1f,(pos[0]+0x3f)&255,(pos[1]+0x40)&255])
        o+=linea_a_bytes(t,err)
    return o+fin

def monta(f,dest=None):
    n,P,O=lee_texto(f); err=[]
    motor=lee_motor(); w0,w1,w2,ln=tabla_motor(motor,n)
    orig=open(os.path.join(R,'datos','C%02d.bin'%n),'rb').read()
    cab=orig[:0x790-0x100]; graf=orig[w1-0x100:]
    tp=b''.join(cadena_bytes(c,err) for c in P); to=b''.join(cadena_bytes(c,err) for c in O)
    nw0=0x790+len(tp); nw1=nw0+len(to); nw2=nw1+(w2-w1)
    d=cab+tp+to+graf; nln=len(d)
    d=cab+tp+to+graf
    if err: print('\n'.join(sorted(set(err)))); sys.exit(1)
    if 0x100+len(d)>0x8000: print('¡El canto %d no cabe! %d bytes'%(n,len(d))); sys.exit(1)
    if dest:
        open(dest,'wb').write(d)
        open(dest+'.tabla','w').write('%d %04X %04X %04X %04X\n'%(n,nw0,nw1,nw2,nln))
    return n,d,(nw0,nw1,nw2,nln)

if __name__=='__main__':
    a=sys.argv[1:]
    if a[0]=='exporta': exporta(int(a[1]),a[2])
    elif a[0]=='monta':
        n,d,t=monta(a[1],a[2]); print('C%d: %d bytes, tabla %s'%(n,len(d),' '.join('%04X'%x for x in t)))
    elif a[0]=='comprueba':
        for n in [int(x) for x in a[1:]]:
            tmp='/tmp/canto_prueba.txt'; exporta(n,tmp); _,d,_=monta(tmp)
            o=open(os.path.join(R,'datos','C%02d.bin'%n),'rb').read()
            print('C%d'%n,'idéntico' if d==o else 'DISTINTO')

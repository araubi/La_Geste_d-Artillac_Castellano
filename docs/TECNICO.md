# Notas técnicas

## La cinta original

- **Cinta 1, «Liminaire»** (`BLOAD"CAS:",R`): la etapa 1 son 32 bytes en FF07h (el gancho H.READ). Carga la etapa 2 (8000h-82C9h), que busca la RAM, pone las pantallas de Infogrames y del título (comprimidas con RLE), carga la creación del personaje (9000h-AC2Fh) y, después, el motor (9000h-BDCFh). Todo va cifrado con XOR 76h salvo la etapa 1.
- **Cinta 2**: la cara A trae los cantos 1 a 6 y la cara B los cantos 7 a 12. Cada canto se carga en 0100h. Los cantos 6 y 12 están vacíos.
- Hace falta un MSX1 con 64 KB de RAM: el juego usa casi toda la memoria.

## Memoria durante la partida

| Dirección | Contenido |
|---|---|
| 0100h-5FFFh | el canto cargado |
| 8000h-82C9h | etapa 2 del cargador (sigue en uso: llama a la BIOS entre slots) |
| 9000h-BDCFh | motor; pila por debajo de 9000h |
| E000h-E0B2h | hoja del personaje: E000-E007 características, E008 vida, E009 canto, E00A párrafo, E00D hambre, E00E comidas, E010 peso, E011+n dónde está el objeto n, E047+n su estado |

## Formato de un canto

| Dirección | Contenido |
|---|---|
| 0100h + 8·n | ficha del párrafo n: +0 característica ±, +1 vida ± (bit 7 = muerte), +2 especial (10h = código), +3 lista de opciones, +4 animación, +5 dibujo lateral, +6 hambre, +7 comidas |
| 0280h / 0300h | listas de 4 / 8 opciones |
| 0380h | opciones simples: pares (texto, destino) |
| 0480h + 16·n | opciones con condiciones (objetos, características, azar) |
| 0790h | textos de los párrafos, seguidos y terminados en 7Fh (sin punteros) |
| tabla AF7Dh del motor | dónde empiezan los textos de las opciones, los dibujos grandes y los laterales, y la longitud |

Destino de una opción: número de párrafo; con el bit 7, cambio de canto; 7Fh/7Eh/7Dh repiten o vuelven.

Textos: `1Fh fila col` sitúa, `1Bh 4C-4F` cambia el tamaño, `1Bh 41-47/51-57` el color, `16h` + letra pone un acento encima de la letra siguiente, y 00h-09h son mensajes del motor. Las columnas son de 6 píxeles (x = 6·col + 10).

## La ROM

- MegaROM **ASCII16 de 256 KB**. El banco 0 lleva el arranque (`rom/arranque.asm`), que copia la etapa 2 y el lector (`rom/lector.asm`) a la RAM y lanza el juego como lo haría la cinta.
- El lector vive en 8400h y sustituye a la rutina de cinta de la etapa 2 (806Eh) y a la carga de cantos del motor (9803h: `LD A,(AFD5h) / CALL 8403h / RET`). Lee del banco 1 en adelante: pantallas, creación, motor y cantos 1-5 y 7-11.
- Las pantallas de Infogrames y del título esperan a que se pulse una tecla (en cinta duraban lo que la carga siguiente).
- La música de la creación del personaje se salta 1 de cada 6 interrupciones en las máquinas de 60 Hz, para que suene al tempo de 50 Hz.
- Cambia de banco por 6000h. Lleva cinco `LD (77FFh),A` de relleno para que openMSX y blueMSX la detecten como ASCII16. Los cargadores del One Chip MSX pueden equivocarse: en él, cárgala con `mglocm /f`.

## La traducción

- `traduccion/Cnn_es.txt`: cantos 1 a 11 (formato en `tools/canto.py`). Cada trozo de texto va situado con `@fila,col`, y `{xx}` son las órdenes de tamaño y color. Casi todos los párrafos tienen caligramas (palabras dibujadas con letras), rehechos en castellano.
- `traduccion/motor_es.txt` y `creacion_es.txt`: textos del motor y de la creación (formato en `tools/motor_textos.py`). Los textos del motor pueden cambiar de longitud: las etiquetas se recolocan al ensamblar. La creación tiene tamaño fijo.
- Las opciones tienen como mucho 26 caracteres. En las casillas del menú H caben 6 letras por línea.
- Se añaden ñ, ¿ y ¡ a las dos fuentes, la tecla (O)ui pasa a (S)í y la brújula pone N y S centradas sobre la flecha.
- Las órdenes del menú (H, I, B...) solo se aceptan en mayúsculas.

# Cintas originales

Copia aquí tus cintas de *La Geste d'Artillac* (versión francesa, Infogrames 1985) en formato `.cas`. Git no las sube.

Hacen falta las dos cintas: la cinta 1 («Liminaire») y las dos caras de la cinta 2 (cantos 1-6 y 7-12). Da igual cómo se llamen los ficheros: `tools/extrae_originales.py` busca los bloques por su nombre en la cinta y comprueba el SHA-1 de cada pieza.

Se han comprobado con estos volcados:

| Cinta | SHA-1 del .cas |
|---|---|
| Cinta 1, Liminaire | `b3d982a9e0a6061b1da20d4af197600d782a19b0` |
| Cinta 2, cara A (cantos 1-6) | `ef040cce7711761c130d2c618bd46e42e66e02b9` |
| Cinta 2, cara B (cantos 7-12) | `149fb0767119931e204dee0df0f367b0c5849720` |

Si tienes la cinta en `.tsx`, pásala antes a `.cas`.

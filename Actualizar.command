#!/bin/bash
# ============================================================
#  Aula IA — Actualizar índice de contenido
#  Doble clic aquí después de agregar o quitar archivos en
#  la carpeta "contenido". Escanea todo y regenera contenido.js.
# ============================================================

cd "$(dirname "$0")" || exit 1
OUT="contenido.js"

esc(){ printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }

{
  printf '// Generado automaticamente por Actualizar.command - no editar a mano\n'
  printf 'window.CONTENIDO = {\n'
  printf '  "generado": "%s",\n' "$(date '+%Y-%m-%d %H:%M')"
  printf '  "curso": "Toma de decisiones basadas en datos con IA",\n'
  printf '  "archivos": {\n'

  fp=1
  for perfil in josue jeanette; do
    [ $fp -eq 0 ] && printf ',\n'
    fp=0
    printf '    "%s": {' "$perfil"
    fu=1
    for u in 1 2 3 4 5 6; do
      dir="contenido/$perfil/unidad-$u"
      [ -d "$dir" ] || continue
      exp=""; mapa=""; audio=""; simple=""
      for f in "$dir"/*; do
        [ -f "$f" ] || continue
        base="$(basename "$f")"
        [ "${base#.}" != "$base" ] && continue        # ignora archivos ocultos (.DS_Store)
        lext="$(printf '%s' "${base##*.}" | tr '[:upper:]' '[:lower:]')"
        rel="$dir/$base"
        case "$lext" in
          pdf)                                  exp="$rel" ;;
          html|htm)  if [ "$perfil" = "josue" ]; then mapa="$rel"; else simple="$rel"; fi ;;
          mp3|m4a|wav|aac|ogg|opus|mp4)         audio="$rel" ;;
        esac
      done
      parts=""
      [ -n "$exp" ]    && parts="$parts\"explicacion\":\"$(esc "$exp")\","
      [ -n "$mapa" ]   && parts="$parts\"mapa\":\"$(esc "$mapa")\","
      [ -n "$audio" ]  && parts="$parts\"audio\":\"$(esc "$audio")\","
      [ -n "$simple" ] && parts="$parts\"explicacion_simple\":\"$(esc "$simple")\","
      [ -z "$parts" ] && continue
      parts="${parts%,}"
      [ $fu -eq 0 ] && printf ','
      fu=0
      printf '\n      "%s":{%s}' "$u" "$parts"
    done
    printf '\n    }'
  done
  printf '\n  },\n'

  # ---- Audiolibros transversales (carpeta contenido/audiolibros) ----
  printf '  "audiolibros": {'
  fa=1
  for u in 1 2 3 4 5 6; do
    file=""
    if [ -d "contenido/audiolibros" ]; then
      for f in contenido/audiolibros/*; do
        [ -f "$f" ] || continue
        b="$(basename "$f")"
        [ "${b#.}" != "$b" ] && continue
        case "$b" in *nidad$u.*|*nidad-$u.*|*_$u.*) file="contenido/audiolibros/$b" ;; esac
      done
    fi
    [ -z "$file" ] && continue
    [ $fa -eq 0 ] && printf ','
    fa=0
    printf '\n    "%s":"%s"' "$u" "$(esc "$file")"
  done
  printf '\n  }\n};\n'
} > "$OUT"

piezas="$(grep -o 'contenido/[^"]*' "$OUT" 2>/dev/null | wc -l | tr -d ' ')"
echo ""
echo "  ============================================"
echo "   Aula IA - indice actualizado."
echo "   Archivos encontrados: $piezas"
echo "   Abre (o recarga) index.html para verlos."
echo "  ============================================"
echo ""
echo "  Puedes cerrar esta ventana."

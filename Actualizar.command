#!/bin/bash
# ============================================================
#  Aula IA - Actualizar indice de contenido  (version por MODULOS)
#  Doble clic aqui despues de agregar o quitar archivos en la
#  carpeta "contenido". Escanea los 4 modulos y sus unidades y
#  regenera contenido.js.
#
#  Estructura esperada (los nombres son TOLERANTES, ver abajo):
#    contenido/
#      josue/    <Modulo>/ <Unidad>/  (un .pdf, un .html)
#      jeanette/ <Modulo>/ <Unidad>/  (un .html)
#      audiolibros/ <Modulo>/ ...      (un .html por unidad, suelto
#                                        o dentro de una subcarpeta de unidad)
#
#  Nombres de MODULO aceptados (cualquiera):
#    "Primer modulo", "Segundo modulo", "Tercer modulo", "Cuarto modulo"
#    "modulo-1", "modulo 2", "Modulo 3", "modulo_4", ...
#  Nombres de UNIDAD aceptados (cualquiera con el numero):
#    "unidad-1", "Unidad 1", "unidad 3", "u4", ...
# ============================================================

cd "$(dirname "$0")" || exit 1
OUT="contenido.js"

esc(){ printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }

# --- numero de modulo -> nombre oficial del diplomado UDD ---
mod_nombre(){
  case "$1" in
    1) printf 'Toma de decisiones basadas en datos con IA' ;;
    2) printf 'Innovacion empresarial con IA' ;;
    3) printf 'Fundamentos de Inteligencia Artificial para negocios' ;;
    4) printf 'IA y automatizacion de procesos empresariales' ;;
  esac
}

# --- nombre de carpeta de modulo -> numero (tolerante a variantes) ---
mod_num_from_name(){
  local s
  s=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')
  case "$s" in
    *primer*|*"modulo 1"*|*"módulo 1"*|*modulo-1*|*modulo_1*|*modulo1*) echo 1 ;;
    *segundo*|*"modulo 2"*|*"módulo 2"*|*modulo-2*|*modulo_2*|*modulo2*) echo 2 ;;
    *tercer*|*"modulo 3"*|*"módulo 3"*|*modulo-3*|*modulo_3*|*modulo3*) echo 3 ;;
    *cuarto*|*"modulo 4"*|*"módulo 4"*|*modulo-4*|*modulo_4*|*modulo4*) echo 4 ;;
    *) echo "" ;;
  esac
}

# --- nombre de carpeta de unidad -> numero (toma los digitos) ---
unit_num_from_name(){
  local d
  d=$(printf '%s' "$1" | tr -dc '0-9')
  d=$(printf '%s' "$d" | cut -c1-2)
  case "$d" in ''|*[!0-9]*) echo "" ;; *) echo $((10#$d)) ;; esac
}

# --- encuentra la carpeta de un modulo dentro de una base ---
find_mod_dir(){  # $1 base, $2 numero de modulo
  local base="$1" want="$2" d bn
  for d in "$base"/*; do
    [ -d "$d" ] || continue
    bn=$(basename "$d")
    [ "$(mod_num_from_name "$bn")" = "$want" ] && { printf '%s' "$d"; return 0; }
  done
  return 1
}

# --- encuentra la carpeta de una unidad dentro de un modulo ---
find_unit_dir(){  # $1 dir del modulo, $2 numero de unidad
  local base="$1" want="$2" d bn
  for d in "$base"/*; do
    [ -d "$d" ] || continue
    bn=$(basename "$d")
    [ "$(unit_num_from_name "$bn")" = "$want" ] && { printf '%s' "$d"; return 0; }
  done
  return 1
}

# --- titulo de la unidad, deducido del nombre del PDF de Josue ---
titulo_de(){  # $1 = dir de unidad de josue
  local dir="$1" f b t
  [ -n "$dir" ] || return 1
  for f in "$dir"/*; do
    [ -f "$f" ] || continue
    b=$(basename "$f"); case "$b" in .*) continue ;; esac
    case "$(printf '%s' "$b" | tr '[:upper:]' '[:lower:]')" in
      *.pdf)
        t="${b%.*}"
        t="${t#Explicacion_}"; t="${t#explicacion_}"
        t=$(printf '%s' "$t" | sed -E 's/^[Uu]nidad[ _-]?[0-9]+[ _-]?//')
        t=$(printf '%s' "$t" | tr '_' ' ')
        printf '%s' "$t"; return 0 ;;
    esac
  done
  return 1
}

# --- escanea una unidad y devuelve el fragmento JSON de sus piezas ---
scan_unit(){  # $1 perfil, $2 dir de unidad
  local perfil="$1" dir="$2" f b lext rel exp mapa audio simple parts
  exp=""; mapa=""; audio=""; simple=""
  for f in "$dir"/*; do
    [ -f "$f" ] || continue
    b=$(basename "$f"); case "$b" in .*) continue ;; esac
    lext=$(printf '%s' "${b##*.}" | tr '[:upper:]' '[:lower:]')
    rel="$dir/$b"
    case "$lext" in
      pdf) exp="$rel" ;;
      html|htm) if [ "$perfil" = "josue" ]; then mapa="$rel"; else simple="$rel"; fi ;;
      mp3|m4a|wav|aac|ogg|opus|mp4) audio="$rel" ;;
    esac
  done
  parts=""
  [ -n "$exp" ]    && parts="$parts\"explicacion\":\"$(esc "$exp")\","
  [ -n "$mapa" ]   && parts="$parts\"mapa\":\"$(esc "$mapa")\","
  [ -n "$audio" ]  && parts="$parts\"audio\":\"$(esc "$audio")\","
  [ -n "$simple" ] && parts="$parts\"explicacion_simple\":\"$(esc "$simple")\","
  parts="${parts%,}"
  printf '%s' "$parts"
}

# --- encuentra el audiolibro de una unidad dentro del modulo ---
find_audio(){  # $1 dir de audiolibros del modulo, $2 numero de unidad
  local dir="$1" u="$2" f b ud
  [ -n "$dir" ] || return 1
  for f in "$dir"/*; do
    [ -f "$f" ] || continue
    b=$(basename "$f"); case "$b" in .*) continue ;; esac
    case "$b" in *nidad$u.*|*nidad-$u.*|*nidad_$u.*|*_$u.*) printf '%s' "$f"; return 0 ;; esac
  done
  ud=$(find_unit_dir "$dir" "$u") || return 1
  for f in "$ud"/*; do
    [ -f "$f" ] || continue
    b=$(basename "$f"); case "$b" in .*) continue ;; esac
    printf '%s' "$f"; return 0
  done
  return 1
}

# ============================================================
#  Generacion de contenido.js
# ============================================================
{
  printf '// Generado automaticamente por Actualizar.command - no editar a mano\n'
  printf 'window.CONTENIDO = {\n'
  printf '  "generado": "%s",\n' "$(date '+%Y-%m-%d %H:%M')"
  printf '  "diplomado": "IA aplicada a los negocios",\n'
  printf '  "modulos": {\n'

  fmod=1
  for m in 1 2 3 4; do
    [ $fmod -eq 0 ] && printf ',\n'
    fmod=0
    printf '    "%s": {\n' "$m"
    printf '      "nombre": "%s",\n' "$(esc "$(mod_nombre "$m")")"

    jmod=$(find_mod_dir "contenido/josue" "$m")

    # --- titulos deducidos de los PDF de Josue ---
    printf '      "titulos": {'
    ft=1
    for u in 1 2 3 4 5 6; do
      [ -n "$jmod" ] || continue
      judir=$(find_unit_dir "$jmod" "$u") || continue
      t=$(titulo_de "$judir") || continue
      [ -n "$t" ] || continue
      [ $ft -eq 0 ] && printf ','
      ft=0
      printf '\n        "%s":"%s"' "$u" "$(esc "$t")"
    done
    printf '\n      },\n'

    # --- archivos por perfil ---
    printf '      "archivos": {\n'
    fp=1
    for perfil in josue jeanette; do
      [ $fp -eq 0 ] && printf ',\n'
      fp=0
      printf '        "%s": {' "$perfil"
      pmod=$(find_mod_dir "contenido/$perfil" "$m")
      fu=1
      for u in 1 2 3 4 5 6; do
        [ -n "$pmod" ] || continue
        udir=$(find_unit_dir "$pmod" "$u") || continue
        parts=$(scan_unit "$perfil" "$udir")
        [ -n "$parts" ] || continue
        [ $fu -eq 0 ] && printf ','
        fu=0
        printf '\n          "%s":{%s}' "$u" "$parts"
      done
      printf '\n        }'
    done
    printf '\n      },\n'

    # --- audiolibros del modulo ---
    printf '      "audiolibros": {'
    amod=$(find_mod_dir "contenido/audiolibros" "$m")
    fa=1
    for u in 1 2 3 4 5 6; do
      [ -n "$amod" ] || continue
      af=$(find_audio "$amod" "$u") || continue
      [ $fa -eq 0 ] && printf ','
      fa=0
      printf '\n        "%s":"%s"' "$u" "$(esc "$af")"
    done
    printf '\n      }\n'
    printf '    }'
  done

  printf '\n  }\n};\n'
} > "$OUT"

piezas="$(grep -o 'contenido/[^"]*' "$OUT" 2>/dev/null | wc -l | tr -d ' ')"
echo ""
echo "  ============================================"
echo "   Aula IA - indice actualizado (por modulos)."
echo "   Piezas de contenido encontradas: $piezas"
echo "   Abre (o recarga) el index para verlas."
echo "  ============================================"
echo ""
echo "  Puedes cerrar esta ventana."

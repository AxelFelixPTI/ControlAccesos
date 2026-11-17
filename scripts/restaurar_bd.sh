#!/usr/bin/env bash
# restaurar_bd.sh - Equivalente en bash de restaurar_bd.ps1 para una base remota (Neon, etc.).
# Uso:  export DATABASE_URL='postgresql://usuario:clave@host/base?sslmode=require'
#       ./scripts/restaurar_bd.sh            # base VACIA: tablas + rutinas (sin pruebas)
#       ./scripts/restaurar_bd.sh --rutinas  # base existente: solo re-aplica SP/funciones
#       ./scripts/restaurar_bd.sh --demo     # ademas carga DATOS_DEMO_ESCENARIOS.sql
# La clave va solo en la variable de entorno; nunca en el repo.
set -euo pipefail
: "${DATABASE_URL:?Defina DATABASE_URL}"
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
MOD="$RAIZ/Docs_Modulos"
SOLO_RUTINAS=0; DEMO=0
for a in "$@"; do case "$a" in --rutinas) SOLO_RUTINAS=1;; --demo) DEMO=1;; esac; done
export PGCLIENTENCODING=UTF8 PGOPTIONS='-c client_min_messages=warning'
run() { echo "  > $(basename "$(dirname "$(dirname "$1")")")/$(basename "$1")"; psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -q -f "$1"; }
hito() { basename "$(dirname "$(dirname "$1")")" | sed -E 's/^HITO_([0-9]+).*/\1/; t; s/.*/99/'; }
mapfile -t TODOS < <(find "$MOD" -path '*/00_BD/*.sql' | sort)
TABLAS=(); GOV=(); CAFA=(); BASE=(); CAFB=()
for f in "${TODOS[@]}"; do
  n="$(basename "$f")"; h=$((10#$(hito "$f")))
  if   [[ $n =~ ^[0-9]{2}_ ]]; then TABLAS+=("$f")
  elif [[ $n == SP_GOVERNANCE_* ]]; then GOV+=("$f")
  elif [[ $n == SP_CAF_SOLICITUD_BASE_ALL.sql ]]; then BASE+=("$f")
  elif [[ $n == SP_CAF_* ]]; then
     if [[ $n != SP_CAF_SOLICITUD* && $h -le 2 ]]; then CAFA+=("$f"); else CAFB+=("$f"); fi
  fi
done
# tablas por numero NN; rutinas post-hito 2 por hito y nombre (igual que el .ps1)
IFS=$'\n' TABLAS=($(printf '%s\n' "${TABLAS[@]}" | awk -F/ '{print $NF"\t"$0}' | sort | cut -f2)); 
IFS=$'\n' CAFB=($(for f in "${CAFB[@]}"; do printf '%02d\t%s\t%s\n' "$((10#$(hito "$f")))" "$(basename "$f")" "$f"; done | sort | cut -f3)); unset IFS
[[ ${#BASE[@]} -eq 1 ]] || { echo "Falta SP_CAF_SOLICITUD_BASE_ALL.sql"; exit 1; }
if [[ $SOLO_RUTINAS -eq 0 ]]; then
  n=$(psql "$DATABASE_URL" -Atc "SELECT count(*) FROM pg_namespace WHERE nspname IN ('CAF_GOVERNANCE','TRIANONSATELITAL_CAF_PRODD')")
  [[ $n == 0 ]] || { echo "La base ya tiene los schemas. Use --rutinas o una base vacia."; exit 1; }
  echo "== A. Tablas y datos iniciales =="; for f in "${TABLAS[@]}"; do run "$f"; done
fi
echo "== B. Procedimientos y funciones =="
for f in "${GOV[@]}" "${CAFA[@]}" "${BASE[@]}" "${CAFB[@]}"; do run "$f"; done
if [[ $DEMO -eq 1 ]]; then
  echo "== C. Datos demo =="; run "$(find "$MOD" -name DATOS_DEMO_ESCENARIOS.sql | head -1)"
fi
psql "$DATABASE_URL" -Atc "SELECT n.nspname||': '||(SELECT count(*) FROM information_schema.tables t WHERE t.table_schema=n.nspname AND t.table_type='BASE TABLE')||' tablas, '||(SELECT count(*) FROM pg_proc p WHERE p.pronamespace=n.oid)||' rutinas' FROM pg_namespace n WHERE n.nspname IN ('CAF_GOVERNANCE','TRIANONSATELITAL_CAF_PRODD') ORDER BY 1"
echo "Base lista."

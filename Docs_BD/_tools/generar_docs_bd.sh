#!/usr/bin/env bash
# =============================================================================
# generar_docs_bd.sh — regenera Docs_BD/ desde la base PostgreSQL del piloto.
# Uso:  ./generar_docs_bd.sh <basedatos> [usuario] [host]
# Produce, por schema: <SCHEMA>_01_TABLAS_CONSOLIDADO.sql y
# <SCHEMA>_03_PROCEDIMIENTOS_CONSOLIDADO.sql, más 00_INVENTARIO_GLOBAL.md.
# Docs_BD es la fuente de verdad: se regenera tras CADA despliegue, nunca se edita a mano.
# =============================================================================
set -euo pipefail
DB="${1:?Indique la base de datos}"; USR="${2:-postgres}"; HOST="${3:-localhost}"
OUT="$(cd "$(dirname "$0")/.." && pwd)"
SCHEMAS=("CAF_GOVERNANCE" "TRIANONSATELITAL_CAF_PRODD")
PSQL=(psql -h "$HOST" -U "$USR" -d "$DB" -At -v ON_ERROR_STOP=1)
FECHA="$(date '+%Y-%m-%d %H:%M')"

{
  echo "# Inventario global de Docs_BD"
  echo
  echo "Export del **$FECHA** · base \`$DB\` · motor PostgreSQL $("${PSQL[@]}" -c 'show server_version')"
  echo
  echo "| Schema | Tablas | Funciones (lectura) | Procedimientos (escritura) |"
  echo "| --- | --: | --: | --: |"
} > "$OUT/00_INVENTARIO_GLOBAL.md"

for S in "${SCHEMAS[@]}"; do
  T="$OUT/${S}_01_TABLAS_CONSOLIDADO.sql"
  P="$OUT/${S}_03_PROCEDIMIENTOS_CONSOLIDADO.sql"
  # Tablas: índice + DDL (sin datos, sin dueños ni permisos)
  {
    echo "-- Docs_BD · $S · TABLAS · export $FECHA"
    echo "-- ÍNDICE"
    "${PSQL[@]}" -c "select '--  '||row_number() over (order by table_name)||'. '||table_name from information_schema.tables where table_schema='$S' and table_type='BASE TABLE' order by table_name"
    echo
    pg_dump -h "$HOST" -U "$USR" -d "$DB" --schema-only --no-owner --no-privileges -n "\"$S\"" \
      | grep -v '^SET \|^SELECT pg_catalog\|^--$\|^\\restrict\|^\\unrestrict' | sed '/^\s*$/N;/^\s*\n$/D'
  } > "$T"
  # Rutinas: índice + definición de cada función y procedimiento
  {
    echo "-- Docs_BD · $S · FUNCIONES Y PROCEDIMIENTOS · export $FECHA"
    echo "-- ÍNDICE"
    "${PSQL[@]}" -c "select '--  '||row_number() over (order by p.proname)||'. '||p.proname||case p.prokind when 'p' then ' (procedimiento)' else ' (función)' end from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='$S' order by p.proname"
    echo
    "${PSQL[@]}" -c "select pg_get_functiondef(p.oid)||';'||chr(10) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='$S' order by p.proname"
  } > "$P"
  NT=$("${PSQL[@]}" -c "select count(*) from information_schema.tables where table_schema='$S' and table_type='BASE TABLE'")
  NF=$("${PSQL[@]}" -c "select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='$S' and p.prokind='f'")
  NP=$("${PSQL[@]}" -c "select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='$S' and p.prokind='p'")
  echo "| \`$S\` | $NT | $NF | $NP |" >> "$OUT/00_INVENTARIO_GLOBAL.md"
done
echo "Docs_BD regenerado en $OUT ($FECHA)"

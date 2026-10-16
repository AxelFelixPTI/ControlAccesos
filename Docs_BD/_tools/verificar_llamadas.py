# Verifica CADA llamada de los repositorios contra la base: resolución de la rutina con los tipos
# que enviaría EjecutorSp (bigint, integer, text, timestamp), y columnas de respuesta.
import re, subprocess, sys, glob, os
base, repos = sys.argv[1], sys.argv[2]
TIPO = {"AddLong": "bigint", "AddLongReq": "bigint", "AddInt": "integer", "AddIntReq": "integer",
        "AddStr": "text", "AddStrReq": "text", "AddChar1": "text", "AddTimestamp": "timestamp"}
def psql(sql, tuplas=True):
    cmd = ["psql", "-q", "-d", base, "-A", "-v", "ON_ERROR_STOP=1", "-c", sql]
    if tuplas: cmd.insert(1, "-t")
    r = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
    return r.returncode, r.stdout, r.stderr
def schema_de(nombre, firmas):
    return firmas[nombre]
firmas = {}
for ln in open(sys.argv[3], encoding="utf-8"):
    if ln.startswith("#") or not ln.strip(): continue
    s = ln.split("|"); firmas[s[1]] = s[0]
ok = mal = 0; vistas = set(); fallos = []; codigos = {}
for f in sorted(glob.glob(os.path.join(repos, "Repo_*.cs"))):
    txt = open(f, encoding="utf-8").read()
    partes = re.split(r'(?=(?:funcion|procedimiento): ")', txt)[1:]
    for seg in partes:
        m = re.match(r'(funcion|procedimiento): "([A-Z_0-9]+)"', seg)
        kind, nombre = m.group(1), m.group(2)
        fin = seg.find("ct: ct);")
        cuerpo = seg[:fin]
        col = re.search(r'columnaId: "([A-Za-z_0-9]+)"', cuerpo)
        args = re.findall(r'(Add\w+)\(p, "([A-Za-z_0-9]+)"', cuerpo)
        lista = ", ".join(f"NULL::{TIPO[a]}" for a, _ in args)
        sch = firmas[nombre]
        pre = f'SET search_path TO "{sch}"; '
        if kind == "funcion":
            sql = pre + f'SELECT * FROM "{nombre}"({lista}) LIMIT 0'
            rc, out, err = psql(sql)
            esperado = None
        else:
            sql = pre + f'CALL "{nombre}"({lista})'
            rc, out, err = psql(sql)
        vistas.add(nombre)
        if rc != 0:
            mal += 1; fallos.append((os.path.basename(f), nombre, err.strip().splitlines()[-1] if err.strip() else "?"))
            continue
        if kind == "procedimiento":
            rc2, o2, _ = psql(sql, tuplas=False)
            lin = [x for x in o2.splitlines() if x and not x.startswith("(")]
            hdr, fila = lin[0].split("|"), lin[1].split("|")
            falta = [c for c in (["HV_Codigo_Resp","HV_Mensaje"] + ([col.group(1)] if col else [])) if c not in hdr]
            if falta:
                mal += 1; fallos.append((os.path.basename(f), nombre, f"faltan columnas {falta} en {hdr}")); continue
            cod = fila[hdr.index("HV_Codigo_Resp")]
            if cod == "500":
                mal += 1; fallos.append((os.path.basename(f), nombre, f"respondió 500 con parámetros nulos: {fila}")); continue
            codigos[cod] = codigos.get(cod, 0) + 1
        ok += 1
print(f"llamadas verificadas: {ok + mal} | OK: {ok} | con problema: {mal} | rutinas distintas: {len(vistas)}")
print("códigos de respuesta con parámetros nulos:", codigos)
for x in fallos[:6]: print("  FALLO", x)
if len(fallos) > 6: print("  ... y", len(fallos)-6, "más")
sys.exit(1 if mal else 0)

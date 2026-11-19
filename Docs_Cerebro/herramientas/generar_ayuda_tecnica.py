#!/usr/bin/env python3
"""Genera la «ficha técnica» de cada pantalla (D-255) a partir del código real.
Cadena: Controlador -> ISrv_X -> Srv_X -> IRepo_Y -> literales "ERP_CAF_*" (SPs y funciones) -> tablas "CAF_*"/Catalogo_* citadas en el SQL de cada SP.
Solo publica NOMBRES de objetos (nunca valores, cadenas de conexión ni claves). Uso:  python3 Docs_Cerebro/herramientas/generar_ayuda_tecnica.py
Salida: src/Web.ControlAccesos/wwwroot/js/ayuda/tecnica.js  (volver a ejecutar cuando cambien SPs, repos o controladores)."""
import re, glob, os, json
R = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
CTRL = os.path.join(R, 'src/Web.ControlAccesos/Controllers')
SRV = os.path.join(R, 'src/Application.Services/ControlAccesos')
REP = os.path.join(R, 'src/Infrastructure.Repositories/ControlAccesos')
OUT = os.path.join(R, 'src/Web.ControlAccesos/wwwroot/js/ayuda/tecnica.js')
leer = lambda p: open(p, encoding='utf-8').read() if os.path.exists(p) else ''
# SQL de cada SP/función: nombre -> texto
sql = {}
for f in glob.glob(os.path.join(R, 'Docs_Modulos/**/*.sql'), recursive=True):
    t = leer(f)
    partes = re.split(r'(?=CREATE OR REPLACE (?:PROCEDURE|FUNCTION) ")', t)
    for b in partes:
        m = re.match(r'CREATE OR REPLACE (?:PROCEDURE|FUNCTION) "(ERP_CAF_[A-Za-z0-9_]+)"', b)
        if m: sql[m.group(1)] = sql.get(m.group(1), '') + b.split('\n$$;')[0]
def tablas(sp, visto=None):
    visto = visto or set(); r = set()
    if sp in visto or sp not in sql: return r
    visto.add(sp); cuerpo = sql[sp]
    r |= set(re.findall(r'"((?:CAF_[A-Za-z0-9_]+)|(?:Catalogo_[A-Za-z0-9_]+)|(?:Usuario|Personal|Rol|Licencia[A-Za-z_]*))"', cuerpo)) - {'CAF_GOVERNANCE'}
    for sub in set(re.findall(r'"(ERP_CAF_[A-Za-z0-9_]+)"', cuerpo)): r |= tablas(sub, visto)
    return r
salida = {}
for c in sorted(glob.glob(CTRL + '/*Controller.cs')):
    nombre = os.path.basename(c)[:-len('Controller.cs')]
    srvs = sorted(set(re.findall(r'ISrv_(\w+)', leer(c))))
    sps = set(); repos = set()
    for s in srvs:
        t = leer(os.path.join(SRV, 'Srv_%s.cs' % s))
        for rp in re.findall(r'IRepo_(\w+)', t): repos.add(rp)
        repos.add(s)
    for rp in repos: sps |= set(re.findall(r'"(ERP_CAF_[A-Za-z0-9_]+)"', leer(os.path.join(REP, 'Repo_%s.cs' % rp))))
    sps = sorted(sps)
    tabs = set()
    for sp in sps: tabs |= tablas(sp)
    salida[nombre] = {'servicios': ['Srv_' + s for s in srvs], 'sps': sps, 'tablas': sorted(tabs)}
with open(OUT, 'w', encoding='utf-8') as f:
    f.write('// GENERADO por Docs_Cerebro/herramientas/generar_ayuda_tecnica.py. No editar a mano.\nwindow.CAF_AYUDA_TEC = ' + json.dumps(salida, ensure_ascii=False, indent=1) + ';\n')
print('Pantallas:', len(salida), '· SPs:', sum(len(v['sps']) for v in salida.values()))

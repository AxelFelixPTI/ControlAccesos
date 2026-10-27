// Control de accesos (Vigilancia): personas autorizadas hoy por solicitud, ingreso y salida con checklist,
// respaldo de equipos/herramientas, desviación cuando un ítem no se cumple, registro tardío y detalle por persona.
// Las reglas viven en los procedimientos; aquí solo se muestran y se envía lo que Vigilancia marcó.
(function () {
    'use strict';
    var raiz = document.getElementById('caf-vig');
    if (!raiz) return;
    var el = CAF.el, d = raiz.dataset, puede = d.puedeRegistrar === 'Y', puedeInc = d.puedeIncidencia === 'Y';
    var todas = [], grupo = 'TODOS', texto = '', temporizador = null, secuencia = 0, modo = 'HOY', hayLimite = false;
    var modos = document.getElementById('v-modos'), desde = document.getElementById('v-desde'), hasta = document.getElementById('v-hasta');
    var cajaTexto = document.getElementById('v-texto'), pills = document.getElementById('v-pills');
    var panelNoAut = document.getElementById('v-noaut'), bloques = document.getElementById('v-bloques');
    var opDesv = {};

    var GRUPOS = [['TODOS', 'Todos'], ['POR_INGRESAR', 'Por ingresar'], ['DENTRO', 'Dentro'], ['SALIERON', 'Salieron'], ['DENEGADOS_NO_VINIERON', 'Denegados o no vinieron']];
    var ESTADO = {
        ESPERADA: ['Por ingresar', 'c-pend'], DENTRO: ['Dentro', 'c-ok'], SALIO: ['Salió', 'c-line'],
        DENEGADA: ['Ingreso denegado', 'c-rec'], NO_SE_PRESENTO: ['No se presentó', 'c-can']
    };
    var RESULTADO = {
        INGRESA: 'Ingresa', INGRESA_RESTRINGIDO: 'Ingresa restringido a la zona administrativa', NO_INGRESA: 'No ingresa',
        SALE: 'Sale', SALE_RETIENE_ELEMENTO: 'Sale y se retiene el elemento'
    };

    function chip(texto, clase) { return el('span', { class: 'chip ' + clase, text: texto }); }
    function docTexto(p) { return (p.tipoDoc ? p.tipoDoc + ' ' : '') + (p.doc || ''); }

    // ── Lista ────────────────────────────────────────────────────────────────────────────────
    function pintarModos() {
        modos.textContent = '';
        [['HOY', 'Hoy'], ['APROBADAS', 'Aprobadas (todas las fechas)']].forEach(function (m) {
            modos.appendChild(el('button', { type: 'button', class: m[0] === modo ? 'on' : '', text: m[1], onclick: function () { cambiarModo(m[0]); } }));
        });
        var apr = modo === 'APROBADAS';
        document.getElementById('v-desde-c').hidden = !apr; document.getElementById('v-hasta-c').hidden = !apr;
        document.getElementById('v-aviso-apr').hidden = !apr;
    }

    function cambiarModo(m) {
        if (m === modo) return;
        modo = m; grupo = 'TODOS'; todas = []; panelNoAut.hidden = true;
        if (modo === 'APROBADAS' && !desde.value) desde.value = SOL.hoy();
        pintarModos(); cargar();
    }

    function cargar() {
        var mi = ++secuencia;
        var apr = modo === 'APROBADAS';
        var url = apr ? d.urlAprobadas + '?texto=' + encodeURIComponent(texto) + '&desde=' + desde.value + '&hasta=' + hasta.value : d.urlLista + '?texto=' + encodeURIComponent(texto);
        return CAF.pedir(url).then(function (r) {
            if (mi !== secuencia) return;
            if (!r.success) { CAF.aviso(r.message || 'No se pudo cargar.', 'warn'); return; }
            todas = r.data; hayLimite = !!r.limite;
            pintar();
            if (!apr && !todas.length && texto.trim().length >= 3) buscarNoAutorizada(mi); else panelNoAut.hidden = true;
        });
    }

    function buscarNoAutorizada(mi) {
        CAF.pedir(d.urlNoaut + '?texto=' + encodeURIComponent(texto)).then(function (r) {
            if (mi !== secuencia) return;
            panelNoAut.textContent = '';
            if (!r.success) { panelNoAut.hidden = true; return; }
            var caja = el('div', { class: 'noaut', role: 'alert' }, [el('strong', { text: 'No autorizado para hoy' })]);
            if (!r.data.length) {
                caja.appendChild(el('p', { text: 'No hay ninguna solicitud con esa persona o empresa. No debe ingresar.' }));
            } else {
                var ul = el('ul');
                r.data.forEach(function (n) {
                    ul.appendChild(el('li', { text: n.nombre + (n.doc ? ' (' + n.doc + ')' : '') + (n.empresa ? ' · ' + n.empresa : '') + ' · ' + n.codigo + ': ' + (n.motivo || n.motivoCodigo) }));
                });
                caja.appendChild(ul);
            }
            panelNoAut.appendChild(caja);
            panelNoAut.hidden = false;
        });
    }

    function cuenta(g) { return g === 'TODOS' ? todas.length : todas.filter(function (p) { return p.grupo === g; }).length; }

    function pintar() {
        pills.textContent = '';
        var soloLectura = modo === 'APROBADAS';
        pills.hidden = soloLectura;
        if (!soloLectura) GRUPOS.forEach(function (g) {
            pills.appendChild(el('button', { type: 'button', class: 'pill' + (grupo === g[0] ? ' on' : ''), text: g[1] + ' (' + cuenta(g[0]) + ')', onclick: function () { grupo = g[0]; pintar(); } }));
        });
        bloques.textContent = '';
        var visibles = soloLectura ? todas : todas.filter(function (p) { return grupo === 'TODOS' || p.grupo === grupo; });
        if (!visibles.length) {
            bloques.appendChild(el('section', { class: 'card' }, [el('p', { class: 'vacio', text: todas.length ? 'No hay personas en este grupo.' : (texto ? 'Nadie coincide con la búsqueda.' : (soloLectura ? 'No hay personas aprobadas en esas fechas.' : 'No hay personas autorizadas para hoy.')) })]));
            return;
        }
        var orden = [], por = {};
        visibles.forEach(function (p) { if (!por[p.solicitudId]) { por[p.solicitudId] = []; orden.push(p.solicitudId); } por[p.solicitudId].push(p); });
        orden.forEach(function (sid) {
            var l = por[sid], s = l[0];
            var exige = [s.exigeSctr ? 'SCTR' : null, s.exigeEpp ? 'EPP' : null].filter(Boolean).join(' y ');
            var cab = el('div', { class: 'blk-h' }, [
                el('div', {}, [el('strong', { text: s.empresa || '(sin empresa)' }), el('div', { class: 'field-h', text: s.codigo + ' · ' + (soloLectura ? 'visita ' + SOL.fechaLarga(s.fecha) + ' ' + s.hora : 'hora prevista ' + s.hora) + (s.atiende ? ' · atiende ' + s.atiende : '') })]),
                el('div', { class: 'vrow-e' }, [s.zonas ? el('span', { class: 'field-h', text: 'Zonas: ' + s.zonas }) : null, exige ? chip('Exige ' + exige, 'c-obs') : null])
            ]);
            var blk = el('section', { class: 'card blk' }, [cab]);
            l.forEach(function (p) { blk.appendChild(fila(p, soloLectura)); });
            bloques.appendChild(blk);
        });
        if (soloLectura && hayLimite) bloques.appendChild(el('div', { class: 'aviso a-warn', text: 'Se muestran las primeras 500 personas. Acote con la búsqueda o con las fechas.' }));
    }

    function fila(p, soloLectura) {
        var e = ESTADO[p.estado] || [p.estado, 'c-pend'];
        var tiempos = [];
        if (p.ingreso) tiempos.push('Ingresó ' + p.ingreso);
        if (p.salida) tiempos.push('Salió ' + p.salida);
        var botones = [];
        if (puede && !soloLectura && p.estado === 'ESPERADA') botones.push(el('button', { type: 'button', class: 'btn btn-sm btn-primary', text: 'Validar ingreso', onclick: function () { movimiento(p, 'INGRESO'); } }));
        if (puede && !soloLectura && p.estado === 'DENTRO') botones.push(el('button', { type: 'button', class: 'btn btn-sm btn-primary', text: 'Registrar salida', onclick: function () { movimiento(p, 'SALIDA'); } }));
        if (puedeInc && !soloLectura && (p.estado === 'DENTRO' || p.estado === 'SALIO')) botones.push(el('button', { type: 'button', class: 'btn btn-sm btn-danger', text: 'Registrar incidencia', onclick: function () {
            // El Coordinador registra en la pantalla única de Incidencias, con la persona ya elegida (queda confirmada directamente).
            if (d.esCoordinador === 'Y') { window.location.href = d.urlIncidencias + '?persona=' + encodeURIComponent(p.id) + '&nombre=' + encodeURIComponent(p.nombre); return; }
            INC.registrar({ opciones: d.urlIncOpciones, personas: d.urlIncPersonas, registrar: d.urlIncRegistrar }, false, { id: p.id, nombre: p.nombre }, function () { cargar(); });
        } }));
        if (p.estado !== 'ESPERADA') botones.push(el('button', { type: 'button', class: 'btn btn-sm', text: 'Detalle', onclick: function () { detalle(p); } }));
        return el('div', { class: 'vrow' }, [
            el('div', { class: 'vrow-n' }, [el('strong', { text: p.nombre }), el('span', { class: 'field-h', text: docTexto(p) })]),
            el('div', { class: 'vrow-e' }, [chip(e[0], e[1]),
                p.restringido ? chip('Restringido a zona administrativa', 'c-obs') : null,
                p.traeEquipos ? chip('Equipos', 'c-line') : null, p.traeHerramientas ? chip('Herramientas', 'c-line') : null,
                tiempos.length ? el('span', { class: 'field-h', text: tiempos.join(' · ') }) : null]),
            el('div', { class: 'vrow-e' }, botones)
        ]);
    }

    desde.addEventListener('change', cargar); hasta.addEventListener('change', cargar);
    cajaTexto.addEventListener('input', function () { clearTimeout(temporizador); temporizador = setTimeout(function () { texto = cajaTexto.value.trim(); cargar(); }, 300); });

    // ── Detalle de la persona ────────────────────────────────────────────────────────────────
    function detalle(p) {
        var cuerpo = el('div', { class: 'stack' }, [el('p', { class: 'vacio', text: 'Cargando...' })]);
        CAF.modal(p.nombre, cuerpo, [{ texto: 'Cerrar', onclick: function (c) { c(); } }], 'ancho');
        CAF.pedir(d.urlDetalle + '?id=' + p.id).then(function (r) {
            cuerpo.textContent = '';
            if (!r.success) { cuerpo.appendChild(el('p', { class: 'err', text: r.message || 'No se pudo cargar.' })); return; }
            cuerpo.appendChild(el('p', { class: 'field-h', text: docTexto(p) + ' · ' + (p.empresa || '') + ' · ' + p.codigo }));
            if (!r.data.length) { cuerpo.appendChild(el('p', { class: 'vacio', text: 'Todavía no tiene movimientos registrados.' })); return; }
            r.data.forEach(function (m) {
                var cab = el('div', { class: 'regbox-h' }, [
                    el('strong', { text: (m.tipo === 'INGRESO' ? 'Ingreso' : 'Salida') + ' · ' + m.hora }),
                    chip(RESULTADO[m.resultado] || m.resultado || '', m.resultado === 'NO_INGRESA' ? 'c-rec' : (m.resultado === 'INGRESA' || m.resultado === 'SALE' ? 'c-ok' : 'c-obs')),
                    m.tardio ? chip('Registro tardío', 'c-obs') : null, m.desviacion ? chip('Desviación ' + m.desviacion, 'c-obs') : null,
                    m.vigilante ? el('span', { class: 'field-h', text: 'Vigilante: ' + m.vigilante }) : null]);
                var ul = el('ul', { class: 'checks' });
                m.items.forEach(function (i) { ul.appendChild(el('li', { class: i.cumple ? 'ok' : 'no', text: (i.cumple ? '✓ ' : '✗ ') + i.texto })); });
                cuerpo.appendChild(el('div', { class: 'regbox' }, [cab, ul, m.observacion ? el('p', { class: 'field-h', text: 'Observación: ' + m.observacion }) : null]));
            });
        });
    }

    // ── Ingreso / salida ─────────────────────────────────────────────────────────────────────
    function movimiento(p, etapa) {
        var cuerpo = el('div', { class: 'stack' }, [el('p', { class: 'vacio', text: 'Cargando...' })]);
        var enviando = false, ctx = null;
        var m = CAF.modal((etapa === 'INGRESO' ? 'Validar ingreso · ' : 'Registrar salida · ') + p.nombre, cuerpo, [
            { texto: 'Cancelar', onclick: function (c) { c(); } },
            { texto: etapa === 'INGRESO' ? 'Registrar ingreso' : 'Registrar salida', tipo: 'primary', onclick: function (c) { if (ctx && !enviando) enviar(ctx, c, function (v) { enviando = v; }); } }
        ], 'ancho');
        CAF.pedir(d.urlFicha + '?id=' + p.id).then(function (r) {
            cuerpo.textContent = '';
            if (!r.success) { cuerpo.appendChild(el('p', { class: 'err', text: r.message || 'No se pudo cargar.' })); return; }
            ctx = armar(p, etapa, r.data, cuerpo);
        });
    }

    function armar(p, etapa, f, cuerpo) {
        var ingreso = etapa === 'INGRESO';
        var ctx = { p: p, f: f, etapa: etapa, items: [], resp: {}, equipos: f.traeEquipos, herramientas: f.traeHerramientas,
                    respEq: f.respaldoEquipos, respHe: f.respaldoHerramientas, error: el('p', { class: 'err', hidden: true, role: 'alert' }) };
        ctx.resp = {};

        var puedeNormal = ingreso ? f.puedeIngreso : f.puedeSalida;
        var motivo = ingreso ? f.motivoNoIngreso : f.motivoNoSalida;
        var puedeTardio = ingreso ? f.puedeIngresoTardio : f.puedeSalida;

        cuerpo.appendChild(el('p', { class: 'field-h', text: docTexto(p) + ' · ' + (f.empresa || '') + ' · ' + f.codigo + (f.zonas ? ' · Zonas: ' + f.zonas : '') }));
        if (f.exigeSctr || f.exigeEpp) cuerpo.appendChild(el('div', { class: 'aviso a-info', text: 'Esta visita exige ' + [f.exigeSctr ? 'SCTR' : null, f.exigeEpp ? 'EPP' : null].filter(Boolean).join(' y ') + '.' }));
        if (ingreso && f.restringido) cuerpo.appendChild(el('div', { class: 'aviso a-warn', text: 'Acceso restringido a la zona administrativa.' }));

        // Tardío
        var tardio = el('input', { type: 'checkbox' });
        var hora = el('input', { type: 'time' });
        ctx.tardio = tardio; ctx.hora = hora;
        var bloqueTardio = el('div', { class: 'sub-card', hidden: true }, [
            SOL.campo('Hora real del ' + (ingreso ? 'ingreso' : 'salida') + ' *', hora, 'Hora de hoy en que ocurrió. Debe explicar el motivo en la observación.')]);
        var modoTardio = false;

        if (!puedeNormal && !puedeTardio) {
            cuerpo.appendChild(el('div', { class: 'aviso a-warn', text: motivo || 'No se puede registrar este movimiento ahora.' }));
            ctx.bloqueado = true;
            return ctx;
        }
        if (!puedeNormal && puedeTardio) {
            cuerpo.appendChild(el('div', { class: 'aviso a-warn', text: (motivo || 'Fuera del horario normal.') + ' Solo puede registrarlo como registro tardío.' }));
            tardio.checked = true; tardio.disabled = true; modoTardio = true;
        }
        if (puedeNormal && puedeTardio) {
            cuerpo.appendChild(el('label', { class: 'chk' }, [tardio, el('span', { text: 'Es un registro tardío (indicar la hora real)' })]));
        }
        cuerpo.appendChild(bloqueTardio);
        function sincTardio() { bloqueTardio.hidden = !tardio.checked; }
        tardio.addEventListener('change', sincTardio); sincTardio();

        // Equipos y herramientas (solo ingreso)
        var zonaResp = el('div', { class: 'stack' });
        if (ingreso) {
            var tEq = el('input', { type: 'checkbox' }), tHe = el('input', { type: 'checkbox' });
            tEq.checked = ctx.equipos; tHe.checked = ctx.herramientas;
            cuerpo.appendChild(el('div', { class: 'chk-grid', style: null }, [
                el('label', { class: 'chk' + (ctx.equipos ? ' on' : '') }, [tEq, el('span', { text: 'Trae equipos (laptop, instrumentos)' })]),
                el('label', { class: 'chk' + (ctx.herramientas ? ' on' : '') }, [tHe, el('span', { text: 'Trae herramientas o materiales' })])
            ]));
            tEq.addEventListener('change', function () { ctx.equipos = tEq.checked; tEq.parentNode.classList.toggle('on', tEq.checked); pintarResp(); recargarChecklist(); });
            tHe.addEventListener('change', function () { ctx.herramientas = tHe.checked; tHe.parentNode.classList.toggle('on', tHe.checked); pintarResp(); recargarChecklist(); });
            cuerpo.appendChild(zonaResp);
        }

        function pintarResp() {
            zonaResp.textContent = '';
            if (ctx.equipos) zonaResp.appendChild(cajaRespaldo(ctx, 'EQUIPOS'));
            if (ctx.herramientas) zonaResp.appendChild(cajaRespaldo(ctx, 'HERRAMIENTAS_MATERIALES'));
        }
        pintarResp();

        // Checklist
        var zonaCheck = el('div', { class: 'stack' });
        cuerpo.appendChild(el('h4', { text: 'Checklist de ' + (ingreso ? 'ingreso' : 'salida') }));
        cuerpo.appendChild(zonaCheck);
        var zonaDesv = el('div');
        cuerpo.appendChild(zonaDesv);
        ctx.zonaDesv = zonaDesv;

        // Observación
        var obs = el('textarea', { rows: '2', maxlength: '1000', placeholder: 'Observación (obligatoria si es registro tardío)' });
        ctx.obs = obs;
        cuerpo.appendChild(SOL.campo('Observación', obs));
        cuerpo.appendChild(ctx.error);

        function pintarChecklist() {
            zonaCheck.textContent = '';
            if (!ctx.items.length) { zonaCheck.appendChild(el('p', { class: 'vacio', text: 'No hay ítems configurados.' })); return; }
            var todos = el('input', { type: 'checkbox' });
            todos.addEventListener('change', function () { ctx.items.forEach(function (i) { ctx.resp[i.id] = todos.checked; }); pintarChecklist(); sincDesv(); });
            zonaCheck.appendChild(el('label', { class: 'chk-all' }, [todos, el('span', { text: 'Marcar todo como cumplido' })]));
            var algunoNo = false, todosSi = true;
            ctx.items.forEach(function (i) {
                var cb = el('input', { type: 'checkbox' });
                cb.checked = ctx.resp[i.id] === true;
                if (!cb.checked) todosSi = false;
                cb.addEventListener('change', function () { ctx.resp[i.id] = cb.checked; pintarChecklist(); sincDesv(); });
                zonaCheck.appendChild(el('label', { class: 'chk' + (cb.checked ? ' on' : '') }, [cb, el('span', {}, [
                    el('span', { text: i.texto }), i.critico ? chip('Crítico', 'c-rec') : null, i.ayuda ? el('span', { class: 'field-h', text: ' ' + i.ayuda }) : null])]));
            });
            todos.checked = todosSi;
        }
        ctx.pintarChecklist = pintarChecklist;

        function recargarChecklist() {
            var q = '?id=' + p.id + '&etapa=' + etapa + '&equipos=' + (ctx.equipos ? 'true' : 'false') + '&herramientas=' + (ctx.herramientas ? 'true' : 'false');
            CAF.pedir(d.urlChecklist + q).then(function (r) {
                if (!r.success) { zonaCheck.textContent = ''; zonaCheck.appendChild(el('p', { class: 'err', text: r.message || 'No se pudo cargar el checklist.' })); return; }
                ctx.items = r.data;
                var nuevo = {};
                ctx.items.forEach(function (i) { nuevo[i.id] = ctx.resp[i.id] === true; });
                ctx.resp = nuevo;
                pintarChecklist(); sincDesv();
            });
        }
        recargarChecklist();

        // Desviación: aparece cuando algún ítem no se cumple
        function sincDesv() {
            var fallan = ctx.items.filter(function (i) { return ctx.resp[i.id] !== true; });
            ctx.fallan = fallan;
            if (!fallan.length) { zonaDesv.textContent = ''; ctx.desv = null; return; }
            if (ctx.desv) { ctx.desv.actualizar(fallan); return; }
            zonaDesv.textContent = '';
            zonaDesv.appendChild(el('p', { class: 'vacio', text: 'Cargando...' }));
            cargarOpDesv(etapa).then(function (op) {
                zonaDesv.textContent = '';
                if (!op) { zonaDesv.appendChild(el('p', { class: 'err', text: 'No se pudieron cargar las opciones de desviación.' })); return; }
                ctx.desv = bloqueDesviacion(etapa, op, zonaDesv);
                ctx.desv.actualizar(ctx.fallan || fallan);
            });
        }
        return ctx;
    }

    // Respaldo de equipos / herramientas
    function cajaRespaldo(ctx, categoria) {
        var eq = categoria === 'EQUIPOS';
        var ya = eq ? ctx.respEq : ctx.respHe;
        var caja = el('div', { class: 'regbox' });
        var titulo = eq ? 'Respaldo de equipos (formato G-FSCA-009)' : 'Respaldo de herramientas o materiales';
        caja.appendChild(el('div', { class: 'regbox-h' }, [el('strong', { text: titulo }), ya ? chip('Registrado', 'c-ok') : chip('Falta registrar', 'c-obs')]));
        if (ya) return caja;
        var tipo = el('select');
        if (eq) tipo.appendChild(el('option', { value: 'G_FSCA_009', text: 'Formato G-FSCA-009' }));
        else { tipo.appendChild(el('option', { value: 'GUIA_REMISION', text: 'Guía de remisión' })); tipo.appendChild(el('option', { value: 'GUIA_MANUAL_G_FSCA_010', text: 'Guía manual G-FSCA-010' })); }
        var num = el('input', { type: 'text', maxlength: '50', autocomplete: 'off', placeholder: 'Serie y número de la guía' });
        var campoNum = SOL.campo('Número de la guía de remisión *', num);
        var obs = el('input', { type: 'text', maxlength: '500', autocomplete: 'off', placeholder: 'Observación (opcional)' });
        var err = el('p', { class: 'err', hidden: true });
        function sinc() { campoNum.hidden = tipo.value !== 'GUIA_REMISION'; }
        tipo.addEventListener('change', sinc); sinc();
        var btn = el('button', { type: 'button', class: 'btn btn-sm btn-primary', text: 'Registrar respaldo' });
        btn.addEventListener('click', function () {
            btn.disabled = true; err.hidden = true;
            CAF.pedir(d.urlRespaldo, { method: 'POST', body: { categoria: categoria, tipo: tipo.value, numero: tipo.value === 'GUIA_REMISION' ? num.value : null, personasIds: [ctx.p.id], observacion: obs.value } }).then(function (r) {
                btn.disabled = false;
                if (!r.success) { err.textContent = SOL.errores(r); err.hidden = false; return; }
                if (eq) ctx.respEq = true; else ctx.respHe = true;
                CAF.aviso('Respaldo registrado.');
                var nuevo = cajaRespaldo(ctx, categoria);
                caja.parentNode.replaceChild(nuevo, caja);
            });
        });
        [SOL.campo('Tipo de respaldo', tipo), campoNum, SOL.campo('Observación', obs), err, el('div', {}, [btn])].forEach(function (x) { caja.appendChild(x); });
        return caja;
    }

    function cargarOpDesv(etapa) {
        if (opDesv[etapa]) return Promise.resolve(opDesv[etapa]);
        return CAF.pedir(d.urlOpdesv + '?etapa=' + etapa).then(function (r) { if (!r.success) { CAF.aviso(r.message || 'No se pudieron cargar las opciones.', 'warn'); return null; } opDesv[etapa] = r.data; return r.data; });
    }

    // Bloque «Desviación»: qué falló, coordinador consultado, tratamiento (y efecto si es «Otro»).
    function bloqueDesviacion(etapa, op, cont) {
        var ingreso = etapa === 'INGRESO';
        var desc = el('textarea', { rows: '2', maxlength: '2000', placeholder: 'Qué no se cumplió y qué ocurrió' });
        var coord = el('select'); coord.appendChild(el('option', { value: '', text: 'Elija al Coordinador consultado' }));
        op.coordinadores.forEach(function (c) { coord.appendChild(el('option', { value: String(c.id), text: c.texto })); });
        var trat = el('select');
        var detalle = el('input', { type: 'text', maxlength: '500', autocomplete: 'off', placeholder: 'En qué consiste el tratamiento' });
        var efecto = el('select');
        var efectos = ingreso ? ['INGRESA', 'INGRESA_RESTRINGIDO', 'NO_INGRESA'] : ['SALE', 'SALE_RETIENE_ELEMENTO'];
        var campoDetalle = SOL.campo('Detalle del tratamiento «Otro» *', detalle);
        var campoEfecto = SOL.campo('Efecto *', efecto);
        var resultado = el('p', { class: 'field-h' });
        var nota = el('p', { class: 'field-h', hidden: true });
        var caja = el('div', { class: 'desv' }, [el('h4', { text: 'Desviación: hay ítems sin cumplir' }), nota,
            SOL.campo('Descripción *', desc), SOL.campo('Coordinador consultado *', coord), SOL.campo('Tratamiento *', trat), campoDetalle, campoEfecto, resultado]);
        cont.appendChild(caja);
        var critico = false;

        function tratamientoActual() { return op.tratamientos.filter(function (t) { return String(t.id) === trat.value; })[0]; }
        function llenarTrat() {
            var previo = trat.value;
            trat.textContent = '';
            trat.appendChild(el('option', { value: '', text: 'Elija el tratamiento' }));
            op.tratamientos.forEach(function (t) {
                // Con un ítem crítico (identidad) solo cabe denegar el ingreso.
                if (critico && !t.esOtro && t.resultado !== 'NO_INGRESA') return;
                trat.appendChild(el('option', { value: String(t.id), text: t.texto }));
            });
            trat.value = previo;
            if (trat.value !== previo) trat.value = '';
            efecto.textContent = '';
            (critico ? ['NO_INGRESA'] : efectos).forEach(function (x) { efecto.appendChild(el('option', { value: x, text: RESULTADO[x] })); });
        }
        function sinc() {
            var t = tratamientoActual();
            var otro = !!(t && t.esOtro);
            campoDetalle.hidden = !otro; campoEfecto.hidden = !otro;
            resultado.textContent = t ? 'Resultado: ' + (otro ? RESULTADO[efecto.value] : (RESULTADO[t.resultado] || t.resultado || '')) : '';
        }
        trat.addEventListener('change', sinc); efecto.addEventListener('change', sinc);
        llenarTrat(); sinc();

        return {
            actualizar: function (fallan) {
                var c = fallan.some(function (i) { return i.critico; });
                nota.hidden = !c;
                nota.textContent = c ? 'Un ítem crítico (identidad) no se cumple: solo corresponde denegar el ingreso.' : '';
                if (c !== critico) { critico = c; llenarTrat(); }
                sinc();
            },
            valores: function () {
                var t = tratamientoActual();
                return { descripcion: desc.value, coordinadorId: coord.value ? Number(coord.value) : null, tratamientoId: trat.value ? Number(trat.value) : null,
                         tratamientoDetalle: t && t.esOtro ? detalle.value : null, resultadoElegido: t && t.esOtro ? efecto.value : null };
            }
        };
    }

    function enviar(ctx, cerrar, marcar) {
        if (ctx.bloqueado) { cerrar(); return; }
        var ingreso = ctx.etapa === 'INGRESO';
        ctx.error.hidden = true;
        function falla(t) { ctx.error.textContent = t; ctx.error.hidden = false; }
        if (!ctx.items.length) { falla('No hay ítems de checklist para responder.'); return; }
        var tardio = ctx.tardio.checked;
        if (tardio && !ctx.hora.value) { falla('Indique la hora real.'); return; }
        if (tardio && !ctx.obs.value.trim()) { falla('Explique por qué el registro es tardío.'); return; }
        if (ctx.fallan && ctx.fallan.length && !ctx.desv) { falla('Espere a que se carguen las opciones de la desviación.'); return; }
        var cuerpo = {
            personaId: ctx.p.id, traeEquipos: ingreso ? ctx.equipos : false, traeHerramientas: ingreso ? ctx.herramientas : false,
            items: ctx.items.map(function (i) { return { id: i.id, cumple: ctx.resp[i.id] === true }; }),
            observacion: ctx.obs.value, horaReal: tardio ? ctx.hora.value : null,
            desviacion: ctx.fallan && ctx.fallan.length && ctx.desv ? ctx.desv.valores() : null
        };
        marcar(true);
        CAF.pedir(ingreso ? d.urlIngreso : d.urlSalida, { method: 'POST', body: cuerpo }).then(function (r) {
            marcar(false);
            if (!r.success) { falla(SOL.errores(r)); return; }
            cerrar();
            CAF.aviso(r.message || 'Registrado.');
            cargar();
        });
    }

    pintarModos();
    cargar();
})();

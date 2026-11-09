// Control de accesos (Vigilancia): personas autorizadas hoy por solicitud, ingreso y salida con checklist,
// respaldo de equipos/herramientas, desviación cuando un ítem no se cumple, registro tardío y detalle por persona.
// Las reglas viven en los procedimientos; aquí solo se muestran y se envía lo que Vigilancia marcó.
(function () {
    'use strict';
    var raiz = document.getElementById('caf-vig');
    if (!raiz) return;
    var el = CAF.el, d = raiz.dataset, puede = d.puedeRegistrar === 'Y', puedeInc = d.puedeIncidencia === 'Y', puedeProv = d.puedeProveedor === 'Y';
    var todas = [], brutas = [], grupo = 'TODOS', texto = '', temporizador = null, secuencia = 0, modo = 'HOY', hayLimite = false;
    var modos = document.getElementById('v-modos'), desde = document.getElementById('v-desde'), hasta = document.getElementById('v-hasta');
    var cajaTexto = document.getElementById('v-texto'), pills = document.getElementById('v-pills');
    var panelNoAut = document.getElementById('v-noaut'), bloques = document.getElementById('v-bloques');
    var opDesv = {}, sel = {};   // sel: personas marcadas para una acción en grupo (D-225), por id de persona

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
    // Filtro por tipo de solicitud (solo en pantalla): `brutas` es lo que llegó, `todas` lo que pasa el filtro.
    var ftipos = SOL.filtroTipos('vigilancia', cajaTexto.closest('section') || cajaTexto.parentNode, function () { aplicarTipos(); });
    function aplicarTipos() { todas = brutas.filter(function (p) { return ftipos.pasa(p.tipo); }); pintar(); }

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
        modo = m; grupo = 'TODOS'; todas = []; brutas = []; panelNoAut.hidden = true;
        if (modo === 'APROBADAS' && !desde.value) desde.value = SOL.hoy();
        pintarModos(); cargar();
    }

    function cargar(silencioso) {
        var mi = ++secuencia;
        var apr = modo === 'APROBADAS';
        var url = apr ? d.urlAprobadas + '?texto=' + encodeURIComponent(texto) + '&desde=' + desde.value + '&hasta=' + hasta.value : d.urlLista + '?texto=' + encodeURIComponent(texto);
        return CAF.pedir(url).then(function (r) {
            if (mi !== secuencia) return;
            if (!r.success) { if (!silencioso) CAF.aviso(r.message || 'No se pudo cargar.', 'warn'); return; }
            brutas = r.data; hayLimite = !!r.limite;
            ftipos.registrar(brutas.map(function (p) { return p.tipo; }));
            aplicarTipos();
            if (!apr && !brutas.length && texto.trim().length >= 3) buscarNoAutorizada(mi); else panelNoAut.hidden = true;
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
        // La selección solo conserva a quienes siguen en la lista (la lista se refresca sola).
        var vivos = {}; todas.forEach(function (x) { vivos[x.id] = true; });
        Object.keys(sel).forEach(function (k) { if (!vivos[k]) delete sel[k]; });
        orden.forEach(function (sid) {
            var l = por[sid], s = l[0];
            var exige = [s.exigeSctr ? 'SCTR' : null, s.exigeEpp ? 'EPP' : null].filter(Boolean).join(' y ');
            var cab = el('div', { class: 'blk-h' }, [
                el('div', {}, [el('strong', { text: s.empresa || '(sin empresa)' }), el('div', { class: 'field-h', text: s.codigo + ' · ' + (soloLectura ? 'visita ' + SOL.fechaLarga(s.fecha) + ' ' + s.hora : 'hora prevista ' + s.hora) + (s.atiende ? ' · atiende ' + s.atiende : '') })]),
                el('div', { class: 'vrow-e' }, [s.zonas ? el('span', { class: 'field-h', text: 'Zonas: ' + s.zonas }) : null, exige ? chip('Exige ' + exige, 'c-obs') : null,
                    el('button', { type: 'button', class: 'btn btn-sm', text: 'Documentos', onclick: function () { documentos(s); } })])
            ]);
            var blk = el('section', { class: 'card blk' }, [cab]);
            if (!soloLectura && s.esProveedor) blk.appendChild(barraGrupo(s, todas.filter(function (x) { return x.solicitudId === s.solicitudId; })));
            l.forEach(function (p) { blk.appendChild(fila(p, soloLectura)); });
            bloques.appendChild(blk);
        });
        if (soloLectura && hayLimite) bloques.appendChild(el('div', { class: 'aviso a-warn', text: 'Se muestran las primeras 500 personas. Acote con la búsqueda o con las fechas.' }));
    }

    // Documentos adjuntos de la solicitud (Entrega J): disponibles desde la primera persona aprobada.
    function documentos(s) {
        CAF.modal('Documentos · ' + s.codigo, ADJ.panel({ solicitudId: s.solicitudId, urlListar: d.urlAdj, puedeAdjuntar: false, titulo: 'Documentos de la solicitud' }).nodo, [{ texto: 'Cerrar', onclick: function (c) { c(); } }], 'ancho');
    }

    function fila(p, soloLectura) {
        var e = ESTADO[p.estado] || [p.estado, 'c-pend'];
        var tiempos = [];
        if (p.ingreso) tiempos.push('Ingresó ' + p.ingreso);
        if (p.salida) tiempos.push('Salió ' + p.salida);
        var botones = [], prov = p.esProveedor && !soloLectura, op = p.estadoOp, extra = null, selector = null;
        if (prov) {
            // D-225: cada persona tiene su propio estado. Verificar datos → (Almacén confirma una vez) → Registrar ingreso → ... → Registrar salida.
            // Verificar datos es el checklist del ingreso normal; Registrar ingreso y Retiró sin ingresar solo existen aquí.
            var grp = todas.filter(function (x) { return x.solicitudId === p.solicitudId; });
            var activa = op === 'EN_ESPERA' || op === 'INGRESO' || op === 'EN_ATENCION';
            if (p.estado === 'ESPERADA') {
                if (puede && (activa || op === 'PROGRAMADO') && !p.verificada) botones.push(el('button', { type: 'button', class: 'btn btn-sm btn-primary', text: 'Verificar datos', onclick: function () { movimiento(p, 'INGRESO', true); } }));
                if (p.verificada && activa && puedeProv) {
                    var bv = el('button', { type: 'button', class: 'btn btn-sm btn-primary', text: 'Registrar ingreso' });
                    if (p.almacenListo) bv.addEventListener('click', function () { registrarIngreso([p]); }); else { bv.disabled = true; bv.classList.add('is-off'); bv.title = 'Almacén aún no confirmó su disponibilidad'; }
                    botones.push(bv);
                    botones.push(el('button', { type: 'button', class: 'btn btn-sm', text: 'Retiró sin ingresar', onclick: function () { retiroPersonas([p]); } }));
                }
                extra = !p.verificada ? chip('Datos por verificar', 'c-pend')
                    : chip(p.almacenListo ? 'Verificado · Almacén listo' : 'Verificado · esperando a Almacén', p.almacenListo ? 'c-ok' : 'c-obs');
            } else if (p.estado === 'DENTRO') {
                if (op === 'INGRESO') extra = chip('Dentro · espera atención de Almacén', 'c-obs');
                else if (op === 'EN_ATENCION') extra = chip('En atención de Almacén', 'c-obs');
                else if (op === 'RECEPCIONADO') extra = chip('Recepción culminada · falta su salida', 'c-par');
                else if (op === 'CIERRE_FORZADO') extra = chip('Cerrada por el sistema · falta registrar su salida', 'c-rec');
                else if (salidaProveedor(p, grp)) extra = chip('Puede salir para dar paso al siguiente vehículo', 'c-par');
            } else if (p.estado === 'NO_SE_PRESENTO') extra = chip(op === 'RETIRO_SIN_INGRESO' ? 'Se retiró sin ingresar' : 'No ingresó', 'c-can');
            var cb = el('input', { type: 'checkbox', 'aria-label': 'Seleccionar a ' + p.nombre });
            cb.checked = !!sel[p.id];
            cb.addEventListener('change', function () { if (cb.checked) sel[p.id] = true; else delete sel[p.id]; pintar(); });
            selector = el('label', { class: 'vsel' }, [cb]);
        }
        if (!prov && puede && !soloLectura && p.estado === 'ESPERADA') botones.push(el('button', { type: 'button', class: 'btn btn-sm btn-primary', text: 'Validar ingreso', onclick: function () { movimiento(p, 'INGRESO'); } }));
        if (puede && !soloLectura && p.estado === 'DENTRO' && (!p.esProveedor || salidaProveedor(p, todas.filter(function (x) { return x.solicitudId === p.solicitudId; })))) botones.push(el('button', { type: 'button', class: 'btn btn-sm btn-primary', text: p.estadoOp === 'CIERRE_FORZADO' ? 'Registrar salida (tardía)' : 'Registrar salida', onclick: function () { movimiento(p, 'SALIDA'); } }));
        if (puedeInc && !soloLectura && (p.estado === 'DENTRO' || p.estado === 'SALIO')) botones.push(el('button', { type: 'button', class: 'btn btn-sm btn-danger', text: 'Registrar incidencia', onclick: function () {
            // El Coordinador registra en la pantalla única de Incidencias, con la persona ya elegida (queda confirmada directamente).
            if (d.esCoordinador === 'Y') { window.location.href = d.urlIncidencias + '?persona=' + encodeURIComponent(p.id) + '&nombre=' + encodeURIComponent(p.nombre); return; }
            INC.registrar({ opciones: d.urlIncOpciones, personas: d.urlIncPersonas, registrar: d.urlIncRegistrar }, false, { id: p.id, nombre: p.nombre }, function () { cargar(); });
        } }));
        if (p.estado !== 'ESPERADA') botones.push(el('button', { type: 'button', class: 'btn btn-sm', text: 'Detalle', onclick: function () { detalle(p); } }));
        return el('div', { class: 'vrow' }, [
            el('div', { class: 'vrow-n' + (selector ? ' con-sel' : '') }, [selector, el('div', { class: 'vrow-t' }, [el('strong', { text: p.nombre }), el('span', { class: 'field-h', text: docTexto(p) + (prov ? ' · ' + (p.esTransportista ? 'Transportista' : 'Ayudante de descarga') : '') })])]),
            el('div', { class: 'vrow-e' }, [chip(e[0], e[1]), p.franja && p.franja !== 'NA' ? chip(p.franja === 'FUERA' ? 'Fuera de franja' : 'Franja de días', p.franja === 'FUERA' ? 'c-obs' : 'c-line') : null,
                extra,
                p.restringido ? chip('Restringido a zona administrativa', 'c-obs') : null,
                p.traeEquipos ? chip('Equipos', 'c-line') : null, p.traeHerramientas ? chip('Herramientas', 'c-line') : null,
                tiempos.length ? el('span', { class: 'field-h', text: tiempos.join(' · ') }) : null]),
            el('div', { class: 'vrow-e' }, botones)
        ]);
    }

    // ── Proveedor: varias personas por entrega (D-225) ───────────────────────────────────────
    // ¿Puede salir ya esta persona que está dentro? Tras la recepción sí; antes, solo para dar paso si aún faltan transportistas por ingresar.
    function salidaProveedor(p, grp) {
        if (p.estado !== 'DENTRO') return false;
        var op = p.estadoOp;
        if (op === 'RECEPCIONADO' || op === 'CIERRE_FORZADO') return true;
        return (op === 'INGRESO' || op === 'EN_ATENCION') && grp.some(function (x) { return x.esTransportista && x.estado === 'ESPERADA'; });
    }
    function esVerificable(p) { var o = p.estadoOp; return p.estado === 'ESPERADA' && !p.verificada && (o === 'PROGRAMADO' || o === 'EN_ESPERA' || o === 'INGRESO' || o === 'EN_ATENCION'); }
    function esIngresable(p) { var o = p.estadoOp; return p.estado === 'ESPERADA' && p.verificada && (o === 'EN_ESPERA' || o === 'INGRESO' || o === 'EN_ATENCION'); }

    // Barra de la entrega: contadores, selección por rol y acciones sobre lo marcado (un solo checklist para todos los marcados).
    function barraGrupo(s, l) {
        var tr = l.filter(function (x) { return x.esTransportista; }), ay = l.filter(function (x) { return !x.esTransportista; });
        function n(arr, f) { return arr.filter(f).length; }
        var marcadas = l.filter(function (x) { return sel[x.id]; });
        var cont = el('div', { class: 'vrow-e vbar-c' }, [
            chip('Transportistas: verificados ' + n(tr, function (x) { return x.verificada; }) + '/' + tr.length + ' · dentro ' + n(tr, function (x) { return x.estado === 'DENTRO'; }) +
                (n(tr, function (x) { return x.estado === 'SALIO'; }) ? ' · salieron ' + n(tr, function (x) { return x.estado === 'SALIO'; }) : ''), 'c-line'),
            ay.length ? chip('Ayudantes de descarga: ' + ay.length + ' · dentro ' + n(ay, function (x) { return x.estado === 'DENTRO'; }), 'c-line') : null]);
        function marcar(f) { l.forEach(function (x) { if (f(x)) sel[x.id] = true; else delete sel[x.id]; }); pintar(); }
        var seleccion = el('div', { class: 'vrow-e' }, [el('span', { class: 'field-h', text: 'Marcar:' }),
            el('button', { type: 'button', class: 'btn btn-sm', text: 'Transportistas', onclick: function () { marcar(function (x) { return x.esTransportista; }); } }),
            ay.length ? el('button', { type: 'button', class: 'btn btn-sm', text: 'Ayudantes', onclick: function () { marcar(function (x) { return !x.esTransportista; }); } }) : null,
            el('button', { type: 'button', class: 'btn btn-sm', text: 'Todos', onclick: function () { marcar(function () { return true; }); } }),
            marcadas.length ? el('button', { type: 'button', class: 'btn btn-sm', text: 'Ninguno', onclick: function () { marcar(function () { return false; }); } }) : null]);
        var acc = [];
        if (marcadas.length) {
            var t = ' (' + marcadas.length + ')';
            var todos = function (f) { return marcadas.every(f); };
            if (puede && todos(esVerificable)) acc.push(el('button', { type: 'button', class: 'btn btn-sm btn-primary', text: 'Verificar datos' + t, onclick: function () { checklistGrupo('INGRESO', s, marcadas); } }));
            if (puedeProv && todos(esIngresable)) {
                var bi = el('button', { type: 'button', class: 'btn btn-sm btn-primary', text: 'Registrar ingreso' + t });
                if (marcadas[0].almacenListo) bi.addEventListener('click', function () { registrarIngreso(marcadas); }); else { bi.disabled = true; bi.classList.add('is-off'); bi.title = 'Almacén aún no confirmó su disponibilidad'; }
                acc.push(bi);
                acc.push(el('button', { type: 'button', class: 'btn btn-sm', text: 'Retiró sin ingresar' + t, onclick: function () { retiroPersonas(marcadas); } }));
            }
            if (puede && todos(function (x) { return salidaProveedor(x, l); })) acc.push(el('button', { type: 'button', class: 'btn btn-sm btn-primary', text: 'Registrar salida' + t, onclick: function () { checklistGrupo('SALIDA', s, marcadas); } }));
            if (!acc.length) acc.push(el('span', { class: 'field-h', text: 'Los marcados están en pasos distintos: marque solo a quienes estén en el mismo paso.' }));
        }
        return el('div', { class: 'vbar' }, [cont, seleccion, acc.length ? el('div', { class: 'vrow-e' }, acc) : null]);
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
    // Proveedor: ingreso físico (Almacén ya reservó la exclusa) y retiro sin ingresar. Cada acción la vuelve a validar la base de datos.
    function accionProveedor(url, cuerpo, cerrar) {
        return CAF.pedir(url, { method: 'POST', body: cuerpo }).then(function (r) {
            if (r.success) { CAF.aviso(r.message || 'Listo.'); cerrar(); } else CAF.aviso(r.message || 'No se pudo completar la acción.', 'warn');
            return cargar();
        });
    }
    function nombres(personas) {
        var ul = el('ul', { class: 'vlista' });
        personas.forEach(function (x) { ul.appendChild(el('li', { text: x.nombre + ' · ' + (x.esTransportista ? 'Transportista' : 'Ayudante de descarga') })); });
        return ul;
    }
    function ids(personas) { return personas.map(function (x) { return x.id; }); }
    function listo(personas) { personas.forEach(function (x) { delete sel[x.id]; }); }

    function registrarIngreso(personas) {
        var env = false;
        CAF.modal('Registrar ingreso · ' + personas.length + ' persona(s)', el('div', { class: 'stack' }, [
            el('p', { text: 'Confirme que ya ingresaron físicamente. Los ayudantes ingresan con su transportista. Almacén los atenderá desde la esclusa reservada; si el cupo de la esclusa está lleno, deberá esperar la salida del vehículo anterior.' }), nombres(personas)]), [
            { texto: 'Cancelar', onclick: function (c) { c(); } },
            { texto: 'Confirmar ingreso', tipo: 'primary', onclick: function (c) { if (env) return; env = true; accionProveedor(d.urlIngresoFisico, { solicitudId: personas[0].solicitudId, personasIds: ids(personas) }, function () { listo(personas); c(); }).then(function () { env = false; }); } }
        ]);
    }
    function retiroPersonas(personas) {
        var mot = el('textarea', { rows: '3', maxlength: '500', placeholder: 'Ej.: se fue por la demora' }), err = el('span', { class: 'field-e' }), env = false;
        var cuerpo = el('div', { class: 'stack' }, [
            el('p', { text: 'Ya fueron verificados pero se retiran sin ingresar. Si no queda ningún transportista por ingresar, la entrega termina y se libera la esclusa que Almacén tenía reservada.' }), nombres(personas),
            el('label', { class: 'field' }, [el('span', { class: 'field-l', text: 'Motivo (obligatorio)' }), mot, err])
        ]);
        CAF.modal('Retiró sin ingresar · ' + personas.length + ' persona(s)', cuerpo, [
            { texto: 'Volver', onclick: function (c) { c(); } },
            { texto: 'Registrar retiro', tipo: 'primary', onclick: function (c) {
                if (env) return;
                if (mot.value.trim().length < 3) { err.textContent = 'Indique el motivo del retiro.'; mot.focus(); return; }
                env = true; accionProveedor(d.urlRetiroPersonas, { solicitudId: personas[0].solicitudId, personasIds: ids(personas), motivo: mot.value.trim() }, function () { listo(personas); c(); }).then(function () { env = false; });
            } }
        ]);
    }

    // Ítems de la selección: la unión de los de cada rol (la placa y la documentación de la carga solo aplican a transportistas).
    function itemsUnion(etapa, personas) {
        var reps = [], vistos = {};
        personas.forEach(function (x) { var k = x.esTransportista ? 'T' : 'A'; if (!vistos[k]) { vistos[k] = true; reps.push({ k: k, p: x }); } });
        var eq = etapa === 'SALIDA' && personas.some(function (x) { return x.traeEquipos; }), he = etapa === 'SALIDA' && personas.some(function (x) { return x.traeHerramientas; });
        return Promise.all(reps.map(function (r) {
            return CAF.pedir(d.urlChecklist + '?id=' + r.p.id + '&etapa=' + etapa + '&equipos=' + eq + '&herramientas=' + he).then(function (res) { return { k: r.k, res: res }; });
        })).then(function (lista) {
            var mapa = {}, orden = [], error = null;
            lista.forEach(function (x) {
                if (!x.res.success) { error = x.res.message || 'No se pudo cargar el checklist.'; return; }
                x.res.data.forEach(function (i) { if (!mapa[i.id]) { mapa[i.id] = { id: i.id, texto: i.texto, ayuda: i.ayuda, critico: i.critico, roles: {} }; orden.push(i.id); } mapa[i.id].roles[x.k] = true; });
            });
            return { error: error, items: orden.map(function (id) { return mapa[id]; }), mixto: reps.length > 1 };
        });
    }

    // Verificar datos o registrar salida de varias personas con UN solo checklist; las respuestas se guardan por persona.
    function checklistGrupo(etapa, s, personas) {
        var ingreso = etapa === 'INGRESO', enviando = false, ctx = null;
        var cuerpo = el('div', { class: 'stack' }, [el('p', { class: 'vacio', text: 'Cargando...' })]);
        CAF.modal((ingreso ? 'Verificar datos · ' : 'Registrar salida · ') + personas.length + ' persona(s)', cuerpo, [
            { texto: 'Cancelar', onclick: function (c) { c(); } },
            { texto: ingreso ? 'Registrar verificación' : 'Registrar salida', tipo: 'primary', onclick: function (c) { if (ctx && !enviando) enviarGrupo(ctx, c, function (v) { enviando = v; }); } }
        ], 'ancho');
        itemsUnion(etapa, personas).then(function (u) {
            cuerpo.textContent = '';
            if (u.error) { cuerpo.appendChild(el('p', { class: 'err', text: u.error })); return; }
            ctx = { etapa: etapa, s: s, personas: personas, items: u.items, resp: {}, error: el('p', { class: 'err', hidden: true, role: 'alert' }), desv: null };
            cuerpo.appendChild(el('p', { class: 'field-h', text: (s.empresa || '') + ' · ' + s.codigo }));
            cuerpo.appendChild(nombres(personas));
            cuerpo.appendChild(el('div', { class: 'aviso a-info', text: 'Un solo checklist para todos los marcados.' + (u.mixto ? ' Los ítems que dicen «Solo transportistas» se exigen únicamente a ellos.' : '') +
                (ingreso ? ' Si alguien no cumple, ciérrelo y verifíquelo aparte para que la desviación sea solo suya. Quien trae equipos o herramientas debe verificarse de forma individual.' : '') }));
            var zonaCheck = el('div', { class: 'stack' }), zonaDesv = el('div');
            cuerpo.appendChild(el('h4', { text: 'Checklist de ' + (ingreso ? 'ingreso' : 'salida') }));
            cuerpo.appendChild(zonaCheck); cuerpo.appendChild(zonaDesv);
            ctx.obs = el('textarea', { rows: '2', maxlength: '1000', placeholder: 'Observación (opcional)' });
            cuerpo.appendChild(SOL.campo('Observación', ctx.obs)); cuerpo.appendChild(ctx.error);
            if (!ctx.items.length) { zonaCheck.appendChild(el('p', { class: 'vacio', text: 'No hay ítems configurados.' })); return; }
            u.items.forEach(function (i) { ctx.resp[i.id] = false; });
            function pintar2() {
                zonaCheck.textContent = '';
                var todosCb = el('input', { type: 'checkbox' });
                todosCb.addEventListener('change', function () { ctx.items.forEach(function (i) { ctx.resp[i.id] = todosCb.checked; }); pintar2(); sinc(); });
                zonaCheck.appendChild(el('label', { class: 'chk-all' }, [todosCb, el('span', { text: 'Marcar todo como cumplido' })]));
                var todosSi = true;
                ctx.items.forEach(function (i) {
                    var cb = el('input', { type: 'checkbox' });
                    cb.checked = ctx.resp[i.id] === true; if (!cb.checked) todosSi = false;
                    cb.addEventListener('change', function () { ctx.resp[i.id] = cb.checked; pintar2(); sinc(); });
                    var solo = u.mixto && !(i.roles.T && i.roles.A) ? chip(i.roles.T ? 'Solo transportistas' : 'Solo ayudantes', 'c-line') : null;
                    zonaCheck.appendChild(el('label', { class: 'chk' + (cb.checked ? ' on' : '') }, [cb, el('span', {}, [el('span', { text: i.texto }), i.critico ? chip('Crítico', 'c-rec') : null, solo, i.ayuda ? el('span', { class: 'field-h', text: ' ' + i.ayuda }) : null])]));
                });
                todosCb.checked = todosSi;
            }
            function sinc() {
                var fallan = ctx.items.filter(function (i) { return ctx.resp[i.id] !== true; });
                ctx.fallan = fallan;
                if (!fallan.length) { zonaDesv.textContent = ''; ctx.desv = null; return; }
                if (ctx.desv) { ctx.desv.actualizar(fallan); return; }
                zonaDesv.textContent = ''; zonaDesv.appendChild(el('p', { class: 'vacio', text: 'Cargando...' }));
                cargarOpDesv(etapa).then(function (op) {
                    zonaDesv.textContent = '';
                    if (!op) { zonaDesv.appendChild(el('p', { class: 'err', text: 'No se pudieron cargar las opciones de desviación.' })); return; }
                    ctx.desv = bloqueDesviacion(etapa, op, zonaDesv); ctx.desv.actualizar(ctx.fallan || fallan);
                });
            }
            pintar2(); sinc();
        });
    }
    function enviarGrupo(ctx, cerrar, marcar) {
        var ingreso = ctx.etapa === 'INGRESO';
        ctx.error.hidden = true;
        function falla(t) { ctx.error.textContent = t; ctx.error.hidden = false; }
        if (!ctx.items.length) { falla('No hay ítems de checklist para responder.'); return; }
        if (ctx.fallan && ctx.fallan.length && !ctx.desv) { falla('Espere a que se carguen las opciones de la desviación.'); return; }
        var cuerpo = {
            solicitudId: ctx.s.solicitudId, personasIds: ids(ctx.personas),
            items: ctx.items.map(function (i) { return { id: i.id, cumple: ctx.resp[i.id] === true }; }),
            observacion: ctx.obs.value, desviacion: ctx.fallan && ctx.fallan.length && ctx.desv ? ctx.desv.valores() : null
        };
        marcar(true);
        CAF.pedir(ingreso ? d.urlVerificarGrupo : d.urlSalidaGrupo, { method: 'POST', body: cuerpo }).then(function (r) {
            marcar(false);
            if (!r.success) { falla(r.message || 'No se pudo registrar.'); return; }
            listo(ctx.personas); cerrar(); CAF.aviso(r.message || 'Registrado.'); cargar();
        });
    }

    function movimiento(p, etapa, verificacion) {
        var cuerpo = el('div', { class: 'stack' }, [el('p', { class: 'vacio', text: 'Cargando...' })]);
        var enviando = false, ctx = null;
        var m = CAF.modal((etapa === 'INGRESO' ? (verificacion ? 'Verificar datos · ' : 'Validar ingreso · ') : 'Registrar salida · ') + p.nombre, cuerpo, [
            { texto: 'Cancelar', onclick: function (c) { c(); } },
            { texto: etapa === 'INGRESO' ? (verificacion ? 'Registrar verificación' : 'Registrar ingreso') : 'Registrar salida', tipo: 'primary', onclick: function (c) { if (ctx && !enviando) enviar(ctx, c, function (v) { enviando = v; }); } }
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
        tardio.addEventListener('change', function () { if (ctx.items && ctx.items.length >= 0) sincDesv(); });
        var bloqueTardio = el('div', { class: 'sub-card', hidden: true }, [
            SOL.campo('Hora real del ' + (ingreso ? 'ingreso' : 'salida') + ' *', hora, 'Hora de hoy en que ocurrió. Debe explicar el motivo en la observación.')]);
        var modoTardio = false;

        if (!puedeNormal && !puedeTardio) {
            cuerpo.appendChild(el('div', { class: 'aviso a-warn', text: motivo || 'No se puede registrar este movimiento ahora.' }));
            ctx.bloqueado = true;
            return ctx;
        }
        if (ingreso && f.fueraFranja) cuerpo.appendChild(el('div', { class: 'aviso a-warn', text: 'Este contratista llega fuera de la franja autorizada (otro día u otro horario). Puede ingresar solo si registra una desviación con el Coordinador que lo autoriza.' }));
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
            // D-227: el contratista que llega fuera de sus días u horario ingresa solo con desviación (aunque cumpla todo el checklist)
            if (ingreso && f.fueraFranja && !tardio.checked) fallan = fallan.concat([{ id: 0, texto: 'Ingreso fuera de la franja autorizada (día u horario)', critico: false }]);
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

    // Acceso directo desde el calendario de proveedores: abre la acción que toca de esa entrega (la misma ventana de siempre, con su checklist).
    var directa = new URLSearchParams(location.search).get('solicitud');
    function abrirDirecta(id) {
        var l = brutas.filter(function (x) { return String(x.solicitudId) === id && x.esProveedor; });
        if (!l.length) { CAF.aviso('Esa entrega no está en la lista de hoy: solo se atiende el día programado.', 'warn'); return; }
        var op = l[0].estadoOp, pv = l.filter(esVerificable)[0], pi = l.filter(function (x) { return esIngresable(x) && x.esTransportista; })[0], ps = l.filter(function (x) { return puede && salidaProveedor(x, l); })[0];
        if (puede && pv) movimiento(pv, 'INGRESO', true);
        else if (puedeProv && pi && pi.almacenListo) registrarIngreso([pi]);
        else if (ps) movimiento(ps, 'SALIDA');
        else CAF.aviso(op === 'EN_ESPERA' ? 'Almacén aún no confirmó su disponibilidad: todavía no se puede registrar el ingreso.' : 'Por ahora no hay una acción de Vigilancia para esa entrega.', 'warn');
    }

    pintarModos();
    cargar().then(function () { if (directa && /^\d+$/.test(directa)) { history.replaceState(null, '', location.pathname); abrirDirecta(directa); } });
    // Refresco automático cada 10 s (sin ventanas abiertas y sin pisar lo que se está escribiendo en el buscador).
    CAF.autoRefrescar(function () { if (document.activeElement !== cajaTexto) cargar(true); }, 10);
})();

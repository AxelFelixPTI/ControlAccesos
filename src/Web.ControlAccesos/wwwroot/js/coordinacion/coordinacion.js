// Pantalla del coordinador: bandeja con pestañas y filtros, y ventana «Revisar» para decidir persona por persona.
(function () {
    'use strict';
    var raiz = document.getElementById('caf-coord');
    if (!raiz) return;
    var el = CAF.el, d = raiz.dataset;
    var pestana = 'POR_DECIDIR', primera = true, porDecidir = 0, filas = [], op = null;
    var cuerpo = document.getElementById('c-filas'), tabs = document.getElementById('c-tabs');
    var f = { empresa: document.getElementById('c-empresa'), solicitante: document.getElementById('c-solicitante'), persona: document.getElementById('c-persona'),
              fecha: document.getElementById('c-fecha'), estado: document.getElementById('c-estado') };

    // ── Bandeja ──────────────────────────────────────────────────────────────────────────────
    function pintarTabs() {
        tabs.textContent = '';
        [['POR_DECIDIR', 'Por decidir (' + porDecidir + ')'], ['TODAS', 'Todas']].forEach(function (t) {
            tabs.appendChild(el('button', { type: 'button', class: 'pill' + (pestana === t[0] ? ' on' : ''), text: t[1], onclick: function () { pestana = t[0]; cargar(); } }));
        });
    }

    function pintar() {
        pintarTabs();
        cuerpo.textContent = '';
        if (!filas.length) {
            cuerpo.appendChild(el('tr', {}, [el('td', { colspan: '7', class: 'vacio', text: pestana === 'POR_DECIDIR' ? 'No tiene solicitudes por decidir.' : 'No hay solicitudes con ese filtro.' })]));
            return;
        }
        filas.forEach(function (s) {
            var detalle = [];
            if (s.autorizadas) detalle.push(s.autorizadas + ' autorizada(s)');
            if (s.pendientes) detalle.push(s.pendientes + ' pendiente(s)');
            if (s.observadas) detalle.push(s.observadas + ' observada(s)');
            if (s.rechazadas) detalle.push(s.rechazadas + ' rechazada(s)');
            cuerpo.appendChild(el('tr', { class: s.esHoy ? 'hoy' : (s.estado === 'CANCELADA' ? 'off' : '') }, [
                el('td', {}, [el('button', { type: 'button', class: 'link', text: s.codigo, onclick: function () { revisar(s.id); } })]),
                el('td', {}, [el('span', { text: SOL.fechaLarga(s.fecha) + ' · ' + s.hora }), s.esHoy ? el('span', { class: 'chip c-obs', text: 'Hoy' }) : null]),
                el('td', { text: s.empresa || '' }),
                el('td', { text: s.solicitante || '' }),
                el('td', {}, [el('div', { text: String(s.total) }), el('div', { class: 'field-h', text: detalle.join(' · ') }),
                              s.porDecidirMis ? el('div', { class: 'field-h', text: s.porDecidirMis + ' por decidir por usted' }) : null]),
                el('td', {}, [SOL.chipEstado(s.estado)]),
                el('td', {}, [el('button', { type: 'button', class: 'btn btn-sm' + (s.porDecidirMis ? ' btn-primary' : ''), text: s.porDecidirMis ? 'Revisar' : 'Ver', onclick: function () { revisar(s.id); } })])
            ]));
        });
    }

    function cargar() {
        var q = '?pestana=' + pestana + '&empresa=' + encodeURIComponent(f.empresa.value) + '&solicitante=' + encodeURIComponent(f.solicitante.value)
              + '&persona=' + encodeURIComponent(f.persona.value) + '&fecha=' + f.fecha.value + '&estado=' + f.estado.value;
        return CAF.pedir(d.urlLista + q).then(function (r) {
            if (!r.success) { CAF.aviso(r.message || 'No se pudo cargar.', 'warn'); return; }
            porDecidir = r.porDecidir; filas = r.data;
            if (primera) { primera = false; if (porDecidir === 0 && pestana === 'POR_DECIDIR') { pestana = 'TODAS'; return cargar(); } }
            pintar();
        });
    }

    var t = null;
    ['empresa', 'solicitante', 'persona'].forEach(function (k) { f[k].addEventListener('input', function () { clearTimeout(t); t = setTimeout(cargar, 300); }); });
    f.fecha.addEventListener('change', cargar); f.estado.addEventListener('change', cargar);

    // ── Revisar ──────────────────────────────────────────────────────────────────────────────
    function opciones() { return op ? Promise.resolve(op) : SOL.cargarOpciones(d.urlOpciones).then(function (o) { op = o; return o; }); }

    function revisar(id) {
        var cont = el('div', { class: 'stack' }, [el('p', { class: 'vacio', text: 'Cargando...' })]);
        var m = CAF.modal('Solicitud', cont, [{ texto: 'Cerrar', onclick: function (c) { c(); cargar(); } }], 'ancho');
        var tab = 'personas', s = null;

        function refrescar(mensaje) {
            return CAF.pedir(d.urlRevisar + '?id=' + id).then(function (r) {
                if (!r.success) { cont.textContent = ''; cont.appendChild(el('p', { class: 'vacio', text: r.message || 'No se pudo cargar la solicitud.' })); return; }
                s = r.data; pintar(); if (mensaje) CAF.aviso(mensaje);
            });
        }

        function pintar() {
            cont.textContent = '';
            cont.appendChild(el('div', { class: 'det-h' }, [el('h3', { text: s.codigo }), SOL.chipEstado(s.estado), s.codigoOrigen ? el('span', { class: 'field-h', text: 'basada en ' + s.codigoOrigen }) : null]));
            if (s.estado === 'CANCELADA') cont.appendChild(el('div', { class: 'aviso a-info', text: 'Solicitud cancelada' + (s.motivoCancelacion ? ': ' + s.motivoCancelacion : '.') }));
            var dl = el('dl', { class: 'dl' });
            [['Visita', SOL.fechaLarga(s.fecha) + ' · ' + s.hora + ' · ' + s.sede], ['Empresa', s.empresa || '—'], ['Motivo', (s.motivo || '—') + (s.motivoDetalle ? ' — ' + s.motivoDetalle : '')],
             ['Zonas', s.zonas || '—'], ['Responsable de atención', (s.responsable || '—') + (s.responsableArea ? ' (' + s.responsableArea + ')' : '')],
             ['Solicitante', (s.solicitante || '—') + (s.solicitanteCorreo ? ' · ' + s.solicitanteCorreo : '')], ['Observaciones', s.observaciones || '—']]
                .forEach(function (x) { dl.appendChild(el('dt', { text: x[0] })); dl.appendChild(el('dd', { text: x[1] })); });
            cont.appendChild(dl);
            cont.appendChild(ADJ.panel({ solicitudId: id, urlListar: d.urlAdj, puedeAdjuntar: false }).nodo);
            if (s.exigeSctr || s.exigeEpp) cont.appendChild(el('div', { class: 'aviso a-warn', text: 'Las zonas exigen ' + [s.exigeSctr ? 'SCTR' : '', s.exigeEpp ? 'EPP' : ''].filter(Boolean).join(' y ') + ': Vigilancia lo verifica al ingreso.' }));
            cont.appendChild(el('div', { class: 'pills' }, [['personas', 'Personas (' + s.personas.filter(function (p) { return p.aprobacion !== 'RETIRADA'; }).length + ')'], ['historial', 'Historial']].map(function (x) {
                return el('button', { type: 'button', class: 'pill' + (tab === x[0] ? ' on' : ''), text: x[1], onclick: function () { tab = x[0]; pintar(); } });
            })));
            cont.appendChild(tab === 'personas' ? vistaPersonas() : vistaHistorial());
        }

        function vistaHistorial() {
            if (!s.historial.length) return el('p', { class: 'vacio', text: 'Sin movimientos.' });
            return el('ul', { class: 'hist' }, s.historial.map(function (h) {
                return el('li', {}, [el('span', { class: 'hist-t', text: h.fecha }), el('span', { text: h.texto + (h.detalle ? ': ' + h.detalle : '') + (h.usuario ? ' — ' + h.usuario : '') })]);
            }));
        }

        function nota(p) {
            if (p.aprobacion === 'APROBADA') return SOL.textoIngreso(p.estado) || ('Autorizada' + (p.aprobadoPor ? ' por ' + p.aprobadoPor : ''));
            if (p.aprobacion === 'OBSERVADA') return 'Observada: ' + (p.mensaje || '');
            if (p.aprobacion === 'RECHAZADA') return 'Rechazada: ' + (p.mensaje || '');
            if (p.aprobacion === 'PENDIENTE' && !p.puedeDecidir) return 'Pendiente de otra aprobación.';
            return '';
        }

        function vistaPersonas() {
            var caja = el('div', { class: 'stack' }), sel = {};
            var decidibles = s.personas.filter(function (p) { return p.puedeDecidir; });
            var error = el('p', { class: 'field-e' });
            var texto = el('textarea', { rows: '2', maxlength: '300', placeholder: 'Qué debe corregir (para observar) o motivo (para rechazar)' });
            var acciones = el('div', { class: 'acc' }), pregunta = el('div'), marcarTodas = null;

            var ul = el('ul', { class: 'plist' });
            s.personas.forEach(function (p) {
                var chk = null;
                var quitable = p.puedeQuitar ? el('div', { class: 'plist-r' }, [el('button', { type: 'button', class: 'btn btn-sm btn-danger-o', text: 'Quitar (emergencia)', onclick: function () { quitar(p); } })]) : null;
                var yaIngreso = s.puedeCorregir && p.aprobacion === 'APROBADA' && p.estado === 'DENTRO';
                if (p.puedeDecidir) {
                    chk = el('input', { type: 'checkbox', 'aria-label': 'Elegir a ' + p.nombre });
                    chk.addEventListener('change', function () { sel[p.id] = chk.checked; p._chk = chk; });
                    p._chk = chk;
                }
                ul.appendChild(el('li', { class: p.aprobacion === 'RETIRADA' ? 'ret' : '' }, [
                    chk ? el('label', { class: 'chk' }, [chk]) : null,
                    el('div', { class: 'plist-m' }, [
                        el('div', { class: 'plist-n' }, [el('span', { class: 'pn', text: p.nombre }), SOL.chipPersona(p), p.origen === 'AGREGADA_COORDINADOR' ? el('span', { class: 'chip c-line', text: 'Agregada por coordinación' }) : null]),
                        el('div', { class: 'field-h', text: (p.tipoDoc ? p.tipoDoc + ' ' : '') + p.doc }),
                        nota(p) ? el('div', { class: 'field-h', text: nota(p) }) : null,
                        yaIngreso ? el('div', { class: 'field-h', text: 'Ya ingresó: no se quita. Vigilancia registra su salida con una observación.' }) : null
                    ]),
                    quitable
                ]));
            });
            caja.appendChild(ul);

            function marcadas() { return decidibles.filter(function (p) { return p._chk && p._chk.checked; }); }

            function ejecutar(decision, ids, mensaje, resto, mensajeResto) {
                error.textContent = '';
                CAF.pedir(d.urlDecidir, { method: 'POST', body: { solicitudId: id, decision: decision, mensaje: mensaje, personasIds: ids, decisionResto: resto || null, mensajeResto: mensajeResto || null } }).then(function (r) {
                    if (!r.success) { error.textContent = SOL.errores(r); if (r.parcial) refrescar(); return; }
                    cargar(); refrescar(r.message);
                });
            }

            function decidir(decision, todas) {
                error.textContent = ''; pregunta.textContent = '';
                var elegidas = todas ? decidibles : marcadas();
                if (!elegidas.length) { error.textContent = 'Marque al menos una persona.'; return; }
                if (decision !== 'APROBADA' && !texto.value.trim()) { error.textContent = decision === 'OBSERVADA' ? 'Escriba qué debe corregir el solicitante.' : 'Escriba el motivo del rechazo.'; return; }
                var ids = elegidas.map(function (p) { return p.id; });
                var quedan = decidibles.length - elegidas.length;
                if (quedan <= 0) { ejecutar(decision, ids, texto.value, null, null); return; }
                // Quedan personas sin marcar: se pregunta qué hacer con ellas.
                var textoResto = el('textarea', { rows: '2', maxlength: '300', placeholder: 'Mensaje para las demás (solo si las observa o rechaza)' });
                pregunta.appendChild(el('div', { class: 'ask' }, [
                    el('p', { text: 'Quedan ' + quedan + ' persona(s) sin marcar. ¿Qué desea hacer con ellas?' }),
                    textoResto,
                    el('div', { class: 'acc' }, [
                        el('button', { type: 'button', class: 'btn btn-sm', text: 'Dejarlas pendientes', onclick: function () { ejecutar(decision, ids, texto.value, null, null); } }),
                        el('button', { type: 'button', class: 'btn btn-sm', text: 'Observarlas', onclick: function () { if (!textoResto.value.trim()) { error.textContent = 'Escriba el mensaje para las demás.'; return; } ejecutar(decision, ids, texto.value, 'OBSERVADA', textoResto.value); } }),
                        el('button', { type: 'button', class: 'btn btn-sm btn-danger-o', text: 'Rechazarlas', onclick: function () { if (!textoResto.value.trim()) { error.textContent = 'Escriba el mensaje para las demás.'; return; } ejecutar(decision, ids, texto.value, 'RECHAZADA', textoResto.value); } }),
                        el('button', { type: 'button', class: 'btn btn-sm', text: 'Volver', onclick: function () { pregunta.textContent = ''; } })
                    ])
                ]));
            }

            if (decidibles.length) {
                marcarTodas = el('input', { type: 'checkbox' });
                marcarTodas.addEventListener('change', function () { decidibles.forEach(function (p) { p._chk.checked = marcarTodas.checked; }); });
                caja.appendChild(el('label', { class: 'chk-all' }, [marcarTodas, 'Marcar todas las que puedo decidir (' + decidibles.length + ')']));
                acciones.appendChild(el('button', { type: 'button', class: 'btn btn-primary', text: 'Aprobar todas', onclick: function () { decidir('APROBADA', true); } }));
                acciones.appendChild(el('button', { type: 'button', class: 'btn', text: 'Aprobar seleccionadas', onclick: function () { decidir('APROBADA', false); } }));
                acciones.appendChild(el('button', { type: 'button', class: 'btn', text: 'Observar seleccionadas', onclick: function () { decidir('OBSERVADA', false); } }));
                acciones.appendChild(el('button', { type: 'button', class: 'btn btn-danger-o', text: 'Rechazar seleccionadas', onclick: function () { decidir('RECHAZADA', false); } }));
                caja.appendChild(el('div', { class: 'decide' }, [texto, acciones, pregunta]));
            } else if (s.puedeDecidir) {
                caja.appendChild(el('p', { class: 'field-h', text: 'No hay personas pendientes para usted en esta solicitud.' }));
            } else {
                caja.appendChild(el('p', { class: 'field-h', text: 'Solo lectura: su rol no decide pasos de esta solicitud.' }));
            }
            caja.appendChild(error);
            if (s.puedeCorregir) {
                caja.appendChild(el('div', { class: 'aviso a-warn' }, [
                    el('span', { text: 'Corrección de emergencia: solo si la visita cambia el mismo día. Agregue a quien llegó sin estar en la solicitud o quite a quien ya no viene. Vigilancia lo ve al instante y el solicitante y Vigilancia reciben un correo con su sustento.' }),
                    el('button', { type: 'button', class: 'btn btn-sm', text: '+ Agregar persona (emergencia)', onclick: agregar })
                ]));
            }
            return caja;
        }

        function campoSustento(ayuda) {
            var area = el('textarea', { rows: '3', maxlength: '300', placeholder: ayuda });
            return { area: area, nodo: el('label', { class: 'field' }, [el('span', { class: 'field-l', text: 'Sustento (obligatorio)' }), area]) };
        }

        function agregar() {
            opciones().then(function (o) {
                if (!o) return;
                var fp = SOL.formPersona(o, d.urlBuscar, d.urlPersona), err = el('p', { class: 'field-e' });
                var sus = campoSustento('Por qué se agrega a esta persona ahora (por ejemplo: llegó a portería, lo pidió el responsable de atención).');
                CAF.modal('Agregar persona (emergencia)', el('div', { class: 'stack' }, [
                    el('div', { class: 'aviso a-warn', text: 'Corrección de emergencia: la persona queda autorizada de inmediato. Vigilancia la verá al instante y el solicitante y Vigilancia recibirán un correo con el sustento.' }),
                    fp.nodo, sus.nodo, err]), [
                    { texto: 'Cancelar', onclick: function (c) { c(); } },
                    {
                        texto: 'Agregar', tipo: 'primary', onclick: function (c) {
                            err.textContent = '';
                            if (!sus.area.value.trim()) { err.textContent = 'Escriba el sustento de la corrección de emergencia.'; return; }
                            fp.guardar().then(function (r) {
                                if (!r.success) { err.textContent = SOL.errores(r); return; }
                                CAF.pedir(d.urlAgregar, { method: 'POST', body: { solicitudId: id, personaId: r.data.id, sustento: sus.area.value } }).then(function (x) {
                                    if (!x.success) { err.textContent = SOL.errores(x); return; }
                                    c(); cargar(); refrescar(x.message || 'Persona agregada y aprobada.');
                                });
                            });
                        }
                    }
                ], 'ancho');
            });
        }

        function quitar(p) {
            var err = el('p', { class: 'field-e' });
            var sus = campoSustento('Por qué se quita a esta persona (por ejemplo: ya no viene, la reemplazó otra persona).');
            CAF.modal('Quitar persona (emergencia)', el('div', { class: 'stack' }, [
                el('p', { text: '¿Quitar a ' + p.nombre + ' de esta solicitud? Ya no podrá ingresar.' }),
                el('div', { class: 'aviso a-warn', text: 'Corrección de emergencia: Vigilancia lo verá al instante y el solicitante y Vigilancia recibirán un correo con el sustento.' }),
                sus.nodo, err]), [
                { texto: 'Volver', onclick: function (c) { c(); } },
                {
                    texto: 'Quitar', tipo: 'primary', onclick: function (c) {
                        err.textContent = '';
                        if (!sus.area.value.trim()) { err.textContent = 'Escriba el sustento de la corrección de emergencia.'; return; }
                        CAF.pedir(d.urlQuitar, { method: 'POST', body: { solicitudPersonaId: p.id, sustento: sus.area.value } }).then(function (x) {
                            if (!x.success) { err.textContent = SOL.errores(x); return; }
                            c(); cargar(); refrescar(x.message || 'Persona retirada.');
                        });
                    }
                }
            ]);
        }

        refrescar();
    }

    cargar();
})();

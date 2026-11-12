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

    var ftipos = SOL.filtroTipos('coord', document.getElementById('c-empresa').closest('section'), function () { pintar(); });

    function pintar() {
        pintarTabs();
        cuerpo.textContent = '';
        var vistas = filas.filter(function (s) { return ftipos.pasa(s.tipo); });
        if (!vistas.length) {
            cuerpo.appendChild(el('tr', {}, [el('td', { colspan: '7', class: 'vacio', text: pestana === 'POR_DECIDIR' ? 'No tiene solicitudes por decidir.' : 'No hay solicitudes con ese filtro.' })]));
            return;
        }
        vistas.forEach(function (s) {
            var detalle = [];
            if (s.autorizadas) detalle.push(s.autorizadas + ' autorizada(s)');
            if (s.pendientes) detalle.push(s.pendientes + ' pendiente(s)');
            if (s.observadas) detalle.push(s.observadas + ' observada(s)');
            if (s.rechazadas) detalle.push(s.rechazadas + ' rechazada(s)');
            cuerpo.appendChild(el('tr', { class: s.esHoy ? 'hoy' : (s.estado === 'CANCELADA' ? 'off' : '') }, [
                el('td', {}, [el('button', { type: 'button', class: 'link', text: s.codigo, onclick: function () { revisar(s.id); } }), el('div', {}, [SOL.chipTipo(s.tipoCodigo, s.tipo)])]),
                el('td', {}, [el('span', { text: SOL.fechaLarga(s.fecha) + ' · ' + s.hora }), s.esHoy ? el('span', { class: 'chip c-obs', text: 'Hoy' }) : null]),
                el('td', {}, [el('div', { text: s.empresa || '' }), SOL.chipEmpresa(s.empresaCodigo)]),
                el('td', { text: s.solicitante || '' }),
                el('td', {}, [SOL.personasLista(s.personas), el('div', { class: 'field-h', text: s.total + ' persona(s)' }), el('div', { class: 'field-h', text: detalle.join(' · ') }),
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
            porDecidir = r.porDecidir; filas = r.data; ftipos.registrar(filas.map(function (s) { return s.tipo; }));
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
            cont.appendChild(el('div', { class: 'det-h' }, [el('h3', { text: s.codigo }), SOL.chipTipo(s.tipoCodigo, s.tipo), SOL.chipEmpresa(s.empresaCodigo), SOL.chipEstado(s.estado), s.codigoOrigen ? el('span', { class: 'field-h', text: 'basada en ' + s.codigoOrigen }) : null]));
            if (s.estado === 'CANCELADA') cont.appendChild(el('div', { class: 'aviso a-info', text: 'Solicitud cancelada' + (s.motivoCancelacion ? ': ' + s.motivoCancelacion : '.') }));
            var dl = el('dl', { class: 'dl' });
            var c = s.tipoCodigo === 'CONTRATISTA', pv = s.tipoCodigo === 'PROVEEDOR';
            var filas = [['Tipo de ingreso', s.tipo || '—'], (c && s.dias && s.dias.length) ? ['Días de trabajo (' + s.dias.length + ')', s.dias.map(function (x) { return SOL.fechaLarga(x.fecha) + (x.origen === 'EXTENSION' ? ' (ampliado)' : ''); }).join(', ') + ' · ' + SOL.textoHoras(s.dias[0].desde, s.dias[0].hasta) + ' · ' + s.sede] : [c ? 'Servicio' : pv ? 'Entrega' : 'Visita', SOL.fechaLarga(s.fecha) + ' · ' + s.hora + ' · ' + s.sede], [c ? 'Empresa contratista' : pv ? 'Empresa proveedora' : 'Empresa', s.empresa || '—']];
            if (pv) filas.push(['Empresa que recibe', s.empresaDestino || '—'], ['Responsable de la entrega', (s.contactoNombre || '—') + ' · ' + (s.contactoTelefonos || '—')]);
            else if (c) filas.push(['Actividad(es)', s.motivoDetalle || '—'], ['Área de trabajo', (s.zonas || '—') + (s.areaDetalle ? ' — ' + s.areaDetalle : '')],
                ['Contacto', (s.contactoNombre || '—') + ' · ' + (s.contactoTelefonos || '—')], ['Correos de contacto', s.contactoCorreos || '—']);
            else filas.push(['Motivo', (s.motivo || '—') + (s.motivoDetalle ? ' — ' + s.motivoDetalle : '')], ['Zonas', s.zonas || '—']);
            if (!pv) filas.push(['Responsable de atención', (s.responsable || '—') + (s.responsableArea ? ' (' + s.responsableArea + ')' : '')]);
            if (s.cochera) filas.push(['Cochera', 'Sí · placa ' + (s.placa || '—')]);
            filas.push(['Solicitante', (s.solicitante || '—') + (s.solicitanteCorreo ? ' · ' + s.solicitanteCorreo : '')], ['Observaciones', s.observaciones || '—']);
            filas
                .forEach(function (x) { dl.appendChild(el('dt', { text: x[0] })); dl.appendChild(el('dd', { text: x[1] })); });
            cont.appendChild(dl);
            if (pv) cont.appendChild(SOL.transportistasNodo(s.transportistas));
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
                var quitable = (p.puedeQuitar || p.puedeCorregirDatos) ? el('div', { class: 'plist-r' }, [
                    p.puedeCorregirDatos ? el('button', { type: 'button', class: 'btn btn-sm', text: 'Corregir datos (emergencia)', onclick: function () { corregir(p); } }) : null,
                    p.puedeQuitar ? el('button', { type: 'button', class: 'btn btn-sm btn-danger-o', text: p.esUnica ? 'Quitar y rechazar (emergencia)' : 'Quitar (emergencia)', onclick: function () { quitar(p); } }) : null
                ]) : null;
                var yaIngreso = s.puedeCorregir && p.aprobacion === 'APROBADA' && p.estado === 'DENTRO';
                if (p.puedeDecidir) {
                    chk = el('input', { type: 'checkbox', 'aria-label': 'Elegir a ' + p.nombre });
                    chk.addEventListener('change', function () { sel[p.id] = chk.checked; p._chk = chk; });
                    p._chk = chk;
                }
                ul.appendChild(el('li', { class: p.aprobacion === 'RETIRADA' ? 'ret' : '' }, [
                    chk ? el('label', { class: 'chk' }, [chk]) : null,
                    el('div', { class: 'plist-m' }, [
                        el('div', { class: 'plist-n' }, [el('span', { class: 'pn', text: p.nombre }), SOL.chipPersona(p), (p.subtipo || s.tipoCodigo === 'PROVEEDOR') ? el('span', { class: 'chip c-line', text: p.subtipo || (p.esTransportista ? 'Transportista' : 'Ayudante de descarga') }) : null, p.origen === 'AGREGADA_COORDINADOR' ? el('span', { class: 'chip c-line', text: 'Agregada por coordinación' }) : null]),
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
                    el('span', { text: 'Corrección de emergencia: solo si la visita cambia el mismo día. Agregue a quien llegó sin estar en la solicitud, corrija un dato mal escrito (menos el número de documento) o quite a quien ya no viene. Vigilancia lo ve al instante y el solicitante y Vigilancia reciben un correo con su sustento.' }),
                    el('button', { type: 'button', class: 'btn btn-sm', text: '+ Agregar persona (emergencia)', onclick: agregar }),
                    (s.tipoCodigo === 'CONTRATISTA' && s.dias && s.dias.length) ? el('button', { type: 'button', class: 'btn btn-sm', text: '+ Ampliar días (emergencia)', onclick: ampliarDias }) : null
                ]));
            }
            return caja;
        }

        function campoSustento(ayuda) {
            var area = el('textarea', { rows: '3', maxlength: '300', placeholder: ayuda });
            return { area: area, nodo: el('label', { class: 'field' }, [el('span', { class: 'field-l', text: 'Sustento (obligatorio)' }), area]) };
        }

        // D-227: el Coordinador agrega días al contratista por franja. Solo suma: no quita días ni toca lo ya registrado.
        function ampliarDias() {
            var sel = SOL.selectorDias([], s.dias[0].desde || '', s.dias[0].hasta || ''), err = el('p', { class: 'field-e' });
            var sus = campoSustento('Por qué se amplía el plazo (por ejemplo: el trabajo se retrasó, el cliente pidió más días).');
            CAF.modal('Ampliar días (emergencia)', el('div', { class: 'stack' }, [
                el('div', { class: 'aviso a-info', text: 'Se suman a los días ya autorizados (' + s.dias.map(function (x) { return SOL.nombreDia(x.fecha); }).join(', ') + '). No se quita ningún día, la solicitud sigue aprobada y lo ya registrado no cambia. Avisamos por correo al solicitante y a Vigilancia.' }),
                sel.nodo, sus.nodo, err]), [
                { texto: 'Cancelar', onclick: function (c) { c(); } },
                {
                    texto: 'Ampliar', tipo: 'primary', onclick: function (c) {
                        err.textContent = '';
                        if (!sel.dias().length) { err.textContent = 'Elija al menos un día para agregar.'; return; }
                        if (!sus.area.value.trim()) { err.textContent = 'Escriba el sustento de la corrección de emergencia.'; return; }
                        CAF.pedir(d.urlExtenderDias, { method: 'POST', body: { solicitudId: id, dias: sel.dias(), horaDesde: sel.horaDesde(), horaHasta: sel.horaHasta(), sustento: sus.area.value } }).then(function (x) {
                            if (!x.success) { err.textContent = SOL.errores(x); return; }
                            c(); cargar(); refrescar(x.message || 'Días agregados.');
                        });
                    }
                }
            ], 'ancho');
        }

        function agregar() {
            opciones().then(function (o) {
                if (!o) return;
                var fp = SOL.formPersona(o, d.urlBuscar, d.urlPersona), err = el('p', { class: 'field-e' });
                var sus = campoSustento('Por qué se agrega a esta persona ahora (por ejemplo: llegó a portería, lo pidió el responsable de atención).');
                // D-226: en una entrega de proveedor se indica si viene como transportista o como ayudante de descarga
                var pv = s && s.tipoCodigo === 'PROVEEDOR', rol = null, dt = null, ins = {};
                // D-234: la persona agregada por emergencia también lleva su rol (subtipo), si el tipo de ingreso los tiene
                var subs = (o.subtipos || []).filter(function (x) { return s && x.tipoId === s.tipoId; });
                function rolActual() { return rol ? subs.filter(function (x) { return String(x.id) === rol.value; })[0] : null; }
                function esTransp() { var r = rolActual(); return !!(pv && r && r.codigo === 'TRANSPORTISTA'); }
                if (subs.length) {
                    rol = el('select');
                    subs.forEach(function (x) { rol.appendChild(el('option', { value: String(x.id), text: x.texto })); });
                    rol.value = String((subs.filter(function (x) { return x.predeterminado; })[0] || subs[0]).id);
                }
                if (pv) {
                    var cam = [['ruc', 'RUC del transportista', 11, '11 dígitos.'], ['nombre', 'Razón social', 200, ''], ['direccion', 'Dirección', 300, ''],
                        ['placa', 'Placa del vehículo', 8, 'De 5 a 8 letras o números.'], ['marca', 'Marca del vehículo', 50, ''], ['licencia', 'Licencia del conductor', 20, '']];
                    dt = el('div', { class: 'stack', hidden: 'hidden' }, [el('p', { class: 'ayuda', text: 'Datos del transportista (opcionales: Vigilancia los completa al verificarlo).' })].concat(cam.map(function (c) {
                        var i = el('input', { type: 'text', maxlength: String(c[2]), placeholder: c[3] }); ins[c[0]] = i;
                        if (c[0] === 'placa') i.style.textTransform = 'uppercase';
                        return el('label', { class: 'field' }, [el('span', { class: 'field-l', text: c[1] }), i]);
                    })));
                    }
                if (rol) rol.addEventListener('change', function () { if (dt) { if (esTransp()) dt.removeAttribute('hidden'); else dt.setAttribute('hidden', 'hidden'); } });
                CAF.modal('Agregar persona (emergencia)', el('div', { class: 'stack' }, [
                    el('div', { class: 'aviso a-warn', text: 'Corrección de emergencia: la persona queda autorizada de inmediato. Vigilancia la verá al instante y el solicitante y Vigilancia recibirán un correo con el sustento.' }),
                    fp.nodo,
                    rol ? el('label', { class: 'field' }, [el('span', { class: 'field-l', text: 'Rol de la persona' }), rol]) : null,
                    pv ? dt : null,
                    pv ? el('div', { class: 'aviso a-info', text: 'Si agrega un transportista cuando la entrega ya esperaba, vuelve a «Programado» hasta que Vigilancia lo verifique. Un transportista no se puede agregar si la entrega ya terminó.' }) : null,
                    sus.nodo, err]), [
                    { texto: 'Cancelar', onclick: function (c) { c(); } },
                    {
                        texto: 'Agregar', tipo: 'primary', onclick: function (c) {
                            err.textContent = '';
                            if (!sus.area.value.trim()) { err.textContent = 'Escriba el sustento de la corrección de emergencia.'; return; }
                            fp.guardar().then(function (r) {
                                if (!r.success) { err.textContent = SOL.errores(r); return; }
                                var cuerpo = { solicitudId: id, personaId: r.data.id, sustento: sus.area.value };
                                if (rol) cuerpo.subtipoId = Number(rol.value);
                                if (esTransp()) {
                                    cuerpo.esTransportista = true;
                                    Object.keys(ins).forEach(function (k) { cuerpo[k] = ins[k].value.trim() || null; });
                                    if (cuerpo.placa) cuerpo.placa = cuerpo.placa.toUpperCase().replace(/[\s-]/g, '');
                                }
                                CAF.pedir(d.urlAgregar, { method: 'POST', body: cuerpo }).then(function (x) {
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
            var err = el('p', { class: 'field-e' }), unica = !!p.esUnica;
            var sus = campoSustento(unica ? 'Por qué se rechaza la solicitud (por ejemplo: el transportista ya no viene y no hay reemplazo).' : 'Por qué se quita a esta persona (por ejemplo: ya no viene, la reemplazó otra persona).');
            CAF.modal(unica ? 'Quitar y rechazar la solicitud (emergencia)' : 'Quitar persona (emergencia)', el('div', { class: 'stack' }, [
                el('p', { text: '¿Quitar a ' + p.nombre + ' de esta solicitud? Ya no podrá ingresar.' }),
                unica ? el('div', { class: 'aviso a-warn', text: p.esTransportista ? 'Es el único transportista: sin él no hay entrega y la solicitud quedará RECHAZADA, aunque queden ayudantes de descarga. Si fue un error de nombre, use «Corregir datos»; si ya no viene, el solicitante puede cancelar la solicitud desde sus solicitudes.' : 'Es la única persona de la solicitud. Si la quita, la solicitud quedará RECHAZADA y nadie podrá ingresar con ella. Si lo que quiere es otra cosa, el solicitante puede cancelarla desde sus solicitudes.' }) : null,
                el('div', { class: 'aviso a-warn', text: 'Corrección de emergencia: Vigilancia lo verá al instante y el solicitante y Vigilancia recibirán un correo con el sustento.' }),
                sus.nodo, err]), [
                { texto: 'Volver', onclick: function (c) { c(); } },
                {
                    texto: unica ? 'Quitar y rechazar la solicitud' : 'Quitar', tipo: 'primary', onclick: function (c) {
                        err.textContent = '';
                        if (!sus.area.value.trim()) { err.textContent = 'Escriba el sustento de la corrección de emergencia.'; return; }
                        CAF.pedir(d.urlQuitar, { method: 'POST', body: { solicitudPersonaId: p.id, sustento: sus.area.value, confirmarRechazo: unica } }).then(function (x) {
                            if (!x.success) { err.textContent = SOL.errores(x); return; }
                            c(); cargar(); refrescar(x.message || 'Persona retirada.');
                        });
                    }
                }
            ]);
        }

        // D-215: corrige tipo de documento, apellidos y nombres. El número de documento se muestra fijo: si es otra persona, se quita y se agrega la otra.
        function corregir(p) {
            opciones().then(function (o) {
                if (!o) return;
                var err = el('p', { class: 'field-e' });
                var tipo = el('select'); o.tiposDoc.forEach(function (t) { tipo.appendChild(el('option', { value: String(t.id), text: t.texto })); });
                tipo.value = String(p.tipoDocId || '');
                function ent(v, max) { var i = el('input', { type: 'text', maxlength: String(max), autocomplete: 'off' }); i.value = v || ''; return i; }
                var doc = ent(p.doc, 20); doc.disabled = true; doc.setAttribute('aria-readonly', 'true');
                var ap = ent(p.apellidoPaterno, 100), am = ent(p.apellidoMaterno, 100), nom = ent(p.nombres, 200);
                var sus = campoSustento('Qué dato estaba mal (por ejemplo: el apellido se digitó con un error).');
                CAF.modal('Corregir datos (emergencia)', el('div', { class: 'stack' }, [
                    el('div', { class: 'aviso a-warn', text: 'Corrección de emergencia: se corrige a la misma persona y su autorización se mantiene. El cambio se ve en toda solicitud donde figure. Vigilancia lo verá al instante y el solicitante y Vigilancia recibirán un correo con el antes y el después.' }),
                    el('div', { class: 'grid g2' }, [SOL.campo('Tipo de documento', tipo), SOL.campo('Número de documento', doc, 'No se puede cambiar. Si es otra persona, quite a esta y agregue a la otra.')]),
                    el('div', { class: 'grid g3' }, [SOL.campo('Apellido paterno *', ap), SOL.campo('Apellido materno', am), SOL.campo('Nombres *', nom)]),
                    sus.nodo, err]), [
                    { texto: 'Cancelar', onclick: function (c) { c(); } },
                    {
                        texto: 'Guardar corrección', tipo: 'primary', onclick: function (c) {
                            err.textContent = '';
                            if (!ap.value.trim() || !nom.value.trim()) { err.textContent = 'Complete el apellido paterno y los nombres.'; return; }
                            if (!sus.area.value.trim()) { err.textContent = 'Escriba el sustento de la corrección de emergencia.'; return; }
                            CAF.pedir(d.urlCorregir, { method: 'POST', body: { solicitudPersonaId: p.id, tipoDocumentoId: Number(tipo.value) || 0, apellidoPaterno: ap.value, apellidoMaterno: am.value, nombres: nom.value, sustento: sus.area.value } }).then(function (x) {
                                if (!x.success) { err.textContent = SOL.errores(x); return; }
                                c(); cargar(); refrescar(x.message || 'Datos corregidos.');
                            });
                        }
                    }
                ], 'ancho');
            });
        }

        refrescar();
    }

    cargar();
    // Acceso directo desde el calendario de proveedores: abre «Revisar» de esa solicitud (la misma ventana de siempre, con sus reglas).
    var directa = new URLSearchParams(location.search).get('solicitud');
    if (directa && /^\d+$/.test(directa)) { history.replaceState(null, '', location.pathname); revisar(Number(directa)); }
})();

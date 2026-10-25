// Detalle de una solicitud propia: datos, personas con sus acciones, historial. Los botones se muestran u ocultan
// según las banderas «puede...» que calcula la base de datos; cuando no se puede, se explica por qué.
(function () {
    'use strict';
    var raiz = document.getElementById('caf-det');
    if (!raiz) return;
    var el = CAF.el, d = raiz.dataset, id = Number(d.id);
    var s = null, op = null;
    var cab = document.getElementById('d-cab'), caja = document.getElementById('d-personas'), hist = document.getElementById('d-historial');

    function opciones() { return op ? Promise.resolve(op) : SOL.cargarOpciones(d.urlOpciones).then(function (o) { op = o; return o; }); }
    function refrescar(msg) { return cargar().then(function () { if (msg) CAF.aviso(msg); }); }

    // Ejecuta una acción POST y vuelve a cargar; en error deja el texto dentro del modal.
    function accion(url, body, errorNodo, cerrar, ok) {
        return CAF.pedir(url, { method: 'POST', body: body }).then(function (r) {
            if (!r.success) { if (errorNodo) errorNodo.textContent = SOL.errores(r); else CAF.aviso(SOL.errores(r), 'warn'); return; }
            if (cerrar) cerrar();
            refrescar(typeof ok === 'function' ? ok(r) : ok);
        });
    }

    // ── Cabecera ─────────────────────────────────────────────────────────────────────────────
    function pintarCab() {
        cab.textContent = '';
        var acc = [];
        if (s.puedeEditar) acc.push(el('button', { type: 'button', class: 'btn btn-sm', text: 'Editar datos', onclick: editarDatos }));
        else if (s.motivoNoEditar) acc.push(el('span', { class: 'field-h', text: s.motivoNoEditar }));
        if (s.puedeReutilizar) acc.push(el('a', { class: 'btn btn-sm', href: d.urlNueva + '?reutilizar=' + s.id, text: 'Reutilizar' }));
        if (s.puedeCancelar) acc.push(el('button', { type: 'button', class: 'btn btn-sm btn-danger-o', text: 'Cancelar solicitud', onclick: cancelar }));
        else if (s.estado !== 'CANCELADA' && s.motivoNoCancelar) acc.push(el('span', { class: 'field-h', text: s.motivoNoCancelar }));
        cab.appendChild(el('div', { class: 'det-h' }, [el('h2', { text: s.codigo }), SOL.chipEstado(s.estado),
            s.codigoOrigen ? el('span', { class: 'field-h', text: 'basada en ' + s.codigoOrigen }) : null, el('div', { class: 'acc acc-r' }, acc)]));
        if (s.estado === 'CANCELADA' && s.motivoCancelacion) cab.appendChild(el('div', { class: 'aviso a-info', text: 'Motivo de la cancelación: ' + s.motivoCancelacion }));
        if (s.observacionCoordinador && s.observadas) cab.appendChild(el('div', { class: 'aviso a-warn', text: 'Coordinación: ' + s.observacionCoordinador }));
        var dl = el('dl', { class: 'dl' });
        [['Visita', SOL.fechaLarga(s.fecha) + ' · ' + s.hora + ' · ' + s.sede], ['Empresa', s.empresa || '—'],
         ['Motivo', (s.motivo || '—') + (s.motivoDetalle ? ' — ' + s.motivoDetalle : '')], ['Zonas', s.zonas || '—'],
         ['Responsable de atención', (s.responsable || '—') + (s.responsableArea ? ' (' + s.responsableArea + ')' : '')],
         ['Detalles adicionales', s.observaciones || '—'], ['Correos en copia', s.copias || '—']]
            .forEach(function (x) { dl.appendChild(el('dt', { text: x[0] })); dl.appendChild(el('dd', { text: x[1] })); });
        cab.appendChild(dl);
        if (s.exigeSctr || s.exigeEpp) cab.appendChild(el('div', { class: 'aviso a-warn', text: 'Vigilancia verificará ' + [s.exigeSctr ? 'el SCTR' : '', s.exigeEpp ? 'el uso de EPP' : ''].filter(Boolean).join(' y ') + ' al ingreso.' }));
    }

    function editarDatos() {
        opciones().then(function (o) {
            if (!o) return;
            var f = SOL.formDatos(o, d.urlResponsables, s), error = el('p', { class: 'field-e' });
            var cuerpoM = el('div', { class: 'stack' }, [
                s.autorizadas ? el('div', { class: 'aviso a-warn', text: 'Si cambia la fecha, la hora, la empresa, el motivo o las zonas, las personas ya autorizadas vuelven a quedar pendientes de aprobación.' }) : null,
                f.nodo, error]);
            CAF.modal('Editar datos de la visita', cuerpoM, [
                { texto: 'Cancelar', onclick: function (c) { c(); } },
                {
                    texto: 'Guardar cambios', tipo: 'primary', onclick: function (c) {
                        var e = f.validar(); if (e) { error.textContent = e; return; }
                        accion(d.urlEditar + '?id=' + id, f.leer(), error, c, function (r) { return r.data && r.data.reenviadas ? 'Datos guardados. Las personas se enviaron de nuevo a aprobación.' : 'Datos guardados.'; });
                    }
                }
            ], 'ancho');
        });
    }

    function cancelar() {
        var motivo = el('textarea', { rows: '2', maxlength: '300', placeholder: 'Motivo (opcional)' }), error = el('p', { class: 'field-e' });
        CAF.modal('Cancelar solicitud', el('div', { class: 'stack' }, [
            el('p', { text: '¿Cancelar la solicitud ' + s.codigo + '? Sus invitados ya no podrán ingresar con ella.' }),
            s.autorizadas ? el('div', { class: 'aviso a-warn', text: 'Tiene ' + s.autorizadas + ' persona(s) ya autorizada(s): se les quitará la autorización.' }) : null, motivo, error]), [
            { texto: 'Volver', onclick: function (c) { c(); } },
            { texto: 'Cancelar solicitud', tipo: 'primary', onclick: function (c) { accion(d.urlCancelar, { solicitudId: id, motivo: motivo.value }, error, c, 'Solicitud cancelada.'); } }
        ]);
    }

    // ── Personas ─────────────────────────────────────────────────────────────────────────────
    function nota(p) {
        if (p.aprobacion === 'APROBADA') return SOL.textoIngreso(p.estado) || ('Autorizada' + (p.aprobadoPor ? ' por ' + p.aprobadoPor : ''));
        if (p.aprobacion === 'OBSERVADA') return 'Coordinación pidió corregir: ' + (p.mensaje || '');
        if (p.aprobacion === 'RECHAZADA') return 'Motivo del rechazo: ' + (p.mensaje || '');
        if (p.aprobacion === 'PENDIENTE') return 'Esperando la decisión de Coordinación.';
        return '';
    }

    function agregar() {
        opciones().then(function (o) {
            if (!o) return;
            var f = SOL.formPersona(o, d.urlBuscar, d.urlPersona), error = el('p', { class: 'field-e' });
            CAF.modal('Agregar persona', el('div', { class: 'stack' }, [
                el('p', { class: 'field-h', text: 'La persona nueva quedará pendiente de aprobación.' }), f.nodo, error]), [
                { texto: 'Cancelar', onclick: function (c) { c(); } },
                {
                    texto: 'Agregar', tipo: 'primary', onclick: function (c) {
                        f.guardar().then(function (r) {
                            if (!r.success) { error.textContent = SOL.errores(r); return; }
                            accion(d.urlAgregar, { solicitudId: id, personaId: r.data.id }, error, c, 'Persona agregada.');
                        });
                    }
                }
            ], 'ancho');
        });
    }

    function corregir(p) {
        opciones().then(function (o) {
            if (!o) return;
            var f = SOL.formPersona(o, d.urlBuscar, d.urlPersona, { id: p.personaId, tipoDocId: p.tipoDocId, doc: p.doc, apellidoPaterno: p.apellidoPaterno, apellidoMaterno: p.apellidoMaterno, nombres: p.nombres });
            var error = el('p', { class: 'field-e' });
            CAF.modal(p.aprobacion === 'OBSERVADA' ? 'Corregir y reenviar' : 'Editar persona', el('div', { class: 'stack' }, [
                p.aprobacion === 'OBSERVADA' ? el('div', { class: 'aviso a-warn', text: 'Coordinación pidió: ' + (p.mensaje || '') }) : null, f.nodo, error]), [
                { texto: 'Cancelar', onclick: function (c) { c(); } },
                {
                    texto: p.aprobacion === 'OBSERVADA' ? 'Corregir y reenviar' : 'Guardar', tipo: 'primary', onclick: function (c) {
                        f.guardar().then(function (r) {
                            if (!r.success) { error.textContent = SOL.errores(r); return; }
                            accion(d.urlCorregir, { solicitudPersonaId: p.id, personaId: r.data.id }, error, c, function (x) { return x.message || 'Persona corregida.'; });
                        });
                    }
                }
            ], 'ancho');
        });
    }

    function retirar(p) {
        var error = el('p', { class: 'field-e' });
        CAF.modal('Retirar persona', el('div', { class: 'stack' }, [el('p', { text: '¿Retirar a ' + p.nombre + ' de esta solicitud? Podrá volver a agregarla mientras la solicitud siga abierta.' }), error]), [
            { texto: 'Volver', onclick: function (c) { c(); } },
            { texto: 'Retirar', tipo: 'primary', onclick: function (c) { accion(d.urlRetirar, { solicitudPersonaId: p.id }, error, c, 'Persona retirada.'); } }
        ]);
    }

    function pintarPersonas() {
        caja.textContent = '';
        var tit = [el('h3', { text: 'Personas (' + s.total + ')' })];
        if (s.puedeModificar) tit.push(el('button', { type: 'button', class: 'btn btn-sm', text: '+ Agregar persona', onclick: agregar }));
        caja.appendChild(el('div', { class: 'row-sp' }, tit));
        if (!s.puedeModificar && s.motivoNoModificar) caja.appendChild(el('p', { class: 'field-h', text: s.motivoNoModificar }));
        var ul = el('ul', { class: 'plist' });
        s.personas.forEach(function (p) {
            var acc = [];
            if (p.puedeCorregir) acc.push(el('button', { type: 'button', class: 'btn btn-sm', text: p.aprobacion === 'OBSERVADA' ? 'Corregir y reenviar' : 'Editar', onclick: function () { corregir(p); } }));
            if (p.puedeRetirar) acc.push(el('button', { type: 'button', class: 'btn btn-sm btn-danger-o', text: 'Retirar', onclick: function () { retirar(p); } }));
            if (p.puedeReactivar) acc.push(el('button', { type: 'button', class: 'btn btn-sm', text: 'Volver a agregar', onclick: function () { accion(d.urlAgregar, { solicitudId: id, personaId: p.personaId }, null, null, 'Persona agregada de nuevo.'); } }));
            ul.appendChild(el('li', { class: p.aprobacion === 'RETIRADA' ? 'ret' : '' }, [
                el('div', { class: 'plist-m' }, [
                    el('div', { class: 'plist-n' }, [el('span', { class: 'pn', text: p.nombre }), SOL.chipPersona(p)]),
                    el('div', { class: 'field-h', text: (p.tipoDoc ? p.tipoDoc + ' ' : '') + p.doc }),
                    nota(p) ? el('div', { class: 'field-h', text: nota(p) }) : null
                ]),
                el('div', { class: 'plist-r' }, acc)
            ]));
        });
        caja.appendChild(ul);
    }

    function pintarHistorial() {
        hist.textContent = '';
        hist.appendChild(el('h3', { text: 'Historial' }));
        if (!s.historial.length) { hist.appendChild(el('p', { class: 'vacio', text: 'Sin movimientos.' })); return; }
        hist.appendChild(el('ul', { class: 'hist' }, s.historial.map(function (h) {
            return el('li', {}, [el('span', { class: 'hist-t', text: h.fecha }), el('span', { text: h.texto + (h.detalle ? ': ' + h.detalle : '') + (h.usuario ? ' — ' + h.usuario : '') })]);
        })));
    }

    function cargar() {
        return CAF.pedir(d.urlDatos + '?id=' + id).then(function (r) {
            if (!r.success) { cab.textContent = ''; cab.appendChild(el('p', { class: 'vacio', text: r.message || 'No se pudo cargar la solicitud.' })); caja.textContent = ''; hist.textContent = ''; return; }
            s = r.data; pintarCab(); pintarPersonas(); pintarHistorial();
        });
    }

    cargar().then(function () {
        if (s && /[?&]nueva=1/.test(location.search)) {
            document.getElementById('d-aviso').appendChild(el('div', { class: 'aviso a-ok', text: 'Solicitud ' + s.codigo + ' enviada. Coordinación la revisará y le avisaremos por correo.' }));
            history.replaceState(null, '', location.pathname);
        }
    });
})();

// Piezas compartidas de las pantallas de solicitudes: estados, formulario de datos de la visita, buscador de
// responsable, formulario de persona externa. Todo texto entra con textContent (CAF.el); nada de innerHTML.
var SOL = (function () {
    'use strict';
    var el = CAF.el;

    var ESTADOS = {
        PENDIENTE: ['Pendiente', 'c-pend'], OBSERVADA: ['Observada', 'c-obs'], APROBADA: ['Aprobada', 'c-ok'],
        APROBADA_PARCIAL: ['Aprobada parcial', 'c-par'], RECHAZADA: ['Rechazada', 'c-rec'], CANCELADA: ['Cancelada', 'c-can']
    };
    function chipEstado(e) { var x = ESTADOS[e] || [e, 'c-pend']; return el('span', { class: 'chip ' + x[1], text: x[0] }); }

    // Estado de una persona dentro de la solicitud: aprobación + lo que ocurrió en portería.
    function chipPersona(p) {
        var m = { PENDIENTE: ['Pendiente de aprobación', 'c-pend'], APROBADA: ['Autorizada', 'c-ok'], OBSERVADA: ['Observada', 'c-obs'], RECHAZADA: ['Rechazada', 'c-rec'], RETIRADA: ['Retirada', 'c-ret'] };
        var x = m[p.aprobacion] || [p.aprobacion, 'c-pend'];
        return el('span', { class: 'chip ' + x[1], text: x[0] });
    }
    function textoIngreso(estado) {
        return { DENTRO: 'Está dentro de la sede', SALIO: 'Ya salió', DENEGADA: 'Se le denegó el ingreso', NO_SE_PRESENTO: 'No se presentó' }[estado] || '';
    }

    function hoy() { var d = new Date(); return d.getFullYear() + '-' + String(d.getMonth() + 1).padStart(2, '0') + '-' + String(d.getDate()).padStart(2, '0'); }
    function fechaLarga(f) { var p = String(f).split('-'); return p.length === 3 ? p[2] + '/' + p[1] + '/' + p[0] : f; }
    function campo(etiqueta, control, ayuda) { return el('label', { class: 'field' }, [el('span', { class: 'field-l', text: etiqueta }), control, ayuda ? el('span', { class: 'field-h', text: ayuda }) : null]); }
    function texto(valor, max, ph) { var i = el('input', { type: 'text', maxlength: String(max), autocomplete: 'off', placeholder: ph || '' }); i.value = valor || ''; return i; }
    function errores(r) {
        var det = (r.errors || []).map(function (e) { return e.message; }).filter(Boolean);
        return det.length ? det.join(' ') : (r.message || 'No se pudo completar la operación.');
    }

    function cargarOpciones(url) {
        return CAF.pedir(url).then(function (r) {
            if (!r.success) { CAF.aviso(r.message || 'No se pudieron cargar las listas.', 'warn'); return null; }
            return r.data;
        });
    }

    // ── Datos de la visita ───────────────────────────────────────────────────────────────────
    // v: valores iniciales {fecha,hora,empresa,responsableId,responsable,motivoId,motivoDetalle,observaciones,zonasIds,copias}
    function formDatos(op, urlResp, v) {
        v = v || {};
        var fecha = el('input', { type: 'date', min: hoy() }); fecha.value = v.fecha || '';
        var hora = el('input', { type: 'time' }); hora.value = v.hora || '';
        var empresa = texto(v.empresa, 250, 'Empresa o procedencia de los visitantes');
        var motivo = el('select'); motivo.appendChild(el('option', { value: '', text: 'Elija el motivo' }));
        op.motivos.forEach(function (m) { motivo.appendChild(el('option', { value: String(m.id), text: m.texto })); });
        motivo.value = v.motivoId ? String(v.motivoId) : '';
        var detalle = texto(v.motivoDetalle, 250, 'Describa el motivo');
        var detalleCampo = campo('Detalle del motivo *', detalle);
        var obs = el('textarea', { rows: '2', maxlength: '500', placeholder: 'Opcional. Se incluye en el correo que reciben Coordinación, Vigilancia y las personas en copia' }); obs.value = v.observaciones || '';
        var copias = texto(v.copias, 500, 'correo1@empresa.com; correo2@empresa.com');

        function sincMotivo() {
            var m = op.motivos.filter(function (x) { return String(x.id) === motivo.value; })[0];
            detalleCampo.hidden = !(m && m.esOtro);
        }
        motivo.addEventListener('change', sincMotivo); sincMotivo();

        // Responsable de atención: se busca desde 2 letras.
        var resp = { id: v.responsableId || 0, nombre: v.responsable || '' };
        var caja = el('div'), busca = texto('', 80, 'Escriba 2 letras del nombre'), sug = el('div', { class: 'sug' }), temp = null;
        sug.hidden = true;
        function pintarResp() {
            caja.textContent = '';
            if (resp.id) {
                caja.appendChild(el('div', { class: 'sel-box' }, [el('span', { text: resp.nombre }),
                    el('button', { type: 'button', class: 'btn btn-sm', text: 'Cambiar', onclick: function () { resp = { id: 0, nombre: '' }; pintarResp(); } })]));
            } else { caja.appendChild(busca); caja.appendChild(sug); }
        }
        busca.addEventListener('input', function () {
            clearTimeout(temp);
            var q = busca.value.trim();
            if (q.length < 2) { sug.hidden = true; return; }
            temp = setTimeout(function () {
                CAF.pedir(urlResp + '?q=' + encodeURIComponent(q)).then(function (r) {
                    sug.textContent = ''; sug.hidden = false;
                    if (!r.success || !r.data.length) { sug.appendChild(el('p', { class: 'vacio', text: 'Nadie coincide. Si no aparece, pida que lo agreguen en Personal.' })); return; }
                    r.data.forEach(function (p) {
                        sug.appendChild(el('button', { type: 'button', text: p.nombre + (p.area ? ' — ' + p.area : ''), onclick: function () { resp = { id: p.id, nombre: p.nombre }; pintarResp(); } }));
                    });
                });
            }, 250);
        });
        pintarResp();

        // Zonas
        var zonasSel = {}; (v.zonasIds || []).forEach(function (id) { zonasSel[id] = true; });
        var aviso = el('div', { class: 'aviso a-warn' }); aviso.hidden = true;
        var zonasNodo = el('fieldset', { class: 'zonas' }, [el('legend', { text: 'Zonas que visitarán *' })]);
        function sincZonas() {
            var sctr = false, epp = false;
            op.zonas.forEach(function (z) { if (zonasSel[z.id]) { sctr = sctr || z.sctr; epp = epp || z.epp; } });
            aviso.hidden = !(sctr || epp);
            aviso.textContent = (sctr || epp) ? 'Para estas zonas Vigilancia verificará ' + [sctr ? 'el SCTR' : '', epp ? 'el uso de EPP' : ''].filter(Boolean).join(' y ') + ' al ingreso.' : '';
        }
        op.zonas.forEach(function (z) {
            var chk = el('input', { type: 'checkbox' }); chk.checked = !!zonasSel[z.id];
            var fila = el('label', { class: 'zona' + (chk.checked ? ' on' : '') }, [chk, el('span', { text: z.texto })]);
            chk.addEventListener('change', function () { zonasSel[z.id] = chk.checked; fila.classList.toggle('on', chk.checked); sincZonas(); });
            zonasNodo.appendChild(fila);
        });
        sincZonas();

        var nodo = el('div', { class: 'stack' }, [
            el('div', { class: 'grid g3' }, [campo('Sede', el('input', { type: 'text', value: op.sede.texto, disabled: true })), campo('Fecha de la visita *', fecha), campo('Hora prevista *', hora)]),
            campo('Empresa o procedencia *', empresa),
            el('div', { class: 'field' }, [el('span', { class: 'field-l', text: 'Responsable de atención *' }), caja]),
            el('div', { class: 'grid g2' }, [campo('Motivo de la visita *', motivo), detalleCampo]),
            zonasNodo, aviso,
            campo('Detalles adicionales (opcional)', obs),
            campo('Correos en copia (opcional)', copias, 'Reciben copia de los avisos de la solicitud (nueva, decisiones, cancelación). Sepárelos con «;».')
        ]);

        function leer() {
            return {
                fecha: fecha.value, hora: hora.value, empresa: empresa.value, responsableId: resp.id, responsable: resp.nombre,
                motivoId: motivo.value ? Number(motivo.value) : null, motivoDetalle: detalle.value, observaciones: obs.value,
                zonasIds: op.zonas.filter(function (z) { return zonasSel[z.id]; }).map(function (z) { return z.id; }), copias: copias.value
            };
        }
        // Validación mínima de formulario; las reglas de fondo las valida el servidor.
        function validar() {
            var d = leer();
            if (!d.fecha || !d.hora) return 'Indique la fecha y la hora de la visita.';
            if (d.fecha < hoy()) return 'La fecha de la visita no puede ser anterior a hoy.';
            if (!d.empresa.trim()) return 'Indique la empresa o procedencia.';
            if (!d.responsableId) return 'Elija al responsable de atención.';
            if (!d.motivoId) return 'Elija el motivo de la visita.';
            if (!detalleCampo.hidden && !d.motivoDetalle.trim()) return 'Describa el motivo de la visita.';
            if (!d.zonasIds.length) return 'Marque al menos una zona.';
            return '';
        }
        return { nodo: nodo, leer: leer, validar: validar };
    }

    // ── Persona externa ──────────────────────────────────────────────────────────────────────
    // ini: persona a editar {tipoDocId, doc, apellidoPaterno, apellidoMaterno, nombres} (opcional).
    // Devuelve {nodo, guardar()}; guardar() registra/corrige la persona y entrega {id, nombreCompleto, doc} a la promesa.
    function formPersona(op, urlBuscar, urlGuardar, ini) {
        ini = ini || {};
        var tipo = el('select'); op.tiposDoc.forEach(function (t) { tipo.appendChild(el('option', { value: String(t.id), text: t.texto })); });
        tipo.value = String(ini.tipoDocId || (op.tiposDoc[0] && op.tiposDoc[0].id) || '');
        var doc = texto(ini.doc, 20, 'Número de documento');
        var ap = texto(ini.apellidoPaterno, 100), am = texto(ini.apellidoMaterno, 100), nom = texto(ini.nombres, 200);
        var nota = el('p', { class: 'field-h' });
        var hallada = null;

        function buscar() {
            hallada = null; nota.textContent = '';
            if (doc.value.trim().length < 4) return;
            CAF.pedir(urlBuscar + '?tipoDocId=' + encodeURIComponent(tipo.value) + '&doc=' + encodeURIComponent(doc.value.trim())).then(function (r) {
                if (!r.success || !r.data) { if (r.success) nota.textContent = 'No está registrada: complete sus datos y quedará registrada.'; return; }
                hallada = r.data; ap.value = r.data.apellidoPaterno || ''; am.value = r.data.apellidoMaterno || ''; nom.value = r.data.nombres || '';
                nota.textContent = 'Ya está registrada. Si su nombre está mal, corríjalo aquí y se actualizará.';
            });
        }
        doc.addEventListener('change', buscar); tipo.addEventListener('change', buscar);
        if (ini.doc) hallada = { id: ini.id || 0 };

        var nodo = el('div', { class: 'stack pform' }, [
            el('div', { class: 'grid g2' }, [campo('Tipo de documento', tipo), campo('Número *', doc)]),
            el('div', { class: 'grid g3' }, [campo('Apellido paterno *', ap), campo('Apellido materno', am), campo('Nombres *', nom)]),
            nota
        ]);

        function guardar() {
            if (!doc.value.trim() || !ap.value.trim() || !nom.value.trim()) return Promise.resolve({ success: false, message: 'Complete el documento, el apellido paterno y los nombres.' });
            var id = hallada && hallada.id ? hallada.id : 0;
            var sinCambios = hallada && hallada.id && hallada.apellidoPaterno === ap.value.trim() && (hallada.apellidoMaterno || '') === am.value.trim() && hallada.nombres === nom.value.trim();
            if (sinCambios) return Promise.resolve({ success: true, data: { id: id, nombreCompleto: hallada.nombreCompleto, doc: doc.value.trim() } });
            return CAF.pedir(urlGuardar, { method: 'POST', body: { id: id, tipoDocId: Number(tipo.value) || 0, doc: doc.value, apellidoPaterno: ap.value, apellidoMaterno: am.value, nombres: nom.value } });
        }
        // Antes de guardar se consulta el documento por si la persona ya existe aunque no se haya salido del campo.
        function listo() {
            if (hallada || doc.value.trim().length < 4) return guardar();
            return CAF.pedir(urlBuscar + '?tipoDocId=' + encodeURIComponent(tipo.value) + '&doc=' + encodeURIComponent(doc.value.trim())).then(function (r) {
                if (r.success && r.data) {
                    hallada = r.data;
                    if (!ap.value.trim() && !nom.value.trim()) { ap.value = r.data.apellidoPaterno || ''; am.value = r.data.apellidoMaterno || ''; nom.value = r.data.nombres || ''; }
                }
                return guardar();
            });
        }
        return { nodo: nodo, guardar: listo };
    }

    return { el: el, chipEstado: chipEstado, chipPersona: chipPersona, textoIngreso: textoIngreso, hoy: hoy, fechaLarga: fechaLarga, campo: campo,
             errores: errores, cargarOpciones: cargarOpciones, formDatos: formDatos, formPersona: formPersona };
})();

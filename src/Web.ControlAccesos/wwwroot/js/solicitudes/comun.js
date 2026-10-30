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
    // Lista de sugerencias bajo un campo de texto. cargar(q) devuelve una promesa con [{t: texto, s: subtexto, v: valor}]; alElegir(v) recibe el valor.
    function sugerencias(input, minimo, cargar, alElegir) {
        var caja = el('div', { class: 'sug' }), temp = null, ult = '';
        caja.hidden = true;
        function ocultar() { caja.hidden = true; caja.textContent = ''; }
        input.addEventListener('input', function () {
            clearTimeout(temp);
            var q = input.value.trim();
            if (q.length < minimo) { ocultar(); return; }
            temp = setTimeout(function () {
                ult = q;
                cargar(q).then(function (items) {
                    if (q !== ult) return;
                    caja.textContent = '';
                    if (!items || !items.length) { caja.hidden = true; return; }
                    caja.hidden = false;
                    items.forEach(function (it) {
                        var b = el('button', { type: 'button' }, [el('span', { text: it.t })]);
                        if (it.s) b.appendChild(el('small', { class: 'sug-sub', text: ' ' + it.s }));
                        b.addEventListener('mousedown', function (e) { e.preventDefault(); ocultar(); alElegir(it.v); });
                        caja.appendChild(b);
                    });
                });
            }, 250);
        });
        input.addEventListener('blur', function () { setTimeout(ocultar, 150); });
        return caja;
    }

    // v: valores iniciales {fecha,hora,empresa,responsableId,responsable,motivoId,motivoDetalle,observaciones,zonasIds,copias,
    //    tipoId,sedeId,cochera,placa,areaDetalle,contactoNombre,contactoTelefonos,contactoCorreos}
    // modo: 'crear' (tipo y sede se eligen) | 'editar' (tipo y sede quedan fijos, solo se muestran).
    // El tipo de ingreso decide qué campos se muestran y cuáles se envían (Entrega H): los datos de un tipo no pasan al otro.
    function formDatos(op, urlResp, v, modo) {
        v = v || {};
        var editar = modo === 'editar';
        var CONTRATISTA = 'CONTRATISTA';

        // ── Tipo de ingreso y sede ──
        var usables = op.tipos.filter(function (t) { return t.usable; });
        var tipoSel = el('select');
        op.tipos.forEach(function (t) {
            var o = el('option', { value: String(t.id), text: t.texto + (t.usable ? '' : ' — ' + (t.leyenda || 'Próximamente')) });
            if (!t.usable) o.disabled = true;
            tipoSel.appendChild(o);
        });
        var tipoIni = op.tipos.filter(function (t) { return t.id === v.tipoId && (t.usable || editar); })[0] || usables[0];
        tipoSel.value = tipoIni ? String(tipoIni.id) : '';
        var tipoAyuda = el('span', { class: 'field-h' });
        var sedeSel = el('select');
        op.sedes.forEach(function (s) { sedeSel.appendChild(el('option', { value: String(s.id), text: s.texto })); });
        var sedeIni = op.sedes.filter(function (s) { return s.id === v.sedeId; })[0] || (editar ? { id: v.sedeId, texto: v.sede || '', cochera: !!v.cochera, zonas: [] } : op.sedes[0]);
        if (!op.sedes.some(function (s) { return s.id === sedeIni.id; })) { op.sedes.push(sedeIni); sedeSel.appendChild(el('option', { value: String(sedeIni.id), text: sedeIni.texto })); }
        sedeSel.value = String(sedeIni.id);
        if (editar) { tipoSel.disabled = true; sedeSel.disabled = true; }
        function tipoActual() { return op.tipos.filter(function (t) { return String(t.id) === tipoSel.value; })[0] || { id: 0, codigo: '', texto: '' }; }
        function sedeActual() { return op.sedes.filter(function (s) { return String(s.id) === sedeSel.value; })[0] || { id: 0, texto: '', cochera: false, zonas: [] }; }
        function esContratista() { return tipoActual().codigo === CONTRATISTA; }

        // ── Campos comunes ──
        var fecha = el('input', { type: 'date', min: hoy() }); fecha.value = v.fecha || '';
        var hora = el('input', { type: 'time' }); hora.value = v.hora || '';
        var empresa = texto(v.empresa, 250, '');
        var motivo = el('select'); motivo.appendChild(el('option', { value: '', text: 'Elija el motivo' }));
        op.motivos.forEach(function (m) { motivo.appendChild(el('option', { value: String(m.id), text: m.texto })); });
        motivo.value = v.motivoId && op.motivos.some(function (m) { return m.id === v.motivoId; }) ? String(v.motivoId) : '';
        var detalle = texto(esContratista() ? '' : v.motivoDetalle, 250, 'Describa el motivo');
        var detalleCampo = campo('Detalle del motivo *', detalle);
        var obs = el('textarea', { rows: '2', maxlength: '500', placeholder: 'Opcional. Se incluye en el correo que reciben Coordinación, Vigilancia y las personas en copia' }); obs.value = v.observaciones || '';
        var sugEmpresa = sugerencias(empresa, 2, function (q) {
            return CAF.pedir(urlResp.replace(/Responsables$/, 'Empresas') + '?q=' + encodeURIComponent(q)).then(function (r) {
                return r.success ? r.data.map(function (e) { return { t: e, v: e }; }) : [];
            });
        }, function (e) { empresa.value = e; });
        var copias = texto(v.copias, 500, 'correo1@empresa.com; correo2@empresa.com');

        function sincMotivo() {
            var m = op.motivos.filter(function (x) { return String(x.id) === motivo.value; })[0];
            detalleCampo.hidden = !(m && m.esOtro);
        }
        motivo.addEventListener('change', sincMotivo); sincMotivo();

        // ── Campos del contratista ──
        var actividades = el('textarea', { rows: '3', maxlength: '250', placeholder: 'Ej.: mantenimiento de aire acondicionado, cableado de red…' }); actividades.value = esContratista() ? (v.motivoDetalle || '') : '';
        var areaDetalle = texto(v.areaDetalle, 300, 'Opcional. Ej.: sala de servidores, segundo piso');
        var cNombre = texto(v.contactoNombre, 200, 'Persona de contacto de la empresa contratista');
        var cTel = texto(v.contactoTelefonos, 100, '999 111 222; 01 555 0000');
        var cCorreos = texto(v.contactoCorreos, 500, 'contacto@contratista.com; otro@contratista.com');

        // ── Cochera ──
        var cochera = el('select', {}, [el('option', { value: 'N', text: 'No' }), el('option', { value: 'Y', text: 'Sí' })]);
        cochera.value = v.cochera ? 'Y' : 'N';
        var placa = texto(v.placa, 8, 'Ej.: ABC123'); placa.style.textTransform = 'uppercase';
        var placaCampo = campo('Placa del vehículo *', placa, 'De 5 a 8 letras o números.');
        var cocheraBloque = el('div', { class: 'grid g2' }, [campo('¿Requiere cochera?', cochera), placaCampo]);
        function sincCochera() { placaCampo.hidden = cochera.value !== 'Y'; }
        cochera.addEventListener('change', sincCochera); sincCochera();

        // ── Responsable de atención: se busca desde 2 letras ──
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

        // ── Zonas (dependen de la sede) ──
        var zonasSel = {}; (v.zonasIds || []).forEach(function (id) { zonasSel[id] = true; });
        var aviso = el('div', { class: 'aviso a-warn' }); aviso.hidden = true;
        var zonasLegend = el('legend');
        var zonasNodo = el('fieldset', { class: 'zonas' }, [zonasLegend]);
        function sincZonas() {
            var sctr = false, epp = false;
            sedeActual().zonas.forEach(function (z) { if (zonasSel[z.id]) { sctr = sctr || z.sctr; epp = epp || z.epp; } });
            aviso.hidden = !(sctr || epp);
            aviso.textContent = (sctr || epp) ? 'Para estas zonas Vigilancia verificará ' + [sctr ? 'el SCTR' : '', epp ? 'el uso de EPP' : ''].filter(Boolean).join(' y ') + ' al ingreso.' : '';
        }
        function pintarZonas() {
            while (zonasNodo.childNodes.length > 1) zonasNodo.removeChild(zonasNodo.lastChild);
            zonasLegend.textContent = esContratista() ? 'Área donde se ejecutará el trabajo *' : 'Zonas que visitarán *';
            var zs = sedeActual().zonas;
            Object.keys(zonasSel).forEach(function (k) { if (!zs.some(function (z) { return String(z.id) === k; })) delete zonasSel[k]; });
            zs.forEach(function (z) {
                var chk = el('input', { type: 'checkbox' }); chk.checked = !!zonasSel[z.id];
                var fila = el('label', { class: 'zona' + (chk.checked ? ' on' : '') }, [chk, el('span', { text: z.texto })]);
                chk.addEventListener('change', function () { zonasSel[z.id] = chk.checked; fila.classList.toggle('on', chk.checked); sincZonas(); });
                zonasNodo.appendChild(fila);
            });
            if (!zs.length) zonasNodo.appendChild(el('p', { class: 'vacio', text: 'Esta sede no tiene zonas configuradas. Pida al administrador que las agregue en Catálogos.' }));
            sincZonas();
        }

        // ── Diseño según el tipo ──
        var nodo = el('div', { class: 'stack' });
        function armar() {
            var c = esContratista(), t = tipoActual();
            tipoAyuda.textContent = editar ? 'El tipo de ingreso y la sede no se pueden cambiar. Si se equivocó, cancele y cree otra solicitud.' : '';
            nodo.textContent = '';
            nodo.appendChild(el('div', { class: 'grid g2' }, [campo('Tipo de ingreso *', tipoSel, editar ? null : (t.codigo ? null : 'Elija el tipo de ingreso.')), campo('Sede *', sedeSel)]));
            if (editar) nodo.appendChild(tipoAyuda);
            nodo.appendChild(el('div', { class: 'grid g2' }, [campo(c ? 'Fecha del servicio *' : 'Fecha de la visita *', fecha), campo(c ? 'Hora prevista del servicio *' : 'Hora prevista *', hora)]));
            empresa.placeholder = c ? 'Nombre de la empresa contratista' : 'Empresa o procedencia de los visitantes';
            nodo.appendChild(campo(c ? 'Empresa contratista *' : 'Empresa o procedencia *', el('div', { class: 'sug-wrap' }, [empresa, sugEmpresa])));
            nodo.appendChild(el('div', { class: 'field' }, [el('span', { class: 'field-l', text: 'Responsable de atención *' }), caja]));
            if (c) {
                nodo.appendChild(campo('Actividad(es) a realizar *', actividades));
                nodo.appendChild(zonasNodo); nodo.appendChild(aviso);
                nodo.appendChild(campo('Detalle del área (opcional)', areaDetalle));
                nodo.appendChild(el('h4', { text: 'Contacto de la empresa contratista' }));
                nodo.appendChild(el('div', { class: 'grid g3' }, [campo('Nombre del contacto *', cNombre), campo('Teléfonos *', cTel, 'Varios, separados por «;».'), campo('Correos *', cCorreos, 'Varios, separados por «;». No se copian solos a los avisos.')]));
            } else {
                nodo.appendChild(el('div', { class: 'grid g2' }, [campo('Motivo de la visita *', motivo), detalleCampo]));
                nodo.appendChild(zonasNodo); nodo.appendChild(aviso);
            }
            if (sedeActual().cochera) nodo.appendChild(cocheraBloque);
            nodo.appendChild(campo('Detalles adicionales (opcional)', obs));
            nodo.appendChild(campo('Correos en copia (opcional)', copias, 'Reciben copia de los avisos de la solicitud (nueva, decisiones, cancelación). Sepárelos con «;».'));
            pintarZonas();
        }
        tipoSel.addEventListener('change', armar);
        sedeSel.addEventListener('change', armar);
        armar();

        function leer() {
            var c = esContratista(), conCochera = sedeActual().cochera && cochera.value === 'Y';
            return {
                tipoId: Number(tipoSel.value) || 0, tipoCodigo: tipoActual().codigo, tipoTexto: tipoActual().texto, sedeId: Number(sedeSel.value) || 0, sedeTexto: sedeActual().texto,
                fecha: fecha.value, hora: hora.value, empresa: empresa.value, responsableId: resp.id, responsable: resp.nombre,
                motivoId: c ? null : (motivo.value ? Number(motivo.value) : null),
                motivoDetalle: c ? actividades.value : detalle.value, observaciones: obs.value,
                zonasIds: sedeActual().zonas.filter(function (z) { return zonasSel[z.id]; }).map(function (z) { return z.id; }), copias: copias.value,
                cochera: conCochera, placa: conCochera ? placa.value.toUpperCase().replace(/[\s-]/g, '') : '',
                areaDetalle: c ? areaDetalle.value : '', contactoNombre: c ? cNombre.value : '', contactoTelefonos: c ? cTel.value : '', contactoCorreos: c ? cCorreos.value : ''
            };
        }
        // Validación mínima de formulario; las reglas de fondo las valida el servidor.
        function validar() {
            var d = leer(), c = esContratista();
            if (!d.tipoId) return 'Elija el tipo de ingreso.';
            if (!d.sedeId) return 'Elija la sede.';
            if (!d.fecha || !d.hora) return c ? 'Indique la fecha y la hora del servicio.' : 'Indique la fecha y la hora de la visita.';
            if (d.fecha < hoy()) return c ? 'La fecha del servicio no puede ser anterior a hoy.' : 'La fecha de la visita no puede ser anterior a hoy.';
            if (!d.empresa.trim()) return c ? 'Indique la empresa contratista.' : 'Indique la empresa o procedencia.';
            if (!d.responsableId) return 'Elija al responsable de atención.';
            if (c) {
                if (!d.motivoDetalle.trim()) return 'Describa la(s) actividad(es) a realizar.';
            } else {
                if (!d.motivoId) return 'Elija el motivo de la visita.';
                if (!detalleCampo.hidden && !d.motivoDetalle.trim()) return 'Describa el motivo de la visita.';
            }
            if (!d.zonasIds.length) return c ? 'Marque al menos un área de trabajo.' : 'Marque al menos una zona.';
            if (c) {
                if (!d.contactoNombre.trim()) return 'Indique el nombre del contacto de la empresa contratista.';
                if (d.contactoTelefonos.replace(/\D/g, '').length < 6) return 'Indique al menos un teléfono de contacto.';
                if (!d.contactoCorreos.trim()) return 'Indique al menos un correo de contacto.';
            }
            if (d.cochera && d.placa.length < 5) return 'Indique la placa del vehículo (de 5 a 8 letras o números).';
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
        var auto = false; // true cuando los nombres vinieron de una persona ya registrada

        // Si cambia el documento tras un autocompletado, esos nombres ya no corresponden: se limpian.
        function limpiarAuto() {
            if (!auto) return;
            auto = false; hallada = null; ap.value = ''; am.value = ''; nom.value = ''; nota.textContent = '';
        }
        function buscar() {
            limpiarAuto(); hallada = null; nota.textContent = '';
            if (doc.value.trim().length < 4) return;
            CAF.pedir(urlBuscar + '?tipoDocId=' + encodeURIComponent(tipo.value) + '&doc=' + encodeURIComponent(doc.value.trim())).then(function (r) {
                if (!r.success || !r.data) { if (r.success) nota.textContent = 'No está registrada: complete sus datos y quedará registrada.'; return; }
                hallada = r.data; auto = true; ap.value = r.data.apellidoPaterno || ''; am.value = r.data.apellidoMaterno || ''; nom.value = r.data.nombres || '';
                nota.textContent = 'Ya está registrada. Si su nombre está mal, corríjalo aquí y se actualizará.';
            });
        }
        doc.addEventListener('input', limpiarAuto); doc.addEventListener('change', buscar); tipo.addEventListener('change', buscar);
        if (ini.doc) hallada = { id: ini.id || 0 };

        // Autocompletar por nombre: al elegir una persona registrada se llenan documento y nombres.
        var sugPersona = sugerencias(ap, 3, function (q) {
            return CAF.pedir(urlBuscar.replace(/PersonaPorDocumento$/, 'PersonasBuscar') + '?q=' + encodeURIComponent(q)).then(function (r) {
                return r.success ? r.data.map(function (p) { return { t: p.nombreCompleto, s: (p.tipoDoc || '') + ' ' + p.doc, v: p }; }) : [];
            });
        }, function (p) {
            tipo.value = String(p.tipoDocId); doc.value = p.doc;
            hallada = { id: p.id, apellidoPaterno: p.apellidoPaterno, apellidoMaterno: p.apellidoMaterno, nombres: p.nombres, nombreCompleto: p.nombreCompleto };
            auto = true; ap.value = p.apellidoPaterno || ''; am.value = p.apellidoMaterno || ''; nom.value = p.nombres || '';
            nota.textContent = 'Ya está registrada. Si su nombre está mal, corríjalo aquí y se actualizará.';
        });
        var nodo = el('div', { class: 'stack pform' }, [
            el('div', { class: 'grid g2' }, [campo('Tipo de documento', tipo), campo('Número *', doc)]),
            el('div', { class: 'grid g3' }, [campo('Apellido paterno *', el('div', { class: 'sug-wrap' }, [ap, sugPersona]), 'Escriba 3 letras para ver personas ya registradas.'), campo('Apellido materno', am), campo('Nombres *', nom)]),
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
                    if (!ap.value.trim() && !nom.value.trim()) { auto = true; ap.value = r.data.apellidoPaterno || ''; am.value = r.data.apellidoMaterno || ''; nom.value = r.data.nombres || ''; }
                }
                return guardar();
            });
        }
        return { nodo: nodo, guardar: listo };
    }

    return { el: el, chipEstado: chipEstado, chipPersona: chipPersona, textoIngreso: textoIngreso, hoy: hoy, fechaLarga: fechaLarga, campo: campo,
             errores: errores, cargarOpciones: cargarOpciones, formDatos: formDatos, formPersona: formPersona };
})();

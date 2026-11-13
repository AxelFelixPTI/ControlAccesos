// Asistente «Nueva solicitud» en 3 pasos: datos de la visita, personas y revisión. También sirve para «Reutilizar»
// (parte de los datos y las personas de otra solicitud; la fecha se elige de nuevo).
(function () {
    'use strict';
    var raiz = document.getElementById('caf-nueva');
    if (!raiz) return;
    var el = CAF.el;
    var d = raiz.dataset;
    var origen = Number(d.reutilizar) || 0;
    var op = null, formDatos = null, formPer = null, paso = 1, enviando = false;
    var personas = [];            // [{id, nombre, doc}]
    var adj = null;               // selector de documentos adjuntos (Entrega J): vive en memoria y sobrevive al cambio de paso
    var cuerpo = document.getElementById('w-cuerpo'), pasos = document.getElementById('w-pasos'), ayuda = document.getElementById('w-ayuda');
    var atras = document.getElementById('w-atras'), sigue = document.getElementById('w-sigue');
    var TITULOS = ['Datos de la visita', 'Personas', 'Revisión y envío'];
    var AYUDAS = ['Elija el tipo de ingreso y la sede; indique cuándo, quién atiende y a qué zonas irán.', 'Agregue a cada persona que ingresará. Si ya la registró antes, se completa sola con su documento.', 'Revise y envíe. Coordinación decidirá persona por persona.'];

    // ── Proveedor (D-223/D-237): cada persona lleva un rol (Conductor o Ayudante de descarga). El conductor debe indicar la placa de su
    //    vehículo; los demás datos del vehículo y del transportista son opcionales y van compactados tras «+ Más datos…». ──
    var CAMPOS_T = [['ruc', 'RUC del transportista', 11, 'Opcional. 11 dígitos.'], ['nombre', 'Nombre o razón social del transportista', 200, ''], ['direccion', 'Dirección del transportista', 300, ''],
                    ['placa', 'Placa del vehículo', 8, 'De 5 a 8 letras o números.'], ['marca', 'Marca del vehículo', 50, ''], ['licencia', 'Licencia del conductor', 20, '']];
    // Roles (subtipos) activos del tipo de ingreso elegido (D-234); vacío si el tipo no tiene.
    function subtiposDelTipo() { var v = formDatos ? formDatos.leer() : null; return v ? (op.subtipos || []).filter(function (x) { return x.tipoId === v.tipoId; }) : []; }
    function esProv() { return !!formDatos && formDatos.leer().tipoCodigo === 'PROVEEDOR'; }
    function limpiaPlaca(t) { return String(t || '').toUpperCase().replace(/[\s-]/g, ''); }
    function bloqueTransportista() {
        var ins = {}, activo = false;
        var panel = el('div', { class: 'stack' }), mas = SOL.fila([]);
        var placa = el('input', { type: 'text', maxlength: '8', placeholder: 'Ej.: ABC123' }); placa.style.textTransform = 'uppercase';
        CAMPOS_T.forEach(function (c) {
            if (c[0] === 'placa') return;
            ins[c[0]] = el('input', { type: 'text', maxlength: String(c[2]) });
            mas.appendChild(SOL.w(c[0] === 'nombre' || c[0] === 'direccion' ? 'f-l' : 'f-s', SOL.campo(c[1], ins[c[0]], null)));
        });
        var opc = SOL.opcional('Más datos del vehículo y del transportista', mas, false, function () { Object.keys(ins).forEach(function (k) { ins[k].value = ''; }); });
        panel.appendChild(SOL.fila([SOL.w('f-xs', SOL.campo('Placa *', placa))]));
        panel.appendChild(opc.nodo);
        function sinc() { panel.hidden = !activo; }
        sinc();
        return {
            nodo: el('div', { class: 'stack' }, [panel]),
            placaValida: function () { var x = limpiaPlaca(placa.value); return x.length >= 5 && x.length <= 8 && /^[A-Z0-9]+$/.test(x); },
            leer: function () {
                var d = {}; CAMPOS_T.forEach(function (c) { d[c[0]] = c[0] === 'placa' ? limpiaPlaca(placa.value) : (opc.abierto() ? ins[c[0]].value.trim() : ''); });
                return { datos: d };
            },
            activar: function (b) { activo = !!b; sinc(); }   // D-234: se muestra solo cuando el rol elegido es Conductor
        };
    }

    function pintarPasos() {
        pasos.textContent = '';
        TITULOS.forEach(function (t, i) {
            var n = i + 1;
            pasos.appendChild(el('li', { class: n === paso ? 'on' : (n < paso ? 'done' : '') }, [el('button', { type: 'button', onclick: function () { if (n < paso) { paso = n; mostrar(); } } },
                [el('span', { class: 'sn', text: n < paso ? '✓' : String(n) }), t])]));
        });
        ayuda.textContent = paso === 2 && esProv() ? 'Agregue a cada persona de la entrega: el conductor (con la placa de su vehículo) y, si hay, el ayudante de descarga.' : AYUDAS[paso - 1];
        atras.hidden = paso === 1;
        sigue.textContent = paso === 3 ? 'Enviar solicitud' : 'Continuar';
    }

    function paso2() {
        var lista = el('ul', { class: 'plist' }), titulo = el('h3');
        function pintarLista() {
            titulo.textContent = (prov ? 'Personas de la entrega (' : 'Personas de la visita (') + personas.length + ')';
            lista.textContent = '';
            if (!personas.length) { lista.appendChild(el('li', {}, [el('span', { class: 'vacio', text: 'Aún no agregó personas.' })])); return; }
            personas.forEach(function (p, i) {
                var etiqueta = !prov ? '' : p.transp ? (personas.filter(function (x) { return x.transp; })[0] === p ? ' · Conductor principal' : ' · Conductor') + ' · placa ' + (p.datos.placa || '—') : ' · Ayudante de descarga';
                lista.appendChild(el('li', {}, [
                    el('div', { class: 'plist-m' }, [el('div', { class: 'pn', text: p.nombre }), el('div', { class: 'field-h', text: p.doc + etiqueta })]),
                    el('button', { type: 'button', class: 'btn btn-sm btn-danger-o', text: 'Quitar', onclick: function () { personas.splice(i, 1); pintarLista(); } })
                ]));
            });
        }
        var prov = esProv(), bt = prov ? bloqueTransportista() : null;
        var error = el('p', { class: 'field-e' });
        // D-234: «Rol de la persona»: un solo rol por persona, solo si el tipo de ingreso tiene subtipos; viene marcado el predeterminado
        var subs = subtiposDelTipo(), rolSel = null;
        if (subs.length) {
            rolSel = el('select');
            subs.forEach(function (x) { rolSel.appendChild(el('option', { value: String(x.id), text: x.texto })); });
            rolSel.value = String((subs.filter(function (x) { return x.predeterminado; })[0] || subs[0]).id);
            rolSel.addEventListener('change', function () { if (bt) bt.activar(rolActual() && rolActual().codigo === 'TRANSPORTISTA'); });
        }
        function rolActual() { return rolSel ? subs.filter(function (x) { return String(x.id) === rolSel.value; })[0] : null; }
        formPer = SOL.formPersona(op, d.urlBuscar, d.urlPersona);
        var agregar = el('button', { type: 'button', class: 'btn btn-sm', text: '+ Agregar persona' });
        agregar.addEventListener('click', function () {
            error.textContent = '';
            var rol0 = rolActual();
            if (bt && rol0 && rol0.codigo === 'TRANSPORTISTA' && !bt.placaValida()) { error.textContent = 'Indique la placa del vehículo del conductor (de 5 a 8 letras o números).'; return; }
            formPer.guardar().then(function (r) {
                if (!r.success) { error.textContent = SOL.errores(r); return; }
                if (personas.some(function (p) { return p.id === r.data.id; })) { error.textContent = 'Esa persona ya está en la lista.'; return; }
                var rol = rolActual(), transp = !!(bt && rol && rol.codigo === 'TRANSPORTISTA');
                var t = bt && transp ? bt.leer() : { datos: {} };
                personas.push({ id: r.data.id, nombre: r.data.nombreCompleto, doc: r.data.doc, transp: transp, datos: t.datos, subtipoId: rol ? rol.id : null, subtipoTexto: rol ? rol.texto : '' });
                formPer = SOL.formPersona(op, d.urlBuscar, d.urlPersona);   // formulario limpio para la siguiente
                caja.textContent = ''; caja.appendChild(formPer.nodo);
                if (bt) { bt = bloqueTransportista(); cajaT.textContent = ''; cajaT.appendChild(bt.nodo); bt.activar(rolActual() && rolActual().codigo === 'TRANSPORTISTA'); }
                pintarLista();
            });
        });
        var caja = el('div'); caja.appendChild(formPer.nodo);
        var cajaT = el('div'); if (bt) { cajaT.appendChild(bt.nodo); bt.activar(rolActual() && rolActual().codigo === 'TRANSPORTISTA'); }
        pintarLista();
        if (!adj) adj = ADJ.selector(d.urlAdj);
        var guia = prov ? el('div', { class: 'aviso a-info', text: 'Todas las personas necesitan documento y nombres (con eso las valida Coordinación y las recibe Vigilancia). Debe haber al menos un conductor, con la placa de su vehículo; el primero que agregue es el principal.' }) : null;
        return el('div', { class: 'stack' }, [guia, titulo, lista, el('hr'), el('h4', { text: 'Agregar persona' }), caja, SOL.fila([rolSel ? SOL.w('f-m', SOL.campo('Rol de la persona', rolSel)) : null, cajaT]), error, el('div', { class: 'row-end' }, [agregar]), el('hr'), adj.nodo]);
    }

    function paso3() {
        var v = formDatos.leer();
        var sede = op.sedes.filter(function (s) { return s.id === v.sedeId; })[0] || { texto: '', zonas: [] };
        var zonas = sede.zonas.filter(function (z) { return v.zonasIds.indexOf(z.id) >= 0; }).map(function (z) { return z.texto; }).join(', ');
        var motivo = (op.motivos.filter(function (m) { return m.id === v.motivoId; })[0] || {}).texto || '';
        var c = v.tipoCodigo === 'CONTRATISTA', p = v.tipoCodigo === 'PROVEEDOR';
        var dl = el('dl', { class: 'dl' });
        var filas = [['Tipo de ingreso', v.tipoTexto], ['Sede', sede.texto], (c && v.dias && v.dias.length) ? ['Días de trabajo (' + v.dias.length + ')', v.dias.map(function (f) { return SOL.fechaLarga(f); }).join(', ') + ' · ' + SOL.textoHoras(v.horaDesde, v.horaHasta)] : [c ? 'Servicio' : p ? 'Entrega' : 'Visita', SOL.fechaLarga(v.fecha) + ' · ' + v.hora + (p && v.horaHasta ? ' – ' + v.horaHasta + ' (estimada)' : '')], [c ? 'Empresa contratista' : p ? 'Empresa proveedora' : 'Empresa', v.empresa]];
        if (p) {
            filas.push(['N.º de OC', (v.numerosOc || []).join(', ')], ['Transporte', v.empresaTransportista || 'El mismo proveedor'], ['Empresa(s) receptora(s)', v.empresaDestino],
                ['Contacto del responsable', v.contactoNombre + ' · ' + v.contactoTelefonos.split(';').join(', ')]);
            if (v.contactoCorreos) filas.push(['Correo del responsable', v.contactoCorreos]);
        }
        else if (c) filas.push(['Actividad(es)', v.motivoDetalle], ['Área de trabajo', zonas + (v.areaDetalle ? ' — ' + v.areaDetalle : '')],
            ['Contacto', v.contactoNombre + ' · ' + v.contactoTelefonos], ['Correos de contacto', v.contactoCorreos]);
        else filas.push(['Motivo', motivo + (v.motivoDetalle ? ' — ' + v.motivoDetalle : '')], ['Zonas', zonas]);
        if (!p && (v.responsable || !c)) filas.push(['Responsable de atención', v.responsable]);
        if (v.cochera) filas.push(['Cochera', 'Sí · placa ' + v.placa]);
        filas.push(['Detalles adicionales', v.observaciones || '—'], ['Correos en copia', v.copias || '—']);
        filas
            .forEach(function (x) { dl.appendChild(el('dt', { text: x[0] })); dl.appendChild(el('dd', { text: x[1] })); });
        var lista = el('ul', { class: 'plist' }, personas.map(function (q) {
            var det = '';
            if (p && q.transp) det = ' · Conductor' + (personas.filter(function (x) { return x.transp; })[0] === q ? ' principal' : '') + ': ' +
                CAMPOS_T.map(function (cc) { return q.datos[cc[0]] ? cc[1] + ' ' + q.datos[cc[0]] : ''; }).filter(Boolean).join(', ');
            return el('li', {}, [el('div', { class: 'plist-m' }, [el('div', { class: 'pn', text: q.nombre }), el('div', { class: 'field-h', text: q.doc + det })])]);
        }));
        var docs = adj ? adj.archivos() : [];
        var tipo = el('div', { class: 'aviso a-info' }, ['Tipo de ingreso: ', SOL.chipTipo(v.tipoCodigo, v.tipoTexto), ' Coordinación revisará la solicitud y decidirá persona por persona.']);
        return el('div', { class: 'stack' }, [dl, el('h3', { text: 'Personas (' + personas.length + ')' }), lista,
            el('h3', { text: 'Documentos adjuntos (' + docs.length + ')' }),
            docs.length ? el('ul', { class: 'plist' }, docs.map(function (f) { return el('li', {}, [el('div', { class: 'plist-m' }, [el('div', { class: 'pn', text: f.name }), el('div', { class: 'field-h', text: (f.size >= 1048576 ? (f.size / 1048576).toFixed(1) + ' MB' : Math.max(1, Math.round(f.size / 1024)) + ' KB') })])]); })) : el('p', { class: 'field-h', text: 'Sin documentos adjuntos.' }),
            tipo, el('p', { class: 'field-e', id: 'w-error' })]);
    }

    function mostrar() {
        pintarPasos();
        cuerpo.textContent = '';
        if (paso === 1) cuerpo.appendChild(formDatos.nodo);
        else if (paso === 2) cuerpo.appendChild(paso2());
        else cuerpo.appendChild(paso3());
        window.scrollTo(0, 0);
    }

    atras.addEventListener('click', function () { if (paso > 1) { paso--; mostrar(); } });
    sigue.addEventListener('click', function () {
        if (enviando) return;
        if (paso === 1) {
            var e = formDatos.validar();
            if (e) { CAF.aviso(e, 'warn'); return; }
            paso = 2; mostrar(); return;
        }
        if (paso === 2) {
            if (!personas.length) { CAF.aviso('Agregue al menos una persona.', 'warn'); return; }
            if (esProv()) {
                if (!personas.some(function (p) { return p.transp; })) { CAF.aviso('Agregue al menos un conductor entre las personas (rol «Conductor»).', 'warn'); return; }
                var sinPlaca = personas.filter(function (p) { return p.transp && !String(p.datos.placa || '').trim(); })[0];
                if (sinPlaca) { CAF.aviso('Falta la placa del vehículo de ' + sinPlaca.nombre + '. Quítelo y agréguelo otra vez indicando la placa.', 'warn'); return; }
            }
            paso = 3; mostrar(); return;
        }
        var v = formDatos.leer(), err = document.getElementById('w-error');
        enviando = true; sigue.disabled = true;
        var transportistas = esProv() ? personas.filter(function (p) { return p.transp; }).map(function (p) {
            return { personaId: p.id, ruc: p.datos.ruc, nombre: p.datos.nombre, direccion: p.datos.direccion, placa: p.datos.placa, marca: p.datos.marca, licencia: p.datos.licencia };
        }) : [];
        CAF.pedir(d.urlCrear, { method: 'POST', body: Object.assign({}, v, { personasIds: personas.map(function (p) { return p.id; }), origenId: origen || null, transportistas: transportistas,
            subtipos: personas.filter(function (p) { return p.subtipoId; }).map(function (p) { return { personaId: p.id, subtipoId: p.subtipoId }; }) }) }).then(function (r) {
            enviando = false; sigue.disabled = false;
            if (!r.success) { err.textContent = SOL.errores(r); return; }
            var destino = d.urlDetalle.replace('__ID__', r.data.id) + '?nueva=1';
            if (!adj || !adj.archivos().length) { location.href = destino; return; }
            // La solicitud ya existe: se suben los documentos. Si alguno falla no se pierde la solicitud; se avisa y se puede adjuntar desde su detalle.
            enviando = true; sigue.disabled = true; sigue.textContent = 'Subiendo documentos...';
            adj.subirTodos(r.data.id).then(function (fallos) {
                enviando = false; sigue.disabled = false;
                if (!fallos.length) { location.href = destino; return; }
                err.textContent = 'La solicitud ' + r.data.codigo + ' se creó, pero no se pudo adjuntar: ' + fallos.map(function (f) { return f.nombre + ' (' + f.mensaje + ')'; }).join('; ') + ' Puede adjuntarlo desde el detalle de la solicitud.';
                sigue.textContent = 'Ir a la solicitud'; atras.hidden = true;
                var nuevo = sigue.cloneNode(true); sigue.parentNode.replaceChild(nuevo, sigue); sigue = nuevo;
                sigue.addEventListener('click', function () { location.href = destino; });
            });
        });
    });

    SOL.cargarOpciones(d.urlOpciones).then(function (o) {
        if (!o) { cuerpo.textContent = ''; cuerpo.appendChild(el('p', { class: 'vacio', text: 'No se pudo preparar el formulario.' })); return; }
        op = o;
        if (!origen) { formDatos = SOL.formDatos(op, d.urlResponsables, {}, 'crear'); mostrar(); return; }
        CAF.pedir(d.urlDatos + '?id=' + origen).then(function (r) {
            var s = r.success ? r.data : {};
            formDatos = SOL.formDatos(op, d.urlResponsables, {
                empresa: s.empresa, responsableId: s.responsableId, responsable: s.responsable, motivoId: s.motivoId, motivoDetalle: s.motivoDetalle,
                observaciones: s.observaciones, zonasIds: s.zonasIds, copias: s.copias,
                tipoId: s.tipoId, sedeId: s.sedeId, cochera: s.cochera, placa: s.placa, areaDetalle: s.areaDetalle,
                contactoNombre: s.contactoNombre, contactoTelefonos: s.contactoTelefonos, contactoCorreos: s.contactoCorreos, empresaDestinoId: s.empresaDestinoId, empresasIds: s.empresasIds,
                numerosOc: s.numerosOc, empresaTransportista: s.empresaTransportista, horaHasta: s.horaHasta
            }, 'crear');
            var tr = {}; (s.transportistas || []).forEach(function (t) { tr[t.personaId] = t; });
            personas = (s.personas || []).filter(function (p) { return p.aprobacion !== 'RETIRADA'; }).map(function (p) {
                var t = tr[p.personaId];
                return { id: p.personaId, nombre: p.nombre, doc: (p.tipoDoc ? p.tipoDoc + ' ' : '') + p.doc, transp: !!t,
                         datos: t ? { ruc: t.ruc || '', nombre: t.nombre || '', direccion: t.direccion || '', placa: t.placa || '', marca: t.marca || '', licencia: t.licencia || '' } : {} };
            });
            if (r.success) CAF.aviso('Copiamos los datos de ' + s.codigo + '. Elija la nueva fecha y hora.');
            mostrar();
        });
    });
})();

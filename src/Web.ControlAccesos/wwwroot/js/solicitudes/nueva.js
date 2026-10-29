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
    var AYUDAS = ['Indique cuándo, quién atiende y a qué zonas irán.', 'Agregue a cada persona que ingresará. Si ya la registró antes, se completa sola con su documento.', 'Revise y envíe. Coordinación decidirá persona por persona.'];

    function pintarPasos() {
        pasos.textContent = '';
        TITULOS.forEach(function (t, i) {
            var n = i + 1;
            pasos.appendChild(el('li', { class: n === paso ? 'on' : (n < paso ? 'done' : '') }, [el('button', { type: 'button', onclick: function () { if (n < paso) { paso = n; mostrar(); } } },
                [el('span', { class: 'sn', text: n < paso ? '✓' : String(n) }), t])]));
        });
        ayuda.textContent = AYUDAS[paso - 1];
        atras.hidden = paso === 1;
        sigue.textContent = paso === 3 ? 'Enviar solicitud' : 'Continuar';
    }

    function paso2() {
        var lista = el('ul', { class: 'plist' }), titulo = el('h3');
        function pintarLista() {
            titulo.textContent = 'Personas de la visita (' + personas.length + ')';
            lista.textContent = '';
            if (!personas.length) { lista.appendChild(el('li', {}, [el('span', { class: 'vacio', text: 'Aún no agregó personas.' })])); return; }
            personas.forEach(function (p, i) {
                lista.appendChild(el('li', {}, [
                    el('div', { class: 'plist-m' }, [el('div', { class: 'pn', text: p.nombre }), el('div', { class: 'field-h', text: p.doc })]),
                    el('button', { type: 'button', class: 'btn btn-sm btn-danger-o', text: 'Quitar', onclick: function () { personas.splice(i, 1); pintarLista(); } })
                ]));
            });
        }
        var error = el('p', { class: 'field-e' });
        formPer = SOL.formPersona(op, d.urlBuscar, d.urlPersona);
        var agregar = el('button', { type: 'button', class: 'btn btn-sm', text: '+ Agregar persona' });
        agregar.addEventListener('click', function () {
            error.textContent = '';
            formPer.guardar().then(function (r) {
                if (!r.success) { error.textContent = SOL.errores(r); return; }
                if (personas.some(function (p) { return p.id === r.data.id; })) { error.textContent = 'Esa persona ya está en la lista.'; return; }
                personas.push({ id: r.data.id, nombre: r.data.nombreCompleto, doc: r.data.doc });
                formPer = SOL.formPersona(op, d.urlBuscar, d.urlPersona);   // formulario limpio para la siguiente
                caja.textContent = ''; caja.appendChild(formPer.nodo);
                pintarLista();
            });
        });
        var caja = el('div'); caja.appendChild(formPer.nodo);
        pintarLista();
        if (!adj) adj = ADJ.selector(d.urlAdj);
        return el('div', { class: 'stack' }, [titulo, lista, el('hr'), el('h4', { text: 'Agregar persona' }), caja, error, el('div', { class: 'row-end' }, [agregar]), el('hr'), adj.nodo]);
    }

    function paso3() {
        var v = formDatos.leer();
        var zonas = op.zonas.filter(function (z) { return v.zonasIds.indexOf(z.id) >= 0; }).map(function (z) { return z.texto; }).join(', ');
        var motivo = (op.motivos.filter(function (m) { return m.id === v.motivoId; })[0] || {}).texto || '';
        var dl = el('dl', { class: 'dl' });
        [['Sede', op.sede.texto], ['Visita', SOL.fechaLarga(v.fecha) + ' · ' + v.hora], ['Empresa', v.empresa], ['Responsable de atención', v.responsable],
         ['Motivo', motivo + (v.motivoDetalle ? ' — ' + v.motivoDetalle : '')], ['Zonas', zonas], ['Detalles adicionales', v.observaciones || '—'], ['Correos en copia', v.copias || '—']]
            .forEach(function (x) { dl.appendChild(el('dt', { text: x[0] })); dl.appendChild(el('dd', { text: x[1] })); });
        var lista = el('ul', { class: 'plist' }, personas.map(function (p) {
            return el('li', {}, [el('div', { class: 'plist-m' }, [el('div', { class: 'pn', text: p.nombre }), el('div', { class: 'field-h', text: p.doc })])]);
        }));
        var docs = adj ? adj.archivos() : [];
        var tipo = el('div', { class: 'aviso a-info', text: 'Tipo de acceso: ' + op.tipo.texto + '. Coordinación revisará la solicitud y decidirá persona por persona.' });
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
            paso = 3; mostrar(); return;
        }
        var v = formDatos.leer(), err = document.getElementById('w-error');
        enviando = true; sigue.disabled = true;
        CAF.pedir(d.urlCrear, { method: 'POST', body: Object.assign({}, v, { personasIds: personas.map(function (p) { return p.id; }), origenId: origen || null }) }).then(function (r) {
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
        if (!origen) { formDatos = SOL.formDatos(op, d.urlResponsables, {}); mostrar(); return; }
        CAF.pedir(d.urlDatos + '?id=' + origen).then(function (r) {
            var s = r.success ? r.data : {};
            formDatos = SOL.formDatos(op, d.urlResponsables, {
                empresa: s.empresa, responsableId: s.responsableId, responsable: s.responsable, motivoId: s.motivoId, motivoDetalle: s.motivoDetalle,
                observaciones: s.observaciones, zonasIds: s.zonasIds, copias: s.copias
            });
            personas = (s.personas || []).filter(function (p) { return p.aprobacion !== 'RETIRADA'; }).map(function (p) { return { id: p.personaId, nombre: p.nombre, doc: (p.tipoDoc ? p.tipoDoc + ' ' : '') + p.doc }; });
            if (r.success) CAF.aviso('Copiamos los datos de ' + s.codigo + '. Elija la nueva fecha y hora.');
            mostrar();
        });
    });
})();

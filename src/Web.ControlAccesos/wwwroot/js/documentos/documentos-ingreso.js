// D-265. «Documentos de ingreso»: Vigilancia sube (de forma asíncrona, un archivo a la vez con su avance) documentos del día
// y los asocia a las personas que ingresaron (etiquetas con autocompletado; filtro «trajeron equipos o herramientas» activo por defecto).
// D-269: dos pestañas, «Subir» (Vigilancia) y «Consultar» (rango de días y búsqueda por persona; también Almacén). Almacén solo consulta. Las reglas (quién ingresó, tamaño, duplicados) las valida el procedimiento.
(function () {
    'use strict';
    var raiz = document.getElementById('caf-docing');
    if (!raiz) return;
    var el = CAF.el, d = raiz.dataset, puede = d.puedeSubir === 'Y';
    var fecha = document.getElementById('di-fecha'), resumen = document.getElementById('di-resumen'), lista = document.getElementById('di-lista');
    var tipo = document.getElementById('di-tipo'), adj = document.getElementById('di-adj'), selNodo = document.getElementById('di-sel'), acc = document.getElementById('di-acc'), cola = document.getElementById('di-cola'), ayuda = document.getElementById('di-ayuda');
    var btnS = null, listoSubir = false;
    var TIPOS = { EQUIPOS: 'Equipos', HERRAMIENTAS: 'Herramientas', GUIA: 'Guía', OTRO: 'Otro' };
    var info = null;
    function hoy() { var t = new Date(); return t.getFullYear() + '-' + ('0' + (t.getMonth() + 1)).slice(-2) + '-' + ('0' + t.getDate()).slice(-2); }
    function token() { var i = document.querySelector('input[name="__RequestVerificationToken"]'); return i ? i.value : ''; }
    function tam(b) { return b >= 1048576 ? (b / 1048576).toFixed(1) + ' MB' : Math.max(1, Math.round(b / 1024)) + ' KB'; }
    function errores(r) { var e = (r.errors || []).map(function (x) { return x.message; }).filter(Boolean); return e.length ? e.join(' ') : (r.message || 'No se pudo completar.'); }

    // ── Etiquetas de personas (se reusan en «Subir» y en «Cambiar personas») ──
    function selectorPersonas(inicial) {
        var elegidas = {}, orden = [];
        var soloEq = el('input', { type: 'checkbox', checked: true });
        var txt = el('input', { type: 'search', placeholder: 'Buscar por nombre, documento, solicitud o empresa', autocomplete: 'off' });
        var sug = el('div', { class: 'di-sug', hidden: true }), chips = el('div', { class: 'di-chips' }), tmr = null;
        (inicial || []).forEach(function (p) { elegidas[p.id] = p; orden.push(p.id); });
        function pintarChips() {
            chips.textContent = '';
            orden.forEach(function (id) {
                var p = elegidas[id];
                chips.appendChild(el('span', { class: 'di-chip' }, [(p.nombre || '') + (p.empresa ? ' · ' + p.empresa : ''),
                    el('button', { type: 'button', 'aria-label': 'Quitar ' + p.nombre, text: '×', onclick: function () { delete elegidas[id]; orden = orden.filter(function (x) { return x !== id; }); pintarChips(); } })]));
            });
        }
        function buscar() {
            CAF.pedir(d.urlPersonas + '?fecha=' + encodeURIComponent(fecha.value) + '&q=' + encodeURIComponent(txt.value) + '&soloEquipos=' + (soloEq.checked ? 'Y' : 'N')).then(function (r) {
                sug.textContent = '';
                if (!r.success) { sug.hidden = false; sug.appendChild(el('p', { class: 'vacio', text: r.message || 'No se pudo buscar.' })); return; }
                var l = r.data.filter(function (p) { return !elegidas[p.id]; });
                sug.hidden = false;
                if (!l.length) { sug.appendChild(el('p', { class: 'vacio', text: soloEq.checked ? 'Nadie que trajera equipos o herramientas coincide. Desmarque el filtro para ver a todos los que ingresaron.' : 'Nadie coincide.' })); return; }
                l.forEach(function (p) {
                    var marca = (p.equipos ? 'Equipos' : '') + (p.equipos && p.herramientas ? ' y ' : '') + (p.herramientas ? 'Herramientas' : '');
                    sug.appendChild(el('button', { type: 'button', onclick: function () { elegidas[p.id] = p; orden.push(p.id); pintarChips(); txt.value = ''; sug.hidden = true; txt.focus(); } },
                        [p.nombre + ' — ' + p.documento, el('small', { text: p.solicitud + (p.empresa ? ' · ' + p.empresa : '') + (marca ? ' · ' + marca : '') + (p.documentos ? ' · ya tiene ' + p.documentos + ' doc.' : '') })]));
                });
            });
        }
        txt.addEventListener('input', function () { clearTimeout(tmr); tmr = setTimeout(buscar, 250); });
        txt.addEventListener('focus', buscar);
        soloEq.addEventListener('change', buscar);
        pintarChips();
        var nodo = el('div', { class: 'stack' }, [
            el('label', { class: 'field' }, [el('span', { class: 'field-l', text: 'Personas a las que corresponde' }), txt]),
            el('label', { class: 'check' }, [soloEq, ' Solo quienes trajeron equipos o herramientas']), sug, chips]);
        return { nodo: nodo, ids: function () { return orden.slice(); } };
    }

    // ── Subida asíncrona con avance (XMLHttpRequest para tener progreso real) ──
    function enviar(archivo, tipo, ids, barra) {
        return new Promise(function (ok) {
            var fd = new FormData();
            fd.append('fecha', fecha.value); fd.append('tipo', tipo); fd.append('personas', ids.join(',')); fd.append('archivo', archivo, archivo.name);
            var x = new XMLHttpRequest();
            x.open('POST', d.urlSubir);
            x.setRequestHeader('RequestVerificationToken', token()); x.setRequestHeader('X-Requested-With', 'fetch');
            x.upload.onprogress = function (e) { if (e.lengthComputable) barra.firstChild.style.width = Math.round(e.loaded * 100 / e.total) + '%'; };
            x.onload = function () { var r; try { r = JSON.parse(x.responseText); } catch (e) { r = { success: false, message: 'Respuesta no válida del servidor.' }; } ok(r); };
            x.onerror = function () { ok({ success: false, message: 'No se pudo conectar con el servidor.' }); };
            x.send(fd);
        });
    }

    // ── Pestaña «Subir»: Día + Tipo + Adjuntar en una fila; lista de archivos con «Quitar» (mismo patrón que el formulario) ──
    var archivos = [], sel = null;
    function pintarArchivos() {
        adj.textContent = '';
        var inp = el('input', { type: 'file', multiple: true, hidden: true, accept: '.pdf,.jpg,.jpeg,.png,application/pdf,image/jpeg,image/png' });
        inp.addEventListener('change', function () { Array.prototype.slice.call(inp.files || []).forEach(function (f) { archivos.push(f); }); inp.value = ''; pintarArchivos(); });
        adj.appendChild(inp);
        adj.appendChild(CAF.btn({ icono: 'adjunto', texto: 'Adjuntar documento', modo: 'texto', clase: 'btn-sm', onclick: function () { inp.click(); } }));
        if (archivos.length) adj.appendChild(el('ul', { class: 'plist' }, archivos.map(function (f, k) {
            return el('li', { class: 'di-arch' }, [el('span', {}, [el('b', { text: f.name }), ' (' + tam(f.size) + ')']),
                CAF.btn({ icono: 'papelera', texto: 'Quitar', clase: 'btn-sm btn-danger-o', onclick: function () { archivos.splice(k, 1); pintarArchivos(); } })]);
        })));
    }

    function iniciarSubir() {
        tipo.textContent = '';
        Object.keys(TIPOS).forEach(function (k) { tipo.appendChild(el('option', { value: k, text: TIPOS[k] })); });
        sel = selectorPersonas([]);
        selNodo.textContent = ''; selNodo.appendChild(sel.nodo);
        pintarArchivos();
        btnS = CAF.btn({ icono: 'subir', texto: 'Subir documentos', clase: 'btn-primary', modo: 'texto', onclick: subirTodo });
        acc.textContent = ''; acc.appendChild(btnS);
    }

    function subirTodo() {
        var ids = sel.ids(), fs = archivos.slice();
        if (!fs.length) { CAF.aviso('Adjunte al menos un archivo.', 'warn'); return; }
        if (!ids.length) { CAF.aviso('Elija al menos una persona.', 'warn'); return; }
        btnS.disabled = true; cola.textContent = '';
        var filas = fs.map(function (f) {
            var barra = el('div', { class: 'di-prog' }, [el('i')]), est = el('span', { class: 'field-h', text: 'En espera' });
            cola.appendChild(el('div', { class: 'di-doc' }, [el('b', { text: f.name }), ' (' + tam(f.size) + ') ', est, barra]));
            return { f: f, barra: barra, est: est };
        });
        var buenos = 0, cadena = Promise.resolve(), fallidos = [];
        filas.forEach(function (fl) {
            cadena = cadena.then(function () {
                fl.est.textContent = 'Subiendo…';
                return enviar(fl.f, tipo.value, ids, fl.barra).then(function (r) {
                    if (r.success) { buenos++; fl.barra.firstChild.style.width = '100%'; fl.est.textContent = 'Listo'; }
                    else { fl.barra.classList.add('err'); fl.est.textContent = errores(r); fallidos.push(fl.f); }
                });
            });
        });
        cadena.then(function () {
            btnS.disabled = false; archivos = fallidos; pintarArchivos();
            if (buenos) { CAF.aviso(buenos + ' documento(s) subido(s).'); cargar(); }
            if (!fallidos.length) setTimeout(function () { cola.textContent = ''; }, 2500);
        });
    }

    function cambiarPersonas(doc) {
        var sel = selectorPersonas((doc.personas || []).map(function (p) { return { id: String(p.id), nombre: p.nombre, empresa: p.empresa }; }));
        var err = el('p', { class: 'field-err' });
        var m = CAF.modal('Personas de «' + doc.nombre + '»', el('div', { class: 'stack' }, [sel.nodo, err]), [
            { texto: 'Cancelar', onclick: function () { m.cerrar(); } },
            { texto: 'Guardar', tipo: 'primary', onclick: function () {
                var ids = sel.ids().map(Number);
                if (!ids.length) { err.textContent = 'Elija al menos una persona.'; return; }
                CAF.pedir(d.urlAsignar, { method: 'POST', body: { id: doc.id, personas: ids } }).then(function (r) {
                    if (!r.success) { err.textContent = errores(r); return; }
                    m.cerrar(); CAF.aviso('Personas actualizadas.'); cargar();
                });
            } }], 'ancho');
    }

    function quitar(doc) {
        var m = CAF.modal('Retirar documento', el('p', { text: '¿Retirar «' + doc.nombre + '»? Dejará de figurar en las personas y solicitudes asociadas.' }), [
            { texto: 'Cancelar', onclick: function () { m.cerrar(); } },
            { texto: 'Retirar', tipo: 'danger', onclick: function () {
                CAF.pedir(d.urlQuitar, { method: 'POST', body: { id: doc.id } }).then(function (r) {
                    if (!r.success) { CAF.aviso(errores(r), 'warn'); return; }
                    m.cerrar(); CAF.aviso('Documento retirado.'); cargar();
                });
            } }]);
    }

    function pintar() {
        resumen.textContent = '';
        var r = info;
        [['Ingresaron', r.ingresaron], ['Con equipos o herramientas', r.conEquipos], ['Documentos', r.documentos]].forEach(function (x) {
            resumen.appendChild(el('div', { class: 'di-stat' }, [el('b', { text: String(x[1]) }), el('span', { text: x[0] })]));
        });
        if (r.obligatorio && r.sinDocumento > 0) resumen.appendChild(el('div', { class: 'di-stat warn' }, [el('b', { text: String(r.sinDocumento) }), el('span', { text: 'con equipos sin documento' })]));
        ayuda.textContent = 'PDF, JPG o PNG; máximo ' + r.maxMb + ' MB por archivo. Todos los archivos se asocian a las mismas personas.';
        if (!listoSubir && r.puedeSubir) { iniciarSubir(); listoSubir = true; }
        lista.textContent = '';
        lista.appendChild(el('h3', { text: 'Documentos del día' }));
        if (!docs.length) { lista.appendChild(el('p', { class: 'vacio', text: 'No hay documentos de ingreso en este día.' })); return; }
        docs.forEach(function (x) { lista.appendChild(filaSimple(x)); });
    }

    function acciones(x) {
        var a = [CAF.btn({ href: d.urlDescargar + '?id=' + x.id, icono: 'descargar', texto: 'Descargar', clase: 'btn-sm' })];
        if (puede && x.puedeModificar) {
            a.push(CAF.btn({ icono: 'editar', texto: 'Cambiar personas', clase: 'btn-sm', onclick: function () { cambiarPersonas(x); } }));
            a.push(CAF.btn({ icono: 'cancelar', texto: 'Retirar', clase: 'btn-sm btn-danger-o', onclick: function () { quitar(x); } }));
        }
        return el('div', { class: 'acc' }, a);
    }
    // «Documentos del día»: solo el nombre completo de cada persona, como etiquetas.
    function filaSimple(x) {
        var nombres = (x.personas || []).map(function (p) { return el('span', { class: 'di-nombre', text: p.nombre }); });
        return el('div', { class: 'di-doc' }, [
            el('div', {}, [el('b', { text: x.nombre }), ' · ' + (TIPOS[x.tipo] || x.tipo) + ' · ' + tam(x.bytes) + ' · ' + x.subido + (x.por ? ' · ' + x.por : '')]),
            el('div', { class: 'di-pers' }, nombres.length ? nombres : [el('span', { class: 'vacio', text: 'Sin personas asociadas' })]), acciones(x)]);
    }
    // «Consultar»: detalle (nombre, DNI, empresa, solicitud) de cada persona.
    function filaDetalle(x) {
        var tabla = el('table', { class: 'di-tabla' }, [el('thead', {}, [el('tr', {}, ['Persona', 'DNI / Documento', 'Empresa', 'Solicitud'].map(function (t) { return el('th', { text: t }); }))]),
            el('tbody', {}, (x.personas || []).map(function (p) {
                return el('tr', {}, [p.nombre, p.documento, p.empresa || '—', p.solicitud].map(function (t) { return el('td', { text: t }); }));
            }))]);
        return el('div', { class: 'di-doc' }, [
            el('div', {}, [el('span', { class: 'di-fecha', text: x.fecha }), el('b', { text: x.nombre }), ' · ' + (TIPOS[x.tipo] || x.tipo) + ' · ' + tam(x.bytes) + ' · subido ' + x.subido + (x.por ? ' por ' + x.por : '')]),
            (x.personas || []).length ? tabla : el('p', { class: 'vacio', text: 'Sin personas asociadas' }), acciones(x)]);
    }

    // ── Pestaña «Consultar» ──
    var desde = document.getElementById('di-desde'), hasta = document.getElementById('di-hasta'), q = document.getElementById('di-q'), result = document.getElementById('di-result');
    function consultar() {
        if (desde.value && hasta.value && desde.value > hasta.value) { CAF.aviso('«Desde» no puede ser posterior a «Hasta».', 'warn'); return; }
        CAF.pedir(d.urlBuscar + '?desde=' + encodeURIComponent(desde.value) + '&hasta=' + encodeURIComponent(hasta.value) + '&q=' + encodeURIComponent(q.value)).then(function (r) {
            result.textContent = '';
            if (!r.success) { result.appendChild(el('p', { class: 'vacio', text: r.message || 'No se pudo buscar.' })); return; }
            result.appendChild(el('h3', { text: 'Resultados (' + r.data.length + ')' }));
            if (!r.data.length) { result.appendChild(el('p', { class: 'vacio', text: 'No se encontraron documentos con esos criterios.' })); return; }
            r.data.forEach(function (x) { result.appendChild(filaDetalle(x)); });
        });
    }
    document.getElementById('di-buscar').appendChild(CAF.btn({ icono: 'buscar', texto: 'Buscar', clase: 'btn-primary', modo: 'texto', onclick: consultar }));
    q.addEventListener('keydown', function (e) { if (e.key === 'Enter') { e.preventDefault(); consultar(); } });

    // ── Pestañas (con ícono) ──
    Array.prototype.forEach.call(document.querySelectorAll('#di-tabs button'), function (b) {
        var t = b.textContent; b.textContent = ''; b.appendChild(CAF.icono(b.dataset.tab === 'subir' ? 'subir' : 'buscar')); b.appendChild(el('span', { text: ' ' + t }));
    });
    var pSubir = document.getElementById('di-p-subir'), pCons = document.getElementById('di-p-consultar'), vistoCons = false;
    Array.prototype.forEach.call(document.querySelectorAll('#di-tabs button'), function (b) {
        b.addEventListener('click', function () {
            Array.prototype.forEach.call(document.querySelectorAll('#di-tabs button'), function (o) { o.classList.toggle('on', o === b); });
            var cons = b.dataset.tab === 'consultar';
            if (pSubir) pSubir.hidden = cons; pCons.hidden = !cons;
            if (cons && !vistoCons) { vistoCons = true; consultar(); }
        });
    });

    var docs = [];
    function cargar() {
        return CAF.pedir(d.urlDatos + '?fecha=' + encodeURIComponent(fecha.value)).then(function (r) {
            if (!r.success) { lista.textContent = ''; lista.appendChild(el('p', { class: 'vacio', text: r.message || 'No se pudo cargar.' })); return; }
            var s = r.resumen;
            info = { ingresaron: s.ingresaron, conEquipos: s.con_Equipos, sinDocumento: s.sin_Documento, documentos: s.documentos, obligatorio: s.obligatorio, maxMb: s.max_MB, puedeSubir: s.puede_Subir };
            docs = r.documentos || [];
            pintar();
        });
    }

    var t0 = new Date(); t0.setDate(t0.getDate() - 7);
    function iso(t) { return t.getFullYear() + '-' + ('0' + (t.getMonth() + 1)).slice(-2) + '-' + ('0' + t.getDate()).slice(-2); }
    desde.value = iso(t0); hasta.value = hoy(); hasta.max = hoy(); desde.max = hoy();
    if (fecha) {
        fecha.value = hoy(); fecha.max = hoy();
        fecha.addEventListener('change', function () { if (fecha.value) cargar(); });
        cargar();
    } else { vistoCons = true; consultar(); }
})();

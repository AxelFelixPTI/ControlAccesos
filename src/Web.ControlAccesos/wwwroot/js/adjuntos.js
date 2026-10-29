// Documentos adjuntos de una solicitud (Entrega J). Tres usos:
//   ADJ.selector(...)  en «Nueva solicitud»: elegir hasta 2 archivos, verlos, quitarlos y subirlos al crear.
//   ADJ.panel(...)     en el detalle, Coordinación y Vigilancia: lista con descarga; el dueño puede adjuntar y retirar.
// La validación del navegador es solo ayuda (el servidor vuelve a validar extensión, tamaño y firma del archivo).
var ADJ = (function () {
    'use strict';
    var el = CAF.el;
    var MAX_BYTES = 5 * 1024 * 1024, MAX_ARCHIVOS = 2, EXT = ['pdf', 'doc', 'docx', 'xls', 'xlsx'];
    var PERMITIDOS = 'PDF, Word (DOC, DOCX) y Excel (XLS, XLSX)';

    function tamano(b) { return b >= 1048576 ? (b / 1048576).toFixed(1) + ' MB' : Math.max(1, Math.round(b / 1024)) + ' KB'; }
    function base(url) { return url.replace(/Listar$/, ''); }
    function token() { var i = document.querySelector('input[name="__RequestVerificationToken"]'); return i ? i.value : ''; }

    // Mensaje de error si el archivo no cumple; null si está bien.
    function revisar(f, yaHay) {
        var n = f.name || '', i = n.lastIndexOf('.'), ext = i > 0 ? n.slice(i + 1).toLowerCase() : '';
        if (EXT.indexOf(ext) < 0) return '«' + n + '»: solo se permiten archivos ' + PERMITIDOS + '.';
        if (!f.size) return '«' + n + '» está vacío.';
        if (f.size > MAX_BYTES) return '«' + n + '» supera el máximo de 5 MB (' + tamano(f.size) + ').';
        if (yaHay >= MAX_ARCHIVOS) return 'Solo se admiten ' + MAX_ARCHIVOS + ' documentos por solicitud.';
        return null;
    }

    function subir(urlSubir, solicitudId, file) {
        var fd = new FormData();
        fd.append('solicitudId', solicitudId);
        fd.append('archivo', file, file.name);
        return fetch(urlSubir, { method: 'POST', body: fd, credentials: 'same-origin', headers: { 'RequestVerificationToken': token(), 'X-Requested-With': 'fetch' } })
            .then(function (r) { return r.json().catch(function () { return { success: false, message: 'Respuesta no válida del servidor.' }; }); })
            .catch(function () { return { success: false, message: 'No se pudo conectar con el servidor.' }; });
    }

    function errorDe(r) {
        var det = (r.errors || []).map(function (e) { return e.message; }).filter(Boolean);
        return det.length ? det.join(' ') : (r.message || 'No se pudo completar la operación.');
    }

    // ── Selector para «Nueva solicitud»: los archivos viven en memoria y sobreviven al cambio de paso ──
    function selector(urlListar) {
        var archivos = [];
        var lista = el('ul', { class: 'plist' }), error = el('p', { class: 'field-e' });
        var entrada = el('input', { type: 'file', multiple: true, hidden: true, accept: '.pdf,.doc,.docx,.xls,.xlsx' });
        var boton = el('button', { type: 'button', class: 'btn btn-sm', text: '+ Adjuntar documento', onclick: function () { entrada.click(); } });
        function pintar() {
            lista.textContent = '';
            archivos.forEach(function (f, i) {
                lista.appendChild(el('li', {}, [
                    el('div', { class: 'plist-m' }, [el('div', { class: 'pn', text: f.name }), el('div', { class: 'field-h', text: tamano(f.size) })]),
                    el('button', { type: 'button', class: 'btn btn-sm btn-danger-o', text: 'Quitar', onclick: function () { archivos.splice(i, 1); error.textContent = ''; pintar(); } })]));
            });
            if (!archivos.length) lista.appendChild(el('li', {}, [el('span', { class: 'vacio', text: 'Sin documentos adjuntos (opcional).' })]));
            boton.disabled = archivos.length >= MAX_ARCHIVOS;
        }
        entrada.addEventListener('change', function () {
            error.textContent = '';
            Array.prototype.forEach.call(entrada.files, function (f) {
                var e = revisar(f, archivos.length);
                if (e) { error.textContent = (error.textContent ? error.textContent + ' ' : '') + e; return; }
                if (archivos.some(function (x) { return x.name === f.name && x.size === f.size; })) { error.textContent = '«' + f.name + '» ya está en la lista.'; return; }
                archivos.push(f);
            });
            entrada.value = ''; pintar();
        });
        pintar();
        var nodo = el('div', { class: 'stack' }, [
            el('h4', { text: 'Documentos de respaldo (opcional)' }),
            el('p', { class: 'field-h', text: 'Por ejemplo el SCTR con los nombres de las personas. Hasta ' + MAX_ARCHIVOS + ' archivos de 5 MB: ' + PERMITIDOS + '. Llegan a Coordinación y, desde la primera aprobación, a Vigilancia.' }),
            lista, error, el('div', { class: 'row-end' }, [boton]), entrada]);
        return {
            nodo: nodo,
            archivos: function () { return archivos.slice(); },
            // Sube los archivos pendientes a la solicitud ya creada. Devuelve los que NO se pudieron subir [{nombre, mensaje}].
            subirTodos: function (solicitudId) {
                var fallos = [], cadena = Promise.resolve();
                archivos.slice().forEach(function (f) {
                    cadena = cadena.then(function () { return subir(base(urlListar) + 'Subir', solicitudId, f); }).then(function (r) {
                        if (r.success) archivos = archivos.filter(function (x) { return x !== f; }); else fallos.push({ nombre: f.name, mensaje: errorDe(r) });
                    });
                });
                return cadena.then(function () { pintar(); return fallos; });
            }
        };
    }

    // ── Panel con lo ya guardado ──────────────────────────────────────────────────────────────
    // opciones: {solicitudId, urlListar, puedeAdjuntar (el dueño aún puede editar), titulo}
    function panel(o) {
        var caja = el('div', { class: 'stack' }), baseUrl = base(o.urlListar);
        var entrada = el('input', { type: 'file', hidden: true, accept: '.pdf,.doc,.docx,.xls,.xlsx' });
        var nodo = el('section', { class: 'card' }, [caja, entrada]);
        var cantidad = 0;
        function pintar(r) {
            caja.textContent = '';
            caja.appendChild(el('h3', { text: o.titulo || 'Documentos adjuntos' }));
            if (!r.success) { caja.appendChild(el('p', { class: 'field-e', text: r.message || 'No se pudieron leer los documentos.' })); return; }
            cantidad = r.data.length;
            var ul = el('ul', { class: 'plist' });
            r.data.forEach(function (a) {
                var acc = [el('a', { class: 'btn btn-sm', href: baseUrl + 'Descargar?id=' + a.id, text: 'Descargar' })];
                if (a.puedeQuitar) acc.push(el('button', { type: 'button', class: 'btn btn-sm btn-danger-o', text: 'Retirar', onclick: function () { quitar(a); } }));
                ul.appendChild(el('li', {}, [el('div', { class: 'plist-m' }, [el('div', { class: 'pn', text: a.nombre }), el('div', { class: 'field-h', text: tamano(a.tamano) + ' · ' + a.fecha })]), el('div', { class: 'acc' }, acc)]));
            });
            if (!r.data.length) ul.appendChild(el('li', {}, [el('span', { class: 'vacio', text: 'Esta solicitud no tiene documentos adjuntos.' })]));
            caja.appendChild(ul);
            if (o.puedeAdjuntar && cantidad < MAX_ARCHIVOS)
                caja.appendChild(el('div', { class: 'row-end' }, [el('button', { type: 'button', class: 'btn btn-sm', text: '+ Adjuntar documento', onclick: function () { entrada.click(); } })]));
            if (o.puedeAdjuntar) caja.appendChild(el('p', { class: 'field-h', text: 'Hasta ' + MAX_ARCHIVOS + ' archivos de 5 MB: ' + PERMITIDOS + '.' }));
        }
        function recargar() { return CAF.pedir(o.urlListar + '?solicitudId=' + o.solicitudId).then(pintar); }
        function quitar(a) {
            CAF.pedir(baseUrl + 'Quitar', { method: 'POST', body: { id: a.id } }).then(function (r) {
                CAF.aviso(r.success ? 'Documento retirado.' : errorDe(r), r.success ? undefined : 'warn'); recargar();
            });
        }
        entrada.addEventListener('change', function () {
            var f = entrada.files[0]; entrada.value = '';
            if (!f) return;
            var e = revisar(f, cantidad);
            if (e) { CAF.aviso(e, 'warn'); return; }
            subir(baseUrl + 'Subir', o.solicitudId, f).then(function (r) {
                CAF.aviso(r.success ? 'Documento adjuntado.' : errorDe(r), r.success ? undefined : 'warn'); recargar();
            });
        });
        recargar();
        return { nodo: nodo, recargar: recargar };
    }

    return { selector: selector, panel: panel };
})();

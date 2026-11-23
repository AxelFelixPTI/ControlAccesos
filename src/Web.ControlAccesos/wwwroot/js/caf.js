// Utilidades comunes de las pantallas: pedir datos al servidor, avisos y ventanas modales.
// Todo el texto se inserta con textContent (nunca innerHTML) para que ningún dato pueda inyectar código.
var CAF = (function () {
    'use strict';

    function el(tag, attrs, hijos) {
        var e = document.createElement(tag);
        Object.keys(attrs || {}).forEach(function (k) {
            if (k === 'class') e.className = attrs[k];
            else if (k === 'text') e.textContent = attrs[k];
            else if (k.indexOf('on') === 0) e.addEventListener(k.slice(2), attrs[k]);
            else if (attrs[k] === true) e.setAttribute(k, '');
            else if (attrs[k] !== false && attrs[k] != null) e.setAttribute(k, attrs[k]);
        });
        (hijos || []).forEach(function (h) { if (h != null) e.appendChild(typeof h === 'string' ? document.createTextNode(h) : h); });
        return e;
    }

    function token() {
        var i = document.querySelector('input[name="__RequestVerificationToken"]');
        return i ? i.value : '';
    }

    function pedir(url, opciones) {
        var o = opciones || {};
        var cab = { 'X-Requested-With': 'fetch' };
        var init = { method: o.method || 'GET', headers: cab, credentials: 'same-origin' };
        if (o.body !== undefined) {
            cab['Content-Type'] = 'application/json';
            cab['RequestVerificationToken'] = token();
            init.body = JSON.stringify(o.body);
        }
        return fetch(url, init).then(function (r) {
            if (r.status === 401 || (r.redirected && r.url.indexOf('/Cuenta/Ingresar') >= 0)) { location.href = '/Cuenta/Ingresar'; return { success: false, message: 'Su sesión venció.' }; }
            return r.json().catch(function () { return { success: false, message: 'Respuesta no válida del servidor.' }; });
        }).catch(function () { return { success: false, message: 'No se pudo conectar con el servidor.' }; });
    }

    function aviso(texto, tipo) {
        var cont = document.getElementById('toasts');
        if (!cont) return;
        var t = el('div', { class: 'toast ' + (tipo === 'warn' ? 't-warn' : 't-ok'), role: 'status', text: texto });
        cont.appendChild(t);
        setTimeout(function () { if (t.parentNode) t.parentNode.removeChild(t); }, 4500);
    }

    // Ventana modal. cuerpo: nodo; botones: [{texto, tipo('primary'|''), onclick}]. Devuelve {cerrar, cuerpo}.
    function modal(titulo, cuerpo, botones, ancho) {
        var previo = document.activeElement;
        var fondo = el('div', { class: 'modal-back' });
        var caja = el('div', { class: 'modal', role: 'dialog', 'aria-modal': 'true', 'aria-label': titulo });
        caja.classList.add(ancho === 'ancho' ? 'modal-ancho' : ancho === 'chico' ? 'modal-chico' : 'modal-normal');
        function cerrar() { document.removeEventListener('keydown', tecla); if (fondo.parentNode) fondo.parentNode.removeChild(fondo); if (previo && previo.focus) previo.focus(); }
        function tecla(ev) { if (ev.key === 'Escape') cerrar(); }
        var pie = el('div', { class: 'modal-f' }, (botones || []).map(function (b) {
            var bm = el('button', { type: 'button', class: 'btn' + (b.tipo === 'primary' ? ' btn-primary' : b.tipo === 'danger' ? ' btn-danger' : b.tipo === 'warn' ? ' btn-warn' : ''), text: b.texto, onclick: function () { b.onclick(cerrar); } });
            var ib = b.icono || ({ 'Cerrar': 'cerrar', 'Volver': 'atras' })[b.texto];
            if (ib) rotular(bm, ib, b.texto);
            return bm;
        }));
        caja.appendChild(el('div', { class: 'modal-h' }, [el('h3', { text: titulo }), el('button', { type: 'button', class: 'btn btn-icon', 'aria-label': 'Cerrar', text: '×', onclick: cerrar })]));
        caja.appendChild(el('div', { class: 'modal-b' }, [cuerpo]));
        caja.appendChild(pie);
        fondo.appendChild(caja);
        fondo.addEventListener('mousedown', function (ev) { if (ev.target === fondo) cerrar(); });
        document.addEventListener('keydown', tecla);
        document.body.appendChild(fondo);
        var primero = caja.querySelector('input,select,textarea,button.btn-primary');
        if (primero) primero.focus();
        return { cerrar: cerrar };
    }

    // Refresco automático de una pantalla. Llama a fn cada `segundos` mientras la pestaña esté a la vista y no haya una
    // ventana abierta (para no pisar lo que la persona está llenando); al volver a la pestaña refresca de inmediato.
    // fn debe ser silenciosa (sin avisos si falla). Devuelve una función para detenerlo.
    function autoRefrescar(fn, segundos) {
        function libre() { return !document.hidden && !document.querySelector('.modal-back'); }
        var id = setInterval(function () { if (libre()) fn(); }, Math.max(5, segundos || 10) * 1000);
        function vis() { if (libre()) fn(); }
        document.addEventListener('visibilitychange', vis);
        return function () { clearInterval(id); document.removeEventListener('visibilitychange', vis); };
    }

    // Nombres y empresas siempre en MAYÚSCULAS (sin mezclar con minúsculas): se pasa al escribir, mantiene el cursor y vale para
    // cualquier formulario cuyo campo se llame Apellido…, Nombres, Empresa…, Razón social, Dirección, Marca, Licencia, Placa, Nombre del contacto o Detalle del área.
    // El servidor lo vuelve a aplicar (Models/Mayus.cs), así que aunque este paso no corra los datos se guardan igual.
    var CAMPO_MAYUS = /^(apellido|nombres\b|nombre del contacto|nombre o raz|raz[oó]n social|empresa|direcci[oó]n|marca|licencia|placa|detalle del [aá]rea)/i;
    function aMayusculas(ev) {
        var t = ev.target;
        if (!t || t.tagName !== 'INPUT' || t.type !== 'text' || !t.closest) return;
        var lab = t.closest('label.field'); if (!lab) return;
        var rot = lab.querySelector('.field-l'); if (!rot || !CAMPO_MAYUS.test(rot.textContent.trim())) return;
        var u = t.value.toLocaleUpperCase('es-PE');
        if (u === t.value) return;
        var ini = t.selectionStart, fin = t.selectionEnd;
        t.value = u;
        try { t.setSelectionRange(ini, fin); } catch (x) { /* sin cursor: no pasa nada */ }
    }
    document.addEventListener('input', aMayusculas, true);
    document.addEventListener('change', aMayusculas, true);


    // ── Iconos y botones con icono (D-253) ─────────────────────────────────────────────────────────────────────────────────────
    // Iconos SVG en línea (trazo 2, 24×24, geometría tipo Lucide, licencia ISC). Toman el color del texto (currentColor), así que
    // siguen el tema claro/oscuro. Cada uno es una lista de elementos: ['path', d] | ['circle', cx, cy, r] | ['rect', x, y, w, h, rx].
    var ICONOS = {
        'aprobar':      [['path', 'M18 6 7 17l-5-5'], ['path', 'm22 10-7.5 7.5L13 16']],
        'ver':          [['path', 'M2.062 12.348a1 1 0 0 1 0-.696 10.75 10.75 0 0 1 19.876 0 1 1 0 0 1 0 .696 10.75 10.75 0 0 1-19.876 0'], ['circle', 12, 12, 3]],
        'observar':     [['path', 'M22 17a2 2 0 0 1-2 2H6.828a2 2 0 0 0-1.414.586l-2.202 2.202A.71.71 0 0 1 2 21.286V5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2z'], ['path', 'M12 15h.01'], ['path', 'M12 7v4']],
        'rechazar':     [['circle', 12, 12, 10], ['path', 'm15 9-6 6'], ['path', 'm9 9 6 6']],
        'cancelar':     [['path', 'M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7Z'], ['path', 'M14 2v4a2 2 0 0 0 2 2h4'], ['path', 'm14.5 12.5-5 5'], ['path', 'm9.5 12.5 5 5']],
        'editar':       [['path', 'M21.174 6.812a1 1 0 0 0-3.986-3.987L3.842 16.174a2 2 0 0 0-.5.83l-1.321 4.352a.5.5 0 0 0 .623.622l4.353-1.32a2 2 0 0 0 .83-.497z'], ['path', 'm15 5 4 4']],
        'reutilizar':   [['rect', 8, 8, 14, 14, 2], ['path', 'M4 16c-1.1 0-2-.9-2-2V4c0-1.1.9-2 2-2h10c1.1 0 2 .9 2 2'], ['path', 'M15 12v6'], ['path', 'M12 15h6']],
        'reenviar':     [['path', 'M14.536 21.686a.5.5 0 0 0 .937-.024l6.5-19a.496.496 0 0 0-.635-.635l-19 6.5a.5.5 0 0 0-.024.937l7.93 3.18a2 2 0 0 1 1.112 1.11z'], ['path', 'm21.854 2.147-10.94 10.939']],
        'agregar':      [['path', 'M5 12h14'], ['path', 'M12 5v14']],
        'persona-mas':  [['path', 'M2 21a8 8 0 0 1 13.292-6'], ['circle', 10, 8, 5], ['path', 'M19 16v6'], ['path', 'M22 19h-6']],
        'persona-menos': [['path', 'M2 21a8 8 0 0 1 13.292-6'], ['circle', 10, 8, 5], ['path', 'M22 19h-6']],
        'persona-editar': [['path', 'M11.5 15H7a4 4 0 0 0-4 4v2'], ['path', 'M21.378 16.626a1 1 0 0 0-3.004-3.004l-4.01 4.012a2 2 0 0 0-.506.854l-.837 2.87a.5.5 0 0 0 .62.62l2.87-.837a2 2 0 0 0 .854-.506z'], ['circle', 10, 7, 4]],
        'persona-x':    [['path', 'M2 21a8 8 0 0 1 11.873-7'], ['circle', 10, 8, 5], ['path', 'm17 17 5 5'], ['path', 'm22 17-5 5']],
        'personas':     [['path', 'M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2'], ['circle', 9, 7, 4], ['path', 'M22 21v-2a4 4 0 0 0-3-3.87'], ['path', 'M16 3.13a4 4 0 0 1 0 7.75']],
        'calendario-mas': [['path', 'M8 2v4'], ['path', 'M16 2v4'], ['path', 'M21 13V6a2 2 0 0 0-2-2H5a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h8'], ['path', 'M3 10h18'], ['path', 'M19 16v6'], ['path', 'M16 19h6']],
        'sirena':       [['path', 'M7 18v-6a5 5 0 1 1 10 0v6'], ['path', 'M5 21a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1v-1a2 2 0 0 0-2-2H7a2 2 0 0 0-2 2z'], ['path', 'M21 12h1'], ['path', 'M18.5 4.5 18 5'], ['path', 'M2 12h1'], ['path', 'M12 2v1'], ['path', 'm4.929 4.929.707.707'], ['path', 'M12 12v6']],
        'subir':        [['path', 'M12 3v12'], ['path', 'm17 8-5-5-5 5'], ['path', 'M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4']],
        'adjunto':      [['path', 'm16 6-8.414 8.586a2 2 0 0 0 2.829 2.829l8.414-8.586a4 4 0 1 0-5.657-5.657l-8.379 8.551a6 6 0 1 0 8.485 8.485l8.379-8.551']],
        'ingreso':      [['path', 'M15 3h4a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-4'], ['path', 'm10 17 5-5-5-5'], ['path', 'M15 12H3']],
        'salida':       [['path', 'M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4'], ['path', 'm16 17 5-5-5-5'], ['path', 'M21 12H9']],
        'verificar':    [['path', 'M20 13c0 5-3.5 7.5-7.66 8.95a1 1 0 0 1-.67-.01C7.5 20.5 4 18 4 13V6a1 1 0 0 1 1-1c2 0 4.5-1.2 6.24-2.72a1.17 1.17 0 0 1 1.52 0C14.51 3.81 17 5 19 5a1 1 0 0 1 1 1z'], ['path', 'm9 12 2 2 4-4']],
        'atras':        [['path', 'm12 19-7-7 7-7'], ['path', 'M19 12H5']],
        'continuar':    [['path', 'M5 12h14'], ['path', 'm12 5 7 7-7 7']],
        'descargar':    [['path', 'M12 15V3'], ['path', 'M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4'], ['path', 'm7 10 5 5 5-5']],
        'descargar-todo': [['path', 'M20 20a2 2 0 0 0 2-2V8a2 2 0 0 0-2-2h-7.9a2 2 0 0 1-1.69-.9L9.6 3.9A2 2 0 0 0 7.93 3H4a2 2 0 0 0-2 2v13a2 2 0 0 0 2 2Z'], ['path', 'M12 10v6'], ['path', 'm9 13 3 3 3-3']],
        'papelera':     [['path', 'M3 6h18'], ['path', 'M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6'], ['path', 'M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2'], ['path', 'M10 11v6'], ['path', 'M14 11v6']],
        'cerrar':       [['path', 'M18 6 6 18'], ['path', 'm6 6 12 12']],
        'confirmar':    [['path', 'M8 2v4'], ['path', 'M16 2v4'], ['path', 'M3 10h18'], ['rect', 3, 4, 18, 18, 2], ['path', 'm9 16 2 2 4-4']],
        'iniciar':      [['path', 'M5 5a2 2 0 0 1 3.008-1.728l11.997 6.998a2 2 0 0 1 .003 3.458l-12 7A2 2 0 0 1 5 19z']],
        'pausa':        [['rect', 14, 3, 5, 18, 1], ['rect', 5, 3, 5, 18, 1]],
        'terminar':     [['circle', 12, 12, 10], ['path', 'm9 12 2 2 4-4']],
        'sin-atencion': [['circle', 12, 12, 10], ['path', 'm4.9 4.9 14.2 14.2']],
        'ceder':        [['path', 'M8 3 4 7l4 4'], ['path', 'M4 7h16'], ['path', 'm16 21 4-4-4-4'], ['path', 'M20 17H4']],
        'tomar':        [['path', 'm19 21-7-4-7 4V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2v16z']],
        'camion':       [['path', 'M14 18V6a2 2 0 0 0-2-2H4a2 2 0 0 0-2 2v11a1 1 0 0 0 1 1h2'], ['path', 'M15 18H9'], ['path', 'M19 18h2a1 1 0 0 0 1-1v-3.65a1 1 0 0 0-.22-.624l-3.48-4.35A1 1 0 0 0 17.52 8H14'], ['circle', 17, 18, 2], ['circle', 7, 18, 2]],
        'ayuda':        [['path', 'M15 14c.2-1 .7-1.7 1.5-2.5 1-.9 1.5-2.2 1.5-3.5A6 6 0 0 0 6 8c0 1 .2 2.2 1.5 3.5.7.7 1.3 1.5 1.5 2.5'], ['path', 'M9 18h6'], ['path', 'M10 22h4']],
        'copiar':       [['rect', 8, 8, 14, 14, 2], ['path', 'M4 16c-1.1 0-2-.9-2-2V4c0-1.1.9-2 2-2h10c1.1 0 2 .9 2 2']],
        'lista':        [['path', 'M3 12h.01'], ['path', 'M3 18h.01'], ['path', 'M3 6h.01'], ['path', 'M8 12h13'], ['path', 'M8 18h13'], ['path', 'M8 6h13']],
        'imprimir':     [['path', 'M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2'], ['path', 'M6 9V3h12v6'], ['rect', 6, 14, 12, 8, 1]],
        'guardar':      [['path', 'M15.2 3a2 2 0 0 1 1.4.6l3.8 3.8a2 2 0 0 1 .6 1.4V19a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2z'], ['path', 'M17 21v-7a1 1 0 0 0-1-1H8a1 1 0 0 0-1 1v7'], ['path', 'M7 3v4a1 1 0 0 0 1 1h7']],
        'buscar':       [['circle', 11, 11, 8], ['path', 'm21 21-4.3-4.3']],
        'refrescar':    [['path', 'M3 12a9 9 0 0 1 9-9 9.75 9.75 0 0 1 6.74 2.74L21 8'], ['path', 'M21 3v5h-5'], ['path', 'M21 12a9 9 0 0 1-9 9 9.75 9.75 0 0 1-6.74-2.74L3 16'], ['path', 'M8 16H3v5']],
        'incidencia':   [['path', 'm21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3'], ['path', 'M12 9v4'], ['path', 'M12 17h.01']]
    };
    var SVG_NS = 'http://www.w3.org/2000/svg';

    function icono(nombre, clase) {
        var def = ICONOS[nombre];
        var svg = document.createElementNS(SVG_NS, 'svg');
        svg.setAttribute('viewBox', '0 0 24 24'); svg.setAttribute('fill', 'none'); svg.setAttribute('stroke', 'currentColor');
        svg.setAttribute('stroke-width', '2'); svg.setAttribute('stroke-linecap', 'round'); svg.setAttribute('stroke-linejoin', 'round');
        svg.setAttribute('aria-hidden', 'true'); svg.setAttribute('focusable', 'false'); svg.setAttribute('class', 'ic' + (clase ? ' ' + clase : ''));
        (def || []).forEach(function (f) {
            var n = document.createElementNS(SVG_NS, f[0]);
            if (f[0] === 'path') n.setAttribute('d', f[1]);
            else if (f[0] === 'circle') { n.setAttribute('cx', f[1]); n.setAttribute('cy', f[2]); n.setAttribute('r', f[3]); }
            else if (f[0] === 'rect') { n.setAttribute('x', f[1]); n.setAttribute('y', f[2]); n.setAttribute('width', f[3]); n.setAttribute('height', f[4]); n.setAttribute('rx', f[5]); }
            svg.appendChild(n);
        });
        return svg;
    }

    // Botón (o enlace, si trae href) con icono. Siempre lleva el nombre de la acción en el tooltip y en aria-label.
    // o = { icono, texto, titulo, clase, href, onclick, disabled, emergencia, modo }
    // modo: 'icono' = solo icono (listados con mucha información) · 'auto' = icono y texto, solo icono en celular · 'texto' = siempre con texto.
    // emergencia: antepone la sirena (corrección de emergencia) en vez de escribir «(emergencia)».
    function btn(o) {
        var modo = o.modo || 'auto', nombre = o.titulo || (o.texto || '');
        var a = { class: 'btn btn-i' + (o.clase ? ' ' + o.clase : '') + (modo === 'icono' ? ' bi-icono' : modo === 'auto' ? ' bi-auto' : ''), title: nombre, 'aria-label': nombre };
        if (o.href) a.href = o.href; else { a.type = 'button'; if (o.disabled) a.disabled = true; }
        if (o.onclick) a.onclick = o.onclick;
        var hijos = [];
        if (o.emergencia) hijos.push(icono('sirena', 'ic-sirena'));
        if (o.icono) hijos.push(icono(o.icono));
        if (o.texto) hijos.push(el('span', { class: 'btn-t', text: o.texto }));
        return el(o.href ? 'a' : 'button', a, hijos);
    }

    // Cambia el contenido de un botón ya creado a «icono + texto» (el texto puede cambiar después con otra llamada).
    function rotular(b, nombre, texto) {
        b.textContent = '';
        b.classList.add('btn-i');
        if (nombre) b.appendChild(icono(nombre));
        b.appendChild(el('span', { class: 'btn-t', text: texto }));
        b.setAttribute('aria-label', texto);
    }

    // ── Iconos automáticos (D-257) ───────────────────────────────────────────────────────────────────────────────────────────
    // Todo botón con texto conocido recibe su icono, en TODAS las pantallas y ventanas (también las que se dibujan después).
    // Dentro de una tabla (acciones de fila) queda solo el icono con su tooltip; en cualquier otro lugar, icono y texto.
    // Para excluir uno: data-sin-icono. Los que ya traen icono (CAF.btn) no se tocan.
    var AUTO = [
        [/incidencia/i, 'incidencia'], [/^(editar|corregir|modificar)\b/i, 'editar'], [/^subtipos/i, 'lista'], [/^(decidir)\b/i, 'aprobar'],
        [/^(dar conformidad|aprobar|aprobada)/i, 'aprobar'], [/^(confirmar|aceptar|terminar|finalizar)\b/i, 'terminar'], [/^(desestimar|rechazar|denegar)/i, 'rechazar'],
        [/^revisar/i, 'ver'], [/^(ver|detalle|consultar)\b/i, 'ver'], [/^exportar/i, 'descargar'], [/^descargar/i, 'descargar'], [/^imprimir/i, 'imprimir'],
        [/^(guardar|registrar respaldo)/i, 'guardar'], [/^(cancelar|cerrar|quitar filtros|limpiar)\b/i, 'cerrar'], [/^volver\b/i, 'atras'], [/^atr[aá]s\b/i, 'atras'],
        [/^(siguiente|continuar)\b/i, 'continuar'], [/^buscar/i, 'buscar'], [/^(actualizar|recargar|refrescar)/i, 'refrescar'],
        [/^(desactivar|inactivar|bloquear|deshabilitar)/i, 'sin-atencion'], [/^(activar|habilitar|desbloquear)/i, 'terminar'],
        [/^(eliminar|retirar|quitar|borrar)\b/i, 'papelera'], [/^(reenviar|enviar)\b/i, 'reenviar'], [/^(restablecer|reiniciar)/i, 'refrescar'],
        [/^(nuev[oa]|agregar|a[ñn]adir|crear|\+)/i, 'agregar'], [/^salir\b/i, 'salida'], [/^subir/i, 'subir'], [/^adjuntar|^documentos?\b/i, 'adjunto']
    ];
    var NOAUTO = /\b(btn-icon|btn-tema|pill|btn-i|is-pagina|tp-)\b/;
    function iconoDe(t) { for (var i = 0; i < AUTO.length; i++) if (AUTO[i][0].test(t)) return AUTO[i][1]; return null; }
    function autoIconos(raiz) {
        Array.prototype.forEach.call((raiz || document).querySelectorAll('button.btn, a.btn'), function (b) {
            if (b.hasAttribute('data-sin-icono') || b.querySelector('svg') || NOAUTO.test(b.className) || b.children.length) return;
            var t = (b.textContent || '').trim();
            if (!t || t.length > 40) return;
            var nombre = iconoDe(t.replace(/^\+\s*/, t.charAt(0) === '+' ? 'Nuevo ' : ''));
            if (!nombre) return;
            var limpio = t.replace(/^\+\s*/, '').replace(/[…]+$/, '');
            b.textContent = ''; b.classList.add('btn-i');
            if (!b.getAttribute('title')) b.setAttribute('title', limpio);
            b.setAttribute('aria-label', limpio);
            b.appendChild(icono(nombre));
            b.appendChild(el('span', { class: 'btn-t', text: limpio }));
            if (b.closest && b.closest('td') && !b.closest('.modal')) b.classList.add('bi-icono');
        });
    }
    var pendiente = false;
    function programar() { if (pendiente) return; pendiente = true; (window.requestAnimationFrame || setTimeout)(function () { pendiente = false; autoIconos(); }); }
    function vigilar() { autoIconos(); if (window.MutationObserver) new MutationObserver(programar).observe(document.body, { childList: true, subtree: true }); }
    if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', vigilar); else vigilar();

    // Elementos de las vistas con data-icono="nombre": se les antepone el icono (para botones escritos a mano en .cshtml).
    function decorar() {
        Array.prototype.forEach.call(document.querySelectorAll('[data-icono]'), function (n) {
            var nombre = n.getAttribute('data-icono'); n.removeAttribute('data-icono');
            var t = n.textContent.trim(); n.classList.add('btn-i'); n.setAttribute('aria-label', t);
            n.textContent = ''; n.appendChild(icono(nombre)); n.appendChild(el('span', { class: 'btn-t', text: t }));
        });
    }
    if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', decorar); else decorar();

    return { el: el, pedir: pedir, aviso: aviso, modal: modal, autoRefrescar: autoRefrescar, icono: icono, btn: btn, rotular: rotular };
})();

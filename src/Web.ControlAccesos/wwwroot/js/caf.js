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
        caja.classList.add(ancho === 'ancho' ? 'modal-ancho' : 'modal-normal');
        function cerrar() { document.removeEventListener('keydown', tecla); if (fondo.parentNode) fondo.parentNode.removeChild(fondo); if (previo && previo.focus) previo.focus(); }
        function tecla(ev) { if (ev.key === 'Escape') cerrar(); }
        var pie = el('div', { class: 'modal-f' }, (botones || []).map(function (b) {
            return el('button', { type: 'button', class: 'btn' + (b.tipo === 'primary' ? ' btn-primary' : ''), text: b.texto, onclick: function () { b.onclick(cerrar); } });
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

    return { el: el, pedir: pedir, aviso: aviso, modal: modal };
})();

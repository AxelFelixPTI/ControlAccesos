// Ficha de ayuda por pantalla (D-255). Botón de bombilla en la cabecera: manual de uso + ficha técnica (SPs y tablas), visible para todos.
// La ficha técnica solo lista nombres de objetos de la base; no muestra datos ni credenciales.
(function () {
    'use strict';
    if (!window.CAF) return;
    var clave = document.body.getAttribute('data-pantalla') || '';
    var ctl = clave.split('/')[0];
    var man = (window.CAF_AYUDA_MAN || {})[clave] || null;
    var tec = (window.CAF_AYUDA_TEC || {})[ctl] || null;
    var cab = document.querySelector('.who');
    if (!cab || (!man && !tec)) return;
    var el = CAF.el;

    function seccion(titulo, hijo, abierta) {
        var d = el('details', { class: 'ay-sec' }, [el('summary', { text: titulo }), hijo]);
        if (abierta) d.open = true;
        return d;
    }

    function lista(items) { return el('ul', { class: 'ay-ul' }, items.map(function (t) { return el('li', { text: t }); })); }
    function tabla(filas, conIcono) {
        return el('table', { class: 'ay-tb' }, filas.map(function (f) {
            return el('tr', {}, conIcono
                ? [el('td', { class: 'ay-i' }, [CAF.icono(f[0])]), el('th', { text: f[1] }), el('td', { text: f[2] })]
                : [el('th', { text: f[0] }), el('td', { text: f[1] })]);
        }));
    }
    function tecnica() {
        var c = el('div', { class: 'stack' });
        if (!tec) { c.appendChild(el('p', { class: 'field-h', text: 'Esta pantalla no tiene ficha técnica.' })); return c; }
        c.appendChild(el('p', { class: 'field-h', text: 'Controlador: ' + ctl + ' · Servicios: ' + (tec.servicios.join(', ') || '—') }));
        c.appendChild(el('p', { class: 'field-h', text: 'Procedimientos y funciones de la base (' + tec.sps.length + '):' }));
        c.appendChild(el('div', { class: 'ay-cod' }, [el('code', { text: tec.sps.join('\n') })]));
        c.appendChild(el('p', { class: 'field-h', text: 'Tablas que consultan o modifican (' + tec.tablas.length + '):' }));
        c.appendChild(el('div', { class: 'ay-cod' }, [el('code', { text: tec.tablas.join('\n') })]));
        return c;
    }
    function texto() {
        var t = [];
        if (man) {
            t.push((man.titulo || clave).toUpperCase(), '', 'PARA QUÉ SIRVE', man.sirve, '', 'CÓMO FUNCIONA');
            man.funciona.forEach(function (x) { t.push('- ' + x); });
            [['CAMPOS', man.campos], ['COLUMNAS', man.columnas], ['ESTADOS', man.estados]].forEach(function (s) {
                if (s[1] && s[1].length) { t.push('', s[0]); s[1].forEach(function (f) { t.push('- ' + f[0] + ': ' + f[1]); }); }
            });
            if (man.botones && man.botones.length) { t.push('', 'BOTONES'); man.botones.forEach(function (f) { t.push('- ' + f[1] + ': ' + f[2]); }); }
            if (man.noHace && man.noHace.length) { t.push('', 'LO QUE NO HACE'); man.noHace.forEach(function (x) { t.push('- ' + x); }); }
        }
        if (tec) t.push('', 'FICHA TÉCNICA', 'Controlador: ' + ctl, 'Procedimientos: ' + tec.sps.join(', '), 'Tablas: ' + tec.tablas.join(', '));
        return t.join('\n');
    }
    function copiar() {
        var t = texto();
        function ok() { CAF.aviso('Manual copiado. Péguelo donde lo necesite.'); }
        if (navigator.clipboard && navigator.clipboard.writeText) { navigator.clipboard.writeText(t).then(ok, falla); return; }
        falla();
        function falla() {
            var a = el('textarea', { rows: '1' }); a.value = t; document.body.appendChild(a); a.select();
            try { document.execCommand('copy'); ok(); } catch (e) { CAF.aviso('No se pudo copiar.', 'warn'); }
            document.body.removeChild(a);
        }
    }
    function abrir() {
        var cuerpo = el('div', { class: 'stack ay' });
        if (man) {
            cuerpo.appendChild(el('p', { class: 'ay-lead', text: man.sirve }));
            cuerpo.appendChild(seccion('Cómo funciona', lista(man.funciona), true));
            if (man.campos.length) cuerpo.appendChild(seccion('Campos', tabla(man.campos)));
            if (man.columnas.length) cuerpo.appendChild(seccion('Columnas', tabla(man.columnas)));
            if (man.botones.length) cuerpo.appendChild(seccion('Botones', tabla(man.botones, true)));
            if (man.estados.length) cuerpo.appendChild(seccion('Estados', tabla(man.estados)));
            if (man.noHace.length) cuerpo.appendChild(seccion('Lo que NO hace', lista(man.noHace)));
        } else cuerpo.appendChild(el('p', { class: 'field-h', text: 'El manual de esta pantalla aún está en preparación. Abajo puede ver su ficha técnica.' }));
        cuerpo.appendChild(seccion('Ficha técnica', tecnica()));
        CAF.modal('Ayuda · ' + ((man && man.titulo) || document.querySelector('.top h1').textContent), cuerpo, [
            { texto: 'Copiar como manual', icono: 'copiar', onclick: function () { copiar(); } },
            { texto: 'Cerrar', onclick: function (c) { c(); } }], 'ancho');
    }
    var b = CAF.btn({ icono: 'ayuda', texto: 'Ayuda', titulo: 'Ayuda de esta pantalla', modo: 'icono', clase: 'btn-sm btn-ayuda', onclick: abrir });
    cab.insertBefore(b, cab.querySelector('#btn-tema'));
})();

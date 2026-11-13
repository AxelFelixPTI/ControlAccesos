// Sección «Almacén por empresa» de la pantalla Catálogos (D-236): empresas del grupo a las que da atención cada usuario de Almacén.
(function () {
    'use strict';
    var raiz = document.getElementById('caf-catalogos');
    var cuerpoTabla = document.getElementById('al-filas');
    if (!raiz || !cuerpoTabla) return;
    var urlListar = raiz.getAttribute('data-url-al-listar'), urlGuardar = raiz.getAttribute('data-url-al-guardar');
    var el = CAF.el, estado = { empresas: [], usuarios: [] };

    function cargar() {
        return CAF.pedir(urlListar).then(function (r) {
            if (!r.success) { CAF.aviso(r.message || 'No se pudo cargar.', 'warn'); return; }
            estado = r.data; pintar();
        });
    }

    function pintar() {
        cuerpoTabla.textContent = '';
        if (!estado.usuarios.length) { cuerpoTabla.appendChild(el('tr', {}, [el('td', { colspan: '4', class: 'vacio', text: 'No hay usuarios con la licencia de Almacén.' })])); return; }
        estado.usuarios.forEach(function (u) {
            var nombres = estado.empresas.filter(function (e) { return u.empresasIds.indexOf(e.id) >= 0; }).map(function (e) { return e.texto; });
            cuerpoTabla.appendChild(el('tr', {}, [
                el('td', { class: 'stk', text: u.nombre }), el('td', { text: u.cargo || '—' }),
                el('td', {}, [nombres.length ? el('span', { text: nombres.join(' · ') }) : el('span', { class: 'chip c-rec', text: 'Sin empresas: no puede atender' })]),
                el('td', {}, [el('button', { type: 'button', class: 'btn btn-sm', text: 'Editar', onclick: function () { editar(u); } })])
            ]));
        });
    }

    function editar(u) {
        var sel = {}; u.empresasIds.forEach(function (i) { sel[i] = true; });
        var lista = el('div', { class: 'stack' });
        estado.empresas.forEach(function (e) {
            var cb = el('input', { type: 'checkbox' }); cb.checked = !!sel[e.id];
            cb.addEventListener('change', function () { if (cb.checked) sel[e.id] = true; else delete sel[e.id]; });
            lista.appendChild(el('label', { class: 'chk' }, [cb, el('span', { text: e.texto })]));
        });
        var env = false;
        CAF.modal('Empresas que atiende · ' + u.nombre, el('div', { class: 'stack' }, [el('p', { class: 'field-h', text: 'Marque las empresas a las que puede dar atención.' }), lista]), [
            { texto: 'Cancelar', onclick: function (c) { c(); } },
            { texto: 'Guardar', tipo: 'primary', onclick: function (c) {
                if (env) return; env = true;
                CAF.pedir(urlGuardar, { method: 'POST', body: { usuarioId: u.id, empresasIds: estado.empresas.filter(function (e) { return sel[e.id]; }).map(function (e) { return e.id; }) } }).then(function (r) {
                    env = false;
                    if (!r.success) { CAF.aviso(r.message || 'No se pudo guardar.', 'warn'); return; }
                    CAF.aviso(r.message || 'Guardado.'); c(); cargar();
                });
            } }
        ]);
    }
    cargar();
})();

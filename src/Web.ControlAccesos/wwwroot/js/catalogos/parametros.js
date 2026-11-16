// Sección «Parámetros» de la pantalla Catálogos (D-238): valores del sistema que se pueden ajustar sin tocar la base de datos.
// El formato de cada valor lo valida el procedimiento ERP_CAF_PARAMETRO_GUARDAR; aquí solo se muestran y se editan.
(function () {
    'use strict';
    var raiz = document.getElementById('caf-catalogos');
    var cuerpoTabla = document.getElementById('pa-filas');
    if (!raiz || !cuerpoTabla) return;
    var urlListar = raiz.getAttribute('data-url-pa-listar'), urlGuardar = raiz.getAttribute('data-url-pa-guardar');
    var el = CAF.el, lista = [];
    // Nombre para mostrar y ayuda de cada clave conocida (las desconocidas se muestran con su clave y su descripción)
    var NOMBRE = {
        ATENCIONES_SIMULTANEAS_EMPRESA: ['Atenciones simultáneas por empresa', 'Cuántas entregas puede atender a la vez una misma empresa. Número entero de 1 a 99 (por defecto 1).'],
        EXCLUSA_CAPACIDAD: ['Capacidad de la esclusa', 'Cuántas personas pueden estar dentro de la esclusa a la vez. Número entero de 1 a 99.'],
        PROVEEDOR_HORA_CORTE: ['Hora de corte del día de proveedores', 'A esta hora (HH:MM) se cierran las entregas del día anterior que quedaron abiertas.']
    };

    function cargar() {
        return CAF.pedir(urlListar).then(function (r) {
            if (!r.success) { CAF.aviso(r.message || 'No se pudo cargar.', 'warn'); return; }
            lista = r.data || []; pintar();
        });
    }

    function pintar() {
        cuerpoTabla.textContent = '';
        if (!lista.length) { cuerpoTabla.appendChild(el('tr', {}, [el('td', { colspan: '3', class: 'vacio', text: 'No hay parámetros.' })])); return; }
        lista.forEach(function (p) {
            var n = NOMBRE[p.clave] || [p.clave, p.descripcion || ''];
            cuerpoTabla.appendChild(el('tr', {}, [
                el('td', { class: 'stk' }, [el('b', { text: n[0] }), el('div', { class: 'small muted', text: n[1] || p.descripcion || '' })]),
                el('td', { text: p.valor === '' ? '—' : p.valor }),
                el('td', {}, [el('button', { type: 'button', class: 'btn btn-sm', text: 'Editar', onclick: function () { editar(p, n); } })])
            ]));
        });
    }

    function editar(p, n) {
        var inp = el('input', { type: 'text', maxlength: '200', value: p.valor });
        var err = el('span', { class: 'field-e' });
        var env = false;
        CAF.modal('Parámetro · ' + n[0], el('div', { class: 'stack' }, [
            n[1] ? el('p', { class: 'field-h', text: n[1] }) : null,
            el('label', { class: 'field' }, [el('span', { class: 'field-l', text: 'Valor' }), inp, err])
        ]), [
            { texto: 'Cancelar', onclick: function (c) { c(); } },
            { texto: 'Guardar', tipo: 'primary', onclick: function (c) {
                if (env) return; env = true; err.textContent = '';
                CAF.pedir(urlGuardar, { method: 'POST', body: { clave: p.clave, valor: inp.value } }).then(function (r) {
                    env = false;
                    if (!r.success) { err.textContent = r.message || 'No se pudo guardar.'; return; }
                    CAF.aviso(r.message || 'Guardado.'); c(); cargar();
                });
            } }
        ]);
    }
    cargar();
})();

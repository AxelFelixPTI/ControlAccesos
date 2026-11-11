// Sección «Tipos de ingreso» de la pantalla Catálogos: lista, crea y edita los tipos (disponibilidad, orden, aprobación).
(function () {
    'use strict';
    var raiz = document.getElementById('caf-catalogos');
    var cuerpoTabla = document.getElementById('tp-filas');
    if (!raiz || !cuerpoTabla) return;
    var urlListar = raiz.getAttribute('data-url-tp-listar');
    var urlGuardar = raiz.getAttribute('data-url-tp-guardar');
    var el = CAF.el;
    var filas = [];

    function cargar() {
        return CAF.pedir(urlListar).then(function (r) {
            if (!r.success) { CAF.aviso(r.message || 'No se pudieron cargar los tipos de ingreso.', 'warn'); return; }
            filas = r.data; pintar();
            document.dispatchEvent(new CustomEvent('caf:tipos-cambiaron'));
        });
    }

    function pintar() {
        cuerpoTabla.textContent = '';
        if (!filas.length) { cuerpoTabla.appendChild(el('tr', {}, [el('td', { colspan: '8', class: 'vacio', text: 'Todavía no hay tipos.' })])); return; }
        filas.forEach(function (t) {
            cuerpoTabla.appendChild(el('tr', { class: t.activo ? '' : 'off' }, [
                el('td', { class: 'stk' }, [el('span', { text: t.descripcion }), el('div', { class: 'small muted', text: t.codigo })]),
                el('td', { text: t.requiereAprobacion ? 'Requiere' : 'No requiere' }),
                el('td', {}, [el('span', { class: 'chip ' + (t.disponible ? 'c-ok' : 'c-can'), text: t.disponible ? 'Sí' : 'No' })]),
                el('td', { text: String(t.orden) }),
                el('td', {}, [t.subtipos ? el('span', { text: t.subtipos }) : el('span', { class: 'small muted', text: 'Sin subtipos' })]),
                el('td', { class: 'small', text: t.pasos + ' paso(s) de aprobación · ' + t.items + ' ítem(s) de checklist · ' + t.solicitudes + ' solicitud(es)' }),
                el('td', {}, [el('span', { class: 'chip ' + (t.activo ? 'c-ok' : 'c-can'), text: t.activo ? 'Activo' : 'Inactivo' })]),
                el('td', {}, [el('button', { type: 'button', class: 'btn btn-sm', text: 'Editar', onclick: function () { formulario(t); } })])
            ]));
        });
    }

    function campo(etiqueta, control, ayuda) {
        var hijos = [el('span', { class: 'field-l', text: etiqueta }), control];
        if (ayuda) hijos.push(el('span', { class: 'field-h', text: ayuda }));
        return el('label', { class: 'field' }, hijos);
    }
    function casilla(texto, marcado) {
        var i = el('input', { type: 'checkbox' }); i.checked = !!marcado;
        return { nodo: el('label', { class: 'chk' }, [i, texto]), input: i };
    }

    function formulario(item) {
        var nombre = el('input', { type: 'text', maxlength: '500', autocomplete: 'off' });
        nombre.value = item ? item.descripcion : '';
        var orden = el('input', { type: 'number', min: '0', max: '9999' });
        orden.value = item ? String(item.orden) : ''; orden.placeholder = 'Al final';
        var aprob = casilla('Requiere aprobación del Coordinador', item ? item.requiereAprobacion : true);
        var disp = casilla('Disponible (se puede elegir al crear una solicitud)', item ? item.disponible : false);
        var activo = casilla('Activo (se muestra en las listas)', item ? item.activo : true);
        var error = el('p', { class: 'field-e' });

        var cuerpo = el('div', { class: 'stack' });
        cuerpo.appendChild(campo('Nombre *', nombre));
        cuerpo.appendChild(campo('Orden', orden, 'Posición en la lista de tipos.'));
        cuerpo.appendChild(aprob.nodo);
        cuerpo.appendChild(disp.nodo);
        cuerpo.appendChild(activo.nodo);
        cuerpo.appendChild(error);
        if (item && item.propio) {
            aprob.input.disabled = true;
            cuerpo.appendChild(el('div', { class: 'aviso a-info', text: 'Este tipo tiene un flujo propio (pantalla y reglas específicas): puede cambiar su nombre, orden, disponibilidad y estado; si requiere aprobación lo define el flujo.' }));
        } else if (!item) {
            cuerpo.appendChild(el('div', { class: 'aviso a-info', text: 'El tipo nuevo usa el flujo estándar de visitante: se le copian los pasos de aprobación y el checklist de «Visita externa». Después puede ajustar su checklist más abajo. Un flujo con campos o reglas propias requiere desarrollo.' }));
        } else if (item.solicitudes > 0) {
            cuerpo.appendChild(el('div', { class: 'aviso a-info', text: 'Ya tiene ' + item.solicitudes + ' solicitud(es). No se elimina: desactívelo para que deje de ofrecerse.' }));
        }

        CAF.modal((item ? 'Editar' : 'Nuevo') + ' tipo de ingreso', cuerpo, [
            { texto: 'Cancelar', onclick: function (cerrar) { cerrar(); } },
            {
                texto: 'Guardar', tipo: 'primary', onclick: function (cerrar) {
                    error.textContent = '';
                    var envio = {
                        id: item ? item.id : 0, descripcion: nombre.value, requiereAprobacion: aprob.input.checked,
                        disponible: disp.input.checked, activo: activo.input.checked,
                        orden: orden.value === '' ? null : parseInt(orden.value, 10)
                    };
                    CAF.pedir(urlGuardar, { method: 'POST', body: envio }).then(function (r) {
                        if (!r.success) { error.textContent = r.message || 'No se pudo guardar.'; return; }
                        cerrar();
                        CAF.aviso((item ? 'Se guardó «' : 'Se agregó «') + nombre.value.trim() + '».');
                        cargar();
                    });
                }
            }
        ]);
    }

    document.getElementById('tp-nuevo').addEventListener('click', function () { formulario(null); });
    cargar();
})();

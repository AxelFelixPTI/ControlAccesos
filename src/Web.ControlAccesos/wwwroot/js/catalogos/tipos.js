// Sección «Tipos de ingreso» de la pantalla Catálogos: lista, crea y edita los tipos (disponibilidad, orden, aprobación).
(function () {
    'use strict';
    var raiz = document.getElementById('caf-catalogos');
    var cuerpoTabla = document.getElementById('tp-filas');
    if (!raiz || !cuerpoTabla) return;
    var urlListar = raiz.getAttribute('data-url-tp-listar');
    var urlGuardar = raiz.getAttribute('data-url-tp-guardar');
    var urlSubListar = raiz.getAttribute('data-url-sub-listar');
    var urlSubGuardar = raiz.getAttribute('data-url-sub-guardar');
    var urlSubEstado = raiz.getAttribute('data-url-sub-estado');
    var urlSubPred = raiz.getAttribute('data-url-sub-pred');
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
                el('td', {}, [el('button', { type: 'button', class: 'btn btn-sm', text: 'Editar', onclick: function () { formulario(t); } }), ' ', el('button', { type: 'button', class: 'btn btn-sm', text: 'Subtipos', onclick: function () { subtipos(t); } })])
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

    // ── Subtipos (roles de persona) del tipo (D-234) ─────────────────────────────────────────
    // Sin subtipos, el checklist se define por tipo. Con subtipos, el checklist se define por subtipo (pantalla «Checklist de portería»).
    function subtipos(tipo) {
        var lista = el('div', { class: 'stack' });
        var aviso = el('p', { class: 'field-e' });
        var cuerpo = el('div', { class: 'stack' }, [
            el('div', { class: 'aviso a-info', text: 'Cada persona de una solicitud de «' + tipo.descripcion + '» tiene un rol. Si el tipo tiene subtipos, su checklist se define por subtipo (en «Checklist de portería»). Un subtipo no se elimina: se desactiva y deja de ofrecerse.' }),
            lista, aviso
        ]);
        var datos = [];

        function recargar() {
            return CAF.pedir(urlSubListar + '?tipoId=' + tipo.id).then(function (r) {
                if (!r.success) { aviso.textContent = r.message || 'No se pudieron cargar los subtipos.'; return; }
                datos = r.data; pintarLista();
            });
        }
        function llamar(url, cuerpoEnvio, ok) {
            aviso.textContent = '';
            CAF.pedir(url, { method: 'POST', body: cuerpoEnvio }).then(function (r) {
                if (!r.success) { aviso.textContent = r.message || 'No se pudo completar.'; return; }
                if (ok) CAF.aviso(ok);
                recargar().then(function () { cargar(); });
            });
        }
        function pintarLista() {
            lista.textContent = '';
            if (!datos.length) lista.appendChild(el('p', { class: 'small muted', text: 'Este tipo no tiene subtipos: todas sus personas comparten un mismo checklist.' }));
            datos.forEach(function (s) {
                var acciones = [el('button', { type: 'button', class: 'btn btn-sm', text: 'Editar', onclick: function () { editar(s); } })];
                if (s.activo && !s.predeterminado) acciones.push(el('button', { type: 'button', class: 'btn btn-sm', text: 'Hacer predeterminado', onclick: function () { llamar(urlSubPred, { id: s.id }, 'Predeterminado actualizado.'); } }));
                if (!s.activo) acciones.push(el('button', { type: 'button', class: 'btn btn-sm', text: 'Activar', onclick: function () { llamar(urlSubEstado, { id: s.id, activo: true }, 'Subtipo activado.'); } }));
                else if (!s.predeterminado && !s.sistema) acciones.push(el('button', { type: 'button', class: 'btn btn-sm', text: 'Desactivar', onclick: function () { llamar(urlSubEstado, { id: s.id, activo: false }, 'Subtipo desactivado.'); } }));
                lista.appendChild(el('div', { class: 'vrow' + (s.activo ? '' : ' off') }, [
                    el('div', {}, [el('strong', { text: s.descripcion }), ' ',
                        s.predeterminado ? el('span', { class: 'chip c-ok', text: 'Predeterminado' }) : null,
                        s.activo ? null : el('span', { class: 'chip c-can', text: 'Desactivado' }),
                        el('div', { class: 'small muted', text: s.codigo + ' · ' + s.personas + ' persona(s) con este rol' })]),
                    el('div', { class: 'vrow-e' }, acciones)
                ]));
            });
            lista.appendChild(el('div', {}, [el('button', { type: 'button', class: 'btn btn-sm btn-primary', text: '+ Agregar subtipo', onclick: function () { editar(null); } })]));
        }
        function editar(s) {
            var nombre = el('input', { type: 'text', maxlength: '200', autocomplete: 'off' });
            nombre.value = s ? s.descripcion : '';
            var orden = el('input', { type: 'number', min: '0', max: '9999' });
            orden.value = s ? String(s.orden) : ''; orden.placeholder = 'Al final';
            var copiar = el('select');
            copiar.appendChild(el('option', { value: '', text: 'Sin checklist (lo defino después)' }));
            datos.forEach(function (x) { copiar.appendChild(el('option', { value: String(x.id), text: 'Copiar el de «' + x.descripcion + '»' })); });
            var err = el('p', { class: 'field-e' });
            var hijos = [campo('Nombre *', nombre), campo('Orden', orden, 'Posición en la lista.')];
            if (!s && datos.some(function (x) { return x.activo; })) hijos.push(campo('Checklist inicial', copiar, 'El subtipo nuevo nace con el checklist que elija; luego puede ajustarlo en «Checklist de portería».'));
            if (!s && !datos.some(function (x) { return x.activo; })) hijos.push(el('div', { class: 'aviso a-info', text: 'Será el primer subtipo: queda como predeterminado, recibe el checklist que hoy tiene el tipo y las personas ya registradas pasan a este rol.' }));
            hijos.push(err);
            CAF.modal(s ? 'Editar subtipo' : 'Nuevo subtipo', el('div', { class: 'stack' }, hijos), [
                { texto: 'Cancelar', onclick: function (c) { c(); } },
                { texto: 'Guardar', tipo: 'primary', onclick: function (c) {
                    err.textContent = '';
                    CAF.pedir(urlSubGuardar, { method: 'POST', body: { id: s ? s.id : 0, tipoId: tipo.id, descripcion: nombre.value, orden: orden.value === '' ? null : parseInt(orden.value, 10), copiarDeId: copiar.value ? parseInt(copiar.value, 10) : null } }).then(function (r) {
                        if (!r.success) { err.textContent = r.message || 'No se pudo guardar.'; return; }
                        c(); CAF.aviso('Se guardó el subtipo.'); recargar().then(function () { cargar(); });
                    });
                } }
            ]);
        }
        CAF.modal('Subtipos · ' + tipo.descripcion, cuerpo, [{ texto: 'Cerrar', onclick: function (c) { c(); } }]);
        recargar();
    }

    document.getElementById('tp-nuevo').addEventListener('click', function () { formulario(null); });
    cargar();
})();

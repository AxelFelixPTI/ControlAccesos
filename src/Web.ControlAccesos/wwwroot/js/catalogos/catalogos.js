// Pantalla Catálogos: lista y edita zonas, motivos, tratamientos e incidencias.
(function () {
    'use strict';
    var raiz = document.getElementById('caf-catalogos');
    if (!raiz) return;
    var urlListar = raiz.getAttribute('data-url-listar');
    var urlGuardar = raiz.getAttribute('data-url-guardar');
    var el = CAF.el;
    var datos = { zona: [], motivo: [], tratamiento: [], incidencia: [], area: [], cargo: [] };

    var NOMBRES = { zona: 'zona', motivo: 'motivo de visita', tratamiento: 'tratamiento de desviación', incidencia: 'tipo de incidencia', area: 'área', cargo: 'cargo' };
    var EFECTO = {
        INGRESA: 'Ingresa', INGRESA_RESTRINGIDO: 'Ingresa restringido a zona administrativa', NO_INGRESA: 'No ingresa',
        SALE: 'Sale', SALE_RETIENE_ELEMENTO: 'Sale; el elemento queda retenido'
    };

    function chip(activo) { return el('span', { class: 'chip ' + (activo ? 'c-ok' : 'c-can'), text: activo ? 'Activa' : 'Inactiva' }); }
    function cargar(tipo) {
        return CAF.pedir(urlListar + '?tipo=' + encodeURIComponent(tipo)).then(function (r) {
            if (!r.success) { CAF.aviso(r.message || 'No se pudo cargar.', 'warn'); return; }
            datos[tipo] = r.data; pintar(tipo);
        });
    }

    function pintar(tipo) {
        var cont = document.getElementById('cat-' + tipo);
        cont.textContent = '';
        var filas = datos[tipo];
        if (tipo === 'zona') {
            if (!filas.length) { cont.appendChild(el('tr', {}, [el('td', { colspan: '6', class: 'vacio', text: 'Todavía no hay zonas.' })])); return; }
            filas.forEach(function (z) {
                cont.appendChild(el('tr', { class: z.activo ? '' : 'off' }, [
                    el('td', { class: 'stk', text: z.descripcion }),
                    el('td', { text: z.tipoZona === 'OPERATIVA' ? 'Operativa' : 'Administrativa' }),
                    el('td', { text: z.exigeSctr ? 'Sí' : 'No' }),
                    el('td', { text: z.exigeEpp ? 'Sí' : 'No' }),
                    el('td', {}, [chip(z.activo)]),
                    el('td', {}, [el('button', { type: 'button', class: 'btn btn-sm', text: 'Editar', onclick: function () { formulario('zona', z); } })])
                ]));
            });
            return;
        }
        filas.forEach(function (it) {
            var texto = el('span', { text: it.descripcion });
            if (tipo === 'tratamiento' && !it.esOtro) {
                var ap = [it.resultadoIngreso && 'ingreso', it.resultadoSalida && 'salida'].filter(Boolean).join(' y ');
                texto.appendChild(el('span', { class: 'small muted', text: ' · ' + ap }));
            }
            if (!it.activo) texto.appendChild(el('span', { class: 'small muted', text: ' · inactivo' }));
            var derecha = it.esOtro
                ? el('span', { class: 'small muted', text: 'fijo · texto libre' })
                : el('button', { type: 'button', class: 'btn btn-sm', text: 'Editar', onclick: function () { formulario(tipo, it); } });
            cont.appendChild(el('li', { class: it.activo ? '' : 'off' }, [texto, derecha]));
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
    function combo(opciones, valor, vacio) {
        var s = el('select');
        if (vacio) s.appendChild(el('option', { value: '', text: vacio }));
        opciones.forEach(function (o) { s.appendChild(el('option', { value: o[0], text: o[1] })); });
        s.value = valor || '';
        return s;
    }

    function formulario(tipo, item) {
        var nombre = el('input', { type: 'text', maxlength: '500', autocomplete: 'off' });
        nombre.value = item ? item.descripcion : '';
        var error = el('p', { class: 'field-e' });
        var cuerpo = el('div', { class: 'stack' });
        cuerpo.appendChild(campo('Nombre *', nombre));
        cuerpo.appendChild(error);

        var cTipo, cSctr, cEpp, cIng, cSal;
        if (tipo === 'zona') {
            cTipo = combo([['ADMINISTRATIVA', 'Administrativa'], ['OPERATIVA', 'Operativa']], item ? item.tipoZona : 'ADMINISTRATIVA');
            cSctr = casilla('Exige SCTR', item && item.exigeSctr);
            cEpp = casilla('Exige EPP', item && item.exigeEpp);
            cuerpo.appendChild(campo('Tipo', cTipo));
            cuerpo.appendChild(cSctr.nodo);
            cuerpo.appendChild(cEpp.nodo);
            cuerpo.appendChild(el('p', { class: 'small muted', text: 'Las solicitudes ya enviadas conservan lo que exigía la zona al enviarse.' }));
        }
        if (tipo === 'tratamiento') {
            cIng = combo([['INGRESA', EFECTO.INGRESA], ['INGRESA_RESTRINGIDO', EFECTO.INGRESA_RESTRINGIDO], ['NO_INGRESA', EFECTO.NO_INGRESA]], item && item.resultadoIngreso, 'No aplica al ingreso');
            cSal = combo([['SALE', EFECTO.SALE], ['SALE_RETIENE_ELEMENTO', EFECTO.SALE_RETIENE_ELEMENTO]], item && item.resultadoSalida, 'No aplica a la salida');
            cuerpo.appendChild(el('div', { class: 'grid g2' }, [campo('Efecto al ingreso', cIng), campo('Efecto a la salida', cSal)]));
        }
        var cActivo = casilla('Activo (se ofrece en las listas)', item ? item.activo : true);
        cuerpo.appendChild(cActivo.nodo);
        if (item) cuerpo.appendChild(el('div', { class: 'aviso a-info', text: 'No se elimina: desactívelo para que deje de ofrecerse. Lo ya registrado se conserva.' }));

        CAF.modal((item ? 'Editar ' : 'Nuevo ') + NOMBRES[tipo], cuerpo, [
            { texto: 'Cancelar', onclick: function (cerrar) { cerrar(); } },
            {
                texto: 'Guardar', tipo: 'primary', onclick: function (cerrar) {
                    error.textContent = '';
                    var cuerpoEnvio = {
                        tipo: tipo, id: item ? item.id : 0, descripcion: nombre.value, activo: cActivo.input.checked,
                        tipoZona: cTipo ? cTipo.value : null, exigeSctr: cSctr ? cSctr.input.checked : false, exigeEpp: cEpp ? cEpp.input.checked : false,
                        resultadoIngreso: cIng ? cIng.value : null, resultadoSalida: cSal ? cSal.value : null
                    };
                    CAF.pedir(urlGuardar, { method: 'POST', body: cuerpoEnvio }).then(function (r) {
                        if (!r.success) { error.textContent = r.message || 'No se pudo guardar.'; return; }
                        cerrar();
                        CAF.aviso((item ? 'Se guardó «' : 'Se agregó «') + nombre.value.trim() + '».');
                        cargar(tipo);
                    });
                }
            }
        ]);
    }

    Array.prototype.forEach.call(raiz.querySelectorAll('[data-nuevo]'), function (b) {
        b.addEventListener('click', function () { formulario(b.getAttribute('data-nuevo'), null); });
    });
    ['zona', 'motivo', 'tratamiento', 'incidencia', 'area', 'cargo'].forEach(cargar);
})();

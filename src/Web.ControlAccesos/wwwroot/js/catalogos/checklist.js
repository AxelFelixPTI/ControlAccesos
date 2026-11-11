// Sección «Checklist de portería» de la pantalla Catálogos: lista, crea y edita los ítems y los asigna a tipos de ingreso.
(function () {
    'use strict';
    var raiz = document.getElementById('caf-catalogos');
    var cuerpoTabla = document.getElementById('ck-filas');
    if (!raiz || !cuerpoTabla) return;
    var urlListar = raiz.getAttribute('data-url-ck-listar');
    var urlGuardar = raiz.getAttribute('data-url-ck-guardar');
    var el = CAF.el;
    var estado = { items: [], tipos: [], subtipos: [] };

    var CONDICION = {
        SIEMPRE: 'Siempre',
        ZONA_EXIGE_SCTR: 'Si la zona exige SCTR',
        ZONA_EXIGE_EPP: 'Si la zona exige EPP',
        TRAE_EQUIPOS: 'Si trae equipos',
        TRAE_HERRAMIENTAS: 'Si trae herramientas',
        // Condiciones antiguas (ya no se ofrecen; se elige el subtipo al asignar el tipo). Se muestran solo si el ítem aún las tiene.
        SOLO_PRINCIPAL: 'Solo al transportista (antiguo)',
        SOLO_AYUDANTE: 'Solo a los ayudantes de descarga (antiguo)'
    };
    var ANTIGUAS = ['SOLO_PRINCIPAL', 'SOLO_AYUDANTE'];
    var ETAPA = { INGRESO: 'Ingreso', SALIDA: 'Salida' };

    function nombreSubtipo(id) {
        var s = estado.subtipos.filter(function (x) { return x.id === id; })[0];
        return s ? s.nombre : ('#' + id);
    }
    function nombresTipos(asig) {
        if (!asig.length) return null;
        return asig.map(function (a) {
            var t = estado.tipos.filter(function (x) { return x.id === a.tipo; })[0];
            return (t ? t.nombre : ('#' + a.tipo)) + (a.subtipo ? ' (solo ' + nombreSubtipo(a.subtipo).toLowerCase() + ')' : '');
        }).join(', ');
    }
    document.addEventListener('caf:tipos-cambiaron', function () { cargar(); });

    function cargar() {
        return CAF.pedir(urlListar).then(function (r) {
            if (!r.success) { CAF.aviso(r.message || 'No se pudo cargar el checklist.', 'warn'); return; }
            estado = r.data; pintar();
        });
    }

    function pintar() {
        cuerpoTabla.textContent = '';
        if (!estado.items.length) {
            cuerpoTabla.appendChild(el('tr', {}, [el('td', { colspan: '8', class: 'vacio', text: 'Todavía no hay ítems.' })]));
            return;
        }
        estado.items.forEach(function (it) {
            var tipos = nombresTipos(it.tipos);
            var celdaTipos = el('td', {}, [tipos ? el('span', { text: tipos }) : el('span', { class: 'small muted', text: 'Ningún tipo (no se ofrece)' })]);
            var ayuda = it.ayuda ? el('div', { class: 'small muted', text: it.ayuda }) : null;
            var primera = el('td', { class: 'stk' }, [el('span', { text: it.descripcion })]);
            if (ayuda) primera.appendChild(ayuda);
            cuerpoTabla.appendChild(el('tr', { class: it.activo ? '' : 'off' }, [
                primera,
                el('td', { text: ETAPA[it.etapa] || it.etapa }),
                el('td', { text: CONDICION[it.condicion] || it.condicion }),
                el('td', { text: it.esCritico ? 'Sí' : 'No' }),
                el('td', { text: String(it.orden) }),
                celdaTipos,
                el('td', {}, [el('span', { class: 'chip ' + (it.activo ? 'c-ok' : 'c-can'), text: it.activo ? 'Activo' : 'Inactivo' })]),
                el('td', {}, [el('button', { type: 'button', class: 'btn btn-sm', text: 'Editar', onclick: function () { formulario(it); } })])
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
    function combo(opciones, valor) {
        var s = el('select');
        opciones.forEach(function (o) { s.appendChild(el('option', { value: o[0], text: o[1] })); });
        s.value = valor;
        return s;
    }

    function formulario(item) {
        var texto = el('input', { type: 'text', maxlength: '500', autocomplete: 'off' });
        texto.value = item ? item.descripcion : '';
        var ayuda = el('input', { type: 'text', maxlength: '500', autocomplete: 'off' });
        ayuda.value = item && item.ayuda ? item.ayuda : '';
        var etapa = combo([['INGRESO', 'Ingreso'], ['SALIDA', 'Salida']], item ? item.etapa : 'INGRESO');
        var condicion = combo(Object.keys(CONDICION).filter(function (k) {
            return ANTIGUAS.indexOf(k) < 0 || (item && item.condicion === k);
        }).map(function (k) { return [k, CONDICION[k]]; }), item ? item.condicion : 'SIEMPRE');
        var orden = el('input', { type: 'number', min: '0', max: '9999' });
        orden.value = item ? String(item.orden) : '';
        orden.placeholder = 'Al final';
        var critico = casilla('Crítico: si no se cumple, se registra una desviación', item && item.esCritico);
        var activo = casilla('Activo (se ofrece en portería)', item ? item.activo : true);
        var error = el('p', { class: 'field-e' });

        var cajasTipos = estado.tipos.map(function (t) {
            var actual = item ? item.tipos.filter(function (a) { return a.tipo === t.id; })[0] : null;
            var c = casilla(t.nombre, !!actual);
            c.id = t.id;
            var subs = estado.subtipos.filter(function (x) { return x.tipoId === t.id; });
            if (subs.length) {
                c.sub = combo([['', 'A todas las personas del tipo']].concat(subs.map(function (x) { return [String(x.id), 'Solo: ' + x.nombre]; })), actual && actual.subtipo ? String(actual.subtipo) : '');
                c.sub.disabled = !c.input.checked;
                c.input.addEventListener('change', function () { c.sub.disabled = !c.input.checked; });
                c.nodo = el('div', { class: 'stack' }, [c.nodo, c.sub]);
            }
            return c;
        });

        var cuerpo = el('div', { class: 'stack' });
        cuerpo.appendChild(campo('Qué verifica el vigilante *', texto, 'Redáctelo como una pregunta o instrucción corta.'));
        cuerpo.appendChild(campo('Ayuda (opcional)', ayuda, 'Texto de apoyo que ve el vigilante bajo el ítem.'));
        cuerpo.appendChild(el('div', { class: 'grid g2' }, [campo('Etapa', etapa), campo('Orden', orden)]));
        cuerpo.appendChild(campo('Cuándo aplica', condicion));
        cuerpo.appendChild(critico.nodo);
        cuerpo.appendChild(el('span', { class: 'field-l', text: 'Se ofrece a estos tipos de ingreso' }));
        cajasTipos.forEach(function (c) { cuerpo.appendChild(c.nodo); });
        cuerpo.appendChild(activo.nodo);
        cuerpo.appendChild(error);
        if (item && item.usos > 0) {
            cuerpo.appendChild(el('div', { class: 'aviso a-info', text: 'Este ítem ya se respondió ' + item.usos + ' vez/veces: no puede cambiar de etapa. Si ya no hace falta, desactívelo; el historial se conserva.' }));
            etapa.disabled = true;
        } else if (item) {
            cuerpo.appendChild(el('div', { class: 'aviso a-info', text: 'No se elimina: desactívelo para que deje de ofrecerse.' }));
        }

        CAF.modal((item ? 'Editar' : 'Nuevo') + ' ítem del checklist', cuerpo, [
            { texto: 'Cancelar', onclick: function (cerrar) { cerrar(); } },
            {
                texto: 'Guardar', tipo: 'primary', onclick: function (cerrar) {
                    error.textContent = '';
                    var envio = {
                        id: item ? item.id : 0, descripcion: texto.value, ayuda: ayuda.value, etapa: etapa.value, condicion: condicion.value,
                        esCritico: critico.input.checked, activo: activo.input.checked,
                        orden: orden.value === '' ? null : parseInt(orden.value, 10),
                        tipos: cajasTipos.filter(function (c) { return c.input.checked; }).map(function (c) {
                            return { tipo: c.id, subtipo: c.sub && c.sub.value ? parseInt(c.sub.value, 10) : null };
                        })
                    };
                    CAF.pedir(urlGuardar, { method: 'POST', body: envio }).then(function (r) {
                        if (!r.success) { error.textContent = r.message || 'No se pudo guardar.'; return; }
                        cerrar();
                        CAF.aviso('Se guardó el ítem del checklist.');
                        cargar();
                    });
                }
            }
        ]);
    }

    document.getElementById('ck-nuevo').addEventListener('click', function () { formulario(null); });
    cargar();
})();

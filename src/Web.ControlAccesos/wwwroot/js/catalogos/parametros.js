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
        ATENCIONES_SIMULTANEAS_EMPRESA: ['Atenciones simultáneas por empresa (general)', 'Cuántas entregas puede atender a la vez una misma empresa, salvo que tenga su propio cupo abajo. Número de 1 a 99 o sin límite (por defecto 1).'],
        ATENCIONES_SIMULTANEAS_ALMACENERO: ['Solicitudes simultáneas por almacenero', 'Cuántas solicitudes puede tener a la vez un almacenero, desde que confirma la disponibilidad hasta que termina o detiene su atención. De 1 a 99 o sin límite (por defecto 1). Con «sin límite» se desactiva esta restricción.'],
        EXCLUSA_CAPACIDAD: ['Capacidad de la esclusa', 'Cuántos conductores (vehículos con placa) pueden estar dentro de la esclusa a la vez: un número de 1 a 99 o sin límite. Cuenta vehículos de todas las entregas: con 2 pueden estar dentro, a la vez, dos vehículos aunque sean de solicitudes distintas (también es el máximo de entregas con la esclusa reservada).'],
        INCIDENCIA_POST_SALIDA: ['Permitir incidencias a quien ya salió', 'Si Vigilancia puede registrar incidencias a personas que ya salieron del establecimiento. Por defecto No: el botón «Registrar incidencia» solo aparece mientras la persona está dentro. El Coordinador no se ve afectado.'],
        PLACA_OBLIGATORIA: ['Placa obligatoria', 'Si se exige la placa del vehículo de cada conductor al registrar la solicitud (Sí por ahora; se puede desactivar).'],
        PROVEEDOR_HORA_CORTE: ['Hora de corte del día de proveedores', 'A esta hora (HH:MM) se cierran las entregas del día anterior que quedaron abiertas.'],
        SOLICITUD_HORA_CORTE_VENCIMIENTO: ['Hora en que vence una solicitud sin decidir', 'Una solicitud que sigue pendiente u observada pasa a «Vencida» cuando termina el último día de la visita, a esta hora (HH:MM). Con 00:00 vence al empezar el día siguiente; con 06:00, a las 6 de la mañana del día siguiente.'],
        SOLICITUD_HORAS_ANTICIPACION_APROBAR: ['Horas de anticipación para aprobar', 'Horas mínimas, antes de la hora de la visita, en que todavía se puede aprobar una solicitud. Pasado ese límite la solicitud vence. Con 0 está APAGADO: se puede aprobar hasta el final del día de la visita (la regla actual).']
    };

    var PREF = 'CUPO_EMPRESA:';
    function esCupo(p) { return p.clave.indexOf(PREF) === 0; }
    function general() { var g = lista.filter(function (x) { return x.clave === 'ATENCIONES_SIMULTANEAS_EMPRESA'; })[0]; return g ? (g.valor === 'SIN_LIMITE' ? 'sin límite' : g.valor) : '1'; }
    // D-244: una fila de cupo por empresa; se muestra con el nombre de la empresa
    function nombreDe(p) {
        if (esCupo(p)) return ['Cupo de ' + (p.descripcion || p.clave.substring(PREF.length)), 'Cuántas entregas puede atender a la vez esta empresa. Es independiente de las demás: un número de 1 a 99, sin límite, o «general» para usar el valor general.'];
        return NOMBRE[p.clave] || [p.clave, p.descripcion || ''];
    }

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
            var n = nombreDe(p);
            cuerpoTabla.appendChild(el('tr', {}, [
                el('td', { class: 'stk' }, [el('b', { text: n[0] }), el('div', { class: 'small muted', text: n[1] || p.descripcion || '' })]),
                el('td', { text: mostrar(p) }),
                el('td', {}, [el('button', { type: 'button', class: 'btn btn-sm', text: 'Editar', onclick: function () { editar(p, n); } })])
            ]));
        });
    }

    // D-239: valores con formato propio se muestran en palabras
    function mostrar(p) {
        if (p.valor === 'SIN_LIMITE') return 'Sin límite';
        if (esCupo(p) && p.valor === 'GENERAL') return 'General (' + general() + ')';
        if (p.clave === 'PLACA_OBLIGATORIA') return p.valor === 'N' ? 'No' : 'Sí';
        if (p.clave === 'INCIDENCIA_POST_SALIDA') return p.valor === 'Y' ? 'Sí' : 'No';
        if (p.clave === 'SOLICITUD_HORAS_ANTICIPACION_APROBAR') return p.valor === '0' ? 'Apagado (0)' : p.valor + ' h antes de la visita';
        return p.valor === '' ? '—' : p.valor;
    }

    function editar(p, n) {
        var inp, leer, ctl;
        if (p.clave === 'PLACA_OBLIGATORIA') {
            inp = el('select', {}, [el('option', { value: 'Y', text: 'Sí, se exige' }), el('option', { value: 'N', text: 'No, es opcional' })]);
            inp.value = p.valor === 'N' ? 'N' : 'Y'; leer = function () { return inp.value; }; ctl = inp;
        } else if (p.clave === 'INCIDENCIA_POST_SALIDA') {
            inp = el('select', {}, [el('option', { value: 'N', text: 'No, solo mientras la persona está dentro' }), el('option', { value: 'Y', text: 'Sí, también a quien ya salió' })]);
            inp.value = p.valor === 'Y' ? 'Y' : 'N'; leer = function () { return inp.value; }; ctl = inp;
        } else if (p.clave === 'EXCLUSA_CAPACIDAD' || p.clave === 'ATENCIONES_SIMULTANEAS_EMPRESA' || p.clave === 'ATENCIONES_SIMULTANEAS_ALMACENERO' || esCupo(p)) {
            // número de 1 a 99, «sin límite» (desactiva el límite) y, solo en el cupo de una empresa, «usar el general»
            var gen = esCupo(p), numero = /^\d+$/.test(p.valor);
            inp = el('input', { type: 'number', min: '1', max: '99', step: '1', value: numero ? p.valor : '' });
            var sl = el('input', { type: 'checkbox' }); sl.checked = p.valor === 'SIN_LIMITE';
            var ge = gen ? el('input', { type: 'checkbox' }) : null; if (ge) ge.checked = p.valor === 'GENERAL';
            function sync() { inp.disabled = sl.checked || (ge && ge.checked); if (ge) sl.disabled = ge.checked; }
            sl.addEventListener('change', function () { if (sl.checked && ge) ge.checked = false; sync(); if (!inp.disabled) inp.focus(); });
            if (ge) ge.addEventListener('change', function () { if (ge.checked) sl.checked = false; sync(); });
            sync();
            leer = function () { return ge && ge.checked ? 'GENERAL' : sl.checked ? 'SIN_LIMITE' : inp.value; };
            ctl = el('div', { class: 'stack' }, [inp, el('label', {}, [sl, ' Sin límite (desactivar)'])].concat(ge ? [el('label', {}, [ge, ' Usar el valor general (' + general() + ')'])] : []));
        } else if (p.clave === 'SOLICITUD_HORAS_ANTICIPACION_APROBAR') {
            // 0 = apagado; de 1 a 999 horas antes de la hora de la visita
            inp = el('input', { type: 'number', min: '0', max: '999', step: '1', value: /^\d+$/.test(p.valor) ? p.valor : '0' });
            leer = function () { return inp.value; }; ctl = el('div', { class: 'stack' }, [inp, el('span', { class: 'field-h', text: '0 = apagado (no hay tiempo mínimo de anticipación).' })]);
        } else if (p.clave === 'SOLICITUD_HORA_CORTE_VENCIMIENTO') {
            inp = el('input', { type: 'time', value: p.valor }); leer = function () { return inp.value; }; ctl = inp;
        } else { inp = el('input', { type: 'text', maxlength: '200', value: p.valor }); leer = function () { return inp.value; }; ctl = inp; }
        var err = el('span', { class: 'field-e' });
        var env = false;
        CAF.modal('Parámetro · ' + n[0], el('div', { class: 'stack' }, [
            n[1] ? el('p', { class: 'field-h', text: n[1] }) : null,
            el('label', { class: 'field' }, [el('span', { class: 'field-l', text: 'Valor' }), ctl, err])
        ]), [
            { texto: 'Cancelar', onclick: function (c) { c(); } },
            { texto: 'Guardar', tipo: 'primary', onclick: function (c) {
                if (env) return; env = true; err.textContent = '';
                CAF.pedir(urlGuardar, { method: 'POST', body: { clave: p.clave, valor: leer() } }).then(function (r) {
                    env = false;
                    if (!r.success) { err.textContent = r.message || 'No se pudo guardar.'; return; }
                    CAF.aviso(r.message || 'Guardado.'); c(); cargar();
                });
            } }
        ]);
    }
    cargar();
})();

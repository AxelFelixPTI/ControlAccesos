// Mis solicitudes: contadores por estado, filtros y tabla con las acciones que cada solicitud permite.
(function () {
    'use strict';
    var raiz = document.getElementById('caf-mis');
    if (!raiz) return;
    var el = CAF.el;
    var url = { mis: raiz.dataset.urlMis, nueva: raiz.dataset.urlNueva, detalle: raiz.dataset.urlDetalle, cancelar: raiz.dataset.urlCancelar };
    var filas = [], estado = '';
    var cuerpo = document.getElementById('m-filas'), kpis = document.getElementById('m-kpis');
    var texto = document.getElementById('m-texto'), desde = document.getElementById('m-desde'), hasta = document.getElementById('m-hasta');
    var GRUPOS = [['', 'Todas'], ['PENDIENTE', 'Pendientes'], ['OBSERVADA', 'Observadas'], ['APROBADA', 'Aprobadas'], ['CANCELADA', 'Canceladas']];

    function verUrl(id) { return url.detalle.replace('__ID__', id); }
    function enGrupo(s, g) { return !g || s.estado === g || (g === 'APROBADA' && s.estado === 'APROBADA_PARCIAL'); }

    function pintarKpis() {
        kpis.textContent = '';
        GRUPOS.forEach(function (g) {
            var n = filas.filter(function (s) { return enGrupo(s, g[0]); }).length;
            kpis.appendChild(el('button', { type: 'button', class: 'kpi' + (estado === g[0] ? ' on' : ''), onclick: function () { estado = g[0]; pintar(); } },
                [el('b', { text: String(n) }), g[1]]));
        });
    }

    function personas(s) {
        var partes = [];
        if (s.autorizadas) partes.push(s.autorizadas + ' autorizada' + (s.autorizadas > 1 ? 's' : ''));
        if (s.pendientes) partes.push(s.pendientes + ' pendiente' + (s.pendientes > 1 ? 's' : ''));
        if (s.observadas) partes.push(s.observadas + ' observada' + (s.observadas > 1 ? 's' : ''));
        if (s.rechazadas) partes.push(s.rechazadas + ' rechazada' + (s.rechazadas > 1 ? 's' : ''));
        return el('div', {}, [el('div', { text: String(s.total) }), partes.length ? el('div', { class: 'field-h', text: partes.join(' · ') }) : null]);
    }

    function cancelar(s) {
        var motivo = el('textarea', { rows: '2', maxlength: '300', placeholder: 'Motivo (opcional)' });
        var cuerpoM = el('div', { class: 'stack' }, [
            el('p', { text: '¿Cancelar la solicitud ' + s.codigo + '? Sus invitados ya no podrán ingresar con ella.' }),
            s.autorizadas ? el('div', { class: 'aviso a-warn', text: 'Tiene ' + s.autorizadas + ' persona(s) ya autorizada(s): se les quitará la autorización.' }) : null,
            motivo, el('p', { class: 'field-e' })
        ]);
        var err = cuerpoM.lastChild;
        CAF.modal('Cancelar solicitud', cuerpoM, [
            { texto: 'Volver', onclick: function (c) { c(); } },
            {
                texto: 'Cancelar solicitud', tipo: 'primary', onclick: function (c) {
                    CAF.pedir(url.cancelar, { method: 'POST', body: { solicitudId: s.id, motivo: motivo.value } }).then(function (r) {
                        if (!r.success) { err.textContent = SOL.errores(r); return; }
                        c(); CAF.aviso('Solicitud cancelada.'); cargar();
                    });
                }
            }
        ]);
    }

    function pintar() {
        pintarKpis();
        var vistas = filas.filter(function (s) { return enGrupo(s, estado); });
        cuerpo.textContent = '';
        if (!vistas.length) { cuerpo.appendChild(el('tr', {}, [el('td', { colspan: '7', class: 'vacio', text: filas.length ? 'No hay solicitudes con ese filtro.' : 'Todavía no ha creado solicitudes.' })])); return; }
        vistas.forEach(function (s) {
            var acc = [el('a', { class: 'btn btn-sm', href: verUrl(s.id), text: 'Ver' })];
            if (s.puedeReutilizar) acc.push(el('a', { class: 'btn btn-sm', href: url.nueva + '?reutilizar=' + s.id, text: 'Reutilizar' }));
            if (s.puedeCancelar) acc.push(el('button', { type: 'button', class: 'btn btn-sm btn-danger-o', text: 'Cancelar', onclick: function () { cancelar(s); } }));
            cuerpo.appendChild(el('tr', { class: s.estado === 'CANCELADA' ? 'off' : '' }, [
                el('td', {}, [el('a', { class: 'link', href: verUrl(s.id), text: s.codigo }), s.codigoOrigen ? el('div', { class: 'field-h', text: 'de ' + s.codigoOrigen }) : null]),
                el('td', { text: SOL.fechaLarga(s.fecha) + ' · ' + s.hora }),
                el('td', { text: s.empresa || '' }),
                el('td', { text: s.responsable || '' }),
                el('td', {}, [personas(s)]),
                el('td', {}, [SOL.chipEstado(s.estado)]),
                el('td', {}, [el('div', { class: 'acc' }, acc)])
            ]));
        });
    }

    function cargar() {
        var q = '?texto=' + encodeURIComponent(texto.value.trim()) + '&desde=' + desde.value + '&hasta=' + hasta.value;
        return CAF.pedir(url.mis + q).then(function (r) {
            if (!r.success) { CAF.aviso(r.message || 'No se pudo cargar.', 'warn'); return; }
            filas = r.data; pintar();
        });
    }

    var t = null;
    texto.addEventListener('input', function () { clearTimeout(t); t = setTimeout(cargar, 300); });
    desde.addEventListener('change', cargar); hasta.addEventListener('change', cargar);
    cargar();
})();

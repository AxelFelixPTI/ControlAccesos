// Desviaciones (coordinador): lista Por revisar / Revisadas y ventana de revisión con conformidad.
(function () {
    'use strict';
    var raiz = document.getElementById('caf-desv');
    if (!raiz) return;
    var el = CAF.el, d = raiz.dataset;
    var estado = 'POR_REVISAR', texto = '', primera = true, porRevisar = 0, revisadas = 0, filas = [], secuencia = 0, temporizador = null;
    var cuerpo = document.getElementById('d-filas'), tabs = document.getElementById('d-tabs'), caja = document.getElementById('d-texto');
    var RESULTADO = {
        INGRESA: 'Ingresa', INGRESA_RESTRINGIDO: 'Ingresa restringido a la zona administrativa', NO_INGRESA: 'No ingresa',
        SALE: 'Sale', SALE_RETIENE_ELEMENTO: 'Sale y se retiene el elemento'
    };
    function fecha(f) { return SOL.fechaLarga(f); }
    function etapa(t) { return t === 'INGRESO' ? 'Ingreso' : 'Salida'; }

    function pintar() {
        tabs.textContent = '';
        [['POR_REVISAR', 'Por revisar (' + porRevisar + ')'], ['REVISADA', 'Revisadas (' + revisadas + ')']].forEach(function (t) {
            tabs.appendChild(el('button', { type: 'button', class: 'pill' + (estado === t[0] ? ' on' : ''), text: t[1], onclick: function () { estado = t[0]; cargar(); } }));
        });
        cuerpo.textContent = '';
        if (!filas.length) {
            cuerpo.appendChild(el('tr', {}, [el('td', { colspan: '7', class: 'vacio', text: texto ? 'Nada coincide con la búsqueda.' : (estado === 'POR_REVISAR' ? 'No hay desviaciones por revisar.' : 'Todavía no hay desviaciones revisadas.') })]));
            return;
        }
        filas.forEach(function (x) {
            cuerpo.appendChild(el('tr', {}, [
                el('td', {}, [el('button', { type: 'button', class: 'link', text: x.codigo, onclick: function () { revisar(x.id); } })]),
                el('td', { text: fecha(x.fecha) + ' ' + x.hora }),
                el('td', {}, [el('div', { text: x.persona }), el('div', { class: 'field-h', text: (x.doc || '') + ' · ' + x.solicitud + (x.empresa ? ' · ' + x.empresa : '') })]),
                el('td', { text: etapa(x.tipo) }),
                el('td', { class: 'field-h', text: x.descripcion }),
                el('td', {}, [el('div', { text: x.tratamiento || '' }), el('div', { class: 'field-h', text: RESULTADO[x.resultado] || x.resultado || '' })]),
                el('td', {}, [el('button', { type: 'button', class: 'btn btn-sm' + (x.estado === 'POR_REVISAR' ? ' btn-primary' : ''), text: x.estado === 'POR_REVISAR' ? 'Revisar' : 'Ver', onclick: function () { revisar(x.id); } })])
            ]));
        });
    }

    function cargar() {
        var mi = ++secuencia;
        return CAF.pedir(d.urlLista + '?estado=' + estado + '&texto=' + encodeURIComponent(texto)).then(function (r) {
            if (mi !== secuencia) return;
            if (!r.success) { CAF.aviso(r.message || 'No se pudo cargar.', 'warn'); return; }
            porRevisar = r.porRevisar; revisadas = r.revisadas; filas = r.data;
            if (primera) { primera = false; if (porRevisar === 0 && estado === 'POR_REVISAR' && revisadas > 0) { estado = 'REVISADA'; return cargar(); } }
            pintar();
        });
    }
    caja.addEventListener('input', function () { clearTimeout(temporizador); temporizador = setTimeout(function () { texto = caja.value.trim(); cargar(); }, 300); });

    function fila(dt, dd) { return [el('dt', { text: dt }), el('dd', { text: dd || '—' })]; }

    function revisar(id) {
        var cont = el('div', { class: 'stack' }, [el('p', { class: 'vacio', text: 'Cargando...' })]);
        var comentario = el('input', { type: 'text', maxlength: '500', autocomplete: 'off', placeholder: 'Comentario (opcional)' });
        var error = el('p', { class: 'err', hidden: true, role: 'alert' });
        var datos = null, enviando = false;
        CAF.modal('Desviación', cont, [
            { texto: 'Cerrar', onclick: function (c) { c(); } },
            { texto: 'Dar conformidad', tipo: 'primary', onclick: function (c) {
                if (!datos || !datos.puedeConformidad || enviando) return;
                enviando = true; error.hidden = true;
                CAF.pedir(d.urlConformidad, { method: 'POST', body: { id: id, comentario: comentario.value } }).then(function (r) {
                    enviando = false;
                    if (!r.success) { error.textContent = SOL.errores(r); error.hidden = false; return; }
                    c(); CAF.aviso(r.message || 'Conformidad registrada.'); cargar();
                });
            } }
        ], 'ancho');
        CAF.pedir(d.urlDetalle + '?id=' + id).then(function (r) {
            cont.textContent = '';
            if (!r.success) { cont.appendChild(el('p', { class: 'err', text: r.message || 'No se pudo cargar.' })); return; }
            var x = r.data; datos = x;
            var dl = el('dl', { class: 'dl' });
            [].concat(fila('Código', x.codigo), fila('Persona', x.persona + (x.doc ? ' (' + x.doc + ')' : '')), fila('Solicitud', x.solicitud + (x.empresa ? ' · ' + x.empresa : '')),
                fila('Momento', etapa(x.tipo) + ' · ' + fecha(x.fecha) + ' ' + x.hora + (x.registradoPor ? ' · registró ' + x.registradoPor : '')),
                fila('Descripción', x.descripcion), fila('Consultado', x.consultado),
                fila('Decisión', (x.tratamiento || '') + (x.tratamientoDetalle ? ': ' + x.tratamientoDetalle : '') + ' → ' + (RESULTADO[x.resultado] || x.resultado || '')))
                .forEach(function (n) { dl.appendChild(n); });
            if (x.estado === 'REVISADA') fila('Conformidad', (x.conformidadPor || '') + ' · ' + (x.fechaConformidad || '') + (x.comentario ? ' · ' + x.comentario : '')).forEach(function (n) { dl.appendChild(n); });
            if (x.incidencia) fila('Incidencia', 'Esta desviación originó una incidencia.').forEach(function (n) { dl.appendChild(n); });
            cont.appendChild(dl);
            cont.appendChild(el('h4', { text: 'Checklist del ' + (x.tipo === 'INGRESO' ? 'ingreso' : 'salida') }));
            var ul = el('ul', { class: 'checks' });
            x.items.forEach(function (i) { ul.appendChild(el('li', { class: i.cumple ? 'ok' : 'no', text: (i.cumple ? '✓ ' : '✗ ') + i.texto })); });
            cont.appendChild(ul);
            if (x.estado === 'POR_REVISAR') {
                if (x.puedeConformidad) cont.appendChild(SOL.campo('Comentario (opcional)', comentario));
                else cont.appendChild(el('div', { class: 'aviso a-warn', text: x.motivoNoConformidad || 'No puede dar conformidad a esta desviación.' }));
                cont.appendChild(error);
            }
        });
    }

    cargar();
})();

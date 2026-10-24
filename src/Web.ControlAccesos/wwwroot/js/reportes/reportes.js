// Reporte de accesos (coordinador): lista de movimientos con filtros, resumen del rango, exportar a CSV e imprimir.
(function () {
    'use strict';
    var raiz = document.getElementById('caf-rep');
    if (!raiz) return;
    var el = CAF.el, d = raiz.dataset;
    var RESULTADO = {
        INGRESA: ['Ingresa', 'c-ok'], INGRESA_RESTRINGIDO: ['Ingresa restringido a la zona administrativa', 'c-obs'], NO_INGRESA: ['No ingresa', 'c-rec'],
        SALE: ['Sale', 'c-ok'], SALE_RETIENE_ELEMENTO: ['Sale y se retiene el elemento', 'c-obs']
    };
    var f = { desde: document.getElementById('r-desde'), hasta: document.getElementById('r-hasta'), texto: document.getElementById('r-texto'),
              tipo: document.getElementById('r-tipo'), desv: document.getElementById('r-desv') };
    var cuerpo = document.getElementById('r-filas'), cuenta = document.getElementById('r-cuenta'), resumen = document.getElementById('r-resumen'), aviso = document.getElementById('r-aviso');
    var secuencia = 0, temporizador = null;

    function iso(dt) { return dt.getFullYear() + '-' + String(dt.getMonth() + 1).padStart(2, '0') + '-' + String(dt.getDate()).padStart(2, '0'); }
    var hoy = new Date(), ini = new Date(); ini.setDate(ini.getDate() - 6);
    f.desde.value = iso(ini); f.hasta.value = iso(hoy);

    function consulta() {
        return '?desde=' + encodeURIComponent(f.desde.value) + '&hasta=' + encodeURIComponent(f.hasta.value) + '&texto=' + encodeURIComponent(f.texto.value.trim()) +
               '&tipo=' + encodeURIComponent(f.tipo.value) + '&soloDesviacion=' + (f.desv.checked ? 'true' : 'false');
    }

    function vacio(msg) { cuerpo.textContent = ''; cuerpo.appendChild(el('tr', {}, [el('td', { colspan: '9', class: 'vacio', text: msg })])); }

    function pintar(r) {
        resumen.textContent = '';
        var s = r.resumen;
        [['Ingresos', s.ingresos, 'c-ok'], ['Restringidos', s.restringidos, 'c-obs'], ['Denegados', s.denegados, 'c-rec'], ['Salidas', s.salidas, 'c-line'],
         ['Desviaciones', s.desviaciones, 'c-obs'], ['Incidencias', s.incidencias, 'c-pend']].forEach(function (x) {
            resumen.appendChild(el('span', { class: 'chip ' + x[2], text: x[0] + ' ' + x[1] }));
        });
        cuenta.textContent = r.total === 1 ? '1 movimiento' : r.total + ' movimientos';
        aviso.hidden = !r.truncado;
        if (r.truncado) aviso.textContent = 'Se muestran los primeros 1000 movimientos. Acote las fechas o exporte para ver todos.';
        if (!r.data.length) { vacio('No hay movimientos con esos filtros.'); return; }
        cuerpo.textContent = '';
        r.data.forEach(function (x) {
            var res = RESULTADO[x.resultado] || [x.resultado, 'c-line'];
            cuerpo.appendChild(el('tr', {}, [
                el('td', {}, [el('div', { text: SOL.fechaLarga(x.fecha) + ' ' + x.hora }), x.tardio ? el('div', { class: 'field-h', text: 'tardío' }) : null]),
                el('td', { text: x.tipo === 'INGRESO' ? 'Ingreso' : 'Salida' }),
                el('td', { text: x.persona }),
                el('td', { text: x.doc || '—' }),
                el('td', { text: x.empresa || '—' }),
                el('td', { text: x.solicitud }),
                el('td', {}, [el('span', { class: 'chip ' + res[1], text: res[0] })]),
                el('td', { text: x.vigilante || '—' }),
                el('td', { text: x.desviacion ? x.desviacion + (x.incumplidos ? ' (' + x.incumplidos + ' ítem' + (x.incumplidos === 1 ? '' : 's') + ')' : '') : '—' })
            ].filter(Boolean)));
        });
    }

    function cargar() {
        var mi = ++secuencia;
        return CAF.pedir(d.urlLista + consulta()).then(function (r) {
            if (mi !== secuencia) return;
            if (!r.success) { resumen.textContent = ''; cuenta.textContent = ''; aviso.hidden = true; vacio(r.message || 'No se pudo cargar.'); return; }
            pintar(r);
        });
    }

    f.texto.addEventListener('input', function () { clearTimeout(temporizador); temporizador = setTimeout(cargar, 300); });
    [f.desde, f.hasta, f.tipo, f.desv].forEach(function (c) { c.addEventListener('change', cargar); });
    document.getElementById('r-exportar').addEventListener('click', function () {
        if (!f.desde.value || !f.hasta.value) { CAF.aviso('Indique las fechas «Desde» y «Hasta».', 'warn'); return; }
        window.location.href = d.urlExportar + consulta();
    });
    document.getElementById('r-imprimir').addEventListener('click', function () { window.print(); });
    cargar();
})();

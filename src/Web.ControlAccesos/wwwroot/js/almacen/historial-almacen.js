// D-273/D-274. «Historial de Almacén»: listado de atenciones de Almacén en entregas de proveedores, con filtros, exportar a CSV e imprimir.
(function () {
    'use strict';
    var raiz = document.getElementById('caf-hist');
    if (!raiz) return;
    var el = CAF.el, d = raiz.dataset;
    var ESTADO = { PENDIENTE: ['Pendiente', 'c-pend'], EN_ATENCION: ['En atención', 'c-obs'], DETENIDA: ['Detenida', 'c-obs'], ATENDIDA: ['Atendida', 'c-ok'], CERRADA_SIN_ATENCION: ['Cerrada sin atención', 'c-rec'] };
    var f = { desde: document.getElementById('h-desde'), hasta: document.getElementById('h-hasta'), texto: document.getElementById('h-texto'),
              empresa: document.getElementById('h-empresa'), estado: document.getElementById('h-estado'), vehiculo: document.getElementById('h-vehiculo') };
    var cuerpo = document.getElementById('h-filas'), cuenta = document.getElementById('h-cuenta');
    var secuencia = 0, temporizador = null;

    function iso(dt) { return dt.getFullYear() + '-' + String(dt.getMonth() + 1).padStart(2, '0') + '-' + String(dt.getDate()).padStart(2, '0'); }
    var hoy = new Date(), ini = new Date(); ini.setDate(ini.getDate() - 30);
    f.desde.value = iso(ini); f.hasta.value = iso(hoy);

    function consulta() {
        return '?desde=' + encodeURIComponent(f.desde.value) + '&hasta=' + encodeURIComponent(f.hasta.value) + '&texto=' + encodeURIComponent(f.texto.value.trim()) +
               '&empresa=' + encodeURIComponent(f.empresa.value) + '&estado=' + encodeURIComponent(f.estado.value) + '&vehiculo=' + encodeURIComponent(f.vehiculo.value);
    }
    function dur(m) { if (m === null || m === undefined) return '—'; var h = Math.floor(m / 60), r = m % 60; return h ? h + ' h ' + String(r).padStart(2, '0') + ' min' : r + ' min'; }
    function hora(s) { return s ? s.substring(11) : ''; }
    function fechaHora(s) { return s ? SOL.fechaLarga(s.substring(0, 10)) + ' ' + s.substring(11) : ''; }
    function vacio(msg) { cuerpo.textContent = ''; cuerpo.appendChild(el('tr', {}, [el('td', { colspan: '9', class: 'vacio', text: msg })])); }

    var ENTREGA = { PROGRAMADO: ['Programado', 'c-line'], EN_ESPERA: ['En espera', 'c-pend'], INGRESO: ['Ingresó', 'c-obs'], EN_ATENCION: ['En atención', 'c-obs'], RECEPCIONADO: ['Recepción culminada', 'c-ok'],
                    SALIO: ['Salió', 'c-ok'], CIERRE_FORZADO: ['Cierre forzado', 'c-rec'], NO_SE_PRESENTO: ['No se presentó', 'c-rec'] };
    function sub(t, cls) { return el('div', { class: cls || 'ha-sub', text: t }); }
    function mismoDia(a, b) { return a && b && a.substring(0, 10) === b.substring(0, 10); }
    // Hora «HH:mm»; con el día cuando no es el de la entrega.
    function horaDia(s, dia) { return s ? (mismoDia(s, dia) ? hora(s) : SOL.fechaLarga(s.substring(0, 10)) + ' ' + hora(s)) : ''; }

    // Lo que se muestra cuando Almacén no llegó a atender: nunca un guion, siempre el motivo según cómo terminó la entrega.
    function sinAtencion(x) {
        var cerro = x.estadoEntrega === 'SALIO' || x.estadoEntrega === 'CIERRE_FORZADO' || x.estadoEntrega === 'RECEPCIONADO';
        if (x.estadoEntrega === 'NO_SE_PRESENTO') return ['No se presentó', 'El proveedor no llegó a la entrega.'];
        if (x.estado === 'CERRADA_SIN_ATENCION') return ['Cerrada sin atención', x.motivoSin || 'Almacén cerró esta empresa sin atenderla.'];
        if (cerro) return ['Sin atención de Almacén', 'La entrega terminó sin que Almacén atendiera a esta empresa' + (x.disponibilidad ? ' (la disponibilidad sí se confirmó).' : '.')];
        if (x.estadoEntrega === 'INGRESO') return ['Aún sin iniciar', 'El vehículo ya está en planta; falta que Almacén inicie la atención.'];
        if (x.estadoEntrega === 'EN_ESPERA') return ['Aún sin iniciar', x.disponibilidad ? 'Almacén confirmó disponibilidad; falta el ingreso.' : 'Esperando que Almacén confirme disponibilidad.'];
        return ['Aún sin iniciar', 'La entrega está programada y todavía no llega.'];
    }

    function desvioTexto(x) {
        if (x.desvio === null || x.desvio === undefined) return null;
        var m = Math.abs(x.desvio);
        if (m <= 5) return ['Inició a la hora programada', 'ha-ok'];
        return ['Inició ' + dur(m) + (x.desvio > 0 ? ' después' : ' antes') + ' de la hora programada', x.desvio > 0 ? 'ha-pausa' : 'ha-sub'];
    }

    function pintar(r) {
        cuenta.textContent = r.total === 1 ? '1 atención' : r.total + ' atenciones' + (r.total >= 500 ? ' (se muestran las 500 más recientes; acote las fechas o filtre)' : '');
        if (!r.data.length) { vacio('No hay atenciones con esos filtros.'); return; }
        cuerpo.textContent = '';
        r.data.forEach(function (x) {
            var est = ESTADO[x.estado] || [x.estado, 'c-line'];
            var ent = ENTREGA[x.estadoEntrega] || [x.estadoEntrega || 'Sin estado', 'c-line'];
            var si = x.inicio ? null : sinAtencion(x);
            var conIngreso = x.conVehiculo === 'Y' ? 'Con ingreso vehicular' : x.conVehiculo === 'N' ? 'Sin ingreso vehicular' : 'Ingreso vehicular sin definir';
            var marcas = [x.llegada ? 'Llegó ' + hora(x.llegada) : null, x.ingreso ? 'Ingresó ' + hora(x.ingreso) : null, x.salida ? 'Salió ' + hora(x.salida) : null].filter(Boolean).join(' · ');

            // Franja programada: la fecha una sola vez, aquí.
            var franja = [el('div', { text: SOL.fechaLarga(x.fecha) }), sub(x.horaHasta ? x.horaDesde + ' – ' + x.horaHasta : 'Desde ' + x.horaDesde)];

            // Atención de Almacén: hora real de inicio y fin, y cuánto se desvió de la franja.
            var atencion;
            if (x.inicio) {
                var dv = desvioTexto(x);
                atencion = [el('div', { text: hora(x.inicio) + ' – ' + (x.fin ? horaDia(x.fin, x.inicio) : 'sin terminar') }),
                            mismoDia(x.inicio, x.fecha + ' 00:00') ? null : sub(SOL.fechaLarga(x.inicio.substring(0, 10))),
                            dv ? sub(dv[0], dv[1]) : null, x.fueraFranja ? el('span', { class: 'chip c-rec', text: 'Fuera de la franja' }) : null];
            } else atencion = [el('div', { text: si[0] }), sub(si[1])];

            // Quién atendió: el nombre; sin inicio, quién confirmó la disponibilidad o por qué no hubo atención.
            var atendio;
            if (x.inicioPor) atendio = [el('div', { text: x.inicioPor }), x.finPor && x.finPor !== x.inicioPor ? sub('Terminó: ' + x.finPor) : null, x.reservo && x.reservo !== x.inicioPor ? sub('Disponibilidad: ' + x.reservo) : null];
            else if (x.estado === 'ATENDIDA') atendio = [el('div', { text: 'No quedó registrado' }), x.reservo ? sub('Disponibilidad: ' + x.reservo) : null];
            else atendio = [el('div', { text: 'Sin atender' }), sub(x.reservo ? 'Disponibilidad confirmada por ' + x.reservo : 'Disponibilidad sin confirmar')];

            var tiempo = x.inicio ? [el('div', { text: dur(x.minutosActivos) }), x.pausas ? el('div', { class: 'ha-pausa', text: x.pausas + (x.pausas === 1 ? ' pausa' : ' pausas') + ' · ' + dur(x.minutosPausa) }) : sub('sin pausas')]
                                  : [el('div', { text: 'Sin iniciar' }), sub('0 min')];
            var res = x.estado === 'CERRADA_SIN_ATENCION' ? (x.motivoSin || 'Sin atención') : x.resultado === 'CONFORME' ? 'Conforme' : x.resultado === 'CON_OBSERVACION' ? 'Con observación' : '';

            var oc = x.oc ? x.oc.split(/[;,]\s*/).filter(Boolean) : [];
            cuerpo.appendChild(el('tr', {}, [
                el('td', {}, [el('div', {}, [el('a', { href: d.urlSolicitud + '?id=' + x.solicitud, text: x.codigo })]), el('div', { class: 'ha-oc', text: oc.length ? 'OC: ' + oc.join(', ') : 'OC no indicada' }), sub('Solicita: ' + (x.solicitante || 'no registrado'))]),
                el('td', {}, [el('div', { text: x.proveedor }), sub('Placa: ' + (x.placa || 'no indicada') + ' · Conductor: ' + (x.conductor || 'no registrado')), x.transportista ? sub('Transporta: ' + x.transportista) : null].filter(Boolean)),
                el('td', {}, [el('div', { text: x.empresaCodigo }), sub(x.empresa)]),
                el('td', {}, franja),
                el('td', {}, atencion.filter(Boolean)),
                el('td', {}, atendio.filter(Boolean)),
                el('td', {}, tiempo),
                el('td', {}, [el('span', { class: 'chip ' + ent[1], text: ent[0] }), sub(conIngreso), marcas ? sub(marcas) : null].filter(Boolean)),
                el('td', {}, [el('span', { class: 'chip ' + est[1], text: est[0] }), res ? sub(res + (x.observacion && x.estado !== 'CERRADA_SIN_ATENCION' ? ' — ' + x.observacion : '')) : null].filter(Boolean))
            ]));
        });
    }

    function cargar() {
        var mi = ++secuencia;
        return CAF.pedir(d.urlLista + consulta()).then(function (r) {
            if (mi !== secuencia) return;
            if (!r.success) { cuenta.textContent = ''; vacio(r.message || 'No se pudo cargar.'); return; }
            pintar(r);
        });
    }

    f.texto.addEventListener('input', function () { clearTimeout(temporizador); temporizador = setTimeout(cargar, 300); });
    [f.desde, f.hasta, f.empresa, f.estado, f.vehiculo].forEach(function (c) { c.addEventListener('change', cargar); });
    // La descarga se pide con fetch y se entrega como archivo: la pestaña nunca navega y un error se muestra como aviso (igual que en «Reporte de accesos»).
    var btn = document.getElementById('h-exportar'), exportando = false;
    btn.addEventListener('click', function () {
        if (exportando) return;
        if (!f.desde.value || !f.hasta.value) { CAF.aviso('Indique las fechas «Desde» y «Hasta».', 'warn'); return; }
        exportando = true; btn.disabled = true;
        function fin() { exportando = false; btn.disabled = false; }
        fetch(d.urlExportar + consulta(), { credentials: 'same-origin', headers: { 'X-Requested-With': 'XMLHttpRequest' } }).then(function (resp) {
            if (!resp.ok) return resp.text().then(function (t) { throw new Error(t && t.length < 300 ? t : 'No se pudo exportar.'); });
            var m = /filename\*?=(?:UTF-8'')?"?([^";]+)"?/i.exec(resp.headers.get('Content-Disposition') || '');
            var nombre = m ? decodeURIComponent(m[1]) : 'historial_almacen.csv';
            return resp.blob().then(function (blob) {
                var url = URL.createObjectURL(blob), a = document.createElement('a');
                a.href = url; a.download = nombre; document.body.appendChild(a); a.click(); document.body.removeChild(a);
                setTimeout(function () { URL.revokeObjectURL(url); }, 2000);
                CAF.aviso('Archivo generado: ' + nombre);
            });
        }).catch(function (e) { CAF.aviso(e.message || 'No se pudo exportar.', 'warn'); }).then(fin);
    });
    document.getElementById('h-imprimir').addEventListener('click', function () { window.print(); });
    cargar();
})();

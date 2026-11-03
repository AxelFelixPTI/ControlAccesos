// Calendario de entregas de proveedores. Semana: tarjetas completas con sus acciones. Mes: conteo por día (un clic abre esa semana).
// Todos los que tienen el permiso del dashboard lo ven; solo Almacén tiene botones. Cada acción la vuelve a validar la base de datos
// (estado, día, esclusa única), así que aquí solo se decide qué botón mostrar y se refresca el estado.
(function () {
    'use strict';
    var raiz = document.getElementById('caf-prov');
    if (!raiz) return;
    var el = CAF.el, d = raiz.dataset, almacen = d.puedeAlmacen === 'Y';
    var vista = 'SEMANA', ancla = lunes(new Date()), anclado = false, hoy = null, datos = [], exclusa = null, cargado = { desde: '', hasta: '' }, secuencia = 0;
    var cal = document.getElementById('pv-cal'), titulo = document.getElementById('pv-titulo'), hora = document.getElementById('pv-hora');
    var avExc = document.getElementById('pv-exclusa');

    var DIAS = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
    var MESES = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'];
    var ESTADO = {
        PROGRAMADO: ['Programado', 'c-pend', ''], EN_ESPERA: ['Llegó, pendiente de ingreso', 'c-obs', 's-esp'], INGRESO: ['En espera de atención', 'c-obs', 's-esp'],
        EN_ATENCION: ['En atención', 'c-ok', 's-ok'], RECEPCIONADO: ['Recepción culminada', 'c-par', 's-fin'], SALIO: ['Salió', 'c-line', 's-fin'], NO_SE_PRESENTO: ['No se presentó', 'c-can', 's-no']
    };

    // ── fechas (texto yyyy-MM-dd; el «hoy» lo manda el servidor) ─────────────────────────────
    function aFecha(t) { var p = t.split('-'); return new Date(+p[0], +p[1] - 1, +p[2]); }
    function aTexto(f) { function z(n) { return (n < 10 ? '0' : '') + n; } return f.getFullYear() + '-' + z(f.getMonth() + 1) + '-' + z(f.getDate()); }
    function sumar(f, n) { var r = new Date(f.getFullYear(), f.getMonth(), f.getDate() + n); return r; }
    function lunes(f) { return sumar(f, -((f.getDay() + 6) % 7)); }
    function rangoVisible() {
        var primero = new Date(ancla.getFullYear(), ancla.getMonth(), 1), ultimo = new Date(ancla.getFullYear(), ancla.getMonth() + 1, 0);
        return { desde: aTexto(lunes(primero)), hasta: aTexto(sumar(lunes(ultimo), 6)) };
    }

    // ── datos ────────────────────────────────────────────────────────────────────────────────
    function cargar(silencioso) {
        var mi = ++secuencia, r = rangoVisible();
        return CAF.pedir(d.urlDatos + '?desde=' + r.desde + '&hasta=' + r.hasta).then(function (res) {
            if (mi !== secuencia) return;
            if (!res.success) { if (!silencioso) CAF.aviso(res.message || 'No se pudo cargar el calendario.', 'warn'); return; }
            hoy = res.hoy; datos = res.data || []; exclusa = res.exclusa; cargado = r;
            if (!anclado) {
                // Primera carga: el «hoy» es el del servidor. Si cambia el rango visible, se vuelve a pedir.
                anclado = true; ancla = vista === 'MES' ? aFecha(hoy) : lunes(aFecha(hoy));
                var rr = rangoVisible();
                if (rr.desde !== r.desde || rr.hasta !== r.hasta) return cargar(true);
            }
            hora.textContent = 'Actualizado a las ' + res.ahora;
            pintar();
        });
    }

    function navegar(paso) {
        if (!ancla) return;
        ancla = vista === 'SEMANA' ? sumar(ancla, 7 * paso) : new Date(ancla.getFullYear(), ancla.getMonth() + paso, 1);
        var r = rangoVisible();
        if (r.desde !== cargado.desde || r.hasta !== cargado.hasta) cargar(); else pintar();
    }

    function irHoy() { ancla = vista === 'SEMANA' ? lunes(aFecha(hoy)) : aFecha(hoy); cargar(); }

    // ── pintado ──────────────────────────────────────────────────────────────────────────────
    function pintarVistas() {
        var c = document.getElementById('pv-vistas'); c.textContent = '';
        [['SEMANA', 'Semana'], ['MES', 'Mes']].forEach(function (v) {
            c.appendChild(el('button', { type: 'button', class: v[0] === vista ? 'on' : '', text: v[1], onclick: function () { cambiarVista(v[0]); } }));
        });
    }

    function cambiarVista(v) {
        if (v === vista) return;
        vista = v; ancla = vista === 'SEMANA' ? lunes(ancla || aFecha(hoy)) : new Date((ancla || aFecha(hoy)).getFullYear(), (ancla || aFecha(hoy)).getMonth(), 1);
        pintarVistas(); cargar();
    }

    function pintarExclusa() {
        avExc.textContent = '';
        if (exclusa && exclusa.ocupada) {
            avExc.className = 'aviso pv-exc-on';
            avExc.appendChild(el('span', {}, [el('b', { text: 'Atención en curso en la esclusa: ' }),
                (exclusa.empresa || '') + (exclusa.codigo ? ' (' + exclusa.codigo + ')' : '') + (exclusa.desde ? ' desde las ' + exclusa.desde : '') + (exclusa.atiende ? ', atiende ' + exclusa.atiende : '') +
                '. No se puede iniciar otra atención hasta que se termine.']));
        } else {
            avExc.className = 'aviso pv-exc-off';
            avExc.appendChild(el('span', {}, [el('b', { text: 'Esclusa libre. ' }), 'No hay ninguna atención en curso.']));
        }
    }

    function pintar() {
        pintarVistas(); pintarExclusa();
        cal.textContent = '';
        if (vista === 'SEMANA') pintarSemana(); else pintarMes();
    }

    function delDia(texto) { return datos.filter(function (e) { return e.fecha === texto; }); }

    function pintarSemana() {
        var fin = sumar(ancla, 6);
        titulo.textContent = ancla.getDate() + ' ' + MESES[ancla.getMonth()].slice(0, 3) + ' – ' + fin.getDate() + ' ' + MESES[fin.getMonth()].slice(0, 3) + ' ' + fin.getFullYear();
        var cont = el('div', { class: 'pv-semana' });
        for (var i = 0; i < 7; i++) {
            var f = sumar(ancla, i), t = aTexto(f), lista = delDia(t);
            var col = el('section', { class: 'pv-dia' + (t === hoy ? ' hoy' : ''), 'aria-label': DIAS[i] + ' ' + f.getDate() }, [
                el('div', { class: 'pv-dia-h' }, [el('span', { text: DIAS[i] + ' ' + f.getDate() }), el('small', { text: lista.length ? lista.length + (lista.length === 1 ? ' entrega' : ' entregas') : '' })])
            ]);
            if (!lista.length) col.appendChild(el('div', { class: 'pv-vacio', text: 'Sin entregas' }));
            else { var rejilla = el('div', { class: 'pv-rejilla' }); lista.forEach(function (e) { rejilla.appendChild(tarjeta(e)); }); col.appendChild(rejilla); }
            cont.appendChild(col);
        }
        cal.appendChild(cont);
    }

    function pintarMes() {
        titulo.textContent = MESES[ancla.getMonth()] + ' ' + ancla.getFullYear();
        var cont = el('div', { class: 'pv-mes' }), r = rangoVisible(), f = aFecha(r.desde), fin = aFecha(r.hasta);
        DIAS.forEach(function (n) { cont.appendChild(el('div', { class: 'pv-mes-dow', text: n })); });
        for (; f <= fin; f = sumar(f, 1)) {
            (function (dia) {
                var t = aTexto(dia), lista = delDia(t);
                var celda = el('button', { type: 'button', class: 'pv-celda' + (dia.getMonth() !== ancla.getMonth() ? ' fuera' : '') + (t === hoy ? ' hoy' : ''), 'aria-label': dia.getDate() + ' de ' + MESES[dia.getMonth()] + ': ' + lista.length + ' entregas',
                    onclick: function () { vista = 'SEMANA'; ancla = lunes(dia); var rr = rangoVisible(); if (rr.desde !== cargado.desde) cargar(); else pintar(); } },
                    [el('span', { class: 'pv-celda-n', text: String(dia.getDate()) })]);
                lista.slice(0, 3).forEach(function (e) {
                    celda.appendChild(el('span', { class: 'pv-mini' }, [el('span', { class: 'pv-punto ' + (ESTADO[e.estado] ? ESTADO[e.estado][2] : '') }), el('span', { text: e.hora + ' ' + e.empresa })]));
                });
                if (lista.length > 3) celda.appendChild(el('span', { class: 'pv-mas', text: '+' + (lista.length - 3) + ' más' }));
                cont.appendChild(celda);
            })(f);
        }
        cal.appendChild(cont);
    }

    function tarjeta(e) {
        var est = ESTADO[e.estado] || [e.estado, 'c-pend', ''];
        var c = el('article', { class: 'pv-card' + (e.estado === 'EN_ATENCION' ? ' e-atencion' : '') }, [
            el('div', { class: 'pv-card-h' }, [el('b', { text: e.empresa }), el('span', { class: 'pv-hora', text: e.hora })]),
            el('div', {}, [el('span', { class: 'chip ' + est[1], text: est[0] })])
        ]);
        function linea(rotulo, valor) { if (valor) c.appendChild(el('div', { class: 'pv-linea' }, [el('b', { text: rotulo + ' ' }), valor])); }
        linea('Transportista:', e.transportista + (e.telefono ? ' · ' + e.telefono : '') + (e.apoyo ? ' (+' + e.apoyo + ' apoyo)' : ''));
        linea('Vehículo:', [e.placa, e.marca].filter(Boolean).join(' · '));
        linea('Recibe:', e.destino);
        linea('RUC:', e.ruc);
        linea('Nota:', e.observaciones);
        c.appendChild(el('div', { class: 'pv-resp' }, [
            el('div', { class: 'pv-linea' }, [el('b', { text: 'Responsable programado: ' }), e.programado || 'Sin asignar']),
            e.efectivo ? el('div', { class: 'pv-linea' }, [el('b', { text: 'Atiende: ' }), e.efectivo]) : null
        ]));
        var tiempos = [];
        if (e.llegada) tiempos.push('Llegó ' + e.llegada); if (e.ingreso) tiempos.push('Ingresó ' + e.ingreso);
        if (e.inicio) tiempos.push('Atención ' + e.inicio); if (e.recepcion) tiempos.push('Culminó ' + e.recepcion);
        if (e.salida) tiempos.push('Salió ' + e.salida);
        if (e.resultado === 'CON_OBSERVACION') tiempos.push('Con observación');
        if (tiempos.length) c.appendChild(el('div', { class: 'pv-tiempos', text: tiempos.join(' · ') }));
        var acc = acciones(e);
        if (acc) c.appendChild(acc);
        return c;
    }

    function acciones(e) {
        if (!almacen) return null;
        var caja = el('div', { class: 'pv-acc' }), hay = false;
        if (e.puedeProgramar) { hay = true; caja.appendChild(el('button', { type: 'button', class: 'btn btn-sm', text: e.programadoId ? 'Cambiar responsable' : 'Asignar responsable', onclick: function () { modalAsignar(e); } })); }
        if (e.estado === 'EN_ATENCION') {
            if (e.puedeTerminar) { hay = true; caja.appendChild(el('button', { type: 'button', class: 'btn btn-sm btn-primary', text: 'Terminar atención', onclick: function () { modalTerminar(e); } })); }
        } else if (e.estado === 'PROGRAMADO' || e.estado === 'EN_ESPERA' || e.estado === 'INGRESO') {
            hay = true;
            var b = el('button', { type: 'button', class: 'btn btn-sm btn-primary' + (e.puedeAtender ? '' : ' is-off'), text: 'Atender' });
            if (e.puedeAtender) b.addEventListener('click', function () { modalAtender(e); });
            else { b.disabled = true; var m = motivo(e); b.title = m; }
            caja.appendChild(b);
            if (!e.puedeAtender) caja.appendChild(el('div', { class: 'pv-motivo', text: motivo(e) }));
        }
        return hay ? caja : null;
    }

    function motivo(e) {
        if (e.motivoNoAtender) return e.motivoNoAtender;
        if (e.estado === 'PROGRAMADO') return 'Vigilancia aún no registra la llegada ni el ingreso.';
        if (e.estado === 'EN_ESPERA') return 'Vigilancia aún no registra el ingreso del proveedor.';
        return 'No disponible por ahora.';
    }

    // ── acciones ─────────────────────────────────────────────────────────────────────────────
    function enviar(url, cuerpo, boton, cerrar) {
        boton.disabled = true;
        return CAF.pedir(url, { method: 'POST', body: cuerpo }).then(function (r) {
            boton.disabled = false;
            if (r.success) { CAF.aviso(r.message || 'Listo.'); cerrar(); } else { CAF.aviso(r.message || 'No se pudo completar la acción.', 'warn'); if (/ya|otra|aún|no está|no tiene/i.test(r.message || '')) cerrar(); }
            return cargar(true);
        });
    }

    function botonDe(ev) { return ev && ev.currentTarget ? ev.currentTarget : { disabled: false }; }

    function modalAtender(e) {
        var cuerpo = el('p', { class: 'pv-modal-p' }, ['¿Confirmas que deseas iniciar la atención de este proveedor? Esta acción registrará tu usuario como responsable efectivo de la atención y bloqueará el inicio de otras atenciones hasta que finalices la actual.']);
        var env = false;
        CAF.modal('Iniciar atención · ' + e.empresa, cuerpo, [
            { texto: 'Cancelar', onclick: function (cerrar) { cerrar(); } },
            { texto: 'Confirmar atención', tipo: 'primary', onclick: function (cerrar) { if (env) return; env = true; enviar(d.urlAtender, { solicitudId: e.id }, { disabled: false }, cerrar).then(function () { env = false; }); } }
        ]);
    }

    function modalTerminar(e) {
        var obs = el('textarea', { rows: '3', maxlength: '1000', placeholder: 'Ej.: faltaron 2 cajas' });
        var cuerpo = el('div', { class: 'stack' }, [
            el('p', { class: 'pv-modal-p', text: '¿Confirmas que la atención de este proveedor ha culminado? Al confirmar, se habilitará a Vigilancia la opción de registrar su salida.' }),
            el('label', { class: 'field' }, [el('span', { class: 'field-l', text: 'Observación de la recepción (opcional)' }), obs, el('span', { class: 'field-h', text: 'Si la deja vacía, la recepción queda como conforme.' })])
        ]);
        var env = false;
        CAF.modal('Terminar atención · ' + e.empresa, cuerpo, [
            { texto: 'Cancelar', onclick: function (cerrar) { cerrar(); } },
            { texto: 'Confirmar culminación', tipo: 'primary', onclick: function (cerrar) { if (env) return; env = true; enviar(d.urlTerminar, { solicitudId: e.id, observacion: obs.value }, { disabled: false }, cerrar).then(function () { env = false; }); } }
        ]);
    }

    function modalAsignar(e) {
        var sel = el('select', {}, [el('option', { value: '', text: 'Cargando…' })]);
        var cuerpo = el('div', { class: 'stack' }, [
            el('label', { class: 'field' }, [el('span', { class: 'field-l', text: 'Responsable de atención programado' }), sel,
                el('span', { class: 'field-h', text: 'Es informativo: cualquier trabajador de Almacén autorizado puede atender, esté o no asignado.' })])
        ]);
        var listo = false, env = false;
        CAF.pedir(d.urlResponsables).then(function (r) {
            sel.textContent = '';
            sel.appendChild(el('option', { value: '', text: '— Sin responsable programado —' }));
            if (!r.success) { CAF.aviso(r.message || 'No se pudo cargar al personal de Almacén.', 'warn'); return; }
            (r.data || []).forEach(function (p) {
                var o = el('option', { value: String(p.id), text: p.nombre + (p.cargo ? ' · ' + p.cargo : '') });
                if (e.programadoId === p.id) o.selected = true;
                sel.appendChild(o);
            });
            listo = true;
        });
        CAF.modal('Responsable de atención · ' + e.empresa, cuerpo, [
            { texto: 'Cancelar', onclick: function (cerrar) { cerrar(); } },
            { texto: 'Guardar', tipo: 'primary', onclick: function (cerrar) {
                if (!listo || env) return; env = true;
                enviar(d.urlProgramar, { solicitudId: e.id, personalId: sel.value ? +sel.value : null }, { disabled: false }, cerrar).then(function () { env = false; });
            } }
        ]);
    }

    // ── arranque ─────────────────────────────────────────────────────────────────────────────
    document.getElementById('pv-ant').addEventListener('click', function () { navegar(-1); });
    document.getElementById('pv-sig').addEventListener('click', function () { navegar(1); });
    document.getElementById('pv-hoy').addEventListener('click', irHoy);
    document.getElementById('pv-act').addEventListener('click', function () { cargar().then(function () { CAF.aviso('Calendario actualizado.'); }); });
    // Sin tiempo real (IIS/WebSocket sin confirmar): se vuelve a consultar cada minuto mientras la pestaña está a la vista.
    setInterval(function () { if (!document.hidden && ancla) cargar(true); }, 60000);
    document.addEventListener('visibilitychange', function () { if (!document.hidden && ancla) cargar(true); });
    pintarVistas();
    cargar();
})();

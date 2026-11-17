// Calendario de entregas de proveedores. Semana: tarjetas completas con sus acciones. Mes: conteo por día (un clic abre esa semana).
// Todos los que tienen el permiso del dashboard lo ven; solo Almacén tiene botones. Cada acción la vuelve a validar la base de datos
// (estado, día, exclusa única), así que aquí solo se decide qué botón mostrar y se refresca el estado.
// Almacén tiene un único botón dinámico por entrega: Confirmar disponibilidad → Iniciar atención → Terminar atención (+ Cancelar disponibilidad).
(function () {
    'use strict';
    var raiz = document.getElementById('caf-prov');
    if (!raiz) return;
    var el = CAF.el, d = raiz.dataset, almacen = d.puedeAlmacen === 'Y';
    var vista = 'SEMANA', ancla = lunes(new Date()), anclado = false, hoy = null, datos = [], exclusa = null, cupos = [], cargado = { desde: '', hasta: '' }, secuencia = 0;
    var cal = document.getElementById('pv-cal'), titulo = document.getElementById('pv-titulo'), hora = document.getElementById('pv-hora');
    var avExc = document.getElementById('pv-exclusa');

    var DIAS = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
    var MESES = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'];
    // [rótulo, clase del chip, punto de la vista mensual, ayuda para la leyenda]
    var ESTADO = {
        PROGRAMADO: ['Programado', 'st-prog', 'st-prog', 'Aprobada y agendada; el proveedor aún no llega o no pasó la verificación.'],
        EN_ESPERA: ['En espera', 'st-esp', 'st-esp', 'Vigilancia verificó sus datos; espera que Almacén confirme disponibilidad y se valide el ingreso.'],
        INGRESO: ['Ingreso', 'st-ing', 'st-ing', 'Ya ingresó físicamente; espera que Almacén inicie la atención.'],
        EN_ATENCION: ['En atención', 'st-aten', 'st-aten', 'Almacén lo está recibiendo en la exclusa.'],
        PAUSADA: ['Pausada', 'st-pau', 'st-pau', 'En atención, pero todas las empresas que ya se iniciaron están detenidas; falta reanudarlas o terminarlas.'],
        RECEPCIONADO: ['Recepción culminada', 'st-rec', 'st-rec', 'Almacén terminó; sigue dentro hasta que Vigilancia registre su salida.'],
        SALIO: ['Salió', 'st-sal', 'st-sal', 'Entrega cerrada.'],
        NO_SE_PRESENTO: ['No se presentó', 'st-nop', 'st-nop', 'No llegó en el día.'],
        CIERRE_FORZADO: ['Cierre forzado', 'st-cie', 'st-cie', 'El día terminó sin registrar su salida: el sistema la cerró y liberó la exclusa.'],
        INGRESO_DENEGADO: ['Ingreso denegado', 'st-den', 'st-den', 'El coordinador denegó su ingreso en la verificación.'],
        RETIRO_SIN_INGRESO: ['Retiró sin ingresar', 'st-ret', 'st-ret', 'Fue verificado pero se retiró sin ingresar (lo registra Vigilancia).']
    };
    // D-238: estado de la atención por empresa [rótulo, clase]
    var ATENCION = { PENDIENTE: ['Pendiente', 'at-pen'], EN_ATENCION: ['En atención', 'at-ing'], DETENIDA: ['Detenida', 'at-pau'], ATENDIDA: ['Atendida', 'at-ok'], CERRADA_SIN_ATENCION: ['Sin atención', 'at-sin'] };
    var EMPRESAS = {
        TRIANON_ENERGO: ['Trianon Energo', 'TE', 'em-te'], POWER_TECHNOLOGY: ['Power Technology', 'PT', 'em-pt'],
        TRIANON_ASCENSORES: ['Trianon Ascensores', 'TA', 'em-ta'], TRIANON_SOSTENIBLE: ['Trianon Sostenible', 'TS', 'em-ts']
    };
    var filtro = leerFiltro();

    function leerFiltro() {
        var q = new URLSearchParams(location.search);
        return { emp: q.get('emp') || '', est: q.get('est') || '', fec: /^\d{4}-\d{2}-\d{2}$/.test(q.get('fec') || '') ? q.get('fec') : '' };
    }
    function guardarFiltro() {
        var q = new URLSearchParams(location.search);
        ['emp', 'est', 'fec'].forEach(function (k) { if (filtro[k]) q.set(k, filtro[k]); else q.delete(k); });
        try { history.replaceState(null, '', location.pathname + (q.toString() ? '?' + q : '')); } catch (x) { /* sin historial: no pasa nada */ }
    }
    function pasa(e) {
        return (!filtro.emp || codigos(e).indexOf(filtro.emp) >= 0) && (!filtro.est || estadoVisual(e) === filtro.est) && (!filtro.fec || e.fecha === filtro.fec);
    }
    // D-244: «Pausada» no es un estado de la base: es la entrega en atención cuyas empresas iniciadas están todas detenidas
    function estadoVisual(e) { return e.pausada && e.estado === 'EN_ATENCION' ? 'PAUSADA' : e.estado; }
    // D-236: una entrega puede estar ligada a 1 a 4 empresas (destinoCodigo = códigos separados por coma)
    function codigos(e) { return String(e.destinoCodigo || '').split(',').filter(Boolean); }
    function emp(e) { return EMPRESAS[codigos(e)[0]] || [e.destino || '—', '··', 'em-xx']; }
    function chipsEmp(e) {
        var l = codigos(e).map(function (c) { var x = EMPRESAS[c]; return x ? el('span', { class: 'pv-em ' + x[2], title: x[0], text: x[1] }) : null; }).filter(Boolean);
        return l.length ? l : [el('span', { class: 'pv-em em-xx', text: '··' })];
    }

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
            hoy = res.hoy; datos = res.data || []; exclusa = res.exclusa; cupos = res.cupos || []; cargado = r;
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
        ancla = vista === 'SEMANA' ? sumar(ancla, 7 * paso) : vista === 'DIA' ? sumar(ancla, paso) : new Date(ancla.getFullYear(), ancla.getMonth() + paso, 1);
        var r = rangoVisible();
        if (r.desde !== cargado.desde || r.hasta !== cargado.hasta) cargar(); else pintar();
    }

    function irHoy() { ancla = vista === 'SEMANA' ? lunes(aFecha(hoy)) : aFecha(hoy); cargar(); }
    function alinear(f) { return vista === 'SEMANA' ? lunes(f) : vista === 'DIA' ? new Date(f.getFullYear(), f.getMonth(), f.getDate()) : new Date(f.getFullYear(), f.getMonth(), 1); }

    // ── pintado ──────────────────────────────────────────────────────────────────────────────
    function pintarVistas() {
        var c = document.getElementById('pv-vistas'); c.textContent = '';
        [['MES', 'Mes'], ['SEMANA', 'Semana'], ['DIA', 'Día']].forEach(function (v) {
            c.appendChild(el('button', { type: 'button', class: v[0] === vista ? 'on' : '', text: v[1], onclick: function () { cambiarVista(v[0]); } }));
        });
    }

    function cambiarVista(v) {
        if (v === vista) return;
        var previa = ancla || aFecha(hoy), h = aFecha(hoy), fin = vista === 'SEMANA' ? sumar(previa, 6) : new Date(previa.getFullYear(), previa.getMonth() + 1, 0);
        var contieneHoy = h >= previa && h <= fin || (vista === 'DIA' && aTexto(previa) === hoy);
        // Al pasar a Día se queda en hoy si el período que se miraba lo incluye; si no, en el primer día de ese período.
        vista = v; ancla = alinear(v === 'DIA' && contieneHoy ? h : previa);
        pintarVistas(); cargar();
    }

    function pintarExclusa() {
        avExc.textContent = '';
        var x = exclusa || {}, quien = (x.empresa || '') + (x.codigo ? ' (' + x.codigo + ')' : '');
        if (x.estado === 'RESERVADA') {
            avExc.className = 'aviso pv-exc-res';
            avExc.appendChild(el('span', {}, [el('b', { text: 'Exclusa reservada: ' }), quien + (x.desde ? ' desde las ' + x.desde : '') + '. Almacén confirmó su disponibilidad y espera que ingrese. Para atender a otro proveedor, cancele esa disponibilidad.']));
        } else if (x.estado === 'DENTRO') {
            avExc.className = 'aviso pv-exc-res';
            avExc.appendChild(el('span', {}, [el('b', { text: 'Proveedor dentro, esperando atención: ' }), quien + '. La exclusa sigue reservada para esa entrega.']));
        } else if (x.estado === 'POR_SALIR') {
            avExc.className = 'aviso pv-exc-on';
            avExc.appendChild(el('span', {}, [el('b', { text: 'Exclusa ocupada, esperando la salida: ' }), quien + '. Almacén ya terminó; el camión sale por la misma exclusa y solo cuando Vigilancia registre su salida se podrá reservar para otra entrega.']));
        } else if (x.estado === 'EN_ATENCION' || x.ocupada) {
            avExc.className = 'aviso pv-exc-on';
            avExc.appendChild(el('span', {}, [el('b', { text: 'Atención en curso en la exclusa: ' }), quien + (x.desde ? ' desde las ' + x.desde : '') + (x.atiende ? ', atiende ' + x.atiende : '') + '. No se puede reservar para otra entrega hasta que se termine.']));
        } else {
            avExc.className = 'aviso pv-exc-off';
            avExc.appendChild(el('span', {}, [el('b', { text: 'Exclusa libre. ' }), 'No hay ninguna entrega reservada ni en atención.']));
        }
    }

    // D-244: panel de cupos. Muestra quién ocupa qué solicitud (como la exclusa) y cuántos cupos hay usados por almacenero y por empresa.
    function pintarCupos() {
        var c = document.getElementById('pv-cupos'); if (!c) return;
        c.textContent = '';
        if (!almacen || !cupos.length) return;
        var alm = cupos.filter(function (t) { return t.tipo === 'ALMACENERO'; }), ems = cupos.filter(function (t) { return t.tipo === 'EMPRESA'; });
        function lim(t) { return t.sinLimite ? 'sin límite' : String(t.limite); }
        var guardado = null; try { guardado = localStorage.getItem('pv-cupos'); } catch (x) { /* sin almacenamiento: queda abierto */ }
        var det = el('details', guardado === 'cerrado' ? {} : { open: '' });
        det.addEventListener('toggle', function () { try { localStorage.setItem('pv-cupos', det.open ? 'abierto' : 'cerrado'); } catch (x) { /* nada */ } });
        det.appendChild(el('summary', { text: 'Cupos de atención' + (alm.length ? ' · ' + alm.length + (alm.length === 1 ? ' entrega ocupa cupo de almacenero' : ' entregas ocupan cupo de almacenero') : '') }));
        var izq = el('div', {}, [el('h4', { text: 'Almaceneros' })]), der = el('div', {}, [el('h4', { text: 'Empresas' })]);
        if (!alm.length) izq.appendChild(el('p', { class: 'pv-cupo-vacio', text: 'Nadie tiene una entrega reservada ni en atención.' }));
        else izq.appendChild(el('ul', {}, alm.map(function (t) {
            var chips = (t.detalle || []).map(function (a) {
                var x = EMPRESAS[a.codigo], s = ATENCION[a.estado] || [a.estado, ''];
                return el('span', { class: 'pv-aten-i ' + s[1], title: (x ? x[0] : a.codigo) + ': ' + s[0] }, [el('span', { class: 'pv-em ' + (x ? x[2] : 'em-xx'), text: x ? x[1] : '··' }), ' ' + s[0]]);
            });
            return el('li', {}, [el('span', { class: 'pv-cupo-n', text: t.nombre }), el('span', { class: 'pv-cupo-tag' + (t.ocupa === 'ATENCION' ? ' at' : ''), text: t.ocupa === 'ATENCION' ? 'atendiendo' : 'reservó' }), el('span', { text: t.solicitud || '' })].concat(chips, [el('span', { class: 'small muted', text: '(' + t.usados + ' de ' + lim(t) + ')' })]));
        })));
        der.appendChild(el('ul', {}, ems.map(function (t) {
            var x = EMPRESAS[t.codigo], lleno = !t.sinLimite && t.usados >= t.limite;
            return el('li', {}, [el('span', { class: 'pv-em ' + (x ? x[2] : 'em-xx'), text: x ? x[1] : '··', title: t.nombre }),
                el('span', { class: lleno ? 'pv-cupo-lleno' : '', text: (x ? x[1] : t.codigo) + ': ' + (t.sinLimite ? t.usados + ' ocupados (sin límite)' : t.usados + ' de ' + t.limite + ' ocupados') }),
                t.solicitud ? el('span', { class: 'small muted', text: t.solicitud }) : null]);
        })));
        det.appendChild(el('div', { class: 'pv-cupos-g' }, [izq, der]));
        c.appendChild(det);
    }

    function pintarFiltros() {
        var c = document.getElementById('pv-filtros'); c.textContent = '';
        function sel(rot, k, ops) {
            var s = el('select', { 'aria-label': rot }, [el('option', { value: '', text: rot + ': todas' })].concat(ops.map(function (o) { return el('option', { value: o[0], text: o[1] }); })));
            s.value = filtro[k]; s.addEventListener('change', function () { filtro[k] = s.value; guardarFiltro(); pintar(); }); return s;
        }
        c.appendChild(sel('Empresa', 'emp', Object.keys(EMPRESAS).map(function (k) { return [k, EMPRESAS[k][0]]; })));
        c.appendChild(sel('Estado', 'est', Object.keys(ESTADO).map(function (k) { return [k, ESTADO[k][0]]; })));
        var f = el('input', { type: 'date', 'aria-label': 'Fecha' }); f.value = filtro.fec;
        f.addEventListener('change', function () {
            filtro.fec = f.value; guardarFiltro();
            if (f.value) { var dia = aFecha(f.value); ancla = alinear(dia); var r = rangoVisible(); if (r.desde !== cargado.desde || r.hasta !== cargado.hasta) { cargar(); return; } }
            pintar();
        });
        c.appendChild(el('label', { class: 'pv-fec' }, [el('span', { class: 'small muted', text: 'Fecha' }), f]));
        c.appendChild(el('button', { type: 'button', class: 'btn btn-sm', id: 'pv-limpiar', text: 'Quitar filtros', onclick: function () { filtro = { emp: '', est: '', fec: '' }; guardarFiltro(); pintarFiltros(); pintar(); } }));
        c.appendChild(el('span', { class: 'small muted', id: 'pv-cuenta', 'aria-live': 'polite' }));
    }

    function pintarLeyenda() {
        var c = document.getElementById('pv-leyenda'); c.textContent = '';
        var det = el('details', { class: 'pv-ley' });
        var guardado = null; try { guardado = localStorage.getItem('pv-leyenda'); } catch (x) { /* sin almacenamiento: queda abierta */ }
        if (guardado !== 'cerrada') det.open = true;
        det.addEventListener('toggle', function () { try { localStorage.setItem('pv-leyenda', det.open ? 'abierta' : 'cerrada'); } catch (x) { /* nada */ } });
        det.appendChild(el('summary', { text: 'Leyenda: estados, empresas y marcas' }));
        function grupo(titulo, items) { return el('div', { class: 'pv-ley-g' }, [el('b', { text: titulo }), el('ul', {}, items)]); }
        function fila(marca, texto) { return el('li', {}, [marca, el('span', { class: 'small muted', text: texto })]); }
        det.appendChild(el('div', { class: 'pv-ley-cols' }, [
            grupo('Estados', Object.keys(ESTADO).map(function (k) { return fila(el('span', { class: 'pv-st ' + ESTADO[k][1], text: ESTADO[k][0] }), ESTADO[k][3]); })),
            el('div', {}, [
                grupo('Empresas (la que recibe la entrega)', Object.keys(EMPRESAS).map(function (k) { return fila(el('span', { class: 'pv-em ' + EMPRESAS[k][2], text: EMPRESAS[k][1] }), EMPRESAS[k][0]); })),
                grupo('Marcas', [
                    fila(el('span', { class: 'pv-leyres', text: 'Borde grueso' }), 'EXCLUSA RESERVADA: la entrega tiene la exclusa, desde que Almacén confirma disponibilidad hasta que Vigilancia registra su salida.'),
                    fila(el('span', { class: 'pv-leyres', text: 'POR SALIR' }), 'Recepción culminada: el camión sigue dentro y la exclusa sigue ocupada hasta su salida.'),
                    fila(el('span', { class: 'pv-marca pv-m-ok', text: 'Almacén listo' }), 'Almacén confirmó disponibilidad.'),
                    fila(el('span', { class: 'pv-marca pv-m-dev', text: 'Con desviación' }), 'Se verificó con datos distintos a la solicitud; el coordinador decidió en el acto.')
                ])
            ])
        ]));
        c.appendChild(det);
    }

    function pintar() {
        pintarVistas(); pintarExclusa(); pintarCupos();
        var n = datos.filter(pasa).length, cu = document.getElementById('pv-cuenta');
        if (cu) cu.textContent = n + (n === 1 ? ' entrega' : ' entregas') + (filtro.emp || filtro.est || filtro.fec ? ' con los filtros' : ' en el rango');
        cal.textContent = '';
        if (vista === 'SEMANA') pintarSemana(); else if (vista === 'DIA') pintarDia(); else pintarMes();
    }

    function delDia(texto) { return datos.filter(function (e) { return e.fecha === texto && pasa(e); }); }

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

    function pintarDia() {
        var t = aTexto(ancla), lista = delDia(t), i = (ancla.getDay() + 6) % 7;
        titulo.textContent = DIAS[i] + ' ' + ancla.getDate() + ' de ' + MESES[ancla.getMonth()] + ' ' + ancla.getFullYear();
        var col = el('section', { class: 'pv-dia' + (t === hoy ? ' hoy' : ''), 'aria-label': titulo.textContent }, [
            el('div', { class: 'pv-dia-h' }, [el('span', { text: t === hoy ? 'Hoy' : '' }), el('small', { text: lista.length ? lista.length + (lista.length === 1 ? ' entrega' : ' entregas') : '' })])
        ]);
        if (!lista.length) col.appendChild(el('div', { class: 'pv-vacio', text: 'Sin entregas' }));
        else { var rejilla = el('div', { class: 'pv-rejilla' }); lista.forEach(function (e) { rejilla.appendChild(tarjeta(e)); }); col.appendChild(rejilla); }
        cal.appendChild(el('div', { class: 'pv-semana' }, [col]));
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
                    celda.appendChild(el('span', { class: 'pv-mini' }, [el('span', { class: 'pv-punto ' + (ESTADO[estadoVisual(e)] ? ESTADO[estadoVisual(e)][2] : '') })].concat(chipsEmp(e), [el('span', { text: e.hora + ' ' + e.empresa })])));
                });
                if (lista.length > 3) celda.appendChild(el('span', { class: 'pv-mas', text: '+' + (lista.length - 3) + ' más' }));
                cont.appendChild(celda);
            })(f);
        }
        cal.appendChild(cont);
    }

    function tarjeta(e) {
        var est = ESTADO[estadoVisual(e)] || [e.estado, 'st-prog', '', ''], em = emp(e);
        // Reserva = la regla que ya existe: la entrega es la titular de la exclusa. Se mantiene hasta que Vigilancia registra la salida (el camión sale por la misma exclusa).
        var reserva = !!(exclusa && exclusa.ocupada && exclusa.id === e.id), porSalir = reserva && e.estado === 'RECEPCIONADO';
        var marcas = el('div', { class: 'pv-marcas' });
        if (e.disponible && !e.modoIngreso && (e.estado === 'EN_ESPERA' || e.estado === 'INGRESO')) marcas.appendChild(el('span', { class: 'pv-marca pv-m-ok', text: 'Almacén listo' + (e.disponibleDesde ? ' ' + e.disponibleDesde : '') }));
        if (e.conDesviacion) marcas.appendChild(el('span', { class: 'pv-marca pv-m-dev', text: 'Con desviación' }));
        var c = el('article', { class: 'pv-card ' + em[2] + ' e-' + estadoVisual(e).toLowerCase() + (reserva ? ' pv-reserva' : '') }, [
            reserva ? el('div', { class: 'pv-cinta' }, [porSalir ? 'POR SALIR · EXCLUSA OCUPADA' : 'EXCLUSA RESERVADA']) : null,
            el('div', { class: 'pv-card-h' }, chipsEmp(e).concat([el('b', { text: e.empresa, title: e.ruc ? 'RUC del proveedor: ' + e.ruc : '' }), el('span', { class: 'pv-hora', text: e.hora })])),
            el('div', { class: 'pv-estado' }, [el('span', { class: 'pv-st ' + est[1], text: est[0] })].concat(e.modoIngreso ? [el('span', { class: 'pv-modo ' + (e.modoIngreso === 'CON' ? 'pv-modo-con' : 'pv-modo-sin'), title: e.modoIngreso === 'CON' ? 'El vehículo ingresa por la esclusa' : 'El vehículo no ingresa; las personas entran a pie', text: e.modoIngreso === 'CON' ? 'Con ingreso vehicular' : 'Sin ingreso vehicular' })] : [])),
            marcas
        ]);
        if (!marcas.firstChild) c.removeChild(marcas);
        function linea(rotulo, valor) { if (valor) c.appendChild(el('div', { class: 'pv-linea' }, [el('b', { text: rotulo + ' ' }), valor])); }
        // D-225: con varios transportistas o con ayudantes de descarga se muestra el avance por persona
        var porPersona = e.transportistas > 1 || e.ayudantes > 0;
        // D-241: solo lo útil para atender; la OC sin el prefijo, el conductor con su documento, sin repetir la empresa que recibe (ya va en la etiqueta) ni el RUC (queda en el título del proveedor)
        linea('OC:', (e.numerosOc || []).map(function (x) { return String(x).replace(/^\s*OC[\s-]*/i, ''); }).join(', '));
        linea('Transporte:', e.empresaTransportista);
        linea('Conductor:', e.transportista + (e.documento ? ' · ' + e.documento : '') + (e.apoyo && !porPersona ? ' (+' + e.apoyo + ' apoyo)' : ''));
        if (porPersona) linea('Personas:', e.transportistas + (e.transportistas === 1 ? ' conductor' : ' conductores') + ' · verificados ' + e.verificados + ' · dentro ' + e.dentro +
            (e.salieron ? ' · salieron ' + e.salieron : '') + (e.ayudantes ? ' · ' + e.ayudantes + (e.ayudantes === 1 ? ' ayudante' : ' ayudantes') + ' de descarga' : ''));
        // D-238: con varias empresas, el estado de la atención de cada una
        if (e.atencion && e.atencion.length) {
            var chips = el('span', { class: 'pv-aten' }, e.atencion.map(function (a) {
                var x = EMPRESAS[a.codigo], t = ATENCION[a.estado] || [a.estado, ''];
                return el('span', { class: 'pv-aten-i ' + t[1], title: (x ? x[0] : a.codigo) + ': ' + t[0] }, [el('span', { class: 'pv-em ' + (x ? x[2] : 'em-xx'), text: x ? x[1] : '··' }), ' ' + t[0]]);
            }));
            linea('Atención:', chips);
        }
        // D-244: quién tiene la reserva (confirmó la disponibilidad) mientras la atención no empieza; si la cedió, queda libre para tomar
        if (almacen && e.disponible && !e.inicio && (e.estado === 'EN_ESPERA' || e.estado === 'INGRESO')) linea('Reserva:', e.reservaNombre ? e.reservaNombre : el('span', { class: 'pv-cupo-n', text: 'cedida · cualquier almacenero de la empresa puede tomarla' }));
        linea('Vehículo:', [e.placa, e.marca].filter(Boolean).join(' · '));
        linea('Detalle:', e.observaciones);
        c.appendChild(el('div', { class: 'pv-resp' }, [
            e.efectivo ? el('div', { class: 'pv-linea' }, [el('b', { text: 'Atiende: ' }), e.efectivo]) : null
        ]));
        var tiempos = [];
        if (e.llegada) tiempos.push((e.estado === 'INGRESO_DENEGADO' ? 'Verificado ' : 'Verificado ') + e.llegada); if (e.ingreso) tiempos.push('Ingresó ' + e.ingreso);
        if (e.inicio) tiempos.push('Atención ' + e.inicio); if (e.recepcion) tiempos.push('Culminó ' + e.recepcion);
        if (e.salida) tiempos.push('Salió ' + e.salida);
        if (e.resultado === 'CON_OBSERVACION') tiempos.push('Con observación');
        if (tiempos.length) c.appendChild(el('div', { class: 'pv-tiempos', text: tiempos.join(' · ') }));
        var acc = acciones(e);
        if (acc) c.appendChild(acc);
        var ir = enlaces(e);
        if (ir) c.appendChild(ir);
        return c;
    }

    // Accesos directos a las pantallas originales, donde se hace el trabajo con sus propias reglas. Cada pantalla abre la entrega ya aplicada.
    function enlaces(e) {
        var l = [];
        var pie = null;
        if (d.puedeSolicitar === 'Y' && e.esMia) {
            // Los mismos botones de la solicitud: Ver, Duplicar y Cancelar (solo mientras la entrega siga PROGRAMADA).
            l.push(['Ver solicitud', d.urlSolDetalle.replace('__ID__', e.id), 'Abre el detalle de su solicitud']);
            l.push(['Duplicar', d.urlSolNueva + '?reutilizar=' + e.id, 'Crea una solicitud nueva a partir de esta']);
            pie = e;
        }
        // D-243: nombres y colores propios por acción (Coordinador: Revisar solicitud / Ver solicitud (en curso) / Ver solicitud)
        if (d.puedeCoordinar === 'Y') {
            var estC = e.estado;
            var rev = estC === 'PROGRAMADO' || estC === 'EN_ESPERA';
            var cur = estC === 'INGRESO' || estC === 'EN_ATENCION' || estC === 'RECEPCIONADO';
            l.push([rev ? 'Revisar solicitud' : (cur ? 'Ver solicitud (en curso)' : 'Ver solicitud'), d.urlCoord + '?solicitud=' + e.id,
                    rev ? 'Abre la solicitud para revisarla o corregir personas en emergencia' : (cur ? 'Abre la solicitud con la entrega en curso (se consulta y se corrige en emergencia)' : 'Abre la solicitud (solo consulta)'),
                    rev ? 'pv-b-rev' : (cur ? 'pv-b-cur' : 'pv-b-ver')]);
        }
        // D-246: Almacén consulta la solicitud del proveedor (datos, personas, historial y documentos), solo lectura.
        if (almacen && !l.some(function (x) { return /^Ver solicitud|^Revisar solicitud/.test(x[0]); }))
            l.push(['Ver solicitud', d.urlSolVer.replace('__ID__', e.id), 'Abre la solicitud del proveedor y sus documentos (solo consulta)', 'pv-b-ver']);
        if (d.puedeVigilar === 'Y') {
            var sinAt = e.modoIngreso === 'SIN' && e.disponible && (e.estado === 'EN_ATENCION' || e.estado === 'INGRESO');   // D-243: sin vehículo Vigilancia sigue validando ingresos mientras Almacén atiende
            var t = { PROGRAMADO: 'Verificar datos', EN_ESPERA: 'Validar ingreso', RECEPCIONADO: 'Registrar salida', CIERRE_FORZADO: 'Registrar salida (tardía)' }[e.estado];
            var cls = { 'Verificar datos': 'pv-b-vf', 'Validar ingreso': 'pv-b-vi' }[t] || 'pv-b-vs';
            if (e.estado === 'EN_ESPERA' && e.transportistas > e.verificados) { l.push(['Verificar datos', d.urlVig + '?solicitud=' + e.id, 'Falta verificar a un conductor agregado', 'pv-b-vf']); }   // D-243: conductor agregado con otro ya verificado
            if (t) l.push([t, d.urlVig + '?solicitud=' + e.id, 'Abre Control de accesos con esta entrega', cls]);
            else if (sinAt) l.push(['Validar ingreso', d.urlVig + '?solicitud=' + e.id, 'Registra el ingreso de las personas (no depende de la atención de Almacén)', 'pv-b-vi']);
        }
        if (!l.length) return null;
        var caja = el('div', { class: 'pv-ir' }, l.map(function (x) { return el('a', { class: 'btn btn-sm' + (x[3] ? ' ' + x[3] : ''), href: x[1], text: x[0], title: x[2] }); }));
        if (pie) {
            var bc = el('button', { type: 'button', class: 'btn btn-sm btn-danger-o', text: 'Cancelar' });
            if (e.puedeCancelarSol) bc.addEventListener('click', function () { modalCancelarSolicitud(e); });
            else { bc.disabled = true; bc.classList.add('is-off'); bc.title = e.motivoNoCancelarSol || 'No se puede cancelar'; }
            caja.appendChild(bc);
        }
        return caja;
    }

    // Cancelar la solicitud (la misma confirmación y regla de «Mis solicitudes»; la base vuelve a validar).
    function modalCancelarSolicitud(e) {
        var motivo = el('textarea', { rows: '2', maxlength: '300', placeholder: 'Motivo (opcional)' });
        var err = el('p', { class: 'field-e' });
        var cuerpo = el('div', { class: 'stack' }, [el('p', { text: '¿Cancelar la solicitud ' + e.codigo + '? Sus invitados ya no podrán ingresar con ella.' }), motivo, err]);
        var env = false;
        CAF.modal('Cancelar solicitud', cuerpo, [
            { texto: 'Volver', onclick: function (c) { c(); } },
            { texto: 'Cancelar solicitud', tipo: 'primary', onclick: function (c) {
                if (env) return; env = true;
                CAF.pedir(d.urlSolCancelar, { method: 'POST', body: { solicitudId: e.id, motivo: motivo.value } }).then(function (r) {
                    env = false;
                    if (!r.success) { err.textContent = (r.errors && r.errors[0] && r.errors[0].message) || r.message || 'No se pudo cancelar.'; return; }
                    c(); CAF.aviso('Solicitud cancelada.'); cargar(true);
                });
            } }
        ]);
    }

    function acciones(e) {
        if (!almacen) return null;
        var caja = el('div', { class: 'pv-acc' }), hay = false;
        function boton(texto, fn, primario, off, ayuda, extra) {
            hay = true;
            var b = el('button', { type: 'button', class: 'btn btn-sm' + (primario ? ' btn-primary' : '') + (extra ? ' ' + extra : '') + (off ? ' is-off' : ''), text: texto });
            if (off) { b.disabled = true; if (ayuda) b.title = ayuda; } else b.addEventListener('click', fn);
            caja.appendChild(b);
        }
        // D-239/D-242: antes del ingreso, Confirmar disponibilidad; ya dentro, los botones dependen de lo que el almacenero puede hacer sobre esta entrega:
        //   Iniciar (verde) mientras queden empresas por iniciar · Detener o Reanudar (ámbar, según el estado) · Terminar (rojo).
        var sinVeh = e.modoIngreso === 'SIN' && e.disponible;                    // D-243: sin vehículo Almacén atiende sin esperar el ingreso
        var textos = [];
        // D-244: reserva cedida → «Tomar» (bloqueado con su motivo si ya tiene su cupo ocupado)
        if (e.puedeTomar) boton('Tomar reserva', function () { accionReserva(e, 'TOMAR'); }, true, false, '', 'pv-b-ini');
        else if (e.motivoTomar) { boton('Tomar reserva', null, true, true, e.motivoTomar, 'pv-b-ini'); textos.push(e.motivoTomar); }
        if (e.estado === 'PROGRAMADO' || (e.estado === 'EN_ESPERA' && !sinVeh)) {
            if (e.puedeConfirmar) boton('Confirmar disponibilidad', function () { modalConfirmar(e); }, true);
            else if (!(e.estado === 'EN_ESPERA' && e.disponible)) boton('Confirmar disponibilidad', null, true, true, motivo(e));
            if (e.puedeCeder) { hay = true; caja.appendChild(el('button', { type: 'button', class: 'pv-enlace', text: 'Ceder reserva…', title: 'Libera su cupo para que otro almacenero de la empresa tome esta entrega', onclick: function () { accionReserva(e, 'CEDER'); } })); }
        } else if (e.estado === 'EN_ESPERA' || e.estado === 'INGRESO' || e.estado === 'EN_ATENCION') {
            // D-243: lo que no se puede usar ahora se ve bloqueado (con su razón), no habilitado
            if (e.puedeAtender) boton('Iniciar atención', function () { accionAtencion(e, 'INICIAR'); }, true, false, '', 'pv-b-ini');
            else if (e.motivoIniciar) { boton('Iniciar atención', null, true, true, e.motivoIniciar, 'pv-b-ini'); textos.push(e.motivoIniciar); }
            if (e.puedeDetener) boton('Detener atención', function () { accionAtencion(e, 'DETENER'); }, false, false, '', 'btn-warn');
            if (e.puedeReanudar) boton('Reanudar atención', function () { accionAtencion(e, 'REANUDAR'); }, false, false, '', 'btn-warn');
            else if (e.motivoReanudar) { boton('Reanudar atención', null, false, true, e.motivoReanudar, 'btn-warn'); textos.push(e.motivoReanudar); }
            if (e.puedeTerminar) boton('Terminar atención', function () { accionAtencion(e, 'TERMINAR'); }, false, false, '', 'btn-danger');
            if (!hay) boton('Iniciar atención', null, true, true, motivo(e) || 'Ninguna empresa de esta entrega es de las que usted atiende.', 'pv-b-ini');
            if (e.puedeCeder) { hay = true; caja.appendChild(el('button', { type: 'button', class: 'pv-enlace', text: 'Ceder reserva…', title: 'Libera su cupo para que otro almacenero de la empresa tome esta entrega', onclick: function () { accionReserva(e, 'CEDER'); } })); }
            if (e.puedeCerrar) {
                hay = true;
                caja.appendChild(el('button', { type: 'button', class: 'pv-enlace', text: 'Cerrar sin atención…', title: 'Una empresa de la entrega no será atendida (queda registrado con el motivo)', onclick: function () { modalCerrarSin(e); } }));
            }
        }
        var m = textos.length ? textos[0] : ((e.estado === 'PROGRAMADO' || e.estado === 'EN_ESPERA' || e.estado === 'INGRESO') && !(e.puedeConfirmar || e.puedeAtender) ? motivo(e) : '');
        if (m) caja.appendChild(el('div', { class: 'pv-motivo', text: m }));
        return hay ? caja : null;
    }

    // D-244: ceder la reserva (con confirmación) o tomar la que cedieron
    function accionReserva(e, tipo) {
        if (tipo === 'TOMAR') { enviar(d.urlTomar, { solicitudId: e.id }, { disabled: false }, function () { }); return; }
        var cuerpo = el('div', { class: 'stack' }, [el('p', { text: 'Va a ceder su reserva de ' + e.codigo + ' (' + e.empresa + '). Quedará libre para que otro almacenero de esas empresas la tome y la inicie; usted dejará de ocupar su cupo con ella.' })]);
        var env = false;
        CAF.modal('Ceder reserva', cuerpo, [
            { texto: 'Volver', onclick: function (cerrar) { cerrar(); } },
            { texto: 'Ceder reserva', tipo: 'primary', onclick: function (cerrar) { if (env) return; env = true; enviar(d.urlCeder, { solicitudId: e.id }, { disabled: false }, cerrar).then(function () { env = false; }); } }
        ]);
    }

    function motivo(e) {
        if (e.motivoBloqueo) return e.motivoBloqueo;
        if (e.estado === 'PROGRAMADO') return 'Vigilancia aún no verifica los datos del proveedor.';
        if (e.estado === 'EN_ESPERA') return e.disponible ? 'Esperando que Vigilancia valide el ingreso.' : 'No disponible por ahora.';
        if (e.estado === 'INGRESO') return 'No disponible por ahora.';
        return '';
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

    // D-239/D-242: la disponibilidad no es anticipada (solo tras la verificación de Vigilancia) y Almacén decide si el vehículo ingresa o no. No se puede deshacer.
    function modalConfirmar(e) {
        var elegido = null, err = el('span', { class: 'field-e' });
        var cajas = [];
        function opcion(valor, titulo, ayuda, glifo) {
            var inp = el('input', { type: 'radio', name: 'pv-modo', value: valor });
            var lab = el('label', { class: 'pv-opcion' }, [inp, el('span', { class: 'pv-opcion-i', 'aria-hidden': 'true', text: glifo }), el('b', { text: titulo }), el('span', { class: 'pv-opcion-a', text: ayuda })]);
            inp.addEventListener('change', function () { elegido = valor; err.textContent = ''; cajas.forEach(function (c) { c.classList.toggle('sel', c === lab); }); });
            cajas.push(lab); return lab;
        }
        var cuerpo = el('div', { class: 'stack' }, [
            el('p', { class: 'pv-modal-p', text: 'Elija cómo se atenderá a este proveedor. Los conductores ya fueron verificados por Vigilancia.' }),
            el('div', { class: 'pv-opciones', role: 'radiogroup', 'aria-label': 'Ingreso vehicular' }, [
                opcion('Y', 'Con ingreso vehicular', 'El vehículo entra por la esclusa, que queda reservada para esta entrega hasta su salida.', '🚚'),
                opcion('N', 'Sin ingreso vehicular', 'No se usa la esclusa; las personas ingresan a pie.', '🚶')]),
            el('p', { class: 'pv-aviso-irrev', text: 'Esta decisión no se puede deshacer.' }), err
        ]);
        var env = false;
        CAF.modal('Confirmar disponibilidad · ' + e.empresa, cuerpo, [
            { texto: 'Volver', onclick: function (cerrar) { cerrar(); } },
            { texto: 'Confirmar disponibilidad', tipo: 'primary', onclick: function (cerrar) {
                if (env) return;
                if (!elegido) { err.textContent = 'Elija con o sin ingreso vehicular.'; return; }
                env = true; enviar(d.urlConfirmar, { solicitudId: e.id, conVehiculo: elegido === 'Y' }, { disabled: false }, cerrar).then(function () { env = false; });
            } }
        ]);
    }

    // D-242: Iniciar / Detener / Reanudar / Terminar. Con una sola empresa posible, Iniciar y Reanudar se ejecutan de inmediato; con varias, un modal pequeño
    // deja elegir una, varias o todas. Detener y Terminar piden además un texto opcional (motivo / observación). Solo quien inició puede detener, reanudar o terminar.
    var ACC = {
        INICIAR:  { titulo: 'Iniciar atención',  flag: 'puedeAtender',     estado: 'PENDIENTE', url: 'urlAtenderEmpresas',  tipo: 'primary', directo: true,  vacio: 'No hay empresas pendientes que usted pueda iniciar.',
                    intro: 'Elija las empresas cuya atención va a iniciar. Se inician las que tienen cupo; de las demás se le avisa.' },
        DETENER:  { titulo: 'Detener atención',  flag: 'puedeDetener',     estado: 'EN_ATENCION', url: 'urlDetenerEmpresas',  tipo: 'warn', vacio: 'No tiene empresas en atención (iniciadas por usted) para detener.',
                    intro: 'Se libera el cupo de la empresa para otra entrega urgente. Luego podrá reanudarla.', campo: ['motivo', 'Motivo (opcional)'] },
        REANUDAR: { titulo: 'Reanudar atención', flag: 'puedeReanudar',    estado: 'DETENIDA', url: 'urlReanudarEmpresas', tipo: 'warn', directo: true, vacio: 'No tiene empresas detenidas por usted para reanudar.',
                    intro: 'Elija las empresas cuya atención va a reanudar. Solo se reanuda si la empresa tiene cupo.' },
        TERMINAR: { titulo: 'Terminar atención', flag: 'puedeRecepcionar', estado: 'EN_ATENCION', url: 'urlTerminarEmpresas', tipo: 'danger', vacio: 'No tiene empresas en atención (iniciadas por usted) para terminar.',
                    intro: 'Cuando todas las empresas terminan, Vigilancia puede registrar la salida.', campo: ['observacion', 'Observación de la recepción (opcional; vacía = conforme)'] }
    };

    function accionAtencion(e, tipo) {
        var cfg = ACC[tipo];
        CAF.pedir(d.urlAtencion + '?id=' + e.id).then(function (r) {
            if (!r.success) { CAF.aviso(r.message || 'No se pudo cargar la atención.', 'warn'); return; }
            var todas = r.data.empresas || [];
            var cand = todas.filter(function (a) { return a.autorizado && a.estado === cfg.estado; });
            var libres = cand.filter(function (a) { return a[cfg.flag]; });
            if (!libres.length) {
                var m = cand.map(function (a) { return a.motivoNo; }).filter(Boolean)[0];
                CAF.aviso(m || cfg.vacio, 'warn'); return;
            }
            if (cfg.directo && cand.length === 1) { enviar(d[cfg.url], { solicitudId: e.id, empresasIds: [libres[0].id] }, { disabled: false }, function () { }); return; }
            modalAtencion(e, tipo, cfg, cand);
        });
    }

    function modalAtencion(e, tipo, cfg, cand) {
        var cuerpo = el('div', { class: 'stack' }), checks = [], extra = null, env = false, err = el('span', { class: 'field-e' });
        cuerpo.appendChild(el('p', { class: 'pv-modal-p', text: cfg.intro }));
        var libres = cand.filter(function (a) { return a[cfg.flag]; }), varias = cand.length > 1;
        if (varias && libres.length > 1) {
            var todas = el('input', { type: 'checkbox' });
            cuerpo.appendChild(el('label', { class: 'pv-opc pv-opc-todas' }, [todas, el('b', { text: 'Todas' })]));
            todas.addEventListener('change', function () { checks.forEach(function (c) { if (!c.disabled) c.checked = todas.checked; }); });
        }
        cand.forEach(function (a) {
            var x = EMPRESAS[a.codigo], ok = !!a[cfg.flag];
            var c = el('input', { type: 'checkbox', value: String(a.id) }); c.checked = ok && cand.length === 1; c.disabled = !ok; checks.push(c);
            var fila = el('label', { class: 'pv-opc' + (ok ? '' : ' off') }, [c, el('span', { class: 'pv-em ' + (x ? x[2] : 'em-xx'), text: x ? x[1] : '··' }), el('span', { text: a.nombre })]);
            if (!ok && a.motivoNo) fila.appendChild(el('span', { class: 'pv-opc-n', text: a.motivoNo }));
            cuerpo.appendChild(fila);
        });
        if (cfg.campo) { extra = el('textarea', { rows: '2', maxlength: '500', placeholder: cfg.campo[1] }); cuerpo.appendChild(extra); }
        cuerpo.appendChild(err);
        CAF.modal(cfg.titulo + ' · ' + e.empresa, cuerpo, [
            { texto: 'Volver', onclick: function (cerrar) { cerrar(); } },
            { texto: cfg.titulo, tipo: cfg.tipo, onclick: function (cerrar) {
                if (env) return;
                var ids = checks.filter(function (c) { return c.checked && !c.disabled; }).map(function (c) { return +c.value; });
                if (!ids.length) { err.textContent = 'Elija al menos una empresa.'; return; }
                var body = { solicitudId: e.id, empresasIds: ids };
                if (cfg.campo) body[cfg.campo[0]] = extra.value;
                env = true; enviar(d[cfg.url], body, { disabled: false }, cerrar).then(function () { env = false; });
            } }
        ], 'chico');
    }

    // D-238/D-242: una empresa de la entrega no será atendida (motivo de la lista; detalle obligatorio si es «Otro»)
    function modalCerrarSin(e) {
        var cuerpo = el('div', { class: 'stack' }, [el('p', { class: 'pv-modal-p', text: 'Cargando…' })]), env = false, empSel = null, motSel = null, det = null, err = el('span', { class: 'field-e' });
        CAF.pedir(d.urlAtencion + '?id=' + e.id).then(function (r) {
            cuerpo.textContent = '';
            if (!r.success) { cuerpo.appendChild(el('p', { class: 'field-e', text: r.message || 'No se pudo cargar.' })); return; }
            var libres = (r.data.empresas || []).filter(function (a) { return a.puedeCerrar; }), motivos = r.data.motivos || [];
            if (!libres.length) { cuerpo.appendChild(el('p', { class: 'pv-modal-p', text: 'No hay empresas que usted pueda cerrar sin atención.' })); return; }
            empSel = el('select', {}, libres.map(function (a) { return el('option', { value: String(a.id), text: a.nombre }); }));
            motSel = el('select', {}, [el('option', { value: '', text: '— Elija el motivo —' })].concat(motivos.map(function (m) { return el('option', { value: String(m.id), text: m.texto, 'data-otro': m.otro ? 'Y' : 'N' }); })));
            det = el('textarea', { rows: '2', maxlength: '300', placeholder: 'Detalle (obligatorio si elige «Otro»)' });
            cuerpo.appendChild(el('p', { class: 'pv-modal-p', text: 'La empresa no será atendida en esta entrega. Queda registrado con el motivo.' }));
            if (libres.length > 1) cuerpo.appendChild(el('label', { class: 'field' }, [el('span', { class: 'field-l', text: 'Empresa' }), empSel]));
            cuerpo.appendChild(el('label', { class: 'field' }, [el('span', { class: 'field-l', text: 'Motivo' }), motSel])); cuerpo.appendChild(det); cuerpo.appendChild(err);
        });
        CAF.modal('Cerrar sin atención · ' + e.empresa, cuerpo, [
            { texto: 'Volver', onclick: function (cerrar) { cerrar(); } },
            { texto: 'Cerrar sin atención', tipo: 'danger', onclick: function (cerrar) {
                if (env || !motSel) return;
                if (!motSel.value) { err.textContent = 'Elija el motivo.'; return; }
                if (motSel.options[motSel.selectedIndex].getAttribute('data-otro') === 'Y' && det.value.trim().length < 3) { err.textContent = 'Describa el motivo.'; return; }
                env = true; enviar(d.urlCerrarSin, { solicitudId: e.id, empresaId: +empSel.value, motivoId: +motSel.value, detalle: det.value }, { disabled: false }, cerrar).then(function () { env = false; });
            } }
        ], 'chico');
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
    // Sin tiempo real (IIS/WebSocket sin confirmar): se vuelve a consultar cada 10 s mientras la pestaña está a la vista y sin ventanas abiertas.
    CAF.autoRefrescar(function () { if (ancla) cargar(true); }, 10);
    pintarVistas(); pintarFiltros(); pintarLeyenda();
    cargar();
})();

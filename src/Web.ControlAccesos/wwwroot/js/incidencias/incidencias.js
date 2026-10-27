// Incidencias. Modo «coord» (coordinador): lista con filtros, decidir y registrar. Modo «dia» (Vigilancia): las de hoy y registrar.
// Expone INC.registrar(previa) para que otras pantallas (Control de accesos) abran el formulario con una persona elegida.
var INC = (function () {
    'use strict';
    var raiz = document.getElementById('caf-inc');
    var el = CAF.el;
    var ESTADO = { REGISTRADA: ['Registrada', 'c-pend'], CONFIRMADA: ['Confirmada', 'c-rec'], DESESTIMADA: ['Desestimada', 'c-can'] };
    function chipEstado(e) { var x = ESTADO[e] || [e, 'c-pend']; return el('span', { class: 'chip ' + x[1], text: x[0] }); }
    function lugarTxt(x) { return [x.zona, x.lugar].filter(Boolean).join(' · ') || '—'; }

    // ── Formulario «Registrar incidencia» ────────────────────────────────────────────────────
    // urls: {opciones, personas, registrar}; previa: {id, nombre} de una persona ya elegida (opcional); alTerminar: función
    function registrar(urls, esCoord, previa, alTerminar) {
        CAF.pedir(urls.opciones).then(function (o) {
            if (!o.success) { CAF.aviso(o.message || 'No se pudieron cargar las listas.', 'warn'); return; }
            var op = o.data, elegidas = previa ? [previa] : [], sugerencias = el('div'), chips = el('div', { class: 'chips-x' });
            var buscar = el('input', { type: 'text', autocomplete: 'off', placeholder: 'Apellido, nombre o DNI' });
            var tipo = el('select'); tipo.appendChild(el('option', { value: '', text: 'Elija' }));
            op.tipos.forEach(function (t) { tipo.appendChild(el('option', { value: String(t.id), text: t.texto })); });
            var hora = el('input', { type: 'time' });
            var d = new Date(); hora.value = String(d.getHours()).padStart(2, '0') + ':' + String(d.getMinutes()).padStart(2, '0');
            var lugar = el('select'); lugar.appendChild(el('option', { value: '', text: 'Elija' }));
            op.zonas.forEach(function (z) { lugar.appendChild(el('option', { value: String(z.id), text: z.texto })); });
            lugar.appendChild(el('option', { value: 'OTRO', text: 'Otro lugar (especificar)' }));
            var tipoDet = SOL.campo('Especifique el tipo *', el('input', { type: 'text', maxlength: '500', autocomplete: 'off' }));
            var lugarDet = SOL.campo('Especifique el lugar *', el('input', { type: 'text', maxlength: '200', autocomplete: 'off', placeholder: 'Estacionamiento de visitas' }));
            var desc = el('textarea', { rows: '3', maxlength: '2000', placeholder: 'Qué pasó, dónde y quién lo vio' });
            var error = el('p', { class: 'err', hidden: true, role: 'alert' });
            tipoDet.hidden = true; lugarDet.hidden = true;

            function sincTipo() { var t = op.tipos.filter(function (x) { return String(x.id) === tipo.value; })[0]; tipoDet.hidden = !(t && t.esOtro); }
            function sincLugar() { lugarDet.hidden = lugar.value !== 'OTRO'; }
            tipo.addEventListener('change', sincTipo); lugar.addEventListener('change', sincLugar);

            function pintarChips() {
                chips.textContent = '';
                elegidas.forEach(function (p) {
                    chips.appendChild(el('span', { class: 'chip c-line' }, [p.nombre + ' ', el('button', { type: 'button', class: 'link', 'aria-label': 'Quitar persona', text: '×', onclick: function () { elegidas = elegidas.filter(function (x) { return x.id !== p.id; }); pintarChips(); } })]));
                });
            }
            pintarChips();
            var t = null, seq = 0;
            buscar.addEventListener('input', function () {
                clearTimeout(t);
                t = setTimeout(function () {
                    var q = buscar.value.trim(), mi = ++seq;
                    sugerencias.textContent = '';
                    if (q.length < 2) return;
                    CAF.pedir(urls.personas + '?texto=' + encodeURIComponent(q)).then(function (r) {
                        if (mi !== seq || !r.success) return;
                        var l = r.data.filter(function (p) { return !elegidas.some(function (x) { return x.id === p.id; }); });
                        if (!l.length) { sugerencias.appendChild(el('p', { class: 'field-h', text: 'Nadie que haya ingresado hoy coincide con la búsqueda.' })); return; }
                        var caja = el('div', { class: 'sug' });
                        l.forEach(function (p) {
                            caja.appendChild(el('button', { type: 'button', onclick: function () { elegidas.push({ id: p.id, nombre: p.nombre }); buscar.value = ''; sugerencias.textContent = ''; pintarChips(); } },
                                [el('b', { text: p.nombre }), ' · ' + (p.empresa || '') + ' · ' + (p.estado === 'DENTRO' ? 'Dentro' : 'Salió')]));
                        });
                        sugerencias.appendChild(caja);
                    });
                }, 300);
            });

            var cuerpo = el('div', { class: 'stack' }, [
                SOL.campo('Personas involucradas *', buscar, 'Solo quienes ingresaron hoy (dentro o ya salieron).'), sugerencias, chips,
                el('div', { class: 'grid g3' }, [SOL.campo('Tipo *', tipo), SOL.campo('Hora aproximada *', hora), SOL.campo('Lugar *', lugar)]),
                tipoDet, lugarDet, SOL.campo('Descripción *', desc),
                el('div', { class: 'aviso a-info', text: esCoord ? 'Como Coordinador, la incidencia queda confirmada directamente.' : 'Quedará como Registrada hasta que el Coordinador la confirme o la desestime.' }), error
            ]);
            var enviando = false;
            CAF.modal('Registrar incidencia', cuerpo, [
                { texto: 'Cancelar', onclick: function (c) { c(); } },
                { texto: 'Registrar incidencia', tipo: 'primary', onclick: function (c) {
                    if (enviando) return;
                    error.hidden = true;
                    function falla(m) { error.textContent = m; error.hidden = false; }
                    if (!elegidas.length) { falla('Agregue al menos una persona.'); return; }
                    if (!tipo.value) { falla('Elija el tipo.'); return; }
                    if (!hora.value) { falla('Indique la hora aproximada.'); return; }
                    if (!lugar.value) { falla('Elija el lugar.'); return; }
                    if (!desc.value.trim()) { falla('Describa qué pasó.'); return; }
                    enviando = true;
                    CAF.pedir(urls.registrar, { method: 'POST', body: {
                        tipoId: Number(tipo.value), tipoDetalle: tipoDet.hidden ? null : tipoDet.querySelector('input').value, hora: hora.value,
                        zonaId: lugar.value === 'OTRO' ? null : Number(lugar.value), lugarDetalle: lugar.value === 'OTRO' ? lugarDet.querySelector('input').value : null,
                        descripcion: desc.value, personasIds: elegidas.map(function (p) { return p.id; })
                    } }).then(function (r) {
                        enviando = false;
                        if (!r.success) { falla(SOL.errores(r)); return; }
                        c(); CAF.aviso((r.data ? r.data.codigo + ' registrada.' : 'Incidencia registrada.') + (esCoord ? '' : ' Queda pendiente de la decisión del Coordinador.'));
                        if (alTerminar) alTerminar();
                    });
                } }
            ], 'ancho');
        });
    }

    function urlsDe(d) { return { opciones: d.urlOpciones, personas: d.urlPersonas, registrar: d.urlRegistrar }; }

    if (!raiz) return { registrar: registrar };

    // ── Pantallas ────────────────────────────────────────────────────────────────────────────
    var d = raiz.dataset, coord = d.modo === 'coord', puede = d.puedeRegistrar === 'Y';
    var cuerpoTabla = document.getElementById('i-filas'), btnNueva = document.getElementById('i-nueva');
    var filas = [], registradas = 0, secuencia = 0, temporizador = null, primera = true;
    var f = coord ? { texto: document.getElementById('i-texto'), estado: document.getElementById('i-estado'), origen: document.getElementById('i-origen'),
                      desde: document.getElementById('i-desde'), hasta: document.getElementById('i-hasta') } : null;
    var tabs = document.getElementById('i-tabs'), pestana = 'REGISTRADA';
    // Llega desde Control de accesos con ?persona=<id>&nombre=<texto>: abre el formulario con esa persona ya elegida.
    var qs = new URLSearchParams(window.location.search), previaId = Number(qs.get('persona')) || 0;

    if (puede) { btnNueva.hidden = false; btnNueva.addEventListener('click', function () { registrar(urlsDe(d), coord, null, cargar); }); }

    function pintar() {
        if (coord && tabs) {
            tabs.textContent = '';
            [['REGISTRADA', 'Por decidir (' + registradas + ')'], ['', 'Todas']].forEach(function (t) {
                tabs.appendChild(el('button', { type: 'button', class: 'pill' + (pestana === t[0] ? ' on' : ''), text: t[1], onclick: function () { pestana = t[0]; f.estado.value = t[0]; cargar(); } }));
            });
        }
        cuerpoTabla.textContent = '';
        if (!filas.length) {
            cuerpoTabla.appendChild(el('tr', {}, [el('td', { colspan: '7', class: 'vacio', text: coord ? 'No hay incidencias con esos filtros.' : 'No hay incidencias registradas hoy.' })]));
            return;
        }
        filas.forEach(function (x) {
            var porDecidir = coord && x.estado === 'REGISTRADA';
            cuerpoTabla.appendChild(el('tr', {}, [
                el('td', {}, [el('button', { type: 'button', class: 'link', text: x.codigo, onclick: function () { ver(x.id); } })]),
                el('td', { text: (coord ? SOL.fechaLarga(x.fecha) + ' ' : '') + '~' + x.hora }),
                el('td', { text: x.personas + (x.personas === 1 ? ' persona' : ' personas') }),
                el('td', {}, [el('div', { text: x.tipo }), el('div', { class: 'field-h', text: x.origen === 'VIGILANCIA' ? 'Vigilancia' : 'Coordinador' })]),
                el('td', { text: lugarTxt(x) }),
                el('td', {}, [chipEstado(x.estado)]),
                el('td', {}, [el('button', { type: 'button', class: 'btn btn-sm' + (porDecidir ? ' btn-primary' : ''), text: porDecidir ? 'Decidir' : 'Ver', onclick: function () { ver(x.id); } })])
            ]));
        });
    }

    function cargar() {
        var mi = ++secuencia, q;
        if (coord) q = '?estado=' + encodeURIComponent(f.estado.value) + '&texto=' + encodeURIComponent(f.texto.value.trim()) + '&desde=' + f.desde.value + '&hasta=' + f.hasta.value;
        else q = '?hoy=true';
        return CAF.pedir(d.urlLista + q).then(function (r) {
            if (mi !== secuencia) return;
            if (!r.success) { CAF.aviso(r.message || 'No se pudo cargar.', 'warn'); return; }
            registradas = r.registradas;
            filas = coord && f.origen.value ? r.data.filter(function (x) { return x.origen === f.origen.value; }) : r.data;
            if (coord && primera) { primera = false; if (registradas === 0 && pestana === 'REGISTRADA') { pestana = ''; f.estado.value = ''; return cargar(); } }
            pintar();
        });
    }

    if (coord) {
        f.estado.value = 'REGISTRADA';
        f.texto.addEventListener('input', function () { clearTimeout(temporizador); temporizador = setTimeout(cargar, 300); });
        [f.origen, f.desde, f.hasta].forEach(function (c) { c.addEventListener('change', cargar); });
        f.estado.addEventListener('change', function () { pestana = f.estado.value === 'REGISTRADA' ? 'REGISTRADA' : (f.estado.value === '' ? '' : 'x'); cargar(); });
    }

    function dd(dt, v) { return [el('dt', { text: dt }), el('dd', { text: v || '—' })]; }

    function ver(id) {
        var cont = el('div', { class: 'stack' }, [el('p', { class: 'vacio', text: 'Cargando...' })]);
        var sustento = el('textarea', { rows: '2', maxlength: '2000', placeholder: 'Sustento de la decisión' });
        var error = el('p', { class: 'err', hidden: true, role: 'alert' });
        var datos = null, enviando = false;
        function decidir(decision, c) {
            if (!datos || !datos.puedeDecidir || enviando) return;
            error.hidden = true;
            if (!sustento.value.trim()) { error.textContent = 'Escriba el sustento.'; error.hidden = false; return; }
            enviando = true;
            CAF.pedir(d.urlDecidir, { method: 'POST', body: { id: id, decision: decision, sustento: sustento.value } }).then(function (r) {
                enviando = false;
                if (!r.success) { error.textContent = SOL.errores(r); error.hidden = false; return; }
                c(); CAF.aviso(decision === 'CONFIRMAR' ? 'Incidencia confirmada.' : 'Incidencia desestimada.'); cargar();
            });
        }
        var botones = [{ texto: 'Cerrar', onclick: function (c) { c(); } }];
        if (coord) {
            botones.unshift({ texto: 'Confirmar', tipo: 'primary', onclick: function (c) { decidir('CONFIRMAR', c); } });
            botones.unshift({ texto: 'Desestimar', onclick: function (c) { decidir('DESESTIMAR', c); } });
        }
        CAF.modal('Incidencia', cont, botones, 'ancho');
        CAF.pedir(d.urlDetalle + '?id=' + id).then(function (r) {
            cont.textContent = '';
            if (!r.success) { cont.appendChild(el('p', { class: 'err', text: r.message || 'No se pudo cargar.' })); return; }
            var x = r.data; datos = x;
            var dl = el('dl', { class: 'dl' });
            dl.appendChild(el('dt', { text: 'Estado' })); dl.appendChild(el('dd', {}, [chipEstado(x.estado)]));
            [].concat(dd('Código', x.codigo), dd('Tipo', x.tipo + (x.tipoDetalle ? ': ' + x.tipoDetalle : '')), dd('Hora aproximada', SOL.fechaLarga(x.fecha) + ' ~' + x.hora),
                dd('Lugar', lugarTxt(x)), dd('Descripción', x.descripcion), dd('Registró', (x.registrador || '') + ' (' + (x.origen === 'VIGILANCIA' ? 'Vigilancia' : 'Coordinador') + ')'))
                .forEach(function (n) { dl.appendChild(n); });
            var per = el('dd'); x.personas.forEach(function (p) { per.appendChild(el('div', { text: p.nombre + (p.doc ? ' (' + p.doc + ')' : '') + ' · ' + p.solicitud + (p.empresa ? ' · ' + p.empresa : '') })); });
            dl.appendChild(el('dt', { text: 'Personas' })); dl.appendChild(per);
            if (x.estado !== 'REGISTRADA' && x.sustento) dd('Decisión', (x.decisor || '') + (x.fechaDecision ? ' · ' + x.fechaDecision : '') + ': ' + x.sustento).forEach(function (n) { dl.appendChild(n); });
            cont.appendChild(dl);
            if (coord && x.estado === 'REGISTRADA') {
                if (x.puedeDecidir) { cont.appendChild(SOL.campo('Sustento de la decisión *', sustento)); cont.appendChild(error); }
                else cont.appendChild(el('div', { class: 'aviso a-warn', text: 'No puede decidir esta incidencia.' }));
            }
        });
    }

    cargar();
    if (puede && previaId) {
        registrar(urlsDe(d), coord, { id: previaId, nombre: qs.get('nombre') || 'Persona elegida' }, cargar);
        try { window.history.replaceState(null, '', window.location.pathname); } catch (e) { /* sin historial */ }
    }
    return { registrar: registrar };
})();

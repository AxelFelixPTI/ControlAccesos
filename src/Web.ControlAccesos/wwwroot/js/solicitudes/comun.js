// Piezas compartidas de las pantallas de solicitudes: estados, formulario de datos de la visita, buscador de
// responsable, formulario de persona externa. Todo texto entra con textContent (CAF.el); nada de innerHTML.
var SOL = (function () {
    'use strict';
    var el = CAF.el;

    var ESTADOS = {
        PENDIENTE: ['Pendiente', 'c-pend'], OBSERVADA: ['Observada', 'c-obs'], APROBADA: ['Aprobada', 'c-ok'],
        APROBADA_PARCIAL: ['Aprobada parcial', 'c-par'], RECHAZADA: ['Rechazada', 'c-rec'], CANCELADA: ['Cancelada', 'c-can']
    };
    function chipEstado(e) { var x = ESTADOS[e] || [e, 'c-pend']; return el('span', { class: 'chip ' + x[1], text: x[0] }); }

    // Estado de una persona dentro de la solicitud: aprobación + lo que ocurrió en portería.
    function chipPersona(p) {
        var m = { PENDIENTE: ['Pendiente de aprobación', 'c-pend'], APROBADA: ['Autorizada', 'c-ok'], OBSERVADA: ['Observada', 'c-obs'], RECHAZADA: ['Rechazada', 'c-rec'], RETIRADA: ['Retirada', 'c-ret'] };
        var x = m[p.aprobacion] || [p.aprobacion, 'c-pend'];
        return el('span', { class: 'chip ' + x[1], text: x[0] });
    }
    function textoIngreso(estado) {
        return { DENTRO: 'Está dentro de la sede', SALIO: 'Ya salió', DENEGADA: 'Se le denegó el ingreso', NO_SE_PRESENTO: 'No se presentó' }[estado] || '';
    }

    function hoy() { var d = new Date(); return d.getFullYear() + '-' + String(d.getMonth() + 1).padStart(2, '0') + '-' + String(d.getDate()).padStart(2, '0'); }
    function fechaLarga(f) { var p = String(f).split('-'); return p.length === 3 ? p[2] + '/' + p[1] + '/' + p[0] : f; }
    function campo(etiqueta, control, ayuda) { return el('label', { class: 'field' }, [el('span', { class: 'field-l', text: etiqueta }), control, ayuda ? el('span', { class: 'field-h', text: ayuda }) : null]); }
    function texto(valor, max, ph) { var i = el('input', { type: 'text', maxlength: String(max), autocomplete: 'off', placeholder: ph || '' }); i.value = valor || ''; return i; }
    function errores(r) {
        var det = (r.errors || []).map(function (e) { return e.message; }).filter(Boolean);
        return det.length ? det.join(' ') : (r.message || 'No se pudo completar la operación.');
    }

    function cargarOpciones(url) {
        return CAF.pedir(url).then(function (r) {
            if (!r.success) { CAF.aviso(r.message || 'No se pudieron cargar las listas.', 'warn'); return null; }
            return r.data;
        });
    }

    // ── Datos de la visita ───────────────────────────────────────────────────────────────────
    // Lista de sugerencias bajo un campo de texto. cargar(q) devuelve una promesa con [{t: texto, s: subtexto, v: valor}]; alElegir(v) recibe el valor.
    function sugerencias(input, minimo, cargar, alElegir) {
        var caja = el('div', { class: 'sug' }), temp = null, ult = '';
        caja.hidden = true;
        function ocultar() { caja.hidden = true; caja.textContent = ''; }
        input.addEventListener('input', function () {
            clearTimeout(temp);
            var q = input.value.trim();
            if (q.length < minimo) { ocultar(); return; }
            temp = setTimeout(function () {
                ult = q;
                cargar(q).then(function (items) {
                    if (q !== ult) return;
                    caja.textContent = '';
                    if (!items || !items.length) { caja.hidden = true; return; }
                    caja.hidden = false;
                    items.forEach(function (it) {
                        var b = el('button', { type: 'button' }, [el('span', { text: it.t })]);
                        if (it.s) b.appendChild(el('small', { class: 'sug-sub', text: ' ' + it.s }));
                        b.addEventListener('mousedown', function (e) { e.preventDefault(); ocultar(); alElegir(it.v); });
                        caja.appendChild(b);
                    });
                });
            }, 250);
        });
        input.addEventListener('blur', function () { setTimeout(ocultar, 150); });
        return caja;
    }

    // D-217: lista de correos como etiquetas. Escriba 2 letras para ver usuarios y correos ya usados; Enter, «;» o «,» agregan;
    // la × quita uno. Sin repetidos. El nodo expone .value (texto «a; b») igual que un campo de texto.
    function chipsCorreo(valor, urlSug, ph) {
        var lista = [], RX = /^[^\s@;,]+@[^\s@;,]+\.[^\s@;,]+$/;
        var caja = el('div', { class: 'chips-box' }), input = el('input', { type: 'text', autocomplete: 'off', placeholder: ph || '' });
        var aviso = el('p', { class: 'field-h' }), raiz = el('div', { class: 'sug-wrap' });
        function partir(t) { return String(t || '').split(/[;,\s]+/).map(function (x) { return x.trim().toLowerCase(); }).filter(Boolean); }
        function pintar() {
            caja.textContent = '';
            lista.forEach(function (c) {
                var x = el('button', { type: 'button', class: 'link', text: '×', 'aria-label': 'Quitar ' + c });
                x.addEventListener('click', function () { lista = lista.filter(function (y) { return y !== c; }); aviso.textContent = ''; pintar(); });
                caja.appendChild(el('span', { class: 'chip c-line' }, [el('span', { text: c }), x]));
            });
            caja.appendChild(input);
        }
        function agregar(t) {
            var ok = true;
            partir(t).forEach(function (c) {
                if (!RX.test(c)) { aviso.textContent = '«' + c + '» no parece un correo válido.'; ok = false; return; }
                if (lista.indexOf(c) >= 0) { aviso.textContent = c + ' ya está en la lista.'; return; }
                lista.push(c); aviso.textContent = '';
            });
            if (ok) input.value = '';
            pintar();
            return ok;
        }
        input.addEventListener('keydown', function (e) {
            if (e.key === 'Enter' || e.key === ';' || e.key === ',') { if (input.value.trim()) { e.preventDefault(); agregar(input.value); input.focus(); } else if (e.key === 'Enter') e.preventDefault(); }
            else if (e.key === 'Backspace' && !input.value && lista.length) { lista.pop(); pintar(); input.focus(); }
        });
        input.addEventListener('paste', function (e) { var t = (e.clipboardData || window.clipboardData).getData('text'); if (/[;,\s]/.test(t.trim())) { e.preventDefault(); agregar(t); input.focus(); } });
        input.addEventListener('blur', function () { setTimeout(function () { if (input.value.trim()) agregar(input.value); }, 200); });
        caja.addEventListener('click', function () { input.focus(); });
        var sug = sugerencias(input, 2, function (q) {
            return CAF.pedir(urlSug + '?q=' + encodeURIComponent(q)).then(function (r) {
                return r.success ? r.data.filter(function (c) { return lista.indexOf(c.correo) < 0; }).map(function (c) { return { t: c.correo, s: c.nombre || 'usado antes', v: c.correo }; }) : [];
            });
        }, function (c) { agregar(c); input.focus(); });
        raiz.appendChild(caja); raiz.appendChild(sug); raiz.appendChild(aviso);
        lista = partir(valor).filter(function (c, i, a) { return RX.test(c) && a.indexOf(c) === i; });
        pintar();
        // Lo escrito y no confirmado se lee también (si no es un correo válido, la base lo rechaza con su mensaje).
        Object.defineProperty(raiz, 'value', {
            get: function () { var p = input.value.trim(); return lista.concat(p ? [p] : []).join('; '); },
            set: function (t) { lista = partir(t).filter(function (c, i, a) { return RX.test(c) && a.indexOf(c) === i; }); input.value = ''; pintar(); }
        });
        return raiz;
    }

    // ── Selector de días de la franja del contratista (D-227): rango consecutivo y/o días sueltos, combinables ──
    // Devuelve {nodo, dias(), horaDesde(), horaHasta(), poner(lista)}. La web expande todo a una lista explícita «AAAA-MM-DD».
    var DIAS_MAX = 92;
    function sumaDias(f, n) { var p = f.split('-'); var d = new Date(Number(p[0]), Number(p[1]) - 1, Number(p[2]) + n); return d.getFullYear() + '-' + String(d.getMonth() + 1).padStart(2, '0') + '-' + String(d.getDate()).padStart(2, '0'); }
    function nombreDia(f) { var p = f.split('-'); var d = new Date(Number(p[0]), Number(p[1]) - 1, Number(p[2])); return ['dom', 'lun', 'mar', 'mié', 'jue', 'vie', 'sáb'][d.getDay()] + ' ' + p[2] + '/' + p[1]; }
    function textoHoras(d, h) {
        if (!d && !h) return 'sin horas indicadas';
        return [d ? 'ingreso aprox. ' + d : null, h ? 'salida aprox. ' + h : null].filter(Boolean).join(' · ');
    }
    // ini: lista de días «AAAA-MM-DD» ya elegidos. Se guardan como tramos (un rango o un día suelto) y cada tramo se quita de una vez.
    function selectorDias(ini, hd, hh) {
        var tramos = [];   // {f: ['AAAA-MM-DD', ...], t: texto}
        var corr = null;
        (ini || []).slice().sort().forEach(function (f) { if (corr && sumaDias(corr.f[corr.f.length - 1], 1) === f) corr.f.push(f); else if (!corr || corr.f[corr.f.length - 1] !== f) { corr = { f: [f] }; tramos.push(corr); } });
        tramos.forEach(function (t) { t.t = t.f.length === 1 ? nombreDia(t.f[0]) : 'Del ' + nombreDia(t.f[0]) + ' al ' + nombreDia(t.f[t.f.length - 1]) + ' (' + t.f.length + ' días)'; });
        // Filtros del rango (se cruzan): frecuencia × fines de semana. getDay: 0 dom ... 6 sáb
        var FRECUENCIAS = [['todos', 'Todos los días', null], ['lmv', 'Interdiario desde lunes (lun, mié, vie)', [1, 3, 5]], ['mjs', 'Interdiario desde martes (mar, jue, sáb)', [2, 4, 6]]];
        var FINES = [['incl', 'Incluidos', null], ['sin', 'Sin fines de semana', [1, 2, 3, 4, 5]], ['sab', 'Con sábados (sin domingos)', [1, 2, 3, 4, 5, 6]]];
        var frec = el('select'); FRECUENCIAS.forEach(function (p) { frec.appendChild(el('option', { value: p[0], text: p[1] })); });
        var fines = el('select'); FINES.forEach(function (p) { fines.appendChild(el('option', { value: p[0], text: p[1] })); });
        function diaSemana(f) { var p = f.split('-'); return new Date(Number(p[0]), Number(p[1]) - 1, Number(p[2])).getDay(); }
        var desde = el('input', { type: 'date', min: hoy() }), hasta = el('input', { type: 'date', min: hoy() }), suelto = el('input', { type: 'date', min: hoy() });
        var horaD = el('input', { type: 'time' }), horaH = el('input', { type: 'time' }); horaD.value = hd || ''; horaH.value = hh || '';
        var msg = el('p', { class: 'field-h' }), lista = el('ul', { class: 'dias-lista' }), total = el('p', { class: 'field-h' }), quitarTodos = el('button', { type: 'button', class: 'btn btn-sm btn-danger-o', text: 'Quitar todos' });
        function expandir() {
            var set = {};
            tramos.forEach(function (t) { t.f.forEach(function (f) { set[f] = true; }); });
            return Object.keys(set).sort();
        }
        function pintar() {
            lista.textContent = '';
            tramos.slice().sort(function (x, y) { return x.f[0] < y.f[0] ? -1 : 1; }).forEach(function (t) {
                var x = el('button', { type: 'button', class: 'btn btn-sm', 'aria-label': 'Quitar este tramo', text: 'Quitar' });
                x.addEventListener('click', function () { tramos = tramos.filter(function (y) { return y !== t; }); msg.textContent = ''; pintar(); });
                lista.appendChild(el('li', {}, [el('span', { text: t.t }), x]));
            });
            if (!tramos.length) lista.appendChild(el('li', { class: 'field-h', text: 'Aún no agregó ningún día.' }));
            var nt = expandir().length;
            total.textContent = nt ? 'Total: ' + nt + (nt === 1 ? ' día' : ' días') : '';
            quitarTodos.hidden = tramos.length < 2;
        }
        function agregar(fechas, texto) {
            var antes = expandir().length;
            tramos.push({ f: fechas, t: texto });
            var despues = expandir().length;
            if (despues > DIAS_MAX) { tramos.pop(); msg.textContent = 'Máximo ' + DIAS_MAX + ' días por solicitud.'; return false; }
            if (despues === antes) { tramos.pop(); msg.textContent = 'Esos días ya estaban en la lista.'; return false; }
            msg.textContent = ''; pintar(); return true;
        }
        quitarTodos.addEventListener('click', function () { tramos = []; msg.textContent = ''; pintar(); });
        var bRango = el('button', { type: 'button', class: 'btn btn-sm', text: 'Agregar rango' }), bDia = el('button', { type: 'button', class: 'btn btn-sm', text: 'Agregar día' });
        bRango.addEventListener('click', function () {
            if (!desde.value || !hasta.value) { msg.textContent = 'Indique el primer y el último día del rango.'; return; }
            if (desde.value < hoy()) { msg.textContent = 'No se admiten días anteriores a hoy.'; return; }
            if (hasta.value < desde.value) { msg.textContent = 'El último día no puede ser anterior al primero.'; return; }
            var pf = FRECUENCIAS.filter(function (p) { return p[0] === frec.value; })[0], pw = FINES.filter(function (p) { return p[0] === fines.value; })[0], fs = [], f = desde.value;
            while (f <= hasta.value && fs.length <= 400) {
                var dw = diaSemana(f);
                if ((!pf[2] || pf[2].indexOf(dw) >= 0) && (!pw[2] || pw[2].indexOf(dw) >= 0)) fs.push(f);
                f = sumaDias(f, 1);
            }
            if (!fs.length) { msg.textContent = 'En ese rango no hay días con los filtros elegidos.'; return; }
            var filtros = [pf[2] ? pf[1].split(' (')[0] : null, pw[2] ? pw[1] : null].filter(Boolean).join(', ');
            var tx = 'Del ' + nombreDia(desde.value) + ' al ' + nombreDia(hasta.value) + (filtros ? ' · ' + filtros : '') + ' (' + fs.length + (fs.length === 1 ? ' día)' : ' días)');
            if (agregar(fs, tx)) { desde.value = ''; hasta.value = ''; frec.value = 'todos'; fines.value = 'incl'; }
        });
        bDia.addEventListener('click', function () {
            if (!suelto.value) { msg.textContent = 'Elija el día que desea agregar.'; return; }
            if (suelto.value < hoy()) { msg.textContent = 'No se admiten días anteriores a hoy.'; return; }
            if (agregar([suelto.value], nombreDia(suelto.value))) suelto.value = '';
        });
        pintar();
        var izq = el('div', { class: 'stack' }, [
            campo('Rango: desde', desde), campo('Rango: hasta', hasta), campo('Frecuencia del rango', frec), campo('Fines de semana', fines), el('div', {}, [bRango]),
            campo('Día suelto', suelto), el('div', {}, [bDia])]);
        var der = el('div', { class: 'field' }, [el('span', { class: 'field-l', text: 'Días autorizados *' }), lista, total, el('div', {}, [quitarTodos]), msg]);
        var nodo = el('div', { class: 'stack' }, [
            el('div', { class: 'dias-sel' }, [izq, der]),
            el('div', { class: 'grid g2' }, [campo('Hora de ingreso aproximada (opcional)', horaD), campo('Hora de salida aproximada (opcional)', horaH, 'Es solo referencia para Vigilancia: no restringe el ingreso ni la salida. Se aplica a todos los días.')])
        ]);
        return { nodo: nodo, dias: expandir, horaDesde: function () { return horaD.value; }, horaHasta: function () { return horaH.value; } };
    }

    // v: valores iniciales {fecha,hora,empresa,responsableId,responsable,motivoId,motivoDetalle,observaciones,zonasIds,copias,
    //    tipoId,sedeId,cochera,placa,areaDetalle,contactoNombre,contactoTelefonos,contactoCorreos}
    // modo: 'crear' (tipo y sede se eligen) | 'editar' (tipo y sede quedan fijos, solo se muestran).
    // El tipo de ingreso decide qué campos se muestran y cuáles se envían (Entrega H): los datos de un tipo no pasan al otro.
    function formDatos(op, urlResp, v, modo) {
        v = v || {};
        var editar = modo === 'editar';
        var CONTRATISTA = 'CONTRATISTA';

        // ── Tipo de ingreso y sede ──
        var usables = op.tipos.filter(function (t) { return t.usable; });
        var tipoSel = el('select');
        op.tipos.forEach(function (t) {
            var o = el('option', { value: String(t.id), text: t.texto + (t.usable ? '' : ' — ' + (t.leyenda || 'Próximamente')) });
            if (!t.usable) o.disabled = true;
            tipoSel.appendChild(o);
        });
        var tipoIni = op.tipos.filter(function (t) { return t.id === v.tipoId && (t.usable || editar); })[0] || usables[0];
        tipoSel.value = tipoIni ? String(tipoIni.id) : '';
        var tipoAyuda = el('span', { class: 'field-h' });
        var sedeSel = el('select');
        op.sedes.forEach(function (s) { sedeSel.appendChild(el('option', { value: String(s.id), text: s.texto })); });
        var sedeIni = op.sedes.filter(function (s) { return s.id === v.sedeId; })[0] || (editar ? { id: v.sedeId, texto: v.sede || '', cochera: !!v.cochera, zonas: [] } : op.sedes[0]);
        if (!op.sedes.some(function (s) { return s.id === sedeIni.id; })) { op.sedes.push(sedeIni); sedeSel.appendChild(el('option', { value: String(sedeIni.id), text: sedeIni.texto })); }
        sedeSel.value = String(sedeIni.id);
        if (editar) { tipoSel.disabled = true; sedeSel.disabled = true; }
        function tipoActual() { return op.tipos.filter(function (t) { return String(t.id) === tipoSel.value; })[0] || { id: 0, codigo: '', texto: '' }; }
        function sedeActual() { return op.sedes.filter(function (s) { return String(s.id) === sedeSel.value; })[0] || { id: 0, texto: '', cochera: false, zonas: [] }; }
        function esContratista() { return tipoActual().codigo === CONTRATISTA; }
        function esProveedor() { return tipoActual().codigo === 'PROVEEDOR'; }

        // ── Campos comunes ──
        var fecha = el('input', { type: 'date', min: hoy() }); fecha.value = v.fecha || '';
        var hora = el('input', { type: 'time' }); hora.value = v.hora || '';
        // D-227: el contratista se solicita por días (franja). Al editar una solicitud que ya tiene días, se muestran y no se cambian.
        var diasFijos = editar && (v.dias || []).length > 0;
        var selDias = selectorDias(v.dias && !editar ? v.dias.map(function (d) { return d.fecha; }) : [], '', '');
        function usaDias() { return esContratista() && !diasFijos && !(editar && !(v.dias || []).length); }
        var empresa = texto(v.empresa, 250, '');
        var motivo = el('select'); motivo.appendChild(el('option', { value: '', text: 'Elija el motivo' }));
        op.motivos.forEach(function (m) { motivo.appendChild(el('option', { value: String(m.id), text: m.texto })); });
        motivo.value = v.motivoId && op.motivos.some(function (m) { return m.id === v.motivoId; }) ? String(v.motivoId) : '';
        var detalle = texto(esContratista() ? '' : v.motivoDetalle, 250, 'Describa el motivo');
        var detalleCampo = campo('Detalle del motivo *', detalle);
        var obs = el('textarea', { rows: '2', maxlength: '500', placeholder: 'Opcional. Se incluye en el correo que reciben Coordinación, Vigilancia y las personas en copia' }); obs.value = v.observaciones || '';
        var sugEmpresa = sugerencias(empresa, 2, function (q) {
            return CAF.pedir(urlResp.replace(/Responsables$/, 'Empresas') + '?q=' + encodeURIComponent(q)).then(function (r) {
                return r.success ? r.data.map(function (e) { return { t: e, v: e }; }) : [];
            });
        }, function (e) { empresa.value = e; });
        var urlCorreos = urlResp.replace(/Responsables$/, 'Correos');
        var copias = chipsCorreo(v.copias, urlCorreos, 'Escriba un correo o nombre y elija de la lista');

        function sincMotivo() {
            var m = op.motivos.filter(function (x) { return String(x.id) === motivo.value; })[0];
            detalleCampo.hidden = !(m && m.esOtro);
        }
        motivo.addEventListener('change', sincMotivo); sincMotivo();

        // ── Campos del contratista ──
        var actividades = el('textarea', { rows: '3', maxlength: '250', placeholder: 'Ej.: mantenimiento de aire acondicionado, cableado de red…' }); actividades.value = esContratista() ? (v.motivoDetalle || '') : '';
        var areaDetalle = texto(v.areaDetalle, 300, 'Opcional. Ej.: sala de servidores, segundo piso');
        var cNombre = texto(v.contactoNombre, 200, 'Persona de contacto de la empresa contratista');
        var cTel = texto(v.contactoTelefonos, 100, '999 111 222; 01 555 0000');
        var cCorreos = chipsCorreo(v.contactoCorreos, urlResp.replace(/Responsables$/, 'Correos'), 'contacto@contratista.com');

        // ── Proveedor de abastecimiento (D-223): empresa que recibe y responsable de la entrega (contacto). Los datos de cada
        //    transportista se piden en el paso «Personas». No tiene responsable de atención (lo define Almacén), zonas ni cochera. ──
        var grupo = el('select'); grupo.appendChild(el('option', { value: '', text: 'Elija la empresa del grupo' }));
        (op.empresasGrupo || []).forEach(function (g) { grupo.appendChild(el('option', { value: String(g.id), text: g.texto })); });
        grupo.value = v.empresaDestinoId && (op.empresasGrupo || []).some(function (g) { return g.id === v.empresaDestinoId; }) ? String(v.empresaDestinoId) : '';
        var pNombre = texto(v.contactoNombre, 200, 'Quién responde por esta entrega');
        var pTel = texto(v.contactoTelefonos, 100, '999 111 222');

        // ── Cochera ──
        var cochera = el('select', {}, [el('option', { value: 'N', text: 'No' }), el('option', { value: 'Y', text: 'Sí' })]);
        cochera.value = v.cochera ? 'Y' : 'N';
        var placa = texto(v.placa, 8, 'Ej.: ABC123'); placa.style.textTransform = 'uppercase';
        var placaCampo = campo('Placa del vehículo *', placa, 'De 5 a 8 letras o números.');
        var cocheraBloque = el('div', { class: 'grid g2' }, [campo('¿Requiere cochera?', cochera), placaCampo]);
        function sincCochera() { placaCampo.hidden = cochera.value !== 'Y'; }
        cochera.addEventListener('change', sincCochera); sincCochera();

        // ── Responsable de atención: se busca desde 2 letras ──
        var resp = { id: v.responsableId || 0, nombre: v.responsable || '' };
        var caja = el('div'), busca = texto('', 80, 'Escriba 2 letras del nombre'), sug = el('div', { class: 'sug' }), temp = null;
        sug.hidden = true;
        function pintarResp() {
            caja.textContent = '';
            if (resp.id) {
                caja.appendChild(el('div', { class: 'sel-box' }, [el('span', { text: resp.nombre }),
                    el('button', { type: 'button', class: 'btn btn-sm', text: 'Cambiar', onclick: function () { resp = { id: 0, nombre: '' }; pintarResp(); } })]));
            } else { caja.appendChild(busca); caja.appendChild(sug); }
        }
        busca.addEventListener('input', function () {
            clearTimeout(temp);
            var q = busca.value.trim();
            if (q.length < 2) { sug.hidden = true; return; }
            temp = setTimeout(function () {
                CAF.pedir(urlResp + '?q=' + encodeURIComponent(q)).then(function (r) {
                    sug.textContent = ''; sug.hidden = false;
                    if (!r.success || !r.data.length) { sug.appendChild(el('p', { class: 'vacio', text: 'Nadie coincide. Si no aparece, pida que lo agreguen en Personal.' })); return; }
                    r.data.forEach(function (p) {
                        sug.appendChild(el('button', { type: 'button', text: p.nombre + (p.area ? ' — ' + p.area : ''), onclick: function () { resp = { id: p.id, nombre: p.nombre }; pintarResp(); } }));
                    });
                });
            }, 250);
        });
        pintarResp();

        // ── Zonas (dependen de la sede) ──
        var zonasSel = {}; (v.zonasIds || []).forEach(function (id) { zonasSel[id] = true; });
        var aviso = el('div', { class: 'aviso a-warn' }); aviso.hidden = true;
        var zonasLegend = el('legend');
        var zonasNodo = el('fieldset', { class: 'zonas' }, [zonasLegend]);
        function sincZonas() {
            var sctr = false, epp = false;
            sedeActual().zonas.forEach(function (z) { if (zonasSel[z.id]) { sctr = sctr || z.sctr; epp = epp || z.epp; } });
            aviso.hidden = !(sctr || epp);
            aviso.textContent = (sctr || epp) ? 'Para estas zonas Vigilancia verificará ' + [sctr ? 'el SCTR' : '', epp ? 'el uso de EPP' : ''].filter(Boolean).join(' y ') + ' al ingreso.' : '';
        }
        function pintarZonas() {
            while (zonasNodo.childNodes.length > 1) zonasNodo.removeChild(zonasNodo.lastChild);
            zonasLegend.textContent = esContratista() ? 'Área donde se ejecutará el trabajo *' : 'Zonas que visitarán *';
            var zs = sedeActual().zonas;
            Object.keys(zonasSel).forEach(function (k) { if (!zs.some(function (z) { return String(z.id) === k; })) delete zonasSel[k]; });
            zs.forEach(function (z) {
                var chk = el('input', { type: 'checkbox' }); chk.checked = !!zonasSel[z.id];
                var fila = el('label', { class: 'zona' + (chk.checked ? ' on' : '') }, [chk, el('span', { text: z.texto })]);
                chk.addEventListener('change', function () { zonasSel[z.id] = chk.checked; fila.classList.toggle('on', chk.checked); sincZonas(); });
                zonasNodo.appendChild(fila);
            });
            if (!zs.length) zonasNodo.appendChild(el('p', { class: 'vacio', text: 'Esta sede no tiene zonas configuradas. Pida al administrador que las agregue en Catálogos.' }));
            sincZonas();
        }

        // ── Diseño según el tipo ──
        var nodo = el('div', { class: 'stack' });
        function armar() {
            var c = esContratista(), t = tipoActual();
            tipoAyuda.textContent = editar ? 'El tipo de ingreso y la sede no se pueden cambiar. Si se equivocó, cancele y cree otra solicitud.' : '';
            nodo.textContent = '';
            nodo.appendChild(el('div', { class: 'grid g2' }, [campo('Tipo de ingreso *', tipoSel, editar ? null : (t.codigo ? null : 'Elija el tipo de ingreso.')), campo('Sede *', sedeSel)]));
            if (editar) nodo.appendChild(tipoAyuda);
            if (c && diasFijos) {
                var hd = textoHoras(v.dias[0].desde, v.dias[0].hasta);
                nodo.appendChild(el('div', { class: 'field' }, [el('span', { class: 'field-l', text: 'Días autorizados' }),
                    el('p', { text: v.dias.map(function (x) { return nombreDia(x.fecha); }).join(', ') + ' · ' + hd }),
                    el('span', { class: 'field-h', text: 'Los días no se cambian. Si se equivocó, cancele la solicitud y cree otra.' })]));
            } else if (usaDias()) {
                nodo.appendChild(selDias.nodo);
            } else {
                nodo.appendChild(el('div', { class: 'grid g2' }, [campo(c ? 'Fecha del servicio *' : esProveedor() ? 'Fecha de la entrega *' : 'Fecha de la visita *', fecha), campo(c ? 'Hora prevista del servicio *' : 'Hora prevista *', hora)]));
            }
            var prov = esProveedor();
            empresa.placeholder = c ? 'Nombre de la empresa contratista' : prov ? 'Empresa proveedora que realiza la entrega' : 'Empresa o procedencia de los visitantes';
            nodo.appendChild(campo(c ? 'Empresa contratista *' : prov ? 'Empresa proveedora *' : 'Empresa o procedencia *', el('div', { class: 'sug-wrap' }, [empresa, sugEmpresa])));
            if (esProveedor()) {
                nodo.appendChild(campo('Empresa del grupo que recibe la entrega *', grupo));
                nodo.appendChild(el('h4', { text: 'Responsable de la entrega' }));
                nodo.appendChild(el('p', { class: 'field-h', text: 'Persona de contacto de esta entrega: quien necesite comunicarse (Vigilancia, Almacén, Coordinación) la llamará a ella. No tiene que ser el transportista.' }));
                nodo.appendChild(el('div', { class: 'grid g2' }, [campo('Nombre del responsable *', pNombre), campo('Teléfono *', pTel, 'Mínimo 6 dígitos. Varios, separados por «;».')]));
                nodo.appendChild(campo('Detalles adicionales (opcional)', obs));
                nodo.appendChild(campo('Correos en copia (opcional)', copias, 'Reciben copia de los avisos de la solicitud.'));
                return;
            }
            nodo.appendChild(el('div', { class: 'field' }, [el('span', { class: 'field-l', text: c ? 'Responsable de atención (opcional)' : 'Responsable de atención *' }), caja]));
            if (c) {
                nodo.appendChild(campo('Actividad(es) a realizar *', actividades));
                nodo.appendChild(zonasNodo); nodo.appendChild(aviso);
                nodo.appendChild(campo('Detalle del área (opcional)', areaDetalle));
                nodo.appendChild(el('h4', { text: 'Contacto de la empresa contratista' }));
                nodo.appendChild(el('div', { class: 'grid g3' }, [campo('Nombre del contacto *', cNombre), campo('Teléfonos *', cTel, 'Varios, separados por «;».'), campo('Correos *', cCorreos, 'Varios correos, uno por etiqueta. No se copian solos a los avisos.')]));
            } else {
                nodo.appendChild(el('div', { class: 'grid g2' }, [campo('Motivo de la visita *', motivo), detalleCampo]));
                nodo.appendChild(zonasNodo); nodo.appendChild(aviso);
            }
            if (sedeActual().cochera) nodo.appendChild(cocheraBloque);
            nodo.appendChild(campo('Detalles adicionales (opcional)', obs));
            nodo.appendChild(campo('Correos en copia (opcional)', copias, 'Reciben copia de los avisos de la solicitud (nueva, decisiones, cancelación). Escriba 2 letras para ver usuarios y correos usados antes; Enter agrega un correo y la × lo quita.'));
            pintarZonas();
        }
        tipoSel.addEventListener('change', armar);
        sedeSel.addEventListener('change', armar);
        armar();

        function leer() {
            var c = esContratista(), p = esProveedor(), conCochera = !p && sedeActual().cochera && cochera.value === 'Y';
            return {
                tipoId: Number(tipoSel.value) || 0, tipoCodigo: tipoActual().codigo, tipoTexto: tipoActual().texto, sedeId: Number(sedeSel.value) || 0, sedeTexto: sedeActual().texto,
                fecha: usaDias() ? (selDias.dias()[0] || '') : diasFijos ? v.fecha : fecha.value, hora: usaDias() ? '00:00' : diasFijos ? v.hora : hora.value,
                dias: usaDias() ? selDias.dias() : [], horaDesde: usaDias() ? selDias.horaDesde() : '', horaHasta: usaDias() ? selDias.horaHasta() : '',
                empresa: empresa.value, responsableId: resp.id, responsable: resp.nombre,
                motivoId: c || p ? null : (motivo.value ? Number(motivo.value) : null),
                motivoDetalle: p ? '' : c ? actividades.value : detalle.value, observaciones: obs.value,
                zonasIds: p ? [] : sedeActual().zonas.filter(function (z) { return zonasSel[z.id]; }).map(function (z) { return z.id; }), copias: copias.value,
                empresaDestinoId: p && grupo.value ? Number(grupo.value) : null, empresaDestino: p ? (grupo.options[grupo.selectedIndex] || {}).text || '' : '',
                cochera: conCochera, placa: conCochera ? placa.value.toUpperCase().replace(/[\s-]/g, '') : '',
                areaDetalle: c ? areaDetalle.value : '', contactoNombre: c ? cNombre.value : p ? pNombre.value : '', contactoTelefonos: c ? cTel.value : p ? pTel.value : '', contactoCorreos: c ? cCorreos.value : ''
            };
        }
        // Validación mínima de formulario; las reglas de fondo las valida el servidor.
        function validar() {
            var d = leer(), c = esContratista();
            if (!d.tipoId) return 'Elija el tipo de ingreso.';
            if (!d.sedeId) return 'Elija la sede.';
            if (usaDias()) {
                if (!d.dias.length) return 'Elija al menos un día de trabajo.';
                if (d.horaDesde && d.horaHasta && d.horaHasta <= d.horaDesde) return 'La hora de salida debe ser posterior a la de ingreso.';
            } else if (!d.fecha || !d.hora) return c ? 'Indique la fecha y la hora del servicio.' : 'Indique la fecha y la hora de la visita.';
            if (!usaDias() && !diasFijos && d.fecha < hoy()) return c ? 'La fecha del servicio no puede ser anterior a hoy.' : 'La fecha de la visita no puede ser anterior a hoy.';
            if (!d.empresa.trim()) return c ? 'Indique la empresa contratista.' : esProveedor() ? 'Indique la empresa proveedora.' : 'Indique la empresa o procedencia.';
            if (esProveedor()) {
                if (!sedeActual().proveedor && !editar) return 'Esa sede no recibe proveedores de abastecimiento. Elija otra sede.';
                if (!d.empresaDestinoId) return 'Elija la empresa del grupo que recibe la entrega.';
                if (!d.contactoNombre.trim()) return 'Indique el nombre del responsable de la entrega.';
                if (d.contactoTelefonos.replace(/\D/g, '').length < 6) return 'Indique el teléfono del responsable de la entrega (mínimo 6 dígitos).';
                return '';
            }
            if (!d.responsableId && !c) return 'Elija al responsable de atención.';
            if (c) {
                if (!d.motivoDetalle.trim()) return 'Describa la(s) actividad(es) a realizar.';
            } else {
                if (!d.motivoId) return 'Elija el motivo de la visita.';
                if (!detalleCampo.hidden && !d.motivoDetalle.trim()) return 'Describa el motivo de la visita.';
            }
            if (!d.zonasIds.length) return c ? 'Marque al menos un área de trabajo.' : 'Marque al menos una zona.';
            if (c) {
                if (!d.contactoNombre.trim()) return 'Indique el nombre del contacto de la empresa contratista.';
                if (d.contactoTelefonos.replace(/\D/g, '').length < 6) return 'Indique al menos un teléfono de contacto.';
                if (!d.contactoCorreos.trim()) return 'Indique al menos un correo de contacto.';
            }
            if (d.cochera && d.placa.length < 5) return 'Indique la placa del vehículo (de 5 a 8 letras o números).';
            return '';
        }
        return { nodo: nodo, leer: leer, validar: validar };
    }

    // ── Persona externa ──────────────────────────────────────────────────────────────────────
    // ini: persona a editar {tipoDocId, doc, apellidoPaterno, apellidoMaterno, nombres} (opcional).
    // Devuelve {nodo, guardar()}; guardar() registra/corrige la persona y entrega {id, nombreCompleto, doc} a la promesa.
    function formPersona(op, urlBuscar, urlGuardar, ini) {
        ini = ini || {};
        var tipo = el('select'); op.tiposDoc.forEach(function (t) { tipo.appendChild(el('option', { value: String(t.id), text: t.texto })); });
        tipo.value = String(ini.tipoDocId || (op.tiposDoc[0] && op.tiposDoc[0].id) || '');
        var doc = texto(ini.doc, 20, 'Número de documento');
        var ap = texto(ini.apellidoPaterno, 100), am = texto(ini.apellidoMaterno, 100), nom = texto(ini.nombres, 200);
        var nota = el('p', { class: 'field-h' });
        var hallada = null;
        var auto = false; // true cuando los nombres vinieron de una persona ya registrada

        // Si cambia el documento tras un autocompletado, esos nombres ya no corresponden: se limpian.
        function limpiarAuto() {
            if (!auto) return;
            auto = false; hallada = null; ap.value = ''; am.value = ''; nom.value = ''; nota.textContent = '';
        }
        function buscar() {
            limpiarAuto(); hallada = null; nota.textContent = '';
            if (doc.value.trim().length < 4) return;
            CAF.pedir(urlBuscar + '?tipoDocId=' + encodeURIComponent(tipo.value) + '&doc=' + encodeURIComponent(doc.value.trim())).then(function (r) {
                if (!r.success || !r.data) { if (r.success) nota.textContent = 'No está registrada: complete sus datos y quedará registrada.'; return; }
                hallada = r.data; auto = true; ap.value = r.data.apellidoPaterno || ''; am.value = r.data.apellidoMaterno || ''; nom.value = r.data.nombres || '';
                nota.textContent = 'Ya está registrada. Si su nombre está mal, corríjalo aquí y se actualizará.';
            });
        }
        doc.addEventListener('input', limpiarAuto); doc.addEventListener('change', buscar); tipo.addEventListener('change', buscar);
        if (ini.doc) hallada = { id: ini.id || 0 };

        // Autocompletar por nombre: al elegir una persona registrada se llenan documento y nombres.
        var sugPersona = sugerencias(ap, 3, function (q) {
            return CAF.pedir(urlBuscar.replace(/PersonaPorDocumento$/, 'PersonasBuscar') + '?q=' + encodeURIComponent(q)).then(function (r) {
                return r.success ? r.data.map(function (p) { return { t: p.nombreCompleto, s: (p.tipoDoc || '') + ' ' + p.doc, v: p }; }) : [];
            });
        }, function (p) {
            tipo.value = String(p.tipoDocId); doc.value = p.doc;
            hallada = { id: p.id, apellidoPaterno: p.apellidoPaterno, apellidoMaterno: p.apellidoMaterno, nombres: p.nombres, nombreCompleto: p.nombreCompleto };
            auto = true; ap.value = p.apellidoPaterno || ''; am.value = p.apellidoMaterno || ''; nom.value = p.nombres || '';
            nota.textContent = 'Ya está registrada. Si su nombre está mal, corríjalo aquí y se actualizará.';
        });
        var nodo = el('div', { class: 'stack pform' }, [
            el('div', { class: 'grid g2' }, [campo('Tipo de documento', tipo), campo('Número *', doc)]),
            el('div', { class: 'grid g3' }, [campo('Apellido paterno *', el('div', { class: 'sug-wrap' }, [ap, sugPersona]), 'Escriba 3 letras para ver personas ya registradas.'), campo('Apellido materno', am), campo('Nombres *', nom)]),
            nota
        ]);

        function guardar() {
            if (!doc.value.trim() || !ap.value.trim() || !nom.value.trim()) return Promise.resolve({ success: false, message: 'Complete el documento, el apellido paterno y los nombres.' });
            var id = hallada && hallada.id ? hallada.id : 0;
            var sinCambios = hallada && hallada.id && hallada.apellidoPaterno === ap.value.trim() && (hallada.apellidoMaterno || '') === am.value.trim() && hallada.nombres === nom.value.trim();
            if (sinCambios) return Promise.resolve({ success: true, data: { id: id, nombreCompleto: hallada.nombreCompleto, doc: doc.value.trim() } });
            return CAF.pedir(urlGuardar, { method: 'POST', body: { id: id, tipoDocId: Number(tipo.value) || 0, doc: doc.value, apellidoPaterno: ap.value, apellidoMaterno: am.value, nombres: nom.value } });
        }
        // Antes de guardar se consulta el documento por si la persona ya existe aunque no se haya salido del campo.
        function listo() {
            if (hallada || doc.value.trim().length < 4) return guardar();
            return CAF.pedir(urlBuscar + '?tipoDocId=' + encodeURIComponent(tipo.value) + '&doc=' + encodeURIComponent(doc.value.trim())).then(function (r) {
                if (r.success && r.data) {
                    hallada = r.data;
                    if (!ap.value.trim() && !nom.value.trim()) { auto = true; ap.value = r.data.apellidoPaterno || ''; am.value = r.data.apellidoMaterno || ''; nom.value = r.data.nombres || ''; }
                }
                return guardar();
            });
        }
        return { nodo: nodo, guardar: listo };
    }

    // Filtro por tipo de solicitud (solo en pantalla; las consultas al servidor no cambian). Muestra una casilla por cada tipo
    // que llegó en los datos, así que cada persona ve solo los tipos que su licencia le permite. Con un solo tipo no se muestra.
    // clave: nombre de la pantalla (recuerda la elección en este navegador). Marcado = se ve; no se puede quitar el último.
    function filtroTipos(clave, despuesDe, alCambiar) {
        var ALM = 'caf.tipos.' + clave, quitados = {}, vistos = [];
        try { var g = JSON.parse(localStorage.getItem(ALM) || '[]'); if (Array.isArray(g)) g.forEach(function (t) { quitados[t] = true; }); } catch (e) { /* sin almacenamiento */ }
        var caja = el('div', { class: 'filtro-tipos', hidden: '' });
        despuesDe.parentNode.insertBefore(caja, despuesDe.nextSibling);
        function guardar() { try { localStorage.setItem(ALM, JSON.stringify(Object.keys(quitados))); } catch (e) { /* sin almacenamiento */ } }
        function pintar() {
            caja.textContent = '';
            caja.hidden = vistos.length < 2;
            if (caja.hidden) return;
            caja.appendChild(el('span', { class: 'field-l', text: 'Tipo de solicitud' }));
            vistos.forEach(function (t) {
                var c = el('input', { type: 'checkbox' }); c.checked = !quitados[t];
                c.addEventListener('change', function () {
                    if (!c.checked && vistos.filter(function (x) { return !quitados[x]; }).length <= 1) { c.checked = true; return; }
                    if (c.checked) delete quitados[t]; else quitados[t] = true;
                    guardar(); alCambiar();
                });
                caja.appendChild(el('label', { class: 'chk' }, [c, el('span', { text: t })]));
            });
        }
        return {
            // Anota los tipos que llegaron (una vez cada uno) y vuelve a pintar las casillas si apareció uno nuevo.
            registrar: function (tipos) {
                var nuevo = false;
                tipos.forEach(function (t) { if (t && vistos.indexOf(t) < 0) { vistos.push(t); nuevo = true; } });
                if (nuevo) { vistos.sort(); pintar(); }
            },
            pasa: function (t) { return !t || !quitados[t]; }
        };
    }

    // Proveedor (D-223): tarjetas de los transportistas de una solicitud (detalle del solicitante y revisión del Coordinador).
    // lista = [{principal,nombrePersona,tipoDoc,doc,ruc,nombre,direccion,placa,marca,licencia,completos}]
    function transportistasNodo(lista) {
        var CAMPOS = [['ruc', 'RUC'], ['nombre', 'Transportista'], ['direccion', 'Dirección'], ['placa', 'Placa'], ['marca', 'Marca'], ['licencia', 'Licencia']];
        var caja = el('div', { class: 'stack' }, [el('h3', { text: 'Transportistas (' + (lista || []).length + ')' })]);
        if (!lista || !lista.length) { caja.appendChild(el('p', { class: 'vacio', text: 'Sin transportistas registrados.' })); return caja; }
        caja.appendChild(el('ul', { class: 'plist' }, lista.map(function (t) {
            var datos = CAMPOS.filter(function (c) { return t[c[0]]; }).map(function (c) { return c[1] + ': ' + t[c[0]]; }).join(' · ');
            return el('li', {}, [el('div', { class: 'plist-m' }, [
                el('div', { class: 'pn', text: t.nombrePersona + (t.principal ? ' (principal)' : '') }),
                el('div', { class: 'field-h', text: (t.tipoDoc ? t.tipoDoc + ' ' : '') + (t.doc || '') }),
                el('div', { class: 'field-h', text: datos || 'Sin datos de transportista aquí: constan en los documentos adjuntos.' }),
                t.completos ? null : (datos ? el('div', { class: 'field-h', text: 'Los datos que faltan constan en los documentos adjuntos.' }) : null)])]);
        })));
        return caja;
    }

    return { textoHoras: textoHoras, selectorDias: selectorDias, nombreDia: nombreDia, transportistasNodo: transportistasNodo, filtroTipos: filtroTipos, el: el, chipEstado: chipEstado, chipPersona: chipPersona, textoIngreso: textoIngreso, hoy: hoy, fechaLarga: fechaLarga, campo: campo,
             errores: errores, cargarOpciones: cargarOpciones, formDatos: formDatos, formPersona: formPersona };
})();

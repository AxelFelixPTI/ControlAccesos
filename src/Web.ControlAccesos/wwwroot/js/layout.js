// Menú lateral en pantallas angostas y botón de tema claro/oscuro.
(function () {
    var lateral = document.getElementById('lateral');
    var boton = document.getElementById('menu-t');
    if (lateral && boton) boton.addEventListener('click', function () { lateral.classList.toggle('open'); });

    // Rol activo: al elegir otro rol se envía el formulario (solo cambia el menú; D-176).
    var rolSel = document.getElementById('rol-sel');
    if (rolSel && rolSel.form) rolSel.addEventListener('change', function () { rolSel.form.submit(); });

    var tema = document.getElementById('btn-tema');
    if (tema) tema.addEventListener('click', function () {
        var nuevo = document.documentElement.getAttribute('data-theme') === 'dark' ? 'light' : 'dark';
        document.documentElement.setAttribute('data-theme', nuevo);
        try { localStorage.setItem('caf.tema', nuevo); } catch (e) { }
    });
})();

// Ojito para ver u ocultar cualquier campo de contraseña (login, definir y cambiar contraseña).
(function () {
    var OJO = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/></svg>';
    var OJO_TACHADO = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M17.94 17.94A10.9 10.9 0 0 1 12 19c-6.5 0-10-7-10-7a18.4 18.4 0 0 1 5.06-5.94M9.9 4.24A10.4 10.4 0 0 1 12 4c6.5 0 10 7 10 7a18.5 18.5 0 0 1-2.16 3.19M1 1l22 22"/><path d="M14.12 14.12A3 3 0 1 1 9.88 9.88"/></svg>';
    var campos = document.querySelectorAll('input[type=password]');
    Array.prototype.forEach.call(campos, function (inp) {
        var envoltura = document.createElement('span');
        envoltura.className = 'pw-wrap';
        inp.parentNode.insertBefore(envoltura, inp);
        envoltura.appendChild(inp);
        var b = document.createElement('button');
        b.type = 'button'; b.className = 'pw-eye';
        b.setAttribute('aria-label', 'Mostrar contraseña'); b.setAttribute('aria-pressed', 'false'); b.title = 'Mostrar contraseña';
        b.innerHTML = OJO;
        b.addEventListener('click', function () {
            var ver = inp.type === 'password';
            inp.type = ver ? 'text' : 'password';
            b.innerHTML = ver ? OJO_TACHADO : OJO;
            b.setAttribute('aria-pressed', ver ? 'true' : 'false');
            b.setAttribute('aria-label', ver ? 'Ocultar contraseña' : 'Mostrar contraseña'); b.title = b.getAttribute('aria-label');
            inp.focus();
        });
        envoltura.appendChild(b);
    });
})();

// Tablas en celular: pone en cada celda su «data-label» (el texto de su encabezado) para que el CSS la muestre como tarjeta (D-177).
// Se vuelve a aplicar cuando el JS de cada pantalla redibuja las filas. Solo escribe textContent/atributos, nunca HTML.
(function () {
    function etiquetar(tabla) {
        var cab = tabla.querySelectorAll('thead th');
        if (!cab.length) return;
        var nombres = Array.prototype.map.call(cab, function (th) { return (th.textContent || '').trim(); });
        Array.prototype.forEach.call(tabla.querySelectorAll('tbody tr'), function (tr) {
            var col = 0;
            Array.prototype.forEach.call(tr.children, function (td) {
                var n = nombres[col] || '';
                if (td.getAttribute('data-label') !== n) td.setAttribute('data-label', n);
                col += td.colSpan || 1;
            });
        });
    }
    function todas() { Array.prototype.forEach.call(document.querySelectorAll('table.tabla'), etiquetar); }
    var pendiente = false;
    function programar() { if (pendiente) return; pendiente = true; requestAnimationFrame(function () { pendiente = false; todas(); }); }
    todas();
    if (window.MutationObserver) new MutationObserver(programar).observe(document.body, { childList: true, subtree: true });
})();


// Tablas: orden por DOBLE CLIC en el encabezado (ascendente/descendente) y registros por página (D-251).
// Funciona sobre las filas que cada pantalla ya dibujó: el filtro y el buscador de la pantalla se aplican ANTES (a todos los registros),
// de modo que la paginación solo reparte lo que ya pasó el filtro y nunca limita la búsqueda. Si la pantalla vuelve a dibujar las filas,
// el orden y la página se reaplican solos. Una celda puede fijar su valor de orden con data-orden. Un encabezado sin texto (acciones) no ordena;
// una tabla con data-sin-paginar no se divide en páginas y con data-sin-orden no se ordena. El tamaño de página se recuerda en este navegador.
(function () {
    'use strict';
    var TAMS = [10, 25, 50, 100], CLAVE = 'caf.tabla.tam', collator = null;
    try { collator = new Intl.Collator('es', { numeric: true, sensitivity: 'base' }); } catch (e) { collator = null; }

    function tamGuardado() { try { var v = parseInt(localStorage.getItem(CLAVE), 10); return TAMS.indexOf(v) >= 0 ? v : 25; } catch (e) { return 25; } }
    function guardarTam(v) { try { localStorage.setItem(CLAVE, String(v)); } catch (e) { /* sin almacenamiento: no pasa nada */ } }

    // Valor ordenable de una celda: número, fecha (con hora si la trae) o texto sin tildes.
    function clave(td) {
        var t = (td ? (td.getAttribute('data-orden') != null ? td.getAttribute('data-orden') : td.textContent) : '').replace(/\s+/g, ' ').trim();
        if (t === '' || t === '—' || t === '-') return { v: null };
        var m = /^(\d{4})-(\d{2})-(\d{2})(?:[ T·]+(\d{1,2}):(\d{2}))?/.exec(t);
        if (m) return { f: true, v: Date.UTC(+m[1], +m[2] - 1, +m[3], +(m[4] || 0), +(m[5] || 0)) };
        m = /^(\d{1,2})\/(\d{1,2})\/(\d{4})(?:[ ·]+(\d{1,2}):(\d{2}))?/.exec(t);
        if (m) return { f: true, v: Date.UTC(+m[3], +m[2] - 1, +m[1], +(m[4] || 0), +(m[5] || 0)) };
        if (/^-?\d+([.,]\d+)?$/.test(t)) return { n: true, v: parseFloat(t.replace(',', '.')) };
        return { s: true, v: t.toLocaleLowerCase('es') };
    }
    function comparar(a, b) {
        if (a.v === null && b.v === null) return 0;
        if (a.v === null) return 1;            // lo vacío va siempre al final
        if (b.v === null) return -1;
        if ((a.n || a.f) && (b.n || b.f)) return a.v - b.v;
        var x = String(a.v), y = String(b.v);
        return collator ? collator.compare(x, y) : (x < y ? -1 : x > y ? 1 : 0);
    }

    function mejorar(tabla) {
        if (tabla.getAttribute('data-mejorada') === '1') return;
        var cuerpo = tabla.tBodies[0], cab = tabla.tHead ? tabla.tHead.rows[0] : null;
        if (!cuerpo || !cab) return;
        tabla.setAttribute('data-mejorada', '1');
        var ths = Array.prototype.slice.call(cab.cells);
        var ordenar = tabla.getAttribute('data-sin-orden') == null, paginar = tabla.getAttribute('data-sin-paginar') == null;
        var st = { col: -1, dir: 1, pag: 1, tam: tamGuardado(), n: -1 }, trabajando = false, pie = null, barra = null, observador = null;

        function datos() {
            return Array.prototype.filter.call(cuerpo.rows, function (tr) {
                return !(tr.cells.length === 1 && (tr.cells[0].colSpan > 1 || tr.cells[0].classList.contains('vacio')));
            });
        }

        // Dos barras con los mismos controles: arriba (a la izquierda «registros por página», a la derecha el paginador) y abajo
        // («Mostrando x a y de z» y el paginador), para cambiar de página desde donde convenga.
        function crearNav() {
            var nav = document.createElement('div'); nav.className = 'tp-nav';
            function boton(txt, titulo, delta) {
                var b = document.createElement('button'); b.type = 'button'; b.className = 'btn btn-sm'; b.textContent = txt; b.title = titulo; b.setAttribute('aria-label', titulo);
                b.addEventListener('click', function () { st.pag = delta === 'ini' ? 1 : delta === 'fin' ? 1e9 : st.pag + delta; aplicar(); });
                return b;
            }
            var pos = document.createElement('span'); pos.className = 'tp-pos';
            nav.appendChild(boton('«', 'Primera página', 'ini')); nav.appendChild(boton('‹', 'Página anterior', -1)); nav.appendChild(pos);
            nav.appendChild(boton('›', 'Página siguiente', 1)); nav.appendChild(boton('»', 'Última página', 'fin'));
            return { nodo: nav, pos: pos, bt: nav.querySelectorAll('button') };
        }

        function construirPie() {
            var info = document.createElement('span'); info.className = 'tp-info';
            var sel = document.createElement('select'); sel.setAttribute('aria-label', 'Registros por página');
            TAMS.forEach(function (n) { var o = document.createElement('option'); o.value = String(n); o.textContent = String(n); sel.appendChild(o); });
            sel.value = String(st.tam);
            sel.addEventListener('change', function () { st.tam = parseInt(sel.value, 10); guardarTam(st.tam); st.pag = 1; aplicar(); });
            var lab = document.createElement('label'); lab.className = 'tp-tam';
            lab.appendChild(sel); lab.appendChild(document.createTextNode(' registros por página'));
            var arriba = crearNav(), abajo = crearNav();
            barra = document.createElement('div'); barra.className = 'tabla-barra'; barra.hidden = true;
            barra.appendChild(lab); barra.appendChild(arriba.nodo);
            pie = document.createElement('div'); pie.className = 'tabla-pie'; pie.hidden = true;
            pie.appendChild(info); pie.appendChild(abajo.nodo);
            pie._info = info; pie._sel = sel; pie._navs = [arriba, abajo];
            var envoltura = tabla.parentNode && tabla.parentNode.classList.contains('tw') ? tabla.parentNode : tabla;
            envoltura.parentNode.insertBefore(barra, envoltura);
            envoltura.parentNode.insertBefore(pie, envoltura.nextSibling);
        }

        function aplicar() {
            trabajando = true;
            try {
                var filas = datos();
                if (filas.length !== st.n) { if (st.n !== -1) st.pag = 1; st.n = filas.length; }
                if (ordenar && st.col >= 0) {
                    var llaves = filas.map(function (tr, i) { return { tr: tr, k: clave(tr.cells[st.col]), i: i }; });
                    llaves.sort(function (a, b) { return (comparar(a.k, b.k) * st.dir) || (a.i - b.i); });
                    llaves.forEach(function (x) { cuerpo.appendChild(x.tr); });
                    filas = llaves.map(function (x) { return x.tr; });
                }
                var total = filas.length, tam = paginar ? st.tam : (total || 1), paginas = Math.max(1, Math.ceil(total / tam));
                if (st.pag > paginas) st.pag = paginas; if (st.pag < 1) st.pag = 1;
                var ini = (st.pag - 1) * tam, fin = ini + tam;
                filas.forEach(function (tr, i) { var oculto = paginar && (i < ini || i >= fin); if (tr.hidden !== oculto) tr.hidden = oculto; });
                if (paginar) {
                    if (!pie) construirPie();
                    barra.hidden = total === 0;
                    pie.hidden = total === 0;
                    pie._info.textContent = total ? 'Mostrando ' + (ini + 1) + ' a ' + Math.min(fin, total) + ' de ' + total : '';
                    pie._sel.value = String(st.tam);
                    pie._navs.forEach(function (n) {
                        n.nodo.hidden = paginas <= 1;
                        n.pos.textContent = 'Página ' + st.pag + ' de ' + paginas;
                        n.bt[0].disabled = n.bt[1].disabled = st.pag <= 1; n.bt[2].disabled = n.bt[3].disabled = st.pag >= paginas;
                    });
                }
                ths.forEach(function (th, i) {
                    th.classList.toggle('ord-asc', i === st.col && st.dir === 1); th.classList.toggle('ord-desc', i === st.col && st.dir === -1);
                    if (th.classList.contains('ord')) th.setAttribute('aria-sort', i === st.col ? (st.dir === 1 ? 'ascending' : 'descending') : 'none');
                });
            } finally {
                if (observador) observador.takeRecords();
                trabajando = false;
            }
        }

        if (ordenar) ths.forEach(function (th, i) {
            if (!(th.textContent || '').trim() || th.hasAttribute('data-sin-orden')) return;
            th.classList.add('ord'); th.title = 'Doble clic para ordenar';
            th.addEventListener('dblclick', function () {
                if (window.getSelection) { var s = window.getSelection(); if (s && s.removeAllRanges) s.removeAllRanges(); }
                if (st.col === i) st.dir = -st.dir; else { st.col = i; st.dir = 1; }
                st.pag = 1; aplicar();
            });
        });

        if (window.MutationObserver) {
            observador = new MutationObserver(function () { if (!trabajando) aplicar(); });
            observador.observe(cuerpo, { childList: true });
        }
        aplicar();
    }

    function todas() { Array.prototype.forEach.call(document.querySelectorAll('table.tabla'), mejorar); }
    todas();
    if (window.MutationObserver) new MutationObserver(function () { todas(); }).observe(document.body, { childList: true, subtree: true });
})();

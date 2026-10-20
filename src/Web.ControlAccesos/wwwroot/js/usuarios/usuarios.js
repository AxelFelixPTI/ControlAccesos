// Pantalla Usuarios y roles: lista con búsqueda y filtro por rol; formulario lateral para crear y editar.
(function () {
    'use strict';
    var raiz = document.getElementById('caf-usuarios');
    if (!raiz) return;
    var el = CAF.el;
    var url = { listar: raiz.dataset.urlListar, opciones: raiz.dataset.urlOpciones, guardar: raiz.dataset.urlGuardar, enlace: raiz.dataset.urlEnlace };
    var filas = [], op = { tiposDoc: [], roles: [], personal: [] }, seleccionado = null;
    var cuerpo = document.getElementById('u-filas'), buscar = document.getElementById('u-buscar'), selRol = document.getElementById('u-rol'), lateral = document.getElementById('u-lateral');

    function norm(s) { return String(s || '').normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase(); }
    function nombreRol(codigo) { var r = op.roles.filter(function (x) { return x.codigo === codigo; })[0]; return r ? r.nombre : codigo; }

    function pintar() {
        var q = norm(buscar.value), rol = selRol.value;
        var vistas = filas.filter(function (u) {
            return (!rol || u.roles.indexOf(rol) >= 0) && (!q || norm(u.nombreCompleto + ' ' + u.correo + ' ' + u.doc).indexOf(q) >= 0);
        });
        cuerpo.textContent = '';
        if (!vistas.length) { cuerpo.appendChild(el('tr', {}, [el('td', { colspan: '5', class: 'vacio', text: filas.length ? 'Ningún usuario coincide con la búsqueda.' : 'Todavía no hay usuarios.' })])); return; }
        vistas.forEach(function (u) {
            var estado = [el('span', { class: 'chip ' + (u.activo ? 'c-ok' : 'c-can'), text: u.activo ? 'Activo' : 'Inactivo' })];
            if (u.activo && !u.tienePassword) estado.push(el('span', { class: 'chip c-obs', text: 'Sin contraseña' }));
            if (u.bloqueado) estado.push(el('span', { class: 'chip c-rec', text: 'Bloqueado' }));
            var empresa = u.personalId
                ? el('td', { text: u.area || '' })
                : el('td', {}, [el('span', { text: u.empresaExterna || '' }), el('div', { class: 'small muted', text: 'externo' })]);
            cuerpo.appendChild(el('tr', { class: (seleccionado && seleccionado.id === u.id) ? 'sel' : (u.activo ? '' : 'off') }, [
                el('td', { class: 'stk' }, [el('b', { text: u.nombreCompleto }), el('div', { class: 'small muted', text: u.correo })]),
                empresa,
                el('td', {}, [el('div', { class: 'chips' }, u.roles.map(function (r) { return el('span', { class: 'chip c-line', text: nombreRol(r) }); }))]),
                el('td', {}, [el('div', { class: 'chips' }, estado)]),
                el('td', {}, [el('button', { type: 'button', class: 'btn btn-sm', text: 'Editar', onclick: function () { abrir(u); } })])
            ]));
        });
    }

    function cargar() {
        return CAF.pedir(url.listar).then(function (r) {
            if (!r.success) { CAF.aviso(r.message || 'No se pudo cargar.', 'warn'); return; }
            filas = r.data; pintar();
        });
    }

    function portada() {
        lateral.textContent = '';
        lateral.appendChild(el('div', { class: 'stack' }, [
            el('h3', { text: 'Usuarios y roles' }),
            el('p', { class: 'small muted', text: 'Elija Editar en un usuario o cree uno nuevo. Un usuario puede tener varios roles.' }),
            el('button', { type: 'button', class: 'btn btn-primary', text: '+ Nuevo usuario', onclick: function () { abrir(null); } })
        ]));
    }

    function abrir(u) { seleccionado = u; pintar(); formulario(u); }
    function cerrarForm() { seleccionado = null; pintar(); portada(); }

    function campo(etiqueta, control, ayuda) {
        var h = [el('span', { class: 'field-l', text: etiqueta }), control];
        if (ayuda) h.push(el('span', { class: 'field-h', text: ayuda }));
        return el('label', { class: 'field' }, h);
    }
    function texto(valor, max, ph) { var i = el('input', { type: 'text', maxlength: String(max), autocomplete: 'off', placeholder: ph || '' }); i.value = valor || ''; return i; }

    function formulario(u) {
        var esNuevo = !u;
        var trabajadores = op.personal.filter(function (t) { return (t.activo && !t.tieneUsuario) || (u && u.personalId === t.id); });
        var selTrab = el('select', {}, [el('option', { value: '', text: 'Sin vínculo (usuario externo)' })].concat(trabajadores.map(function (t) { return el('option', { value: String(t.id), text: t.texto }); })));
        selTrab.value = u && u.personalId ? String(u.personalId) : '';
        var externo = el('div', { class: 'stack' });
        var vinculado = el('div', { class: 'aviso a-info', text: 'Nombre, documento y correo vienen del catálogo de Personal. Se editan allí.' });
        var apPat = texto(u && u.apellidoPaterno, 100), apMat = texto(u && u.apellidoMaterno, 100), nombres = texto(u && u.nombres, 100);
        var tipoDoc = el('select', {}, op.tiposDoc.map(function (t) { return el('option', { value: String(t.id), text: t.texto }); }));
        tipoDoc.value = u ? String(u.tipoDocId) : (op.tiposDoc[0] ? String(op.tiposDoc[0].id) : '');
        var doc = texto(u && u.doc, 20), correo = texto(u && u.correo, 200, 'nombre@empresa.com'), empresa = texto(u && u.empresaExterna, 200, 'Seguridad Andina S.A.C.');
        externo.appendChild(el('div', { class: 'grid g3' }, [campo('Apellido paterno *', apPat), campo('Apellido materno', apMat), campo('Nombres *', nombres)]));
        externo.appendChild(el('div', { class: 'grid g2' }, [campo('Tipo de documento', tipoDoc), campo('Número *', doc)]));
        externo.appendChild(campo('Correo *', correo));
        externo.appendChild(campo('Empresa externa *', empresa));
        function alternar() { var v = !!selTrab.value; externo.hidden = v; vinculado.hidden = !v; }
        selTrab.addEventListener('change', alternar); alternar();

        var checks = {}, roles = el('fieldset', { class: 'roles' }, [el('legend', { text: 'Roles en la sede VES *' })]);
        op.roles.forEach(function (r) {
            var c = el('input', { type: 'checkbox' }); c.checked = !!(u && u.roles.indexOf(r.codigo) >= 0); checks[r.id] = c;
            roles.appendChild(el('label', { class: 'chk' }, [c, el('span', {}, [el('b', { text: r.nombre }), el('span', { class: 'small muted', text: ' · ' + r.descripcion })])]));
        });
        var activo = el('input', { type: 'checkbox' }); activo.checked = u ? u.activo : true;
        var error = el('p', { class: 'field-e' });

        var guardar = el('button', { type: 'button', class: 'btn btn-primary', text: esNuevo ? 'Crear usuario' : 'Guardar cambios' });
        guardar.addEventListener('click', function () {
            error.textContent = '';
            var ids = Object.keys(checks).filter(function (k) { return checks[k].checked; }).map(Number);
            guardar.disabled = true;
            CAF.pedir(url.guardar, {
                method: 'POST', body: {
                    id: u ? u.id : 0, personalId: selTrab.value ? Number(selTrab.value) : null, apellidoPaterno: apPat.value, apellidoMaterno: apMat.value,
                    nombres: nombres.value, tipoDocId: Number(tipoDoc.value) || 0, doc: doc.value, correo: correo.value, empresaExterna: empresa.value,
                    roles: ids, activo: activo.checked
                }
            }).then(function (r) {
                guardar.disabled = false;
                if (!r.success) {
                    var det = (r.errors || []).map(function (e) { return e.message; }).filter(Boolean);
                    error.textContent = det.length ? det.join(' ') : (r.message || 'No se pudo guardar.');
                    if (r.id) { cargar().then(function () { op.cambiado = true; }); }
                    return;
                }
                CAF.aviso(r.message);
                cerrarForm();
                recargarTodo().then(function () { if (r.enlace) mostrarEnlace(r.enlace, true); else if (r.enlaceError) CAF.aviso('Usuario creado, pero no se pudo generar el enlace: ' + r.enlaceError, 'warn'); });
            });
        });
        var cancelar = el('button', { type: 'button', class: 'btn', text: 'Cancelar', onclick: cerrarForm });

        lateral.textContent = '';
        var partes = [
            el('div', { class: 'card-hd' }, [el('h3', { text: esNuevo ? 'Nuevo usuario' : 'Editar usuario' }), el('button', { type: 'button', class: 'btn btn-icon', 'aria-label': 'Cerrar', text: '×', onclick: cerrarForm })]),
            campo('Personal vinculado', selTrab, 'Los vigilantes de empresa contratista no se vinculan.'),
            vinculado, externo, roles,
            el('label', { class: 'chk' }, [activo, 'Usuario activo']),
            esNuevo ? el('p', { class: 'small muted', text: 'Al crearlo se genera un enlace para que el usuario defina su contraseña. Usted se lo entrega.' }) : null,
            error,
            el('div', { class: 'row-end' }, [cancelar, guardar])
        ];
        if (!esNuevo && u.activo) {
            partes.splice(partes.length - 1, 0, el('button', { type: 'button', class: 'btn btn-sm', text: 'Generar enlace de contraseña', onclick: function () {
                CAF.pedir(url.enlace, { method: 'POST', body: { id: u.id } }).then(function (r) {
                    if (r.success) mostrarEnlace(r.enlace, false); else CAF.aviso(r.message || 'No se pudo generar el enlace.', 'warn');
                });
            } }));
        }
        lateral.appendChild(el('div', { class: 'stack' }, partes));
    }

    function mostrarEnlace(enlace, nuevo) {
        var caja = el('input', { type: 'text', readonly: true }); caja.value = enlace;
        var cuerpoM = el('div', { class: 'stack' }, [
            el('p', { text: nuevo ? 'Entregue este enlace al usuario para que defina su contraseña.' : 'Entregue este enlace al usuario. Reemplaza al anterior.' }),
            caja,
            el('p', { class: 'small muted', text: 'Sirve una sola vez y vence en 3 días. Por seguridad no se vuelve a mostrar: si se pierde, genere otro.' })
        ]);
        CAF.modal('Enlace para definir contraseña', cuerpoM, [
            { texto: 'Cerrar', onclick: function (cerrar) { cerrar(); } },
            {
                texto: 'Copiar enlace', tipo: 'primary', onclick: function () {
                    caja.select();
                    var ok = function () { CAF.aviso('Enlace copiado.'); };
                    if (navigator.clipboard && navigator.clipboard.writeText) navigator.clipboard.writeText(enlace).then(ok, function () { document.execCommand('copy'); ok(); });
                    else { document.execCommand('copy'); ok(); }
                }
            }
        ]);
    }

    function recargarOpciones() {
        return CAF.pedir(url.opciones).then(function (r) {
            if (!r.success) { CAF.aviso(r.message || 'No se pudieron cargar las listas.', 'warn'); return; }
            op = r.data;
        });
    }
    function recargarTodo() { return recargarOpciones().then(cargar); }

    buscar.addEventListener('input', pintar);
    selRol.addEventListener('change', pintar);
    recargarOpciones().then(function () {
        op.roles.forEach(function (r) { selRol.appendChild(CAF.el('option', { value: r.codigo, text: r.nombre })); });
        portada();
        return cargar();
    });
})();

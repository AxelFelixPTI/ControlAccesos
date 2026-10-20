// Pantalla Personal: lista con búsqueda y filtro por área; crear y editar en ventana.
(function () {
    'use strict';
    var raiz = document.getElementById('caf-personal');
    if (!raiz) return;
    var el = CAF.el;
    var url = { listar: raiz.dataset.urlListar, opciones: raiz.dataset.urlOpciones, guardar: raiz.dataset.urlGuardar };
    var filas = [], op = { tiposDoc: [], areas: [], cargos: [], empresas: [] };
    var cuerpo = document.getElementById('t-filas'), buscar = document.getElementById('t-buscar'), selArea = document.getElementById('t-area');

    function norm(s) { return String(s || '').normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase(); }

    function pintar() {
        var q = norm(buscar.value), area = selArea.value;
        var vistas = filas.filter(function (p) {
            return (!area || String(p.areaId) === area) && (!q || norm(p.nombreCompleto + ' ' + p.doc + ' ' + (p.cargo || '')).indexOf(q) >= 0);
        });
        cuerpo.textContent = '';
        if (!vistas.length) { cuerpo.appendChild(el('tr', {}, [el('td', { colspan: '8', class: 'vacio', text: filas.length ? 'Nadie coincide con la búsqueda.' : 'Todavía no hay personal registrado.' })])); return; }
        vistas.forEach(function (p) {
            cuerpo.appendChild(el('tr', { class: p.activo ? '' : 'off' }, [
                el('td', { class: 'stk', text: p.nombreCompleto }),
                el('td', { class: 'mono', text: (p.tipoDoc ? p.tipoDoc + ' ' : '') + p.doc }),
                el('td', { text: p.area || '' }),
                el('td', { text: p.cargo || '' }),
                el('td', { text: p.anexo || '' }),
                el('td', { text: p.tieneUsuario ? 'Sí' : 'No' }),
                el('td', {}, [el('span', { class: 'chip ' + (p.activo ? 'c-ok' : 'c-can'), text: p.activo ? 'Activo' : 'Inactivo' })]),
                el('td', {}, [el('button', { type: 'button', class: 'btn btn-sm', text: 'Editar', onclick: function () { formulario(p); } })])
            ]));
        });
    }

    function cargar() {
        return CAF.pedir(url.listar).then(function (r) {
            if (!r.success) { CAF.aviso(r.message || 'No se pudo cargar.', 'warn'); return; }
            filas = r.data; pintar();
        });
    }

    function combo(lista, valor, vacio) {
        var s = el('select');
        if (vacio) s.appendChild(el('option', { value: '', text: vacio }));
        lista.forEach(function (o) { s.appendChild(el('option', { value: String(o.id), text: o.texto })); });
        s.value = valor ? String(valor) : '';
        return s;
    }
    function campo(etiqueta, control) { return el('label', { class: 'field' }, [el('span', { class: 'field-l', text: etiqueta }), control]); }
    function texto(valor, max, ph) { var i = el('input', { type: 'text', maxlength: String(max), autocomplete: 'off', placeholder: ph || '' }); i.value = valor || ''; return i; }

    function formulario(p) {
        var apPat = texto(p && p.apellidoPaterno, 100), apMat = texto(p && p.apellidoMaterno, 100), nombres = texto(p && p.nombres, 200);
        var tipoDoc = combo(op.tiposDoc, p ? p.tipoDocId : (op.tiposDoc[0] && op.tiposDoc[0].id)), doc = texto(p && p.doc, 20), anexo = texto(p && p.anexo, 20);
        var area = combo(op.areas, p ? p.areaId : (op.areas[0] && op.areas[0].id)), cargo = combo(op.cargos, p && p.cargoId, 'Sin cargo');
        var empresa = combo(op.empresas, p ? p.empresaId : (op.empresas[0] && op.empresas[0].id));
        var correo = texto(p && p.correo, 200, 'nombre@grupotrianon.com');
        var chk = el('input', { type: 'checkbox' }); chk.checked = p ? p.activo : true;
        var error = el('p', { class: 'field-e' });
        var cuerpoForm = el('div', { class: 'stack' }, [
            el('div', { class: 'grid g3' }, [campo('Apellido paterno *', apPat), campo('Apellido materno', apMat), campo('Nombres *', nombres)]),
            el('div', { class: 'grid g3' }, [campo('Tipo de documento', tipoDoc), campo('Número *', doc), campo('Anexo', anexo)]),
            el('div', { class: 'grid g3' }, [campo('Área', area), campo('Cargo', cargo), campo('Empresa', empresa)]),
            campo('Correo', correo),
            el('label', { class: 'chk' }, [chk, 'Activo (se ofrece como responsable de atención)']),
            error
        ]);
        CAF.modal(p ? 'Editar persona del personal' : 'Nueva persona del personal', cuerpoForm, [
            { texto: 'Cancelar', onclick: function (cerrar) { cerrar(); } },
            {
                texto: 'Guardar', tipo: 'primary', onclick: function (cerrar) {
                    error.textContent = '';
                    CAF.pedir(url.guardar, {
                        method: 'POST', body: {
                            id: p ? p.id : 0, apellidoPaterno: apPat.value, apellidoMaterno: apMat.value, nombres: nombres.value,
                            tipoDocId: Number(tipoDoc.value) || 0, doc: doc.value, anexo: anexo.value, areaId: Number(area.value) || 0,
                            cargoId: cargo.value ? Number(cargo.value) : null, empresaId: Number(empresa.value) || 0, correo: correo.value, activo: chk.checked
                        }
                    }).then(function (r) {
                        if (!r.success) {
                            var det = (r.errors || []).map(function (e) { return e.message; }).filter(Boolean);
                            error.textContent = det.length ? det.join(' ') : (r.message || 'No se pudo guardar.'); return;
                        }
                        cerrar();
                        CAF.aviso(r.message && r.message.indexOf('pero') >= 0 ? r.message : (p ? 'Datos actualizados.' : 'Persona agregada. Ya aparece como responsable de atención.'), r.message && r.message.indexOf('pero') >= 0 ? 'warn' : 'ok');
                        cargar();
                    });
                }
            }
        ], 'ancho');
    }

    document.getElementById('t-nuevo').addEventListener('click', function () { formulario(null); });
    buscar.addEventListener('input', pintar);
    selArea.addEventListener('change', pintar);

    CAF.pedir(url.opciones).then(function (r) {
        if (!r.success) { CAF.aviso(r.message || 'No se pudieron cargar las listas.', 'warn'); return; }
        op = r.data;
        op.areas.forEach(function (a) { selArea.appendChild(el('option', { value: String(a.id), text: a.texto })); });
        return cargar();
    });
})();

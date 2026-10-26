// Menú lateral en pantallas angostas y botón de tema claro/oscuro.
(function () {
    var lateral = document.getElementById('lateral');
    var boton = document.getElementById('menu-t');
    if (lateral && boton) boton.addEventListener('click', function () { lateral.classList.toggle('open'); });

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

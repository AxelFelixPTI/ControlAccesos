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

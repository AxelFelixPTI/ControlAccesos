// Menú lateral en pantallas angostas: abre y cierra con el botón de las tres rayas.
(function () {
    var lateral = document.getElementById('lateral');
    var boton = document.getElementById('menu-t');
    if (!lateral || !boton) return;
    boton.addEventListener('click', function () { lateral.classList.toggle('open'); });
})();

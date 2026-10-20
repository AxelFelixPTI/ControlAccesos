// Tema claro/oscuro. Se carga en <head> para aplicarlo antes de pintar (evita el parpadeo).
// Por defecto es claro; la elección se recuerda en este navegador.
(function () {
    var t = 'light';
    try { if (localStorage.getItem('caf.tema') === 'dark') t = 'dark'; } catch (e) { }
    document.documentElement.setAttribute('data-theme', t);
})();

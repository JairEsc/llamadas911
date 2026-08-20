// Estado compartido de los filtros (Municipio, Colonia, Incidente).
//
// Cualquier gráfica que quiera reaccionar a cambios de filtro se
// suscribe una sola vez, en su propio archivo, con suscribirse(fn).
// Nadie tiene que mantener una lista central de "qué gráficas existen":
// agregar una gráfica nueva en el futuro es agregar un archivo nuevo
// que se suscribe solo, sin tocar este archivo ni logica.js.

let estado = {
    municipio: "Pachuca de Soto",
    colonia: "Centro (Colonia)",
    incidente: "Otras Alarmas De Emergencias Activadas (Seguridad)"
};

let seleccion_ids = {
    municipio: "selector_municipio",
    colonia: "selector_colonia",
    incidente: "selector_incidente"
};

const _listenersEstado = [];

// Cada gráfica llama suscribirse(miFuncionDeRender) una vez, al cargar su script.
function suscribirse(fn) {
    _listenersEstado.push(fn);
}

// Se llama cuando el estado ya quedó "asentado" (M, C, I finales) y se
// quiere que todas las gráficas suscritas se vuelvan a dibujar.
function notificarCambio() {
    _listenersEstado.forEach(fn => fn(estado.municipio, estado.colonia, estado.incidente));
}

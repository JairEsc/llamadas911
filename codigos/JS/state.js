// Estado compartido de los filtros (Municipio, Colonia, Incidente, Clasificación).
//
// Cualquier gráfica que quiera reaccionar a cambios de filtro se
// suscribe una sola vez, en su propio archivo, con suscribirse(fn).
// Nadie tiene que mantener una lista central de "qué gráficas existen":
// agregar una gráfica nueva en el futuro es agregar un archivo nuevo
// que se suscribe solo, sin tocar este archivo ni logica.js.
//
// Clasificación es un filtro nuevo e independiente de Municipio/Colonia/
// Incidente: sus opciones salen de la columna "Clasificacion" de
// Base 911.json (coincide 1 a 1 con las columnas de Base municipal.geojson,
// ver Cargar_Resumen.js y Cargar_Municipal.js). El valor por defecto de
// abajo corresponde a la Clasificación del Incidente por defecto, para
// que el estado inicial sea consistente.
//
// Municipio puede tomar además el valor especial TODOS_MUNICIPIOS: en ese
// caso Colonia/Incidente dejan de aplicar (se ocultan) y el mapa/las
// gráficas usan la vista agregada por municipio (ver logica.js y cada
// gráfica en codigos/JS/charts/).
const TODOS_MUNICIPIOS = "Todos los municipios";

let estado = {
    municipio: "Pachuca de Soto",
    colonia: "Centro (Colonia)",
    incidente: "Otras Alarmas De Emergencias Activadas (Seguridad)",
    clasificacion: "Alarmas y objetos sospechosos"
};

let seleccion_ids = {
    municipio: "selector_municipio",
    colonia: "selector_colonia",
    incidente: "selector_incidente",
    clasificacion: "selector_clasificacion"
};

const _listenersEstado = [];

// Cada gráfica llama suscribirse(miFuncionDeRender) una vez, al cargar su script.
function suscribirse(fn) {
    _listenersEstado.push(fn);
}

// Se llama cuando el estado ya quedó "asentado" (M, C, I, Cl finales) y se
// quiere que todas las gráficas suscritas se vuelvan a dibujar.
function notificarCambio() {
    _listenersEstado.forEach(fn => fn(estado.municipio, estado.colonia, estado.incidente, estado.clasificacion));
}

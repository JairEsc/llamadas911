// Estado compartido de los filtros (Municipio, Colonia, Incidente, Clasificación).
//
// Cualquier gráfica que quiera reaccionar a cambios de filtro se
// suscribe una sola vez, en su propio archivo, con suscribirse(fn).
// Nadie tiene que mantener una lista central de "qué gráficas existen":
// agregar una gráfica nueva en el futuro es agregar un archivo nuevo
// que se suscribe solo, sin tocar este archivo ni logica.js.
//
// Cascada de filtros: Municipio -> Colonia -> Clasificación -> Incidente.
// Para un municipio específico, las opciones de Clasificación dependen de
// Municipio + Colonia, y las de Incidente dependen además de la
// Clasificación elegida (ver Rellenar_Clasificacion/Rellenar_Incidente en
// logica.js). Sólo en la vista agregada "Todos los municipios" (donde
// Colonia/Incidente no aplican) Clasificación muestra el catálogo
// completo, tomado de la columna "Clasificacion" de Base 911.json
// (coincide 1 a 1 con las columnas de Base municipal.geojson, ver
// Cargar_Resumen.js y Cargar_Municipal.js). El valor por defecto de abajo
// corresponde a la Clasificación del Incidente por defecto, para que el
// estado inicial sea consistente.
//
// Municipio puede tomar además el valor especial TODOS_MUNICIPIOS: en ese
// caso Colonia/Incidente dejan de aplicar (se ocultan) y el mapa/las
// gráficas usan la vista agregada por municipio (ver logica.js y cada
// gráfica en codigos/JS/charts/).
const TODOS_MUNICIPIOS = "Todos los municipios";

// Valor especial del selector de Incidente: agrega, para el
// Municipio + Colonia + Clasificación seleccionados, todos los
// Incidentes que pertenecen a esa Clasificación (ver
// agregarPorClasificacion() en funciones_extras.js y su uso en
// logica.js/charts/*.js). A diferencia de TODOS_MUNICIPIOS, este valor
// no cambia la cascada de filtros: Municipio/Colonia/Clasificación
// siguen aplicando igual, solo Incidente pasa a representar la suma de
// todos los incidentes de esa Clasificación.
const TODOS_INCIDENTES = "Todas";

let estado = {
    municipio: "Pachuca de Soto",
    colonia: "Centro (Colonia)",
    incidente: "Todas",
    clasificacion: "Alarmas y objetos sospechosos",
    // Municipio seleccionado con click en el mapa coroplético (modo
    // "Todos los municipios"). Lo usan serieTemporalChart.js y
    // heatmapChart.js para su vista de detalle (ver mapaChart.js).
    municipioClickeado: "Pachuca de Soto"
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
    _listenersEstado.forEach(fn => fn(estado.municipio, estado.colonia, estado.incidente, estado.clasificacion, estado.municipioClickeado));
}
//Slidebar
function toggleSidebar() {
  const sidebar = document.querySelector(".sidebar");
  sidebar.classList.toggle("collapsed");
}

// Regresión lineal
// Necesitarémos una función que dadas dos listas nos regrese la pendiente
// y la constante de la regresión lineal de los datos de esas dos listas
function Regresion(x, y) {
  let n = x.length; //asumiendo que son del mismo tamaño
  let sumX = 0;
  let sumY = 0;
  let sumXY = 0;
  let sumXX = 0;

  for (let i = 0; i < n; i++) {
    sumX += x[i];
    sumY += y[i];
    sumXY += x[i] * y[i];
    sumXX += x[i] * x[i];
  }

  //Fórmulas verificadas con apuntes de Margarita
  let pendiente = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX);
  let constante = (sumY - pendiente * sumX) / n;

  return { pendiente, constante };
}

//Para radio dinámico definimos
let r_min;
let r_max;
function Radio(v) {
  if (r_max != r_min) {
    return 5 + ((v - r_min) / (r_max - r_min)) * 15;
  }

  return 15;
}

function validarColumnas(datos, columnasEsperadas, nombreArchivo) {
    if (datos.length === 0) {
        console.error(`${nombreArchivo}: el archivo llegó vacío.`);
        return false;
    }
    const columnasReales = Object.keys(datos[0]);
    const faltantes = columnasEsperadas.filter(c => !columnasReales.includes(c));
    if (faltantes.length > 0) {
        console.error(
            `${nombreArchivo}: faltan columnas esperadas: ${faltantes.join(", ")}. ` +
            `Columnas encontradas: ${columnasReales.join(", ")}.`
        );
        return false;
    }
    return true;
}

// ---------------------------------------------------------------
// Utilidades para la vista "Todos los municipios" (mapa coroplético,
// serieTemporalChart, heatmapChart y treemapChart agregados).
// ---------------------------------------------------------------

// Normaliza texto para comparar Clasificación vs columnas del GeoJSON de
// forma robusta ante acentos, mayúsculas/minúsculas o espacios extra.
function normalizarTexto(txt) {
    if (txt === null || txt === undefined) return "";
    return txt.toString()
        .normalize("NFD").replace(/[\u0300-\u036f]/g, "") // quita acentos
        .trim()
        .toLowerCase()
        .replace(/\s+/g, " ");
}

// Dado el objeto "properties" de un feature de Base municipal.geojson y el
// nombre de la Clasificación seleccionada, regresa el nombre exacto de la
// columna del GeoJSON que le corresponde (o null si no se encuentra).
function buscarColumnaClasificacion(propiedades, clasificacion) {
    if (!propiedades) return null;
    if (Object.prototype.hasOwnProperty.call(propiedades, clasificacion)) {
        return clasificacion;
    }
    const objetivo = normalizarTexto(clasificacion);
    const encontrada = Object.keys(propiedades).find(
        (columna) => normalizarTexto(columna) === objetivo
    );
    return encontrada || null;
}

// Escala de color secuencial (usada por el mapa coroplético municipal),
// en tonos del color institucional de la app (#691c32).
const RAMPA_COLOR_MUNICIPAL = ["#f6e8ec", "#e3aebd", "#c96e8b", "#a13154", "#691c32", "#450f21"];
const COLOR_SIN_DATO_MUNICIPAL = "#e0e0e0";

function colorClasificacionMunicipal(valor, minVal, maxVal) {
    if (valor === null || valor === undefined || isNaN(valor)) {
        return COLOR_SIN_DATO_MUNICIPAL;
    }
    if (maxVal === minVal) {
        return RAMPA_COLOR_MUNICIPAL[RAMPA_COLOR_MUNICIPAL.length - 1];
    }
    const proporcion = (valor - minVal) / (maxVal - minVal);
    const idx = Math.min(
        RAMPA_COLOR_MUNICIPAL.length - 1,
        Math.floor(proporcion * RAMPA_COLOR_MUNICIPAL.length)
    );
    return RAMPA_COLOR_MUNICIPAL[idx];
}

// Muestra u oculta los filtros de Colonia e Incidente: no aplican cuando
// el Municipio seleccionado es TODOS_MUNICIPIOS (vista agregada).
// Clasificación se queda siempre visible (no está dentro de estos
// wrappers) porque en la vista agregada sigue usándose directamente para
// colorear el mapa coroplético y las gráficas municipales.
function mostrarFiltrosPorMunicipio(mostrar) {
    const wrapperColonia = document.getElementById("filtro-colonia");
    const wrapperIncidente = document.getElementById("filtro-incidente");
    if (wrapperColonia) {
        wrapperColonia.style.display = mostrar ? "" : "none";
    }
    if (wrapperIncidente) {
        wrapperIncidente.style.display = mostrar ? "" : "none";
    }
}
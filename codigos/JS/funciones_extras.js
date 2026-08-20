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
// Utilidad para la opción "Todas" del filtro de Incidente (agrega, para
// una Clasificación, todos sus Incidentes). Equivalente en R:
//
//   datos |>
//     dplyr::group_by(<columnasAgrupar>) |>
//     dplyr::summarise(
//       Recuento = sum(Recuento, na.rm = TRUE),
//       X = mean(X),   # solo si incluirCoordenadas = TRUE
//       Y = mean(Y)
//     ) |>
//     dplyr::ungroup()
//
// Recibe un arreglo plano de filas (objetos con, al menos, las
// columnas en columnasAgrupar + Recuento, y X/Y si incluirCoordenadas
// es true) y regresa un arreglo con una fila por combinación única de
// columnasAgrupar, con Recuento sumado (ignorando null/undefined/NaN,
// como sum(..., na.rm = TRUE)) y, opcionalmente, X/Y promediados para
// conservar las coordenadas que necesitan los mapas.
function agregarPorClasificacion(filas, columnasAgrupar, incluirCoordenadas = false) {
    const grupos = new Map();

    filas.forEach(fila => {
        const clave = columnasAgrupar.map(col => fila[col]).join("|||");

        if (!grupos.has(clave)) {
            const base = {};
            columnasAgrupar.forEach(col => base[col] = fila[col]);
            base.Recuento = 0;
            if (incluirCoordenadas) {
                base._sumaX = 0;
                base._sumaY = 0;
                base._n = 0;
            }
            grupos.set(clave, base);
        }

        const grupo = grupos.get(clave);

        // sum(Recuento, na.rm = TRUE): los valores faltantes no suman,
        // pero tampoco invalidan el resto de la suma.
        const recuento = Number(fila.Recuento);
        if (!isNaN(recuento)) {
            grupo.Recuento += recuento;
        }

        if (incluirCoordenadas) {
            grupo._sumaX += fila.X;
            grupo._sumaY += fila.Y;
            grupo._n += 1;
        }
    });

    return Array.from(grupos.values()).map(grupo => {
        if (incluirCoordenadas) {
            grupo.X = grupo._n > 0 ? grupo._sumaX / grupo._n : null;
            grupo.Y = grupo._n > 0 ? grupo._sumaY / grupo._n : null;
            delete grupo._sumaX;
            delete grupo._sumaY;
            delete grupo._n;
        }
        return grupo;
    });
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
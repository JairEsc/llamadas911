// Carga de los archivos agregados a nivel Municipio, usados por la vista
// "Todos los municipios" (RF-2/RF-3/RF-4):
//   - Base municipal.geojson         -> mapa coroplético y treemapChart
//   - Histórico_AñoXMes_municipal.xlsx -> serieTemporalChart
//   - Tabla_DiaXHora_municipal.xlsx    -> heatmapChart
//
// A diferencia de Cargar_Resumen.js/logica.js (que cargan sus archivos de
// entrada apenas arranca la página, porque el municipio específico es la
// vista por defecto), estos archivos solo se necesitan si el usuario
// llega a seleccionar "Todos los municipios". Para evitar lecturas de
// red innecesarias, cargarDatosMunicipales() los pide la primera vez que
// se necesitan y cachea la misma promesa para cualquier llamada
// posterior (mapa, treemap, serie temporal y heatmap comparten la
// descarga en vez de repetirla cada uno).

let MUNICIPAL_GEOJSON = null;
let AnioXMes_Municipal = [];
let DiaXHora_Municipal = [];

const COLUMNAS_ANIO_MES_MUNICIPAL = ["Municipio", "Incidente", "Fecha", "Recuento"];
const COLUMNAS_DIA_HORA_MUNICIPAL = ["Municipio", "Incidente", "Dia_Semana", "Hora", "Recuento"];

let _promesaDatosMunicipales = null;

function cargarDatosMunicipales() {
    if (_promesaDatosMunicipales) {
        // Ya se cargaron (o se están cargando): reutilizamos la misma promesa.
        return _promesaDatosMunicipales;
    }

    const prometoGeojson = fetch("outputs/Estadistica Ejercicio/Municipio/Base municipal.geojson")
        .then((response) => {
            if (!response.ok) {
                throw new Error("No se pudo cargar Base municipal.geojson");
            }
            return response.json();
        })
        .then((geojson) => {
            MUNICIPAL_GEOJSON = geojson;
        })
        .catch((err) => {
            console.error("Error al cargar Base municipal.geojson:", err);
        });

    const prometoAnioXMes = fetch("outputs/Estadistica Ejercicio/Municipio/Histórico_AñoXMes_municipal.xlsx")
        .then((response) => {
            if (!response.ok) {
                throw new Error("No se pudo cargar Histórico_AñoXMes_municipal.xlsx");
            }
            return response.arrayBuffer();
        })
        .then((data) => {
            try {
                const workbook = XLSX.read(data, { type: "array" });
                const worksheet = workbook.Sheets[workbook.SheetNames[0]];
                AnioXMes_Municipal = XLSX.utils.sheet_to_json(worksheet, { defval: null });
                validarColumnas(AnioXMes_Municipal, COLUMNAS_ANIO_MES_MUNICIPAL, "Histórico_AñoXMes_municipal.xlsx");
            } catch (error) {
                console.error("Error al procesar Histórico_AñoXMes_municipal.xlsx:", error);
            }
        })
        .catch((err) => {
            console.error("Error al cargar Histórico_AñoXMes_municipal.xlsx:", err);
        });

    const prometoDiaXHora = fetch("outputs/Estadistica Ejercicio/Municipio/Tabla_DiaXHora_municipal.xlsx")
        .then((response) => {
            if (!response.ok) {
                throw new Error("No se pudo cargar Tabla_DiaXHora_municipal.xlsx");
            }
            return response.arrayBuffer();
        })
        .then((data) => {
            try {
                const workbook = XLSX.read(data, { type: "array" });
                const worksheet = workbook.Sheets[workbook.SheetNames[0]];
                DiaXHora_Municipal = XLSX.utils.sheet_to_json(worksheet, { defval: null });
                validarColumnas(DiaXHora_Municipal, COLUMNAS_DIA_HORA_MUNICIPAL, "Tabla_DiaXHora_municipal.xlsx");
            } catch (error) {
                console.error("Error al procesar Tabla_DiaXHora_municipal.xlsx:", error);
            }
        })
        .catch((err) => {
            console.error("Error al cargar Tabla_DiaXHora_municipal.xlsx:", err);
        });

    _promesaDatosMunicipales = Promise.all([prometoGeojson, prometoAnioXMes, prometoDiaXHora]);
    return _promesaDatosMunicipales;
}

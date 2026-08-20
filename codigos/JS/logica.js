// Carga de los históricos (xlsx) y cascada de filtros
// Municipio -> Colonia -> Incidente.
//
// Ya NO dibuja ninguna gráfica directamente: cuando la cascada termina
// (en Rellenar_Incidente), llama a notificarCambio() y cada gráfica
// suscrita (en codigos/JS/charts/) se redibuja sola.

let AñoXMes = [];
let DiaXHora = [];

// Esquema esperado de cada archivo. Si el pipeline en R llega a
// renombrar, eliminar o reordenar columnas, validarColumnas() lo
// reporta con un mensaje claro en vez de dejar que el dashboard
// muestre datos de la columna equivocada sin ningún aviso.
const COLUMNAS_ANIO_MES = ["Colonia", "Municipio", "Incidente", "Fecha", "Recuento"];
const COLUMNAS_DIA_HORA = ["Colonia", "Municipio", "Incidente", "Dia_Semana", "Hora", "Recuento"];


let tePrometoLeerExcel = new Promise((resolve, reject) => {
    fetch("outputs/llamadas9112025/Histórico_AñoXMes_new.xlsx") // Debe estar accesible públicamente
    .then((response) => {
        if (!response.ok) {
            throw new Error("No se pudo cargar el archivo Excel");
        }
        return response.arrayBuffer();
    })
    .then((data) => {
        try {
            const workbook = XLSX.read(data, { type: "array" });
            const firstSheetName = workbook.SheetNames[0];
            const worksheet = workbook.Sheets[firstSheetName];
            AñoXMes = XLSX.utils.sheet_to_json(worksheet, { defval: null });
            validarColumnas(AñoXMes, COLUMNAS_ANIO_MES, "Histórico_AñoXMes_new.xlsx");
        } catch (error) {
            console.error("Error al procesar el Excel:", error);
        }
        resolve();
    })
    .catch((err) =>
        console.error("Error al cargar el archivo:", err),
    );
});

let tePrometoLeerExcel2 = new Promise((resolve, reject) => {
    fetch("outputs/llamadas9112025/Tabla_DiaXHora_new.xlsx") // Debe estar accesible públicamente
    .then((response) => {
        if (!response.ok) {
            throw new Error("No se pudo cargar el archivo Excel");
        }
        return response.arrayBuffer();
    })
    .then((data) => {
        try {
            const workbook = XLSX.read(data, { type: "array" });
            const firstSheetName = workbook.SheetNames[0];
            const worksheet = workbook.Sheets[firstSheetName];
            DiaXHora = XLSX.utils.sheet_to_json(worksheet, { defval: null });
            validarColumnas(DiaXHora, COLUMNAS_DIA_HORA, "Tabla_DiaXHora_new.xlsx");
        } catch (error) {
            console.error("Error al procesar el Excel:", error);
        }
        resolve();
    })
    .catch((err) =>
        console.error("Error al cargar el archivo:", err),
    );
});


Promise.all([tePrometoLeerExcel, tePrometoLeerExcel2, tePrometoLeerInfo]).then(
    () => {
        Rellenar_Mpio();
        Rellenar_Clasificacion();
    },
);

// Municipio
function Rellenar_Mpio() {
    const datalist = document.getElementById('Mpios');
    datalist.innerHTML = '';

    let lista = [...new Set(AñoXMes.map(row => row.Municipio))];

    // Opción agregada (RF-2): además de cada municipio individual, se
    // puede elegir "Todos los municipios" para la vista estadística
    // agregada (mapa coroplético + gráficas municipales).
    const listaConTodos = [TODOS_MUNICIPIOS, ...lista];

    listaConTodos.forEach(item => {
        const option = document.createElement('option');
        option.value = item;
        datalist.appendChild(option);
    });

    // El comportamiento por defecto al cargar la página se conserva: se
    // sigue arrancando en un municipio específico, no en la vista agregada.
    document.getElementById("selector_municipio").value = "";
    document.getElementById("selector_municipio").value = lista[0];

    let primer_municipio = lista[0];
    Rellenar_Colonia(primer_municipio);
}

// Clasificación (RF-1): se llama una sola vez, cuando ya se cargó
// Base 911.json y por lo tanto ya existe la lista CLASIFICACIONES
// (ver Cargar_Resumen.js).
function Rellenar_Clasificacion() {
    const datalist = document.getElementById('Clas');
    datalist.innerHTML = '';

    CLASIFICACIONES.forEach(item => {
        const option = document.createElement('option');
        option.value = item;
        datalist.appendChild(option);
    });

    // Si el valor por defecto de estado.js no existiera entre las
    // Clasificaciones reales (p. ej. si cambia el pipeline de datos),
    // caemos a la primera disponible en vez de dejar el selector vacío.
    if (!CLASIFICACIONES.includes(estado.clasificacion)) {
        estado.clasificacion = CLASIFICACIONES[0];
    }
    document.getElementById("selector_clasificacion").value = estado.clasificacion;
}

// Colonia
function Rellenar_Colonia(M) {
    estado.municipio = M;

    if (M === TODOS_MUNICIPIOS) {
        // Vista agregada (RF-2): Colonia e Incidente no aplican aquí, así
        // que se ocultan y no se corre la cascada habitual. El mapa y las
        // gráficas municipales reaccionan directamente a Clasificación
        // (ver renderMapa/renderTreemap/renderSerieTemporal/renderHeatmap).
        mostrarFiltrosPorMunicipio(false);
        notificarCambio();
        return;
    }
    mostrarFiltrosPorMunicipio(true);

    const datalist = document.getElementById('Cols');
    datalist.innerHTML = '';

    let filtrado_M = AñoXMes.filter(row => row.Municipio === M);
    let lista = [...new Set(filtrado_M.map(row => row.Colonia))];

    lista.forEach(item => {
        const option = document.createElement('option');
        option.value = item;
        datalist.appendChild(option);
    });

    document.getElementById("selector_colonia").value = "";
    document.getElementById("selector_colonia").value = lista[0];

    let primera_colonia = lista[0];
    Rellenar_Incidente(M, primera_colonia);
}

// Incidente
function Rellenar_Incidente(M, C) {
    estado.colonia = C;

    let incidente_anterior = estado.incidente;

    const datalist = document.getElementById('Inds');
    datalist.innerHTML = '';

    let filtrado_M = AñoXMes.filter(row => row.Municipio === M);
    let filtrado_M2 = filtrado_M.filter(row => row.Colonia === C);
    let lista = [...new Set(filtrado_M2.map(row => row.Incidente))];

    lista.forEach(item => {
        const option = document.createElement('option');
        option.value = item;
        datalist.appendChild(option);
    });

    if (lista.includes(incidente_anterior)) {
        estado.incidente = incidente_anterior;
    } else {
        estado.incidente = lista[0];
    }

    document.getElementById("selector_incidente").value = estado.incidente;

    // Antes: Generar_Todo(M, C, estado.incidente)
    // Ahora: cada gráfica se suscribió sola en su propio archivo,
    // así que solo hace falta avisar que el estado ya quedó listo.
    notificarCambio();
}

// Para que se reincie la cajita del buscador
$("#selector_colonia").focus(function () {
    $(this).val('');
});
$("#selector_incidente").focus(function () {
    $(this).val('');
});
$("#selector_municipio").focus(function () {
    $(this).val('');
});
$("#selector_clasificacion").focus(function () {
    $(this).val('');
});

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
        // La cascada completa (Municipio -> Colonia -> Clasificación ->
        // Incidente) arranca sola desde Rellenar_Mpio(); ya no hace falta
        // llamar a Clasificación por separado.
        Rellenar_Mpio();
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

// Clasificación, sólo para la vista agregada "Todos los municipios"
// (RF-2): ahí Colonia/Incidente no aplican, así que Clasificación no se
// filtra por Colonia y muestra el catálogo completo (CLASIFICACIONES,
// ver Cargar_Resumen.js). Para la vista de un municipio específico, las
// opciones de Clasificación las llena Rellenar_Clasificacion(M, C) más
// abajo, filtradas por Municipio + Colonia.
function Rellenar_Clasificacion_Global() {
    const datalist = document.getElementById('Clas');
    datalist.innerHTML = '';

    CLASIFICACIONES.forEach(item => {
        const option = document.createElement('option');
        option.value = item;
        datalist.appendChild(option);
    });

    // Si el valor actual no existiera entre las Clasificaciones reales
    // (p. ej. si cambia el pipeline de datos), caemos a la primera
    // disponible en vez de dejar el selector vacío.
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
        // (ver renderMapa/renderTreemap/renderSerieTemporal/renderHeatmap),
        // que en este caso muestra el catálogo completo.
        mostrarFiltrosPorMunicipio(false);
        Rellenar_Clasificacion_Global();
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
    Rellenar_Clasificacion(M, primera_colonia);
}

// Clasificación (para un municipio específico): sus opciones son las
// Clasificaciones de los Incidentes que realmente existen para la
// combinación Municipio + Colonia, usando el mapeo
// INCIDENTE_A_CLASIFICACION (derivado de Base 911.json, ver
// Cargar_Resumen.js). Al terminar, dispara Rellenar_Incidente para que
// el campo Incidente quede filtrado por esta Clasificación.
function Rellenar_Clasificacion(M, C) {
    estado.colonia = C;

    let clasificacion_anterior = estado.clasificacion;

    const datalist = document.getElementById('Clas');
    datalist.innerHTML = '';

    let filtrado_M = AñoXMes.filter(row => row.Municipio === M);
    let filtrado_MC = filtrado_M.filter(row => row.Colonia === C);
    let incidentesDisponibles = [...new Set(filtrado_MC.map(row => row.Incidente))];

    let lista = [...new Set(
        incidentesDisponibles
            .map(incidente => INCIDENTE_A_CLASIFICACION[incidente])
            .filter(c => c !== null && c !== undefined && c !== "")
    )].sort((a, b) => a.localeCompare(b, "es"));

    lista.forEach(item => {
        const option = document.createElement('option');
        option.value = item;
        datalist.appendChild(option);
    });

    // Si la Clasificación previamente elegida sigue siendo válida para
    // esta Colonia, se conserva; si no, caemos a la primera disponible.
    let clasificacion_actual = lista.includes(clasificacion_anterior)
        ? clasificacion_anterior
        : lista[0];

    document.getElementById("selector_clasificacion").value = clasificacion_actual;

    Rellenar_Incidente(M, C, clasificacion_actual);
}

// Incidente: depende de Municipio + Colonia + Clasificación. Si el
// usuario cambia de Clasificación, el Incidente anterior deja de estar
// en la lista filtrada (cada Incidente pertenece a una sola
// Clasificación) y el campo se "limpia" solo, cayendo al primero de la
// nueva lista.
//
// Además de los Incidentes reales de esa Clasificación, se agrega al
// final la opción especial TODOS_INCIDENTES ("Todas"): al elegirla, las
// gráficas (ver charts/*.js) agregan (suman Recuento, promedian X/Y)
// todos los Incidentes de la Clasificación seleccionada para este
// Municipio + Colonia, en vez de mostrar uno solo. Se agrega al final,
// no al inicio, para no cambiar el Incidente que queda seleccionado por
// defecto (se conserva el comportamiento actual).
function Rellenar_Incidente(M, C, Cl) {
    estado.clasificacion = Cl;

    let incidente_anterior = estado.incidente;

    const datalist = document.getElementById('Inds');
    datalist.innerHTML = '';

    let filtrado_M = AñoXMes.filter(row => row.Municipio === M);
    let filtrado_MC = filtrado_M.filter(row => row.Colonia === C);
    let filtrado_MCCl = filtrado_MC.filter(row => INCIDENTE_A_CLASIFICACION[row.Incidente] === Cl);
    let incidentesReales = [...new Set(filtrado_MCCl.map(row => row.Incidente))];
    let lista = [...incidentesReales, TODOS_INCIDENTES];

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
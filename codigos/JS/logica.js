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
    },
);

// Municipio
function Rellenar_Mpio() {
    const datalist = document.getElementById('Mpios');
    datalist.innerHTML = '';

    let lista = [...new Set(AñoXMes.map(row => row.Municipio))];

    lista.forEach(item => {
        const option = document.createElement('option');
        option.value = item;
        datalist.appendChild(option);
    });

    document.getElementById("selector_municipio").value = "";
    document.getElementById("selector_municipio").value = lista[0];

    let primer_municipio = lista[0];
    Rellenar_Colonia(primer_municipio);
}

// Colonia
function Rellenar_Colonia(M) {
    estado.municipio = M;
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

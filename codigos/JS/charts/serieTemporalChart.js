// Gráfica de la serie temporal (llamadas por mes/año + línea de
// regresión). Se suscribe a los cambios de estado al final de este
// archivo.

let Hist;

function renderSerieTemporal(M, C, I, Cl, Mc) {
    if (M === TODOS_MUNICIPIOS) {
        renderSerieTemporalMunicipal(Cl, Mc);
        return;
    }

    // Cuando I es TODOS_INCIDENTES ("Todas"), agregamos (sum Recuento)
    // todos los Incidentes de la Clasificación Cl para esta Colonia +
    // Municipio, agrupando por Fecha (ver agregarPorClasificacion en
    // funciones_extras.js).
    let H_filtrado;
    if (I === TODOS_INCIDENTES) {
        const filas = AñoXMes.filter(row =>
            row.Colonia === C &&
            row.Municipio === M &&
            INCIDENTE_A_CLASIFICACION[row.Incidente] === Cl
        );
        H_filtrado = agregarPorClasificacion(filas, ["Colonia", "Municipio", "Fecha"]);
    } else {
        H_filtrado = AñoXMes.filter(row => row.Colonia === C && row.Municipio === M && row.Incidente === I);
    }
    let Valor_Recuento = H_filtrado.map(row => row.Recuento);
    let Fechas = H_filtrado.map(row => row.Fecha);

    let combinado = Fechas.map((fecha, i) => ({
        fecha,
        dato: Valor_Recuento[i]
    }));
    combinado.sort((a, b) => new Date(a.fecha) - new Date(b.fecha));

    Fechas = combinado.map(x => x.fecha);
    Valor_Recuento = combinado.map(x => x.dato);

    let Eje_X_numerico = Fechas.map((_, i) => i);

    let Regresion_Datos = Regresion(Eje_X_numerico, Valor_Recuento);
    let m = Regresion_Datos.pendiente;
    let b = Regresion_Datos.constante;

    const ctx2 = document.getElementById('miBarras').getContext('2d');
    if (Hist) {
        Hist.destroy();
    }
    Hist = new Chart(ctx2, {
        type: 'line',
        data: {
            labels: Fechas,
            datasets: [
                {
                    label: 'Cantidad de llamadas',
                    data: Valor_Recuento,
                    showLine: true,
                    borderColor: 'rgba(138,0,0,1)',
                    backgroundColor: 'rgba(138,0,0,1)',
                    pointRadius: 6,
                    order: 1
                },
                {
                    label: 'Regresión',
                    data: Eje_X_numerico.map(i => m * i + b),
                    type: 'line',
                    showLine: true,
                    fill: false,
                    borderColor: 'rgba(54, 162, 235, 1)',
                    borderWidth: 2,
                    pointRadius: 0,
                    order: 2
                }
            ]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                title: {
                    text: "Cantidad de llamadas por mes y año en " + C + ", " + M,
                    padding: { top: 0, bottom: 0 },
                    display: true
                },
                subtitle: {
                    text: I,
                    display: true,
                    padding: { top: 0, bottom: 0 },
                }
            },
            scales: {
                x: {
                    type: 'category',
                    title: { display: true, text: 'Mes y Año' }
                },
                y: {
                    beginAtZero: true,
                    title: { display: true, text: 'Cantidad de Llamadas' }
                }
            }
        }
    });
}

// Serie temporal para "Todos los municipios" (RF-4.1): usa
// Histórico_AñoXMes_municipal.xlsx, que viene a nivel de Incidente
// detallado, así que se agrega por Fecha sumando solo los incidentes
// cuya Clasificación (según INCIDENTE_A_CLASIFICACION) es la
// seleccionada.
function renderSerieTemporalMunicipal(Cl, Municipio_clicked = "Pachuca de Soto") {
    cargarDatosMunicipales().then(() => {
        if (estado.municipio !== TODOS_MUNICIPIOS) {
            return;
        }

        const filtrado = AnioXMes_Municipal.filter(
           row => row.Incidente === Cl &&
            row.Municipio === Municipio_clicked
        );

        let Valor_Recuento = filtrado.map(row => row.Recuento);
        let Fechas = filtrado.map(row => row.Fecha);

        let combinado = Fechas.map((fecha, i) => ({
            fecha,
            dato: Valor_Recuento[i]
        }));
        combinado.sort((a, b) => new Date(a.fecha) - new Date(b.fecha));


        let Eje_X_numerico = Fechas.map((_, i) => i);

        let Regresion_Datos = Regresion(Eje_X_numerico, Valor_Recuento);
        let m = Regresion_Datos.pendiente;
        let b = Regresion_Datos.constante;

        const ctx2 = document.getElementById('miBarras').getContext('2d');
        if (Hist) {
            Hist.destroy();
        }
        Hist = new Chart(ctx2, {
            type: 'line',
            data: {
                labels: Fechas,
                datasets: [
                    {
                        label: 'Cantidad de llamadas',
                        data: Valor_Recuento,
                        showLine: true,
                        borderColor: 'rgba(138,0,0,1)',
                        backgroundColor: 'rgba(138,0,0,1)',
                        pointRadius: 6,
                        order: 1
                    },
                    {
                        label: 'Regresión',
                        data: Eje_X_numerico.map(i => m * i + b),
                        type: 'line',
                        showLine: true,
                        fill: false,
                        borderColor: 'rgba(54, 162, 235, 1)',
                        borderWidth: 2,
                        pointRadius: 0,
                        order: 2
                    }
                ]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    title: {
                        text: "Cantidad de llamadas por mes y año en " + Municipio_clicked,
                        padding: { top: 0, bottom: 0 },
                        display: true
                    },
                    subtitle: {
                        text: Cl,
                        display: true,
                        padding: { top: 0, bottom: 0 },
                    }
                },
                scales: {
                    x: {
                        type: 'category',
                        title: { display: true, text: 'Mes y Año' }
                    },
                    y: {
                        beginAtZero: true,
                        title: { display: true, text: 'Cantidad de Llamadas' }
                    }
                }
            }
        });
    });
}

suscribirse(renderSerieTemporal);

// Gráfica del heatmap día x hora (Chart.js "matrix"). Se suscribe a
// los cambios de estado al final de este archivo.

let Heat;

function renderHeatmap(M, C, I, Cl, Mc) {
    if (M === TODOS_MUNICIPIOS) {
        renderHeatmapMunicipal(Cl, Mc);
        return;
    }

    // Cuando I es TODOS_INCIDENTES ("Todas"), agregamos (sum Recuento)
    // todos los Incidentes de la Clasificación Cl para esta Colonia +
    // Municipio, agrupando por Día de la semana + Hora (ver
    // agregarPorClasificacion en funciones_extras.js).
    let D_filtrado;
    if (I === TODOS_INCIDENTES) {
        const filas = DiaXHora.filter(row =>
            row.Colonia === C &&
            row.Municipio === M &&
            INCIDENTE_A_CLASIFICACION[row.Incidente] === Cl
        );
        D_filtrado = agregarPorClasificacion(filas, ["Colonia", "Municipio", "Dia_Semana", "Hora"]);
    } else {
        D_filtrado = DiaXHora.filter(row => row.Colonia === C && row.Municipio === M && row.Incidente === I);
    }
    let Dias = D_filtrado.map(row => row.Dia_Semana);
    let Horas = D_filtrado.map(row => row.Hora);
    let Cuantos = D_filtrado.map(row => row.Recuento);

    let juntos = Horas.map((hora, i) => ({
        x: hora,
        y: Dias[i],
        v: Cuantos[i]
    }));

    console.log("Datos para heatmap:", juntos);

    const ctx3 = document.getElementById("heatmap").getContext("2d");
    let maxi = Math.max(...Cuantos);

    if (Heat) {
        Heat.destroy();
    }
    Heat = new Chart(ctx3, {
        type: "matrix",
        data: {
            datasets: [{
                label: "Heatmap",
                data: juntos,
                parsing: {
                    xAxisKey: 'x',
                    yAxisKey: 'y'
                },

                backgroundColor(context) {
                    if (!context.raw) return "rgba(138,0,0,0)";

                    const v = Number(context.raw.v) || 0;
                    return `rgba(138,0,0,${Math.min(v / maxi, 1)})`;
                },

                width: ({ chart }) => {
                    const area = chart.chartArea;
                    return area ? area.width / 24 : 20;
                },

                height: ({ chart }) => {
                    const area = chart.chartArea;
                    return area ? area.height / 8 : 20;
                }
            }]
        },

        options: {
            responsive: true,
            animation: false,
            maintainAspectRatio: false,
            plugins: {
                tooltip: {
                    callbacks: {
                        title: (context) => {
                            const item = context[0].raw;
                            return `${item.y} | ${item.x}:00 h`;
                        },
                        label: (context) => {
                            const v = context.raw.v;
                            return `Cantidad de llamadas: ${v}`;
                        }
                    }
                },
                legend: { display: false },
                title: {
                    text: "Cantidad de llamadas por hora y día en " + C + ", " + M,
                    display: true,
                    padding: { top: 0, bottom: 0 }
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
                    labels: [
                        '00', '01', '02', '03', '04', '05', '06', '07',
                        '08', '09', '10', '11', '12', '13', '14', '15',
                        '16', '17', '18', '19', '20', '21', '22', '23'
                    ]
                },
                y: {
                    type: 'category',
                    labels: ['', 'Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', '']
                }
            }
        }
    });
}

// Heatmap para "Todos los municipios" (RF-4.2): usa
// Tabla_DiaXHora_municipal.xlsx, que viene a nivel de Incidente
// detallado, así que se agrega por (Día, Hora) sumando solo los
// incidentes cuya Clasificación (según INCIDENTE_A_CLASIFICACION) es la
// seleccionada.
function renderHeatmapMunicipal(Cl, Municipio_clicked = "Pachuca de Soto") {
    cargarDatosMunicipales().then(() => {
        if (estado.municipio !== TODOS_MUNICIPIOS) {
            return;
        }



        const filtrado = DiaXHora_Municipal.filter(
            row => row.Incidente === Cl &&
            row.Municipio === Municipio_clicked
        );

       let dias = filtrado.map(row => row.Dia_Semana);
       let horas = filtrado.map(row => row.Hora);
       let cuantos = filtrado.map(row => row.Recuento);

       let juntos = horas.map((hora, i) => ({
            x: hora,
            y: dias[i],
            v: cuantos[i]
        }));

        console.log("Datos para heatmap municipal:", juntos);

        const ctx3 = document.getElementById("heatmap").getContext("2d");
        let maxi = Math.max(...juntos.map(d => d.v), 1);

        if (Heat) {
            Heat.destroy();
        }
        Heat = new Chart(ctx3, {
            type: "matrix",
            data: {
                datasets: [{
                    label: "Heatmap",
                    data: juntos,
                    parsing: {
                        xAxisKey: 'x',
                        yAxisKey: 'y'
                    },

                    backgroundColor(context) {
                        if (!context.raw) return "rgba(138,0,0,0)";

                        const v = Number(context.raw.v) || 0;
                        return `rgba(138,0,0,${Math.min(v / maxi, 1)})`;
                    },

                    width: ({ chart }) => {
                        const area = chart.chartArea;
                        return area ? area.width / 24 : 20;
                    },

                    height: ({ chart }) => {
                        const area = chart.chartArea;
                        return area ? area.height / 8 : 20;
                    }
                }]
            },

            options: {
                responsive: true,
                animation: false,
                maintainAspectRatio: false,
                plugins: {
                    tooltip: {
                        callbacks: {
                            title: (context) => {
                                const item = context[0].raw;
                                return `${item.y} | ${item.x}:00 h`;
                            },
                            label: (context) => {
                                const v = context.raw.v;
                                return `Cantidad de llamadas: ${v}`;
                            }
                        }
                    },
                    legend: { display: false },
                    title: {
                        text: "Cantidad de llamadas por hora y día en " + Municipio_clicked,
                        display: true,
                        padding: { top: 0, bottom: 0 }
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
                        labels: [
                            '00', '01', '02', '03', '04', '05', '06', '07',
                            '08', '09', '10', '11', '12', '13', '14', '15',
                            '16', '17', '18', '19', '20', '21', '22', '23'
                        ]
                    },
                    y: {
                        type: 'category',
                        labels: ['', 'Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', '']
                    }
                }
            }
        });
    });
}

suscribirse(renderHeatmap);

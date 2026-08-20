// Gráfica del treemap (Chart.js). Se suscribe a los cambios de estado
// al final de este archivo.

let chart;

function renderTreemap(M, C, I, Cl) {
    if (M === TODOS_MUNICIPIOS) {
        renderTreemapMunicipal(Cl);
        return;
    }

    // El treemap se filtra por la Clasificación seleccionada Cl (además
    // de Municipio + Colonia), sin importar si el Incidente elegido es
    // uno específico o TODOS_INCIDENTES ("Todas"): siempre muestra el
    // desglose de los incidentes que pertenecen a esa Clasificación.
    const Colonia_feature = {
        type: "FeatureCollection",
        features: INFO.features.filter(feature =>
            feature.properties.Municipio === M &&
            feature.properties.Colonia === C &&
            INCIDENTE_A_CLASIFICACION[feature.properties.Incidente] === Cl
        )
    };
    const datosParaGrafica = Colonia_feature.features.map(f => ({
        categoria: f.properties.Incidente,
        valor: f.properties.Recuento
    }));

    const top10Datos = datosParaGrafica
        .sort((a, b) => b.valor - a.valor)
        .slice(0, 10);

    const ctx = document.getElementById('miTreemap').getContext('2d');
    if (chart) {
        chart.destroy();
    }
    chart = new Chart(ctx, {
        type: 'treemap',
        data: {
            datasets: [{
                label: 'Incidentes en' + C,
                tree: top10Datos,
                key: 'valor',
                groups: ['categoria'],
                spacing: 1,
                borderWidth: 1,
                borderColor: 'white',
                labels: {
                    display: true,
                    formatter: (ctx) => {
                        const data = ctx.raw._data;
                        return [`${data.categoria}`, `Total: ${data.valor}`];
                    },
                    font: { size: 12, weight: 'bold' },
                    color: 'white',
                    overflow: 'fit',
                    display: true,
                },
                backgroundColor: (ctx) => {
                    const colors = ['#4A0E4E', '#483D8B', '#3B5998', '#20B2AA', '#32CD32'];
                    return colors[ctx.dataIndex % colors.length];
                }
            }]
        },
        options: {
            // Al hacer click en un recuadro del treemap, actualizamos
            // el incidente seleccionado y notificamos el cambio — las
            // 4 gráficas (incluido este mismo treemap) se redibujan solas.
            onClick: (event, elements) => {
                if (elements.length > 0) {
                    const elemento = elements[0];
                    const index = elemento.index;
                    const data = chart.data.datasets[0].data[index];
                    estado.incidente = data.g;

                    document.getElementById("selector_incidente").value = estado.incidente;
                    notificarCambio();
                }
            },
            plugins: {
                legend: {
                    display: false
                },
                tooltip: {
                    callbacks: {
                        title(items) {
                            const item = items[0].raw._data;
                            return item.categoria;
                        },
                        label: (item) => `Cantidad de llamadas: ${item.raw.v}`,
                    }
                },
                title: {
                    text: "Top de incidentes en " + C + ", " + M,
                    display: true,
                    padding: { top: 0, bottom: 0 },
                },
                // Subtítulo con la Clasificación: el treemap ahora
                // siempre está filtrado por ella, así que siempre es
                // relevante mostrarla.
                subtitle: {
                    text: Cl,
                    display: true,
                    padding: { top: 0, bottom: 0 },
                },
            },
            maintainAspectRatio: false
        }
    });
}

// Treemap para "Todos los municipios" (RF-4.3): usa directamente
// Base municipal.geojson (no los xlsx), tomando para cada municipio el
// valor de la columna que corresponde a la Clasificación seleccionada.
function renderTreemapMunicipal(Cl) {
    cargarDatosMunicipales().then(() => {
        if (estado.municipio !== TODOS_MUNICIPIOS || !MUNICIPAL_GEOJSON) {
            return;
        }

        const featureEjemplo = MUNICIPAL_GEOJSON.features[0];
        const columna = buscarColumnaClasificacion(featureEjemplo.properties, Cl);
        if (!columna) {
            console.error(`No se encontró en Base municipal.geojson la columna correspondiente a la Clasificación "${Cl}".`);
            return;
        }

        const datosParaGrafica = MUNICIPAL_GEOJSON.features
            .map(f => ({
                categoria: f.properties.Municipio,
                valor: f.properties[columna]
            }))
            .filter(d => d.valor !== null && d.valor !== undefined && !isNaN(d.valor));

        const top10Datos = datosParaGrafica
            .sort((a, b) => b.valor - a.valor)
            .slice(0, 10);

        const ctx = document.getElementById('miTreemap').getContext('2d');
        if (chart) {
            chart.destroy();
        }
        chart = new Chart(ctx, {
            type: 'treemap',
            data: {
                datasets: [{
                    label: 'Municipios - ' + Cl,
                    tree: top10Datos,
                    key: 'valor',
                    groups: ['categoria'],
                    spacing: 1,
                    borderWidth: 1,
                    borderColor: 'white',
                    labels: {
                        display: true,
                        formatter: (ctx) => {
                            const data = ctx.raw._data;
                            return [`${data.categoria}`, `Total: ${data.valor}`];
                        },
                        font: { size: 12, weight: 'bold' },
                        color: 'white',
                        overflow: 'fit',
                        display: true,
                    },
                    backgroundColor: (ctx) => {
                        const colors = ['#4A0E4E', '#483D8B', '#3B5998', '#20B2AA', '#32CD32'];
                        return colors[ctx.dataIndex % colors.length];
                    }
                }]
            },
            options: {
                // Al hacer click en un municipio del treemap agregado,
                // saltamos a la vista de ese municipio específico
                // (reutiliza la misma cascada que el selector de Municipio).
                onClick: (event, elements) => {
                    if (elements.length > 0) {
                        const index = elements[0].index;
                        const data = chart.data.datasets[0].data[index];
                        document.getElementById("selector_municipio").value = data.g;
                        Rellenar_Colonia(data.g);
                    }
                },
                plugins: {
                    legend: {
                        display: false
                    },
                    tooltip: {
                        callbacks: {
                            title(items) {
                                const item = items[0].raw._data;
                                return item.categoria;
                            },
                            label: (item) => `Cantidad de llamadas: ${item.raw.v}`,
                        }
                    },
                    title: {
                        text: 'Top de municipios por "' + Cl + '"',
                        display: true,
                        padding: { top: 0, bottom: 0 },
                    },
                },
                maintainAspectRatio: false
            }
        });
    });
}

suscribirse(renderTreemap);

// Gráfica del treemap (Chart.js). Se suscribe a los cambios de estado
// al final de este archivo.

let chart;

function renderTreemap(M, C, I) {
    const Colonia_feature = {
        type: "FeatureCollection",
        features: INFO.features.filter(feature =>
            feature.properties.Municipio === M &&
            feature.properties.Colonia === C
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
            },
            maintainAspectRatio: false
        }
    });
}

suscribirse(renderTreemap);

// Gráfica de la serie temporal (llamadas por mes/año + línea de
// regresión). Se suscribe a los cambios de estado al final de este
// archivo.

let Hist;

function renderSerieTemporal(M, C, I) {
    let H_filtrado = AñoXMes.filter(row => row.Colonia === C && row.Municipio === M && row.Incidente === I);
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

suscribirse(renderSerieTemporal);

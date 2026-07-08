let chart;
let Hist;
let Heat;

//Necesitamos estas variables globales que serán las que nos dirá
//que selección tenemos para cada filtro actualmente

let seleccion = {
    municipio: "Pachuca De Soto",
    colonia: "Centro (Colonia)",
    incidente: "Otras Alarmas De Emergencias Activadas (Seguridad)"
}

let seleccion_ids = {
    municipio: "selector_municipio",
    colonia: "selector_colonia",
    incidente: "selector_incidente"
}

MUNICIPIO="Pachuca De Soto";
COLONIA="Centro (Colonia)";
INCIDENTE="Otras Alarmas De Emergencias Activadas (Seguridad)";
let geometria_seleccionada = null; 
let incidente_seleccionado = null;
let coordenadas_seleccionadas = null;

var mapa = L.map('map').setView([20.1, -98.7], 13);
L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    maxZoom: 19,
    attribution: '© OpenStreetMap'
}).addTo(mapa); //y añadimos la capa base

let Mapa_Act;


//Esta función será con la que generen los 4 gráficos 
//Habrá ejecutarla cada vez que se cambie el minicipio (M), la colonia (C) o el incidente (I)
function Generar_Todo(M,C,I){
    console.log(I);
    //MAPA primero

    //Como el mapa no depende de la colonia de interés C, solo vamos a filtrar
    //por el municipio M y el incidente I
    const filtrado = {
        type: "FeatureCollection",
        features: INFO.features.filter(feature => 
            feature.properties.Municipio === M &&
            feature.properties.Incidente === I 
        )
    };

    //obtenemos los valores maximos y mínimos de recuento ya filtrado
    const valores = filtrado.features.map(f => f.properties.Recuento);
    r_max = Math.max(...valores);
    r_min = Math.min(...valores);
    
        
    if (Mapa_Act) {
        mapa.removeLayer(Mapa_Act);
    }
    Mapa_Act=L.geoJSON(filtrado, {
        pointToLayer: function (feature, latlng) {
            //Crear el círculo y ajustar el radio
            return L.circleMarker(latlng, {
                radius: Radio(feature.properties.Recuento),
                fillColor: "#0D00B0",
                color: "#0D00B0",
                weight: 1,
                opacity: 1,
                fillOpacity: 0.8
            });
        },
        
        onEachFeature: function (feature, layer) {
            layer.on('click', function () {
                geometria_seleccionada = feature;
                coordenadas_seleccionadas = geometria_seleccionada.geometry.coordinates;
                geometria_seleccionada = geometria_seleccionada.properties.Colonia;

                console.log("Geometría seleccionada:", geometria_seleccionada);
                //console.log("Coordenadas seleccionadas:", coordenadas_seleccionadas);

                COLONIA = geometria_seleccionada;
                Rellenar_Incidente(MUNICIPIO, COLONIA); 
                geometria_seleccionada = null; 
            });
            if (feature.properties && feature.properties.Recuento) {
                layer.bindPopup("<h3 style='text-align: center; font-size: large;'><strong>"+
                                feature.properties.Colonia+"</strong></h3>"+
                                "<h5 style='text-align: center; font-size: medium;'><strong>"+
                                feature.properties.Municipio+"</strong></h5>"+
                                "<hr style='border: 0; height: 4px; background: linear-gradient(to right, transparent, #404040, transparent); margin: 10px 0 15px 0;'>"+
                                "<h4  style='text-align: center; font-size: medium;'>Llamadas totales: "+
                                feature.properties.Recuento +
                                "</h4>");
                layer.bindTooltip(feature.properties.Colonia);
            }
        }
    });
    Mapa_Act.addTo(mapa);
        //Esto es para que el zoom sea sobre la colonia
    let colonia_act={
        type: "FeatureCollection",
        features: filtrado.features.filter(
            feature => feature.properties.Colonia === C 
        )
    };
    
    const coords = colonia_act.features[0].geometry.coordinates;

    mapa.setView([coords[1], coords[0]], 14);

    Mapa_Act.eachLayer(function (layer) {
        if (layer.feature.properties.Colonia === C) {
            layer.openPopup();
        }
    });



    //TREEMAP
    //Vamos a filtrar el geojson a la colonia de interés C (en su respectivo municipio M)
    const Colonia_feature = {
        type: "FeatureCollection",
        features: INFO.features.filter(feature => 
            feature.properties.Municipio === M &&
            feature.properties.Colonia === C
        )
    };
    const datosParaGrafica = Colonia_feature.features.map(f => ({
        categoria: f.properties.Incidente, //Extraemos columna
        valor: f.properties.Recuento       //Extraemos columna
    }));

    const top10Datos = datosParaGrafica
        .sort((a, b) => b.valor - a.valor) //Orden descendente
        .slice(0, 10); //solo tomemos los 10 primeros

    //console.log("Vamos imprimir el top10Datos:", top10Datos);
    const ctx = document.getElementById('miTreemap').getContext('2d');
    if(chart){
        chart.destroy();
    }
    chart = new Chart(ctx, {
        type: 'treemap',
        data: {
            datasets: [{
                label: 'Incidentes en'+ C,
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
            // Para saber donde estamos haciendo click 
            onClick: (event, elements) => {
                if (elements.length > 0) {
                    const elemento = elements[0];
                    const index = elemento.index;
                    const data = chart.data.datasets[0].data[index];
                    INCIDENTE= data.g;

                    console.log("Incidente seleccionado:", INCIDENTE);
                    document.getElementById("selector_incidente").value=INCIDENTE;
                    Generar_Todo(MUNICIPIO, COLONIA, INCIDENTE);
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
                    text: "Top de incidentes en "+C+", "+M,
                    display: true,
                    padding: { top: 0, bottom: 0 },
                },
            },
            maintainAspectRatio: false
        }
    });


    //HISTÓRICO
    //Filtramos por colonia, municipio e incidente
    let H_filtrado=AñoXMes.filter(v => v[0] === C && v[1] === M && v[2] === I);
    let Valor_Recuento=H_filtrado.map(fila => fila[4]);
    let Fechas=H_filtrado.map(fila => fila[3]);

        //Combinar
    let combinado = Fechas.map((fecha, i) => ({
        fecha,
        dato: Valor_Recuento[i]
    }));
    //Ordenar por fecha ascendente
    combinado.sort((a, b) => new Date(a.fecha) - new Date(b.fecha));

    // Separar otra vez
    Fechas = combinado.map(x => x.fecha);
    Valor_Recuento = combinado.map(x => x.dato);

    let Eje_X_numerico = Fechas.map((_, i) => i);

    //Hacemos la regresión para obtener la pendiente y la constante
    let Regresion_Datos=Regresion(Eje_X_numerico,Valor_Recuento);
    let m = Regresion_Datos.pendiente; 
    let b = Regresion_Datos.constante;

    let lineaRegresion = Fechas.map((fecha, i) => ({
        x: fecha,
        y: m * i + b
    }));

    //
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
                    data: Eje_X_numerico.map(i => m*i + b),
                    type: 'line', // Sobrescribimos a tipo línea para unir los puntos
                    showLine: true, // Forzamos que se dibuje la línea
                    fill: false,
                    borderColor: 'rgba(54, 162, 235, 1)',
                    borderWidth: 2,
                    pointRadius: 0, // Ocultamos los puntos de la línea
                    order: 2
                }
            ]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                title: {
                    text: "Cantidad de llamadas por mes y año en "+C+", "+M,
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
                    title: { display: true, text: 'Mes y Año' } },
                y: {
                    beginAtZero: true,
                    title: { display: true, text: 'Cantidad de Llamadas' }
                }
            }
        }
    });

    //MAPA DE CALOR/////////////////////////////////////////////////////////////////////

    console.log(C)
    console.log(M)
    console.log(I)
    let D_filtrado = DiaXHora.filter(v => v[0] === C && v[1] === M && v[2] === I);
    console.log(D_filtrado) //Por alguna razón no hace nada
    let Dias = D_filtrado.map(fila => fila[3]);
    let Horas = D_filtrado.map(fila => fila[4]);
    let Cuantos = D_filtrado.map(fila => fila[5]);

    // Combinar
    let juntos = Horas.map((hora, i) => ({
        x: hora,
        y: Dias[i],
        v: Cuantos[i]
    }));
    console.log(juntos);
    //console.log(juntos[0]);
    //console.log([...new Set(juntos.map(d => d.x))]);
    //console.log([...new Set(juntos.map(d => d.y))]);
    const ctx3 = document.getElementById("heatmap").getContext("2d");

    let maxi=Math.max(...Cuantos)

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
                    return `rgba(138,0,0,${Math.min(v/maxi,1)})`;
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
                        // El cuerpo del tooltip (donde quieres el valor v)
                        label: (context) => {
                            const v = context.raw.v;
                            return `Cantidad de llamadas: ${v}`;
                        }
                    }
                },
                legend :{ display: false},
                title: {
                    text: "Cantidad de llamadas por hora y día en "+C+", "+M,
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
                        '00','01','02','03','04','05','06','07',
                        '08','09','10','11','12','13','14','15',
                        '16','17','18','19','20','21','22','23'
                    ]
                },
                y: {
                    type: 'category',
                    labels: ['','Domingo','Lunes','Martes','Miércoles','Jueves','Viernes','Sábado','']
                }
            }
        }
    });


}
        




         //Leemos el resumen para el histórico
        let AñoXMes = [];
        let DiaXHora = [];
        
        tePrometoLeerExcel = new Promise((resolve, reject) => {
            fetch("outputs/llamadas9112025/Histórico_AñoXMes_new.xlsx") // Debe estar accesible públicamente (Qué se supone que significa eso?)
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
                AñoXMes = XLSX.utils.sheet_to_json(worksheet, {
                    header: 1,
                });
                } catch (error) {
                console.error("Error al procesar el Excel:", error);
                }
                resolve();
            })
            .catch((err) =>
                console.error("Error al cargar el archivo:", err),
            );
        });

        tePrometoLeerExcel2 = new Promise((resolve, reject) => {
            fetch("outputs/llamadas9112025/Tabla_DiaXHora_new.xlsx") // Debe estar accesible públicamente (Qué se supone que significa eso?)
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
                DiaXHora = XLSX.utils.sheet_to_json(worksheet, {
                    header: 1,
                });
                } catch (error) {
                console.error("Error al procesar el Excel:", error);
                }
                resolve();
            })
            .catch((err) =>
                console.error("Error al cargar el archivo:", err),
            );
        });

        Promise.all([tePrometoLeerExcel, tePrometoLeerExcel2]).then(
            () => {
            Rellenar_Mpio();
            },
        );



        //Municipio
        function Rellenar_Mpio(){//M nos dirá el municipio que se ha escogido
            const datalist = document.getElementById('Mpios');

            //Limpiamos
            datalist.innerHTML = '';

            let lista = [...new Set(AñoXMes.map(fila => fila[1]))].filter(num => num !== "Municipio");
            //console.log("Lista limpia municipio:", lista);        

            //Vamos metiendolos
            lista.forEach(item => {
                const option = document.createElement('option');
                option.value = item
                datalist.appendChild(option);
            });

            document.getElementById("selector_municipio").value="";
            document.getElementById("selector_municipio").value=lista[0];
            
            let primer_municipio=lista[0];
            Rellenar_Colonia(primer_municipio); //Como ya tenemos la colonia ahora podemos llenar el Incidente
        }



        //Colonia
        function Rellenar_Colonia(M){//M nos dirá el municipio que se ha escogido
            MUNICIPIO=M;
            console.log(M);
            const datalist = document.getElementById('Cols');

            //Limpiamos
            datalist.innerHTML = '';

            let filtrado_M=AñoXMes.filter(v => v[1] === M); //Lo hago con AñoXMes pero se puede hacer con cualquera de los dos xlsx
            let lista = [...new Set(filtrado_M.map(fila => fila[0]))].filter(num => num !== "Colonia"); //Esto hace lo mismo pero con un set, además de eliminar el título de la columna

            //Vamos metiendolos
            lista.forEach(item => {
                const option = document.createElement('option');
                option.value = item
                datalist.appendChild(option);
            });

            document.getElementById("selector_colonia").value="";
            document.getElementById("selector_colonia").value=lista[0];
            
            let primera_colonia=lista[0];
            Rellenar_Incidente(M,primera_colonia); //Como ya tenemos la colonia ahora podemos llenar el Incidente
        }

        //Incidente
        function Rellenar_Incidente(M,C){//M nos dirá el municipio que se ha escogido
            
            //y C la colonia elegida
            COLONIA=C;
            console.log(C);

            let incidente_anterior = INCIDENTE;

            const datalist = document.getElementById('Inds');
            //Limpiamos
            datalist.innerHTML = '';

            let filtrado_M=AñoXMes.filter(v => v[1] === M); //Lo hago con AñoXMes pero se puede hacer con cualquera de los dos xlsx
            let filtrado_M2=filtrado_M.filter(v => v[0] === C);
            let lista = [...new Set(filtrado_M2.map(fila => fila[2]))].filter(num => num !== "Incidente"); //Esto hace lo mismo pero con un set, además de eliminar el título de la columna

            //Vamos metiendolos
            lista.forEach(item => {
                const option = document.createElement('option');
                option.value = item
                datalist.appendChild(option);
            });

            if (lista.includes(incidente_anterior)) {
                INCIDENTE = incidente_anterior;
            } else {
                INCIDENTE = lista[0];
            }

            console.log("Incidente seleccionado:", INCIDENTE);

            document.getElementById("selector_incidente").value=INCIDENTE;
            
            Generar_Todo(M,C,INCIDENTE)
        }
        
        //Para que se reincie la cajita del buscador
        $("#selector_colonia").focus(function() {
            // reiniciamos el valor del input a vacío.
            $(this).val('');
        });
        $("#selector_incidente").focus(function() {
            // reiniciamos el valor del input a vacío.
            $(this).val('');
        });
        $("#selector_municipio").focus(function() {
            // reiniciamos el valor del input a vacío.
            $(this).val('');
        });

// Gráfica del mapa (Leaflet). Se suscribe a los cambios de estado al
// final de este archivo y se redibuja sola; ningún otro archivo
// necesita saber que mapaChart.js existe.

var mapa = L.map('map').setView([20.1, -98.7], 13);
L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    maxZoom: 19,
    attribution: '© OpenStreetMap'
}).addTo(mapa);

let Mapa_Act;
let capaMunicipal = null;   // capa coroplética de "Todos los municipios"
let leyendaMunicipal = null; // control de leyenda de esa capa

function renderMapa(M, C, I, Cl) {
    if (M === TODOS_MUNICIPIOS) {
        renderMapaMunicipal(Cl);
        return;
    }

    // Si veníamos de la vista agregada, quitamos su capa/leyenda antes de
    // volver a dibujar el mapa de puntos habitual para un municipio.
    limpiarCapaMunicipal();

    // El mapa no depende de la colonia de interés C, solo se filtra
    // por el municipio M y el incidente I.
    const filtrado = {
        type: "FeatureCollection",
        features: INFO.features.filter(feature =>
            feature.properties.Municipio === M &&
            feature.properties.Incidente === I
        )
    };

    const valores = filtrado.features.map(f => f.properties.Recuento);
    r_max = Math.max(...valores);
    r_min = Math.min(...valores);

    if (Mapa_Act) {
        mapa.removeLayer(Mapa_Act);
    }
    Mapa_Act = L.geoJSON(filtrado, {
        pointToLayer: function (feature, latlng) {
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
                // Al hacer click en una colonia del mapa, delegamos en
                // Rellenar_Incidente (logica.js), que repuebla el
                // datalist de incidentes para esa colonia y al final
                // notifica el cambio — igual que hace el selector manual.
                Rellenar_Incidente(estado.municipio, feature.properties.Colonia);
            });
            if (feature.properties && feature.properties.Recuento) {
                layer.bindPopup("<h3 style='text-align: center; font-size: large;'><strong>" +
                    feature.properties.Colonia + "</strong></h3>" +
                    "<h5 style='text-align: center; font-size: medium;'><strong>" +
                    feature.properties.Municipio + "</strong></h5>" +
                    "<hr style='border: 0; height: 4px; background: linear-gradient(to right, transparent, #404040, transparent); margin: 10px 0 15px 0;'>" +
                    "<h4  style='text-align: center; font-size: medium;'>Llamadas totales: " +
                    feature.properties.Recuento +
                    "</h4>");
                layer.bindTooltip(feature.properties.Colonia);
            }
        }
    });
    Mapa_Act.addTo(mapa);

    // Zoom hacia la colonia seleccionada
    let colonia_act = {
        type: "FeatureCollection",
        features: filtrado.features.filter(feature => feature.properties.Colonia === C)
    };
    const coords = colonia_act.features[0].geometry.coordinates;
    mapa.setView([coords[1], coords[0]], 14);

    Mapa_Act.eachLayer(function (layer) {
        if (layer.feature.properties.Colonia === C) {
            layer.openPopup();
        }
    });
}

function limpiarCapaMunicipal() {
    if (capaMunicipal) {
        mapa.removeLayer(capaMunicipal);
        capaMunicipal = null;
    }
    if (leyendaMunicipal) {
        mapa.removeControl(leyendaMunicipal);
        leyendaMunicipal = null;
    }
}

// Mapa coroplético para "Todos los municipios" (RF-3): cada polígono de
// Base municipal.geojson se colorea según la columna que le corresponde
// a la Clasificación seleccionada.
function renderMapaMunicipal(Cl) {
    // Quitamos la capa de puntos del municipio individual, si estaba.
    if (Mapa_Act) {
        mapa.removeLayer(Mapa_Act);
        Mapa_Act = null;
    }

    cargarDatosMunicipales().then(() => {
        // El usuario pudo cambiar de opinión mientras se cargaban los
        // datos (volver a un municipio específico); si ya no estamos en
        // la vista agregada, no dibujamos nada.
        if (estado.municipio !== TODOS_MUNICIPIOS || !MUNICIPAL_GEOJSON) {
            return;
        }

        const featureEjemplo = MUNICIPAL_GEOJSON.features[0];
        const columna = buscarColumnaClasificacion(featureEjemplo.properties, Cl);
        if (!columna) {
            console.error(`No se encontró en Base municipal.geojson la columna correspondiente a la Clasificación "${Cl}".`);
            return;
        }

        const valores = MUNICIPAL_GEOJSON.features
            .map(f => f.properties[columna])
            .filter(v => v !== null && v !== undefined && !isNaN(v));
        const minVal = Math.min(...valores);
        const maxVal = Math.max(...valores);

        if (capaMunicipal) {
            mapa.removeLayer(capaMunicipal);
        }

        capaMunicipal = L.geoJSON(MUNICIPAL_GEOJSON, {
            style: (feature) => {
                const valor = feature.properties[columna];
                return {
                    fillColor: colorClasificacionMunicipal(valor, minVal, maxVal),
                    color: "#691c32",
                    weight: 1,
                    fillOpacity: 0.75
                };
            },
            onEachFeature: (feature, layer) => {
                const valor = feature.properties[columna];
                const valorTexto = (valor === null || valor === undefined || isNaN(valor))
                    ? "Sin dato" : valor;
                layer.bindTooltip(
                    "<strong>" + feature.properties.Municipio + "</strong><br>" +
                    Cl + ": " + valorTexto,
                    { sticky: true }
                );
                layer.on({
                    mouseover: (e) => e.target.setStyle({ weight: 3, color: "#450f21" }),
                    mouseout: (e) => capaMunicipal.resetStyle(e.target)
                });
            }
        });
        capaMunicipal.addTo(mapa);
        mapa.fitBounds(capaMunicipal.getBounds());

        dibujarLeyendaMunicipal(minVal, maxVal);
    });
}

function dibujarLeyendaMunicipal(minVal, maxVal) {
    if (leyendaMunicipal) {
        mapa.removeControl(leyendaMunicipal);
    }
    leyendaMunicipal = L.control({ position: "bottomright" });
    leyendaMunicipal.onAdd = function () {
        const div = L.DomUtil.create("div", "leyenda-municipal");
        div.style.background = "white";
        div.style.padding = "6px 8px";
        div.style.borderRadius = "4px";
        div.style.fontSize = "0.75rem";
        div.style.lineHeight = "1.3";
        div.style.boxShadow = "0 1px 4px rgba(0,0,0,0.3)";

        const pasos = RAMPA_COLOR_MUNICIPAL.length;
        let html = "<strong>Llamadas</strong><br>";
        for (let i = 0; i < pasos; i++) {
            const desde = Math.round(minVal + ((maxVal - minVal) * i) / pasos);
            const hasta = Math.round(minVal + ((maxVal - minVal) * (i + 1)) / pasos);
            html += "<i style=\"background:" + RAMPA_COLOR_MUNICIPAL[i] +
                ";width:14px;height:14px;display:inline-block;margin-right:4px;\"></i>" +
                desde + "&ndash;" + hasta + "<br>";
        }
        div.innerHTML = html;
        return div;
    };
    leyendaMunicipal.addTo(mapa);
}

suscribirse(renderMapa);

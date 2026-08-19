// Gráfica del mapa (Leaflet). Se suscribe a los cambios de estado al
// final de este archivo y se redibuja sola; ningún otro archivo
// necesita saber que mapaChart.js existe.

var mapa = L.map('map').setView([20.1, -98.7], 13);
L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    maxZoom: 19,
    attribution: '© OpenStreetMap'
}).addTo(mapa);

let Mapa_Act;

function renderMapa(M, C, I) {
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

suscribirse(renderMapa);

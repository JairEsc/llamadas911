let INFO = null;

// mapaChart.js y treemapChart.js usan INFO de forma síncrona dentro de
// sus funciones renderMapa()/renderTreemap(). Como el JSON ahora se
// carga por red (fetch), exponemos esta promesa para que logica.js
// pueda esperar a que INFO esté listo antes de disparar el primer
// notificarCambio() (ver Promise.all en logica.js).
let tePrometoLeerInfo = new Promise((resolve, reject) => {
    fetch("outputs/Base 911.json") // Debe estar accesible públicamente
        .then((response) => {
            if (!response.ok) {
                throw new Error("No se pudo cargar outputs/Base 911.json");
            }
            return response.json();
        })
        .then((registros) => {
            try {
                INFO = {
                    type: "FeatureCollection",
                    name: "Resumen_Colonias_new",
                    crs: { type: "name", properties: { name: "urn:ogc:def:crs:OGC:1.3:CRS84" } },
                    features: registros.map((row) => ({
                        type: "Feature",
                        properties: {
                            Colonia: row.Colonia,
                            Municipio: row.Municipio,
                            Incidente: row.Incidente,
                            Clasificacion: row.Clasificacion,
                            Recuento: row.Recuento
                        },
                        geometry: {
                            type: "Point",
                            // X = longitud, Y = latitud (ver nota arriba)
                            coordinates: [row.X, row.Y]
                        }
                    }))
                };
            } catch (error) {
                console.error("Error al procesar Base 911.json:", error);
            }
            resolve();
        })
        .catch((err) => {
            console.error("Error al cargar Base 911.json:", err);
            reject(err);
        });
});

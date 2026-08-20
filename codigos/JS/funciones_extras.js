//Slidebar
function toggleSidebar() {
  const sidebar = document.querySelector(".sidebar");
  sidebar.classList.toggle("collapsed");
}

// Regresión lineal
// Necesitarémos una función que dadas dos listas nos regrese la pendiente
// y la constante de la regresión lineal de los datos de esas dos listas
function Regresion(x, y) {
  let n = x.length; //asumiendo que son del mismo tamaño
  let sumX = 0;
  let sumY = 0;
  let sumXY = 0;
  let sumXX = 0;

  for (let i = 0; i < n; i++) {
    sumX += x[i];
    sumY += y[i];
    sumXY += x[i] * y[i];
    sumXX += x[i] * x[i];
  }

  //Fórmulas verificadas con apuntes de Margarita
  let pendiente = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX);
  let constante = (sumY - pendiente * sumX) / n;

  return { pendiente, constante };
}

//Para radio dinámico definimos
let r_min;
let r_max;
function Radio(v) {
  if (r_max != r_min) {
    return 5 + ((v - r_min) / (r_max - r_min)) * 15;
  }

  return 15;
}

function validarColumnas(datos, columnasEsperadas, nombreArchivo) {
    if (datos.length === 0) {
        console.error(`${nombreArchivo}: el archivo llegó vacío.`);
        return false;
    }
    const columnasReales = Object.keys(datos[0]);
    const faltantes = columnasEsperadas.filter(c => !columnasReales.includes(c));
    if (faltantes.length > 0) {
        console.error(
            `${nombreArchivo}: faltan columnas esperadas: ${faltantes.join(", ")}. ` +
            `Columnas encontradas: ${columnasReales.join(", ")}.`
        );
        return false;
    }
    return true;
}
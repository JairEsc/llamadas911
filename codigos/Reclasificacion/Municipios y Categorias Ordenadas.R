categorias_ordenadas = c(
  "Accidentes de tránsito",
  "Alarmas y objetos sospechosos",
  "Alcohol y drogas",
  "Alteración del orden público",
  "Amenazas, extorsión y conductas sospechosas",
  "Armas, explosivos y pirotecnia",
  "Asistencia y apoyo ciudadano",
  "Crisis de salud mental y suicidio",
  "Daños a bienes y propiedad",
  "Delitos electorales",
  "Delitos en materia de Hidrocarburo",
  "Delitos sexuales",
  "Emergencias médicas y lesiones",
  "Fenómenos naturales y riesgos urbanos",
  "Fraude y abuso patrimonial",
  "Incendios",
  "Incidentes con animales",
  "Incidentes y faltas viales",
  "Medio ambiente",
  "Otros incidentes de emergencia",
  "Personas no localizadas y libertad personal",
  "Robo y delitos patrimoniales",
  "Servicios públicos e infraestructura",
  "Sustancias peligrosas y materiales químicos",
  "Violencia de genero y grupos vulnerables"
)



municipios_ordenados = c(
  "Acatlán",
  "Acaxochitlán",
  "Actopan",
  "Agua Blanca de Iturbide",
  "Ajacuba",
  "Alfajayucan",
  "Almoloya",
  "Apan",
  "El Arenal",
  "Atitalaquia",
  "Atlapexco",
  "Atotonilco el Grande",
  "Atotonilco de Tula",
  "Calnali",
  "Cardonal",
  "Cuautepec de Hinojosa",
  "Chapantongo",
  "Chapulhuacán",
  "Chilcuautla",
  "Eloxochitlán",
  "Emiliano Zapata",
  "Epazoyucan",
  "Francisco I. Madero",
  "Huasca de Ocampo",
  "Huautla",
  "Huazalingo",
  "Huehuetla",
  "Huejutla de Reyes",
  "Huichapan",
  "Ixmiquilpan",
  "Jacala de Ledezma",
  "Jaltocán",
  "Juárez Hidalgo",
  "Lolotla",
  "Metepec",
  "San Agustín Metzquititlán",
  "Metztitlán",
  "Mineral del Chico",
  "Mineral del Monte",
  "La Misión",
  "Mixquiahuala de Juárez",
  "Molango de Escamilla",
  "Nicolás Flores",
  "Nopala de Villagrán",
  "Omitlán de Juárez",
  "San Felipe Orizatlán",
  "Pacula",
  "Pachuca de Soto",
  "Pisaflores",
  "Progreso de Obregón",
  "Mineral de la Reforma",
  "San Agustín Tlaxiaca",
  "San Bartolo Tutotepec",
  "San Salvador",
  "Santiago de Anaya",
  "Santiago Tulantepec de Lugo Guerrero",
  "Singuilucan",
  "Tasquillo",
  "Tecozautla",
  "Tenango de Doria",
  "Tepeapulco",
  "Tepehuacán de Guerrero",
  "Tepeji del Río de Ocampo",
  "Tepetitlán",
  "Tetepango",
  "Villa de Tezontepec",
  "Tezontepec de Aldama",
  "Tianguistengo",
  "Tizayuca",
  "Tlahuelilpan",
  "Tlahuiltepa",
  "Tlanalapa",
  "Tlanchinol",
  "Tlaxcoapan",
  "Tolcayuca",
  "Tula de Allende",
  "Tulancingo de Bravo",
  "Xochiatipan",
  "Xochicoatlán",
  "Yahualica",
  "Zacualtipán de Ángeles",
  "Zapotlán de Juárez",
  "Zempoala",
  "Zimapán"
)






categorias_secretariado = c(
  "Alcohol y Drogas",
  "Alteracion del Orden Publico",
  "Amenazas, Exstorsión y Conductas Sospechosas",
  "Daños a Bienes y Propiedad",
  "Delitos Electorales",
  "Delitos Sexuales",
  "Fraude y Abuso Patrimonial",
  "Homicidio y/o Lesiones",
  "Medio Ambiente",
  "Otros sin Especificar",
  "Personas no Localizadas y Libertad Personal",
  "Robo y Delitos Patrimoniales",
  "Violencia De Genero y Grupos Vulnerables"
)



################################

categorias_interes = c(
  "Alcohol y drogas", 
  "Alteración del orden público", 
  "Amenazas, extorsión y conductas sospechosas",               
  "Armas, explosivos y pirotecnia", 
  "Daños a bienes y propiedad", 
  "Personas no localizadas y libertad personal", 
  "Robo y delitos patrimoniales", 
  "Violencia de genero y grupos vulnerables", 
  "Delitos en materia de Hidrocarburo", 
  "Delitos sexuales"
  )

columnas_categorias_interes = paste(categorias_interes, "mil habitantes")



######################
### Municipios 911 ###
######################

datos = "outputs/Estadistica Ejercicio/Municipios 911.xlsx" |>  readxl::read_excel()
datos = datos |> 
  dplyr::select(Municipio, dplyr::any_of(columnas_categorias_interes)) |> 
  # dplyr::mutate(
  #   dplyr::across(
  #     .cols = dplyr::any_of(interes),
  #     .fns =  ~ (.x - min(.x, na.rm = T)) /  (max(.x, na.rm = T) - min(.x, na.rm = T))  #~.x |>  scale() |>  as.numeric()
  #   )
  # ) |> 
  tidyr::pivot_longer(
    cols = dplyr::any_of(columnas_categorias_interes),
    names_to = "Categorias",
    values_to = "Valor"
  ) |> 
  dplyr::mutate(
    Categorias = Categorias |>  gsub(pattern = "mil habitantes", replacement = "") |>  stringr::str_squish(),
  )

categorias_importancia = datos |> 
  dplyr::group_by(Categorias) |> 
  dplyr::summarise(Valor = Valor |>  sum(na.rm = T)) |> 
  dplyr::ungroup() |> 
  dplyr::arrange(Valor |>  dplyr::desc())



datos = datos |> 
  dplyr::group_by(Municipio) |> 
  dplyr::summarise(Valor = Valor |>  sum(na.rm = T)) |> 
  dplyr::ungroup() |> 
  dplyr::arrange(Valor |>  dplyr::desc())


municipios_orden_importancia = datos$Municipio
categorias_importancia = categorias_importancia$Categorias

#########################################################


datos = "outputs/Estadistica Ejercicio/Municipios Secretariado.xlsx" |>  readxl::read_excel()


datos = datos |> 
  dplyr::select(Municipio, dplyr::any_of(categorias_secretariado)) |> 
  tidyr::pivot_longer(
    cols = dplyr::any_of(categorias_secretariado),
    names_to = "Categorias",
    values_to = "Valor"
  ) 

categorias_secretariado_importancia = datos |> 
  dplyr::group_by(Categorias) |> 
  dplyr::summarise(Valor = Valor |>  sum(na.rm = T)) |> 
  dplyr::ungroup() |> 
  dplyr::arrange(Valor |>  dplyr::desc())


datos = datos |> 
  dplyr::group_by(Municipio) |> 
  dplyr::summarise(Valor = Valor |>  sum(na.rm = T)) |> 
  dplyr::ungroup() |> 
  dplyr::arrange(Valor |>  dplyr::desc())

municipios_secretariado_importancia = datos$Municipio
categorias_secretariado_importancia = categorias_secretariado_importancia$Categorias

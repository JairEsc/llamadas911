datos = "outputs/Estadistica Ejercicio/Municipios 911.xlsx" |>  readxl::read_excel()

interes = c("Accidentes de tránsito", "Alarmas y objetos sospechosos", "Alcohol y drogas", "Alteración del orden público", "Amenazas, extorsión y conductas sospechosas",               
            "Armas, explosivos y pirotecnia", "Asistencia y apoyo ciudadano", "Crisis de salud mental y suicidio", "Daños a bienes y propiedad", "Emergencias médicas y lesiones",
            "Fenómenos naturales y riesgos urbanos", "Fraude y abuso patrimonial", "Incendios", "Incidentes con animales", "Incidentes y faltas viales",
            "Medio ambiente", "Otros incidentes de emergencia", "Personas no localizadas y libertad personal", "Robo y delitos patrimoniales", "Servicios públicos e infraestructura", 
            "Sustancias peligrosas y materiales químicos", "Violencia de genero y grupos vulnerables", "Delitos en materia de Hidrocarburo", "Delitos sexuales", "Delitos electorales")


interes = c("Alcohol y drogas", "Alteración del orden público", "Amenazas, extorsión y conductas sospechosas",               
            "Armas, explosivos y pirotecnia", "Daños a bienes y propiedad", 
            "Personas no localizadas y libertad personal", "Robo y delitos patrimoniales", 
            "Violencia de genero y grupos vulnerables", "Delitos en materia de Hidrocarburo", "Delitos sexuales")


datos = datos |> 
  dplyr::select(Municipio, dplyr::any_of(interes))



top = datos |>
  tidyr::pivot_longer(
    cols = -Municipio,
    names_to = "Categoria",
    values_to = "Valor"
  ) |> 
  dplyr::group_by(Categoria) |> 
  dplyr::slice_max(order_by = Valor, n = 5, with_ties = F)  |> # with_ties = F, Te devuelve exactamente 5 municipios, aunque haya un empate. 
  dplyr::ungroup() |> 
  dplyr::arrange(Categoria, dplyr::desc(Valor))


top_collapse = top |> 
  dplyr::group_by(Categoria) |> 
  dplyr::summarise(Municipios_top = Municipio |> paste(collapse = ", ") |>  stringr::str_squish())
  

#a = top_collapse$Municipios_top[1] |> stringr::str_split(pattern = ",\\s*") |>  unlist() |>  stringr::str_squish()



### Funcion para ver colonias de interes ###

datos = "outputs/llamadas9112025/Resumen_Colonias_new.geojson" |>  sf::read_sf()

datos = datos |> 
  dplyr::mutate(
    Municipio = dplyr::case_when(
      Municipio == "Santiago Tulantepec De Lugo Guerrero" ~ "Santiago Tulantepec de Lugo Guerrero", 
      Municipio == "Mixquiahuala De Juárez" ~ "Mixquiahuala de Juárez", 
      Municipio == "Tepehuacán De Guerrero" ~ "Tepehuacán de Guerrero", 
      Municipio == "Zacualtipán De Ángeles" ~ "Zacualtipán de Ángeles", 
      Municipio == "Cuautepec De Hinojosa" ~ "Cuautepec de Hinojosa", 
      Municipio == "Molango De Escamilla" ~ "Molango de Escamilla", 
      Municipio == "Nopala De Villagrán" ~ "Nopala de Villagrán", 
      Municipio == "Progreso De Obregón" ~ "Progreso de Obregón", 
      Municipio == "Tulancingo De Bravo" ~ "Tulancingo de Bravo", 
      Municipio == "Villa De Tezontepec" ~ "Villa de Tezontepec", 
      Municipio == "Atotonilco De Tula" ~ "Atotonilco de Tula", 
      Municipio == "Zapotlán De Juárez" ~ "Zapotlán de Juárez", 
      Municipio == "Huejutla De Reyes" ~ "Huejutla de Reyes", 
      Municipio == "Mineral Del Chico" ~ "Mineral del Chico", 
      Municipio == "Mineral Del Monte" ~ "Mineral del Monte", 
      Municipio == "Omitlán De Juárez" ~ "Omitlán de Juárez", 
      Municipio == "Santiago De Anaya" ~ "Santiago de Anaya", 
      Municipio == "Huasca De Ocampo" ~ "Huasca de Ocampo", 
      Municipio == "Pachuca De Soto" ~ "Pachuca de Soto", 
      Municipio == "Tula De Allende" ~ "Tula de Allende", 
      Municipio == "Tepeji Del Río De Ocampo" ~ "Tepeji del Río de Ocampo", 
      Municipio == "Mineral De La Reforma" ~ "Mineral de la Reforma", 
      Municipio == "Tenango De Doria" ~ "Tenango de Doria", 
      Municipio == "Tezontepec De Aldama" ~ "Tezontepec de Aldama", 
      Municipio == "Jacala De Ledezma" ~ "Jacala de Ledezma", 
      Municipio == "Agua Blanca De Iturbide" ~ "Agua Blanca de Iturbide", 
      Municipio == "Atotonilco El Grande" ~ "Atotonilco el Grande", 
      T ~ Municipio
    )
  )


reclasificacion = "inputs/Reclasificacion/Reclasificacion911_Tania.xlsx" |> 
  readxl::read_excel()  |> 
  dplyr::select(Incidente, `Nueva clasificación`)



datos = datos |> 
  sf::st_drop_geometry() |> 
  dplyr::left_join(
    y = reclasificacion,
    by = "Incidente"
  )



datos = datos |> 
  dplyr::relocate(`Nueva clasificación`, .before = Incidente) |> 
  dplyr::rename(Clasificacion = `Nueva clasificación`)


for (i in 1:nrow(top_collapse)) {
  
  
  excel =  openxlsx::createWorkbook()
  excel |>  openxlsx::addWorksheet("Top municipios categorias")
  excel |>  openxlsx::writeData(sheet = "Top municipios categorias", x = top_collapse)
  
  #i = 1
  lista_mun = top_collapse$Municipios_top[i] |> stringr::str_split(pattern = ",\\s*") |>  unlist() |>  stringr::str_squish()
  filtro = datos |> 
    dplyr::filter(Clasificacion ==  top_collapse$Categoria[i] & Municipio %in% lista_mun)
  
  
  incidente_interes = filtro |> 
    dplyr::group_by(Municipio, Incidente) |> 
    dplyr::summarise(Recuento = Recuento |>  sum(na.rm = T)) |> 
    dplyr::ungroup() |> 
    dplyr::arrange(Municipio, Recuento |>  dplyr::desc()) |> 
    dplyr::group_by(Municipio) |> 
    dplyr::slice_max(order_by = Recuento, n = 5) |> 
    dplyr::ungroup() 
  
  excel |>  openxlsx::addWorksheet("Incidente interes")
  excel |>  openxlsx::writeData(sheet = "Incidente interes", x = incidente_interes)
  
  incidentes_top = incidente_interes$Incidente |>  unique()
  
  colonias_incidentes = filtro |> 
    dplyr::filter(Incidente %in% incidentes_top)
  
  
  colonias_incidentes = colonias_incidentes |> 
    dplyr::group_by(Municipio, Incidente) |> 
    dplyr::slice_max(order_by = Recuento, n = 5) |> 
    dplyr::arrange(Municipio, Incidente |>  dplyr::desc()) |> 
    dplyr::relocate(Municipio, .before = Colonia)
  
  # colonias_incidentes = colonias_incidentes |> 
  #   tidyr::pivot_wider(
  #     names_from = Incidente,
  #     values_from = Recuento,
  #     values_fill = NA
  #   )
  
   
  z = colonias_incidentes$Incidente |>  unique()
  nombres = z |>  gsub(pattern = "Del Orden Público Por",replacement = "") |>  stringr::str_squish()
  
  
  for (j in seq_along(z)) {
    p = colonias_incidentes |> 
      dplyr::filter(Incidente == z[j])
    
    
    excel |>  openxlsx::addWorksheet(nombres[j] |>  substr(start = 1, stop = 30) |>  stringr::str_squish())
    excel |>  openxlsx::writeData(sheet = nombres[j] |>  substr(start = 1, stop = 30) |>  stringr::str_squish(), x = p)
  }
  
  openxlsx::saveWorkbook(excel, paste0("outputs/Estadistica Ejercicio/Resumenes/", top_collapse$Categoria[i], ".xlsx"), overwrite = TRUE)
}



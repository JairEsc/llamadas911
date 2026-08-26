datos = "outputs/llamadas9112025/Resumen_Colonias_new.geojson" |>  sf::read_sf()

colonias = datos |> 
  dplyr::select(Municipio, Colonia, geometry) |> 
  unique() |> 
  dplyr::mutate(
    id = paste0(Municipio, "_" ,Colonia)
  ) 


colonias = colonias |> dplyr::group_by(id) |>  dplyr::slice(1)


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



datos = datos |> 
  dplyr::group_by(Municipio, Colonia, Clasificacion) |> 
  dplyr::summarise(Recuento = Recuento |>  sum(na.rm = T)) |> 
  dplyr::ungroup() 


datos = datos |> 
  dplyr::rename(Incidente = Clasificacion) |> 
  dplyr::select(Colonia, Municipio, Incidente, Recuento)



datos = datos |> 
  dplyr::mutate(
    id = paste0(Municipio, "_" ,Colonia)
  )



datos = datos |> 
  dplyr::left_join(
    y = colonias |>  dplyr::select(id),
    by = "id"
  ) |> 
  dplyr::select(-id) |>
  sf::st_as_sf(crs = 4326) |> 
  dplyr::arrange(Municipio, Colonia, Incidente, Recuento)



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
  


  
datos |>  sf::st_write("outputs/Estadistica Ejercicio/Base reclasificacion 911.geojson", delete_dsn = T)









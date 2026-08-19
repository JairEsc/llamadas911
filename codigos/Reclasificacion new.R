datos = "outputs/llamadas9112025/Resumen_Colonias_new.geojson" |>  sf::read_sf()


municipio = datos |> 
  sf::st_drop_geometry()  


municipio = municipio |>  
  dplyr::select(Municipio, Incidente, Recuento) |> 
  dplyr::group_by(Municipio, Incidente) |> 
  dplyr::summarise(Recuento = Recuento |>  sum(na.rm = T)) |> 
  dplyr::ungroup()






#############
reclasificacion = "inputs/Reclasificacion/Reclasificacion911_Tania.xlsx" |> 
  readxl::read_excel()  |> 
  dplyr::select(Incidente, `Nueva clasificación`) 




reclasificacion = reclasificacion |> 
  dplyr::mutate(
    `Nueva clasificación` = dplyr::if_else(condition = `Nueva clasificación` |>  is.na(), true = "Pendiente", false = `Nueva clasificación`)
  )
##################






reclasificacion$Delito %in% municipio$Incidente |>  all()
municipio$Incidente |>  unique() |> length()
reclasificacion$Delito |>  unique() |>  length()

municipio = municipio |> 
  dplyr::left_join(
    y = reclasificacion,
    by = c("Incidente" = "Incidente")
  )


municipio = municipio |> 
  dplyr::group_by(Municipio, `Nueva clasificación`) |> 
  dplyr::summarise(Recuento = Recuento |>  sum(na.rm = T)) |> 
  dplyr::ungroup() |> 
  dplyr::rename(Incidente = `Nueva clasificación`)



municipio = municipio |> 
  tidyr::pivot_wider(
    names_from = Incidente,
    values_from = Recuento,
    values_fill = 0
  )





infografias = "../../Importantes_documentos_usar/Infografias Base Enero 2026.xlsx" |> 
  readxl::read_excel()

# infografias = infografias |> 
#   dplyr::select(CVE_MUN, Municipio, `Población total`, `Población Hombres`, `Población Mujeres`,
#                 `Población infantil (0-14 años)`, 
#                 `Población juvenil (15-29 años)`,
#                 `Población adulta (30-59 años)`,
#                 `Población adulta mayor (60 y más años)`)



infografias = infografias |> 
  dplyr::select(Municipio, `Población total`)





comparar = fuzzyjoin::stringdist_join(
  x = municipio |>  dplyr::select(Municipio) |>  sf::st_drop_geometry(),
  y = infografias |>  dplyr::select(Municipio) |>  sf::st_drop_geometry(),
  by = c("Municipio" = "Municipio"),
  mode = "left",
  ignore_case = F,
  method = "jw",
  max_dist = 99,
  distance_col = "distancia"
) |> 
  dplyr::rename(
    Municipio_municipio = Municipio.x,
    Municipio_infograficas = Municipio.y
  ) |> 
  dplyr::group_by(Municipio_municipio) |> 
  dplyr::slice_min(order_by = distancia, n = 1)  |> 
  dplyr::arrange(distancia) |> 
  dplyr::filter(distancia > 0)


for (i in 1:nrow(comparar)) {
  cat(
    'Municipio == "',
    comparar$Municipio_municipio[i],
    '" ~ "',
    comparar$Municipio_infograficas[i],
    '", \n', 
    sep = ""
  )
}

municipio = municipio |> 
  dplyr::mutate(
    Municipio = dplyr::case_when(
      Municipio == "" ~ "",
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


municipio = municipio |> 
  dplyr::left_join(
    y = infografias,
    by = c("Municipio" = "Municipio")
  ) |> 
  dplyr::relocate(`Población total`, .after = Municipio)




reclasificacion_columnas = reclasificacion$`Nueva clasificación` |>  unique()

municipio = municipio |> 
  dplyr::mutate(
    dplyr::across(
      .cols = dplyr::any_of(reclasificacion_columnas),
      .fns = ~ ((.x /`Población total`)*100) |>  round(digits = 4),
      .names = "{.col} Porcentaje"
    )
  )

municipio = municipio |> 
  dplyr::mutate(
    dplyr::across(
      .cols = dplyr::any_of(reclasificacion_columnas),
      .fns = ~ ((.x /`Población total`)*1000) |>  round(digits = 4),
      .names = "{.col} mil habitantes"
    )
  )


municipio |>  openxlsx::write.xlsx("outputs/Estadistica Ejercicio/Municipios 911.xlsx")











### Base municipal

datos = "outputs/Estadistica Ejercicio/Base 911.json" |>  jsonlite::read_json(simplifyVector = T)

datos = datos |> 
  dplyr::select(Municipio, Clasificacion, Recuento) |> 
  dplyr::group_by(Municipio, Clasificacion) |> 
  dplyr::summarise(Recuento = Recuento |>  sum(na.rm = T)) |> 
  dplyr::ungroup()


datos = datos |> 
  tidyr::pivot_wider(
    names_from = Clasificacion,
    values_from = Recuento,
    values_fill = 0
  )


mun = "../../Importantes_documentos_usar/Municipios/municipiosjair.shp" |>  
  sf::read_sf() |>  
  dplyr::select(NOM_MUN)



datos = datos |> 
  dplyr::left_join(
    y = mun,
    by = c("Municipio" = "NOM_MUN")
  ) |> 
  sf::st_as_sf(
    crs = 4326
  )


datos |>  sf::write_sf("outputs/Estadistica Ejercicio/Municipio/Base municipal.geojson", delete_layer = T)







##########

hora = "outputs/llamadas9112025/Tabla_DiaXHora_new.xlsx" |>  readxl::read_excel()

reclasificacion = "inputs/Reclasificacion/Reclasificacion911_Tania.xlsx" |>  readxl::read_excel()
reclasificacion = reclasificacion |> 
  dplyr::select(Incidente, `Nueva clasificación`) |> 
  dplyr::rename(Clasificacion = `Nueva clasificación`)

hora = hora |> 
  dplyr::left_join(
    y = reclasificacion,
    by = "Incidente"
  ) 


hora = hora |> 
  dplyr::select(-Incidente) |> 
  dplyr::rename(Incidente = Clasificacion) |> 
  dplyr::relocate(Incidente, .after = Municipio) |> 
  dplyr::arrange(Municipio, Incidente, Dia_Semana, Hora)

hora = hora |> 
  dplyr::group_by(Municipio, Incidente, Dia_Semana, Hora) |> 
  dplyr::summarise(Recuento = Recuento |>  sum()) |> 
  dplyr::ungroup() |> 
  dplyr::arrange(Municipio, Incidente, Dia_Semana, Hora)



hora |>  openxlsx::write.xlsx("outputs/Estadistica Ejercicio/Municipio/Tabla_DiaXHora_municipal.xlsx")



#####################

mes = "outputs/llamadas9112025/Histórico_AñoXMes_new.xlsx" |>  readxl::read_excel()

reclasificacion = "inputs/Reclasificacion/Reclasificacion911_Tania.xlsx" |>  readxl::read_excel()
reclasificacion = reclasificacion |> 
  dplyr::select(Incidente, `Nueva clasificación`) |> 
  dplyr::rename(Clasificacion = `Nueva clasificación`)

mes = mes |> 
  dplyr::left_join(
    y = reclasificacion,
    by = "Incidente"
  )


mes = mes |> 
  dplyr::select(-Incidente) |> 
  dplyr::rename(Incidente = Clasificacion) |> 
  dplyr::relocate(Incidente, .after = Municipio) |> 

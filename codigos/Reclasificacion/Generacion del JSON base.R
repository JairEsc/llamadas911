base = "outputs/Estadistica Ejercicio/Mapa/Resumen_Colonias_new.geojson" |>  sf::read_sf()


reclasificacion = "inputs/Reclasificacion/Reclasificacion911_Tania.xlsx" |>  readxl::read_excel()
reclasificacion = reclasificacion |> 
  dplyr::select(Incidente, `Nueva clasificación`) |> 
  dplyr::rename(Clasificacion = `Nueva clasificación`)


base = base |> 
  dplyr::left_join(
    y = reclasificacion,
    by = "Incidente"
  )


base = base |> 
  dplyr::select(Municipio, Colonia, Clasificacion, Incidente, Recuento) |> 
  sf::st_drop_geometry() |> 
  dplyr::mutate(
    id = paste0(Municipio, "_", Colonia)
  )



nueva = "outputs/Estadistica Ejercicio/Base reclasificacion 911.geojson" |>  sf::read_sf()
nueva = nueva |> 
  dplyr::select(Municipio, Colonia) |> 
  unique()



coordenadas = nueva |>  sf::st_coordinates()

nueva = nueva |> 
  dplyr::bind_cols(coordenadas)


nueva = nueva |> 
  sf::st_drop_geometry()


nueva = nueva |> 
  dplyr::mutate(
    id = paste0(Municipio, "_", Colonia)
  ) 



base = base |> 
  dplyr::left_join(
    y = nueva |>  dplyr::select(id, X, Y),
    by = "id"
  )


base = base |>  dplyr::select(-id)



base |>  openxlsx::write.xlsx("outputs/Estadistica Ejercicio/Base 911.xlsx")


base |>  jsonlite::write_json("outputs/Estadistica Ejercicio/Base 911.json", pretty = T, auto_unbox = T)




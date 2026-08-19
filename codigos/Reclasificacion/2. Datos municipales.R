datos = "outputs/Estadistica Ejercicio/Base reclasificacion 911.geojson" |>  sf::read_sf()

datos = datos |> sf::st_drop_geometry() |> 
  dplyr::group_by(Municipio, Incidente) |> 
  dplyr::summarise(Recuento = Recuento |>  sum(na.rm = T)) |> 
  dplyr::ungroup()

reclasificacion_columnas = datos$Incidente |>  unique()


datos = datos |> 
  tidyr::pivot_wider(
    names_from = Incidente,
    values_from = Recuento,
    values_fill = 0
  )




info = "../../Importantes_documentos_usar/Infografias Base Enero 2026.xlsx" |>  readxl::read_excel()
info = info |> dplyr::select(Municipio, `Población total`)


datos = datos |> 
  dplyr::left_join(
    y = info,
    by = "Municipio"
  ) |> 
  dplyr::relocate(`Población total`, .after = Municipio)







datos = datos |> 
  dplyr::mutate(
    dplyr::across(
      .cols = dplyr::any_of(reclasificacion_columnas),
      .fns = ~ ((.x /`Población total`)*100) |>  round(digits = 4),
      .names = "{.col} Porcentaje"
    )
  )

datos = datos |> 
  dplyr::mutate(
    dplyr::across(
      .cols = dplyr::any_of(reclasificacion_columnas),
      .fns = ~ ((.x /`Población total`)*1000) |>  round(digits = 4),
      .names = "{.col} mil habitantes"
    )
  )


datos |>  openxlsx::write.xlsx("outputs/Estadistica Ejercicio/Municipios 911.xlsx")

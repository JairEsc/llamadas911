datos = "inputs/Reclasificacion/2025_jul26.xlsx" |>  readxl::read_excel(col_types = "text")

datos = datos |> 
  dplyr::filter(Entidad == "Hidalgo")



datos = datos |> 
  dplyr::mutate(
    dplyr::across(
      .cols = Enero:Diciembre,
      .fns = ~ .x |>  as.numeric()
    )
  )

datos = datos |> 
  dplyr::mutate(
    Recuento = rowSums(x = dplyr::across(Enero:Diciembre), na.rm = T)
  )



datos = datos |> 
  dplyr::select(Municipio, `SUBTIPO O CLASIFICACIÓN SIMILAR AL CATALOGO NACIONAL DE INCIDENTES 911`, Recuento) |> 
  dplyr::rename(Categorias = `SUBTIPO O CLASIFICACIÓN SIMILAR AL CATALOGO NACIONAL DE INCIDENTES 911`) |> 
  dplyr::group_by(Municipio, Categorias) |> 
  dplyr::summarise(Recuento = Recuento |>  sum(na.rm = T)) |> 
  dplyr::ungroup()


datos = datos |> 
  dplyr::mutate(
    Categorias = Categorias |>  stringr::str_to_title()
  )


datos$Categorias |>  unique()



datos = datos |> 
  dplyr::mutate(
    Categorias = Categorias |> 
      gsub(pattern = " Exstorsión  ", replacement = " Extorsión ") |> 
      gsub(pattern = " Y ", replacement = " y ") |> 
      gsub(pattern = " Del ", replacement = " del ") |> 
      gsub(pattern = " Y/O ", replacement = " y/o ") |> 
      gsub(pattern = " Sin ", replacement = " sin ") |> 
      gsub(pattern = " No ", replacement = " no ") |> 
      gsub(pattern = " A ", replacement = " a ") |> 
      stringr::str_squish()
      
  )

reclasificacion_columnas = datos$Categorias |>  unique()
  
datos$Categorias |>  unique()

datos = datos |> 
  tidyr::pivot_wider(
    names_from = Categorias,
    values_from = Recuento,
    values_fill = 0
  )




infografias = "../../Importantes_documentos_usar/Infografias Base Enero 2026.xlsx" |>  
  readxl::read_excel() |> 
  dplyr::select(Municipio, `Población total`)



datos = datos |> 
  dplyr::left_join(
    y = infografias,
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







datos |>  openxlsx::write.xlsx("outputs/Estadistica Ejercicio/Municipios Secretariado.xlsx")

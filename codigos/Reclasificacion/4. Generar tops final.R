datos = "outputs/Estadistica Ejercicio/Heatmap/Llamadas911.xlsx" |>  readxl::read_excel()

top = datos |>
  tidyr::pivot_longer(
    cols = -Municipio,
    names_to = "Categoria",
    values_to = "Valor"
  ) |> 
  dplyr::group_by(Categoria) |> 
  dplyr::slice_max(order_by = Valor, n = 10, with_ties = F)  |> # with_ties = F, Te devuelve exactamente 5 municipios, aunque haya un empate. 
  dplyr::ungroup() |> 
  dplyr::arrange(Categoria, dplyr::desc(Valor))


percentil = datos |>
  tidyr::pivot_longer(
    cols = -Municipio,
    names_to = "Categoria",
    values_to = "Valor"
  ) |> 
  dplyr::group_by(Categoria) |> 
  dplyr::filter(
    Valor >= quantile(Valor, probs = 0.90, na.rm = TRUE)
  ) |> 
  dplyr::ungroup() |> 
  dplyr::arrange(Categoria, dplyr::desc(Valor))


percentil |>  openxlsx::write.xlsx("outputs/Estadistica Ejercicio/Heatmap/Resumenes_Llamadas/Resumen_categoria.xlsx")


top_collapse = percentil |> 
  dplyr::group_by(Categoria) |> 
  dplyr::summarise(Municipios_top = Municipio |> paste(collapse = ", ") |>  stringr::str_squish())


####################

datos = "outputs/Estadistica Ejercicio/Base 911.xlsx" |>  readxl::read_excel()

datos = datos |> 
  dplyr::select(-c(X, Y))


for (i in 1:nrow(top_collapse)) {
  excel =  openxlsx::createWorkbook()
  excel |>  openxlsx::addWorksheet("Top municipios categorias")
  excel |>  openxlsx::writeData(sheet = "Top municipios categorias", x = percentil |> dplyr::filter(Categoria == top_collapse$Categoria[i]))
  
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
  
  
  
  z = colonias_incidentes$Incidente |>  unique()
  nombres = z |>  gsub(pattern = "Del Orden Público Por",replacement = "") |>  stringr::str_squish()
  for (j in seq_along(z)) {
    p = colonias_incidentes |> 
      dplyr::filter(Incidente == z[j])
    
    
    excel |>  openxlsx::addWorksheet(nombres[j] |>  substr(start = 1, stop = 30) |>  stringr::str_squish())
    excel |>  openxlsx::writeData(sheet = nombres[j] |>  substr(start = 1, stop = 30) |>  stringr::str_squish(), x = p)
  }
  
  openxlsx::saveWorkbook(excel, paste0("outputs/Estadistica Ejercicio/Heatmap/Resumenes/", top_collapse$Categoria[i], ".xlsx"), overwrite = TRUE)
  
}










##################

datos = "outputs/Estadistica Ejercicio/Heatmap/Secretariado.xlsx" |>  readxl::read_excel()

top = datos |>
  tidyr::pivot_longer(
    cols = -Municipio,
    names_to = "Categoria",
    values_to = "Valor"
  ) |> 
  dplyr::group_by(Categoria) |> 
  dplyr::slice_max(order_by = Valor, n = 10, with_ties = F)  |> # with_ties = F, Te devuelve exactamente 5 municipios, aunque haya un empate. 
  dplyr::ungroup() |> 
  dplyr::arrange(Categoria, dplyr::desc(Valor))


percentil = datos |>
  tidyr::pivot_longer(
    cols = -Municipio,
    names_to = "Categoria",
    values_to = "Valor"
  ) |> 
  dplyr::group_by(Categoria) |> 
  dplyr::filter(
    Valor >= quantile(Valor, probs = 0.90, na.rm = TRUE)
  ) |> 
  dplyr::ungroup() |> 
  dplyr::arrange(Categoria, dplyr::desc(Valor))



percentil |>  openxlsx::write.xlsx("outputs/Estadistica Ejercicio/Heatmap/Resumen secretariado.xlsx")

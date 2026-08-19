##################
### Dia y hora ###
##################

datos = "outputs/llamadas9112025/Tabla_DiaXHora_new.xlsx" |>  readxl::read_excel()
reclasificacion = "inputs/Reclasificacion/Reclasificacion911_Tania.xlsx" |>  
  readxl::read_excel() |> 
  dplyr::select(Incidente, `Nueva clasificación`)

re = datos |> 
  dplyr::left_join(
    y = reclasificacion,
    by = "Incidente"
  ) 


re = re |> 
  dplyr::group_by(Colonia, Municipio, `Nueva clasificación`, Dia_Semana, Hora) |> 
  dplyr::summarise(Recuento = Recuento |>  sum(na.rm = T)) |> 
  dplyr::ungroup() |> 
  dplyr::rename(Incidente = `Nueva clasificación`)

re |>  openxlsx::write.xlsx("outputs/Estadistica Ejercicio/Mapa/Tabla_DiaXHora_new.xlsx")










#################
### Historico ###
#################

datos = "outputs/llamadas9112025/Histórico_AñoXMes_new.xlsx" |>  readxl::read_excel()
reclasificacion = "inputs/Reclasificacion/Reclasificacion911_Tania.xlsx" |>  
  readxl::read_excel() |> 
  dplyr::select(Incidente, `Nueva clasificación`)




re = datos |> 
  dplyr::left_join(
    y = reclasificacion,
    by = "Incidente"
  ) |> 
  dplyr::group_by(Colonia, Municipio, `Nueva clasificación`, Fecha) |> 
  dplyr::summarise(Recuento = Recuento |>  sum(na.rm = T)) |> 
  dplyr::ungroup() |> 
  dplyr::rename(Incidente = `Nueva clasificación`)


re |> openxlsx::write.xlsx("outputs/Estadistica Ejercicio/Mapa/Histórico_AñoXMes_new.xlsx")


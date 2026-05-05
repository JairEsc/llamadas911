#proteccion de datos personales
llamadas="inputs/llamadas9112025/Estadístico 911 2025.xlsx" |> openxlsx::read.xlsx()
llamadas=llamadas |> 
  dplyr::sample_frac(size = 0.01)

llamadas=llamadas |> 
  dplyr::mutate(
    Longitud.Emergencia=as.numeric(gsub(pattern = "'",'',Longitud.Emergencia))+rnorm(n = nrow(llamadas),mean = 0,sd = 0.1),
    Latitud.Emergencia=as.numeric(gsub(pattern = "'",'',Latitud.Emergencia))+rnorm(n = nrow(llamadas),mean = 0,sd = 0.1)
                )
llamadas |> write.csv("inputs/llamadas9112025/datos_dummy.csv",row.names = F)


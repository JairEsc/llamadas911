source("../../Reutilizables/Postgres_BUIG/conexion_local.R")
municipios=st_read(local,"limite_municipal")
library(sf)
subtabla=function(range){
  return("inputs/estadisticas911/Estadístico 911 por tipo de incidente 2025.xlsx" |> readxl::read_excel(range = range))
}
#B2:C200
subtabla("B2:C199")
incidencia_mensual=subtabla("E2:F14")
incidencia_diaria=subtabla("H2:I9")
regionales=subtabla("K2:N93")
incidencia_municipal_por_delito=subtabla("S2:T6950")

library(openxlsx)
wb <- loadWorkbook("inputs/estadisticas911/Estadístico 911 por tipo de incidente 2025.xlsx")
getStyleFgColor <- function(styleObjects, row, col){
  temp <- lapply(styleObjects, function(x){
    if( (length(intersect(which(x$rows == row), which(x$cols == col))) == 1) ){
      return(x$style$fill$fillFg)
    } 
    return(NA)
  })
  temp <- unlist(temp)
  if(sum(is.na(temp)) == length(temp)){
    return(NA)
  }
  return(temp[!is.na(temp)])
}
styleObjects <- wb$styleObjects
S=which(LETTERS=='S')

columna_municipal=1:(nrow(incidencia_municipal_por_delito)+1) |> lapply(\(r){getStyleFgColor(styleObjects = styleObjects, row = r, col = S)}) 

##Podemos identificar el fondo gris porque tiene dos argumentos: theme, tint
(2==columna_municipal |> lapply(\(df){return(length(df))}) |> unlist()) |> which()
incidencia_municipal_por_delito$`MUNICIPIO E INCIDENTE`[((2==columna_municipal |> lapply(\(df){return(length(df))}) |> unlist()) |> which())-2]
incidencia_municipal_por_delito$nom_mun=NA
incidencia_municipal_por_delito$nom_mun[((2==columna_municipal |> lapply(\(df){return(length(df))}) |> unlist()) |> which())-2]=
  incidencia_municipal_por_delito$`MUNICIPIO E INCIDENTE`[((2==columna_municipal |> lapply(\(df){return(length(df))}) |> unlist()) |> which())-2]


incidencia_municipal_por_delito=incidencia_municipal_por_delito |> tidyr::fill(nom_mun,.direction = "down") |> 
  dplyr::filter(`MUNICIPIO E INCIDENTE`!=nom_mun)

incidencia_municipal_por_delito$nom_mun |> unique() |> lapply(\(mun){
  stringi::stri_trans_general(stringr::str_to_upper(mun),id = "Latin-ASCII")%in%stringi::stri_trans_general(stringr::str_to_upper(municipios$NOM_MUN),id = "Latin-ASCII")
}) |> unlist()







incidencia_municipal_por_delito_left=fuzzyjoin::stringdist_full_join(
  x = incidencia_municipal_por_delito |> dplyr::mutate(nom_mun=stringr::str_to_title(nom_mun)),
  y = municipios |> dplyr::select(NOM_MUN,CVE_MUN)  |> st_drop_geometry(),
  by = c("nom_mun" = "NOM_MUN"), 
  max_dist = 10,
  distance_col = "dist"
) |> 
  dplyr::group_by(nom_mun,`MUNICIPIO E INCIDENTE`) |> 
  dplyr::arrange(dist) |> 
  dplyr::slice_head(n=1)
###Nos dimos cuenta a ojo que mayor que 2 es otros estados
incidencia_municipal_por_delito_left=incidencia_municipal_por_delito_left |> 
  dplyr::ungroup() |> 
  dplyr::filter(dist<=2) |> 
  dplyr::select(CVE_MUN,`MUNICIPIO E INCIDENTE`,TOTAL) |> 
  dplyr::rename(INCIDENTE=`MUNICIPIO E INCIDENTE`) |> 
  merge(municipios |> dplyr::select(CVE_MUN,NOM_MUN) |> st_drop_geometry(),by='CVE_MUN')

incidencia_municipal_por_delito_left |> 
  dplyr::group_by(NOM_MUN) |> 
  dplyr::summarise(total=sum(TOTAL))

incidencia_municipal_por_delito_left |> write.csv("outputs/incidencia_municipal_por_delito.csv",fileEncoding = "UTF-8",row.names = F)


regionales |> 
  dplyr::filter(!is.na(...2) & !is.na(...3) ) |> 
  dplyr::rename(region=`REGIONES DEL ESTADO DE HIDALGO`,
                nom_mun=...3) |> 
  tidyr::fill(region,.direction = "down") |> 
  dplyr::select(region,nom_mun) |> 
  write.csv("outputs/regionalizacion.csv",fileEncoding = "UTF-8",row.names = F)

incidencia_diaria |> write.csv("outputs/estadisticas911/incidencia_diaria.csv",fileEncoding = "UTF-8",row.names = F)
incidencia_mensual |> write.csv("outputs/estadisticas911/incidencia_mensual.csv",fileEncoding = "UTF-8",row.names = F)

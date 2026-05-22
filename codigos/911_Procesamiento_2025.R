library(tidyverse)
library(dplyr)
library(lubridate) #Es para las fechas (es la primera vez que lo ocupo así que haré notas)
library(sf)

Data="../outputs/llamadas9112025/llamadas9112025.csv" |> read.csv()
  
fechas <- as.Date(Data$Fecha.Incidente)

Data$Año <- lubridate::year(fechas)
Data$Mes <- lubridate::month(fechas)
Data$Dia <- lubridate::day(fechas)

Data$Dia_Semana <- lubridate::wday(fechas, label=T, abbr=F, locale="es_ES.UTF-8")
  #label=T y abbr=F es para que regrese el nombre del día y no lo abrevie

Data$Hora.Incidente <- gsub(":.*", "", Data$Hora.Incidente)
  #el :.* significa todo lo que esté despues del primer :

Data$Incidente=paste0(Data$Delito...Emergencia," (",Data$Categoría,")")

colonias="../inputs/Datos_Geográficos/colonias/13as.shp" |> 
  sf::read_sf()

Data=merge(Data,colonias |> dplyr::select(cvegeo,cve_mun,geometry),by.x = "cve_col",by.y = "cvegeo",all.x = T,all.y = F)
Data=st_transform(st_as_sf(Data),crs=4326)
Data=st_centroid(Data |> st_make_valid())

Data$Colonia=if_else(Data$tipo_colonia=="NINGUNO",
                     Data$colonia,paste0(Data$colonia," (",str_to_title(Data$tipo_colonia),")"))

#Corrección del municipio
Mpios=openxlsx::read.xlsx("../inputs/Datos_Geográficos/Municipios.xlsx")
Data$Municipio_C=character(nrow(Data))
for(municipio in unique(Data$cve_mun)[!is.na(unique(Data$cve_mun))]){
  Data$Municipio_C[Data$cve_mun==municipio]=Mpios$NOM_MUN[Mpios$CVE_MUN==municipio]
}
#La siguiente instrucción tarda demasiado (aguas)
Resumen=Data |> group_by(Incidente,Fecha.Incidente,Hora.Incidente,cve_col) |>
  summarise(Año=first(Año),
            Mes=first(Mes),
            Dia=first(Dia),
            Dia_Semana=first(Dia_Semana) |> str_to_title(),
            Colonia=first(Colonia),
            Municipio=first(Municipio_C),
            geometry=first(geometry),
            Recuento = n(),
            .groups = "drop")

#Renombramos bonito algunas variables
colnames(Resumen)[colnames(Resumen)=="Fecha.Incidente"]="Fecha"
colnames(Resumen)[colnames(Resumen)=="Hora.Incidente"]="Hora"
colnames(Resumen)[colnames(Resumen)=="cve_col"]="CVEGEO"

#ordenamos
Resumen=Resumen |> dplyr::select(Incidente,Recuento,Fecha,Año,Mes,Dia,Dia_Semana,Hora,CVEGEO,Colonia,Municipio,geometry)

#[OJO] Por ahora tomamos solo a los que si tienen geometría
Prueba=Resumen[!(st_is_empty(Resumen$geometry)),]


#Para el mapa y el arbol
Resumen_Colonia=Prueba |> group_by(Colonia,Municipio,Incidente) |> 
  summarise(Recuento=sum(Recuento,na.rm = T),
            geometry=first(geometry)) #Pues la combinación Colonia-Municipio generea una única geometría
sf::write_sf(Resumen_Colonia,"../outputs/llamadas9112025/Resumen_Colonias.geojson")

#Para el histórico con regresión
Historic=Prueba
Historic$Fecha=substr(Historic$Fecha,1,7)
Historic=group_by(Historic |> st_drop_geometry(),Colonia,Municipio,Incidente,Fecha) |>
  summarise(Recuento=sum(Recuento, na.rm = T), .groups="drop")

openxlsx::write.xlsx(Historic,"../outputs/llamadas9112025/Histórico_AñoXMes.xlsx")



#Para la Tabla de calor¿
SemanaHora=Prueba|> st_drop_geometry() |> group_by(Colonia,Municipio,Incidente,Dia_Semana,Hora) |>
  summarise(Recuento=sum(Recuento, na.rm = T))
  
openxlsx::write.xlsx(SemanaHora,"../outputs/llamadas9112025/Tabla_DiaXHora.xlsx") 

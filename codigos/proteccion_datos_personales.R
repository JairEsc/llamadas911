#proteccion de datos personales
llamadas="inputs/llamadas9112025/Estadístico 911 2025.xlsx" |> readxl::read_excel()
llamadas=llamadas |>
  dplyr::mutate(
    `Longitud Emergencia`=as.numeric(gsub(pattern = "'",'',`Longitud Emergencia`)),
    `Latitud Emergencia`=as.numeric(gsub(pattern = "'",'',`Latitud Emergencia`))
                )
source("../../Reutilizables/Postgres_BUIG/conexion_buig.R")

municipios=st_read(buig,'limite_municipal')|> 
  st_transform(4326)
localidades=st_read(buig,'localidades')|> 
  st_transform(4326)
colonias=st_read("../../Reutilizables/Cartografia/colonias_Hidalgo_2025/colonias_Hidalgo_2025.shp") |> 
  st_transform(4326) |> 
  st_make_valid()

llamadas=llamadas |> 
  st_as_sf(coords=c('Longitud Emergencia','Latitud Emergencia'),crs=4326 )
library(sf)
library(leaflet)
llamadas_NOconfid=llamadas |> 
  st_join(y = municipios |> dplyr::select(cvegeo,nomgeo),join = st_intersects) |> 
  dplyr::filter(!is.na(nomgeo))
llamadas_NOconfid=llamadas_NOconfid |> 
  st_join(y = localidades |> dplyr::select(nomgeo,ambito,cve_loc) |> 
            dplyr::rename(localidad=nomgeo),join = st_intersects) |> 
  dplyr::rename(municipio=nomgeo)
llamadas_NOconfid_c_loc= llamadas_NOconfid|>
  dplyr::filter(!is.na(localidad))
llamadas_NOconfid_sin_loc= llamadas_NOconfid|>
  dplyr::filter(is.na(localidad)) |> 
  dplyr::arrange(municipio) |> 
  dplyr::select(-c(localidad,cve_loc,ambito))
localidades_poligonos_exterior=st_read(buig,Lista_BUIG[[6]]) |> st_transform(4326) |> 
  st_make_valid()
##Algoritmo para asignar el más cercano si está dentro de 200 m
leaflet() |> 
  addTiles() |> 
  addMarkers(data=llamadas |> 
               st_join(y = municipios |> dplyr::select(cvegeo,nomgeo),join = st_intersects) |> 
               dplyr::filter(is.na(nomgeo)))


indexes=numeric(0)
particion_1_n=1:17000 |> 
  split(gl(17,1000))
particion_1_n[[18]]=17001:nrow(llamadas_NOconfid_sin_loc)
(particion_1_n) |> 
  sapply(\(x){
    subset_llamadas=llamadas_NOconfid_sin_loc[x,]
    subset_colonias=st_crop(localidades_poligonos_exterior,y = st_bbox(subset_llamadas) )
    #=localidades_poligonos_exterior[1:300,]
    subset_colonias |> nrow() |> print()
    w=st_distance(subset_llamadas,subset_colonias )
    #print(w)
    indexes=numeric(0)
    for(i in 1:nrow(w)){
      x=w[i,]
      min_index=which.min(x)
      if(x[min_index]<=units::set_units(200, "m")){
        indexes[length(indexes)+1]<-subset_colonias$CVEGEO[min_index]
      }
      else{
        indexes[length(indexes)+1]=NA
      }
    }
    return(indexes)
  },simplify = T) |> unlist()->colonias_mas_cercanas200
colonias_mas_cercanas200_unlist=colonias_mas_cercanas200 |> unlist()

llamadas_NOconfid_sin_loc$cve_loc=colonias_mas_cercanas200_unlist
llamadas_NOconfid_sin_loc=llamadas_NOconfid_sin_loc |> 
  merge(localidades_poligonos_exterior |> 
          dplyr::select(CVEGEO,NOMGEO,AMBITO) |> 
          dplyr::rename(cve_loc=CVEGEO,
                        localidad=NOMGEO,
                        ambito=AMBITO) |> st_drop_geometry(),
        by='cve_loc',all.x=T)


#Después de verificar que en efecto nuestro código es una generalización:
# llamadas_NOconfid_sin_loc=llamadas_NOconfid_sin_loc |> 
#   st_join(y =localidades_poligonos_exterior |> dplyr::select(CVEGEO,NOMGEO) |> 
#             dplyr::rename(localidad=NOMGEO),join = st_intersects)


llamadas_localidades=
  rbind(llamadas_NOconfid_c_loc,llamadas_NOconfid_sin_loc)
llamadas_localidades=llamadas_localidades |> 
  st_join(y = colonias |> st_make_valid() |> dplyr::select(nom_asen,tipo,cvegeo) |> 
            dplyr::rename(cvegeo_colonia=cvegeo),join = st_intersects)
llamadas_localidades_sin_col=llamadas_localidades |> 
  dplyr::filter(is.na(cvegeo_colonia)) |> 
  dplyr::arrange(municipio)
llamadas_localidades_con_col=llamadas_localidades |> 
  dplyr::filter(!is.na(cvegeo_colonia))
particion_1_n=1:25000 |> 
  split(gl(25,1000))
particion_1_n[[26]]=25001:nrow(llamadas_localidades_sin_col)
#colonias=colonias |> st_make_valid()

(particion_1_n) |> 
  sapply(\(x){
    subset_llamadas=llamadas_localidades_sin_col[x,]
    subset_colonias=st_crop(colonias,y = st_bbox(subset_llamadas) )
    #=localidades_poligonos_exterior[1:300,]
    subset_colonias |> nrow() |> print()
    w=st_distance(subset_llamadas,subset_colonias )
    #print(w)
    indexes=numeric(0)
    for(i in 1:nrow(w)){
      x=w[i,]
      min_index=which.min(x)
      if(x[min_index]<=units::set_units(200, "m")){
        indexes[length(indexes)+1]<-subset_colonias$cvegeo[min_index]
      }
      else{
        indexes[length(indexes)+1]=NA
      }
    }
    return(indexes)
  },simplify = T) |> unlist()->colonias_mas_cercanas200
colonias_mas_cercanas200_unlist=colonias_mas_cercanas200 |> unlist()

llamadas_localidades_sin_col$cve_col=colonias_mas_cercanas200_unlist
llamadas_localidades_sin_col=llamadas_localidades_sin_col |> 
  merge(colonias |> 
          dplyr::select(cvegeo,nom_asen,tipo) |> 
          dplyr::rename(cve_col=cvegeo,
                        colonia=nom_asen,
                        tipo_colonia=tipo) |> st_drop_geometry(),
        by='cve_col',all.x=T)

llamadas_limpia=llamadas_localidades_sin_col |> 
  dplyr::select(-c(cvegeo_colonia,nom_asen,tipo)) |> 
  dplyr::relocate(cve_col,.before = colonia) |> 
  st_drop_geometry() |> 
  rbind(llamadas_localidades_con_col |> 
          dplyr::rename(cve_col=cvegeo_colonia,
                        colonia=nom_asen,
                        tipo_colonia=tipo) |> st_drop_geometry()) |> 
  dplyr::rename(colonia_original=Colonia)
sum(!is.na(llamadas_limpia$colonia))
llamadas_limpia=llamadas_limpia |> 
  dplyr::mutate(`Hora Incidente`=
                  format(`Hora Incidente`,"%H:%M"))

llamadas_limpia |> write.csv("outputs/llamadas9112025/llamadas9112025.csv",fileEncoding = "UTF-8",row.names = F)

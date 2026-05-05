"../Seguridad_Tablero_Movil/Datos/CSVs_2/delitos por mes_15-24.csv" |> read.csv() ->delitos
delitos_p_mun=delitos |> 
  dplyr::filter(Año==2025) |> 
  dplyr::group_by(Municipio) |> 
  dplyr::summarise(total=sum(total))
llamadas_p_mun=incidencia_municipal_por_delito_left |> 
  dplyr::group_by(NOM_MUN) |> 
  dplyr::summarise(TOTAL=sum(TOTAL))
llamadas_p_tipo=incidencia_municipal_por_delito_left |> 
  dplyr::group_by(INCIDENTE) |> 
  dplyr::summarise(TOTAL=sum(TOTAL))
llamadas_y_delitos_p_mun=
  merge(delitos_p_mun,llamadas_p_mun,by.x = "Municipio",by.y='NOM_MUN')


cor.test(x = llamadas_y_delitos_p_mun$total,y=llamadas_y_delitos_p_mun$TOTAL,method = 
           "p"#s,p,k
         )

llamadas_y_delitos_p_mun$total |> scale()|> hist()
llamadas_y_delitos_p_mun$TOTAL |> scale()|> hist()

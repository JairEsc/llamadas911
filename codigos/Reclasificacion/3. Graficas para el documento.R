categorias_interes = c(
  "Alcohol y drogas", 
  "Alteración del orden público", 
  "Amenazas, extorsión y conductas sospechosas",
  "Armas, explosivos y pirotecnia", 
  "Daños a bienes y propiedad", 
  "Delitos en materia de Hidrocarburo", 
  "Delitos sexuales",
  "Personas no localizadas y libertad personal", 
  "Robo y delitos patrimoniales", 
  "Violencia de genero y grupos vulnerables"
  )

categorias_interes_l = categorias_interes |>
  stringr::str_to_lower() |>
  stringr::str_squish() |>
  stringi::stri_trans_general("Latin-ASCII")

categorias_secretariado = c(
  "Alcohol y Drogas",
  "Alteracion del Orden Publico",
  "Amenazas, Exstorsión y Conductas Sospechosas",
  "Daños a Bienes y Propiedad",
  "Delitos Electorales",
  "Delitos Sexuales",
  "Fraude y Abuso Patrimonial",
  "Homicidio y/o Lesiones",
  "Medio Ambiente",
  "Otros sin Especificar",
  "Personas no Localizadas y Libertad Personal",
  "Robo y Delitos Patrimoniales",
  "Violencia De Genero y Grupos Vulnerables"
)

categorias_secretariado_l = categorias_secretariado |>
  stringr::str_to_lower() |>
  stringr::str_squish() |>
  stringi::stri_trans_general("Latin-ASCII")


# Se encuentran en categorias del 911 pero no del secretariado
# "Armas, explosivos y pirotecnia"
# "Delitos en materia de Hidrocarburo"


# Se encuentran en secretario pero no del 911
# "Delitos Electorales"              # Quitar
# "Fraude y Abuso Patrimonial",      # Se añadio
# "Homicidio y/o Lesiones",          # Quitamos por la falta de coincidencia
# "Medio Ambiente",                  # Quitar
# "Otros sin Especificar",           # Otros sin Especificar

####################
### Llamadas 911 ###
####################

categorias = c(
  "Alcohol y drogas", 
  "Alteración del orden público", 
  "Amenazas, extorsión y conductas sospechosas",
  "Armas, explosivos y pirotecnia", 
  "Daños a bienes y propiedad", 
  
  "Delitos en materia de Hidrocarburo", 
  "Delitos sexuales",
  "Fraude y abuso patrimonial",                       # Se añadio
  "Homicidio y/o Lesiones",                           # Se añadio
  "Personas no localizadas y libertad personal", 
  "Robo y delitos patrimoniales",
  
  "Violencia de genero y grupos vulnerables",
  "Otros sin Especificar"                             #Se añadio
) 

df_cate = categorias |>  data.frame()
df_cate = df_cate |> 
  dplyr::mutate(
    categorias_limpias = categorias |> stringr::str_to_lower() |>
      stringr::str_squish() |>
      stringi::stri_trans_general("Latin-ASCII")
  )


df_cate = df_cate |> 
  dplyr::mutate(
    categorias_correctas = dplyr::case_when(
      categorias == "Alcohol y drogas" ~ "Alcohol y drogas",
      categorias == "Alteración del orden público" ~ "Alteración del orden público",
      categorias == "Amenazas, extorsión y conductas sospechosas" ~ "Amenazas, extorsión y conductas sospechosas",
      categorias == "Armas, explosivos y pirotecnia" ~ "Armas, explosivos y pirotecnia",
      categorias == "Daños a bienes y propiedad" ~ "Daños a bienes y propiedad",
      
      categorias == "Delitos en materia de Hidrocarburo" ~ "Delitos en materia de hidrocarburos",
      categorias == "Delitos sexuales" ~ "Delitos sexuales",
      categorias == "Fraude y abuso patrimonial" ~ "Fraude y abuso patrimonial",
      categorias == "Homicidio y/o Lesiones" ~ "Homicidio y/o lesiones",
      categorias == "Personas no localizadas y libertad personal" ~ "Personas no localizadas y libertad personal",
      categorias == "Robo y delitos patrimoniales" ~ "Robo y delitos patrimoniales",
      
      categorias == "Violencia de genero y grupos vulnerables"~ "Violencia de género y grupos vulnerables",
      categorias == "Otros sin Especificar" ~ "Otros sin especificar",

      T ~ categorias
    ) |>  stringr::str_squish()
  )
  
  

llamadas = "outputs/Estadistica Ejercicio/Municipios 911.xlsx" |>  readxl::read_excel()

llamadas = llamadas |> 
  dplyr::select(Municipio, dplyr::any_of(categorias |>  paste("mil habitantes"))) |> 
  tidyr::pivot_longer(
    cols = dplyr::any_of(categorias  |>  paste("mil habitantes")),
    names_to = "Categorias",
    values_to = "Valor"
  ) |> 
  dplyr::mutate(
    Categorias = Categorias |> 
      stringr::str_to_lower() |>
      stringr::str_squish() |>
      stringi::stri_trans_general("Latin-ASCII")
  ) |> 
  dplyr::mutate(
    Categorias = Categorias |> 
      gsub(pattern = "mil habitantes" , replacement = "") |> 
      stringr::str_squish()
  )

llamadas$Categorias |>  unique()


llamadas = llamadas |> 
  dplyr::left_join(
    y = df_cate |>  dplyr::select(categorias_limpias, categorias_correctas),
    by = c("Categorias" = "categorias_limpias")
  )


llamadas = llamadas |> 
  dplyr::select(-Categorias) |> 
  dplyr::rename(Categorias = categorias_correctas) |> 
  dplyr::relocate(Categorias, .after = Municipio)


llamadas = llamadas |> 
  dplyr::mutate(
    Valor = Valor |>  as.numeric()
  )

llamadas = llamadas |> 
  tidyr::pivot_wider(
    names_from = Categorias,
    values_from = Valor,
    values_fill = 0
  )



# llamadas = llamadas |> 
#   dplyr::mutate(
#     `Otros sin especificar` = 0
#   )



llamadas |>  openxlsx::write.xlsx("outputs/Estadistica Ejercicio/Heatmap/Llamadas911.xlsx")




































categorias_secretariado = c(
  "Alcohol y Drogas",
  "Alteracion del Orden Publico",
  "Amenazas, Exstorsión y Conductas Sospechosas",
  "Daños a Bienes y Propiedad",
  "Delitos Electorales",
  "Delitos Sexuales",
  "Fraude y Abuso Patrimonial",
  "Homicidio y/o Lesiones",
  "Medio Ambiente",
  "Otros sin Especificar",
  "Personas no Localizadas y Libertad Personal",
  "Robo y Delitos Patrimoniales",
  "Violencia De Genero y Grupos Vulnerables"
)


secretariado = "outputs/Estadistica Ejercicio/Municipios Secretariado.xlsx" |>  readxl::read_excel()
secretariado = secretariado |> 
  dplyr::select(Municipio, dplyr::any_of(categorias_secretariado  |>  paste("mil habitantes"))) |> 
  tidyr::pivot_longer(
    cols = dplyr::any_of(categorias_secretariado  |>  paste("mil habitantes")),
    names_to = "Categorias",
    values_to = "Valor"
    ) 


secretariado = secretariado |> 
  dplyr::mutate(
    Categorias = Categorias |> 
      stringr::str_to_lower() |>
      stringr::str_squish() |>
      stringi::stri_trans_general("Latin-ASCII")
  ) |> 
  dplyr::mutate(Categorias = Categorias |> 
                  gsub(pattern = "mil habitantes" , replacement = "") |> 
                  stringr::str_squish()) |> 
  dplyr::mutate(
    Categorias = dplyr::if_else(condition = Categorias == "amenazas, exstorsion y conductas sospechosas", true = "amenazas, extorsion y conductas sospechosas", false = Categorias)
  )

secretariado$Categorias |>  unique()


secretariado = secretariado |> 
  dplyr::filter(Categorias %in% df_cate$categorias_limpias)


secretariado = secretariado |> 
  dplyr::left_join(
    y = df_cate |>  dplyr::select(categorias_limpias, categorias_correctas),
    by = c("Categorias" = "categorias_limpias")
  )


secretariado = secretariado |> 
  dplyr::select(-Categorias) |> 
  dplyr::rename(Categorias = categorias_correctas) |> 
  dplyr::relocate(Categorias, .after = Municipio)


secretariado = secretariado |> 
  dplyr::mutate(
    Valor = Valor |>  as.numeric()
  )

secretariado = secretariado |> 
  tidyr::pivot_wider(
    names_from = Categorias,
    values_from = Valor,
    values_fill = 0
  )



df_cate$categorias_correctas %in% (secretariado |> names())[2:length(secretariado)] 

faltantes = df_cate[-which(df_cate$categorias_correctas %in% (secretariado |> names())[2:length(secretariado)]) ,]
faltantes$categorias_correctas |>  unique()

# secretariado = secretariado |> 
#   dplyr::mutate(
#     `Armas, explosivos y pirotecnia` = 0,
#     `Delitos en materia de hidrocarburos` = 0
#   )
# 



secretariado |>  openxlsx::write.xlsx("outputs/Estadistica Ejercicio/Heatmap/Secretariado.xlsx")




























###############

llamadas = "outputs/Estadistica Ejercicio/Heatmap/Llamadas911.xlsx" |>  readxl::read_excel()

categorias = llamadas |>  names()
categorias = categorias[-1]

llamadas = llamadas |> 
  tidyr::pivot_longer(
    cols = dplyr::any_of(categorias),
    names_to = "Categorias",
    values_to = "Valor"
  ) 


municipios_orden = llamadas |> 
  dplyr::group_by(Municipio) |> 
  dplyr::summarise(Valor = Valor |>  sum(na.rm = T)) |> 
  dplyr::ungroup() |> 
  dplyr::arrange(Valor |>  dplyr::desc())

municipios_orden = municipios_orden$Municipio

categorias_orden = llamadas |> 
  dplyr::group_by(Categorias) |> 
  dplyr::summarise(Valor = Valor |>  sum(na.rm = T)) |> 
  dplyr::ungroup() |> 
  dplyr::arrange(Valor |>  dplyr::desc())

categorias_orden = categorias_orden$Categorias

# [1] "Alteración del orden público"                "Violencia de género y grupos vulnerables"   
# [3] "Amenazas, extorsión y conductas sospechosas" "Alcohol y drogas"                           
# [5] "Robo y delitos patrimoniales"                "Armas, explosivos y pirotecnia"             
# [7] "Daños a bienes y propiedad"                  "Personas no localizadas y libertad personal"
# [9] "Delitos en materia de hidrocarburos"         "Fraude y abuso patrimonial"                 
# [11] "Delitos sexuales"                            "Otros sin especificar"

categorias_orden = c("Alteración del orden público", 
  "Violencia de género y grupos vulnerables",
  "Amenazas, extorsión y conductas sospechosas",
  "Alcohol y drogas",
  "Robo y delitos patrimoniales",
  # "Armas, explosivos y pirotecnia",
  "Daños a bienes y propiedad" ,
  "Personas no localizadas y libertad personal",
  #"Delitos en materia de hidrocarburos",
  "Fraude y abuso patrimonial" ,
  "Delitos sexuales",
  
  "Armas, explosivos y pirotecnia",
  "Delitos en materia de hidrocarburos",
  "Homicidio y/o lesiones",
  "Otros sin especificar"
  )


llamadas = llamadas |> 
  dplyr::mutate(
    Municipio = Municipio |>  factor(levels = municipios_orden),
    Categorias = Categorias |>  factor(levels = categorias_orden)
  )

g = ggplot(
  data = llamadas,
  aes(
    x = Municipio,
    y = Categorias,
    fill = Valor
  )
) +
  geom_tile(
    color = "white",
    linewidth = 0.15
  ) +
  scale_fill_distiller(palette = "RdPu", direction = 1)+
  labs(
    title = "Datos de llamadas del 911 por cada mil habitantes",
    x = "Municipio",
    y = "Categorías"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    axis.text.x = element_text(
      angle = 90,
      hjust = 1,
      vjust = 0.5,
      size = 6
    ),
    axis.text.y = element_text(size = 8),
    axis.title = element_text(face = "bold"),
    plot.title = element_text(
      face = "bold",
      hjust = 0.5
    ),
    panel.grid = element_blank()
  )

g
ggplot2::ggsave(
  filename = "../../../../Llamadas 911 mil habitantes_ordenadas.png", 
  plot = g,
  width = 1291,
  height = 569,
  units = "px",
  dpi = 300)







secretariado = "outputs/Estadistica Ejercicio/Heatmap/Secretariado.xlsx" |>  readxl::read_excel()

categorias = (secretariado |>  names())[2:ncol(secretariado)]

secretariado = secretariado |> 
  tidyr::pivot_longer(
    cols = dplyr::any_of(categorias),
    names_to = "Categorias",
    values_to = "Valor"
  ) 

secretariado = secretariado |> 
  dplyr::mutate(
    Municipio = Municipio |>  factor(levels = municipios_orden),
    Categorias = Categorias |>  factor(levels = categorias_orden)
  )


gg = ggplot(
  data = secretariado,
  aes(
    x = Municipio,
    y = Categorias,
    fill = Valor
  )
) +
  geom_tile(
    color = "white",
    linewidth = 0.15
  ) +
  scale_fill_distiller(palette = "RdPu", direction = 1)+
  labs(
    title = "Datos de secretariado por cada mil habitantes",
    x = "Municipio",
    y = "Categorías"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    axis.text.x = element_text(
      angle = 90,
      hjust = 1,
      vjust = 0.5,
      size = 6
    ),
    axis.text.y = element_text(size = 8),
    axis.title = element_text(face = "bold"),
    plot.title = element_text(
      face = "bold",
      hjust = 0.5
    ),
    panel.grid = element_blank()
  )

gg








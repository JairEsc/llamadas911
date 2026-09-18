### Previo
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

##################






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



secretariado |>  openxlsx::write.xlsx("outputs/Estadistica Ejercicio/Heatmap/Secretariado Municipal.xlsx")

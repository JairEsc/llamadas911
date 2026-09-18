

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


secretariado = "outputs/Estadistica Ejercicio/Regional Secretariado.xlsx" |>  readxl::read_excel()
secretariado = secretariado |> 
  dplyr::select(Región, dplyr::any_of(categorias_secretariado  |>  paste("mil habitantes"))) |> 
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
  dplyr::relocate(Categorias, .after = Región)


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



secretariado |>  openxlsx::write.xlsx("outputs/Estadistica Ejercicio/Heatmap/Secretariado Regional.xlsx")

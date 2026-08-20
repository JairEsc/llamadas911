secretariado = "outputs/Estadistica Ejercicio/Municipios Secretariado.xlsx" |>  readxl::read_excel()

categorias_secretariado = c(
  "Alcohol y Drogas",
  "Alteracion del Orden Publico",
  "Amenazas, Exstorsión y Conductas Sospechosas",
  "Daños a Bienes y Propiedad",
  "Delitos Sexuales",
  "Fraude y Abuso Patrimonial",
  "Homicidio y/o Lesiones",
  "Otros sin Especificar",
  "Personas no Localizadas y Libertad Personal",
  "Robo y Delitos Patrimoniales",
  "Violencia De Genero y Grupos Vulnerables"
)


secretariado = secretariado |> 
  dplyr::select(Municipio, dplyr::any_of(categorias_secretariado |>  paste("mil habitantes"))) |> 
  tidyr::pivot_longer(
    cols = dplyr::any_of(categorias_secretariado |>  paste("mil habitantes")),
    names_to = "Categorias",
    values_to = "Valor"
  ) |> 
  dplyr::mutate(
    Categorias = Categorias |>  gsub(pattern = "mil habitantes", replacement = "") |>  stringr::str_squish(),
  )


categorias_secretariado_importancia = secretariado |> 
  dplyr::group_by(Categorias) |> 
  dplyr::summarise(Valor = Valor |>  sum(na.rm = T)) |> 
  dplyr::ungroup() |> 
  dplyr::arrange(Valor |>  dplyr::desc())


municipios_secretariado_importancia = secretariado |> 
  dplyr::group_by(Municipio) |> 
  dplyr::summarise(Valor = Valor |>  sum(na.rm = T)) |> 
  dplyr::ungroup() |> 
  dplyr::arrange(Valor |>  dplyr::desc())


municipios_secretariado_importancia = municipios_secretariado_importancia$Municipio
categorias_secretariado_importancia = categorias_secretariado_importancia$Categorias


secretariado = secretariado |> 
  dplyr::mutate(
    Municipio = Municipio |>  factor(levels = municipios_secretariado_importancia),
    Categorias = Categorias |>  factor(levels = categorias_secretariado_importancia)
  )



g = ggplot(
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
    title = "Datos del secretariado por cada mil habitantes",
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

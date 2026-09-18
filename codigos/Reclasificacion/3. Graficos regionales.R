library(ggplot2)

llamadas = "outputs/Estadistica Ejercicio/Heatmap/Llamadas911 Region.xlsx" |>  readxl::read_excel()

categorias = llamadas |>  names()
categorias = categorias[-1]

llamadas = llamadas |> 
  tidyr::pivot_longer(
    cols = dplyr::any_of(categorias),
    names_to = "Categorias",
    values_to = "Valor"
  ) 


municipios_orden = llamadas |> 
  dplyr::group_by(Región) |> 
  dplyr::summarise(Valor = Valor |>  sum(na.rm = T)) |> 
  dplyr::ungroup() |> 
  dplyr::arrange(Valor |>  dplyr::desc())

municipios_orden = municipios_orden$Región

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
    Región = Región |>  factor(levels = municipios_orden),
    Categorias = Categorias |>  factor(levels = categorias_orden)
  )

g = ggplot(
  data = llamadas,
  aes(
    x = Región,
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
    x = "Región",
    y = "Categorías"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    axis.text.x = element_text(
      angle = 90,
      hjust = 1,
      vjust = 0.5,
      size = 10
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
  filename = "outputs/Img/Regional llamadas 911.png",
  plot = g,
  width = 13.44,     # 1344/100
  height = 6.59,      # 659/100
  units = "in",
  dpi = 600,
  bg = "white"
)







secretariado = "outputs/Estadistica Ejercicio/Heatmap/Secretariado Regional.xlsx" |>  readxl::read_excel()

categorias = (secretariado |>  names())[2:ncol(secretariado)]

secretariado = secretariado |> 
  tidyr::pivot_longer(
    cols = dplyr::any_of(categorias),
    names_to = "Categorias",
    values_to = "Valor"
  ) 

secretariado = secretariado |> 
  dplyr::mutate(
    Región = Región |>  factor(levels = municipios_orden),
    Categorias = Categorias |>  factor(levels = categorias_orden)
  )


gg = ggplot(
  data = secretariado,
  aes(
    x = Región,
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
    x = "Región",
    y = "Categorías"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    axis.text.x = element_text(
      angle = 90,
      hjust = 1,
      vjust = 0.5,
      size = 10
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




ggplot2::ggsave(
  filename = "outputs/Img/Regional Secretariado.png",
  plot = gg,
  width = 13.44,     # 1344/100
  height = 6.59,      # 659/100
  units = "in",
  dpi = 600,
  bg = "white"
)








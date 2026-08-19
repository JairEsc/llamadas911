datos = "outputs/Estadistica Ejercicio/Municipios 911.xlsx" |>  readxl::read_excel()

interes = c("Accidentes de tránsito", "Alarmas y objetos sospechosos", "Alcohol y drogas", "Alteración del orden público", "Amenazas, extorsión y conductas sospechosas",               
            "Armas, explosivos y pirotecnia", "Asistencia y apoyo ciudadano", "Crisis de salud mental y suicidio", "Daños a bienes y propiedad", "Emergencias médicas y lesiones",
            "Fenómenos naturales y riesgos urbanos", "Fraude y abuso patrimonial", "Incendios", "Incidentes con animales", "Incidentes y faltas viales",
            "Medio ambiente", "Otros incidentes de emergencia", "Personas no localizadas y libertad personal", "Robo y delitos patrimoniales", "Servicios públicos e infraestructura", 
            "Sustancias peligrosas y materiales químicos", "Violencia de genero y grupos vulnerables", "Delitos en materia de Hidrocarburo", "Delitos sexuales", "Delitos electorales")


interes = c("Alcohol y drogas", "Alteración del orden público", "Amenazas, extorsión y conductas sospechosas",               
            "Armas, explosivos y pirotecnia", "Daños a bienes y propiedad", 
            "Personas no localizadas y libertad personal", "Robo y delitos patrimoniales", 
             "Violencia de genero y grupos vulnerables", "Delitos en materia de Hidrocarburo", "Delitos sexuales")

interes = paste(interes, "mil habitantes")




grafico = datos |> 
  dplyr::select(Municipio, dplyr::any_of(interes)) |> 
  # dplyr::mutate(
  #   dplyr::across(
  #     .cols = dplyr::any_of(interes),
  #     .fns =  ~ (.x - min(.x, na.rm = T)) /  (max(.x, na.rm = T) - min(.x, na.rm = T))  #~.x |>  scale() |>  as.numeric()
  #   )
  # ) |> 
  tidyr::pivot_longer(
    cols = dplyr::any_of(interes),
    names_to = "Categorias",
    values_to = "Valor"
  ) |> 
  dplyr::mutate(
    Categorias = Categorias |>  gsub(pattern = "mil habitantes", replacement = "") |>  stringr::str_squish(),
  )


grafico = grafico |> 
  dplyr::arrange(Categorias |>  dplyr::desc())


a = c("Alteración del orden público", "Robo y delitos patrimoniales" ,
      "Amenazas, extorsión y conductas sospechosas",
      "Alcohol y drogas", "Violencia de genero y grupos vulnerables",
      "Daños a bienes y propiedad",
      "Armas, explosivos y pirotecnia", 
      "Personas no localizadas y libertad personal", 
      "Delitos sexuales",
      "Delitos en materia de Hidrocarburo")


orden = grafico |> 
  dplyr::group_by(Municipio) |> 
  dplyr::summarise(Valor = Valor |>  sum(na.rm = T)) |> 
  dplyr::ungroup() |> 
  dplyr::arrange(Valor |>  dplyr::desc())


grafico = grafico |> 
  dplyr::mutate(
    Municipio = Municipio |>  factor(levels = orden$Municipio),
    Categorias = Categorias |>  factor(levels = a)
  )

grafico$Categorias |>  unique()

orden$Municipio

grafico$Categorias |>  levels()

library(ggplot2)
library(dplyr)
library(forcats)
library(viridis)

g = ggplot(
  data = grafico,
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
    title = "Llamadas 911 mil habitantes",
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

plotly::ggplotly(g)































#############

grafico = datos |> 
  dplyr::select(Municipio, dplyr::any_of(interes)) |> 
  # dplyr::mutate(
  #   dplyr::across(
  #     .cols = dplyr::any_of(interes),
  #     .fns =  ~ (.x - min(.x, na.rm = T)) /  (max(.x, na.rm = T) - min(.x, na.rm = T))  #~.x |>  scale() |>  as.numeric()
  #   )
  # ) |> 
  tidyr::pivot_longer(
    cols = dplyr::any_of(interes),
    names_to = "Categorias",
    values_to = "Valor"
  ) |> 
  dplyr::mutate(
    Categorias = Categorias |>  gsub(pattern = "mil habitantes", replacement = "") |>  stringr::str_squish(),
    Valor = dplyr::if_else(condition = Valor == 0, true = NA, false = Valor)
  )


library(ggplot2)
library(dplyr)
library(forcats)
library(viridis)

g = ggplot(
  data = grafico,
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
  scale_fill_distiller(palette = "RdPu", direction = 1, na.value = "white")+
  labs(
    title = "Llamadas 911 mil habitantes",
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



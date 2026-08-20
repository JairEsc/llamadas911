source("codigos/Reclasificacion/Municipios y Categorias Ordenadas.R")
generar_heatmap = function(datos, municipios_clasificacion, categorias_clasificacion, titulo){
  
  grafico = datos |> 
    dplyr::mutate(
      Municipio = Municipio |>  factor(levels = municipios_clasificacion),
      Categorias = Categorias |>  factor(levels = categorias_clasificacion)
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
    scale_fill_distiller(palette = "RdPu", direction = 1)+
    labs(
      title = titulo,
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
  
  return(g)
}


################
### Llamadas ###
################

llamadas = "outputs/Estadistica Ejercicio/Municipios 911.xlsx" |>  readxl::read_excel()

llamadas = llamadas |> 
  dplyr::select(Municipio, dplyr::any_of(categorias_interes |>  paste("mil habitantes"))) |> 
  tidyr::pivot_longer(
    cols = dplyr::any_of(categorias_interes  |>  paste("mil habitantes")),
    names_to = "Categorias",
    values_to = "Valor"
  ) |> 
  dplyr::mutate(
    Categorias = Categorias |>  gsub(pattern = "mil habitantes", replacement = "") |>  stringr::str_squish(),
  )


grafico_llamadas = generar_heatmap(datos = llamadas, 
                                   municipios_clasificacion = municipios_orden_importancia,
                                   categorias_clasificacion = categorias_importancia,
                                   titulo = "Llamadas 911 por cada 1,000 habitantes"
                                     )

grafico_llamadas



####################
### Secretariado ###
####################

secretariado = "outputs/Estadistica Ejercicio/Municipios Secretariado.xlsx" |>  readxl::read_excel()

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


grafico_secretariado = generar_heatmap(datos = secretariado, 
                                   municipios_clasificacion = municipios_secretariado_importancia,
                                   categorias_clasificacion = categorias_secretariado_importancia,
                                   titulo = "Secretariado por cada 1,000 habitantes"
)

grafico_secretariado

#' @title mod_tsOutput and mod_ts
#'
#' @description Shiny module to show the variables timeseries
#'
#' @param id shiny id
#'
#' @export
mod_tsOutput <- function(id) {
  # ns
  ns <- shiny::NS(id)
  shiny::tagList(
    shiny::column(
      width = 12,
      echarts4r::echarts4rOutput(ns("output_ts_temp"), height = 200),
      echarts4r::echarts4rOutput(ns("output_ts_rh"), height = 200),
      echarts4r::echarts4rOutput(ns("output_ts_rpp"), height = 200)
    )
  )
}

#' mod_ts server function
#' @param input internal
#' @param output internal
#' @param session internal
#' @param user_inputs reactiveValues containing the user selected inputs
#' @param duckdb_proxy duckdb connection
#' @param lang lang selected
#'
#' @export
#'
#' @rdname mod_tsOutput
mod_ts <- function(
  input, output, session,
  user_inputs, duckdb_proxy,
  lang
) {
  # get the ns
  ns <- session$ns

  # hostess ready
  hostess_ts <- waiter::Hostess$new(infinite = TRUE)
  hostess_ts$set_loader(waiter::hostess_loader(
    svg = "images/hostess_image.svg",
    progress_type = "fill",
    fill_direction = "ltr"
  ))

  # update the data on input change (only refresh, not lang long)
  ts_data <- shiny::reactive({
    shiny::validate(
      shiny::need(user_inputs$user_latitude, "Missing latitude"),
      shiny::need(user_inputs$user_longitude, "Missing longitude")
    )

    # show hostess
    waiter_ts <- waiter::Waiter$new(
      id = ns("output_ts_temp"),
      html = shiny::tagList(
        hostess_ts$get_loader(),
        shiny::br(),
        shiny::p(glue::glue(
          "{translate_app('getting_data_for', lang())} {user_inputs$longitude} - {user_inputs$user_latitude}"
        )),
        shiny::p(translate_app("please_wait", lang()))
      ),
      color = "#E8EAEB"
    )
    waiter_ts$show()
    on.exit(waiter_ts$hide(), add = TRUE)
    hostess_ts$start()
    on.exit(hostess_ts$close(), add = TRUE)

    parquet_files_vector <- seq(Sys.Date() - 370, Sys.Date() - 5, by = "day") |>
      purrr::map_chr(
        .f = \(i_date) {
          glue::glue("https://data-emf.creaf.cat/public/parquet/daily_interpolated_meteo/year={lubridate::year(i_date)}/month={lubridate::month(i_date)}/day={lubridate::day(i_date)}/part-0.parquet")
        }
      )
    parquet_files_array <- glue::glue(
      '[{glue::glue_sql(.con = duckdb_proxy, "{parquet_files_vector}") |> glue::glue_sql_collapse(sep = ", ")}]'
    )
    coords_bbox <- dplyr::tibble(
      x = user_inputs$user_longitude, y = user_inputs$user_latitude
    ) |>
      sf::st_as_sf(coords = c("x", "y"), crs = 4326) |>
      sf::st_transform(crs = 25830) |>
      sf::st_buffer(250) |>
      sf::st_bbox()

    ts_query <- glue::glue(
      # .con = duckdb_proxy,
      "SELECT 
        dates,
        avg(COLUMNS('elevation|Temperature|Prec|Humidity|Radiation|Wind|PET|Thermal')),
        first(geom_text) AS geom_text
      FROM read_parquet({parquet_files_array})
      WHERE geom.x > {coords_bbox$xmin} AND
        geom.x < {coords_bbox$xmax} AND
        geom.y > {coords_bbox$ymin} AND
        geom.y < {coords_bbox$ymax}
      GROUP BY dates;"
    )

    DBI::dbGetQuery(duckdb_proxy, ts_query) |>
      dplyr::arrange(dates)
  }) |>
    shiny::bindCache(
      user_inputs$user_longitude, user_inputs$user_latitude,
      cache = "session"
    ) |>
    shiny::bindEvent(user_inputs$user_ts_update)

  # echart outputs (temp, rh and rad-prec-pet (rpp))
  output$output_ts_temp <- echarts4r::renderEcharts4r({
    ts_data() |>
      echarts4r::e_charts(dates) |>
      echarts4r::e_area(MaxTemperature) |>
      echarts4r::e_area(MeanTemperature) |>
      echarts4r::e_area(MinTemperature) |>
      echarts4r::e_datazoom(toolbox = FALSE, type = "slider", show = FALSE) |>
      echarts4r::e_group("timeseries")
  })

  output$output_ts_rh <- echarts4r::renderEcharts4r({
    ts_data() |>
      echarts4r::e_charts(dates) |>
      echarts4r::e_area(MaxRelativeHumidity) |>
      echarts4r::e_area(MeanRelativeHumidity) |>
      echarts4r::e_area(MinRelativeHumidity) |>
      echarts4r::e_datazoom(toolbox = FALSE, type = "slider", show = FALSE) |>
      echarts4r::e_group("timeseries")
  })

  output$output_ts_rpp <- echarts4r::renderEcharts4r({
    ts_data() |>
      echarts4r::e_charts(dates) |>
      echarts4r::e_area(Radiation) |>
      echarts4r::e_area(PET) |>
      echarts4r::e_bar(Precipitation) |>
      echarts4r::e_datazoom(toolbox = FALSE, type = "slider") |>
      echarts4r::e_group("timeseries") |>
      echarts4r::e_connect_group("timeseries")
  })
}
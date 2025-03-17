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
      shiny::div(
        id = ns("ts_hostess"),
        echarts4r::e_theme_register(
          '{"color":["#14ABCC","#7CC69A","#E3DF68"],"backgroundColor":"#191A1A"}',
          name = "emf_colors"
        ),
        echarts4r::echarts4rOutput(ns("output_ts_temp"), height = 195),
        echarts4r::echarts4rOutput(ns("output_ts_rh"), height = 195),
        echarts4r::echarts4rOutput(ns("output_ts_rpp"), height = 210)
      )
    )
  )
}

#' mod_ts server function
#' @param input internal
#' @param output internal
#' @param session internal
#' @param user_inputs reactiveValues containing the user selected inputs
#' @param button_session session object from user inputs module
#' @param duckdb_proxy duckdb connection
#' @param lang lang selected
#'
#' @export
#'
#' @rdname mod_tsOutput
mod_ts <- function(
  input, output, session,
  user_inputs,
  button_session,
  duckdb_proxy, lang
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

  # extended task for ts_data, to avoid blocking the app while calculating the
  # time series
  # 1. create extended task with mirai function
  ts_data <- shiny::ExtendedTask$new(
    \(...) {
      mirai::mirai({
        # duckdb conn
        duckdb_parquet <- duckdb::dbConnect(duckdb::duckdb())
        withr::defer(duckdb::dbDisconnect(duckdb_parquet))
        install_httpfs_statement <- glue::glue_sql(
          .con = duckdb_parquet,
          "INSTALL httpfs;"
        )
        httpfs_statement <- glue::glue_sql(
          .con = duckdb_parquet,
          "LOAD httpfs;"
        )
        DBI::dbExecute(duckdb_parquet, install_httpfs_statement)
        DBI::dbExecute(duckdb_parquet, httpfs_statement)
        # parquet files to read (last year)
        parquet_files_vector <- seq(Sys.Date() - 370, Sys.Date() - 5, by = "day") |>
          purrr::map_chr(
            .f = \(i_date) {
              glue::glue("https://data-emf.creaf.cat/public/parquet/daily_interpolated_meteo/year={lubridate::year(i_date)}/month={lubridate::month(i_date)}/day={lubridate::day(i_date)}/part-0.parquet")
            }
          )
        parquet_files_array <- glue::glue(
          '[{glue::glue_sql(.con = duckdb_parquet, "{parquet_files_vector}") |> glue::glue_sql_collapse(sep = ", ")}]'
        )
        # user points bbox (500^2)
        coords_bbox <- dplyr::tibble(
          x = user_longitude, y = user_latitude
        ) |>
          sf::st_as_sf(coords = c("x", "y"), crs = 4326) |>
          sf::st_transform(crs = 25830) |>
          sf::st_buffer(250) |>
          sf::st_bbox()
        # duckdb sql query
        ts_query <- glue::glue(
          # .con = duckdb_parquet,
          "SELECT 
            dates,
            avg(COLUMNS('elevation|Temperature|Prec|Humidity|Radiation|Wind|PET|Thermal'))
          FROM read_parquet({parquet_files_array})
          WHERE geom.x > {coords_bbox$xmin} AND
            geom.x < {coords_bbox$xmax} AND
            geom.y > {coords_bbox$ymin} AND
            geom.y < {coords_bbox$ymax}
          GROUP BY dates;"
        )
        # return the result of the query ordered by dates
        DBI::dbGetQuery(duckdb_parquet, ts_query) |>
          dplyr::arrange(dates) |>
          dplyr::mutate(
            point_latitude = user_latitude,
            point_longitude = user_longitude
          )
      }, ...)
    }
  ) |>
    bslib::bind_task_button("user_ts_update", session = button_session)
  # 2. create an observer, bind it to the action button and invoke the
  # extended task
  shiny::observe({
    # validate inputs
    shiny::validate(
      shiny::need(user_inputs$user_latitude, "Missing latitude"),
      shiny::need(user_inputs$user_longitude, "Missing longitude")
    )
    # invoke extended task
    ts_data$invoke(
      user_longitude = user_inputs$user_longitude,
      user_latitude = user_inputs$user_latitude
    )
  }) |>
    shiny::bindEvent(user_inputs$user_ts_update)

  # 3. observer for hostess (copied from bslib bind_task_button code)
  was_running <- FALSE
  shiny::observe({
    waiter_ts <- waiter::Waiter$new(
      id = ns("ts_hostess"),
      html = shiny::tagList(
        hostess_ts$get_loader(),
        shiny::br(),
        shiny::p(glue::glue(
          "{translate_app('getting_data_for', lang())} {shiny::isolate(user_inputs$user_longitude)} - {shiny::isolate(user_inputs$user_latitude)}"
        )),
        shiny::p(translate_app("please_wait", lang()))
      ),
      color = '#E8EAEB'
    )
    running <- ts_data$status() == "running"
    if (running != was_running) {
      was_running <<- running
      if (running) {
        # show hostess
        waiter_ts$show()
        hostess_ts$start()
      } else {
        waiter_ts$hide()
        hostess_ts$close()
      }
    }
  }, priority = 1000)

  # 4. use $result() to get the extended task result when calculated
  # echart outputs (temp, rh and rad-prec-pet (rpp))
  output$output_ts_temp <- echarts4r::renderEcharts4r({
    ts_data$result() |>
      echarts4r::e_charts(dates) |>
      echarts4r::e_line(MinTemperature, symbol = "none") |>
      echarts4r::e_line(MeanTemperature, symbol = "none") |>
      echarts4r::e_line(MaxTemperature, symbol = "none") |>
      echarts_formatter()
  })
  output$output_ts_rh <- echarts4r::renderEcharts4r({
    ts_data$result() |>
      echarts4r::e_charts(dates) |>
      echarts4r::e_line(MaxRelativeHumidity, symbol = "none") |>
      echarts4r::e_line(MeanRelativeHumidity, symbol = "none") |>
      echarts4r::e_line(MinRelativeHumidity, symbol = "none") |>
      echarts_formatter()
  })
  output$output_ts_rpp <- echarts4r::renderEcharts4r({
    ts_data$result() |>
      echarts4r::e_charts(dates) |>
      echarts4r::e_bar(Precipitation) |>
      echarts4r::e_line(PET, symbol = "none") |>
      echarts4r::e_line(Radiation, symbol = "none") |>
      echarts_formatter(bottom = TRUE)
  })

  # Collect reactives to pass to the main app or other modules
  ts_reactives <- shiny::reactiveValues()
  shiny::observe({
    ts_reactives$ts_data <- ts_data
  })
  return(ts_reactives)
}
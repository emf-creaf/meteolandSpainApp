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
    shiny::div(
      id = ns("ts_hostess"),
      echarts4r::echarts4rOutput(ns("output_ts_temp"), height = 195),
      echarts4r::echarts4rOutput(ns("output_ts_rh"), height = 195),
      echarts4r::echarts4rOutput(ns("output_ts_rpp"), height = 205),
      shiny::uiOutput(ns("output_ts_point"))
    )
  )
}

#' mod_ts server function
#' @param input internal
#' @param output internal
#' @param session internal
#' @param user_inputs reactiveValues containing the user selected inputs
#' @param button_session session object from user inputs module
#' @param lang lang selected
#'
#' @export
#'
#' @rdname mod_tsOutput
mod_ts <- function(
  input, output, session,
  user_inputs, button_session,
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

  # extended task for ts_data, to avoid blocking the app while calculating the
  # time series
  # 1. create extended task with mirai function
  # ts_data <- shiny::ExtendedTask$new(
  #   \(...) {
  #     mirai::mirai({
  #       # duckdb conn
  #       duckdb_parquet <- duckdb::dbConnect(duckdb::duckdb())
  #       withr::defer(duckdb::dbDisconnect(duckdb_parquet))
  #       install_httpfs_statement <- glue::glue_sql(
  #         .con = duckdb_parquet,
  #         "INSTALL httpfs;"
  #       )
  #       httpfs_statement <- glue::glue_sql(
  #         .con = duckdb_parquet,
  #         "LOAD httpfs;"
  #       )
  #       credentials_statement <- glue::glue(
  #         "CREATE OR REPLACE SECRET secret (
  #           TYPE s3,
  #           PROVIDER config,
  #           KEY_ID '{Sys.getenv('AWS_ACCESS_KEY_ID')}',
  #           SECRET '{Sys.getenv('AWS_SECRET_ACCESS_KEY')}',
  #           ENDPOINT '{Sys.getenv('AWS_S3_ENDPOINT')}',
  #           REGION ''
  #         );"
  #       )
  #       DBI::dbExecute(duckdb_parquet, install_httpfs_statement)
  #       DBI::dbExecute(duckdb_parquet, httpfs_statement)
  #       DBI::dbExecute(duckdb_parquet, credentials_statement)
  #       # parquet files to read (last year)
  #       # parquet_files_vector <- seq(Sys.Date() - 370, Sys.Date() - 5, by = "day") |>
  #       #   purrr::map_chr(
  #       #     .f = \(i_date) {
  #       #       glue::glue("https://data-emf.creaf.cat/public/parquet/daily_interpolated_meteo/year={lubridate::year(i_date)}/month={lubridate::month(i_date)}/day={lubridate::day(i_date)}/part-0.parquet")
  #       #     }
  #       #   )
  #       # parquet_files_array <- glue::glue(
  #       #   '[{glue::glue_sql(.con = duckdb_parquet, "{parquet_files_vector}") |> glue::glue_sql_collapse(sep = ", ")}]'
  #       # )
  #       # user points bbox (500^2)
  #       coords_bbox <- dplyr::tibble(
  #         x = user_longitude, y = user_latitude
  #       ) |>
  #         sf::st_as_sf(coords = c("x", "y"), crs = 4326) |>
  #         sf::st_transform(crs = 25830) |>
  #         sf::st_buffer(250) |>
  #         sf::st_bbox()
  #       # duckdb sql query
  #       ts_query <- glue::glue(
  #         # .con = duckdb_parquet,
  #         "SELECT 
  #           dates,
  #           avg(COLUMNS('elevation|slope|aspect|Temperature|Prec|Humidity|Radiation|Wind|PET|Thermal'))
  #         FROM read_parquet('s3://meteoland-spain-app-meteo/*/*/*/*.parquet')
  #         WHERE geom.x > {coords_bbox$xmin} AND
  #           geom.x < {coords_bbox$xmax} AND
  #           geom.y > {coords_bbox$ymin} AND
  #           geom.y < {coords_bbox$ymax}
  #         GROUP BY dates;"
  #       )
  #       # ts_query <- glue::glue(
  #       #   # .con = duckdb_parquet,
  #       #   "SELECT 
  #       #     dates,
  #       #     avg(COLUMNS('elevation|Temperature|Prec|Humidity|Radiation|Wind|PET|Thermal'))
  #       #   FROM read_parquet({parquet_files_array})
  #       #   WHERE geom.x > {coords_bbox$xmin} AND
  #       #     geom.x < {coords_bbox$xmax} AND
  #       #     geom.y > {coords_bbox$ymin} AND
  #       #     geom.y < {coords_bbox$ymax}
  #       #   GROUP BY dates;"
  #       # )
  #       # return the result of the query ordered by dates
  #       DBI::dbGetQuery(duckdb_parquet, ts_query) |>
  #         dplyr::arrange(dates) |>
  #         dplyr::mutate(
  #           point_latitude = user_latitude,
  #           point_longitude = user_longitude
  #         )
  #     }, ...)
  #   }
  # ) |>
  ts_data <- shiny::ExtendedTask$new(
    \(...) {
      mirai::mirai_map(
        1L:12L,
        \(month_to_query) {
          # db preparation
          duckdb_proxy <- DBI::dbConnect(duckdb::duckdb())
          withr::defer(DBI::dbDisconnect(duckdb_proxy))
          install_httpfs_statement <- glue::glue_sql(
            .con = duckdb_proxy,
            "INSTALL httpfs;"
          )
          httpfs_statement <- glue::glue_sql(
            .con = duckdb_proxy,
            "LOAD httpfs;"
          )
          install_spatial_statement <- glue::glue_sql(
            .con = duckdb_proxy,
            "INSTALL spatial;"
          )
          spatial_statement <- glue::glue_sql(
            .con = duckdb_proxy,
            "LOAD spatial;"
          )
          credentials_statement <- glue::glue(
            "CREATE OR REPLACE SECRET secret (
              TYPE s3,
              PROVIDER config,
              KEY_ID '{Sys.getenv('AWS_ACCESS_KEY_ID')}',
              SECRET '{Sys.getenv('AWS_SECRET_ACCESS_KEY')}',
              REGION '',
              ENDPOINT '{Sys.getenv('AWS_S3_ENDPOINT')}'
            );"
          )
          DBI::dbExecute(duckdb_proxy, install_httpfs_statement)
          DBI::dbExecute(duckdb_proxy, httpfs_statement)
          DBI::dbExecute(duckdb_proxy, install_spatial_statement)
          DBI::dbExecute(duckdb_proxy, spatial_statement)
          DBI::dbExecute(duckdb_proxy, credentials_statement)

          # month query
          ts_query <- glue::glue(
            "SELECT 
              dates,
              avg(COLUMNS('elevation|slope|aspect|Temperature|Prec|Humidity|Radiation|Wind|PET|Thermal')),
              first(geom_text) AS geom_text
            FROM read_parquet('s3://meteoland-spain-app-meteo/*/*/*/*.parquet')
            WHERE geom.x > {coords_bbox[['xmin']]} AND
              geom.x < {coords_bbox[['xmax']]} AND
              geom.y > {coords_bbox[['ymin']]} AND
              geom.y < {coords_bbox[['ymax']]} AND
              month = {month_to_query}
            GROUP BY dates
            ;"
          )
          DBI::dbGetQuery(duckdb_proxy, ts_query) |>
            dplyr::arrange(dates) |>
            dplyr::mutate(
              point_latitude = user_latitude,
              point_longitude = user_longitude
            )
        },
        ...
      )
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
    # user points bbox (500^2)
    coords_bbox <- dplyr::tibble(
      x = user_inputs$user_longitude, y = user_inputs$user_latitude
    ) |>
      sf::st_as_sf(coords = c("x", "y"), crs = 4326) |>
      sf::st_transform(crs = 25830) |>
      sf::st_buffer(250) |>
      sf::st_bbox()
    # invoke extended task
    ts_data$invoke(
      user_longitude = user_inputs$user_longitude,
      user_latitude = user_inputs$user_latitude,
      coords_bbox = coords_bbox
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
  # title only in the first, zoom only in last
  output$output_ts_temp <- echarts4r::renderEcharts4r({
    ts_data$result() |>
      purrr::list_rbind() |>
      dplyr::arrange(dates) |>
      echarts4r::e_charts(dates) |>
      echarts4r::e_line(
        MinTemperature, symbol = "none",
        name = translate_app("MinTemperature", lang())
      ) |>
      echarts4r::e_line(
        MeanTemperature, symbol = "none",
        name = translate_app("MeanTemperature", lang())
      ) |>
      echarts4r::e_line(
        MaxTemperature, symbol = "none",
        name = translate_app("MaxTemperature", lang())
      ) |>
      echarts_ts_formatter()
  })
  output$output_ts_rh <- echarts4r::renderEcharts4r({
    ts_data$result() |>
      purrr::list_rbind() |>
      dplyr::arrange(dates) |>
      echarts4r::e_charts(dates) |>
      echarts4r::e_line(
        MinRelativeHumidity, symbol = "none",
        name = translate_app("MinRelativeHumidity", lang())
      ) |>
      echarts4r::e_line(
        MeanRelativeHumidity, symbol = "none",
        name = translate_app("MeanRelativeHumidity", lang())
      ) |>
      echarts4r::e_line(
        MaxRelativeHumidity, symbol = "none",
        name = translate_app("MaxRelativeHumidity", lang())
      ) |>
      echarts_ts_formatter()
  })
  output$output_ts_rpp <- echarts4r::renderEcharts4r({
    ts_data$result() |>
      purrr::list_rbind() |>
      dplyr::arrange(dates) |>
      echarts4r::e_charts(dates) |>
      echarts4r::e_bar(
        Precipitation,
        name = translate_app("Precipitation", lang())
      ) |>
      echarts4r::e_line(
        PET, symbol = "none",
        name = translate_app("PET", lang())
      ) |>
      echarts4r::e_line(
        Radiation, symbol = "none",
        name = translate_app("Radiation", lang())
      ) |>
      echarts4r::e_line(
        WindSpeed, symbol = "none",
        name = translate_app("WindSpeed", lang())
      ) |>
      echarts_ts_formatter(bottom = TRUE)
  })

  # 5. Use $result() also to get the point info and show it in the
  # ui
  output$output_ts_point <- shiny::renderUI({
    shiny::validate(
      shiny::need(ts_data$result(), "no ts data yet")
    )

    point_data <- ts_data$result() |>
      purrr::list_rbind()

    point_elevation <- point_data |>
      dplyr::pull(elevation) |>
      dplyr::first() |>
      round(2)
    point_aspect <- point_data |>
      dplyr::pull(aspect) |>
      dplyr::first() |>
      round(2)
    point_slope <- point_data |>
      dplyr::pull(slope) |>
      dplyr::first() |>
      round(2)
    point_latitude <- point_data |>
      dplyr::pull(point_latitude) |>
      dplyr::first()
    point_longitude <- point_data |>
      dplyr::pull(point_longitude) |>
      dplyr::first()

    shiny::tagList(
      shiny::wellPanel(
        shiny::div(
          align = "center",
          shiny::icon("map-location"),
          glue::glue("{point_longitude}, {point_latitude}  |  "),
          shiny::icon("mountain"),
          glue::glue("{point_elevation}m asl.  |  "),
          shiny::icon("hill-rockslide"),
          glue::glue("{point_slope}º  |  "),
          shiny::icon("compass"),
          glue::glue("{point_aspect}º")
        )
      )
    )
  })

  # Collect reactives to pass to the main app or other modules
  ts_reactives <- shiny::reactiveValues()
  shiny::observe({
    ts_reactives$ts_data <- ts_data
  })
  return(ts_reactives)
}
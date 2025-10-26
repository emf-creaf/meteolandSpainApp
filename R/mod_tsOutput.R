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
    bslib::layout_sidebar(
      bslib::layout_column_wrap(
        width = "350px",
        !!!lapply(
          c(
            "MeanTemperature",
            "MinTemperature",
            "MaxTemperature",
            "ThermalAmplitude",
            "MeanRelativeHumidity",
            "MinRelativeHumidity",
            "MaxRelativeHumidity",
            "Precipitation",
            "Radiation",
            "WindSpeed",
            "PET"
          ),
          \(id) {
            bslib::card(
              echarts4r::echarts4rOutput(ns(paste0("ts_", id)), height = "250px")
            )
          }
        )
      ),
      sidebar = bslib::sidebar(
        shiny::uiOutput(ns('inputs_ts')),
        class = "inputs_ts",
        open = list(desktop = "open", mobile = "always-above")
      )
    )
  )
}

#' mod_ts server function
#' @param input internal
#' @param output internal
#' @param session internal
#' @param arrow_sink bucket s3 filesystem
#' @param lang lang selected
#'
#' @export
#'
#' @rdname mod_tsOutput
mod_ts <- function(
  input, output, session,
  arrow_sink,
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

  # ts inputs
  output$inputs_ts <- shiny::renderUI({
    # tagList creating the draggable absolute panel
    shiny::tagList(
      # first row of inputs, variable and dates
      shiny::h4(translate_app("ts_controls", lang())),
      shiny::br(),
      shiny::fluidRow(
        shiny::column(
          width = 12,
          # aggregation input
          shinyWidgets::materialSwitch(
            ns("user_ts_type"), label = translate_app("user_ts_type", lang()),
            value = FALSE
          ),
          shiny::conditionalPanel(
            condition = "input.user_ts_type == false", ns = ns,
            shiny::br(),
            shinyWidgets::pickerInput(
              ns("user_province"), label = translate_app("user_province", lang()),
              choices = province_names,
              selected = province_names[1],
              multiple = FALSE,
              options = shinyWidgets::pickerOptions(
                actionsBox = FALSE,
                tickIcon = "glyphicon-ok-sign"
              )
            )
          ),
          shiny::conditionalPanel(
            condition = "input.user_ts_type == true", ns = ns,
            shiny::br(),
            # user_longitude
            shiny::numericInput(
              ns("user_longitude"), translate_app("user_longitude", lang()),
              value = -3.034,
              min = -9.500, max = 4, step = 0.100,
              updateOn = "blur"
            ),
            # user_latitude
            shiny::numericInput(
              ns("user_latitude"), translate_app("user_latitude", lang()),
              value = 43.216,
              min = 35.500, max = 44, step = 0.100,
              updateOn = "blur"
            ),
            # user_ts_calculate
            bslib::input_task_button(
              ns("user_ts_update"), translate_app("user_ts_calculate", lang()),
              icon = shiny::icon("rotate"),
              label_busy = translate_app("user_ts_refresh_calculating", lang())
            )
          ),
          shiny::br(), shiny::br(),
          # download
          shiny::wellPanel(
            shiny::h4(translate_app("download_ts_title", lang())),
            shiny::p(translate_app("download_ts_text", lang())),
            shiny::downloadButton(
              ns("download_ts_button"), translate_app("download_ts_button", lang()),
              icon = shiny::icon("up-right-from-square")
            )
          )
        )
      ) # END of first row of inputs
    ) # end of tagList
  }) # end of ts inputs ui

  # province ts data
  province_data <- shiny::reactive({
    # only run when inputs are populated
    shiny::validate(
      shiny::need(input$user_province, "Missing province")
    )

    # show hostess
    waiter_ts <- waiter::Waiter$new(
      id = NULL,
      html = shiny::tagList(
        hostess_ts$get_loader(),
        shiny::br(),
        shiny::p(glue::glue(
          "{translate_app('getting_data_for', lang())} {input$user_province}"
        )),
        shiny::p(translate_app("please_wait", lang()))
      ),
      color = '#f8f9fa71'
    )
    waiter_ts$show()
    on.exit(waiter_ts$hide(), add = TRUE)
    hostess_ts$start()
    on.exit(hostess_ts$close(), add = TRUE)

    province_sel <- input$user_province
    # arrow data
    arrow::open_dataset(
      arrow_sink,
      factory_options = list(
        selector_ignore_prefixes = c(
          "daily_interpolated_meteo_cvs",
          "daily_interpolated_meteo_bitmaps"
        )
      )
    ) |>
      dplyr::filter(provincia == province_sel) |>
      dplyr::as_tibble()
  }) |>
    shiny::bindCache(
      # input$user_var,
      input$user_province,
      cache = "session"
    ) |>
    shiny::bindEvent(
      input$user_province
    )


  ts_coords_data <- shiny::ExtendedTask$new(
    \(...) {
      mirai::mirai_map(
        1L:12L,
        \(month_to_query) {
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
    bslib::bind_task_button("user_ts_update")
  # 2. create an observer, bind it to the action button and invoke the
  # extended task
  shiny::observe({
    # validate inputs
    shiny::validate(
      shiny::need(input$user_latitude, "Missing latitude"),
      shiny::need(input$user_longitude, "Missing longitude")
    )
    # user points bbox (500^2)
    coords_bbox <- dplyr::tibble(
      x = input$user_longitude, y = input$user_latitude
    ) |>
      sf::st_as_sf(coords = c("x", "y"), crs = 4326) |>
      sf::st_transform(crs = 25830) |>
      sf::st_buffer(250) |>
      sf::st_bbox()
    # invoke extended task
    ts_coords_data$invoke(
      user_longitude = input$user_longitude,
      user_latitude = input$user_latitude,
      coords_bbox = coords_bbox
    )
  }) |>
    shiny::bindEvent(input$user_ts_update)

  # observer for hostess (copied from bslib bind_task_button code)
  was_running <- FALSE
  shiny::observe({
    waiter_ts <- waiter::Waiter$new(
      id = NULL,
      html = shiny::tagList(
        hostess_ts$get_loader(),
        shiny::br(),
        shiny::p(glue::glue(
          "{translate_app('getting_data_for', lang())} {shiny::isolate(input$user_longitude)} - {shiny::isolate(input$user_latitude)}"
        )),
        shiny::p(translate_app("please_wait", lang()))
      ),
      color = '#f8f9fa71'
    )
    running <- ts_coords_data$status() == "running"
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

  # echart outputs
  output$ts_Precipitation <- echarts4r::renderEcharts4r({
    if (isFALSE(input$user_ts_type)) {
      ts_data <- province_data()
    } else {
      shiny::validate(
        shiny::need(ts_coords_data$result(), "No time series data yet, press the button")
      )
      ts_data <- ts_coords_data$result() |>
        purrr::list_rbind()
    }

    ts_data |>
      dplyr::arrange(dates) |>
      echarts4r::e_charts(dates) |>
      echarts4r::e_line(
        Precipitation, symbol = "none",
        name = translate_app("Precipitation", lang()),
        lineStyle = list(color = "#2575CF"),
        itemStyle = list(color = "#2575CF"),
        areaStyle = list(
          color = list(
            type = "linear", x = 0, y = 0, x2 = 0, y2 = 1,
            colorStops = list(
              list(offset = 0, color = "#2575CF"),
              list(offset = 0.25, color = "#2575CF8F"),
              list(offset = 0.5, color = "#2575CF4F"),
              list(offset = 0.75, color = "#2575CF2F"),
              list(offset = 1, color = "#2575CF00")
            )
          ),
          opacity = 0.7
        )
      ) |>
      echarts_ts_formatter()
  })

  output$ts_MeanTemperature <- echarts4r::renderEcharts4r({
    if (isFALSE(input$user_ts_type)) {
      ts_data <- province_data()
    } else {
      shiny::validate(
        shiny::need(ts_coords_data$result(), "No time series data yet, press the button")
      )
      ts_data <- ts_coords_data$result() |>
        purrr::list_rbind()
    }

    ts_data |>
      dplyr::arrange(dates) |>
      echarts4r::e_charts(dates) |>
      echarts4r::e_line(
        MeanTemperature, symbol = "none",
        name = translate_app("MeanTemperature", lang()),
        lineStyle = list(color = "#C75C00"),
        itemStyle = list(color = "#C75C00"),
        areaStyle = list(
          color = list(
            type = "linear", x = 0, y = 0, x2 = 0, y2 = 1,
            colorStops = list(
              list(offset = 0, color = "#C75C00"),
              list(offset = 0.25, color = "#C75C008F"),
              list(offset = 0.5, color = "#C75C004F"),
              list(offset = 0.75, color = "#C75C002F"),
              list(offset = 1, color = "#C75C0000")
            )
          ),
          opacity = 0.7
        )
      ) |>
      echarts_ts_formatter()
  })
  output$ts_MinTemperature <- echarts4r::renderEcharts4r({
    if (isFALSE(input$user_ts_type)) {
      ts_data <- province_data()
    } else {
      shiny::validate(
        shiny::need(ts_coords_data$result(), "No time series data yet, press the button")
      )
      ts_data <- ts_coords_data$result() |>
        purrr::list_rbind()
    }

    ts_data |>
      dplyr::arrange(dates) |>
      echarts4r::e_charts(dates) |>
      echarts4r::e_line(
        MinTemperature, symbol = "none",
        name = translate_app("MinTemperature", lang()),
        lineStyle = list(color = "#C75C00"),
        itemStyle = list(color = "#C75C00"),
        areaStyle = list(
          color = list(
            type = "linear", x = 0, y = 0, x2 = 0, y2 = 1,
            colorStops = list(
              list(offset = 0, color = "#C75C00"),
              list(offset = 0.25, color = "#C75C008F"),
              list(offset = 0.5, color = "#C75C004F"),
              list(offset = 0.75, color = "#C75C002F"),
              list(offset = 1, color = "#C75C0000")
            )
          ),
          opacity = 0.7
        )
      ) |>
      echarts_ts_formatter()
  })
  output$ts_MaxTemperature <- echarts4r::renderEcharts4r({
    if (isFALSE(input$user_ts_type)) {
      ts_data <- province_data()
    } else {
      shiny::validate(
        shiny::need(ts_coords_data$result(), "No time series data yet, press the button")
      )
      ts_data <- ts_coords_data$result() |>
        purrr::list_rbind()
    }

    ts_data |>
      dplyr::arrange(dates) |>
      echarts4r::e_charts(dates) |>
      echarts4r::e_line(
        MaxTemperature, symbol = "none",
        name = translate_app("MaxTemperature", lang()),
        lineStyle = list(color = "#C75C00"),
        itemStyle = list(color = "#C75C00"),
        areaStyle = list(
          color = list(
            type = "linear", x = 0, y = 0, x2 = 0, y2 = 1,
            colorStops = list(
              list(offset = 0, color = "#C75C00"),
              list(offset = 0.25, color = "#C75C008F"),
              list(offset = 0.5, color = "#C75C004F"),
              list(offset = 0.75, color = "#C75C002F"),
              list(offset = 1, color = "#C75C0000")
            )
          ),
          opacity = 0.7
        )
      ) |>
      echarts_ts_formatter()
  })
  output$ts_ThermalAmplitude <- echarts4r::renderEcharts4r({
    if (isFALSE(input$user_ts_type)) {
      ts_data <- province_data()
    } else {
      shiny::validate(
        shiny::need(ts_coords_data$result(), "No time series data yet, press the button")
      )
      ts_data <- ts_coords_data$result() |>
        purrr::list_rbind()
    }

    ts_data |>
      dplyr::arrange(dates) |>
      echarts4r::e_charts(dates) |>
      echarts4r::e_line(
        ThermalAmplitude, symbol = "none",
        name = translate_app("ThermalAmplitude", lang()),
        lineStyle = list(color = "#C75C00"),
        itemStyle = list(color = "#C75C00"),
        areaStyle = list(
          color = list(
            type = "linear", x = 0, y = 0, x2 = 0, y2 = 1,
            colorStops = list(
              list(offset = 0, color = "#C75C00"),
              list(offset = 0.25, color = "#C75C008F"),
              list(offset = 0.5, color = "#C75C004F"),
              list(offset = 0.75, color = "#C75C002F"),
              list(offset = 1, color = "#C75C0000")
            )
          ),
          opacity = 0.7
        )
      ) |>
      echarts_ts_formatter()
  })

  output$ts_MeanRelativeHumidity <- echarts4r::renderEcharts4r({
    if (isFALSE(input$user_ts_type)) {
      ts_data <- province_data()
    } else {
      shiny::validate(
        shiny::need(ts_coords_data$result(), "No time series data yet, press the button")
      )
      ts_data <- ts_coords_data$result() |>
        purrr::list_rbind()
    }

    ts_data |>
      dplyr::arrange(dates) |>
      echarts4r::e_charts(dates) |>
      echarts4r::e_line(
        MeanRelativeHumidity, symbol = "none",
        name = translate_app("MeanRelativeHumidity", lang()),
        lineStyle = list(color = "#00abfa"),
        itemStyle = list(color = "#00abfa"),
        areaStyle = list(
          color = list(
            type = "linear", x = 0, y = 0, x2 = 0, y2 = 1,
            colorStops = list(
              list(offset = 0, color = "#00abfa"),
              list(offset = 0.25, color = "#00abfa8F"),
              list(offset = 0.5, color = "#00abfa4F"),
              list(offset = 0.75, color = "#00abfa2F"),
              list(offset = 1, color = "#00abfa00")
            )
          ),
          opacity = 0.7
        )
      ) |>
      echarts_ts_formatter()
  })
  output$ts_MinRelativeHumidity <- echarts4r::renderEcharts4r({
    if (isFALSE(input$user_ts_type)) {
      ts_data <- province_data()
    } else {
      shiny::validate(
        shiny::need(ts_coords_data$result(), "No time series data yet, press the button")
      )
      ts_data <- ts_coords_data$result() |>
        purrr::list_rbind()
    }

    ts_data |>
      dplyr::arrange(dates) |>
      echarts4r::e_charts(dates) |>
      echarts4r::e_line(
        MinRelativeHumidity, symbol = "none",
        name = translate_app("MinRelativeHumidity", lang()),
        lineStyle = list(color = "#00abfa"),
        itemStyle = list(color = "#00abfa"),
        areaStyle = list(
          color = list(
            type = "linear", x = 0, y = 0, x2 = 0, y2 = 1,
            colorStops = list(
              list(offset = 0, color = "#00abfa"),
              list(offset = 0.25, color = "#00abfa8F"),
              list(offset = 0.5, color = "#00abfa4F"),
              list(offset = 0.75, color = "#00abfa2F"),
              list(offset = 1, color = "#00abfa00")
            )
          ),
          opacity = 0.7
        )
      ) |>
      echarts_ts_formatter()
  })
  output$ts_MaxRelativeHumidity <- echarts4r::renderEcharts4r({
    if (isFALSE(input$user_ts_type)) {
      ts_data <- province_data()
    } else {
      shiny::validate(
        shiny::need(ts_coords_data$result(), "No time series data yet, press the button")
      )
      ts_data <- ts_coords_data$result() |>
        purrr::list_rbind()
    }

    ts_data |>
      dplyr::arrange(dates) |>
      echarts4r::e_charts(dates) |>
      echarts4r::e_line(
        MaxRelativeHumidity, symbol = "none",
        name = translate_app("MaxRelativeHumidity", lang()),
        lineStyle = list(color = "#00abfa"),
        itemStyle = list(color = "#00abfa"),
        areaStyle = list(
          color = list(
            type = "linear", x = 0, y = 0, x2 = 0, y2 = 1,
            colorStops = list(
              list(offset = 0, color = "#00abfa"),
              list(offset = 0.25, color = "#00abfa8F"),
              list(offset = 0.5, color = "#00abfa4F"),
              list(offset = 0.75, color = "#00abfa2F"),
              list(offset = 1, color = "#00abfa00")
            )
          ),
          opacity = 0.7
        )
      ) |>
      echarts_ts_formatter()
  })

  output$ts_Radiation <- echarts4r::renderEcharts4r({
    if (isFALSE(input$user_ts_type)) {
      ts_data <- province_data()
    } else {
      shiny::validate(
        shiny::need(ts_coords_data$result(), "No time series data yet, press the button")
      )
      ts_data <- ts_coords_data$result() |>
        purrr::list_rbind()
    }

    ts_data |>
      dplyr::arrange(dates) |>
      echarts4r::e_charts(dates) |>
      echarts4r::e_line(
        Radiation, symbol = "none",
        name = translate_app("Radiation", lang()),
        lineStyle = list(color = "#ff9100"),
        itemStyle = list(color = "#ff9100"),
        areaStyle = list(
          color = list(
            type = "linear", x = 0, y = 0, x2 = 0, y2 = 1,
            colorStops = list(
              list(offset = 0, color = "#ff9100"),
              list(offset = 0.25, color = "#ff91008F"),
              list(offset = 0.5, color = "#ff91004F"),
              list(offset = 0.75, color = "#ff91002F"),
              list(offset = 1, color = "#ff910000")
            )
          ),
          opacity = 0.7
        )
      ) |>
      echarts_ts_formatter()
  })

  output$ts_PET <- echarts4r::renderEcharts4r({
    if (isFALSE(input$user_ts_type)) {
      ts_data <- province_data()
    } else {
      shiny::validate(
        shiny::need(ts_coords_data$result(), "No time series data yet, press the button")
      )
      ts_data <- ts_coords_data$result() |>
        purrr::list_rbind()
    }

    ts_data |>
      dplyr::arrange(dates) |>
      echarts4r::e_charts(dates) |>
      echarts4r::e_line(
        PET, symbol = "none",
        name = translate_app("PET", lang()),
        lineStyle = list(color = "#94C96E"),
        itemStyle = list(color = "#94C96E"),
        areaStyle = list(
          color = list(
            type = "linear", x = 0, y = 0, x2 = 0, y2 = 1,
            colorStops = list(
              list(offset = 0, color = "#94C96E"),
              list(offset = 0.25, color = "#94C96E8F"),
              list(offset = 0.5, color = "#94C96E4F"),
              list(offset = 0.75, color = "#94C96E2F"),
              list(offset = 1, color = "#94C96E00")
            )
          ),
          opacity = 0.7
        )
      ) |>
      echarts_ts_formatter()
  })

  output$ts_WindSpeed <- echarts4r::renderEcharts4r({
    if (isFALSE(input$user_ts_type)) {
      ts_data <- province_data()
    } else {
      shiny::validate(
        shiny::need(ts_coords_data$result(), "No time series data yet, press the button")
      )
      ts_data <- ts_coords_data$result() |>
        purrr::list_rbind()
    }

    ts_data |>
      dplyr::arrange(dates) |>
      echarts4r::e_charts(dates) |>
      echarts4r::e_line(
        WindSpeed, symbol = "none",
        name = translate_app("WindSpeed", lang()),
        lineStyle = list(color = "#94C96E"),
        itemStyle = list(color = "#94C96E"),
        areaStyle = list(
          color = list(
            type = "linear", x = 0, y = 0, x2 = 0, y2 = 1,
            colorStops = list(
              list(offset = 0, color = "#94C96E"),
              list(offset = 0.25, color = "#94C96E8F"),
              list(offset = 0.5, color = "#94C96E4F"),
              list(offset = 0.75, color = "#94C96E2F"),
              list(offset = 1, color = "#94C96E00")
            )
          ),
          opacity = 0.7
        )
      ) |>
      echarts_ts_formatter()
  })

  # download button logic
  output$download_ts_button <- shiny::downloadHandler(
    filename = glue::glue(
      "meteoland_timeseries_{format(Sys.time(), '%Y%m%d%H%M%S')}.csv"
    ),
    content = function(file) {
      if (isFALSE(input$user_ts_type)) {
        shiny::validate(
          shiny::need(province_data(), "no provinces data yet")
        )
        province_data() |>
          write.csv(file)
      } else {
        shiny::validate(
          shiny::need(ts_coords_data$result(), "No time series data yet, press the button")
        )
        ts_coords_data$result() |>
          purrr::list_rbind() |>
          write.csv(file)
      }
    }
  )
}
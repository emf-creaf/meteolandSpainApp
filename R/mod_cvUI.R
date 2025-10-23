#' @title mod_cvUI and mod_cv
#'
#' @description A shiny module to create and populate the cross validations
#'   explorer.
#'
#' @param id shiny id
#'
#' @export
mod_cvUI <- function(id) {
  # ns
  ns <- shiny::NS(id)
  shiny::tagList(
    bslib::layout_sidebar(
      shiny::uiOutput(ns("mod_cv_container")),
      sidebar = bslib::sidebar(
        shiny::uiOutput(ns('inputs_cv')),
        class = "inputs_cv",
        open = list(desktop = "open", mobile = "always-above")
      )
    )
  )
}

#' mod_cv server function
#' @param input internal
#' @param output internal
#' @param session internal
#' @param arrow_sink bucket s3 filesystem
#' @param lang lang selected
#'
#' @export
#'
#' @rdname mod_cvUI
mod_cv <- function(input, output, session, arrow_sink, lang) {
  # cv inputs
  output$inputs_cv <- shiny::renderUI({
    # precalculated choices
    cv_date_choices <- seq(Sys.Date() - 370, Sys.Date() - 5, by = "day") |>
      as.Date(format = '%j', origin = as.Date('1970-01-01')) |>
      as.character()
    cv_var_choices <- c(
      "MinTemperature", "MaxTemperature", "RangeTemperature",
      "RelativeHumidity", "Radiation",
      "TotalPrecipitation", "StationsPrecipitation"
    ) |>
      purrr::set_names(translate_app(c(
        "MinTemperature", "MaxTemperature", "RangeTemperature",
        "RelativeHumidity", "Radiation",
        "TotalPrecipitation", "StationsPrecipitation"
      ), lang()))

    shiny::tagList(
      shiny::h4(translate_app("map_controls", lang())),
      shiny::br(),
      shiny::fluidRow(
        shiny::column(
          width = 12,
          # cv_var
          shinyWidgets::pickerInput(
            ns("cv_var"), label = translate_app("cv_var", lang()),
            choices = cv_var_choices,
            selected = cv_var_choices[1],
            multiple = FALSE,
            options = shinyWidgets::pickerOptions(
              actionsBox = FALSE,
              tickIcon = "glyphicon-ok-sign"
            )
          ),
          shiny::br(),
          # cv date
          shinyWidgets::airDatepickerInput(
            ns("cv_date"), label = translate_app("cv_date", lang()),
            value = cv_date_choices[length(cv_date_choices)],
            multiple = FALSE, range = FALSE,
            minDate = cv_date_choices[1],
            maxDate = cv_date_choices[length(cv_date_choices)],
            firstDay = 1
          )
        )
      )
    ) # end of tagList
  }) # end of cv inputs ui
  
  # output rendering echarts for cv
  output$mod_cv_container <- shiny::renderUI({
    # get the ns
    ns <- session$ns
    shiny::tagList(
      shiny::fluidRow(
        shiny::column(
          width = 6,
          echarts4r::echarts4rOutput(ns("output_cv_maps_1")),
        ),
        shiny::column(
          width = 6,
          echarts4r::echarts4rOutput(ns("output_cv_maps_2")),
        )
      ),
      shiny::fluidRow(
        shiny::column(
          width = 6,
          echarts4r::echarts4rOutput(ns("output_cv_maps_3"))
        ),
        shiny::column(
          width = 6,
          echarts4r::echarts4rOutput(ns("output_cv_maps_4"))
        )
      )
    )
  })

  # reactives
  # data reactive
  cv_data <- shiny::reactive({
    # inputs needed
    shiny::validate(
      shiny::need(input$cv_var, "no cv statistic selected yet"),
      shiny::need(input$cv_date, "no cv date selected yet")
    )
    # arrow data
    arrow::open_dataset(
      arrow_sink,
      factory_options = list(
        selector_ignore_prefixes = c(
          "daily_interpolated_meteo_bitmaps",
          "daily_interpolated_meteo_timeseries"
        )
      )
    ) |>
      dplyr::filter(
        variable == input$cv_var,
        dates == as.Date(input$cv_date)
      ) |>
      dplyr::as_tibble()
  }) |>
    # bind to cache and to events (same inputs, date and stat)
    shiny::bindCache(input$cv_var, input$cv_date) |>
    shiny::bindEvent(input$cv_var, input$cv_date)

  # echarts output with the cross validations maps
  # when a precipitation var is selected, only two stats are calculated, deal
  # accordingly with this on plots 2 and 3
  output$output_cv_maps_1 <- echarts4r::renderEcharts4r({
    # validate we have data
    shiny::validate(
      shiny::need(
        validate_rows_with_alert(cv_data(), lang),
        "no data for cv selected"
      )
    )
    # process cv
    cv_data() |>
      echarts_cv_builder("bias", lang)
  })
  output$output_cv_maps_2 <- echarts4r::renderEcharts4r({
    # validate we have data
    shiny::validate(
      shiny::need(
        validate_rows_with_alert(cv_data(), lang),
        "no data for cv selected"
      )
    )
    # process cv
    stat2plot <- "mae"
    if (input$cv_var %in% c("TotalPrecipitation", "StationsPrecipitation")) {
      stat2plot <- "relative_bias"
    }
    cv_data() |>
      echarts_cv_builder(stat2plot, lang)
  })
  output$output_cv_maps_3 <- echarts4r::renderEcharts4r({
    # validate we have data
    shiny::validate(
      shiny::need(
        validate_rows_with_alert(cv_data(), lang),
        "no data for cv selected"
      )
    )
    # process cv
    stat2plot <- "r2"
    if (input$cv_var %in% c("TotalPrecipitation", "StationsPrecipitation")) {
      stat2plot <- "n_stations"
    }
    cv_data() |>
      echarts_cv_builder(stat2plot, lang)
  })
  output$output_cv_maps_4 <- echarts4r::renderEcharts4r({
    # validate we have data
    shiny::validate(
      shiny::need(
        validate_rows_with_alert(cv_data(), lang),
        "no data for cv selected"
      )
    )
    # process cv
    stat2plot <- "n_stations"
    if (input$cv_var %in% c("TotalPrecipitation", "StationsPrecipitation")) {
      return()
    }
    cv_data() |>
      echarts_cv_builder(stat2plot, lang)
  })
}
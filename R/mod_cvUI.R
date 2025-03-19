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

  # UI ####
  shiny::tagList(shiny::uiOutput(ns("mod_cv_container")))
}

#' mod_cv server function
#' @param input internal
#' @param output internal
#' @param session internal
#' @param lang lang selected
#'
#' @export
#'
#' @rdname mod_cvUI
mod_cv <- function(input, output, session, lang) {
  # render ui for cv inputs and output placeholders
  output$mod_cv_container <- shiny::renderUI({
    # get the ns
    ns <- session$ns

    # options
    cv_date_choices <- seq(Sys.Date() - 370, Sys.Date() - 6, by = "day") |>
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
    # sidebar layout
    shiny::sidebarLayout(
      position = "left", fluid = TRUE,
      sidebarPanel = shiny::sidebarPanel(
        width = 4,
        shiny::fluidRow(
          shiny::column(
            width = 12,
            # cv date
            shinyWidgets::airDatepickerInput(
              ns("cv_date"), label = translate_app("cv_date", lang()),
              value = cv_date_choices[length(cv_date_choices)],
              multiple = FALSE, range = FALSE,
              minDate = cv_date_choices[1],
              maxDate = cv_date_choices[length(cv_date_choices)],
              firstDay = 1
            ),
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
            )
          )
        )
      ), # END of sidebarPanel
      mainPanel = shiny::mainPanel(
        width = 8,
        shiny::fluidRow(
          shiny::column(
            width = 6,
            echarts4r::echarts4rOutput(ns("output_cv_maps_1")),
            echarts4r::echarts4rOutput(ns("output_cv_maps_3"))
          ),
          shiny::column(
            width = 6,
            echarts4r::echarts4rOutput(ns("output_cv_maps_2"))
          )
        )
      ) # END of mainPanel
    )
  }) # END of renderUI

  # reactives
  # data reactive
  cv_data <- shiny::reactive({
    # inputs needed
    shiny::validate(
      shiny::need(input$cv_var, "no cv statistic selected yet"),
      shiny::need(input$cv_date, "no cv date selected yet")
    )
    # open, filter and return the stat-date data
    arrow::open_dataset(Sys.getenv("PARQUET_CVS")) |>
      dplyr::filter(
        variable == input$cv_var,
        dates == as.Date(input$cv_date)
      ) |>
      dplyr::as_tibble()
  }) |>
    # bind to cache and to events (same inputs, date and stat)
    shiny::bindCache(input$cv_var, input$cv_date) |>
    shiny::bindEvent(input$cv_var, input$cv_date)
  
  # plots reactive
  cv_plots <- shiny::reactive({
    # plots for each stat
    cv_plots <- cv_data() |>
      dplyr::group_by(stat) |>
      dplyr::group_map(
        .f = \(stat_data, stat_key) {
          stat_data |>
            echarts4r::e_charts(interpolator_id) |>
            echarts4r::e_map_register(
              "interpolator_bboxes", interpolators_geojson
            ) |>
            echarts4r::e_map(
              value, map = "interpolator_bboxes", nameProperty = "i_step"
            ) |>
            echarts4r::e_visual_map(value) |>
            echarts4r::e_title(translate_app(stat_key[["stat"]], lang()))
        }
      )
    # precip vars have only 2 stats, create an empty plot to serve in that
    # output
    if (length(cv_plots) < 3) {
      cv_plots[[3]] <- echarts4r::e_charts()
    }

    return(cv_plots)
  }) |>
    shiny::bindEvent(cv_data())

  # echarts output with the cross validations maps
  output$output_cv_maps_1 <- echarts4r::renderEcharts4r({
    cv_plots()[[1]]
  })
  output$output_cv_maps_2 <- echarts4r::renderEcharts4r({
    cv_plots()[[2]]
  })
  output$output_cv_maps_3 <- echarts4r::renderEcharts4r({
    cv_plots()[[3]]
  })
  # output$output_cv_maps <- echarts4r::renderEcharts4r({
  #   browser()
  #   # plots for each stat
  #   cv_plots <- cv_data() |>
  #     dplyr::group_by(stat) |>
  #     dplyr::group_map(
  #       .f = \(stat_data, stat_key) {
  #         stat_data |>
  #           echarts4r::e_charts(interpolator_id) |>
  #           echarts4r::e_map_register(
  #             "interpolator_bboxes", interpolators_geojson
  #           ) |>
  #           echarts4r::e_map(
  #             value, map = "interpolator_bboxes", nameProperty = "i_step"
  #           ) |>
  #           echarts4r::e_visual_map(value) |>
  #           echarts4r::e_title(translate_app(stat_key[["stat"]], lang()))
  #       }
  #     )
  #   if (length(cv_plots) < 3) {
  #     cv_plots[[3]] <- echarts4r::e_charts()
  #   }
  #   echarts4r::e_arrange(
  #     cv_plots[[1]], cv_plots[[2]], cv_plots[[3]],
  #     cols = 2, rows = 2
  #   )
  # })
}
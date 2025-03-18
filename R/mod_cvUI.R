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
  output$mod_cv_container <- shiny::renderUI({
    # get the ns
    ns <- session$ns

    # options
    cv_date_choices <- seq(Sys.Date() - 370, Sys.Date() - 6, by = "day") |>
      as.Date(format = '%j', origin = as.Date('1970-01-01')) |>
      as.character()
    cv_stat_choices <- c("bias", "relative_bias", "mae", "r2") |>
      purrr::set_names(
        translate_app(c("bias", "relative_bias", "mae", "r2"), lang())
      )
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
            # cv_stat
            shinyWidgets::pickerInput(
              ns("cv_stat"), label = translate_app("cv_stat", lang()),
              choices = cv_stat_choices,
              selected = cv_stat_choices[1],
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
            width = 12,
            echarts4r::echarts4rOutput(ns("output_cv_maps"))
          )
        )
      ) # END of mainPanel
    )
  }) # END of renderUI

  output$output_cv_maps <- echarts4r::renderEcharts4r({
    
  })
}
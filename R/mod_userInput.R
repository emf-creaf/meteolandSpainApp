#' @title mod_userInput and mod_user
#'
#' @description A shiny module to create and populate the user inputs
#' (variable, dates...)
#'
#' @param id shiny id
#'
#' @export
mod_userInput <- function(id) {
  # ns
  ns <- shiny::NS(id)

  # UI ####
  shiny::tagList(
    shiny::br(),
    shiny::uiOutput(
      ns('mod_user_container')
    )
  )
}

#' mod_user server function
#' 
#' @param input internal
#' @param output internal
#' @param session internal
#' @param lang lang reactive
#'
#' @export
mod_user <- function(
  input, output, session,
  lang
) {
  # renderUI for creating the inputs server-side (mainly due to translations)
  output$mod_user_container <- shiny::renderUI({
    # get the ns
    ns <- session$ns

    # precalculated choices
    user_var_choices <- c(
      "MeanTemperature", "MinTemperature", "MaxTemperature", "ThermalAmplitude",
      "MeanRelativeHumidity", "MinRelativeHumidity", "MaxRelativeHumidity",
      "Precipitation", "Radiation", "WindSpeed", "PET"
    ) |>
      purrr::set_names(translate_app(c(
        "MeanTemperature", "MinTemperature", "MaxTemperature", "ThermalAmplitude",
        "MeanRelativeHumidity", "MinRelativeHumidity", "MaxRelativeHumidity",
        "Precipitation", "Radiation", "WindSpeed", "PET"
      ), lang()))

    user_date_choices <- seq(Sys.Date() - 370, Sys.Date() - 6, by = "day") |>
      as.Date(format = '%j', origin = as.Date('1970-01-01')) |>
      as.character()

    # inputs tagList
    shiny::tagList(
      # first row of inputs, variable and dates
      shiny::fluidRow(
        # user_var
        shiny::column(
          width = 6,
          shinyWidgets::pickerInput(
            ns("user_var"), label = translate_app("user_var", lang()),
            choices = user_var_choices,
            selected = user_var_choices[1],
            multiple = FALSE,
            options = shinyWidgets::pickerOptions(
              actionsBox = FALSE,
              tickIcon = "glyphicon-ok-sign"
            )
          )
        ),
        # user_date
        shiny::column(
          width = 6,
          shinyWidgets::airDatepickerInput(
            ns("user_date"), label = translate_app("user_date", lang()),
            value = user_date_choices[length(user_date_choices)],
            multiple = FALSE, range = FALSE,
            minDate = user_date_choices[1],
            maxDate = user_date_choices[length(user_date_choices)],
            firstDay = 1
          )
        )
      ), # END of first row of inputs
      # second row of inputs, time series
      shiny::h4(translate_app("user_ts_title", lang())),
      shiny::fluidRow(
        # user_var
        shiny::column(
          width = 6,
          shinyWidgets::numericInputIcon(
            "user_longitude", translate_app("user_longitude", lang()),
            value = -5.641,
            min = -9.500, max = 4, step = 0.001,
            icon = shiny::icon("x"),
            help_text = translate_app("user_longitude_help", lang())
          ),
          shinyWidgets::numericInputIcon(
            "user_latitude", translate_app("user_latitude", lang()),
            value = 42.662,
            min = 35.500, max = 44, step = 0.001,
            icon = shiny::icon("y"),
            help_text = translate_app("user_latitude_help", lang())
          ),
          shinyWidgets::actionBttn(
            "user_ts_update", translate_app("user_ts_update", lang()),
            icon = shiny::icon("rotate"),
            style = "simple", color = "royal", size = "sm"
          )
        ),
        # user_date
        shiny::column(
          width = 6,
          shiny::p("TODO - Placeholder for the info about map resolution and waiting time")
        )
      ) # END of second row of inputs
    ) # END of inputs tagList
  }) # END of renderUI

  # Collect reactives to pass to the main app or other modules
  user_reactives <- shiny::reactiveValues()
  shiny::observe({
    user_reactives$user_var <- input$user_var
    user_reactives$user_date <- input$user_date
    user_reactives$user_longitude <- input$user_longitude
    user_reactives$user_latitude <- input$user_latitude
    user_reactives$user_ts_update <- input$user_ts_update
  })
  return(user_reactives)
}
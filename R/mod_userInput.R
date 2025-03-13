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
          width = 5, offset = 1,
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
          width = 5, offset = 1,
          shinyWidgets::airDatepickerInput(
            ns("user_date"), label = translate_app("user_date", lang()),
            value = user_date_choices[length(user_date_choices)],
            multiple = FALSE, range = FALSE,
            minDate = user_date_choices[1],
            maxDate = user_date_choices[length(user_date_choices)],
            firstDay = 1
          )
        )
      ) # END of first row of inputs
    ) # END of inputs tagList
  }) # END of renderUI

  # Collect reactives to pass to the main app or other modules
  user_reactives <- shiny::reactiveValues()
  shiny::observe({
    user_reactives$user_var <- input$user_var
    user_reactives$user_date <- input$user_date
  })
  return(user_reactives)
}
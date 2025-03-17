#' @title mod_downloadOutput and mod_download
#'
#' @description Shiny module to generate the contents of the download tab
#'
#' @param id shiny id
#'
#' @export
mod_downloadOutput <- function(id) {
  # ns
  ns <- shiny::NS(id)
  shiny::tagList(
    shiny::uiOutput(
      ns('mod_download_container')
    )
  )
}

#' mod_download server function
#' @param input internal
#' @param output internal
#' @param session internal
#' @param user_inputs reactiveValues containing the user selected inputs
#' @param lang lang selected
#'
#' @export
#'
#' @rdname mod_downloadOutput
mod_download <- function(
  input, output, session,
  user_inputs,
  lang
) {
  output$mod_download_container <- shiny::renderUI({
    # get the ns
    ns <- session$ns
    # output tagList
    shiny::tagList(
      shiny::fluidRow(
        # maps download (gpkg public repository link)
        shiny::column(
          width = 4,
          shiny::h4(translate_app("download_maps_title", lang())),
          shiny::p(translate_app("download_maps_text", lang())),
          shiny::actionButton(
            "download_maps_link", translate_app("download_maps_link", lang()),
            icon = shiny::icon("up-right-from-square"),
            onclick = "window.open('https://data-emf.creaf.cat/public/gpkg/daily_interpolated_meteo/', '_blank')"
          )
        ), # END of maps download column
        # timeseries download (csv)
        shiny::column(
          width = 4,
          shiny::h4(translate_app("download_ts_title", lang())),
          shiny::p(translate_app("download_ts_text", lang())),
          shiny::actionButton(
            "download_ts_button", translate_app("download_ts_button", lang()),
            icon = shiny::icon("download")
          )
        )
      )
    ) # END of ouput tagList
  }) # END of renderUI
}
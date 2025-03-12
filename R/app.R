#' App launcher
#'
#' Function to launch the app (in console, in container...)
#'
#' This function builds the UI (calling any modules necessary), the server
#' (calling any modules necessary) and return a `ShinyApp()` object.
#'
#' @export
meteoland_spain_app <- function() {
  #### duckdb connection ####
  duckdb_proxy <- duckdb::dbConnect(duckdb::duckdb())
  withr::defer(duckdb::dbDisconnect(duckdb_proxy))
  install_httpfs_statement <- glue::glue_sql(
    .con = duckdb_proxy,
    "INSTALL httpfs;"
  )
  httpfs_statement <- glue::glue_sql(
    .con = duckdb_proxy,
    "LOAD httpfs;"
  )
  DBI::dbExecute(duckdb_proxy, install_httpfs_statement)
  DBI::dbExecute(duckdb_proxy, httpfs_statement)

  #### Language input ####
  shiny::addResourcePath(
    "images", system.file("resources", "images", package = "meteolandApp")
  )
  lang_choices <- c("cat", "spa", "eng")
  lang_flags <- c(
    glue::glue(
      "<img class='flag-image' src='images/cat.png'",
      " width=20px><div class='flag-lang'>%s</div></img>"
    ),
    glue::glue(
      "<img class='flag-image' src='images/spa.png'",
      " width=20px><div class='flag-lang'>%s</div></img>"
    ),
    glue::glue(
      "<img class='flag-image' src='images/eng.png'",
      " width=20px><div class='flag-lang'>%s</div></img>"
    )
  )

  #### JS scripts needed ####

  #### UI ####
  ui <- shiny::tagList(
    # css
    shiny::tags$head(
      # js script,

      # corporative image custom css
      shiny::includeCSS(
        system.file("apps_css", "corp_image.css", package = "lfcdata")
      ),
      # meteoland app custom css
      shiny::includeCSS(
        system.file("apps_css", "meteolandapp.css", package = "lfcdata")
      )
    ),

    navbarPageWithInputs(
      # opts
      title = "Meteoland App",
      id = "nav",
      collapsible = TRUE,

      # Lang selector (input for navbaraPageWithInputs)
      # inputs = shinyWidgets::pickerInput(
      #   "lang", NULL,
      #   choices = lang_choices,
      #   selected = "eng",
      #   width = "100px",
      #   choicesOpt = list(
      #     content = c(
      #       sprintf(lang_flags[1], lang_choices[1]),
      #       sprintf(lang_flags[2], lang_choices[2]),
      #       sprintf(lang_flags[3], lang_choices[3])
      #     )
      #   )
      # ),
      inputs = shinyWidgets::slimSelectInput(
        "lang", NULL,
        choices = shinyWidgets::prepare_slim_choices(
          .data = data.frame(lang_choices = lang_choices, lang_label = lang_flags),
          label = NULL, value = lang_choices,
          html = lang_label
        )
      )
    ) # END of navbarPage
  ) # END of UI tagList
}
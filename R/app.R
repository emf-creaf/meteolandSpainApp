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
  install_httpfs_statement <- glue_sql(
    .con = duckdb_proxy,
    "INSTALL httpfs;"
  )
  httpfs_statement <- glue_sql(
    .con = duckdb_proxy,
    "LOAD httpfs;"
  )
  dbExecute(duckdb_proxy, install_httpfs_statement)
  dbExecute(duckdb_proxy, httpfs_statement)

  ### Language input ###########################################################
  shiny::addResourcePath(
    'images', system.file('resources', 'images', package = 'meteolandApp')
  )
  lang_choices <- c('cat', 'spa', 'eng')
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
}
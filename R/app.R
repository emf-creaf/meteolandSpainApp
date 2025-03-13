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
  # withr::defer(duckdb::dbDisconnect(duckdb_proxy))
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

  #### Pre-loaded data ####
  # bitmaps
  bitmaps_query <- glue::glue_sql(
    .con = duckdb_proxy,
    "CREATE VIEW bitmaps AS
      SELECT * FROM
        read_parquet('https://data-emf.creaf.cat/public/parquet/bitmaps/daily_interpolated_meteo_bitmaps.parquet');"
  )
  DBI::dbExecute(duckdb_proxy, bitmaps_query)

  #### Language input ####
  shiny::addResourcePath(
    "images", system.file("resources", "images", package = "meteolandSpainApp")
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

      # initializations
      waiter::use_waiter(),
      waiter::use_hostess(),
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
      inputs = shinyWidgets::pickerInput(
        "lang", NULL,
        choices = lang_choices,
        selected = "eng",
        width = "100px",
        choicesOpt = list(
          content = c(
            sprintf(lang_flags[1], lang_choices[1]),
            sprintf(lang_flags[2], lang_choices[2]),
            sprintf(lang_flags[3], lang_choices[3])
          )
        )
      ),

      # footer
      footer = shiny::tags$footer(
        shiny::fluidRow(
          shiny::column(
            width = 12, align = "right",
            shiny::HTML(glue::glue(
              '<img src="images/emf_white_logo.svg" width="120px" class="d-inline-block" alt="" loading="lazy">
              <img src="images/creaf_white_logo.svg" width="135px" class="d-inline-block" alt="" loading="lazy">
              <span>({lubridate::year(Sys.Date())})</span>'
            ))
          )
        )
      ),

      # Main (Explore) tab
      shiny::tabPanel(
        title = mod_tab_translateOutput("main_tab_translation"),
        icon = shiny::icon("eye"),
        shiny::sidebarLayout(
          position = "right", fluid = TRUE,
          sidebarPanel = shiny::sidebarPanel(
            mod_userInput("user_input")
          ), # END of sidebarPanel
          mainPanel = shiny::mainPanel(
            mod_mapOutput("map_output")
          ) # END of mainPanel
        ) # END of sidebarLayout
      ) # END of main (Explore) tab
    ) # END of navbarPage
  ) # END of UI tagList

  #### SERVER ####
  server <- function(input, output, session) {
    # lang reactive
    lang <- shiny::reactive({
      input$lang
    })

    # mapbox token
    mapdeck::set_token(Sys.getenv("MAPBOX_TOKEN"))

    # modules
    user_reactives <- shiny::callModule(
      mod_user, 'user_input', lang
    )
    map_reactives <- shiny::callModule(
      mod_map, 'map_output', user_reactives, duckdb_proxy, lang
    )

    # tab translations
    shiny::callModule(
      mod_tab_translate, "main_tab_translation",
      "main_tab_translation", lang
    )
  } # END of server function

  #### Wrap the App ####
  app_wrapped <- shiny::shinyApp(
    ui = ui, server = server
  )
  # shiny::runApp(meteoland_app)
  return(app_wrapped)
}
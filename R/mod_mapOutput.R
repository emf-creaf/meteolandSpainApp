#' @title mod_mapOutput and mod_map
#'
#' @description Shiny module to generate the map with mabox and mapdeck
#'
#' @param id shiny id
#'
#' @export
mod_mapOutput <- function(id) {
  # ns
  ns <- shiny::NS(id)
  shiny::tagList(
    mapdeck::mapdeckOutput(ns("output_map"), height = 600)
  )
}

#' mod_map server function
#' @param input internal
#' @param output internal
#' @param session internal
#' @param user_inputs reactiveValues containing the user selected inputs
#' @param duckdb_proxy duckdb connection
#' @param lang lang selected
#'
#' @export
#'
#' @rdname mod_mapOutput
mod_map <- function(
  input, output, session,
  user_inputs, duckdb_proxy,
  lang
) {
  # get the ns
  ns <- session$ns
  # output base map, later we update it
  output$output_map <- mapdeck::renderMapdeck({
    mapdeck::mapdeck(
      ## debug
      # show_view_state = TRUE,
      # style = mapdeck::mapdeck_style('dark'),
      # style = "mapbox://styles/mapbox/dark-v10",
      style = mapdeck::mapdeck_style("dark"),
      location = c(-3.622, 40.234), zoom = 5.1, pitch = 0, max_pitch = 60,
      # debug info (TRUE)
      show_view_state = FALSE
    )
  })

  # Updating the map based on inputs
  shiny::observe({

    # only run when inputs are populated
    shiny::validate(
      shiny::need(user_inputs$user_var, "Missing meteo variable"),
      shiny::need(user_inputs$user_date, "Missing date")
    )

    # needed inputs
    var_sel <- user_inputs$user_var
    date_sel <- user_inputs$user_date |>
      as.character() |>
      stringr::str_remove_all("-")

    # query
    bitmap_sel_query <- glue::glue_sql(
      .con = duckdb_proxy,
      "SELECT * FROM bitmaps
      WHERE var = {var_sel} AND date = {date_sel};"
    )

    # browser()
    # get the selected bitmap info an base64 text
    bitmap_sel <- DBI::dbGetQuery(duckdb_proxy, bitmap_sel_query)

    # create the custom legend to show with the bitmap
    legend_js <- mapdeck::legend_element(
      variables = rev(round(seq(
        bitmap_sel[["min_value"]],
        bitmap_sel[["max_value"]],
        length.out = 5
      ), 0)),
      colours = scales::col_numeric(
        hcl.colors(10, "ag_GrnYl", alpha = 0.8),
        c(bitmap_sel[["min_value"]], bitmap_sel[["max_value"]]),
        na.color = "#FFFFFF00", reverse = FALSE, alpha = TRUE
      )(seq(
        bitmap_sel[["min_value"]],
        bitmap_sel[["max_value"]],
        length.out = 5
      )),
      colour_type = "fill", variable_type = "gradient",
      title = glue::glue(
        "{translate_app(var_sel, lang())} - {user_inputs$user_date}"
      )
    ) |>
      mapdeck::mapdeck_legend()

    # update the map
    mapdeck::mapdeck_update(map_id = ns("output_map")) |>
      mapdeck::add_bitmap(
        image = bitmap_sel$base64_string, layer_id = "bitmap_sel",
        bounds = c(
          bitmap_sel$left_ext, bitmap_sel$down_ext,
          bitmap_sel$right_ext, bitmap_sel$up_ext
        ),
        update_view = FALSE, focus_layer = FALSE,
        transparent_colour = "#00000000"
      ) |>
      mapdeck::add_legend(legend = legend_js, layer_id = "custom_legend")
  })
}
# Call this function with an input (such as `textInput("text", NULL, "Search")`)
# if you want to add an input to the navbar (from dean attali,
# https://github.com/daattali/advanced-shiny)
navbarPageWithInputs <- function(..., inputs) {
  navbar <- shiny::navbarPage(...)
  form <- shiny::tags$form(class = "navbar-form", inputs)

  navbar[[4]][[1]]$children[[1]][[1]]$children[[1]][[3]][[2]] <-
    htmltools::tagAppendChild(navbar[[4]][[1]]$children[[1]][[1]]$children[[1]][[3]][[2]], form)

  return(navbar)
}
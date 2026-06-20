modualFormUI <- function(id) {
  ns <- shiny::NS(id)
  shiny::actionButton(ns("open"), "Open Form", class = "btn-primary")
}

modualFormServer <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns

    shiny::observeEvent(input$open, {
      shiny::showModal(shiny::modalDialog(
        title  = "New Entry",
        size   = "m",
        easyClose = TRUE,

        shiny::textInput(ns("name"),    "Name",    placeholder = "Full name"),
        shiny::textInput(ns("email"),   "Email",   placeholder = "email@example.com"),
        shiny::selectInput(
          ns("type"), "Type",
          choices = c("Inquiry", "Feedback", "Follow-up", "Other")
        ),
        shiny::textAreaInput(
          ns("notes"), "Notes",
          placeholder = "Enter any additional notes...",
          width = "100%", rows = 4
        ),

        footer = htmltools::tagList(
          shiny::modalButton("Cancel"),
          shiny::actionButton(ns("submit"), "Submit", class = "btn-primary")
        )
      ))
    })

    # Return submitted values as a reactive; NULL until first submission
    submitted <- shiny::eventReactive(input$submit, {
      list(
        name      = input$name,
        email     = input$email,
        type      = input$type,
        notes     = input$notes,
        timestamp = Sys.time()
      )
    })

    shiny::observeEvent(input$submit, {
      shiny::removeModal()
    })

    submitted  # return so callers can react to submissions
  })
}

# Standalone demo app
modualForm <- function() {
  ui <- bslib::page_fluid(
    theme = bslib::bs_theme(version = 5, preset = "shiny"),
    class = "p-4",
    modualFormUI("form"),
    shiny::uiOutput("submission_display")
  )

  server <- function(input, output, session) {
    result <- modualFormServer("form")

    output$submission_display <- shiny::renderUI({
      r <- result()
      shiny::req(r)
      bslib::card(
        class = "mt-3",
        bslib::card_header("Last Submission"),
        htmltools::tags$dl(
          class = "row mb-0",
          htmltools::tags$dt(class = "col-sm-2", "Name"),
          htmltools::tags$dd(class = "col-sm-10", r$name),
          htmltools::tags$dt(class = "col-sm-2", "Email"),
          htmltools::tags$dd(class = "col-sm-10", r$email),
          htmltools::tags$dt(class = "col-sm-2", "Type"),
          htmltools::tags$dd(class = "col-sm-10", r$type),
          htmltools::tags$dt(class = "col-sm-2", "Notes"),
          htmltools::tags$dd(class = "col-sm-10", r$notes),
          htmltools::tags$dt(class = "col-sm-2", "Time"),
          htmltools::tags$dd(class = "col-sm-10", format(r$timestamp, "%b %d, %Y %H:%M:%S"))
        )
      )
    })
  }

  shiny::shinyApp(ui, server)
}

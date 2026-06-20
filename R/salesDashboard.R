salesDashboard <- function() {
  source("data/sales_data.R")

  ui <- 
    # Have card fill the whole page
    bslib::page_fillable(
      # Use bootstrap 5
      theme = bslib::bs_theme(version = 5, preset = "shiny"),
      title = "Sales Dashboard",
      # Card with header and title and a dark mode toggle in the header
      bslib::card(
      bslib::card_header(
        # Justify content between the title, form, and dark mode toggle
        class = "d-flex justify-content-between align-items-center",
        "Customers \u2014 click a row to view sales",
        # Add div for form button and dark mode tile
        htmltools::div(
          class = "d-flex align-items-center gap-3",
          modualFormUI("form"),
          bslib::input_dark_mode()
        )
      ),
      # Table of customers
      reactable::reactableOutput("customers_table")
    ),
    # UI table of sales rendered when customer is clicked
    uiOutput("sales_card")
  )

  # Reactable theme that mirrors Bootstrap 5 CSS variables so it automatically
  # responds to bslib's dark mode toggle without any R-side reactivity.
  rt_theme <- reactable::reactableTheme(
    # BS 5 CSS
    color                 = "var(--bs-body-color)",
    backgroundColor       = "var(--bs-body-bg)",
    borderColor           = "var(--bs-border-color)",
    stripedColor          = "var(--bs-secondary-bg)",
    highlightColor        = "var(--bs-tertiary-bg)",
    rowSelectedStyle      = list(
      backgroundColor = "var(--bs-primary-bg-subtle)",
      color           = "var(--bs-emphasis-color)"
    ),
    searchInputStyle      = list(
      backgroundColor = "var(--bs-body-bg)",
      color           = "var(--bs-body-color)",
      borderColor     = "var(--bs-border-color)"
    ),
    headerStyle           = list(
      backgroundColor = "var(--bs-body-bg)",
      color           = "var(--bs-body-color)",
      borderColor     = "var(--bs-border-color)"
    )
  )

  server <- function(input, output, session) {

    output$customers_table <- reactable::renderReactable({
      reactable::reactable(
        customers[, c("id", "company", "first_name", "last_name", "industry", "hq_location")],
        selection  = "single",
        onClick    = "select",
        highlight  = TRUE,
        striped    = TRUE,
        searchable = TRUE,
        theme      = rt_theme,
        columns = list(
          id           = reactable::colDef(name = "ID", maxWidth = 60),
          company      = reactable::colDef(name = "Company"),
          first_name   = reactable::colDef(name = "First Name"),
          last_name    = reactable::colDef(name = "Last Name"),
          industry     = reactable::colDef(name = "Industry"),
          hq_location  = reactable::colDef(name = "HQ Location")
        )
      )
    })

    modualFormServer("form")

    selected_customer <- reactive({
      selected_id <- reactable::getReactableState("customers_table", "selected")
      if (is.null(selected_id)) return(NULL)
      customers[selected_id, ]
    })

    output$sales_card <- renderUI({
      cust <- selected_customer()
      if (is.null(cust)) return(NULL)

      bslib::card(
        bslib::card_header(
          paste0(cust$first_name, " ", cust$last_name,
          " \u2014 ", cust$company, " Sales History")
        ),
        reactable::reactableOutput("sales_table")
      )
    })

    output$sales_table <- reactable::renderReactable({
      cust <- selected_customer()
      req(cust)

      cust_sales <- sales_data[sales_data$customer_id == cust$id, ]
      cust_sales$revenue <- cust_sales$quantity * cust_sales$price

      reactable::reactable(
        cust_sales[, c("sale_date", "product", "quantity", "price", "revenue")],
        striped       = TRUE,
        searchable    = TRUE,
        defaultSorted = list(sale_date = "desc"),
        theme         = rt_theme,
        columns = list(
          sale_date = reactable::colDef(name = "Date", maxWidth = 120),
          product   = reactable::colDef(name = "Product"),
          quantity  = reactable::colDef(name = "Qty", maxWidth = 80),
          price     = reactable::colDef(name = "Unit Price", maxWidth = 120,
                        format = reactable::colFormat(prefix = "$", separators = TRUE, digits = 2)),
          revenue   = reactable::colDef(name = "Revenue", maxWidth = 120,
                        format = reactable::colFormat(prefix = "$", separators = TRUE, digits = 2))
        )
      )
    })
  }

  shiny::shinyApp(ui, server)
}

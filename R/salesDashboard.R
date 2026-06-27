salesDashboard <- function() {
  source("data/sales_data.R")

  # Join and prep data once for dashboard plots
  sales_full <- merge(
    sales_data,
    customers[, c("id", "company", "industry")],
    by.x = "customer_id", by.y = "id"
  )
  sales_full$revenue   <- sales_full$quantity * sales_full$price
  sales_full$sale_date <- as.Date(sales_full$sale_date)
  sales_full$month     <- as.Date(format(sales_full$sale_date, "%Y-%m-01"))

  # Reactable theme mirroring Bootstrap 5 CSS variables for automatic dark mode
  rt_theme <- reactable::reactableTheme(
    color            = "var(--bs-body-color)",
    backgroundColor  = "var(--bs-body-bg)",
    borderColor      = "var(--bs-border-color)",
    stripedColor     = "var(--bs-secondary-bg)",
    highlightColor   = "var(--bs-tertiary-bg)",
    rowSelectedStyle = list(
      backgroundColor = "var(--bs-primary-bg-subtle)",
      color           = "var(--bs-emphasis-color)"
    ),
    searchInputStyle = list(
      backgroundColor = "var(--bs-body-bg)",
      color           = "var(--bs-body-color)",
      borderColor     = "var(--bs-border-color)"
    ),
    headerStyle = list(
      backgroundColor = "var(--bs-body-bg)",
      color           = "var(--bs-body-color)",
      borderColor     = "var(--bs-border-color)"
    )
  )

  ui <- bslib::page_navbar(
    title    = "Sales Dashboard",
    theme    = bslib::bs_theme(version = 5, preset = "shiny"),
    fillable = FALSE,

    # ── Tab 1: Dashboard ──────────────────────────────────────────────────────
    bslib::nav_panel(
      "Dashboard",

      bslib::layout_column_wrap(
        width         = 1/2,
        fill          = FALSE,
        heights_equal = "row",

        bslib::card(
          full_screen = TRUE,
          bslib::card_header("Revenue by Industry"),
          shiny::plotOutput("plot_industry", height = "260px")
        ),
        bslib::card(
          full_screen = TRUE,
          bslib::card_header("Monthly Revenue"),
          shiny::plotOutput("plot_trend", height = "260px")
        ),
        bslib::card(
          full_screen = TRUE,
          bslib::card_header("Top 10 Customers by Revenue"),
          shiny::plotOutput("plot_top_customers", height = "260px")
        ),
        bslib::card(
          full_screen = TRUE,
          bslib::card_header("Revenue by Product"),
          shiny::plotOutput("plot_products", height = "260px")
        )
      ),

      bslib::card(
        bslib::card_header("Recent Sales"),
        reactable::reactableOutput("recent_sales_table")
      )
    ),

    # ── Tab 2: Customers ──────────────────────────────────────────────────────
    bslib::nav_panel(
      "Customers",

      bslib::card(
        bslib::card_header(
          class = "d-flex justify-content-between align-items-center",
          "Customers \u2014 click a row to view sales",
          modualFormUI("form")
        ),
        reactable::reactableOutput("customers_table")
      ),

      shiny::uiOutput("sales_card")
    ),

    bslib::nav_spacer(),
    bslib::nav_item(bslib::input_dark_mode())
  )

  server <- function(input, output, session) {

    # ── Dashboard plots ───────────────────────────────────────────────────────

    output$plot_industry <- shiny::renderPlot({
      d <- aggregate(revenue ~ industry, data = sales_full, FUN = sum)
      d <- d[order(d$revenue), ]
      d$industry <- factor(d$industry, levels = d$industry)

      ggplot2::ggplot(d, ggplot2::aes(x = revenue, y = industry)) +
        ggplot2::geom_col() +
        ggplot2::scale_x_continuous(labels = scales::label_dollar()) +
        ggplot2::labs(x = "Total Revenue", y = NULL) +
        ggplot2::theme_minimal()
    })

    output$plot_trend <- shiny::renderPlot({
      d <- aggregate(revenue ~ month, data = sales_full, FUN = sum)

      ggplot2::ggplot(d, ggplot2::aes(x = month, y = revenue)) +
        ggplot2::geom_line() +
        ggplot2::geom_point() +
        ggplot2::scale_y_continuous(labels = scales::label_dollar()) +
        ggplot2::scale_x_date(date_labels = "%b %Y", date_breaks = "3 months") +
        ggplot2::labs(x = NULL, y = "Revenue") +
        ggplot2::theme_minimal()
    })

    output$plot_top_customers <- shiny::renderPlot({
      d <- aggregate(revenue ~ company, data = sales_full, FUN = sum)
      d <- d[order(d$revenue, decreasing = TRUE), ][seq_len(10), ]
      d <- d[order(d$revenue), ]
      d$company <- factor(d$company, levels = d$company)

      ggplot2::ggplot(d, ggplot2::aes(x = revenue, y = company)) +
        ggplot2::geom_col() +
        ggplot2::scale_x_continuous(labels = scales::label_dollar()) +
        ggplot2::labs(x = "Total Revenue", y = NULL) +
        ggplot2::theme_minimal()
    })

    output$plot_products <- shiny::renderPlot({
      d <- aggregate(revenue ~ product, data = sales_full, FUN = sum)
      d <- d[order(d$revenue), ]
      d$product <- factor(d$product, levels = d$product)

      ggplot2::ggplot(d, ggplot2::aes(x = revenue, y = product)) +
        ggplot2::geom_col() +
        ggplot2::scale_x_continuous(labels = scales::label_dollar()) +
        ggplot2::labs(x = "Total Revenue", y = NULL) +
        ggplot2::theme_minimal()
    })

    output$recent_sales_table <- reactable::renderReactable({
      d <- sales_full[order(sales_full$sale_date, decreasing = TRUE), ][seq_len(5), ]

      reactable::reactable(
        d[, c("sale_date", "company", "product", "quantity", "price", "revenue")],
        striped = TRUE,
        theme   = rt_theme,
        columns = list(
          sale_date = reactable::colDef(name = "Date",       maxWidth = 120),
          company   = reactable::colDef(name = "Company"),
          product   = reactable::colDef(name = "Product"),
          quantity  = reactable::colDef(name = "Qty",        maxWidth = 80),
          price     = reactable::colDef(name = "Unit Price", maxWidth = 120,
                        format = reactable::colFormat(prefix = "$", separators = TRUE, digits = 2)),
          revenue   = reactable::colDef(name = "Revenue",    maxWidth = 120,
                        format = reactable::colFormat(prefix = "$", separators = TRUE, digits = 2))
        )
      )
    })

    # ── Customers tab ─────────────────────────────────────────────────────────

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
          id          = reactable::colDef(name = "ID",          maxWidth = 60),
          company     = reactable::colDef(name = "Company"),
          first_name  = reactable::colDef(name = "First Name"),
          last_name   = reactable::colDef(name = "Last Name"),
          industry    = reactable::colDef(name = "Industry"),
          hq_location = reactable::colDef(name = "HQ Location")
        )
      )
    })

    modualFormServer("form")

    selected_customer <- reactive({
      idx <- reactable::getReactableState("customers_table", "selected")
      if (is.null(idx)) return(NULL)
      customers[idx, ]
    })

    output$sales_card <- shiny::renderUI({
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
          sale_date = reactable::colDef(name = "Date",       maxWidth = 120),
          product   = reactable::colDef(name = "Product"),
          quantity  = reactable::colDef(name = "Qty",        maxWidth = 80),
          price     = reactable::colDef(name = "Unit Price", maxWidth = 120,
                        format = reactable::colFormat(prefix = "$", separators = TRUE, digits = 2)),
          revenue   = reactable::colDef(name = "Revenue",    maxWidth = 120,
                        format = reactable::colFormat(prefix = "$", separators = TRUE, digits = 2))
        )
      )
    })
  }

  shiny::shinyApp(ui, server)
}

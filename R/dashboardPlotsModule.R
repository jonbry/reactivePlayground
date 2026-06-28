dashboardPlotsUI <- function(id) {
  ns <- shiny::NS(id)

  htmltools::tagList(

    # ── Filters ───────────────────────────────────────────────────────────────
    bslib::card(
      bslib::card_header("Filters"),
      bslib::layout_column_wrap(
        width = 1/3,
        fill  = FALSE,
        shiny::dateRangeInput(
          ns("date_range"),
          "Date Range",
          start = NULL,   # populated by server via updateDateRangeInput
          end   = NULL
        ),
        shiny::selectInput(
          ns("industry"),
          "Industry",
          choices  = NULL,  # populated by server
          multiple = TRUE,
          selected = NULL
        ),
        shiny::selectInput(
          ns("product"),
          "Product",
          choices  = NULL,  # populated by server
          multiple = TRUE,
          selected = NULL
        )
      )
    ),

    # ── Plots ─────────────────────────────────────────────────────────────────
    bslib::layout_column_wrap(
      width         = 1/2,
      fill          = FALSE,
      heights_equal = "row",

      bslib::card(
        full_screen = TRUE,
        bslib::card_header("Revenue by Industry"),
        shiny::plotOutput(ns("plot_industry"), height = "260px")
      ),
      bslib::card(
        full_screen = TRUE,
        bslib::card_header("Monthly Revenue"),
        shiny::plotOutput(ns("plot_trend"), height = "260px")
      ),
      bslib::card(
        full_screen = TRUE,
        bslib::card_header("Top 10 Customers by Revenue"),
        shiny::plotOutput(ns("plot_top_customers"), height = "260px")
      ),
      bslib::card(
        full_screen = TRUE,
        bslib::card_header("Revenue by Product"),
        shiny::plotOutput(ns("plot_products"), height = "260px")
      )
    ),

    # ── Recent Sales ──────────────────────────────────────────────────────────
    bslib::card(
      bslib::card_header("Recent Sales"),
      reactable::reactableOutput(ns("recent_sales_table"))
    )
  )
}

dashboardPlotsServer <- function(id, sales_full, rt_theme) {
  shiny::moduleServer(id, function(input, output, session) {

    # Populate filter controls from the data
    shiny::observe({
      shiny::updateDateRangeInput(
        session, "date_range",
        start = min(sales_full$sale_date),
        end   = max(sales_full$sale_date)
      )
      shiny::updateSelectInput(session, "industry",
        choices  = sort(unique(sales_full$industry)),
        selected = sort(unique(sales_full$industry))
      )
      shiny::updateSelectInput(session, "product",
        choices  = sort(unique(sales_full$product)),
        selected = sort(unique(sales_full$product))
      )
    })

    # Filtered dataset used by all plots
    filtered <- shiny::reactive({
      shiny::req(input$date_range, input$industry, input$product)
      sales_full[
        sales_full$sale_date >= input$date_range[1] &
        sales_full$sale_date <= input$date_range[2] &
        sales_full$industry  %in% input$industry    &
        sales_full$product   %in% input$product,
      ]
    })

    # ── Plots ─────────────────────────────────────────────────────────────────

    output$plot_industry <- shiny::renderPlot({
      d <- aggregate(revenue ~ industry, data = filtered(), FUN = sum)
      d <- d[order(d$revenue), ]
      d$industry <- factor(d$industry, levels = d$industry)

      ggplot2::ggplot(d, ggplot2::aes(x = revenue, y = industry)) +
        ggplot2::geom_col() +
        ggplot2::scale_x_continuous(labels = scales::label_dollar()) +
        ggplot2::labs(x = "Total Revenue", y = NULL) +
        ggplot2::theme_minimal()
    })

    output$plot_trend <- shiny::renderPlot({
      d <- aggregate(revenue ~ month, data = filtered(), FUN = sum)

      ggplot2::ggplot(d, ggplot2::aes(x = month, y = revenue)) +
        ggplot2::geom_line() +
        ggplot2::geom_point() +
        ggplot2::scale_y_continuous(labels = scales::label_dollar()) +
        ggplot2::scale_x_date(date_labels = "%b %Y", date_breaks = "3 months") +
        ggplot2::labs(x = NULL, y = "Revenue") +
        ggplot2::theme_minimal()
    })

    output$plot_top_customers <- shiny::renderPlot({
      d <- aggregate(revenue ~ company, data = filtered(), FUN = sum)
      d <- d[order(d$revenue, decreasing = TRUE), ][seq_len(min(10, nrow(d))), ]
      d <- d[order(d$revenue), ]
      d$company <- factor(d$company, levels = d$company)

      ggplot2::ggplot(d, ggplot2::aes(x = revenue, y = company)) +
        ggplot2::geom_col() +
        ggplot2::scale_x_continuous(labels = scales::label_dollar()) +
        ggplot2::labs(x = "Total Revenue", y = NULL) +
        ggplot2::theme_minimal()
    })

    output$plot_products <- shiny::renderPlot({
      d <- aggregate(revenue ~ product, data = filtered(), FUN = sum)
      d <- d[order(d$revenue), ]
      d$product <- factor(d$product, levels = d$product)

      ggplot2::ggplot(d, ggplot2::aes(x = revenue, y = product)) +
        ggplot2::geom_col() +
        ggplot2::scale_x_continuous(labels = scales::label_dollar()) +
        ggplot2::labs(x = "Total Revenue", y = NULL) +
        ggplot2::theme_minimal()
    })

    output$recent_sales_table <- reactable::renderReactable({
      d <- filtered()
      d <- d[order(d$sale_date, decreasing = TRUE), ][seq_len(min(5, nrow(d))), ]

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
  })
}

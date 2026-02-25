#!/usr/bin/env Rscript
# Shiny QC dashboard
# Reads:
#   - <RESULTS_ROOT>/combined_metrics.csv
#   - <RESULTS_ROOT>/fastqc_multiqc/multiqc/multiqc_report.html (if present)

library(shiny)
library(readr)
library(ggplot2)
library(plotly)
library(dplyr)
library(tidyr)
library(bslib)
library(colorspace)

custom_theme <- bs_theme(
  version = 5,
  bootswatch = "flatly",
  base_font = font_google("Inter")
)

# -------------------------
# Results root (dummy-proof)
# -------------------------
# Prefer environment variable RESULTS_ROOT (set by run_dashboard.R)
results_root <- Sys.getenv("RESULTS_ROOT", unset = "")
if (results_root == "") {
  # fallback: allow running from within a results directory
  results_root <- getwd()
}
results_root <- normalizePath(results_root, winslash = "/", mustWork = FALSE)

metrics_path <- file.path(results_root, "combined_metrics.csv")
multiqc_dir   <- file.path(results_root, "fastqc_multiqc", "multiqc")
multiqc_html  <- file.path(multiqc_dir, "multiqc_report.html")

# Fail early with clear error for metrics
if (!file.exists(metrics_path)) {
  stop(
    "combined_metrics.csv not found.\n",
    "Looked for: ", metrics_path, "\n\n",
    "Run the metrics script first, e.g.:\n",
    "  Rscript local/metrics/summarize_metrics.R \"", results_root, "\"\n"
  )
}

metrics <- readr::read_csv(metrics_path, show_col_types = FALSE)

# Palette for samples
all_samples <- sort(unique(metrics$sample))
sample_palette <- setNames(
  colorspace::rainbow_hcl(n = length(all_samples), c = 45, l = 78),
  all_samples
)

plot_theme <- theme_minimal(base_size = 13) +
  theme(
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    panel.border = element_rect(colour = "grey35", fill = NA, linewidth = 0.9),
    plot.background = element_rect(fill = "white", colour = NA),
    panel.background = element_rect(fill = "white", colour = NA),
    strip.text = element_text(size = 14, face = "bold"),
    strip.background = element_rect(fill = "grey95", colour = "grey35", linewidth = 0.7),
    axis.title = element_text(size = 13),
    axis.text = element_text(size = 11),
    axis.ticks = element_line(colour = "grey35"),
    axis.line = element_line(colour = "grey35")
  )

# Serve MultiQC HTML from its folder (no copying needed)
multiqc_available <- dir.exists(multiqc_dir) && file.exists(multiqc_html)
if (multiqc_available) {
  addResourcePath("multiqc", multiqc_dir)
}

ui <- navbarPage(
  theme = custom_theme, titlePanel("WGS QC dashboard"),
  
  sidebarLayout(
    sidebarPanel(
      helpText(paste0("Results folder: ", results_root)),
      textInput("sample_filter", "Filter samples (substring or regex):", ""),
      helpText("Tip: try filtering by '3A06' or 's3b'."),
      helpText("Use the filter to restrict plots and tables to a subset of samples.")
    ),
    
    mainPanel(
      tabsetPanel(
        tabPanel(
          "Introduction",
          h3("Whole-genome sequencing QC dashboard"),
          p("This dashboard summarises QC and analysis output from the WGS pipeline."),
          tags$hr(),
          tags$ul(
            tags$li(strong("FastQC & MultiQC"), ": read QC summary"),
            tags$li(strong("Shovill & QUAST"), ": assembly metrics (contigs, N50)"),
            tags$li(strong("BUSCO"), ": completeness metrics"),
            tags$li(strong("Prokka"), ": gene count summary")
          )
        ),
        
        tabPanel(
          "MultiQC",
          h3("MultiQC report"),
          if (multiqc_available) {
            tags$iframe(
              src = "multiqc/multiqc_report.html",
              style = "width:100%; height:800px; border:none;"
            )
          } else {
            tags$div(
              tags$p(strong("MultiQC report not found.")),
              tags$p("Expected at:"),
              tags$pre(multiqc_html),
              tags$p("If you ran the pipeline, check that results/fastqc_multiqc/multiqc/multiqc_report.html exists.")
            )
          }
        ),
        
        tabPanel(
          "Shovill & QUAST results",
          h3("Assembly metrics (Shovill & QUAST)"),
          plotlyOutput("shovill_quast_plot", height = "450px"),
          tableOutput("shovill_quast_table")
        ),
        
        tabPanel(
          "Prokka results",
          h3("Annotation metrics (Prokka)"),
          plotlyOutput("prokka_plot", height = "350px"),
          tableOutput("prokka_table")
        ),
        
        tabPanel(
          "BUSCO (genome quality)",
          h3("BUSCO completeness per assembly"),
          plotlyOutput("busco_plot", height = "350px"),
          tableOutput("busco_table"),
          tags$hr(),
          h4("BUSCO composition (donut)"),
          plotlyOutput("busco_donut", height = "350px")
        ),
        
        tabPanel(
          "QC relationships",
          h3("Relationships between QC metrics"),
          plotlyOutput("scatter_contigs_n50", height = "350px"),
          plotlyOutput("scatter_n50_genes", height = "350px"),
          plotlyOutput("scatter_busco_n50", height = "350px")
        )
      )
    )
  )
)

server <- function(input, output, session) {
  
  filtered_metrics <- reactive({
    df <- metrics
    if (nzchar(input$sample_filter)) {
      df <- df[grepl(input$sample_filter, df$sample), ]
    }
    df
  })
  
  output$shovill_quast_plot <- renderPlotly({
    df <- filtered_metrics()
    req(nrow(df) > 0)
    
    key_metrics <- intersect(c("contigs", "n50"), names(df))
    req(length(key_metrics) > 0)
    
    long_df <- df %>%
      select(sample, all_of(key_metrics)) %>%
      pivot_longer(-sample, names_to = "metric", values_to = "value")
    
    p <- ggplot(long_df, aes(x = sample, y = value, fill = sample)) +
      geom_col(linewidth = 0.2) +
      facet_wrap(~ metric, scales = "free_y") +
      scale_fill_manual(values = sample_palette) +
      plot_theme +
      theme(axis.text.x = element_text(angle = 45, hjust = 1), legend.position = "none") +
      labs(x = "Sample", y = "Value")
    
    ggplotly(p)
  })
  
  output$shovill_quast_table <- renderTable({
    df <- filtered_metrics()
    keep <- intersect(c("sample", "contigs", "n50"), names(df))
    df[, keep, drop = FALSE]
  })
  
  output$prokka_plot <- renderPlotly({
    df <- filtered_metrics()
    req(nrow(df) > 0, "gene_count" %in% names(df))
    
    p <- ggplot(df, aes(x = sample, y = gene_count, fill = sample)) +
      geom_col(linewidth = 0.2) +
      scale_fill_manual(values = sample_palette) +
      plot_theme +
      theme(axis.text.x = element_text(angle = 45, hjust = 1), legend.position = "none") +
      labs(x = "Sample", y = "gene_count")
    
    ggplotly(p)
  })
  
  output$prokka_table <- renderTable({
    df <- filtered_metrics()
    keep <- intersect(c("sample", "gene_count"), names(df))
    df[, keep, drop = FALSE]
  })
  
  output$busco_plot <- renderPlotly({
    df <- filtered_metrics()
    if (!"busco_complete" %in% names(df) || nrow(df) == 0) return(NULL)
    
    df <- df %>% mutate(busco_complete = as.numeric(busco_complete))
    
    p <- ggplot(df, aes(x = sample, y = busco_complete, fill = sample)) +
      geom_col(linewidth = 0.2) +
      scale_fill_manual(values = sample_palette) +
      plot_theme +
      theme(axis.text.x = element_text(angle = 45, hjust = 1), legend.position = "none") +
      labs(x = "Sample", y = "BUSCO completeness (%)")
    
    ggplotly(p)
  })
  
  output$busco_table <- renderTable({
    df <- filtered_metrics()
    keep <- intersect(c("sample", "busco_complete", "busco_fragmented", "busco_missing"), names(df))
    if (length(keep) == 0) return(NULL)
    df[, keep, drop = FALSE]
  })
  
  output$busco_donut <- renderPlotly({
    df <- filtered_metrics()
    req(nrow(df) > 0)
    req(all(c("sample", "busco_complete", "busco_fragmented", "busco_missing") %in% names(df)))
    
    df1 <- df[1, , drop = FALSE]
    samp <- df1$sample[1]
    
    donut_df <- tibble::tibble(
      category = c("Complete", "Fragmented", "Missing"),
      value = c(df1$busco_complete, df1$busco_fragmented, df1$busco_missing)
    ) %>%
      mutate(value = as.numeric(value)) %>%
      filter(!is.na(value), value >= 0)
    
    req(nrow(donut_df) == 3)
    
    plot_ly(
      donut_df,
      labels = ~category,
      values = ~value,
      type = "pie",
      hole = 0.6,
      sort = FALSE,
      direction = "clockwise",
      textinfo = "percent",
      textposition = "inside",
      insidetextorientation = "radial",
      hoverinfo = "text",
      text = ~paste0(category, ": ", round(value, 2), "%")
    ) %>%
      layout(
        title = list(text = paste0("BUSCO composition: ", samp)),
        showlegend = TRUE,
        legend = list(orientation = "h", x = 0, y = -0.15),
        margin = list(l = 10, r = 10, t = 60, b = 60),
        uniformtext = list(mode = "hide", minsize = 10)
      )
  })
  
  output$scatter_contigs_n50 <- renderPlotly({
    df <- filtered_metrics()
    req(nrow(df) > 0)
    req(all(c("contigs", "n50") %in% names(df)))
    
    p <- ggplot(df, aes(x = contigs, y = n50, colour = sample)) +
      geom_point(size = 3, alpha = 0.9) +
      scale_colour_manual(values = sample_palette) +
      plot_theme +
      theme(legend.position = "none") +
      labs(x = "Number of contigs", y = "N50")
    
    ggplotly(p)
  })
  
  output$scatter_n50_genes <- renderPlotly({
    df <- filtered_metrics()
    req(nrow(df) > 0)
    req(all(c("n50", "gene_count") %in% names(df)))
    
    p <- ggplot(df, aes(x = n50, y = gene_count, colour = sample)) +
      geom_point(size = 3, alpha = 0.9) +
      scale_colour_manual(values = sample_palette) +
      plot_theme +
      theme(legend.position = "none") +
      labs(x = "N50", y = "Gene count")
    
    ggplotly(p)
  })
  
  output$scatter_busco_n50 <- renderPlotly({
    df <- filtered_metrics()
    if (nrow(df) == 0) return(NULL)
    if (!all(c("n50", "busco_complete") %in% names(df))) return(NULL)
    
    df <- df %>%
      mutate(
        busco_complete = as.numeric(busco_complete),
        qc_busco_flag = ifelse(!is.na(busco_complete) & busco_complete < 95, "FLAG: BUSCO < 95%", "OK")
      )
    
    p <- ggplot(df, aes(
      x = n50, y = busco_complete, colour = sample,
      text = paste0(
        "Sample: ", sample,
        "<br>N50: ", n50,
        "<br>BUSCO complete: ", busco_complete,
        "<br>Status: ", qc_busco_flag
      )
    )) +
      geom_point(size = 3, alpha = 0.9) +
      scale_colour_manual(values = sample_palette) +
      plot_theme +
      theme(legend.position = "none") +
      labs(x = "N50", y = "BUSCO completeness (%)")
    
    ggplotly(p, tooltip = "text")
  })
}

shinyApp(ui, server)
#!/usr/bin/env Rscript
# Shiny QC dashboard
# Reads:
#   - <RESULTS_ROOT>/combined_metrics.csv
#   - <RESULTS_ROOT>/fastqc_multiqc/multiqc/multiqc_report.html (if present)

# -------------------------
# 0) Results root (actually uses user input)
# -------------------------
args <- commandArgs(trailingOnly = TRUE)

# Priority:
# 1) first CLI argument (recommended)
# 2) env var RESULTS_ROOT
# 3) current working directory
results_root <- if (length(args) >= 1 && nzchar(args[1])) {
  args[1]
} else {
  Sys.getenv("RESULTS_ROOT", unset = getwd())
}

results_root <- normalizePath(results_root, winslash = "/", mustWork = FALSE)

# -------------------------
# 1) renv (project-local packages; works with conda R too)
# -------------------------
# Run renv restore from the dashboard folder so it finds renv.lock
dashboard_dir <- normalizePath("01_wgs/local/dashboard", winslash = "/", mustWork = FALSE)
old_wd <- getwd()
setwd(dashboard_dir)
on.exit(setwd(old_wd), add = TRUE)

if (!requireNamespace("renv", quietly = TRUE)) {
  install.packages("renv", repos = "https://cloud.r-project.org")
}
# restore is fast if already installed
renv::restore(prompt = FALSE)

# -------------------------
# 2) Load libraries
# -------------------------
library(shiny)
library(readr)
library(ggplot2)
library(plotly)
library(dplyr)
library(tidyr)
library(bslib)
library(colorspace)

# Optional: used for SVG export
if (!requireNamespace("svglite", quietly = TRUE)) {
  message("NOTE: Package 'svglite' not installed. SVG export will warn until installed.")
}

custom_theme <- bs_theme(
  version = 5,
  bootswatch = "flatly",
  base_font = font_google("Inter")
)

# -------------------------
# 3) Inputs (from results_root)
# -------------------------
metrics_path <- file.path(results_root, "combined_metrics.csv")
multiqc_dir  <- file.path(results_root, "fastqc_multiqc", "multiqc")
multiqc_html <- file.path(multiqc_dir, "multiqc_report.html")

if (!file.exists(metrics_path)) {
  stop(
    "combined_metrics.csv not found.\n",
    "Looked for: ", metrics_path, "\n\n",
    "USAGE:\n",
    "  Rscript 01_wgs/local/dashboard/app.R /path/to/results\n\n",
    "Then generate metrics first, e.g.:\n",
    "  Rscript 01_wgs/local/metrics/summarize_metrics.R \"", results_root, "\"\n"
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
      helpText("Use the filter to restrict plots and tables to a subset of samples."),
      
      tags$hr(),
      
      # NEW: export controls
      textInput("export_dir", "Export folder (SVG):", value = file.path(results_root, "dashboard_exports")),
      actionButton("export_svg", "Download all plots as SVG"),
      helpText("Creates one .svg per plot in the export folder.")
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
  
  # -------------------------
  # NEW: build ggplot objects (for SVG export) with minimal duplication
  # -------------------------
  gg_shovill_quast <- reactive({
    df <- filtered_metrics()
    validate(need(nrow(df) > 0, "No samples after filtering."))
    
    key_metrics <- intersect(c("contigs", "n50"), names(df))
    validate(need(length(key_metrics) > 0, "Missing contigs/n50 in metrics."))
    
    long_df <- df %>%
      select(sample, all_of(key_metrics)) %>%
      pivot_longer(-sample, names_to = "metric", values_to = "value")
    
    ggplot(long_df, aes(x = sample, y = value, fill = sample)) +
      geom_col(linewidth = 0.2) +
      facet_wrap(~ metric, scales = "free_y") +
      scale_fill_manual(values = sample_palette) +
      plot_theme +
      theme(axis.text.x = element_text(angle = 45, hjust = 1), legend.position = "none") +
      labs(x = "Sample", y = "Value")
  })
  
  gg_prokka <- reactive({
    df <- filtered_metrics()
    validate(need(nrow(df) > 0, "No samples after filtering."))
    validate(need("gene_count" %in% names(df), "gene_count missing in metrics."))
    
    ggplot(df, aes(x = sample, y = gene_count, fill = sample)) +
      geom_col(linewidth = 0.2) +
      scale_fill_manual(values = sample_palette) +
      plot_theme +
      theme(axis.text.x = element_text(angle = 45, hjust = 1), legend.position = "none") +
      labs(x = "Sample", y = "gene_count")
  })
  
  gg_busco <- reactive({
    df <- filtered_metrics()
    validate(need(nrow(df) > 0, "No samples after filtering."))
    validate(need("busco_complete" %in% names(df), "BUSCO columns not present."))
    
    df <- df %>% mutate(busco_complete = as.numeric(busco_complete))
    
    ggplot(df, aes(x = sample, y = busco_complete, fill = sample)) +
      geom_col(linewidth = 0.2) +
      scale_fill_manual(values = sample_palette) +
      plot_theme +
      theme(axis.text.x = element_text(angle = 45, hjust = 1), legend.position = "none") +
      labs(x = "Sample", y = "BUSCO completeness (%)")
  })
  
  gg_scatter_contigs_n50 <- reactive({
    df <- filtered_metrics()
    validate(need(nrow(df) > 0, "No samples after filtering."))
    validate(need(all(c("contigs", "n50") %in% names(df)), "contigs/n50 missing in metrics."))
    
    ggplot(df, aes(x = contigs, y = n50, colour = sample)) +
      geom_point(size = 3, alpha = 0.9) +
      scale_colour_manual(values = sample_palette) +
      plot_theme +
      theme(legend.position = "none") +
      labs(x = "Number of contigs", y = "N50")
  })
  
  gg_scatter_n50_genes <- reactive({
    df <- filtered_metrics()
    validate(need(nrow(df) > 0, "No samples after filtering."))
    validate(need(all(c("n50", "gene_count") %in% names(df)), "n50/gene_count missing in metrics."))
    
    ggplot(df, aes(x = n50, y = gene_count, colour = sample)) +
      geom_point(size = 3, alpha = 0.9) +
      scale_colour_manual(values = sample_palette) +
      plot_theme +
      theme(legend.position = "none") +
      labs(x = "N50", y = "Gene count")
  })
  
  gg_scatter_busco_n50 <- reactive({
    df <- filtered_metrics()
    validate(need(nrow(df) > 0, "No samples after filtering."))
    validate(need(all(c("n50", "busco_complete") %in% names(df)), "n50/busco_complete missing in metrics."))
    
    df <- df %>%
      mutate(
        busco_complete = as.numeric(busco_complete),
        qc_busco_flag = ifelse(!is.na(busco_complete) & busco_complete < 95, "FLAG: BUSCO < 95%", "OK")
      )
    
    ggplot(df, aes(
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
  })
  
  # -------------------------
  # Plotly outputs (unchanged behavior; now reuse ggplot reactives)
  # -------------------------
  output$shovill_quast_plot <- renderPlotly({
    ggplotly(gg_shovill_quast())
  })
  
  output$shovill_quast_table <- renderTable({
    df <- filtered_metrics()
    keep <- intersect(c("sample", "contigs", "n50"), names(df))
    df[, keep, drop = FALSE]
  })
  
  output$prokka_plot <- renderPlotly({
    ggplotly(gg_prokka())
  })
  
  output$prokka_table <- renderTable({
    df <- filtered_metrics()
    keep <- intersect(c("sample", "gene_count"), names(df))
    df[, keep, drop = FALSE]
  })
  
  output$busco_plot <- renderPlotly({
    df <- filtered_metrics()
    if (!"busco_complete" %in% names(df) || nrow(df) == 0) return(NULL)
    ggplotly(gg_busco())
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
    ggplotly(gg_scatter_contigs_n50())
  })
  
  output$scatter_n50_genes <- renderPlotly({
    ggplotly(gg_scatter_n50_genes())
  })
  
  output$scatter_busco_n50 <- renderPlotly({
    p <- gg_scatter_busco_n50()
    ggplotly(p, tooltip = "text")
  })
  
  # -------------------------
  # NEW: export SVGs (server-side)
  # -------------------------
  observeEvent(input$export_svg, {
    validate(need(requireNamespace("svglite", quietly = TRUE),
                  "Please install svglite to export SVGs: install.packages('svglite')"))
    
    outdir <- normalizePath(input$export_dir, winslash = "/", mustWork = FALSE)
    dir.create(outdir, recursive = TRUE, showWarnings = FALSE)
    
    safe_filter <- if (nzchar(input$sample_filter)) {
      gsub("[^A-Za-z0-9._-]+", "_", input$sample_filter)
    } else {
      "ALL"
    }
    
    # helper
    save_svg <- function(plot_obj, filename, width = 12, height = 6) {
      f <- file.path(outdir, filename)
      ggplot2::ggsave(f, plot_obj, device = svglite::svglite, width = width, height = height)
      f
    }
    
    saved <- c()
    saved <- c(saved, save_svg(gg_shovill_quast(), paste0("01_shovill_quast_", safe_filter, ".svg"), 14, 7))
    saved <- c(saved, save_svg(gg_prokka(),       paste0("02_prokka_", safe_filter, ".svg"),       14, 6))
    
    # BUSCO plot only if available
    if ("busco_complete" %in% names(filtered_metrics())) {
      saved <- c(saved, save_svg(gg_busco(), paste0("03_busco_", safe_filter, ".svg"), 14, 6))
    }
    
    saved <- c(saved, save_svg(gg_scatter_contigs_n50(), paste0("04_scatter_contigs_n50_", safe_filter, ".svg"), 8, 6))
    saved <- c(saved, save_svg(gg_scatter_n50_genes(),   paste0("05_scatter_n50_genes_", safe_filter, ".svg"),   8, 6))
    
    # BUSCO scatter only if available
    if (all(c("n50", "busco_complete") %in% names(filtered_metrics()))) {
      saved <- c(saved, save_svg(gg_scatter_busco_n50(), paste0("06_scatter_busco_n50_", safe_filter, ".svg"), 8, 6))
    }
    
    showNotification(
      paste0("Saved ", length(saved), " SVG files to: ", outdir),
      type = "message", duration = 8
    )
  })
}

shinyApp(ui, server)
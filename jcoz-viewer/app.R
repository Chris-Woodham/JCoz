#### Set up packages and clear environment

library(shiny)
library(ggplot2)
library(dplyr)
rm(list = ls())


## Graph theme
graph_theme <- theme(strip.background = element_rect(fill = "white"),
                  title = element_text(size = 18),
                  panel.grid.major = element_line(colour = "lightgrey", size = 0.5),
                  panel.grid.minor = element_line(colour = "lightgrey", size = 0.5),
                  panel.background = element_rect(fill = "white"),
                  legend.position = "bottom",
                  legend.justification = "bottom",
                  legend.text=element_text(size = 11),
                  axis.line.x = element_line(color="black", size = 0.5),
                  axis.line.y = element_line(color="black", size = 0.5),
                  axis.title.y = element_text(size = 14),
                  axis.text.y = element_text(size = 14),
                  axis.title.x = element_text(size = 14),
                  axis.text.x = element_text(size = 14),
                  plot.margin = margin(t = 30, r = 10, b = 10, l = 10))



#### Global variables - 

#### ShinyApp front end (User Interface)

ui <- fluidPage(
  titlePanel(title = "JCoz Causal Profile Viewer", windowTitle = "JCoz Causal Profile Viewer"),
  sidebarLayout(
    sidebarPanel( 
      sliderInput("minSampleSize", "Minimum sample size to plot a graph", value = 20, min = 0, max = 100),
      fileInput("dataFile", NULL, accept = ".csv"),
      actionButton("plotGraphs", "Plot Graphs"),
      actionButton("clearGraphs", "Clear Graphs"),
      tags$br(),
      tags$div("\n"),
      tags$h4("Graph info:"),
      tags$div(
        tags$ul(
          tags$li("The fitted blue line represents the general trend of throughput with line speedup"),
          tags$li("The grey area surrounding the trend line is a measure of the confidence in the trend (the wider the grey area, the lower the confidence we have in the trend)"),
          tags$li("The result of each individual experiment is plotted as a grey data point (the more experiments with identical results, the darker the data point)")
          )
      ),
      width = 3,
      style = "position:fixed; width:25%;"
    ),
    mainPanel(
      uiOutput("allPlots"),
      width = 9
    )
  )
)



#### ShinyApp back end (server)

server <- function(input, output, session) {
  
  getJcozData <- reactive(function() {
    req(input$dataFile)
    
    fileExtension <- tools::file_ext(input$dataFile$name)
    switch(fileExtension,
           csv = {jcozData = read.csv(input$dataFile$datapath, header = TRUE, stringsAsFactors = TRUE)},
           validate("Invalid file format; please upload a .csv file")
    )
    #jcozData$selectedClassLineNo <- as.factor(jcozData$selectedClassLineNo)
    
    # calculate throughput (Number of progress points hit per second)
    jcozData$throughput = (jcozData$progressPointHits / jcozData$duration) * 1000000000
    jcozData
  })
  
  observeEvent(input$plotGraphs, {
    req(input$dataFile)
    # Create a progress object
    graph_progress <- shiny::Progress$new()
    graph_progress$set(message = "Preparing JCoz graphs", detail = "For large datasets, this can take a while. There is a delay for initial rendering but when the graphs appear, this box can be closed.", value = 0)
    output$allPlots <- renderUI({
        plot_list <- list()
        req(input$dataFile)
        data <- getJcozData()
        # calculate min and max throughput
        min_throughput = min(data()$throughput) * 0.99
        max_throughput = max(data()$throughput) * 1.01
        
        filtered_data <- data() %>% add_count(selectedClassLineNo, sort = TRUE) %>% group_by(selectedClassLineNo) %>% dplyr::filter(n >= input$minSampleSize) %>% dplyr::filter(speedup == 0) %>% dplyr::filter(n() >= 3)
        print(typeof(filtered_data))
      
        unique_methods <- unique(filtered_data$selectedClassLineNo)

        num_unique_methods <- length(unique_methods)
        
        plot_list <- lapply(unique_methods, function(method){
          method_data = dplyr::filter(data(), selectedClassLineNo == method)
          subtitle <- paste0(" Sample size: ", nrow(method_data))
          renderPlot({
            ggplot() +
              geom_point(data = method_data, aes(x = speedup, y = throughput), size = 2, alpha = 0.3) +
              geom_smooth(data = method_data, aes(x = speedup, y = throughput), colour = "blue",  method = "loess", se = TRUE) +
              ylab("Throughput (no. progress points hit per second)") +
              ylim(min_throughput, max_throughput) +
              scale_x_continuous(name = "Line speedup (%)", breaks = c(0.0, 0.2, 0.4, 0.6, 0.8, 1.0), labels = c(0, 20, 40, 60, 80, 100), limits = c(0, 1)) +
              ggtitle(method, subtitle = subtitle) +
              graph_theme
          }) %>% bindCache(method_data$speedup, method_data$throughput)
        }
        )

        convert_plots_to_UI <-
            fluidRow(
              lapply(1:num_unique_methods, function(plot_list_index) {
                graph_progress$inc(1/(num_unique_methods + 1))
                return(column(6, plot_list[plot_list_index]))
              }
                )
            ) 

        graph_progress$inc(1/(num_unique_methods + 1))
        return(convert_plots_to_UI)
        })
    
    })
  
    observeEvent(input$clearGraphs, {
      output$allPlots <- renderUI({})
    })
}



#### run ShinyApp

runApp(appDir = shinyApp(ui = ui, server = server), launch.browser = TRUE)


#### Set up packages and clear environment

library(shiny)
library(ggplot2)
library(dplyr)
rm(list = ls())



#### ShinyApp front end (User Interface)

ui <- fluidPage(
  titlePanel("JCoz Causal Profile Viewer"),
  sidebarLayout(
    sidebarPanel( 
      sliderInput("graphSize", "Size of the graphs (1 = small, 10 = large)", value = 5, min = 1, max = 10),
      sliderInput("minSampleSize", "Minimum sample size to plot a graph", value = 20, min = 0, max = 100),
      fileInput("dataFile", NULL, accept = ".csv"),
      actionButton("plotGraphs", "Plot Graphs"),
      actionButton("clearGraphs", "Clear Graphs")
    ),
    mainPanel(
      uiOutput("allPlots")
    )
  )
)



#### ShinyApp back end (server)

server <- function(input, output, session) {
  
  getJcozData <- reactive(function() {
    req(input$dataFile)
    
    fileExtension <- tools::file_ext(input$dataFile$name)
    switch(fileExtension,
           csv = {jcozData = read.csv(input$dataFile$datapath, header = TRUE)},
           validate("Invalid file format; please upload a .csv file")
    )
    
    # calculate throughput (Number of progress points hit per second)
    jcozData$throughput = (jcozData$progressPointHits / jcozData$duration) * 1000000000
    jcozData
  })
  
  output$allPlots <- renderUI({
    plot_list <- list()
    
    req(input$dataFile)
    data <- getJcozData()
    # calculate min and max throughput
    min_throughput = min(data()$throughput) * 0.99
    max_throughput = max(data()$throughput) * 1.01
    
    for (method in unique(data()$selectedClassLineNo)) {
      print(method)
    }
    
    current_method_index = 1
    
    unique_methods <- unique(data()$selectedClassLineNo)
    
    plot_list <- lapply(unique_methods, function(method){
      method_data = dplyr::filter(data(), selectedClassLineNo == method)
      if (nrow(method_data) >= input$minSampleSize && nrow(filter(method_data, speedup == 0)) >= 3) {
        renderPlot({
          ggplot() +
            geom_point(data = method_data, aes(x = speedup, y = throughput), size = 2, alpha = 0.3) +
            geom_point(data = method_data %>% dplyr::group_by(speedup) %>% dplyr::summarise(mean_throughput = mean(throughput)), 
                       aes(x = speedup, y = mean_throughput), size = 5, colour = "navyblue") +
            geom_smooth(data = method_data, aes(x = speedup, y = throughput), method = "loess", se = FALSE) +
            ylim(min_throughput, max_throughput) +
            theme_classic()
        })
          }
    }
    )
    
    convert_plots_to_UI <- fluidRow(
      lapply(1:length(unique_methods), function(plot_list_index) column(6, plot_list[plot_list_index]))
    )

    return(convert_plots_to_UI)
  })
}



#### run ShinyApp

shinyApp(ui, server)

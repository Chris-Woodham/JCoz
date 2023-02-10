## Set up packages and clear environment ----

library(ggplot2)
library(dplyr)
rm(list = ls())
library(shiny)



## ShinyApp front end (User Interface) ----

ui <- fluidPage(
  titlePanel("JCoz Causal Profile Viewer"),
  sidebarLayout(
    sidebarPanel( 
      sliderInput("graphSize", "Size of the graphs (1 = small, 10 = large)", value = 5, min = 1, max = 10),
      sliderInput("minSampleSize", "Minimum sample size to plot a graph", value = 20, min = 0, max = 100),
      fileInput("dataFile", NULL, accept = ".csv")
    ),
    mainPanel(
      plotOutput("jcozPlot", width = "400px")
    )
  )
)



## ShinyApp back end (server) ----

server <- function(input, output, session) {
  tidyUploadedData <- reactive({
    req(input$dataFile)
    
    fileExtension <- tools::file_ext(input$dataFile$name)
    switch(fileExtension,
           csv = {jcozData = read.csv(input$dataFile$datapath, header = TRUE)},
           validate("Invalid file format; please upload a .csv file")
    )
    
    # calculate throughput (Number of progress points hit per second)
    jcozData$throughput = (data_test$progressPointHits / data_test$duration) * 1000000000
    # calculate min and max throughput
    min_throughput = min(jcozData$throughput)
    max_throughput = max(jcozData$throughput)
  })
  
  output$jcozPlot <- renderPlot({
    tidyUploadedData()
    # plot one graph for each 
    for (method in unique(data_test$selectedClassLineNo)) {
      method_data = dplyr::filter(data_test, selectedClassLineNo == method)
      print(length(unique(method_data$speedup)))
      print(input$minSampleSize)
      if (nrow(method_data) >= input$minSampleSize && nrow(filter(method_data, speedup == 0)) >= 3) {
        print(
          ggplot() +
            geom_point(data = method_data, aes(x = speedup, y = throughput), size = 2, alpha = 0.3) +
            geom_point(data = method_data %>% dplyr::group_by(speedup) %>% dplyr::summarise(mean_throughput = mean(throughput)), 
                       aes(x = speedup, y = mean_throughput), size = 5, colour = "navyblue") +
            geom_smooth(data = method_data, aes(x = speedup, y = throughput), method = "loess", se = FALSE) +
            theme_classic()
        )
      }
    }
  })
}



## run ShinyApp ----

shinyApp(ui, server)


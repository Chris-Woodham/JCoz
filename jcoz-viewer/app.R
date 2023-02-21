#### Set up packages, clear environment and parse the command line args

library(shiny)
library(ggplot2)
library(dplyr)
library(gridExtra)
rm(list = ls())

command_line_args = commandArgs(trailingOnly=TRUE)



#### Graph theme
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
                  plot.margin = margin(t = 30, r = 5, b = 10, l = 15))



#### ShinyApp front end (User Interface)

ui <- fluidPage(
  titlePanel(title = "JCoz Causal Profile Viewer", windowTitle = "JCoz Causal Profile Viewer"),
  sidebarLayout(
    sidebarPanel( 
      sliderInput("minSampleSize", "Minimum sample size to plot a graph", value = 50, min = 30, max = 100),
      fileInput("dataFile", NULL, accept = ".csv"),
      tags$div(
        actionButton("plotGraphs", "Plot Graphs"),
        actionButton("clearGraphs", "Clear Graphs")
      ),
      tags$div("\n"),
      tags$h4("Graph info:"),
      tags$div(
        tags$ul(
          tags$li("The fitted blue line represents the general trend of throughput with line speedup"),
          tags$li("The wider the grey area surrounding the trend line, the lower the confidence we have in the trend"),
          tags$li("The result of each individual experiment is plotted as a grey data point (overlapping data points appear darker)")
          )
      ),
      tags$h4("Downloading graphs"),
      tags$div(
        radioButtons("graphShape", label = "Select the shape for downloaded graphs:", 
                     choices = c("Landscape", "Portrait", "Square"), 
                     selected = "Square", inline = TRUE),
        downloadButton("downloadGraphs", "Download Graphs")
      ),
      style = "position:fixed; width:25%;",
      width = 3
    ),
    mainPanel(
      uiOutput("allPlots"),
      width = 9
    )
  )
)



#### ShinyApp back end (Server)

server <- function(input, output, session) {
  
  # load data and filter two types of result:
  # 1) experiments where effectiveDuration <= 0
  # 2) experiments with a speedup of 0.0 where effectiveDuration != duration
  # then calculate throughput
  getJcozData <- reactive(function() {
    
    # ensure that getJcozData() can only be called once the user has input the `dataFile`
    req(input$dataFile)
    
    # read the data from the user input `dataFile`
    fileExtension <- tools::file_ext(input$dataFile$name)
    switch(fileExtension,
           csv = {jcozData = read.csv(input$dataFile$datapath, header = TRUE, stringsAsFactors = TRUE)},
           validate("Invalid file format; please upload a .csv file")
    )
    jcozData <- filter(jcozData, effectiveDuration > 0)
    jcozData <- jcozData[!(jcozData$speedup == 0 & jcozData$effectiveDuration < jcozData$duration),]
    # calculate throughput (Number of progress points hit per second)
    jcozData$throughput = (jcozData$progressPointHits / jcozData$effectiveDuration) * 1000000000
    jcozData
  })
  
  observeEvent(input$plotGraphs, {
    
    # ensure that the graphs can only be plotted once the user has input the `dataFile`
    req(input$dataFile)
    
    # Create a progress object
    # Note - the progress bar is not perfect, it hits 100% progress before the graphs are completed and does not automatically close
    # This is because this renderUI call itself returns a `fluidRow` object that then calls the graph rendering function (so at the end of the renderUI method - the progress bar should not automatically close because the graphs will not yet be rendered)
    # However, the progress bar has a subtitle that briefly explains this to the user
    graph_progress <- shiny::Progress$new()
    graph_progress$set(message = "Preparing JCoz graphs", detail = "For large datasets, this can take a while. There is a delay for initial rendering but when the graphs appear, this box can be closed.", value = 0)
    
    # render the JCoz graphs
    output$allPlots <- renderUI({
      
        # load and filter data
        data <- getJcozData()
        
        # filter the data to identify methods that: a) have 3 or more data points for 0 speed-up; and b) have a sample size greater than the user specified minimum sample size
        filtered_data <- data() %>% add_count(selectedClassLineNo, sort = TRUE) %>% group_by(selectedClassLineNo) %>% dplyr::filter(n >= input$minSampleSize) %>% dplyr::filter(speedup == 0) %>% dplyr::filter(n() >= 3)
        unique_methods <- unique(filtered_data$selectedClassLineNo)
        num_unique_methods <- length(unique_methods)
        
        # create a list of ggplot objects - one for each of the unique_methods in the filtered data set
        plot_list <- list()
        plot_list <- lapply(unique_methods, function(method) {
          # obtain the data for this specific method (JavaClass:LineNo) and then:
          # filter method_data to remove any extreme outliers (as these results occur when JCoz (or coz) incorrectly calculates effectiveDuration)
          # (Note - mean rather than median has been used for identifying outliers, as calculating the mean should have a lower time complexity than calculating the median)
          method_data <- dplyr::filter(data(), selectedClassLineNo == method)
          mean_throughput <- mean(method_data$throughput)
          percentile_95_difference <- quantile(method_data$throughput, 0.95) - mean_throughput
          percentile_5_difference <- mean_throughput - quantile(method_data$throughput, 0.05)
          method_data <- method_data[!(method_data$throughput < (mean_throughput - (2 * percentile_5_difference)) | method_data$throughput > (mean_throughput + (2 * percentile_95_difference))), ]
          # calculate min and max throughput for the scale of the y-axis
          min_throughput <- min(method_data$throughput) * 0.99
          max_throughput <- max(method_data$throughput) * 1.01
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
          # this cache greatly speeds up re-rendering graphs when the user changes the minimum sample size
        }
        )
        
        # create a `fluidRow` output block that plots each of the ggplot graphs in `plot_list` in a `fluidRow` format
        convert_plots_to_UI <-
            fluidRow(
              lapply(1:num_unique_methods, function(plot_list_index) {
                # increment the progress bar for graph rendering
                graph_progress$inc(1/(num_unique_methods + 1))
                return(column(6, plot_list[plot_list_index]))
                }
              )
            ) 
        
        # increment the progress bar for graph rendering
        graph_progress$inc(1/(num_unique_methods + 1))
        
        return(convert_plots_to_UI)
        })
    
    })
  
    observeEvent(input$clearGraphs, {
      output$allPlots <- renderUI({})
    })
    
    output$downloadGraphs <- downloadHandler(
      filename = "jcoz-graphs.pdf",
      content = function(fileName) {
        
        # ensure that the graphs can only be plotted once the user has input the `dataFile`
        req(input$dataFile)

        # create the download notification pop-up box - and ensure that it closes automatically once the download completes
        notification <- showNotification(
          "Rendering PDF ...", 
          duration = NULL, 
          closeButton = FALSE
        )
        on.exit(removeNotification(notification), add = TRUE)
        
        # load and filter data
        data <- getJcozData()
        
        # filter the data to identify methods that: a) have 3 or more data points for 0 speed-up; and b) have a sample size greater than the user specified minimum sample size
        filtered_data <- data() %>% add_count(selectedClassLineNo, sort = TRUE) %>% group_by(selectedClassLineNo) %>% dplyr::filter(n >= input$minSampleSize) %>% dplyr::filter(speedup == 0) %>% dplyr::filter(n() >= 3)
        unique_methods <- unique(filtered_data$selectedClassLineNo)
        num_unique_methods <- length(unique_methods)
        
        # create a list of ggplot objects - one for each of the unique_methods in the filtered data set
        plot_list <- list()
        plot_list <- lapply(unique_methods, function(method) {
          # obtain the data for this specific method (JavaClass:LineNo) and then:
          # filter method_data to remove any extreme outliers (as these results occur when JCoz (or coz) incorrectly calculates effectiveDuration)
          # (Note - mean rather than median has been used for identifying outliers, as calculating the mean should have a lower time complexity than calculating the median)
          method_data <- dplyr::filter(data(), selectedClassLineNo == method)
          mean_throughput <- mean(method_data$throughput)
          percentile_95_difference <- quantile(method_data$throughput, 0.95) - mean_throughput
          percentile_5_difference <- mean_throughput - quantile(method_data$throughput, 0.05)
          method_data <- method_data[!(method_data$throughput < (mean_throughput - (2 * percentile_5_difference)) | method_data$throughput > (mean_throughput + (2 * percentile_95_difference))), ]
          # calculate min and max throughput for the scale of the y-axis
          min_throughput <- min(method_data$throughput) * 0.99
          max_throughput <- max(method_data$throughput) * 1.01
          subtitle <- paste0(" Sample size: ", nrow(method_data))
          return(
            ggplot() +
              geom_point(data = method_data, aes(x = speedup, y = throughput), size = 2, alpha = 0.3) +
              geom_smooth(data = method_data, aes(x = speedup, y = throughput), colour = "blue",  method = "loess", se = TRUE) +
              ylab("Throughput (no. progress points hit per second)") +
              ylim(min_throughput, max_throughput) +
              scale_x_continuous(name = "Line speedup (%)", breaks = c(0.0, 0.2, 0.4, 0.6, 0.8, 1.0), labels = c(0, 20, 40, 60, 80, 100), limits = c(0, 1)) +
              ggtitle(method, subtitle = subtitle) +
              graph_theme
          )
        }
        )
        
        # graph shape determined by user input
        if (input$graphShape == "Landscape") {
          graph_height_mm = 190
          graph_width_mm = 277
        } else if (input$graphShape == "Portrait") {
          graph_height_mm = 277
          graph_width_mm = 190
        } else {
          graph_height_mm = 190
          graph_width_mm = 190
        }
        
        # save each of the ggplot graphs within `plot_list` into a single PDF whose name is determined by `fileName``
        ggsave(filename = fileName,
               plot = gridExtra::marrangeGrob(plot_list, nrow = 1, ncol = 1),
               width = graph_width_mm, height = graph_height_mm, unit = "mm")
        
        # return the graph pdf so that it downloads on the browser
        return(fileName)
        }
    )
}



#### Run ShinyApp

# Note - command_line_args[1] is the port that this shiny app will run on
runApp(appDir = shinyApp(ui = ui, server = server), port = as.numeric(command_line_args[1]))


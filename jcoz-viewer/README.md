# JCoz Viewer

The JCoz viewer web app can be run using the following command:
`Rscript app.R $port_number`

Before it can be run on a machine - R (and the R packages the app uses) will need to be installed.

Resources I found useful when building the JCoz Viewer Shiny app:

* [Mastering Shiny online book](https://mastering-shiny.org/index.html)
* [A Shiny guide to dynamic UI](https://shiny.rstudio.com/articles/dynamic-ui.html)
* [Adding progress bars to Shiny apps](https://shiny.rstudio.com/articles/progress.html)
* How to save multiple ggplot graphs into a single PDF using `gridExtra::marrangeGrob` and `ggsave` [a (StackOverflow)](https://stackoverflow.com/questions/12234248/printing-multiple-ggplots-into-a-single-pdf-multiple-plots-per-page) and [b (StackOverflow)](https://stackoverflow.com/questions/68719869/saving-several-plots-contained-within-a-list-as-one-pdf-file-with-ggsave)
* How to create a `fluidRow` object containing graphs - when the number of graphs (and therefore the number of rows) is determined by the data the user uploads [(StackOverflow question)](https://stackoverflow.com/questions/73898763/dynamic-plot-layout-in-shiny)
* Not used in the app - but how to include a waiting spinner in a Shiny app: [a) StackOverflow](https://stackoverflow.com/questions/49488228/how-to-show-spinning-wheel-or-busy-icon-while-waiting-in-shiny) and [b) the GitHub repo](https://github.com/daattali/shinycssloaders)
* Promises are not currently used in the app - but this was a good [introduction to using promises in R](https://rstudio.github.io/promises/articles/motivation.html)

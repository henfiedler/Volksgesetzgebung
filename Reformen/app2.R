#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

ui <- fluidPage(
    
    # Application title
    titlePanel("Reformen der Volksgesetzgebung in den Bundesländern"),
    
    # Sidebar with a slider input for number of bins 
    sidebarLayout(
        sidebarPanel(
            sliderInput("years",
                        "Jahr",
                        min = 1945,
                        max = 2020,
                        value = 1945,
                        sep = "")
        ),
        
        # Show a plot of the generated distribution
        mainPanel(
            plotlyOutput("plot")
        )
    )
)

# Define server logic required to draw a histogram
server <- function(input, output) {
    output$plot <- renderPlotly({
        
        ggplotly({
            
            P <- ggplot(DF) +
                geom_sf(aes(geometry = geometry,
                            label = Bundesland),
                        lwd = 0.2) +
                geom_sf(aes(geometry = geometry,
                            frame = Jahr,
                            label = Beschreibung,
                            fill = Typ),
                        lwd = 1) +
                theme_bw() +
                theme(legend.position = "none") +
                labs(
                    x = "",
                    y = "",
                    title = "Reformen der Volksgesetzgebung in den Bundesländern",
                    caption = "Source: Mehr Demokratie e.V.")
            
            P
        })
    })
}

# Run the application 
shinyApp(ui = ui, server = server)

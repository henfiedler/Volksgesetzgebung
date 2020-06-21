# Pakete laden
packages <- c("tidyverse",
              "readr",
              "ggplot2",
              "plotly",
              "shiny")

for (p in packages) {
    if (p %in% installed.packages()[,1]) {
        print(paste0(p, ' is installed. Will now load ', p,'.'))
        library(p, character.only=T)
    }
    else {
        print(paste0(p, ' is NOT installed. Will now install ', p,'.'))
        install.packages(p)
        library(p, character.only=T)
    }
}

rm(packages, p)

## Daten laden
# Reformen der Volksgesetzgebung
df <- read_csv("VB_VE.csv")

# Geodaten für Deutschland (nach Bundesländern)
ger <- readRDS("gadm36_DEU_1_sf.rds") %>%
    rename(Bundesland = NAME_1)

## Join mit Geodaten
# Check des Identifiers
df$Bundesland %in% ger$Bundesland

DF <- ger %>%
    left_join(df, by = "Bundesland") %>%
    select(Jahr, Bundesland, Typ, Beschreibung, geometry) %>%
    mutate(Beschreibung = str_wrap(Beschreibung, width = 40))


# Define UI for application
ui <- fluidPage(

    # Application title
    titlePanel("Reformen der Volksgesetzgebung in den Bundesländern"),

    # Sidebar with a slider input for years
    sidebarLayout(
        sidebarPanel(
            sliderInput(inputId = "years",
                        label = "Jahr",
                        min = min(DF$Jahr),
                        max = max(DF$Jahr),
                        value = min(DF$Jahr),
                        sep = "")
        ),
        # Show a plot
        mainPanel(
           plotlyOutput("plot")
        )
    )
)

# Definiere Server Logik für Map
server <- function(input, output) {
    output$plot <- renderPlotly({
        
        ggplotly({
            
            DF_year <- DF %>%
                filter(Jahr == input$years)
            
            p <- ggplot(DF) +
                geom_sf(aes(geometry = geometry,
                            label = Bundesland), lwd = 0.2) +
                ifelse(input$years != DF$Jahr,
                        geom_sf(data = DF, aes(geometry = geometry,
                                label = Bundesland), lwd = 0.2),
                        geom_sf(data = DF_year, aes(geometry = geometry,
                                            fill = Typ,
                                            text = paste0("Bundesland: ", Bundesland, "\n",
                                                          Beschreibung)),
                        lwd = 0.4)) +
                theme_bw() +
                theme(legend.position = "none") +
                labs(
                    x = "",
                    y = "",
                    caption = "Source: Mehr Demokratie e.V.")
            p
        })
    })
}

# Run the application 
shinyApp(ui = ui, server = server)

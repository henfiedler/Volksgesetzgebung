# Pakete laden ------------------------------------------------------
library("tidyverse")
library("readr")
library("ggplot2")
library("plotly")
library("shiny")
library("rsconnect")

## Daten laden ------------------------------------------------------
# Reformen der Volksgesetzgebung
df <- read_csv("VB_VE.csv")

# Geodaten für Deutschland (nach Bundesländern)
ger <- readRDS("gadm36_DEU_1_sf.rds") %>%
    rename(Bundesland = NAME_1)

## Join mit Geodaten -------------------------------------------------
# Check des Identifiers
df$Bundesland %in% ger$Bundesland

DF <- ger %>%
    left_join(df, by = "Bundesland") %>%
    select(Jahr, Bundesland, Typ, Beschreibung, geometry) %>%
    mutate(Beschreibung = str_wrap(Beschreibung, width = 40))

## Shiny App programmieren -------------------------------------------
# definiere UI für Applikation
ui <- fluidPage(

    # Applikationstitle
    titlePanel("Reformen der Volksgesetzgebung in den Bundesländern"),

    # Sidebar mit  einem Slider-Input für Jahre
    sidebarLayout(
        sidebarPanel(
            sliderInput(inputId = "years",
                        label = "Jahr",
                        min = min(DF$Jahr),
                        max = max(DF$Jahr),
                        value = min(DF$Jahr),
                        sep = "")
            
        ),
        # Plot als interaktive Plotly-Grafik anlegen
        mainPanel(
           plotlyOutput("plot"),
           textOutput("caption")
        )
    )
)

# Definiere Server Logik für die Umsetzung als Map
server <- function(input, output) {
    output$plot <- renderPlotly({
        # Plot wird zu interaktiver plotly-Grafik umgewandelt
        ggplotly({
            
            DF_year <- DF %>%
                filter(Jahr == input$years)
            # der eigentliche Plot wird mit ggplot erstellt
            p <- ggplot(DF) +
                # Karte an sich mit allen Bundesländern
                geom_sf(aes(geometry = geometry,
                            label = Bundesland), lwd = 0.2) +
                # Einfärben der Bundesländer mit Reformen in einem jeweiligen Jahr
                ifelse(input$years != DF$Jahr, # mit ifelse-Funktion wird ausgeklammert, wenn es in einem Jahr keine Reformen gab
                        geom_sf(data = DF, aes(geometry = geometry,
                                label = Bundesland), lwd = 0.2),
                        geom_sf(data = DF_year, aes(geometry = geometry,
                                            fill = Typ,
                                            text = paste0("Bundesland: ", Bundesland, "\n",
                                                          Beschreibung)),
                        lwd = 0.4)) +
                # Layout-Einstellungen
                theme_bw() +
                theme(legend.position = "none")
            # Plot wird ausgegeben
            p
        })
    })
    # Caption wird unter den Plot eingefügt
    output$caption <- renderText("Quelle: Mehr Demokratie e.V.; Wir möchten darauf hinweisen, dass diese Übersicht trotz sorgfältiger Prüfung
                                 keine Vollständigkeit beanspruchen kann. Wenn Sie ergänzende oder korrigierende Hinweise für uns haben,
                                 nehmen wir diese gerne unter [E-Mail-Adresse] entgegen und versuchen sie so schnell wie möglich zu berücksichtigen.")
}

## Shiny App starten -----------------------------------------------------
shinyApp(ui = ui, server = server)
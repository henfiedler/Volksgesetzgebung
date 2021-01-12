# Pakete laden ------------------------------------------------------
library("tidyverse")
library("readxl")
library("plotly")
library("shiny")
library("sf")

## Daten laden ------------------------------------------------------
# Reformen der Volksgesetzgebung
df <- read_excel("Reformen.xlsx") %>%
    rename(NAME_1 = Bundesland)

# Geodaten für Deutschland (nach Bundesländern)
ger <- readRDS("gadm36_DEU_1_sf.rds") %>% 
    st_transform(3857) %>% # Mercator-Projektion
    st_simplify(preserveTopology = TRUE, dTolerance = 5000) %>%
    # lowering resolution
    st_cast("MULTIPOLYGON")


## Join mit Geodaten -------------------------------------------------
DF <- ger %>%
    left_join(df, by = "NAME_1") %>%
    select(Jahr, NAME_1, Typ, Beschreibung, geometry) %>%
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
            p <- ggplot(data = DF) +
                # Deutschlandkarte mit Label für Bundesländer
                ifelse(input$years != DF$Jahr,
                       geom_sf(aes(geometry = geometry,
                                   text = paste0("Bundesland: ", NAME_1)),
                               lwd = 0.2),
                       geom_sf(data = DF_year, aes(geometry = geometry,
                                                   fill = Typ,
                                                   text = paste0("Bundesland: ", NAME_1, "\n",
                                                                 Beschreibung)),
                               lwd = 0.4)) +
                # Layout-Einstellungen
                theme_bw() +
                theme(legend.position = "none") +
                scale_fill_manual(values = c(
                    "Landesverfassung" = "lightblue",
                    "Landesgesetz" = "green",
                    "Gesetzesänderung" = "orange",
                    "Gesetzespaket" = "darkblue"))
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


# Pakete laden ------------------------------------------------------
library("tidyverse")
library("readxl")
library("plotly")
library("sf")

## Daten laden ------------------------------------------------------
# Reformen der Volksgesetzgebung#
# https://cran.r-project.org/web/packages/GADMTools/GADMTools.pdf
df <- read_excel("VB_VE.xlsx") %>%
  rename(NAME_1 = Bundesland)

# Geodaten für Deutschland (nach Bundesländern)
ger <- readRDS("gadm36_DEU_1_sf.rds")

# https://plotly-r.com/maps.html
ger_simple <- readRDS("gadm36_DEU_1_sf.rds") %>% 
  st_transform(3857) %>%
  # CRS: Mercator
  # https://www.nceas.ucsb.edu/sites/default/files/2020-04/OverviewCoordinateReferenceSystems.pdf
  st_simplify(preserveTopology = TRUE, dTolerance = 1000) %>% 
  st_cast("MULTIPOLYGON")

str(ger_simple)
object.size(ger_simple)

## Join mit Geodaten -------------------------------------------------
DF <- ger_simple %>%
  left_join(df, by = "NAME_1") %>%
  select(Jahr, NAME_1, Typ, Beschreibung, geometry) %>%
  mutate(Beschreibung = str_wrap(Beschreibung, width = 40))

## Ausgangskarte -----------------------------------------------------
# mit ggplot
P <- ggplot(data = DF) +
  # Karte an sich mit allen Bundesländern
  geom_sf(aes(geometry = geometry,
              text = paste0("Bundesland: ", NAME_1)),
          lwd = 0.2) +
  # Layout
  theme_bw() +
  labs(
    x = "",
    y = "",
    title = "Reformen der Volksgesetzgebung in den  von 1946 bis 2018")

## Interaktive Grafik ------------------------------------------------
# in plotly-Objekt umwandeln
ggplotly(P) %>%
  # Hervorhebungen und Infotext der Reformen hinzufügen
  add_sf(color = ~Typ == c("Landesverfassung", "Landesgesetz", "Gesetzesänderung", "Gesetzespaket"),
         # colors = "lightblue",
         hoveron = "points",
         text = ~paste0("Bundesland: ", NAME_1, "\n",
                        Beschreibung),
         hoverinfo = "text",
         # Slider nach Jahreszahlen einfügen
         frame = ~Jahr) %>%
  # Parameter der Animation spezifizieren
  animation_opts(frame = 5000, transition = 0, easing = "linear", redraw = TRUE, mode = "immediate"
  ) %>%
  # Anmerkungstext hinzufügen
  layout(annotations =
           list(x = 0,
                y = -0.07,
                text = "Quelle: Mehr Demokratie e.V. Stand 2020; Wir möchten darauf hinweisen, dass diese Übersicht trotz sorgfältiger Prüfung keine Vollständigkeit beanspruchen kann. Wenn Sie ergänzende
oder korrigierende Hinweise für uns haben, nehmen wir diese gerne unter [E-Mail-Adresse] entgegen und versuchen sie so schnell wie möglich zu berücksichtigen.",
                align = "left",
                showarrow = FALSE,
                xref = "paper",
                yref = "paper",
                xanchor = "left",
                yanchor = "top",
                xshift = 0,
                yshift = 0,
                font = list(size = 12, color = "black"))) %>%
  style(hoverlabel = list(bgcolor = "white")) 
# %>% plotly_build()
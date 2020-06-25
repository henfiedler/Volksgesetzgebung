# Pakete laden ------------------------------------------------------
library("tidyverse")
library("readr")
library("plotly")
library("sf")

## Daten laden ------------------------------------------------------
# Reformen der Volksgesetzgebung
df <- read_csv("VB_VE.csv") %>%
  rename(NAME_1 = Bundesland)

# Geodaten für Deutschland (nach Bundesländern)
ger <- readRDS("gadm36_DEU_1_sf.rds")

## Join mit Geodaten -------------------------------------------------
DF <- ger %>%
  left_join(df, by = "NAME_1") %>%
  select(Jahr, NAME_1, Typ, Beschreibung, geometry) %>%
  mutate(Beschreibung = str_wrap(Beschreibung, width = 40))

## Plot programmieren -------------------------------------------
# ggplot
P <- ggplot(data = DF) +
  # Karte an sich mit allen Bundesländern
  geom_sf(aes(geometry = geometry,
              text = paste0("Bundesland: ", NAME_1)),
          lwd = 0.2) +
  # Einfärben der Bundesländer mit Reformen in einem jeweiligen Jahr
  geom_sf(aes(geometry = geometry,
              frame = Jahr,
              fill = Typ,
              text = paste0("Bundesland: ", NAME_1, "\n",
                            Beschreibung)),
          lwd = 0.4) +
  # Layout
  theme_bw() +
  theme(legend.position = "none") +
  labs(
    x = "",
    y = "",
    title = "Reformen der Volksgesetzgebung in den Bundesländern")

## Interaktive Grafik -----------------------------------------------------
# ggplot in plotly umwandeln
ggplotly(P) %>%
  # Parameter der Animation spezifizieren
  animation_opts(frame = 10000, easing = "elastic", redraw = FALSE, mode = "immediate"
  ) %>%
  # Caption hinzufügen
  layout(annotations =
           list(x = 1, y = -0.1, text = "Quelle: Mehr Demokratie e.V.; Wir möchten darauf hinweisen, dass diese Übersicht trotz sorgfältiger Prüfung
                                 keine Vollständigkeit beanspruchen kann. Wenn Sie ergänzende oder korrigierende Hinweise für uns haben,
                                 nehmen wir diese gerne unter [E-Mail-Adresse] entgegen und versuchen sie so schnell wie möglich zu berücksichtigen.",
                showarrow = FALSE, xref = "paper", yref = "paper",
                xanchor = "right", yanchor = "auto", xshift = 0, yshift = 0,
                font = list(size = 15, color = "black")))

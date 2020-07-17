# install packages
packages <- c("tidyverse",
              "readr",
              "ggplot2",
              "plotly")

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

## Laden der Datensätze
# Reformen
df <- read_csv("VB_VE.csv")
str(df)

# Geodaten für Deutschland (nach Bundesländern)
ger <- readRDS("gadm36_DEU_1_sf.rds")
str(ger)

## Join mit Geodaten
# Check des Identifiers
df$NAME_1 %in% ger$NAME_1

DF <- ger %>%
  left_join(df, by = "NAME_1") %>%
  select(Jahr, NAME_1, Typ, Beschreibung, geometry) %>%
  rename(Bundesland = NAME_1) %>%
  mutate(Beschreibung = str_wrap(Beschreibung, width = 40))
  

P <- ggplot(DF) +
  # Karte an sich mit allen Bundesländern
  geom_sf(aes(geometry = geometry,
              label = Bundesland),
          lwd = 0.2) +
  # Einfärben der Bundesländer mit Reformen in einem jeweiligen Jahr
  geom_sf(aes(geometry = geometry,
              frame = Jahr,
              fill = Typ,
              label = Beschreibung),
          lwd =0.4) +
  # Layout
  theme_bw() +
  theme(legend.position = "none") +
  labs(
    x = "",
    y = "",
    title = "Reformen der Volksgesetzgebung in den Bundesländern",
    caption = "Source: Mehr Demokratie e.V.")

ggplotly(P)

## Direkt mit plotly
# https://stackoverflow.com/questions/59637672/r-changing-labels-in-an-animated-map-using-ggplotly-and-geom-sf
# https://plotly.com/r/filled-area-plots/
plot_ly(DF) %>% 
  add_sf(color = ~Typ,
         text = ~paste0("Bundesland: ", NAME_1, "\n",
                        Beschreibung),
         hoverinfo = "text",
         hoveron = "fills",
         frame = ~Jahr) %>% 
  style(hoverlabel = list(bgcolor = "white")) %>% 
  animation_opts(frame = 5000,
                 transition = 0,
                 easing = "linear",
                 redraw = TRUE,
                 mode = "immediate") %>%
  layout(title = "Reformen der Volksgesetzgebung in den Bundesländern",
         showlegend = FALSE,
         annotations =
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
                font = list(size = 12, color = "black")))

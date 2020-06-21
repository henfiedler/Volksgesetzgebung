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

# Geodaten für Deutschland (nach Bundesländern)
ger <- readRDS("gadm36_DEU_1_sf.rds")

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


DF %>%
  plot_ly(color= ~Typ,
         hoverinfo = ~Beschreibung,
         hoveron = "fills",
         frame= ~Jahr) %>%
         layout(title="Reformen in Deutschland")))


style(hoverlabel = list(bgcolor = "white")) %>% 
  animation_slider(currentvalue = list(prefix = "Jahr ")) %>%
  layout(title="Reformen")

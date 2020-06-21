# install packages
packages <- c("tidyverse",
              "readr",
              "ggplot2",
              "plotly",
              "leaflet")

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

# Laden der Datensätze

##Deutschlandkarte
ger <- readRDS("gadm36_DEU_1_sf.rds")

##Datensatz
df <- read_csv("VB_VE.csv")

# Wenn der Identifier noch umbenannt werden muss:
#df <- df %>%
#  rename(NAME_1 = Name)

#checking
df$NAME_1 %in% ger$NAME_1

# Zusammenfügen von geodaten mit dem df
DF <- df %>%
  left_join(ger, by = "NAME_1") %>%
  select(Reform, Jahr, Monat, Tag, NAME_1, Typ, Beschreibung, geometry) %>%
  rename(Bundesland = NAME_1)

#Plotten
P <- ggplot(DF) +
  geom_sf(aes(geometry = geometry,
              label = Bundesland),
          lwd = 0.2) +
  geom_sf(aes(geometry = geometry,
              frame = Jahr,
              label = Beschreibung,
              fill = Typ),
          lwd = 0.2) +
  theme_bw() +
  theme(legend.position = "none") +
  labs(
    x = "",
    y = "",
    title = "Reformen der Volksgesetzgebung in den Bundesländern",
    caption = "Source: Eigene Recherchen")

p <- ggplot(ger) +
  geom_sf(aes(),
          lwd = 0.2) +
  geom_sf(data = DF, aes(geometry = geometry,
                         frame = Jahr,
                         label = Beschreibung,
                         fill = Typ),
          lwd = 0.2) +
  theme(legend.position = "none") +
  labs(
    x = "",
    y = "",
    title = "Reformen der Volksgesetzgebung in den Bundesländern",
    caption = "Source: Eigene Recherchen")

ggplotly(p)
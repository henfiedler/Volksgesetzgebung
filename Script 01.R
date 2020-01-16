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

# loading data
df <- read_csv("VB_VE.csv")

ger <- readRDS("gadm36_DEU_1_sf.rds")

df$NAME_1 %in% ger$NAME_1

DF <- ger %>%
  left_join(df, by = "NAME_1") %>%
  mutate(NAME_1 = as.factor(NAME_1)) %>%
  filter(complete.cases(NAME_1))

P <- ggplot(DF) +
  geom_sf(aes(geometry = geometry,
              label = NAME_1),
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

ggplotly(P)

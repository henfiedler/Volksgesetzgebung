# Pakete laden ------------------------------------------------------
library("tidyverse")
library("readr")
library("plotly")

## Daten laden ------------------------------------------------------
# Reformen der Volksgesetzgebung
df <- read_csv("VB_VE.csv")

## Plot -------------------------------------------------

df1 <- df %>%
  group_by(Reform, Jahr, Bundesland, Typ, Beschreibung) %>%
  summarise(Anzahl = n()) %>%
  mutate(Beschreibung = str_wrap(Beschreibung, width = 40))

plot1 <- ggplot(df1, aes(x = Jahr, y = Anzahl,
                         fill = Bundesland,
                         text = Beschreibung)) +
  geom_bar(stat = "identity") +
  theme(legend.position = "none") +
  ggtitle("Reformen der Volksgesetzgebung in den Bundesländern") +
  labs(y = "Anzahl Reformen",
       x = "Jahre",
       caption = "Quelle: Mehr Demokratie e.V.")

# Liniendiagram
df2 <- df %>%
  group_by(Jahr) %>%
  summarise(Anzahl = n())

ggplot(df2, aes(x = Jahr, y = Anzahl)) +
  geom_line() +
  ggtitle("Reformen der Volksgesetzgebung in den Bundesländern") +
  labs(y = "Anzahl Reformen",
       x = "Jahre",
       caption = "Quelle: Mehr Demokratie e.V.")

# Interaktive Grafik
ggplotly(plot1)
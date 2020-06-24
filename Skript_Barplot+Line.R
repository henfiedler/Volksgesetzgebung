# Pakete laden ------------------------------------------------------
library("tidyverse")
library("readr")
library("plotly")

## Daten laden ------------------------------------------------------
# Reformen der Volksgesetzgebung
df <- read_csv("VB_VE.csv")

## Plot -------------------------------------------------

df1 <- df %>%
  count(Reform, Jahr, Bundesland, Typ, Beschreibung, name = "Anzahl") %>%
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

## Liniendiagram
# Anzahl Reformen nach Jahren
df2 <- df %>%
  add_count(Jahr, name = "Anzahl")

# Anzahl der Reformen nach Jahren und Bundesländern
df3 <- df %>%
  add_count(Jahr, Bundesland, name = "Anzahl") %>%
  mutate(Beschreibung = str_wrap(Beschreibung, width = 40))

ggplot(df2, aes(x = Jahr, y = Anzahl)) +
  geom_line(color = "red") +
  geom_line(data = df3, aes(x = Jahr, y = Anzahl, color = Bundesland)) +
  ggtitle("Reformen der Volksgesetzgebung in den Bundesländern") +
  labs(y = "Anzahl Reformen",
       x = "Jahre",
       caption = "Quelle: Mehr Demokratie e.V.")

# Interaktive Grafik
ggplotly(plot1)
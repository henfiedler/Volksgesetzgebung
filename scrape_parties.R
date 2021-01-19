library(tidyverse)
library(rvest)
library(lubridate)

wiki_seite <- "https://web.archive.org/web/20210117235830/https://de.wikipedia.org/wiki/Liste_der_Ministerpr%C3%A4sidenten_der_deutschen_L%C3%A4nder" %>% 
  read_html()

wiki_tabellen <- wiki_seite %>% 
  html_elements("table.wikitable") %>% 
  html_table()

laender <- wiki_tabellen[[1]][["Land"]]

laender_colnames <- wiki_tabellen %>% 
  pluck(4) %>% 
  janitor::clean_names() %>% 
  names()

laender_df <- wiki_tabellen %>% 
  magrittr::extract(c(3:11, 13:19)) %>% 
  set_names(laender) %>% 
  map(set_names, nm = laender_colnames) %>% 
  map_df(bind_rows, .id = "land") %>% 
  select(-bild) %>% 
  filter(str_detect(amtszeit, "\\d+\\. \\w+ (\\d){4}"),
         !str_detect(amtszeit, "das Land")) %>% 
  mutate(amtszeit = str_remove(amtszeit, "\\(\\d+\\.\\) ")) %>% 
  separate(amtszeit, c("amtszeit_von", "amtszeit_bis"), "–", remove = FALSE) %>% 
  mutate(across(starts_with("amtszeit_"),
                ~ dmy(.x, locale = if_else(Sys.info()[["sysname"]] == "Windows",
                                           "German", "de_DE"))))

saveRDS(laender_df, "landesregierungen.RDS")

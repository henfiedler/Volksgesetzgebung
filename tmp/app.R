library(shiny)
library(shinydashboard)
library(tidyverse)
library(ggiraph)

source(here::here("long_gg_theme.R"), echo = FALSE)

# Data --------------------------------------------------------------------

reformen <- read_csv(here::here("Reformen.csv"), col_types = "Diiicccc")


landesregierungen <- readRDS(here::here("landesregierungen.RDS")) %>% 
  filter(!(land == "Saarland" & regierung == "Verwaltungskommission")) %>% 
  mutate(amtszeit_bis = if_else(str_detect(amtszeit, "[Ss]eit") & is.na(amtszeit_bis),
                                Sys.Date(),
                                amtszeit_bis))

de_geodaten <- rnaturalearth::ne_states(country = "Germany", returnclass = "sf")

reformen <- reformen %>% 
  fuzzyjoin::fuzzy_left_join(landesregierungen %>% 
                               select(land, amtszeit_von, amtszeit_bis, partei),
                             by = c("Bundesland" = "land",
                                    "Reform" = "amtszeit_von",
                                    "Reform" = "amtszeit_bis"),
                             match_fun = list(`==`, `>=`, `<=`)) %>% 
  mutate(partei_legend = case_when(is.na(partei) ~ "parteilos",
                                   str_detect(partei, "Grüne") ~ "Grüne",
                                   str_detect(partei, "^C") ~ "CDU/CSU/CVP",
                                   TRUE ~ partei),
         partei = coalesce(partei, partei_legend)) %>% 
  left_join(de_geodaten %>% 
              as_tibble() %>% 
              select(name, iso_3166_2),
            by = c("Bundesland" = "name"))

# Timeline scatterplot base -----------------------------------------------

gg_reformen <- reformen %>%
  ggplot(aes(Reform, .5, colour = fct_infreq(partei_legend))) +
  geom_jitter_interactive(aes(data_id = Reform, tooltip = Reform),
                          size = 3) +
  labs(x = NULL, y = "Anwendungsfreundlichkeit (Fake)", colour = NULL,
       title = "Alle Reformen der Volksgesetzgebung in deutschen Bundesländern",
       subtitle = "(Die Maus über einen der Punkte halten für mehr Details)") +
  scale_colour_manual_interactive(data_id = reformen$partei_legend %>% 
                                    fct_infreq() %>% 
                                    levels() %>% 
                                    stringi::stri_enc_toutf8(),
                                  values = c("CDU/CSU/CVP" = "#000000",
                                             "FDP" = "#ffe600",
                                             "Grüne" = "#187f2b",
                                             "parteilos" = "grey",
                                             "SPD" = "#ed0020")) +
  panel_grid("XxY")

# German map base ---------------------------------------------------------

gg_karte <- de_geodaten %>% 
  ggplot() +
  geom_sf_interactive(aes(data_id = iso_3166_2, tooltip = name),
                      colour = "#f8f8f8") +
  coord_sf(expand = FALSE, label_axes = "----") +
  panel_grid(FALSE)

# UI ----------------------------------------------------------------------

ui <- dashboardPage(skin = "purple",
  
  dashboardHeader(title = "Volksgesetzgebung"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("Überblick", tabName = "ueberblick"),
      menuItem("Lorem ipsum", tabName = "loremipsum")
    )
  ),
  
  dashboardBody(
    
    tags$head(
      tags$link(href = "https://code.cdn.mozilla.net/fonts/fira.css",
                rel = "stylesheet"),
      tags$style(HTML("
        .main-header .logo {
          font-family: 'Fira Sans', sans-serif;
          font-weight: 500;
        }
        body {
          font-family: 'Fira Sans', sans-serif;
          font-variant-numeric: tabular-nums;
        }
      "))
    ),
    
    tabItems(
      
      # Tab "Überblick"
      tabItem(tabName = "ueberblick",
        
        box(width = 9, height = 720,
            ggiraphOutput("timeline", height = "700px")),
        
        box(width = 3, height = 360,
            div("Klicken, um nach Bundesland zu filtern"),
            ggiraphOutput("minikarte", height = "320px")),
        
        box(width = 3, height = 340, title = "Beschreibung",
            div(style = "overflow-y: scroll; height: 275px",
                uiOutput("reform_description")))
      ),
      
      # Tab ...
      tabItem(tabName = "loremipsum")
    )
  )
)

# Server ------------------------------------------------------------------

server <- function(input, output, session) {
  
  # Timeline scatterplot ----
  
  output$timeline <- renderggiraph({
    set.seed(2021)
    
    girafe(ggobj = gg_reformen,
           width_svg = 10, height_svg = 7,
           options = list(
             opts_hover("stroke-width: 5",
                        reactive = TRUE),
             opts_hover_inv("opacity: .15"),
             opts_hover_key("stroke-width: 5",
                            reactive = TRUE),
             opts_selection(girafe_css("stroke-width: 5",
                                       point = "fill: white"),
                            type = "single"),
             opts_selection_key(type = "none"),
             opts_tooltip(offx = 20, offy = 20),
             opts_toolbar(saveaspng = FALSE)
           ))
  })
  
  output$minikarte <- renderggiraph({
    girafe(ggobj = gg_karte,
           width_svg = 3, height_svg = 4,
           options = list(
             opts_hover(girafe_css("stroke: #605ca877; cursor: crosshair",
                                   area = "fill: #605ca877"),
                        reactive = TRUE),
             opts_selection(girafe_css("stroke: #605ca8",
                                       area = "fill: #605ca8"),
                            type = "single"),
             opts_tooltip(offx = 20, offy = 20),
             opts_toolbar(saveaspng = FALSE)
           ))
  })
  
  output$reform_description <- renderUI({
    validate(
      need(length(input$timeline_selected) == 1,
           "Bitte eine Reform auswählen")
    )
    
    reformen %>% 
      filter(Reform == input$timeline_selected) %>% 
      mutate(description = glue::glue("
        <p><b>{Bundesland} &mdash; {Typ}</b></p>
        <p><i>Amtierende Partei: {partei}</i></p>
        <p>{Beschreibung}</p>
      ")) %>% 
      pull(description) %>% 
      HTML()
  })
  
  # Interactivity between widgets ----
  
  observeEvent(input$timeline_hovered, {
    if (length(input$timeline_hovered) == 1) {
      # Hovering erases selection in timeline plot
      session$sendCustomMessage(
        type = "timeline_set",
        message = input$timeline_hovered
      )
      # Hovering in timeline -> hovering in map
      session$sendCustomMessage(
        type = "minikarte_hovered_set",
        message = reformen$iso_3166_2[reformen$Reform == input$timeline_hovered]
      )
    } else if (length(input$timeline_hovered) > 1) {
      session$sendCustomMessage(
        type = "timeline_set",
        message = character(0)
      )
      session$sendCustomMessage(
        type = "minikarte_hovered_set",
        message = character(0)
      )
    }
  })
  
  observeEvent(input$timeline_selected, {
    session$sendCustomMessage(
      type = "minikarte_set",
      message = character(0)
    )
  })
  
  observeEvent(input$timeline_key_hovered, {
    # Hovering over party legend -> hovering in timeline
    session$sendCustomMessage(
      type = "timeline_hovered_set",
      message = reformen$Reform[reformen$partei_legend == input$timeline_key_hovered]
    )
  })

  observeEvent(input$minikarte_selected, {
    # Selection in map -> hovering in timeline
    session$sendCustomMessage(
      type = "timeline_hovered_set",
      message = reformen$Reform[reformen$iso_3166_2 == input$minikarte_selected]
    )
  })
  
}

shinyApp(ui, server)

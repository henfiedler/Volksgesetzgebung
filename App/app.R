library(shiny)
library(shinydashboard)
library(tidyverse)
library(ggrepel)
library(ggiraph)

source(here::here("long_gg_theme.R"), echo = FALSE)

# Data --------------------------------------------------------------------

reformen <- read_csv(here::here("Reformen.csv"),
                     col_types = cols(Verabschiedung = col_date(format = "%Y-%m-%d"), 
                                      Inkrafttreten = col_date(format = "%Y-%m-%d"), 
                                      unterschriftenquorum_vi_abs = col_double(), 
                                      eligible_population = col_double(),
                                      unterschriftenquorum_vi = col_double(), 
                                      sammelfrist_vi = col_double(),
                                      mobilisierungskoeffizient_vi = col_double()))


landesregierungen <- readRDS(here::here("landesregierungen.RDS")) %>% 
  filter(!(land == "Saarland" & regierung == "Verwaltungskommission")) %>% 
  mutate(amtszeit_bis = if_else(str_detect(amtszeit, "[Ss]eit") & is.na(amtszeit_bis),
                                Sys.Date(),
                                amtszeit_bis))

de_geodaten <- rnaturalearth::ne_states(country = "Germany", returnclass = "sf")

timeline <- readxl::read_excel(here::here("timeline.xlsx"), col_types = c("text", "text", "text", "text")) %>% 
  mutate(datum = as.Date(datum))

reformen <- reformen %>% 
  fuzzyjoin::fuzzy_left_join(landesregierungen %>% 
                               select(land, amtszeit_von, amtszeit_bis, partei),
                             by = c("Bundesland" = "land",
                                    "Verabschiedung" = "amtszeit_von",
                                    "Verabschiedung" = "amtszeit_bis"),
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

# German map base ---------------------------------------------------------

gg_karte <- de_geodaten %>% 
  ggplot() +
  geom_sf_interactive(aes(data_id = iso_3166_2, tooltip = name),
                      colour = "#f8f8f8") +
  coord_sf(expand = FALSE, label_axes = "----") +
  theme_fira() +
  panel_grid(FALSE)

# UI ----------------------------------------------------------------------

ui <- dashboardPage(skin = "purple",
  
  dashboardHeader(title = "Volksgesetzgebung"),
  
  dashboardSidebar(
    sidebarMenu(
      selectInput("bundesland_selection", 
                  "Auswahl des Bundeslandes", 
                  choices = reformen %>% 
                    distinct(Bundesland) %>% 
                    add_row(Bundesland = "Alle") %>% 
                    arrange(Bundesland) %>% 
                    pull(),
                  selected = NULL),
      menuItem("Überblick", tabName = "ueberblick"),
      menuItem("Anzahl Reformen", tabName = "anzahl",
               menuSubItem("Nach Partei", tabName = "anzpartei"),
               menuSubItem("Nach Bundesland", tabName = "anzbundl")),
      tags$footer(
        div("Daten von ",
            a("Mehr Demokratie e.V.",
              href = "https://www.mehr-demokratie.de/")),
        align = "center",
        style = "
          position: absolute;
          bottom: 10px;
          width: 100%;
          z-index: 1000;
          font-size: small;
        "
      )
    )
  ),
  
  dashboardBody(
    
    tags$head(
      tags$link(href = "//brick.freetls.fastly.net/Fira+Sans:400,500,700,400i,500i,700i",
                rel = "stylesheet"),
      tags$style(HTML("
        .main-header .logo {
          font-family: 'Fira Sans', sans-serif;
          font-weight: 500;
        }
        .h1, .h2, .h3, .h4, .h5, .h6, h1, h2, h3, h4, h5, h6 {
          font-family: 'Fira Sans', sans-serif;
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
        
        box(width = 9, height = "90vh",
            ggiraphOutput("timeline", height = "calc(90vh - 40px)")),
        
        box(width = 3, height = "45vh",
            div("Klicken, um nach Bundesland zu filtern"),
            ggiraphOutput("minikarte", height = "calc(45vh - 40px)")),
        
        box(width = 3, height = "calc(45vh - 20px)", title = "Beschreibung",
            div(style = "overflow-y: scroll; height: calc(45vh - 85px)",
                uiOutput("reform_description")))
      ),
      
      tabItem(tabName = "anzpartei",
        
        box(width = 8,
            plotOutput("bar_partei", height = "480px"))
              
      ),
      
      tabItem(tabName = "anzbundl",
              
              box(width = 8,
                  plotOutput("bar_bundl", height = "480px"))
              
      )
    )
  )
)

# Server ------------------------------------------------------------------

server <- function(input, output, session) {
  
  # reactive input
  reformen_selected <- reactive({
    
    if (input$bundesland_selection == "Alle") {
      
      reformen
      
    } else {
      
      reformen %>% 
        filter(Bundesland == input$bundesland_selection)
      
    }
    
    })
  
  # Timeline scatterplot base -----------------------------------------------
  
  gg_reformen <- reactive({
    reformen_selected() %>%
      ggplot(aes(Verabschiedung, .5)) + 
      geom_vline_interactive(data = timeline, aes(xintercept = datum, tooltip = ereignis),
                             color = "firebrick", alpha = .5, size = 2) +
    
      #geom_text_interactive(data = timeline, aes(x = datum, y = -Inf, label = datum), 
      #                     show.legend = FALSE, size = 3) +
      
      geom_jitter_interactive(aes(data_id = Verabschiedung,
                                  tooltip = Verabschiedung,
                                  colour = fct_infreq(partei_legend)),
                              size = 3) +
      labs(x = NULL, y = "Anwendungsfreundlichkeit (Fake-Daten)", colour = NULL,
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
      theme_fira() +
      panel_grid("XxY")
  })
    
  
  # Timeline scatterplot ----
  
  output$timeline <- renderggiraph({
    set.seed(2021)
    girafe(ggobj = gg_reformen(),
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
      filter(Verabschiedung == input$timeline_selected) %>% 
      mutate(description = glue::glue("
        <p><b>{Bundesland} &mdash; {Typ}</b></p>
        <p><i>Amtierende Partei: {partei}</i></p>
        <p>{Beschreibung}</p>
      ")) %>% 
      pull(description) %>% 
      HTML()
  })
  
  output$bar_partei <- renderPlot({
  
    reformen %>% 
      group_by(partei_legend, Ver_Jahr) %>% 
      mutate(n = n()) %>% 
      ungroup() %>% 
      ggplot(aes(x = Ver_Jahr, y = n, fill = fct_infreq(partei_legend))) +
      geom_bar(position = "stack", stat = "identity", width = 1) +
      labs(x = NULL, y = "Anzahl der Reformen") +
      scale_x_continuous(breaks = seq(1950, 2020, by = 5)) +
      scale_fill_manual(reformen$partei_legend %>% 
                          fct_infreq() %>% 
                          levels() %>% 
                          stringi::stri_enc_toutf8(),
                        values = c("CDU/CSU/CVP" = "#000000",
                                   "FDP" = "#ffe600",
                                   "Grüne" = "#187f2b",
                                   "parteilos" = "grey",
                                   "SPD" = "#ed0020"))
    
  })
  
  output$bar_bundl <- renderPlot({
    
    reformen %>% 
      group_by(Bundesland, Ver_Jahr) %>% 
      mutate(n = n()) %>% 
      ungroup() %>% 
      ggplot(aes(x = Ver_Jahr, y = n, fill = fct_infreq(Bundesland))) +
      geom_bar(position = "stack", stat = "identity", width = 1) +
      labs(x = NULL, y = "Anzahl der Reformen") +
      scale_x_continuous(breaks = seq(1950, 2020, by = 5)) +
      scale_fill_discrete(reformen$Bundesland %>% 
                            fct_infreq() %>% 
                            levels() %>% 
                            stringi::stri_enc_toutf8()) +
      theme(legend.title = element_blank())
    
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
        message = reformen$iso_3166_2[reformen$Verabschiedung == input$timeline_hovered]
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
      message = reformen$Verabschiedung[reformen$partei_legend == input$timeline_key_hovered]
    )
  })

  observeEvent(input$minikarte_selected, {
    # Selection in map -> hovering in timeline
    session$sendCustomMessage(
      type = "timeline_hovered_set",
      message = reformen$Verabschiedung[reformen$iso_3166_2 == input$minikarte_selected]
    )
  })
  
}

shinyApp(ui, server)

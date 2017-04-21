source("global.R")
source("~/.postpass")
drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname = dbname, host = host, port = port, user = user, password = password)

levtidbes_cat <- dbGetQuery(con, "select distinct cat from datamart.accession_lev_tid_bes order by cat")
levtidmat_vnd <- dbGetQuery(con, "select distinct vndcustomerid from datamart.accession_lev_tid_mat")

dbDisconnect(con)

dashboardPage(
  skin = "black",
  
  dashboardHeader(
    title = "Centralbibliotek"
  ),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("Leveringstid materialer", tabName = "levtidmat", icon = icon("database", lib="font-awesome")),
      menuItem("Leveringstid res", tabName = "levtidres", icon = icon("database", lib="font-awesome")),
      menuItem("Leveringstid bestil", tabName = "levtidbes", icon = icon("database", lib="font-awesome")),
      menuItem("Dokumentation", tabName = "dokumentation", icon = icon("file-text-o", lib="font-awesome")
      )
    )
  ),
  
  dashboardBody(
    tabItems(
      
      tabItem(tabName = "levtidmat",
        
        box(width = 12,
          h3("Mål for tilgængelighed"),
          "Danske bøger skal være tilgængelige for udlån max. 17 arbejdsdage og udenlandske bøger max 25 arbejdsdage efter bestilling hos leverandør."
          ),
        
        fluidRow(
          column(3,
            box(width = 12,
              column(12,
                h4("Filtre")
              ),
              column(12,
                selectInput("dkudl", "DK/UDL:", c("Alle" = "All", "DK" = "DK", "UDL" = "UDL"))
              ),
              column(12,
                dateRangeInput('dateRange', label = 'Bestil dato fra og til', start = Sys.Date() - 365, end = Sys.Date() + 0)
              ),
              column(12,
                selectInput("vndcustomerid", "Kundenummer:", c("Alle" = "All", unique(as.character(levtidmat_vnd$vndcustomerid))))
              ),
              column(12,
                sliderInput("range", "Dage fra bestil til tilgængelig:", min = 0, max = 250, value = c(1,250))
              )
            )
          ),
          column(9,
            box(width = 4,
              h4("Rettidig/Forsinket DK"),
              plotOutput("plotmatdk")
            ),
            box(width = 4,
              h4("Rettidig/Forsinket UDL"),
              plotOutput("plotmatudl")
            ),
            box(width = 4,
              h4("Fordeling"),
              plotOutput("plot")
            ),
            box(width = 12,
              DT::dataTableOutput("tableMat")
            )   
          )
        )
      ),
      
      tabItem(tabName = "levtidres",
              
        box(width = 12,
          h3("Mål for leveringstid for reserverede overbygningsmaterialer"),
          "Målet er, at der max er 3 reserveringer pr. eksemplar. Dette gælder dog ikke bestsellere, film og lydbøger." 
        ),
              
        fluidRow(
          column(3,
            box(width = 12,
              column(12,
                h4("Filtre")
              ),
              column(12,
                selectInput("sprog", "Sprog:", c("All" = "All", "Dansk" = "dan","Norsk" = "nor"))
              )
            )
          ),
          column(9,
            box(width = 6,
              h4("Fordeling"),
              plotOutput("plotres")
            ),
            box(width = 12,
              DT::dataTableOutput("table")
            )
          )
        )
      ),
      
      tabItem(tabName = "levtidbes",
              
        box(width = 12,
          h3("Mål for leveringstid på ikke-udlånte materialer"),
          "Der må max gå 24 timer fra et materiale er bestilt til det er afsendt" 
        ),
        
        fluidRow(
          column(3,
            box(width = 12,     
              column(12,
                h4("Filtre")
              ),
              column(12,
                selectInput("year", "År:", c("Alle" = "All", "2017" = "2017","2016" = "2016","2015" = "2015" ))
              ),
              column(12,
                selectInput("week", "Bestillingsuge:", c("Alle" = "All", 1:52))
              ),
              column(12,
               selectInput("cat", "Lånerkategori:", c("Alle" = "All", unique(as.character(levtidbes_cat$cat))))
              ), 
              column(12,
                tags$b("Resultater:"), textOutput("ordersresult")
              )
              
            )
          ),
          column(9,
            box(width = 6,
              plotOutput("plotbes")
            ),
            box(width = 12,
              DT::dataTableOutput("tablebes")
            )
          )
        )
      ),
      
      tabItem(tabName = "dokumentation",
          
        box(width = 12,
          includeMarkdown("www/doc.md")
        )
      )
      
    )
  )
)
source("global.R")

shinyServer(function(input, output) {

  source("~/.postpass")
  drv <- dbDriver("PostgreSQL")
  con <- dbConnect(drv, dbname = dbname, host = host, port = port, user = user, password = password)
  
  levtidmat <- dbGetQuery(con, "SELECT * FROM datamart.accession_lev_tid_mat")
  levtidres <- dbGetQuery(con, "SELECT * FROM datamart.accession_lev_tid_res where r_pr_e > 3")
  rescount <- dbGetQuery(con, "SELECT (case when r_pr_e  > 3 then 'suppleres' else 'ok' end) as status, sprog FROM datamart.accession_lev_tid_res")
  levtidbes <- dbGetQuery(con, "SELECT * FROM datamart.accession_lev_tid_bes")
  
  dbDisconnect(con)
  
  # reserveringer
  
  output$plotmatdk <- renderPlot({
    data <- levtidmat
    data <- data[data$dkudl == 'DK',]
    data <- data[data$orddate > input$dateRange[1] & data$orddate < input$dateRange[2],]
    if (input$vndcustomerid != "All") {
      data <- data[data$vndcustomerid == input$vndcustomerid,]
    }
    slices <- c(sum(data$dage > 17), sum(data$dage <= 17 & data$dage > 0), sum(data$dage == 0))
    lbls <- c("Forsinket", "Rettidig", "Ikke Leveret")
    pct <- round(slices/sum(slices)*100)
    lbls <- paste(lbls, pct)
    lbls <- paste(lbls,"%",sep="")
    pie(slices, labels = lbls)
  })
  
  output$plotmatudl <- renderPlot({
    data <- levtidmat
    data <- data[data$dkudl == 'UDL',]
    data <- data[data$orddate > input$dateRange[1] & data$orddate < input$dateRange[2],]
    if (input$vndcustomerid != "All") {
      data <- data[data$vndcustomerid == input$vndcustomerid,]
    }
    slices <- c(sum(data$dage > 25), sum(data$dage <= 25 & data$dage > 0), sum(data$dage == 0))
    lbls <- c("Forsinket", "Rettidig", "Ikke Leveret")
    pct <- round(slices/sum(slices)*100)
    lbls <- paste(lbls, pct)
    lbls <- paste(lbls,"%",sep="")
    pie(slices, labels = lbls)
  })
  
  output$plot <- renderPlot({
    x    <- levtidmat$dage
    bins <- seq(min(x), max(x), length.out = 25)
    hist(x, breaks = bins, xlab = 'Dage', main = '', ylab="Antal")
  })
  
  output$tableMat <- DT::renderDataTable(DT::datatable({
    data <- levtidmat
    if (input$dkudl != "All") {
      data <- data[data$dkudl == input$dkudl,]
    }
    if (input$vndcustomerid != "All") {
      data <- data[data$vndcustomerid == input$vndcustomerid,]
    }
    data <- data[data$orddate > input$dateRange[1] & data$orddate < input$dateRange[2],]
    data <- data[data$dage > input$range[1] & data$dage < input$range[2],]
    data
  }, 
  class = 'cell-border stripe',
  rownames = FALSE,
  colnames = c('Acqno', 'Kundenummer', 'UDL/DK', 'Bestil','Dage')
  ))
  
  # reserveringer
  output$table <- DT::renderDataTable(DT::datatable({
    data <- levtidres
    if (input$sprog != "All") {
      data <- data[data$sprog == input$sprog,]
    }
    data
  }))
  
  output$plotres <- renderPlot({
    data <- rescount
    if (input$sprog != "All") {
      data <- data[data$sprog == input$sprog,]
    }
    slices <- c(sum(data$status == 'suppleres'), sum(data$status == 'ok'))
    lbls <- c("Suppleres", "Ok")
    pct <- round(slices/sum(slices)*100)
    lbls <- paste(lbls, pct) # add percents to labels 
    lbls <- paste(lbls,"%",sep="") # ad % to labels 
    pie(slices, labels = lbls)
  })
  
  ### ORDERS ###  
  
  # count rows i dataframe #
  
  output$ordersresult <- renderText ({
    data <- levtidbes
    if (input$year != "All") {
      data <- data[data$year == input$year,]
    }
    if (input$cat != "All") {
      data <- data[data$cat == input$cat,]
    }
    if (input$week != "All") {
      data <- data[data$week == input$week,]
    }
    data <- count(data)
    data <- toString(data)
  })
  
  # 
  
  output$plotbes <- renderPlot({
    data <- levtidbes
    if (input$year != "All") {
      data <- data[data$year == input$year,]
    }
    if (input$cat != "All") {
      data <- data[data$cat == input$cat,]
    }
    if (input$week != "All") {
      data <- data[data$week == input$week,]
    }
    slices <- c(sum(data$days == 0), sum(data$days == 1, sum(data$days > 1)))
    lbls <- c("1 dag", "2 dage", "over 2 dage")
    pct <- round(slices/sum(slices)*100)
    lbls <- paste(lbls, pct) # add percents to labels 
    lbls <- paste(lbls,"%",sep="") # ad % to labels 
    pie(slices, labels = lbls, main="Leveringsdage")
  })
  
  output$tablebes <- DT::renderDataTable(DT::datatable({
    data <- levtidbes
    if (input$year != "All") {
      data <- data[data$year == input$year,]
    }
    if (input$week != "All") {
      data <- data[data$week == input$week,]
    }
    if (input$cat != "All") {
      data <- data[data$cat == input$cat,]
    }
    data
    
  },
    class = 'cell-border stripe',
    rownames = FALSE,
    options = list(pageLength = 100, dom = 'tip'),
    colnames = c('År', 'Uge','Resno', 'Cat', 'Bestil','Lev','Tid','Dage')))
  
})
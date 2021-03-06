#shinytse4navbar/server.r
#andy south 27/08/2014

#testing adding a navbar to phase2 grid & movement
#most changes are in ui.r not server

#to run type this in R console
#setwd('C:\\Dropbox\\Ian and Andy\\andy\\shiny\\')
#library(shiny)
#runApp('shinytse4')

library(rtsetse)

library(shiny)
library(raster)
#i don't see why these are needed when they are imported by rtsetse but seems they are
library(ggplot2) 
library(reshape2)
library(plyr)
#library(dplyr)
library(abind) 

#to read in a csv
#inFile <- "top5000.csv" 
#dFglobList <- read.csv(inFile,as.is=TRUE)

## can put functions here


#run the model once before start with minimal params
#to initiate the global output object
#output <- rtPhase2Test(nRow=1,nCol=1,iDays=1)
output <- rtPhase2Test2(nRow=1,nCol=1,iDays=1,report = NULL)

#the output is structured like this
#num [1:5, 1:100, 1:100, 1:2, 1:7] 0 0 0 0 0 0 0 0 0 0 ...
#..$ : chr [1:5] "day0" "day1" "day2" "day3" ...
#..$ : chr [1:100] "x1" "x2" "x3" "x4" ...
#..$ : chr [1:100] "y1" "y2" "y3" "y4" ...
#..$ : chr [1:2] "F" "M"
#..$ : chr [1:7] "age1" "age2" "age3" "age4" ...


shinyServer(function(input, output) {

  
  #in shinytse3 the output is different to shinytse2
  #it's now a multi-dimensional array
  #[day,x,y,ages] just for F to start
  v <- reactiveValues( output=output ) 
  
  
  runModel <- reactive({
    
    cat("in runModel input$iDays=",input$iDays,"\n")
    
    #without mention of input$ params in here
    #this doesn't run even when the Run button is pressed
    #so this is a temporary workaround
    if ( input$iDays > 0 )
    {

      v$output <- rtPhase2Test2(nRow = input$nRow,
                               nCol = input$nCol,
                               pMove = input$pMove,
                               iDays = input$iDays,
                               pMortF = input$pMortF,
                               pMortM = input$pMortM, 
                               pMortPupa = input$pMortPupa,
                               iPupaDensThresh = input$iPupaDensThresh,
                               fSlopeDD = input$fSlopeDD,
                               iStartAges = input$iStartAges,
                               iStartAdults = input$iStartAdults )   
                               #iStartPupae = "sameAsAdults",
                               #iCarryCap = input$iCarryCap,
                               #iMaxAge = 120,
                               #report = NULL )
                               
#                                propMortAdultDD = input$propMortAdultDD,
#                                iMaxAge = input$iMaxAge,
#                                iFirstLarva = input$iFirstLarva,
#                                iInterLarva = input$iInterLarva,
#                                pMortLarva = input$pMortLarva,        
#                                propMortLarvaDD = input$propMortLarvaDD,
#                                pMortPupa = input$pMortPupa,
#                                propMortPupaDD = input$propMortPupaDD,                          
#                                verbose=FALSE)
      
    }
    
       
  })
  

###############################
# plotting pop maps for MF
output$plotMapDays <- renderPlot({
  
  #needed to get plot to react when button is pressed
  runModel()
  
  #browser()
  
  cat("in plotMapDays input$iDays=",input$iDays,"\n")
  
  rtPlotMapPop(v$output, days='all', ifManyDays = 'spread', sex='MF')
})  

###############################
# plotting pop maps for F (not used currently)
output$plotMapDaysF <- renderPlot({
  
  #needed to get plot to react when button is pressed
  runModel()
  
  cat("in plotMapDaysF input$iDays=",input$iDays,"\n")
  
  rtPlotMapPop(v$output, days='all', ifManyDays = 'spread', sex='F')
})  


###############################
# plot pop map for final day
output$plotMapFinalDay <- renderPlot({
  
  #needed to get plot to react when button is pressed
  runModel()
  
  cat("in plotMapFinalDay input$iDays=",input$iDays,"\n")
  
  rtPlotMapPop(v$output, days='final', sex='MF')
   
})  


###############################
# plot total adult population & by M&F for whole grid
output$plotPopGrid <- renderPlot({
  
  #needed to get plot to react when button is pressed
  #i'm not quite sure why, i thought it might react to v changing
  runModel()
  
  cat("in plotPopGrid input$iDays=",input$iDays,"\n")

  rtPlotPopGrid(v$output,"Adult Flies") 
  #print( rtPlotPopGrid(v$output,"Adult Flies") )
  
  
})  

###############################
# plot mean age of adults
output$plotMeanAgeGrid <- renderPlot({
  
  runModel()
  
  cat("in plotMeanAgeGrid input$iDays=",input$iDays,"\n")
  
  rtPlotMeanAgeGrid(v$output)
  
})  

#########################################
# download a report
# code from: http://shiny.rstudio.com/gallery/download-knitr-reports.html
# the report format is set by a Rmd file in the shiny app folder
# note this doesn't use the reporting function from rtsetse

output$downloadReport <- downloadHandler(
#this was how to allow user to choose file
#   filename = function() {
#     paste('my-report', sep = '.', switch(
#       input$format, PDF = 'pdf', HTML = 'html', Word = 'docx'
#     ))
#   },
  
  # name of the report file to create
  filename = "rtsetsePhase2Report.html",
  
  content = function(file) {
    
    #name of the Rmd file that sets what's in the report
    filenameRmd <- 'rtReportPhase2fromShiny.Rmd'
    
    src <- normalizePath(filenameRmd)
    
    # temporarily switch to the temp dir, in case you do not have write
    # permission to the current working directory
    owd <- setwd(tempdir())
    on.exit(setwd(owd))
    file.copy(src, filenameRmd)
    
    library(rmarkdown)

#this allowed rendering in pdf,html or doc
#     out <- render(filenameRmd, switch(
#       input$format,
#       PDF = pdf_document(), HTML = html_document(), Word = word_document()
#     ))

    #rendering in html only
    out <- render(filenameRmd, html_document())    
    
    file.rename(out, file)
  }
)

###############################
# test plotting of inputs
output$testInputs <- renderText({
  
  #needed to get plot to react when button is pressed
  #i'm not quite sure why, i thought it might react to v changing
  runModel()
  
  cat("in testInputs() input$iDays=",input$iDays,"\n")
  
  lNamedArgs <- isolate(reactiveValuesToList(input))
  
  #print(unlist())
  
  #names(lNamedArgs)[ names(lNamedArgs)!='iStartAges' ]
  #cool the below works to omit 2 sets of vars, can use similar code in the report Rmd
  names(lNamedArgs)[ substring(names(lNamedArgs),1,2)!='iS' & substring(names(lNamedArgs),1,2)!='pM' ]
  
})  

###############################
# plot age structure summed for M&F across whole grid 
output$plotAgeStruct <- renderPlot({
  
  #needed to get plot to react when button is pressed
  runModel()
  
  cat("in plotAgeStruct input$iDays=",input$iDays,"\n")
  
  rtPlotAgeStructure(v$output,"M & F")
  
})  

#############################
#functions after here are from shintse2 and probably don't work anymore
 
  ###############################
  # plot female age structure
  output$plotAgeStructF <- renderPlot({
        
    #needed to get plot to react when button is pressed
    #i'm not quite sure why, i thought it might react to v changing
    runModel()
    
    cat("in plotAgeStructF input$iDays=",input$iDays,"\n")
    
    rtPlotAgeStructure(v$output$dfRecordF,"Females")
    
  })  

  ###############################
  # plot male age structure
  output$plotAgeStructM <- renderPlot({
    
    #needed to get plot to react when button is pressed
    #i'm not quite sure why, i thought it might react to v changing
    runModel()
    
    cat("in plotAgeStructM input$iDays=",input$iDays,"\n")
    
    rtPlotAgeStructure(v$output$dfRecordM,"Males")
    
  })    
  
  ###############################
  # plot total adult population
  output$plotPop <- renderPlot({
    
    #needed to get plot to react when button is pressed
    #i'm not quite sure why, i thought it might react to v changing
    runModel()
    
    cat("in plotPop input$iDays=",input$iDays,"\n")
        
    #rtPlotPop(v$output$dfRecordF + v$output$dfRecordF,"Adult Flies")
    
    rtPlotPopAndPupae(v$output$dfRecordF, v$output$dfRecordM, v$output$dfRecordPupaF, v$output$dfRecordPupaM)
    
  })  

 
  ###############################
  # plot mean age of adults
  output$plotMeanAge <- renderPlot({
    
    runModel()
    
    cat("in plotMeanAge input$iDays=",input$iDays,"\n")
    
    rtPlotMeanAge(v$output$dfRecordF, v$output$dfRecordM,title="Mean age of adult flies")
        
  })    
  
  
}) # end of shinyServer()

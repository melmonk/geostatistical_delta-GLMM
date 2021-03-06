library(shiny)

# Load stuff
source( "Plot_Points_and_Bounds_Fn.R" )
load( file="database/Results-speciesDF.RData" )
load( file="database/Results-indexDF.RData" )
load( file="database/Results-cogDF.RData" )

# Global settings
interval_width = 1

# Function containing things to display
function(input, output, session){

  #### Dynamic user inputs
  # The following reactive function would return the column variable names corresponding to the dataset selected by the user.
  species_subset <- reactive({
    rows_subset <- which(speciesDF[,'Region']==input$region)
    if( input$species_category=="fish" ) rows_subset <- rows_subset[which(tolower(speciesDF[rows_subset,'Phylum'])=="chordata")]
    if( input$species_category=="top10fish" ){
      rows_subset <- rows_subset[which(tolower(speciesDF[rows_subset,'Phylum'])=="chordata")]
      rows_subset <- rows_subset[order(speciesDF[rows_subset,'average_density'],decreasing=TRUE)][1:min(length(rows_subset),10)]
    }
    speciesDF[rows_subset,'Sci']
  })
  # Checkbox -- select species from group
  output$speciesSelex <- renderUI({
    Names = paste0(species_subset(), "  (", speciesDF[match(species_subset(),speciesDF[,'Sci']), 'Common'], ")")
    checkboxGroupInput(inputId="species2plot", label=NULL, choices=Names, selected=Names)
  })
  # Action button -- unselect all species
  observeEvent( eventExpr=input$unselect_all, handlerExpr={          # "Species to show"
    Names = paste0(species_subset(), "  (", speciesDF[match(species_subset(),speciesDF[,'Sci']), 'Common'], ")")
    updateCheckboxGroupInput( session, inputId="species2plot", label=NULL, choices=Names, selected=NULL )
  })
  # Textbox -- search for species from group
  observeEvent( eventExpr=input$species_match, handlerExpr={
    Full_Names = apply( speciesDF[match(species_subset(),speciesDF[,'Sci']),c("Class","Order","Family","Sci","Common")], FUN=paste, collapse=" ", MARGIN=1)
    Names = paste0(species_subset(), "  (", speciesDF[match(species_subset(),speciesDF[,'Sci']), 'Common'], ")")
    Names2Select = grep( tolower(input$species_match), tolower(Full_Names) )
    updateCheckboxGroupInput( session, inputId="species2plot", label=NULL, choices=Names, selected=Names[Names2Select] )
  })

  # Select species for mapping animation
  output$speciesMapSelex <- renderUI({
    selectInput(inputId="species2animate", label="Species to map", choices=species_subset(), selected=species_subset()[1], multiple=FALSE)
  })

  # Select years for mapping animation
  Num_years <- reactive({
    dir <- paste0("database/Image-",input$region,"-",input$species2animate,"/")
    length( list.files(dir) )
  })
  output$sliderSelex <- renderUI({
    sliderInput(inputId="sliderNum", label="Year of animation", min=1, max=Num_years(), value=1, step=1, animate=animationOptions(interval=500, loop=FALSE, playButton="PLAY", pauseButton="PAUSE"))
  })

  #### Plots
  # Plot abundance index
  output$plot1 <- renderPlot({
    input$activate
    #isolate({
      par( xaxs="i", yaxs="i" )
      species2plot = sapply( input$species2plot, FUN=function(Char){strsplit(Char,'  ')[[1]][1]})
      # Ylim = c(0, max(indexDF[which(indexDF[,'Region']==input$region),'Index'])*1.2)
      Ylim = c(0, max(indexDF[which(indexDF[,'Species']%in%species2plot & indexDF[,'Region']==input$region),'Index'])*1.2)
      plot( 1, type="n", xlim=range(indexDF[which(indexDF[,'Region']==input$region),'Year']), ylim=ifelse(abs(Ylim)==Inf,1,Ylim), xlab="Year", ylab="Population biomass (relative to average in the survey)", main="Indices of population abundance")
      for( sI in 1:length(species2plot)){
        Tmp = indexDF[ which(indexDF[,'Species']==species2plot[sI] & indexDF[,'Region']==input$region), ]
        if(input$plotCI==FALSE) lines( y=Tmp[,'Index'], x=Tmp[,'Year'], type="b", col=rainbow(length(species2plot))[sI] )
        if(input$plotCI==TRUE) Plot_Points_and_Bounds_Fn( y=Tmp[,'Index'], x=Tmp[,'Year'], ybounds=(Tmp[,'Index']%o%c(1,1))*exp(Tmp[,'SD..log.']%o%c(-interval_width,interval_width)), type="b", col=rainbow(length(species2plot))[sI], col_bounds=rainbow(length(species2plot),alpha=0.2)[sI], bounds_type="shading")
      }
      if(length(species2plot)>0 & length(species2plot)<50) legend( "top", legend=species2plot, fill=rainbow(length(species2plot)), bty="n", ncol=min(4,ceiling(sqrt(length(species2plot)))) )
    #})
  })

  # Plot northward COG
  output$plot2 <- renderPlot({
    input$activate
    #isolate({
      par( xaxs="i" )
      Range = function(vec, buffer=0.2){ range(vec) + c(0,0.2)*diff(range(vec)) }
      species2plot = sapply( input$species2plot, FUN=function(Char){strsplit(Char,"  ")[[1]][1]})
      plot( 1, type="n", xlim=range(cogDF[which(cogDF[,'Region']==input$region),'Year']), ylim=Range(cogDF[which(cogDF[,'Region']==input$region),'North.COG_hat']%o%c(1,1)+(cogDF[which(cogDF[,'Region']==input$region),'North.SE']%o%c(-interval_width,interval_width))), xlab="Year", ylab="kilometers north of equator", main="Northward center-of-gravity")
      for( sI in 1:length(species2plot)){
        Tmp = cogDF[ which(cogDF[,'Species']==species2plot[sI] & cogDF[,'Region']==input$region), ]
        if(input$plotCI==FALSE) lines( y=Tmp[,'North.COG_hat'], x=Tmp[,'Year'], type="b", col=rainbow(length(species2plot))[sI])
        if(input$plotCI==TRUE) Plot_Points_and_Bounds_Fn( y=Tmp[,'North.COG_hat'], x=Tmp[,'Year'], ybounds=(Tmp[,'North.COG_hat']%o%c(1,1))+(Tmp[,'North.SE']%o%c(-interval_width,interval_width)), type="b", col=rainbow(length(species2plot))[sI], col_bounds=rainbow(length(species2plot),alpha=0.2)[sI], bounds_type="shading")
      }
      if(length(species2plot)>0 & length(species2plot)<50) legend( "top", legend=species2plot, fill=rainbow(length(species2plot)), bty="n", ncol=min(4,ceiling(sqrt(length(species2plot)))) )
    #})
  })

  # Plot eastward COG
  output$plot3 <- renderPlot({
    input$activate
    #isolate({
      par( xaxs="i" )
      species2plot = sapply( input$species2plot, FUN=function(Char){strsplit(Char,'  ')[[1]][1]})
      plot( 1, type="n", xlim=range(cogDF[which(cogDF[,'Region']==input$region),'Year']), ylim=range(cogDF[which(cogDF[,'Region']==input$region),'East.COG_hat']%o%c(1,1)+(cogDF[which(cogDF[,'Region']==input$region),'East.SE']%o%c(-interval_width,interval_width))), xlab="Year", ylab="kilometers east of regional reference", main="Eastward center-of-gravity")
      for( sI in 1:length(species2plot)){
        Tmp = cogDF[ which(cogDF[,'Species']==species2plot[sI] & cogDF[,'Region']==input$region), ]
        if(input$plotCI==FALSE) lines( y=Tmp[,'East.COG_hat'], x=Tmp[,'Year'], type="b", col=rainbow(length(species2plot))[sI])
        if(input$plotCI==TRUE) Plot_Points_and_Bounds_Fn( y=Tmp[,'East.COG_hat'], x=Tmp[,'Year'], ybounds=(Tmp[,'East.COG_hat']%o%c(1,1))+(Tmp[,'East.SE']%o%c(-interval_width,interval_width)), type="b", col=rainbow(length(species2plot))[sI], col_bounds=rainbow(length(species2plot),alpha=0.2)[sI], bounds_type="shading")
      }
    #})
  })

  # Disply species
  #output$debug_text <- renderPrint({
  #  dir <- paste0("database/Image-",input$region,"-",input$species2animate,"/")
  #  paste0(dir,list.files(dir)[input$sliderSelex])
  #})

  # Plot animation images
  output$image1 <- renderImage({
    dir <- paste0("database/Image-",input$region,"-",input$species2animate,"/")
    list(src=paste0(dir,list.files(dir)[input$sliderNum]), contentType="image/png", alt="Maps") # , width=600, height="auto"
  }, deleteFile=FALSE)

  # Plot global coverage image
  output$image2 <- renderImage({
    list(src="global_coverage.png", contentType="image/png", alt="Global coverage", width="100%", height="auto") #
  }, deleteFile=FALSE)

  # Table of credits
  output$table1 <- renderTable({
    Sys.setlocale('LC_ALL','C')
    read.csv("Acknowledgements_for_regional_inputs.csv")
  },  include.rownames=FALSE )
}

#' @export
PlotResultsOnMap_Fn <-
function(MappingDetails, Report, Nknots=Inf, PlotDF, MapSizeRatio, Xlim, Ylim, FileName, Year_Set=NULL, Years2Include=NULL, plot_set=1:5,
         Rescale=FALSE, Rotate=0, Format="png", Res=200, zone=NA, Cex=0.01, add=FALSE, textmargin=NULL, pch=NULL, ...){

  # Fill in missing inputs
  if( is.null(Year_Set) ) Year_Set = 1:ncol(Report$D_xt)
  if( is.null(Years2Include) ) Years2Include = 1:ncol(Report$D_xt)

  # Extract elements
  plot_codes <- c("Pres", "Pos", "Dens", "Pos_Rescaled", "Dens_Rescaled", "Eps_Pres", "Eps_Pos", "LinPred_Pres", "LinPred_Pos")
  if( is.null(textmargin)){
    textmargin <- c("Probability of encounter", "Density, ln(kg. per square km.)", "Density, ln(kg. per square km.)", "", "", "", "", "", "")
  }

  # Select locations to plot
  if( Nknots<Inf ){
    NN_plot = RANN::kmeans(x=PlotDF[,c("Lon","Lat")], centers=Nknots, iter.max=50, nstart=2, trace=0)
    Match = match( 1:Nknots, NN_plot$cluster)
    PlotDF = PlotDF[Match,]
    message( "Restricted plotting locations to ", Nknots, " locations" )
  }

  # Loop through plots
  for(plot_num in plot_set){
    if(plot_num==1){
      # Presence/absence ("Pres")
      Mat = Report$R1_xt
    }
    if(plot_num==2){
      # Positive values ("Pos")
      Mat = log(Report$R2_xt)
      Mat = ifelse(Mat<(-5),-5,Mat)
    }
    if(plot_num==3){
      # Density ("Dens")
      Mat = log(Report$D_xt)
      Mat = ifelse(Mat<(-5),-5,Mat)
    }
    if(plot_num==4){
      # Positive values rescaled ("Pos_Rescaled")
      Mat = log(Report$R2_xt+quantile(Report$R2_xt,0.25))
    }
    if(plot_num==5){
      # Density rescaled ("Dens_Rescaled")
      Mat = log(Report$D_xt+quantile(Report$D_xt,0.25))
    }
    if(plot_num==6){
      # Epsilon for presence/absence ("Eps_Pres")
      Mat = Report$Epsilon1_st
    }
    if(plot_num==7){
      # Epsilon for positive values ("Eps_Pos")
      Mat = Report$Epsilon2_st
    }
    if(plot_num==8){
      # Linear predictor for probability of encounter
      Mat = Report$P1_xt
    }
    if(plot_num==9){
      # Linear predictor for positive catch rates
      Mat = Report$P2_xt
    }
    # Do plot
    Return = SpatialDeltaGLMM:::PlotMap_Fn( MappingDetails=MappingDetails, Mat=Mat[,Years2Include], PlotDF=PlotDF, MapSizeRatio=MapSizeRatio, Xlim=Xlim, Ylim=Ylim, FileName=paste0(FileName,plot_codes[plot_num]), Year_Set=Year_Set[Years2Include], Rescale=Rescale, Rotate=Rotate, Format=Format, Res=Res, zone=zone, Cex=Cex, textmargin=textmargin[plot_num], add=add, pch=pch, ...)
  }          #
  return( invisible(Return) )
}

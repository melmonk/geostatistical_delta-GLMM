

#devtools::install_github("nwfsc-assess/geostatistical_delta-GLMM")
library( SpatialDeltaGLMM )
library( maps )

# Plot global coverage of database
png( file="C:/Users/James.Thorson/Desktop/Project_git/geostatistical_delta-GLMM/examples/global_coverage.png", width=8, height=4, res=200, units="in")
  map( "worldHires", mar=c(4,4,2,0), mgp=c(2,0.5,0), tck=-0.02, oma=c(2,2,0,0), xaxs="i", yaxs="i" )
  box()
  axis(1)
  axis(2)
  mtext( side=1:2, outer=TRUE, text=c("Longitude", "Latitude"))

  # Get extrapolation data
  for(i in 1:8 ){
    if(i==1) Extrapolation_List = Prepare_WCGBTS_Extrapolation_Data_Fn( strata.limits=data.frame('STRATA'="All_areas") )
    if(i==2) Extrapolation_List = Prepare_BC_Coast_Extrapolation_Data_Fn( strata.limits=data.frame('STRATA'="All_areas"), strata_to_use=c("SOG","WCVI","QCS","HS","WCHG") )
    if(i==3) Extrapolation_List = Prepare_EBS_Extrapolation_Data_Fn( strata.limits=data.frame('STRATA'="All_areas") )
    if(i==4) Extrapolation_List = Prepare_GOA_Extrapolation_Data_Fn( strata.limits=data.frame('STRATA'="All_areas") )
    if(i==5) Extrapolation_List = Prepare_NWA_Extrapolation_Data_Fn( strata.limits=data.frame('STRATA'="All_areas") )
    if(i==6) Extrapolation_List = Prepare_SA_Extrapolation_Data_Fn( strata.limits=data.frame('STRATA'="All_areas"), region=c("south_coast","west_coast") )
    if(i==7){
      data( iceland_cod )
      Data_Geostat = data.frame( "Catch_KG"=iceland_cod[,'Catch_b'], "Year"=iceland_cod[,'year'], "Vessel"=1, "AreaSwept_km2"=iceland_cod[,'towlength'], "Lat"=iceland_cod[,'lat1'], "Lon"=iceland_cod[,'lon1'])
      Data_Geostat = na.omit( Data_Geostat )
      Extrapolation_List = Prepare_Other_Extrapolation_Data_Fn( strata.limits=data.frame('STRATA'="All_areas"), observations_LL=Data_Geostat[,c('Lat','Lon')], maximum_distance_from_sample=15 )
    }
    if(i==8) Extrapolation_List = Prepare_GSL_Extrapolation_Data_Fn( strata.limits=data.frame('STRATA'="All_areas") )

    # Plot
    Which = which( Extrapolation_List$a_el>0 )
    points( Extrapolation_List$Data_Extrap[Which,c('Lon','Lat')], pch=20, cex=0.01, col=rainbow(8)[i])
  }
dev.off()
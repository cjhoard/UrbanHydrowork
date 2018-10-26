# General script for Rainmaker using AQ exported rainfall data

# This script is written for the user to change a few settings at the top, 
# then run the remainder of the script without needing to make any further changes.
#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***
    #***#***#***#***#***#***#***#***#***#***#***#***# SETTINGS/PREFERENCES  #***#***#***#***#***#***#***#***#***#***#***#***#***#***
        #***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***
# 
    # Set working directory to folder with unit-value rainfall data exported from AQ
        setwd("H:/R/Rainmaker") # <-- insert your file path here
    # Name of the unit-value rainfall data exported from AQ
        rain.filename <- "Open.csv" # <-- insert your file name here ***MUST BE EXPORTED FROM AQ TO WORK IN THIS SCRIPT***
    # Time between events in hours (interevent)
        ieHr <- 6
    # Amount it must rain to count as an event in tenths of inches (rain threshold)
        rainthresh <- 0.05
    # Antecedent Rainfall in days (ARF.days)
        ARF.days = c(0.5, 1, 2, 3, 5, 10, 15, 20)
    # Output filename
        output = "StormSummary.csv" # <-- insert what you want to name the output file here
        
# FYI - The Rainmaker workflow follows this path:
    # - 1 Aquire precipitation data
    # - 2 Prepare the data for use in `Rainmaker`
    # - 3 Determine precipitation event start and end times using `RMevents`
    # - 4 Compute intensities using `RMintensity`
    # - 5 Compute erosivity index using `RMerosivity`
    # - 6 Compute antecedent rainfall using `RMarf`
    # - 7 Output the results to a file
         
#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***
    #***#***#***#***#***#***#***#***#***#***#***#***# SELECT ALL BELOW THIS LINE AND RUN#***#***#***#***#***#***#***#***#***#***#***
        #***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***
# Check for Rainmaker updates
    devtools::install_github("USGS-R/Rainmaker")

# Turn on Rainmaker package
    library("Rainmaker")

# - 1 Aquire precipitation data
      # Load rainfall in .csv format
        Rain.uv <- read.csv(file=rain.filename,skip=15,col.names = c("UTC", "GMT.Time", "rain", "x", "y", "z"))
    
# - 2 Prepare the data for use in Rainmaker
        Rain.prep <- RMprep(df=Rain.uv,date.type = 2)

# - 3 Determine precipitation event start and end times        
        Rain.events <- RMevents(df=Rain.prep, ieHr=ieHr, rainthresh=rainthresh, rain="rain", time="pdate")
        Rain.event.list <- Rain.events$storms2
        tipsbystorm <- Rain.events$tipsbystorm

# - 4 Compute intensities
        StormSummary <- RMintensity(df=Rain.prep, date="pdate", df.events=Rain.event.list, depth="rain", xmin=c(5,10,15,30,60))

# - 5 Compute erosivity index
        StormSummary <- RMerosivity(df=tipsbystorm, ieHr=ieHr, rain="rain", method=1, StormSummary=StormSummary)
      
# - 6 Compute antecedent rainfall using `RMarf`
        ARF <- RMarf(df=Rain.prep, date = "pdate", df.events=Rain.event.list, days = ARF.days, varnameout = "ARF")
        StormSummary <- merge(StormSummary,ARF)
# - 7 Output the results to a file
        write.csv(StormSummary,file=output,row.names = FALSE)
#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***#***
        
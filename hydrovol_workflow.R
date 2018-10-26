# This Generic Hydrovol Workflow requires:
# 1. Aquarius unit value discharge export
# 2. Start and end dates and times in a separate .csv file
    # example format: mm/dd/YYYY hh:mm,mm/dd/YYYY hh:mm

    # start,finish
    # 09/01/2017 00:45:00,09/03/2017 04:30:00
    # 09/05/2017 02:15:00,09/07/2017 13:15:00
    # 09/08/2017 14:15:00,09/09/2017 08:30:00
    # 09/12/2017 07:15:00,09/27/2017 13:00:00

# It assumes both these files are in the same folder 

# ----------------- #
#     USER INPUT    #
# Timezone
    tz="Etc/GMT-6" 
    #This is the timezone-code for CST all year-round, if the data observe daylight savings, use "America/Chicago"

# INPUT FILE FOLDER
  # Insert the route to the folder with the two input files:
    input.folder <- "Z:/R/HydroVol/" 

# UNIT VALUE DISCHARGE FILENAME
  # Insert the unit value discharge data filename:
    input.uv <- "Holly_Q.csv"

# START and END DATE FILENAME
    input.time <- "Holly_times.csv"

# OUTPUT FILENAME
    output.file <- "hydrovol_output.csv"

# END OF USER INPUT #
# ----------------- #

# Initial setup - 
# Only need to do this section the first time through
  library("USGSHydroTools")
  library("Rainmaker")
    
  # Check for Rainmaker updates
    devtools::install_github("USGS-R/Rainmaker")
    
  # Turn off scientific notation, set to zero (0) to turn on scientific notation
    options(scipen=999) 

# end of initial setup
# ----------------- #

# INPUT FILE FOLDER
    setwd(input.folder) 

# UNIT VALUE FILENAME
    input.uv <- read.csv(file = input.uv,skip=15,
                     col.names = c("UTC", "GMT.Time", "Q", "x", "y", "z")) 

# Insert the filename for a .csv with one column for start and one column for end in format: 
    input.time <- read.csv(file = input.time,col.names = c("begin", "end")) 

# Use RMprep to convert timestamps to POSIXct
#   This function prepares data files for Rainmaker functions. Dates are transformed to as.POSIXct 
#   dates using the as.POSIXct function. Multiple common date formats are included as options for 
#   tranformation. The original date column is transformed to a character variable. Column header 
#   names are changed to desired names.
#
# Identify what format the date and time are in, then pick the corresponding date.type
# (Data exported from Aquarius are in the date.type 2 format)
#
#   - 1 mm/dd/YYYY hh:mm
#   - 2 YYYY-mm-ddTHH:MM
#   - 3 Date colmun: m/d/Y AND time column: h:mm
#   - 4 4 columns, Year, Month, Day and Minute
#   - 5 Date column: YYYYMMDD AND Time column H:MM

    input.uv <- RMprep(df=input.uv, date.type = 2, tz = tz)
    input.time <- RMprep(df=input.time, date.type = 1, dates.in = "begin", dates.out = "bpdate",tz=tz)
    input.time <- RMprep(df=input.time, date.type = 1, dates.in = "end", dates.out = "epdate",tz=tz)
    
# If you'd rather not use RMprep on an AQ export, 
#    you can run the following lines instead to convert timestamps to POSIXct without RMprep:
    
# input.uv$pdate <- as.POSIXct(x = input.uv$local_standard_time) 
# input.time$bpdate <- as.POSIXct(x=input.time$begin)
# input.time$epdate <- as.POSIXct(x=input.time$end)

#declare things for hydrovol
dfQ <- input.uv
df.dates <- input.time

#run hydrovol
output <- Hydrovol(dfQ, Q = "Q", time = "pdate", df.dates, bdate = "bpdate",
         edate = "epdate")

#remove duplicate columns
output <- subset(output, select= -c(begin, end))

#write to a .csv file
write.csv(x=output, file=output.file, row.names = FALSE)

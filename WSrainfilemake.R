library(lubridate)
library(tidyverse)
library(dataRetrieval)
#
#Set the directory to where you want to save the file you create at the end
#need to change this to a path that you are using to save your files
setwd("C:/Home/cjhoard/Recov_park/MODEL_DEV/JUST_SLAMM")
#
#retrieve the data from NWISWEB you can edit these values to meet whatever your site
#requirements are.
site = "422239083032401"
date1 = "2015-03-05"
date2 = "2016-03-29"
tz="America/Jamaica"

raindat = readNWISuv(site,"00045",date1,date2,tz)
#
#This option 1 thing was tried and it requires a couple steps for the user to
#implement the rain file in the program. Just easier to format the rainfile all
#once in R and not mess around with WinSLAMM
#
#option 1 from pdf
# rain1 = raindat %>% mutate(date=as.character(dateTime,format="%m/%d/%y")) %>%
#         group_by(date,time=hour(dateTime)) %>%
#         summarize(raintot=as.character(sum(X_00045_00000))) %>%
#         spread(time,raintot)
# 
# #outputfile
# write.table(rain1,"rain_output.csv",row.names=F,col.names=F,sep=",",quote = F)


#option 2 from PDF
#
rainfile = filter(raindat,X_00045_00000>0)
#
rainfile$delta = rainfile$dateTime - lag(rainfile$dateTime)
#
#Setting a lag value of one hour so that any gap beyond an hour is
#considered a new event this lag value can be adjusted to make it longer 
# depending on what you want to include in an event.
r_idx=which(rainfile$delta>=60)
#
#creating a grouping variable to combine rain into individual events
rainfile$group=0
for(i in seq_along(r_idx)){
        rainfile$group[1:r_idx[i]-1]=rainfile$group[1:r_idx[i]-1]+1
}
#
#Summarizing the rain by event
raindat = rainfile %>% group_by(group*-1) %>%
        summarize(mindate=floor_date(min(dateTime),unit='hour'),
                  maxdate=ceiling_date(max(dateTime),unit='hour'),
                  raintot=sum(X_00045_00000))
#
#error catching to make sure that the begin dates and times are not
#matching each other which would throw an error in WinSLAMM
#
for(i in 1:nrow(raindat)){
raindat$maxdate[i] = as.POSIXct(ifelse(raindat$mindate[i]==raindat$maxdate[i],
                         raindat$maxdate[i]+3600,raindat$maxdate[i]),
                         origin = "1970-01-01")
}
#
raindat = raindat %>%
        mutate(bdate=as.character(mindate,format="%m/%d/%y"),
               btime=as.character(mindate,format="%H:%M"),
               edate=as.character(maxdate,format="%m/%d/%y"),
               etime=as.character(maxdate,format="%H:%M")) %>%
         select(bdate,btime,edate,etime,raintot)

#
raindat$raintot=as.character(raindat$raintot)
#
write.table(nrow(raindat),"RP_rainfile.RAN",row.names=F,col.names=F)
write.table(raindat,"RP_rainfile.RAN",append=T,sep=",",row.names=F,col.names=F)



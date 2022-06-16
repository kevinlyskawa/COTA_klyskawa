library(RPostgreSQL)
library(plyr)
library(dplyr)
library(googlesheets)
library(data.table)
library(openxlsx)
library(googledrive)
library(Hmisc)
library(stringr)
library(stringi)
library(bigrquery)
library(googlesheets4)
library(comorbidity)

bq_auth(email=TRUE)
drive_auth(email = TRUE)

con <- dbConnect(
  bigrquery::bigquery(),
  project = "bigquery-408fd9e5",
  dataset = "seid"
)

# point to google drive folders
OUTPUT <- '1LH51ClPJ2urklPIwF5EH_oAQ1g01RjO4'
INPUT <- as.data.frame(drive_ls(as_id('1MpR_0B-hfDudnrBccTvtmMxkpwPPiVce')))

# assign list of input docs and SMV CSVs to data frame 
CSV <- as.data.frame(drive_ls(as_id('1MpR_0B-hfDudnrBccTvtmMxkpwPPiVce')))

# point to folder with scripts
SCRIPTDIR <- paste0('~/DSgit/cortex/External/Provider_Regulatory/FOCR/pilot3/scripts/')

# load functions 
source("~/DSgit/cortex/Library/functions/FollowupTimeDelta_fxn.R")
source("~/DSgit/cortex/Library/functions/DemoAgeCat_fxn.R")
source("~/DSgit/cortex/Library/functions/DemoAttributes_fxn.R")
source("~/DSgit/cortex/Library/functions/DemoSummaryOutput_fxn.R")
source("~/DSgit/cortex/Library/functions/CalculateCCI_fxn.R")
source("~/DSgit/cortex/Library/functions/NSCLC_Histology_Map_fxn.R")
source("~/DSgit/cortex/Library/functions/NSCLC_Squamous_Map_fxn.R")
source("~/DSgit/cortex/Library/functions/OutputTableOne_fxn.R")
source("~/DSgit/cortex/Library/functions/TableOneCombineCols_fxn.R")

# load tables 
NSC_histology_mapping <- fread("~/DSgit/cortex/Library/tables/NSC_histology_mapping.csv")
NSC_map_squamous <- fread("~/DSgit/cortex/Library/tables/NSC_map_squamous.csv")
map_lung_surgeries <- read_sheet("19XXldatKhUZrFujQuM9pQE9yAcg0BU7rcYqU_wazzOU")

# load tables 
NSC_histology_mapping <- fread("~/DSgit/cortex/Library/tables/NSC_histology_mapping.csv")
NSC_map_squamous <- fread("~/DSgit/cortex/Library/tables/NSC_map_squamous.csv")
map_lung_surgeries <- read_sheet("19XXldatKhUZrFujQuM9pQE9yAcg0BU7rcYqU_wazzOU")


### Load SMV Export ###

CSV <- subset(CSV, grepl('csv', name)) %>% arrange(name)
for (i in 1:nrow(CSV)) {  
  filename_str <- CSV$name[i]  
  temp <- drive_download(file = as_id(CSV$id[CSV$name == filename_str]), overwrite = TRUE)  
  df <- read.csv(filename_str, stringsAsFactors = F)  
  file.remove(filename_str)    
  assign(paste0(gsub('.csv', '', filename_str), '0'), df)
}

mpid_list <- paste0("('", paste(sort(unique(patient0$mpid)), collapse="', '"), "')")
mds.patients0 <- data.frame(dbGetQuery(con, paste0("select mpid, entity_id FROM mds.patients WHERE mpid IN ", mpid_list)))
cota.entities0 <- data.frame(dbGetQuery(con, paste0("select * from mds.entities")))
mpid_entity <- left_join(mds.patients0, cota.entities0)



##################################################################### 
#Line Break... just gives me space to think. 





data <- lab_test0
summary(data)   #tells me what types of variables I'm dealing with

charVar <- c("mpid", "assessed", "lab_name", "qualitative_observation", "logical_operator", "unit", "data_source")
#May need to make all vectors similar... OR, will need to know how to manipulate "units" column.

data.unit <- data$unit
view(data.unit)

#See how many different units are present in df == 20 
categories <- unique(data$unit) ##20 different units in df
numberOfCategories <- length(categories)
#categories
#[1] "mg_dL"                "k_uL"                 "g_dL"                
#[4] "u_l"                  "percent"              "unknown_unit"        
#[7] ""                     "k_mm_3"               "IU_L"                
#[10] "k_mcl"                "cells_uL"             "10_3_mcl"            
#[13] "gm_dl"                "x10_3_uL"             "IU_mL"               
#[16] "units_not_abstracted" "g_L"                  "cells_mm_3"          
#[19] "kU_L"                 "umol_L"              


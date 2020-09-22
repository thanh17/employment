# PROGRAM NAME: Goodness Indicator
# DESCRIPTION: Creating a GI from the  wage and growth changes associated with a job change
# PROGRAMMER(S): Axelle Clochard
# DATE WRITTEN: 09/22/2020
# LAST UPDATED: 09/22/2020



# STEP 0. SET UP WORKSPACE AND LOAD DATA
# ---------------------------------------------------------------------------------------------------#
# ---------------------------------------------------------------------------------------------------#


# A. SET WORKSPACE PARAMS
# ------------------------#
rm(list = ls()) 

# Set working directory to where file is
# script.dir <- dirname(rstudioapi::getActiveDocumentContext()$path)
# setwd(script.dir)
setwd('C:/Users/axell/OneDrive/Documents/MIT/J-WEL/employment/CPS Job Changes')


# install packages if necessary
packages <- c("ggplot2",
              "haven",
              "scales",
              "dplyr",
              "gridExtra",
              "grid",
              "xlsx", 
              "reshape2", 
              "stargazer", 
              "Hmisc", 
              "readxl",
              "httr",
              "Hmisc")

install_list <- packages[!(packages %in% installed.packages()[,"Package"])]
if(length(install_list)) install.packages(install_list)

lapply(packages, require, character.only = TRUE)




# B. O*NET DATA
# ---------------#

#ONET 2010 to SOC 2018 (BLS) xwalk from https://www.onetcenter.org/taxonomy/2010/soc2018.html
onet = read_excel("./2010_to_2018_SOC_Crosswalk.xlsx", skip = 3)

names(onet) = c("onet_2010_soc", "onet_2010_title", "SOC_2018", "SOC_title_2018" )

# C. BLS WAGE DATA (https://www.bls.gov/oes/current/oes_nat.htm)
# ---------------------------------------------------------------------#
blsw = read_excel("./national_M2019_dl.xlsx", skip = 0)
hb_w = read_excel("./national_M2019_dl.xlsx", skip = 0, sheet = 2)


# C. BLS GROWTH DATA (https://www.bls.gov/emp/tables/emp-by-detailed-occupation.htm)
# ------------------------------------------------------------------------------------#
blsg = read_excel("./occupation.xlsx", sheet = 3)
old_names = blsg[1:4,]
names(blsg) = c("SOC_Title", "SOC", "OccupationType", "employment_2019", "employment_2029", "pct_dist_2019", "pct_dist_2029", "change_employment_number", "change_employment_pct", "occ_openings_201929_annual_average")


# Note - there's a good education and training requirement page
bls_training = read_excel("./occupation.xlsx", sheet = 15)




# Merge BLS datasets:
bls <- merge(x = subset(blsg, OccupationType == "Line item")[c("SOC", "change_employment_number", "change_employment_pct")],
             y = subset(blsw, o_group == "detailed")[c("occ_code", "h_median", "a_median", "annual", "hourly")],
             by.x = "SOC", 
             by.y = "occ_code",
             all = T)

bls$a_median <- as.numeric(as.character(sub("[*]", NA, bls$a_median)))
bls$h_median <- as.numeric(as.character(sub("[*]", NA, bls$h_median)))

# convert annual to hourly:
bls$h_median_new <- ifelse(is.na(bls$h_median), bls$a_median/2080, bls$h_median)








# STEP 1: CREATE INDICATOR
# ---------------------------------------------------------------------------------------------------#
# ---------------------------------------------------------------------------------------------------#


# Create combos:
soc_combos = expand.grid(onet$SOC_2018, onet$SOC_2018) %>% subset(., Var1 != Var2)
names(soc_combos) <- c("SOC1", "SOC2")


# Merge on wage and growth info:
dat <- merge(x = soc_combos,
             y = bls[c("SOC", "h_median_new")],
             by.x = "SOC1", by.y = "SOC",
             all = T,
             suffixes = c("",".1")) %>%
        
        merge(x = .,
              y = bls[c("SOC", "change_employment_pct", "h_median_new")],
              by.x = "SOC2", by.y = "SOC",
              all = T,
              suffixes = c("",".2")) 


# Note: no wage change projection

dat$change_employment_pct <- as.numeric(as.character(dat$change_employment_pct))

dat <- dat %>%
       mutate(employment_projection_NewJob = change_employment_pct,
              wage_change_BetweenJobs = ((h_median_new.2 - h_median_new)/h_median_new)*100)

dat <- distinct(dat)







# STEP 2: MERGE ON TO EXISTING JOB CHANGE DATA
# ---------------------------------------------------------------------------------------------------#
# ---------------------------------------------------------------------------------------------------#
job_changes <- read.csv("./JobChanges_2011to19.csv")

# Some combinations missing, e.g. "11-3012" - double check that BLS is indeed using SOC 2018?
jc <- merge(x = job_changes, 
            y = dat[c("SOC1", "SOC2", "employment_projection_NewJob", "wage_change_BetweenJobs")],
            by.x = c("ONET18_SOC_LY", "ONET18_SOC"), by.y = c("SOC1", "SOC2"), all.x = T) 
  
write.csv(x=jc, file="JobChanges_2011to19.csv",  row.names = FALSE)








# STEP 3: COMPUTE SOME IMPORTANT STATS
# ------------------------------------------------------------------------------------------------------#
# ------------------------------------------------------------------------------------------------------#
# Most common transition: OCC Measure
head(jc %>% arrange(desc(pct_tot)), 10)[c("ONET18_Title_LY","ONET18_Title", "employment_projection_NewJob", "wage_change_BetweenJobs")]

# Investigate that last one
test <- subset(dat, SOC1 == "41-1011"  & SOC2 == "41-1012")








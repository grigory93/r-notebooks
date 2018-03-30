library(data.table)
library(RSocrata)

# some OSX work-around 
if (Sys.info()["sysname"] == "Darwin")
  Sys.setenv (TZ="America/Chicago")

# Read Dallas Animal Shelters Data 2015 - 2018
data15.source = read.socrata(url = "https://www.dallasopendata.com/resource/8pn8-24ku.csv")
data16.source = read.socrata(url = "https://www.dallasopendata.com/resource/4qfv-27du.csv")
data17.source = read.socrata(url = "https://www.dallasopendata.com/resource/8849-mzxh.csv")
data18.source = read.socrata(url = "https://www.dallasopendata.com/resource/4jgt-nenk.csv")

# Read Dallas Animal Medical Records 2018 (not used)
data18.recs.source = read.socrata(url = "https://www.dallasopendata.com/resource/5dkq-vasv.csv")
data17.recs.source = read.socrata(url = "https://www.dallasopendata.com/resource/tab8-7f9r.csv")

# Create data tables for speed
dt15 = data.table(data15.source)
dt16 = data.table(data16.source)
dt17 = data.table(data17.source)
dt18 = data.table(data18.source)

# Minimal changes to make all years compatible
dt15n16 = bind_rows(list(dt15,dt16))
dt15n16[, c("intake_time","outcome_time") := 
          list(strftime(intake_time, format="%H:%M:%S."), 
               strftime(outcome_time, format="%H:%M:%S."))]

names(dt17)[21] = 'month'

alldata = bind_rows(dt15n16,dt17,dt18)

alldogs = alldata[!is.na(outcome_date) & 
                    (intake_total == 1 | is.na(intake_total)) &
                    animal_type == 'DOG' &
                    !outcome_type %in% c("DEAD ON ARRIVAL","FOUND REPORT","LOST REPORT")]

alldogs[, c("activity_number","activity_sequence","tag_type",
            "animal_type","additional_information") := NULL]
alldogs[, c("intake_time", "outcome_time","month","lost",
            "intake_is_contagious","intake_treatable") := list(
  substring(intake_time, 1, 8),
  substring(outcome_time, 1, 8),
  substring(month, 1, 3),
  ifelse(outcome_type %in% c("DIED","EUTHANIZED","MISSING"), 1, 0),
  ifelse(is.na(str_match(intake_condition, ' CONTAGIOUS$')[,1]), 'NO','YES'),
  ifelse(is.na(str_match(intake_condition, '^TREATABLE ')[,1]), 'UNTREATABLE',
         ifelse(is.na(str_match(intake_condition, 'MANAGEABLE')[,1]),
                'REHABILITABLE', 'MANAGEABLE'))
)]
            
        
fwrite(alldogs[!year %in% "FY2018"], file = "~/Projects/Playground/data/dallas_animal_services_train.csv")
fwrite(alldogs[year %in% "FY2018"], file = "~/Projects/Playground/data/dallas_animal_services_test.csv")

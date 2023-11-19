* Note - from this point, run scripts 9.1 onwards once until the end for each cohort 

use  workingCohort\9.01_create_secondary_care_admission_dataset.dta
rename admidate pneumonia_pc_date
save workingCohort\9_add_HES_data.dta, replace


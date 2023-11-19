clear all
set more off, perm
macro drop _all

capture log close
log using "Logs/10_add_patient_demographics", replace

global hes_extract "Aurum_linked\"
global cohort "workingCohort\"
*global working_data "workingData\"
global working_data "workingData\"
global extract "extractDataMini\"
*global codelist "Code_lists\CPRD_Aurum\"

*NOTE - FOR THIS DRUG ISSUE ONE, I HAVE USED EMILY'S NEW CODELIST SAVED IN THE ORIGINAL CODELISTS FOLDER
global codelist "codelists\jkq\"

global covar "covariates\"


use ${cohort}9_add_HES_data, clear

merge 1:1 patid using ${extract}Patient_practice

keep if _m == 3
drop _m

* we did this before but we don't really need the old 4_ cohort - better to have all their demographics at pneumonia date rather than the date they became eligible.

gen age = (pneumonia_pc_date - dob)/365.25

sum age
tab gender

count if cprd_ddate < pneumonia_pc_date
count if cprd_ddate == pneumonia_pc_date
count if cprd_ddate > pneumonia_pc_date & cprd_ddate != .

*no one dies before their first pneumonia, because we've already done this step.

*save the cohort

save ${cohort}10_add_patient_demographics, replace

log close


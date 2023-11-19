*Base cohort
************************************************************************



clear all
set more off, perm
macro drop _all

capture log close
log using "Logs/17_add_IMD", replace

global extract_HES "Aurum_linked\"
global cohort "workingCohort\"
*global working_data "workingData\"
global working_data "workingData\"
global extract "extractDataMini\"
*global codelist "Code_lists\CPRD_Aurum\"

*NOTE - FOR THIS DRUG ISSUE ONE, I HAVE USED EMILY'S NEW CODELIST SAVED IN THE ORIGINAL CODELISTS FOLDER
global codelist "Code_lists\CPRD_Aurum\"

global covar "covariates\"
**********************************************************************
* Add IMD
*******************************************************************

use ${cohort}10_add_patient_demographics, clear 

* unfortunately, we forgot to reinput our eligibility criteria after we had used it for defining pneumonia events!!!
* so, doing it now...
* this will mean we lose some people who were not eligigble for HES linkage. 
* this doesn't matter that much as we were only interested in those who were admitted to hospital, but still...

merge 1:1 patid using ${cohort}4_full_eligibility_criteria

*merge 1:1 patid using ${extract_HES}patient_imd2015_21_000386_request2
keep if _m == 3
drop _m




save ${cohort}17_add_IMD, replace

log close






/*******************************************************************************

AUTHOR:					AA
DATE: 					24-12-2021
VERSION:				STATA 16.1
DO FILE NAME:			22_add_covariates

DESCRIPTION OF FILE:	


*******************************************************************************/
clear all
set more off, perm
macro drop _all

capture log close
log using "Logs/12_BMI_part_1.smcl", replace

global hes_extract "Aurum_linked\"
global cohort "workingCohort\"
*global working_data "workingData\"
global working_data "workingData/"
global extract "extractDataMini\"
*global codelist "Code_lists\CPRD_Aurum\"

*NOTE - FOR THIS DRUG ISSUE ONE, I HAVE USED EMILY'S NEW CODELIST SAVED IN THE ORIGINAL CODELISTS FOLDER
global codelist "codelists\jkq\"

global covar "covariates\"


use ${working_data}BMI_pre_diagnosis, clear

*Amazingly, there is just a value for BMI given.

*drop if obsdate < pneumonia_pc_date - (age*365.25)


*I think that for this variable, we're looking to see whether they have BMI measured, so we just ignore manually calculating weight and height because that would be us obtaining BMI, not the doctor obtaining it. 

*we potentially just keep those with values? Let's see how many have values first...

count if value == .
count if value != .

*almost every value isn't missing so it is legitimate to drop those with missing values.

drop if value == .

*some of the values refer to percentiles. I think it is best to remove these...
drop if medcodeid == "8286961000006110"
drop if medcodeid == "2196031000000118"
drop if medcodeid == "7332961000006118"
drop if medcodeid == "1728141000006115"
drop if medcodeid == "1551651000000111"
drop if medcodeid == "8334011000006117"
drop if medcodeid == "1922491000006113"

*Oh... hardly used anyway...

rename obsdate bmi_date
rename value bmi_value 


* drop ridiculous values
drop if bmi_value > 100
drop if bmi_value < 13


save ${working_data}bmi_clean, replace

sort patid bmi_date

* get most recent BMI
by patid: keep if _n == _N

keep patid bmi_date bmi_value bmi

codebook

save ${covar}bmi, replace

log close


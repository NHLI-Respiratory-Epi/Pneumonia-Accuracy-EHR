/*******************************************************************************

AUTHOR:					AA
DATE: 					24-12-2021
VERSION:				STATA 16.1
DO FILE NAME:			Sort out CCI

DESCRIPTION OF FILE:	


*******************************************************************************/
clear all
set more off, perm
macro drop _all


capture log close
log using "Logs/15_CCI_part_2", replace

*global hes_extract "Aurum_linked\"
global cohort "workingCohort\"
*global working_data "workingData\"
global working_data "workingData\"
global extract "extractDataMini\"
*global codelist "Code_lists\CPRD_Aurum\"

*NOTE - FOR THIS DRUG ISSUE ONE, I HAVE USED EMILY'S NEW CODELIST SAVED IN THE ORIGINAL CODELISTS FOLDER
global codelist "Code_lists\CPRD_Aurum\"

global covar "covariates\"

use ${working_data}CCI_Quan_2011_only_pre_diagnosis, clear

*drop if they are diagnosed before they are born

*drop if obsdate < start_date - (age*365.25)


* keep just unique disease types

keep patid cat

duplicates drop

gen ones = 1

* need to encode it to reshape it...
encode cat, gen(cat2)

drop cat
rename cat2 cat


labelbook

tab cat

reshape wide ones, i(patid) j(cat)

*got to do loads of renaming...

rename ones1 CCI_any_malignancy
rename ones2 CCI_cerebrovascular
rename ones3 CCI_CPD
rename ones4 CCI_congestive_heart_failure
rename ones5 CCI_dementia
rename ones6 CCI_diabetes_uncomplicated
rename ones7 CCI_diabetes_end_organ_damage
rename ones8 CCI_HIV
rename ones9 CCI_hemi_paraplegia
rename ones10 CCI_metastatic
rename ones11 CCI_liver_disease_mild
rename ones12 CCI_liver_disease_mod_sev
rename ones13 CCI_MI
rename ones14 CCI_peptic_ulcer
rename ones15 CCI_peripheral_vascular
rename ones16 CCI_CKD
rename ones17 CCI_rheumatic

*checked and this is all fine

*now we drop the labels

foreach var of varlist CCI_any_malignancy - CCI_rheumatic {
	label var `var' `var'
}


save ${covar}CCI, replace



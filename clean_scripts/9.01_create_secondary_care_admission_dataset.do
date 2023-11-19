
clear all
set more off, perm
macro drop _all

capture log close
log using "Logs/9.01_create_secondary_care_admission_dataset", replace

global hes_extract "extractHES\"
global cohort "workingCohort\"
global working_data "workingData\"
global extract "extractData\"
global codelist "codelists\jkq\"

global covar "covariates\"


use ${hes_extract}hes_diagnosis_epi_21_000468_elig_restruc_last_epi, clear


gen icd_pneumo_20 = 0

forvalues x = 1/20  {
	replace icd_pneumo_20 = 1 if substr(icd0`x',1,3) == "J12"
	replace icd_pneumo_20 = 1 if substr(icd0`x',1,3) == "J13"
	replace icd_pneumo_20 = 1 if substr(icd0`x',1,3) == "J14"
	replace icd_pneumo_20 = 1 if substr(icd0`x',1,3) == "J15"
	replace icd_pneumo_20 = 1 if substr(icd0`x',1,3) == "J16"
	replace icd_pneumo_20 = 1 if substr(icd0`x',1,3) == "J17"
	replace icd_pneumo_20 = 1 if substr(icd0`x',1,3) == "J18"
}

gen icd_pneumo_first = 0

forvalues x = 1/1  {
	replace icd_pneumo_first = 1 if substr(icd0`x',1,3) == "J12"
	replace icd_pneumo_first = 1 if substr(icd0`x',1,3) == "J13"
	replace icd_pneumo_first = 1 if substr(icd0`x',1,3) == "J14"
	replace icd_pneumo_first = 1 if substr(icd0`x',1,3) == "J15"
	replace icd_pneumo_first = 1 if substr(icd0`x',1,3) == "J16"
	replace icd_pneumo_first = 1 if substr(icd0`x',1,3) == "J17"
	replace icd_pneumo_first = 1 if substr(icd0`x',1,3) == "J18"
}

tab icd_pneumo_20
tab icd_pneumo_first

keep if icd_pneumo_20 == 1


forvalues x = 1/20  {
	gen icd0`x'_3d = substr(icd0`x',1,3)
    gen icd0`x'_1d = substr(icd0`x',1,1)
}

codebook patid

keep if icd_pneumo_first == 1

codebook patid

merge m:1 patid using ${cohort}4_full_eligibility_criteria

keep if _m == 3
drop _m

*keep those that occur during the eligibility period
keep if admidate >=start_date & admidate <= end_date

codebook patid

drop first_copd-imd_quintile

*keep the first episode
sort patid admidate
by patid: keep if _n == 1

*15,954 observations removed

/*
*remove those that popped up in the secondary care dataset
merge 1:1 patid using ${cohort}9_add_HES_data
drop if _m == 2
drop if _m == 3 & hosp_7days == 1
drop pneumonia_pc_date-_m
*/


*merge with the pneumonia_lrti events

preserve
use ${working_data}pneumonia_lrti, clear
keep if pneumonia == 1
save ${working_data}pneumonia_lrti_just_pneumo, replace
restore


merge 1:m patid using ${working_data}pneumonia_lrti_just_pneumo
drop if _m == 2

tab pneumonia_lrti, m

keep if pneumonia_lrti == "pneumonia"  | pneumonia_lrti == ""

gen time_to_pneumo_recording = obsdate - admidate
codebook time_to_pneumo_recording
replace time_to_pneumo_recording = . if time_to_pneumo_recording < 0  
replace time_to_pneumo_recording = . if time_to_pneumo_recording > 42  

tab time_to_pneumo_recording, m

codebook patid

sort patid time_to_pneumo_recording

*missing is infinitely big, so by sorting this way we can then take the first record per patient.

by patid: keep if _n == 1

tab time_to_pneumo_recording, m



drop _m lrti pneumonia_lrti 

*and make age correct for the age at admission
drop age


*just for ease here... I'm going to rename the date as primary_date_pc so I can just use the scripts I've already written...


save ${cohort}9.01_create_secondary_care_admission_dataset.dta, replace

log close


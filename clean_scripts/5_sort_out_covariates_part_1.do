/*******************************************************************************

AUTHOR:					AA
DATE: 					24-12-2021
VERSION:				STATA 16.1
DO FILE NAME:			7_create_covariates_smokstatus

DESCRIPTION OF FILE:	


*******************************************************************************/
clear all
set more off, perm
macro drop _all

capture log close
log using "Logs/5_sort_out_covariates_part_1", replace

*global hes_extract "Aurum_linked\"
global cohort "workingCohort\"
*global working_data "workingData\"
local working_data "workingData"
global extract "extractData\"
*global codelist "Code_lists\CPRD_Aurum\"
local codelistfilepath "codelists\jkq"

global covar "covariates\"


*code lists:

* defining the study population:

*The following clinical features were used to define the study population (patients) at baseline; symptoms (breathlessness, fever, lethargy, tachycardia, tachypnoea), referrals for chest x-ray, antibiotics use, sputum sample sent / abnormal / positive and blood culture, blood culture positive.

* plus cough?

*In addition, we looked for presence of Oral corticosteroids (OCS) and antibiotics prescriptions, each for a period of 5 to 14 days. 

* pneumonia code (obvs)

* AECOPD

* generic: BMI, 

*abx_codelist_jkq_2 - for drug issue
*copd_meds_final_2 - mystery



*read in the extract data

/*
forvalues f=1/84{
	local i=string(`f',"%03.0f")	
	use ${extract}Observation_`i'.dta, clear

	
	*Do loads of codelists in one go, so merge on patient id first

	merge m:1 patid using ${cohort}4_full_eligibility_criteria.dta
	keep if _m==3 
	drop _m
	
	drop first_copd-study_enddate
*/
	local codelistlist "pneumonia_lrti AECOPD blood_culture_3_jkq_positive blood_culture_3_jkq_sent BMI breathless_3_jkq_2 chest_x_ray_3_jkq_2 cough_jkq_2 fever_3_jkq_2 lethargy_3_jkq_2 mrc_breathless_final_2 sputum_final_2_jkq_abnormal sputum_final_2_jkq_positive sputum_final_2_jkq_sent tachycardia_3_jkq_2"
	/*
	foreach codelistfile of local codelistlist {
		preserve
		display "`codelistfile'"
		merge m:1 medcodeid using "`codelistfilepath'/`codelistfile'"
		keep if _m==3 
		drop _m
		


		save "`working_data'/`codelistfile'_`i'", replace
		display "`codelistfile'_`i'"

	    restore

	}
}
*/


foreach codelistfile of local codelistlist {
  use "`working_data'/`codelistfile'_001", clear
	forvalues f = 2/84{ 
		local i=string(`f',"%03.0f")
	append using "`working_data'/`codelistfile'_`i'"
	}
	
	* all obs
	save "`working_data'/`codelistfile'", replace


	* all previous obs
	drop if obsdate > start_date
	
	drop start_date-imd_quintile
	
	save "`working_data'/`codelistfile'_pre_diagnosis", replace

	* most recent previous obs
	use "`working_data'/`codelistfile'", clear
	
	drop if obsdate > start_date
	
	drop start_date-age

	sort patid obsdate
	
	by patid: keep if _n == _N
	
	
	
	save "`working_data'/`codelistfile'_most_recent", replace

	
	*during study period
	use "`working_data'/`codelistfile'", clear
	
	
	keep if obsdate > start_date & obsdate <= end_date
	
	drop start_date-age
	
	save "`working_data'/`codelistfile'_during_SP", replace
	
		use "`working_data'/`codelistfile'", clear
	
		keep if obsdate > start_date & obsdate <= end_date
	
	keep if obsdate == enterdate
	
		drop start_date-age
		
	* make sure that enter date = study date. this removes a lot of records, but ensures accuracy and that GPs haven't entered data post hoc

	save "`working_data'/`codelistfile'_SP_enter_obs_same", replace
	
	}


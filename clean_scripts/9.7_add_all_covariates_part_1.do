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
log using "Logs/9.7_add_all_covariates_part_1", replace

global hes_extract "Aurum_linked\"
global cohort "workingCohort\"
*global working_data "workingData\"
local working_data "workingData"
global extract "extractDataMini\"
*global codelist "Code_lists\CPRD_Aurum\"


local codelistfilepath "Code_lists/CPRD_Aurum"

global covar "covariates\"


*code lists:
/*
anaemia_clean
annual_review_clean

*/


*read in the extract data

forvalues f=1/84{	
	local i=string(`f',"%03.0f")
	use ${extract}Observation_`i'.dta, clear

	keep patid  medcodeid obsdate value numunitid obstypeid

	*Do loads of codelists in one go, so merge on patient id first

	merge m:1 patid using ${cohort}9_add_HES_data.dta
	keep if _m==3 
	drop _m

	local codelistlist "anaemia_clean annual_review_clean anxiety_clean asthma_clean atrial_fibrillation_clean BMI chest_xray_clean depression_clean diabetes_clean hf_clean hypertension_clean pulmonary_rehab_clean referral_clean smoking_cessation_obs_clean smoking_status spirometry stroke_clean CCI_Quan_2011_only hf_referral_clean fluvac_offer_clean fluvac_admin_clean echocardiogram_clean BNP_clean"
	
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





local codelistlist "anaemia_clean annual_review_clean anxiety_clean asthma_clean atrial_fibrillation_clean BMI chest_xray_clean depression_clean diabetes_clean hf_clean hypertension_clean pulmonary_rehab_clean referral_clean smoking_cessation_obs_clean smoking_status spirometry stroke_clean CCI_Quan_2011_only hf_referral_clean fluvac_offer_clean fluvac_admin_clean echocardiogram_clean BNP_clean"

foreach codelistfile of local codelistlist {
	use "`working_data'/`codelistfile'_001", clear
	forvalues f = 2/84{ 
	local i=string(`f',"%03.0f")
	append using "`working_data'/`codelistfile'_`i'"
	}
	
	save "`working_data'/`codelistfile'", replace

	drop if obsdate > pneumonia_pc_date
	
	save "`working_data'/`codelistfile'_pre_diagnosis", replace

	sort patid obsdate
	
	by patid: keep if _n == _N
	
	local newname "`codelistfile'_date"
	rename obsdate `newname'
	
	save "`working_data'/`codelistfile'_most_recent", replace
}

log close


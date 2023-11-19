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
log using "Logs/6_add_drug_issue_covariates", replace

*global hes_extract "Aurum_linked\"
global cohort "workingCohort\"
*global working_data "workingData\"
local working_data "workingData"
global extract "extractData\"
*global codelist "Code_lists\CPRD_Aurum\"
local codelistfilepath "codelists\jkq"
global extract_mini "extractDataMini\"

global covar "covariates\"



*read in the extract data

local codelistlist "abx_codelist_jkq_2 COPD_meds_combined_clean copd_meds_final_2"



forvalues f=1/96{	
	local i=string(`f',"%03.0f")	
	use ${extract}DrugIssue_`i'.dta, clear

	
	*Do loads of codelists in one go, so merge on patient id first

	merge m:1 patid using ${cohort}4_full_eligibility_criteria.dta
	keep if _m==3 
	drop _m

	preserve
    drop first_copd-imd_quintile
	
	save ${extract_mini}DrugIssue_`i'.dta, replace

	restore
	

	*Do loads of codelists in one go, so merge on patient id first



	foreach codelistfile of local codelistlist {
		preserve
		display "`codelistfile'"
		merge m:1 prodcodeid using "`codelistfilepath'/`codelistfile'"
		keep if _m==3 
		drop _m
		


		save "`working_data'/`codelistfile'_`i'", replace
		display "`codelistfile'_`i'"

	    restore

	}
}



*global hes_extract "Aurum_linked\"
global cohort "workingCohort\"
*global working_data "workingData\"
local working_data "workingData"
global extract "extractData\"
*global codelist "Code_lists\CPRD_Aurum\"
local codelistfilepath "codelists\jkq"
global extract_mini "extractDataMini\"

global covar "covariates\"




*read in the extract data



local working_data "workingData"

use "`working_data'/abx_codelist_jkq_2_001", clear
	forvalues f = 2/96 { 
		local i=string(`f',"%03.0f")	
		append using "`working_data'/abx_codelist_jkq_2_`i'"

	}
	
save "`working_data'/abx_codelist_jkq_2", replace

local working_data "workingData"

use "`working_data'/COPD_meds_combined_clean_001", clear
	forvalues f = 2/96 { 
		local i=string(`f',"%03.0f")	
		append using "`working_data'/COPD_meds_combined_clean_`i'"

	}
	
save "`working_data'/COPD_meds_combined_clean", replace
	

	
local working_data "workingData"

use "`working_data'/copd_meds_final_2_001", clear
	forvalues f = 2/96 { 
		local i=string(`f',"%03.0f")	
		append using "`working_data'/copd_meds_final_2_`i'"

	}
	
save "`working_data'/copd_meds_final_2"	, replace






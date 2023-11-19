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
log using "Logs/9.9_add_drug_issue_covariates_part_1", replace

global hes_extract "Aurum_linked\"
global cohort "workingCohort\"
*global working_data "workingData\"
global working_data "workingData\"
global extract "extractDataMini\"
*global codelist "Code_lists\CPRD_Aurum\"

*NOTE - FOR THIS DRUG ISSUE ONE, I HAVE USED EMILY'S NEW CODELIST SAVED IN THE ORIGINAL CODELISTS FOLDER
global codelist "codelists\jkq\"

global covar "covariates\"

*code lists:
/*
anaemia_clean
annual_review_clean

*/


*read in the extract data


forvalues f=1/96{	
	local i=string(`f',"%03.0f")
	use ${extract}DrugIssue_`i'.dta, clear

	keep patid  prodcodeid issuedate

	*Do loads of codelists in one go, so merge on patient id first
* should already be just patients we want so don't need to merge with patids.

		merge m:1 prodcodeid using ${codelist}COPD_inhalers_clean
		keep if _m==3 
		drop _m
		
		save ${working_data}COPD_inhalers_clean_`i', replace
		

}


use ${working_data}COPD_inhalers_clean_001, clear
	forvalues f = 2/96 { 
			local i=string(`f',"%03.0f")
	append using ${working_data}COPD_inhalers_clean_`i'
	}
	
	save ${working_data}COPD_inhalers_clean, replace

	merge m:1 patid using ${cohort}9_add_HES_data
	keep if _m == 3
	keep patid issuedate inhaler_category pneumonia_pc_date
	
	drop if issuedate > pneumonia_pc_date
	
	save ${working_data}COPD_inhalers_clean_pre_diagnosis, replace

	sort patid issuedate
	
	by patid: keep if _n == _N
	
  save ${working_data}COPD_inhalers_clean_most_recent, replace


* alt COPD drugs

forvalues f=1/96{	
	local i=string(`f',"%03.0f")
	use ${extract}DrugIssue_`i'.dta, clear

	keep patid  prodcodeid issuedate

	*Do loads of codelists in one go, so merge on patient id first
* should already be just patients we want so don't need to merge with patids.

		merge m:1 prodcodeid using ${codelist}copd_medications-aurum_dmd_bnf_atc_clean
		keep if _m==3 
		drop _m
		
		save ${working_data}copd_medications-aurum_dmd_bnf_atc_clean_`i', replace
		

	}


use ${working_data}copd_medications-aurum_dmd_bnf_atc_clean_001, clear
	forvalues f = 2/96{ 
			local i=string(`f',"%03.0f")
	append using ${working_data}copd_medications-aurum_dmd_bnf_atc_clean_`i'
	}
	
	save ${working_data}copd_medications-aurum_dmd_bnf_atc_clean, replace

	merge m:1 patid using ${cohort}9_add_HES_data
    keep if _m == 3
	keep patid issuedate drug_category pneumonia_pc_date
	
	drop if issuedate > pneumonia_pc_date
	
	save ${working_data}copd_medications-aurum_dmd_bnf_atc_clean_pre_diagnosis, replace

	sort patid issuedate
	
	by patid: keep if _n == _N
	
  save ${working_data}copd_medications-aurum_dmd_bnf_atc_clean_most_recent, replace


log close


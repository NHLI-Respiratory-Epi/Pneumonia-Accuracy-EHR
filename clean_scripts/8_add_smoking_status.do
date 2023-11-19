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
log using "Logs/8_add_smoking_status", replace

*global hes_extract "Aurum_linked\"
global cohort "workingCohort\"
global working_data "workingData\"
global extract "extractData\"
global codelist "Code_lists/CPRD_Aurum"

global covar "covariates\"




*list of all variables we need:

*outcomes:


*read in the extract data


forvalues f=1/84{
local i=string(`f',"%03.0f")	
use ${extract}Observation_`i'.dta, clear

keep patid  medcodeid obsdate

*using the medcode ids first is probably faster?

merge m:1 medcodeid using ${codelist}smoking_status.dta
keep if _m==3 
drop _m



merge m:1 patid using ${cohort}4_full_eligibility_criteria.dta
keep if _m==3 
drop _m


save ${working_data}smoking_`i', replace
}


use ${working_data}smoking_001, clear
forvalues f=2/84{
	local i=string(`f',"%03.0f")
append using ${working_data}smoking_`i'
}



save ${working_data}smoking_full_end, replace

*Use the smoking status codes



log close


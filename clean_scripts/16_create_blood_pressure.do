/*******************************************************************************

AUTHOR:					AA
DATE: 					17-12-2021
VERSION:				STATA 16.1
DO FILE NAME:			Set up dual therapy. So, create start dates for when people are on dual therapy using lama and laba separately.

DESCRIPTION OF FILE:	

* Laba and Lama need to be recorded within 2 months of each other to be counted as dual.
* Then, they need to be recorded twice within a 6 months period.
* This do file sorts this out, using a drug issue file from which only inhalers have been extracted.

*******************************************************************************/
clear all
set more off, perm
macro drop _all

capture log close
log using "Logs/16_create_blood_pressure", replace

*global hes_extract "Aurum_linked\"
global cohort "workingCohort\"
*global working_data "workingData\"
global working_data "workingData\"
global extract "extractDataMini\"
*global codelist "Code_lists\CPRD_Aurum\"

*NOTE - FOR THIS DRUG ISSUE ONE, I HAVE USED EMILY'S NEW CODELIST SAVED IN THE ORIGINAL CODELISTS FOLDER
global codelist "Code_lists\CPRD_Aurum\"

global covar "covariates\"




forvalues f=1/84{	
	local i=string(`f',"%03.0f")
	use ${extract}Observation_`i'.dta, clear

	keep patid  medcodeid obsdate value

	*systolic | diastolic
	
	gen systolic = 1 if medcodeid == "114311000006111"
	gen diastolic = 1 if medcodeid == "619931000006119"
	
	keep if systolic == 1 | diastolic == 1
	
	
	
	*Do loads of codelists in one go, so merge on patient id first


	save ${working_data}blood_pressure_`i', replace
	
	
}

use ${working_data}blood_pressure_001, clear

	forvalues f = 2/84 { 
		local i=string(`f',"%03.0f")
	append using ${working_data}blood_pressure_`i'
	}
	
save ${working_data}blood_pressure, replace


*systolic

use ${working_data}blood_pressure, clear

merge m:1 patid using ${cohort}10_add_patient_demographics
keep if _m == 3

keep if systolic == 1

*drop ridiculous values
* drop if higher than highest recorded blood pressure

drop if value > 400
drop if value < 40

drop if obsdate > pneumonia_pc_date

	sort patid obsdate
	
	keep patid obsdate value

	*most recent date
	by patid: keep if _n == _N
    rename value BP_systolic_value
	rename obsdate BP_systolic_date
	gen BP_systolic = 1
	save ${covar}BP_systolic, replace


	use ${working_data}blood_pressure, clear

	
merge m:1 patid using ${cohort}10_add_patient_demographics
keep if _m == 3


keep if diastolic == 1

drop if value > 400
drop if value < 40


drop if obsdate > pneumonia_pc_date

	sort patid obsdate
	
	keep patid obsdate value

	*most recent date
	by patid: keep if _n == _N
    rename value BP_diastolic_value
	rename obsdate BP_diastolic_date
	gen BP_diastolic = 1
	save ${covar}BP_diastolic, replace

	log close
	
	
	


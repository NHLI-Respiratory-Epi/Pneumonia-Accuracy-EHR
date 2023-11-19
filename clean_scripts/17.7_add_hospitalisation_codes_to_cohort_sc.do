clear all
set more off, perm
macro drop _all


capture log close
log using "Logs/17.7_add_hospitalisation_codes_to_cohort_sc", replace

global extract_HES "Aurum_linked\"
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

	drop pracid
	

	merge m:1 medcodeid using codelists\jkq\hospital_codes_clean.dta
	keep if _m==3 
	drop _m
		
	merge m:1 patid using ${cohort}17_add_IMD.dta
	keep if _m==3 
	drop _m

	save ${working_data}hospital_code_`i'.dta, replace

}

use ${working_data}hospital_code_001.dta, clear

	forvalues f = 2/84{ 
		local i=string(`f',"%03.0f")	
	append using ${working_data}hospital_code_`i'
	}
	
	
	save ${working_data}hospital_code.dta, replace


*all lung function
use ${working_data}hospital_code, clear

drop if obsdate == .

*identify hospital codes within 42 days of pneumonia admission
gen time_to_GP_hospital_code = datediff((pneumonia_pc_date), (obsdate),  "day")

list obsdate pneumonia_pc_date time_to_GP_hospital_code in 1/6

keep if time_to_GP_hospital_code <=42 & time_to_GP_hospital_code >=0

tab time_to_GP_hospital_code
tab time_to_pneumo_recording


gen same_day_GP_code_pneumo = 1 if time_to_GP_hospital_code == time_to_pneumo_recording
replace same_day_GP_code_pneumo = 0 if same_day_GP_code_pneumo == .

gen GP_hosp_code_42 = 1 if time_to_GP_hospital_code != .
replace GP_hosp_code_42 = 0 if GP_hosp_code_42 == .

keep patid time_to_GP_hospital_code time_to_pneumo_recording same_day_GP_code_pneumo GP_hosp_code_42

tab same_day_GP_code_pneumo GP_hosp_code_42, m

preserve 
keep patid same_day_GP_code_pneumo GP_hosp_code_42
duplicates drop
restore

preserve
keep patid time_to_GP_hospital_code GP_hosp_code_42
sort patid
by patid: keep if _n == 1
save ${covar}GP_hosp_code_42, replace
restore


preserve
keep patid same_day_GP_code_pneumo
keep if same_day_GP_code_pneumo == 1
sort patid
by patid: keep if _n == 1
save ${covar}same_day_GP_code_pneumo, replace
restore



*use ${cohort}18_add_covariates, replace

*log close




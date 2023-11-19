clear

set rmsg on

macro drop _all

capture log close
log using "Logs/9.1_create_mini_CPRD_datasets_for_eligible_pneumonia_patients_only", replace

global hes_extract "extractHES\"
global cohort "workingCohort\"
global working_data "workingData\"
global extract "extractData\"
global codelist "codelists\jkq\"

global covar "covariates\"







*********************************************************************
* CREATE LOCAL MACROS

* PATH FOR THE MINI DATA TO GO TO
local path_mini "extractDataMini" 
*
*
* PATH WHERE DATA ORIGINALLY COMES FROM:
local path_orig "extractData\"

*********************************************************************

clear
set more off
 
/*
The commands below basically say - look in the directory you have specified as
path_orig and memorise all the file names.  Then, for each of the file names 
perform the command in the loop. In this case its unzip. The unzipped files
will be put where you have specific 'path' goes in your local macros.

*/

*

use ${cohort}9_add_HES_data, clear
keep patid
duplicates drop

save ${working_data}9_add_HES_data_patid_only, replace

use ${cohort}9.01_create_secondary_care_admission_dataset, clear
keep patid
duplicates drop

save ${working_data}9.01_create_secondary_care_admission_dataset_patid_only, replace

use ${working_data}9_add_HES_data_patid_only
append using ${working_data}9.01_create_secondary_care_admission_dataset_patid_only

duplicates drop

save ${working_data}9_pc_HES_patid_only, replace



local filelist: dir "`path_orig'" files "*.dta", respectcase
local counter=1
display `filelist'


foreach file of local filelist {
	* Read in the data
	use "`path_orig'/`file'"
	
	* Merge using patid - some files don't have patid so we expect and error to occur, so we use capture
	capture merge m:1 patid using ${working_data}9_pc_HES_patid_only
	capture keep if _m == 3
	capture drop _m
	
	* Now save what we've got in our new folder
	save "`path_mini'/`file'", replace
	
	*I'm not using replace because I don't want something to go wrong and I delete all my data
	
}
*

* And now append the files that have been created.

/*
use  extractDataMini\Consultation_001, clear

forvalues f=2/22 {
	local x=string(`f',"%03.0f")
	append using extractDataMini\Consultation_`x'
}

save extractDataMini\Consultation_mini, replace


use  extractDataMini\DrugIssue_001, clear

forvalues f=2/96 {
	local x=string(`f',"%03.0f")
	append using extractDataMini\DrugIssue_`x'
}


use  extractDataMini\Observation_001, clear

forvalues f=2/84 {
	local x=string(`f',"%03.0f")
	append using extractDataMini\Observation_`x'
}

save extractDataMini\Observation_mini, replace

*/	
	
	
frame reset

macro drop _all

clear

log close



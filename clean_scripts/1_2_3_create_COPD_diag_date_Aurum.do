************************************************************************
clear all
set more off, perm
macro drop _all

global extract  "extractData\" 
global data "workingData\"  
global code "Analysis\Code_lists\" 
***********************************************************************************
*Use the patient_practice file and merge with obs files and COPD codelist to find people with COPD
				
* 84 observations
				
forvalues f=1/84{
local i=string(`f',"%03.0f")
use ${extract}Patient_practice.dta, clear
merge 1:m patid using ${extract}Observation_`i'
keep if _merge==3
drop _merge 

*this is to find people with COPD and also to find the date that they get it
* at this point, the dataset has all observations for which we have a patient ID, linked to the variables in the patient_practice cohort.


merge m:1 medcodeid using ${code}COPD_A    /* medcodeid = observation/consultation files, diagnoses, symptoms, tests etc. prodcodeid = drugs*/
keep if _merge==3
drop _merge
save ${data}copd_aurum_patid_`i', replace   /* loop through. save it each time. only pulls out copd-relevant stuff */

*at this point, we have the previous dataset matched for COPD diagnoses. Only observations with COPD diagnoses remain.
* copd_aurum_patid is the observation file linked with patient data, for COPD diagnoses only.

}


use ${data}copd_aurum_patid_001
forvalues f=2/84{
	local i=string(`f',"%03.0f")
append using ${data}copd_aurum_patid_`i'
}

*all being appended together. At this point it is the whole dataset of COPD-related diagnoses.

*merge m:1 patid using ${extract}Patient_practice.dta
*drop _m

*we merge this back into the patient_practice dataset... which I don't really understand because the patient_practice dataset should be part of it already. 
*It doesn't do anything if you merge it or not so I've commented it out.

*identify first date
*obsdate = date of diagnosis / test

sort patid obsdate   /* Sort in order of patient, and then in order of observation*/
keep if obsdate!=.   /* Remove observations with a missing value - can't work out from that when diagnosis is. */ 
by patid: gen litn=_n   /* Create a variable that numbers the observations within a patient in chronological order */
keep if litn==1      /* Keep the first value. COPD is a chronic disease so they can't undiagnosed so we only need the first one. */
keep patid obsdate    /* Now we just have the diagnosis date*/
duplicates drop       /* */
gen first_copd=obsdate     /* */

format first_copd %td
keep patid first_copd

*This file contains the date of FIRST COPD diagnosis (and only that)
save ${data}first_copd_aurum, replace

******************************************************************


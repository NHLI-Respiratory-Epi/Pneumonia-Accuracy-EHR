/*******************************************************************************

AUTHOR:					AA
DATE: 					22-12-2021
VERSION:				STATA 16.1
DO FILE NAME:			Set up full eligibility

DESCRIPTION OF FILE:	apply all the other uts, criteria etc. 


*******************************************************************************/
clear all
set more off, perm
macro drop _all

capture log close
log using "Analysis\Logs\4_full_eligibility_criteria", replace

global hes_extract "extractHES\"
global cohort "workingCohort\"
global working_data "workingData\"
global extract "extractData\"


*import delimited 21_000468\Final\patient_imd2015_21_000468.txt, stringcols(1) clear
*save "workingData\hes_alt_imd"

*use ${cohort}first_copd_hes_smokelig, clear

use ${cohort}first_copd_aurum, clear 

count

* 706,965


merge m:1 patid using ${extract}patient_practice
keep if _m == 3
drop _m

*Drop the practices that automatically need to be dropped

local pracid_remove "20024 20036 20091 20202 20254 20389 20430 20469 20487 20552 20554 20734 20790 20803 20868 20996 21001 21078 21118 21172 21173 21277 21334 21390 21444 21451 21553 21558 21585"

foreach pracidrem of local pracid_remove {
	
	drop if pracid == `pracidrem'

}

count

*699,566


*Need to be registered for at least a year pre- 2015


gen study_startdate = date("01/01/2015", "DMY")
gen study_prestartdate = date("01/01/2014", "DMY")
gen study_enddate = date("31/12/2019", "DMY")

format study_startdate study_prestartdate study_enddate %td




*drop if their age is less than 35 when they are first diagnosed with COPD
* this also means that noone will be below 35 at the start of the study

drop if first_copd < (dob + 365.25*35)

*5,753 observations dropped

count

*693,813 remain



* Then, the start of the study period is the maximum of: 

/*

Definition of the study population
Our study period will encompass 5 years (January 2015 – December 2019) and we will include individuals from
CPRD to identify records containing pneumonia, asthma, and COPD codes for individual patients. We will
specifically look at the coding of pneumonia in the following group of patients.
• General population
• People with asthma
• People with COPD
The minimum eligibility criteria for inclusion in the base study population will be specified as follows:
• Regular patient status in CPRD
• Male or female gender
• Aged 18 years or over at study entry
• At least 1 year of data prior to study start
• At least one code denoting a pneumonia diagnosis in either CPRD or HES
Individuals will be followed from 1 January 2015, date of current registration, date of their 18th birthday (date of
their 35th birthday for the COPD population), or practice acceptability date, whichever is later. Follow up will
end at death, transfer out date, last collection date from the practice, or 31 December 2019, whichever is
earliest.


*/



*They need to have had COPD for at least a year before the start of the study (which is the 1st Jan 2015). Therefore...:



* study start date is the maximum of: 
* 1st Jan 2015, copd diag date + 1 year, reg start date + 1 year, practice acceptability date

gen start_date = max(study_startdate, first_copd + 365, regstartdate + 365)
gen end_date = min(study_enddate, regenddate, lcd, cprd_ddate)

format start_date end_date %td

*drop if start date is after the study period, or the end date is before the study period, or the start date is after the end date

drop if start_date >= end_date
drop if start_date >= study_enddate
drop if end_date <= study_startdate

*308,235 dropped

count

*385,578

drop if acceptable != 1

* everyone is acceptable at this point

*and now we create an age variable for the age of the patient at the start of the patient's study period

gen age = (start_date - dob)/365.25



* Just keep the variables we need or the variables we've made 
keep patid first_copd age study_startdate study_prestartdate study_enddate start_date end_date

*Can just merge back in any other essential stuff later.


*merge 1:1 patid using "Aurum_linked\patient_imd2015_21_000386_request2

/* none of this is needed because we are just linking on the data available already, but this is the process:

import delimited "Z:\Database guidelines and info\CPRD\CPRD_Latest_Lookups_Linkages_Denominators\Aurum_Linkages_Set_19\linkage_eligibility.txt", stringcols(1) clear 

merge 1:1 patid using ${cohort}first_copd_aurum
*merge 1:1 patid using ${cohort}first_copd_hes_smokelig

count if _m == 2   // not matched
count if _m == 3   // matched

keep if _m == 3
drop _m

codebook hes_e death_e cr_e hes_e lsoa_e

*/

merge 1:1 patid using ${hes_extract}patient_imd2015_21_000468
keep if _m == 3
drop _m

rename imd2015_5 imd_quintile 


save ${cohort}4_full_eligibility_criteria, replace


log close


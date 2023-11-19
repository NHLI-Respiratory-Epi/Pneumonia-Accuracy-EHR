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
log using "Logs/17.6_set_up_dual_therapy", replace


global extract_HES "Aurum_linked\"
global cohort "workingCohort\"
*global working_data "workingData\"
global working_data "workingData\"
global extract "extractDataMini\"
*global codelist "Code_lists\CPRD_Aurum\"

*NOTE - FOR THIS DRUG ISSUE ONE, I HAVE USED EMILY'S NEW CODELIST SAVED IN THE ORIGINAL CODELISTS FOLDER
global codelist "Code_lists\CPRD_Aurum\"

global covar "covariates\"


use ${cohort}10_add_patient_demographics, clear

merge 1:m patid using ${working_data}COPD_meds_combined_clean, keep(match)
drop _m






sort patid issuedate 


*first we need to sort out when laba and lama are being used together but prescribed separately

label list lab1

*keep both of them and create a variable for them
* We ignore laba_ics because if they're on ics they don't count as being on dual therapy

**********we can do these all separately. this one is laba-lama

* = laba, lama, or laba-lama.

* next will be laba_ics: laba, ics, or laba_ics.

* and then will be triple:

*laba, icd, lama, or triple

* for LAMA and LABA, I don't think having 2 sets of prescriptions within 6 months is appropriate because we don't know how long they might be on the drugs before diagnosis. Just do the dates of if they had them prescribed within 2 months of each other.
* it's also not fair if just one laba-lama prescription is a given, but they need two to work it out separately.

*can also have length of time on them.

* we are looking at their prescription within 5 years of diagnosis (first prescription within 5 years).
* then, we need the data on first prescription date (from 5 years previous). 

keep if issuedate < pneumonia_pc_date

keep if issuedate > pneumonia_pc_date - (365.25*5)

* For LABA/ICS, it is more appropriate because patients can be prescribed an ICS temporarily. 
gen byte lama = 1 if groups == 3 | groups == 5 | groups == 8
gen byte laba = 1 if groups == 4 | groups == 5 | groups == 8
gen byte ics = 1 if groups == 6 | groups == 7 | groups == 8



* And we just keep patid issuedate and groups, and the newly created variables

keep patid issuedate lama laba ics

* And rename issuedate as eventdate

rename issuedate eventdate 

* And create a date for lama and a date for laba

gen lama_new_presc = eventdate if lama == 1
gen laba_new_presc = eventdate if laba == 1
gen ics_new_presc = eventdate if ics == 1

format lama_new_presc %td
format laba_new_presc %td
format ics_new_presc %td

* And we just keep observations where laba or lama == 1

keep if laba == 1 | lama == 1 | ics == 1

sort patid eventdate

* Laba and Lama need to be recorded within 2 months of each other to be counted as dual.
* Then, they need to be recorded twice within a 6 months period.

* Let's create a new variable, of most recent lama date and laba date. This variable lists when the patient last had laba or lama

gen lama_most_recent = lama_new_presc
gen laba_most_recent = laba_new_presc
gen ics_most_recent = ics_new_presc

by patid: replace lama_most_recent = lama_most_recent[_n-1] if lama_most_recent == . & lama != 1
by patid: replace laba_most_recent = laba_most_recent[_n-1] if laba_most_recent == . & laba != 1
by patid: replace ics_most_recent = ics_most_recent[_n-1] if ics_most_recent == . & laba != 1

format lama_most_recent %td
format laba_most_recent %td
format ics_most_recent %td


* Let's put it all in a sensible order

order patid lama lama_new_presc lama_most_recent laba laba_new_presc laba_most_recent ics ics_new_presc ics_most_recent eventdate

* if there is overlap between lama and laba of within 2 months, it counts as dual therapy!
* to create this, we subtract the 'most recent' dates - if the different it less than 2 months, it counts as dual.

* A difference of either way is fine.
gen lama_laba_diff = abs(lama_most_recent - laba_most_recent)
gen laba_ics_diff = abs(laba_most_recent - ics_most_recent)

gen lama_laba_overlap = 1 if lama_laba_diff < 61
gen ics_laba_overlap = 1 if laba_ics_diff < 61
gen ics_laba_lama_overlap = 1 if lama_laba_diff < 61 & laba_ics_diff < 61

*for rows whether ics_laba_lama_overlap exists, mark laba_lama_overlap as .

replace lama_laba_overlap = . if ics_laba_lama_overlap == 1
replace ics_laba_overlap = . if ics_laba_lama_overlap == 1

*and we take the latest date for each one for each row to indicate medication.

gen lama_laba_date = max(lama_most_recent, laba_most_recent)
gen ics_laba_date = max(laba_most_recent, ics_most_recent)

replace lama_laba_date = . if lama_laba_overlap == .
replace ics_laba_date = . if ics_laba_overlap == .

gen ics_laba_lama_date = max(laba_most_recent, ics_most_recent, lama_most_recent)
replace ics_laba_lama_date = . if ics_laba_lama_overlap == .

format lama_laba_date %td
format ics_laba_date %td
format ics_laba_lama_date %td


* and now, we keep the first instance  within the 5 years. 
* we will now pick up people who had multile at different points, but we won't have the issue of triple also being classed as dual

sort patid eventdate

egen lama_laba_5yr = max(lama_laba_overlap), by(patid)
egen ics_laba_5yr = max(ics_laba_overlap), by(patid)
egen triple_5yr = max(ics_laba_lama_overlap), by(patid)

egen lama_laba_5yr_date = min(lama_laba_date), by(patid)
egen ics_laba_5yr_date = min(ics_laba_date), by(patid)
egen triple_5yr_date = min(ics_laba_lama_date), by(patid)


format lama_laba_5yr_date %td
format ics_laba_5yr_date %td
format triple_5yr_date %td


* if these minimum dates are within 60 days of each other, keep the triple therapy date only

replace lama_laba_5yr = . if abs(lama_laba_5yr_date - triple_5yr_date) < 61
replace lama_laba_5yr_date = . if abs(lama_laba_5yr_date - triple_5yr_date) < 61

replace ics_laba_5yr = . if abs(ics_laba_5yr_date - triple_5yr_date) < 61
replace ics_laba_5yr_date = . if abs(ics_laba_5yr_date - triple_5yr_date) < 61

* and at this point we create the lama, laba and ics single variables too.

egen lama_5yr = max(lama), by(patid)
egen laba_5yr = max(laba), by(patid)
egen ics_5yr = max(ics), by(patid)

egen lama_5yr_date = min(lama_new_presc), by(patid)
egen laba_5yr_date = min(laba_new_presc), by(patid)
egen ics_5yr_date = min(ics_new_presc), by(patid)

format lama_5yr_date %td
format laba_5yr_date %td
format ics_5yr_date %td

* and keep all the variables we need for each person

by patid: keep if _n == 1

* and now just keep the variables we want:

keep patid lama_laba_5yr-ics_5yr_date

save ${covar}5_year_previous_COPD_meds, replace



* and do the same for saba and sama (but don't need to combine now)

*sama

use ${cohort}10_add_patient_demographics, clear

merge 1:m patid using ${working_data}COPD_meds_combined_clean, keep(match)
drop _m




keep if groups == 1
gen sama_5yr = 1

sort patid issuedate 


*first we need to sort out when laba and lama are being used together but prescribed separately

label list lab1


keep if issuedate < pneumonia_pc_date

keep if issuedate > pneumonia_pc_date - (365.25*5)

egen sama_5yr_date = min(issuedate), by(patid) 
format sama_5yr_date  %td


sort patid
by patid: keep if _n == 1

keep patid sama_5yr sama_5yr_date

save ${covar}sama_5yr, replace



*saba

use ${cohort}10_add_patient_demographics, clear

merge 1:m patid using ${working_data}COPD_meds_combined_clean, keep(match)
drop _m



keep if groups == 2
gen saba_5yr = 1

sort patid issuedate 


*first we need to sort out when laba and lama are being used together but prescribed separately

label list lab1


keep if issuedate < pneumonia_pc_date

keep if issuedate > pneumonia_pc_date - (365.25*5)

egen saba_5yr_date = min(issuedate), by(patid)
format saba_5yr_date  %td

sort patid
by patid: keep if _n == 1

keep patid saba_5yr saba_5yr_date

save ${covar}saba_5yr, replace



*ocs

use ${cohort}10_add_patient_demographics, clear

merge 1:m patid using ${working_data}COPD_meds_combined_clean, keep(match)
drop _m




keep if groups == 9
gen ocs_5yr = 1

sort patid issuedate 


*first we need to sort out when laba and lama are being used together but prescribed separately

label list lab1


keep if issuedate < pneumonia_pc_date

keep if issuedate > pneumonia_pc_date - (365.25*5)

egen ocs_5yr_date = min(issuedate), by(patid)
format ocs_5yr_date  %td

sort patid
by patid: keep if _n == 1

keep patid ocs_5yr ocs_5yr_date

save ${covar}ocs_5yr, replace

log close 


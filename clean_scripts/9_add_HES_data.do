

clear all
set more off, perm
macro drop _all

capture log close
log using "Logs/9_add_HES_data", replace

global hes_extract "extractHES\"
global cohort "workingCohort\"
global working_data "workingData\"
global extract "extractData\"
global codelist "codelists\jkq\"

global covar "covariates\"

*use ${hes_extract}hes_diagnosis_epi_21_000468, clear

/*

*Do a bit of sorting out the episodes.

use ${hes_extract}hes_diagnosis_epi_21_000468, clear


merge m:1 patid using "${cohort}4_full_eligibility_criteria"

* let's restrict it down here a little bit

*merge m:1 patid using "${cohort}99_7_all_algorithms_added.dta"
drop if _m == 1
drop if _m == 2
drop _m
drop first_copd-imd_quintile

* and this is our new little mini hes dataset of relevant patients
save ${hes_extract}hes_diagnosis_epi_21_000468_elig, replace


use ${working_data}hes_diagnosis_epi_21_000468_elig, clear



forvalues x = 1/20  {
	generate icd0`x'=icd if d_order==`x'
}

* make each record represent an episode
collapse (firstnm) icd0*, by (patid spno epikey epistart epiend) //firstnm=first non-missing value


* we only want the first episode


generate epistart2 = date(epistart, "DMY") 
drop epistart 
rename epistart2 epistart
format epistart %td
drop if epistart == .
*18 dropped

generate epiend2 = date(epiend, "DMY") 
drop epiend 
rename epiend2 epiend
format epiend %td
drop if epiend == .
*54 dropped

save ${hes_extract}hes_diagnosis_epi_21_000468_elig_restruc_all_epi, replace


sort patid spno epistart epiend
by patid spno: keep if _n == 1


save ${hes_extract}hes_diagnosis_epi_21_000468_elig_restruc_first_epi, replace



use ${hes_extract}hes_diagnosis_epi_21_000468_elig_restruc_all_epi, clear

sort patid spno epistart epiend

by patid spno: egen admidate = min(epistart)
format admidate %td

by patid spno: keep if _n == _N

drop if admidate == .




save ${hes_extract}hes_diagnosis_epi_21_000468_elig_restruc_last_epi, replace



*/


*run to here!



* now, we only have the last episode with first diagnosis.
* we now merge with our pneumonia cohort.


use ${cohort}99_7_all_algorithms_added.dta, clear
codebook patid


joinby patid using ${hes_extract}hes_diagnosis_epi_21_000468_elig_restruc_last_epi, unmatched(master)
drop _m



codebook patid

*use ${hes_extract}hes_diagnosis_epi_21_000468_elig_restruc_first_epi, clear


*merge m:1 patid using "${cohort}99_7_all_algorithms_added.dta"



*at this point we have all the people with and without being admitted.

* I DON'T THINK WE WANT TO DROP _m == 2...
*drop if _m == 2
*drop _m



/*generate admidate2 = date(admidate, "DMY") 
drop admidate
rename admidate2 admidate
format admidate %td
*/

*rename epistart admidate


gen date_interval = datediff((pneumonia_pc_date), (admidate), "day")



preserve
keep if date_interval <=7 & date_interval >=0
count 
restore

*2,979 with maximise
*2,228 with normal

*but after removing repeats, not worth it. stick with normal version.

*2391 within the correct time period

preserve
keep if date_interval <=14 & date_interval >=0
count 
restore


*I guess we need to do this a bit differently to collect the appropriate data.

gen hosp_7days = 1 if date_interval <=7 & date_interval >= 0
replace hosp_7days = 0 if hosp_7days == .

*we also want hosp_sameday

gen hosp_sameday = 1 if date_interval == 0
replace hosp_sameday = 0 if hosp_sameday == .

codebook patid

*if the date interval lies outside the required dates we reocde it to missing.
replace date_interval = . if date_interval <0 | date_interval >7

*and now we can sort by patient id and date interval

sort patid date_interval

*and just keep the first record, and this shows who was hospitalised within 7 days or not.

tab date_interval hosp_7days

sort patid date_interval
by patid: keep if _n == 1


tab hosp_7days

*2961 if you extend out to 14 days

* let's go for the first version.
*keep if date_interval <=7 & date_interval >=0

*count if date_interval == 0
*1598 people see the GP and then go to hospital

*count if date_interval > 0
*793 people get admitted the day after or more.


*gen icd_pneumo_20 = 0

tab hosp_7days

save ${cohort}9_add_HES_data, replace




ci proportions pneumonia_HES if pneumo_symp2 == 1



ci proportions pneumonia_HES if pneumo_symp2 == 1

*1
table pneumonia_primary hosp_7days, statistic (frequency) statistic(percent, across(hosp_7days))  

*2
table pneumo_symp2 hosp_7days, statistic (frequency) statistic(percent, across(hosp_7days)) 

*3
table chest_xray hosp_7days, statistic (frequency) statistic(percent, across(hosp_7days)) 

*4
table bc_sp_sent2 hosp_7days, statistic (frequency) statistic(percent, across(hosp_7days)) 

*5 
table sputum_positive hosp_7days, statistic (frequency) statistic(percent, across(hosp_7days)) 

*6
table symp_cxray2 hosp_7days, statistic (frequency) statistic(percent, across(hosp_7days)) 

*7
table abx hosp_7days, statistic (frequency) statistic(percent, across(hosp_7days)) 

*8
table symp_abx2 hosp_7days, statistic (frequency) statistic(percent, across(hosp_7days)) 

*9
table cxray_abx2 hosp_7days, statistic (frequency) statistic(percent, across(hosp_7days)) 

*10
table abx_bc_sp_sent2 hosp_7days, statistic (frequency) statistic(percent, across(hosp_7days)) 

*11
table abx_sputum_positive2 hosp_7days, statistic (frequency) statistic(percent, across(hosp_7days)) 

*12
table cxray_bc_sp_sent2 hosp_7days, statistic (frequency) statistic(percent, across(hosp_7days)) 

*13
table cxray_sputum_positive2 hosp_7days, statistic (frequency) statistic(percent, across(hosp_7days)) 

*14
table symp_bc_sp_sent2 hosp_7days, statistic (frequency) statistic(percent, across(hosp_7days)) 

*15
table symp_sputum_positive2 hosp_7days, statistic (frequency) statistic(percent, across(hosp_7days)) 

*16
table cxray_symp_abx2 hosp_7days, statistic (frequency) statistic(percent, across(hosp_7days)) 

*17
table cxray_symp_abx_bc_sp_sent2 hosp_7days, statistic (frequency) statistic(percent, across(hosp_7days)) 

*18
table cxray_symp_abx_blood_sputum_pos2 hosp_7days, statistic (frequency) statistic(percent, across(hosp_7days)) 



*collect layout (pneumonia_primary#result pneumo_symp2#result bc_sp_sent2#result) (hosp_7days#result)


*At this point, we just keep those that ended up in hospital

keep if hosp_7days == 1


tab date_interval


count if date_interval == 0
count if date_interval != 0


* restrict to just zero day...

* and we go through the tables again, but for pneumonia diagnosis in HES.


*1
table pneumonia_primary pneumonia_HES, statistic (frequency) statistic(percent, across(pneumonia_HES))  

*2
table pneumo_symp2 pneumonia_HES, statistic (frequency) statistic(percent, across(pneumonia_HES)) 

*3
table chest_xray pneumonia_HES, statistic (frequency) statistic(percent, across(pneumonia_HES)) 

*4
table bc_sp_sent2 pneumonia_HES, statistic (frequency) statistic(percent, across(pneumonia_HES)) 

*5 
table sputum_positive pneumonia_HES, statistic (frequency) statistic(percent, across(pneumonia_HES)) 

*6
table symp_cxray2 pneumonia_HES, statistic (frequency) statistic(percent, across(pneumonia_HES)) 

*7
table abx pneumonia_HES, statistic (frequency) statistic(percent, across(pneumonia_HES)) 

*8
table symp_abx2 pneumonia_HES, statistic (frequency) statistic(percent, across(pneumonia_HES)) 

*9
table cxray_abx2 pneumonia_HES, statistic (frequency) statistic(percent, across(pneumonia_HES)) 

*10
table abx_bc_sp_sent2 pneumonia_HES, statistic (frequency) statistic(percent, across(pneumonia_HES)) 

*11
table abx_sputum_positive2 pneumonia_HES, statistic (frequency) statistic(percent, across(pneumonia_HES)) 

*12
table cxray_bc_sp_sent2 pneumonia_HES, statistic (frequency) statistic(percent, across(pneumonia_HES)) 

*13
table cxray_sputum_positive2 pneumonia_HES, statistic (frequency) statistic(percent, across(pneumonia_HES)) 

*14
table symp_bc_sp_sent2 pneumonia_HES, statistic (frequency) statistic(percent, across(pneumonia_HES)) 

*15
table symp_sputum_positive2 pneumonia_HES, statistic (frequency) statistic(percent, across(pneumonia_HES)) 

*16
table cxray_symp_abx2 pneumonia_HES, statistic (frequency) statistic(percent, across(pneumonia_HES)) 

*17
table cxray_symp_abx_bc_sp_sent2 pneumonia_HES, statistic (frequency) statistic(percent, across(pneumonia_HES)) 

*18
table cxray_symp_abx_blood_sputum_pos2 pneumonia_HES, statistic (frequency) statistic(percent, across(pneumonia_HES)) 


* ------- *

* And we do all the PPVs.



*1
ci proportions pneumonia_HES if pneumonia_primary == 1

*2
ci proportions pneumonia_HES if pneumo_symp2 == 1

*3
ci proportions pneumonia_HES if  chest_xray == 1

*4
ci proportions pneumonia_HES if  bc_sp_sent2 == 1

*5 
ci proportions pneumonia_HES if  sputum_positive == 1

*6
ci proportions pneumonia_HES if  symp_cxray2 == 1

*7
ci proportions pneumonia_HES if  abx == 1

*8
ci proportions pneumonia_HES if  symp_abx2 == 1

*9
ci proportions pneumonia_HES if  cxray_abx2 == 1

*10
ci proportions pneumonia_HES if  abx_bc_sp_sent2 == 1

*11
ci proportions pneumonia_HES if  abx_sputum_positive2 == 1

*12
ci proportions pneumonia_HES if  cxray_bc_sp_sent2 == 1

*13
ci proportions pneumonia_HES if  cxray_sputum_positive2 == 1

*14
ci proportions pneumonia_HES if  symp_bc_sp_sent2 == 1

*15
ci proportions pneumonia_HES if  symp_sputum_positive2 == 1

*16
ci proportions pneumonia_HES if  cxray_symp_abx2 == 1

*17
ci proportions pneumonia_HES if  cxray_symp_abx_bc_sp_sent2 == 1

*18
ci proportions pneumonia_HES if  cxray_symp_abx_blood_sputum_pos2 == 1




*chi-square test: 
* proof that it is equivalent to looking at the subset of the population: https://www.statalist.org/forums/forum/general-stata-discussion/general/59830-statistical-test-of-subpopulation-vs-entire-population-using-jackknife-standard-errors

tab pneumo_symp2 pneumonia_HES, chi2

tab pneumonia_HES 

*1
tab pneumonia_HES pneumonia_primary, chi2

*2
tab pneumonia_HES  pneumo_symp2, chi2

*3
tab pneumonia_HES  chest_xray, chi2

*4
tab pneumonia_HES  bc_sp_sent2, chi2

*5 
tab pneumonia_HES  sputum_positive, chi2

tabi 957 1 \ 1305 2
tabi 958 1 \ 1307 2


*6
tab pneumonia_HES  symp_cxray2, chi2

tabi 957 1 \ 1307 0



*7
tab pneumonia_HES  abx, chi2
tabi 795 163 \ 1150 157
tabi 958 163 \ 1307 157



*8
tab pneumonia_HES  symp_abx2, chi2

*9
tab pneumonia_HES  cxray_abx2, chi2

*10
tab pneumonia_HES  abx_bc_sp_sent2, chi2

*11
tab pneumonia_HES abx_sputum_positive2, chi2

*12
tab pneumonia_HES  cxray_bc_sp_sent2, chi2

*13
tab pneumonia_HES  cxray_sputum_positive2, chi2

*14
tab pneumonia_HES  symp_bc_sp_sent2, chi2

*15
tab pneumonia_HES  symp_sputum_positive2, chi2

*16
tab pneumonia_HES  cxray_symp_abx2, chi2

*17
tab pneumonia_HES  cxray_symp_abx_bc_sp_sent2, chi2

*18
tab pneumonia_HES  cxray_symp_abx_blood_sputum_pos2, chi2







tab cxray_abx2 pneumonia_HES, 

table pneumonia_primary pneumo_symp2 hosp_7days

table (hosp_7days) (pneumonia_primary pneumo_symp2)


*table pneumo_term disease, statistic(percent, across( disease_HES))

*1870 people have a single episode.
*396 people have multiple episodes.


*1


ci proportions icd_pneumo_20 if hosp_sameday == 1 

*PPV goes up to 73.9% (71.7% to 76.1%) if using the strictest criteria


tab icd_pneumo_20 hosp_sameday



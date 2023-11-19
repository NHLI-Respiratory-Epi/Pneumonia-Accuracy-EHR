clear all
set more off, perm
macro drop _all

capture log close
log using "Logs/7_data_prep_and_algorithms", replace

global hes_extract "extractHES\"
global cohort "workingCohort\"
global working_data "workingData\"
global extract "extractData\"
global codelist "codelists\jkq\"

global covar "covariates\"



 ********pneumonia************* 

 
use "${working_data}pneumonia_lrti_during_SP" , clear
 
* How many overall with pneumonia?

count if pneumonia == 1 


*how many individual patients?

codebook patid

* how many of these are hospital-acquired?

count if hospital_acquired == 1




* How does this compare if we just keep those diagnosed and entered on the same date?
 
use "${working_data}pneumonia_lrti_SP_enter_obs_same" , clear

count if pneumonia == 1


keep if pneumonia == 1

count if hospital_acquired == 1




* we are not interested in hospital-acquired cases so we remove these.

keep if pneumonia == 1 & hospital_acquired != 1

count




* remove records within 14 days of each other.

  
*Drop events within 15 days of each other
sort patid obsdate
gen datelastobs = .
by patid: replace datelastobs = obsdate[_n-1]
format datelastobs %td

gen duration = obsdate - datelastobs
drop if duration < 15
drop duration datelastobs

count

codebook patid

by patid: gen bigN = _N

preserve 
by patid: keep if _n == 1
tab bigN
restore


by patid: keep if _n == 1

* and this is our final pneumonia diagnosis list (for  this part)

rename obsdate pneumonia_pc_date
rename medcodeid pneumo_medcodeid
rename term pneumo_term 

keep patid pneumonia_pc_date pneumo_medcodeid pneumo_term

*and save.

save ${working_data}pneumonia_first_diag_pc_clean, replace

count

* we can attach all the algorithm stuff here anyway, and remove according to whether they've been admitted to hospital later.


/*

keep patid obsdate pneumonia
merge m:1 patid using "${cohort}HES_linkage_set19_final.dta"
keep if _m ==3
drop _m
codebook patid 
save "${working_data}pneumonia_first_diag_pc_clean", replace

*/

* !!!! this is the cohort that makes pneumonia 4 !!!!!

*********antibiotics use********

use "${working_data}abx_codelist_jkq_2.dta", clear

*check out the durations

sum duration
codebook duration

count
count if duration > 0
count if duration == 0

*we lose 123,150 observations that have a duration of 0...

* oh well. for now it's fine.

*dropping observations with prescription that falls outside 5-14 days
drop if duration < 5
drop if duration > 14 

gen abx=1



**merge with pneumonia file to know the number of patients that have with pneumonia that were prescribed abx

*create antibiotics any, and antibiotics 5-14 days
 
joinby patid using "${working_data}pneumonia_first_diag_pc_clean", unmatched(master)
keep if _m ==3
drop _m

** Identify patient that were prescribed antibiotics within 7 days of pneumonia events
gen date_interval = datediff((pneumonia_pc_date), (issuedate), "day")
keep if date_interval <=7 & date_interval >=-7

keep patid abx
duplicates drop

save "${covar}abx_7days.dta", replace


* actually, also do abx all


use "${working_data}abx_codelist_jkq_2.dta", clear

*check out the durations

gen abx_all_dur=1



**merge with pneumonia file to know the number of patients that have with pneumonia that were prescribed abx

*create antibiotics any, and antibiotics 5-14 days
 
joinby patid using "${working_data}pneumonia_first_diag_pc_clean", unmatched(master)
keep if _m ==3
drop _m

** Identify patient that were prescribed antibiotics within 7 days of pneumonia events
gen date_interval = datediff((pneumonia_pc_date), (issuedate), "day")
keep if date_interval <=7 & date_interval >=-7

keep patid abx_all_dur
duplicates drop

save "${covar}abx_all_dur_7days.dta", replace




/*
*********OCS use*********************
use "${drugs}DrugIssue_all8.dta", clear
merge m:1 prodcodeid using"${meds}copd_meds_final_2.dta" 
keep if _m == 3
drop _m
gen ocs=1 if groups==11
recode ocs .=0
drop groups
keep if ocs == 1
sort patid issuedate
merge m:1 patid using "${cohort}HES_linkage_set19_final.dta"
keep if _m ==3
drop _m  
codebook patid
**merge with pneumonia file 
joinby patid using "${working_data}pneumonia_first_diag_pc_clean", unmatched(master)
keep if _m ==3
drop _m
*identify events in  that ocur in7 days window
gen date_interval = datediff((obsdate), (issuedate), "day")
keep if date_interval <=7 & date_interval >=-7
keep patid obsdate ocs issuedate date_interval
rename issuedate issuedate_ocs
save "${cohort2}ocs2.dta", replace

*/

*****symptoms*******************************
**Breathelessness

use ${working_data}breathless_3_jkq_2, clear

**merge with pneumonia file
joinby patid using "${working_data}pneumonia_first_diag_pc_clean", unmatched(master)
keep if _m ==3
drop _m

codebook patid

*identify patients that have codes for pneumonia and breathlessness within 7 days
gen date_interval = datediff((pneumonia_pc_date), (obsdate), "day")
keep if date_interval <=7 & date_interval >=-7

count

tab breathless_yes

*save as having the diagnosis within 7 days.

codebook patid

* we only need to match on patid, because we only have one pneumonia event per person.

keep patid breathless_yes 
rename breathless_yes breathless

duplicates drop 

save "${covar}breathless_7days.dta", replace

 
  
  **Cough**********
  
  
use ${working_data}cough_jkq_2, clear

**merge with pneumonia file
joinby patid using "${working_data}pneumonia_first_diag_pc_clean", unmatched(master)
keep if _m ==3
drop _m

codebook patid

*identify patients that have codes for pneumonia and breathlessness within 7 days
gen date_interval = datediff((pneumonia_pc_date), (obsdate), "day")
keep if date_interval <=7 & date_interval >=-7

count

tab cough
tab acute_cough


*save as having the diagnosis within 7 days.

codebook patid

* we only need to match on patid, because we only have one pneumonia event per person.

keep patid cough 
duplicates drop 

save "${covar}cough_7days.dta", replace




****fever********

 
use ${working_data}fever_3_jkq_2, clear

**merge with pneumonia file
joinby patid using "${working_data}pneumonia_first_diag_pc_clean", unmatched(master)
keep if _m ==3
drop _m

codebook patid

*identify patients that have codes for pneumonia and breathlessness within 7 days
gen date_interval = datediff((pneumonia_pc_date), (obsdate), "day")
keep if date_interval <=7 & date_interval >=-7

count

*save as having the diagnosis within 7 days.

codebook patid

* we only need to match on patid, because we only have one pneumonia event per person.

keep patid fever
duplicates drop 

save "${covar}fever_7days.dta", replace


***Lethargy****

*local codelistlist "pneumonia_lrti AECOPD blood_culture_3_jkq_positive blood_culture_3_jkq_sent BMI breathless_3_jkq_2 chest_x_ray_3_jkq_2 cough_jkq_2 fever_3_jkq_2 lethargy_3_jkq_2 mrc_breathless_final_2 sputum_final_2_jkq_abnormal sputum_final_2_jkq_positive sputum_final_2_jkq_sent tachycardia_3_jkq_2"

use ${working_data}lethargy_3_jkq_2, clear

**merge with pneumonia file
joinby patid using "${working_data}pneumonia_first_diag_pc_clean", unmatched(master)
keep if _m ==3
drop _m

codebook patid
count

*identify patients that have codes for pneumonia and breathlessness within 7 days
gen date_interval = datediff((pneumonia_pc_date), (obsdate), "day")
keep if date_interval <=7 & date_interval >=-7

count

*save as having the diagnosis within 7 days.
codebook patid

* we only need to match on patid, because we only have one pneumonia event per person.

keep patid lethargy
duplicates drop 

save "${covar}lethargy_7days.dta", replace



  
****Tachycardia******** 


use ${working_data}tachycardia_3_jkq_2, clear

**merge with pneumonia file
joinby patid using "${working_data}pneumonia_first_diag_pc_clean", unmatched(master)
keep if _m ==3
drop _m

codebook patid
count

*identify patients that have codes for pneumonia and breathlessness within 7 days
gen date_interval = datediff((pneumonia_pc_date), (obsdate), "day")
keep if date_interval <=7 & date_interval >=-7

count

*save as having the diagnosis within 7 days.
codebook patid

* we only need to match on patid, because we only have one pneumonia event per person.

tab tachycardia

keep patid tachycardia
duplicates drop 
save "${covar}tachycardia_7days.dta", replace



  
/*
***Tachypnoea********
clear all
use "${observation2}Observation_all6b.dta " , clear
merge m:1 medcodeid using "${codelists}tachypnoea.dta" 
keep if _merge == 3
drop _m
gen tachyp_1 = 1
keep patid tachyp_1 obsdate
sort patid obsdate
merge m:1 patid using "${cohort}HES_linkage_set19_final.dta"
keep if _merge ==3
drop _m
joinby patid using "${working_data}pneumonia_first_diag_pc_clean", unmatched(master)
keep if _m ==3
drop _m
*Identify patients that had tachypnoea and pneumonia within 7 day window
gen date_interval = datediff((obsdate), (obsdate), "day")
keep if date_interval <=7 & date_interval >=-7
keep patid tachyp_1 obsdate obsdate date_interval
rename obsdate obsdate_tachyp
save "${cohort2}tachypnoea.dta", replace
 */
 
***blood culture taken (sent)


use ${working_data}blood_culture_3_jkq_sent, clear

**merge with pneumonia file
joinby patid using "${working_data}pneumonia_first_diag_pc_clean", unmatched(master)
keep if _m ==3
drop _m

codebook patid
count

*identify patients that have codes for pneumonia and breathlessness within 7 days
gen date_interval = datediff((pneumonia_pc_date), (obsdate), "day")
keep if date_interval <=7 & date_interval >=-7

count

*save as having the diagnosis within 7 days.
codebook patid

* we only need to match on patid, because we only have one pneumonia event per person.


rename sent blood_sent

keep patid blood_sent
duplicates drop 
save "${covar}blood_sent_7days.dta", replace


  
*** positive blood culture**

* no one has positive blood culture, so skip.

/*use ${working_data}blood_culture_3_jkq_positive, clear

**merge with pneumonia file
joinby patid using "${working_data}pneumonia_first_diag_pc_clean", unmatched(master)
keep if _m ==3
drop _m

codebook patid
count

*identify patients that have codes for pneumonia and breathlessness within 7 days
gen date_interval = datediff((pneumonia_pc_date), (obsdate), "day")
keep if date_interval <=7 & date_interval >=-7

count

*save as having the diagnosis within 7 days.
codebook patid

* we only need to match on patid, because we only have one pneumonia event per person.

tab sent

tab tachycardia

rename positive blood_positive

keep patid 
duplicates drop 
save "${covar}blood_positive_7days.dta", replace

*/
  
  
***Chest-x-ray****


use ${working_data}chest_x_ray_3_jkq_2, clear

**merge with pneumonia file
joinby patid using "${working_data}pneumonia_first_diag_pc_clean", unmatched(master)
tab _m
keep if _m ==3
drop _m

codebook patid
count

*identify patients that have codes for pneumonia and breathlessness within 7 days
gen date_interval = datediff((pneumonia_pc_date), (obsdate), "day")
keep if date_interval <=7 & date_interval >=-7

count

*save as having the diagnosis within 7 days.
codebook patid

* we only need to match on patid, because we only have one pneumonia event per person.

tab chest_x_ray

rename chest_x_ray chest_xray

keep patid chest_xray
duplicates drop 
save "${covar}chest_xray_7days.dta", replace


  
/*  
 *****Sputum******
clear all
use "${observation2}Observation_all6b.dta " , clear
merge m:1 medcodeid using  "${codelists}sputum.dta" 
keep if _merge == 3
drop _m
gen sputum = 1
keep patid sputum obsdate
sort patid obsdate
merge m:1 patid using "${cohort}HES_linkage_set19_final.dta"
keep if _merge ==3
drop _m
joinby patid using "${working_data}pneumonia_first_diag_pc_clean", unmatched(master)

*Identify patients that had code for sputum and pneumonia  in 7 days window
gen date_interval = datediff((obsdate), (obsdate), "day")
keep if date_interval <=7 & date_interval >=-7 
keep patid sputum  obsdate obsdate date_interval
rename obsdate obsdate_sputum
save "${cohort2}sputum.dta", replace
*/


****sputum sent



use ${working_data}sputum_final_2_jkq_sent.dta, clear

**merge with pneumonia file
joinby patid using "${working_data}pneumonia_first_diag_pc_clean", unmatched(master)
tab _m
keep if _m ==3
drop _m

codebook patid
count

*identify patients that have codes for pneumonia and breathlessness within 7 days
gen date_interval = datediff((pneumonia_pc_date), (obsdate), "day")
keep if date_interval <=7 & date_interval >=-7

count

*save as having the diagnosis within 7 days.
codebook patid

* we only need to match on patid, because we only have one pneumonia event per person.

tab sent positive, m 
tab sent abnormal, m 
tab positive abnormal, m 

rename sent sputum_sent
rename positive sputum_positive
rename abnormal sputum_abnormal

*just do it all here as all info contained here, rather than reading in 
* positive, abnormal codelists etc.

preserve
keep patid sputum_sent
duplicates drop 
save "${covar}sputum_sent_7days.dta", replace
restore

preserve
keep if sputum_positive == 1
keep patid sputum_positive
duplicates drop 
save "${covar}sputum_positive_7days.dta", replace
restore
  
preserve
keep if sputum_abnormal == 1
keep patid sputum_abnormal
duplicates drop 
save "${covar}sputum_abnormal_7days.dta", replace
restore
  

 * Now.... put them all together.
 
**merge to determine patients characteristics

use "${working_data}pneumonia_first_diag_pc_clean", clear

* rename obsdate primary_pneumonia_obsdate


joinby patid using"${covar}abx_7days.dta", unmatched(master)
drop _merge 
  
/* 
*OCS
joinby patid using "${cohort2}ocs2.dta", unmatched(master)
drop  obsdate _merge issuedate date_interval
*/

*Breathlessness

joinby patid using "${covar}breathless_7days.dta", unmatched(master)
drop _m  

*Cough
joinby patid using "${covar}cough_7days.dta", unmatched(master)
drop _m 

*fever
joinby patid using "${covar}fever_7days.dta", unmatched(master)
drop _m 

*Lethargy
joinby patid using "${covar}lethargy_7days.dta", unmatched(master)
drop _m 

*Tachycardia
joinby patid using "${covar}tachycardia_7days.dta", unmatched(master)
drop _m 

/*
*Tachypnoea
joinby patid obsdate using "${cohort2}tachypnoea.dta", unmatched(master)
drop _m obsdate_tachyp 
*/

*Blood culture taken
joinby patid using "${covar}blood_sent_7days.dta", unmatched(master)
drop _m 

* no observations matching blood culture positive codelist

*therefore:

gen blood_positive = 0
label define bloodpositive 1 "blood positive" 0 "no positive blood result"
label values blood_positive bloodpositive

/*blood_culture_positive
joinby patid obsdate using "${cohort2}blood_culture_positive.dta", unmatched(master)
drop _m obsdate_bcul date_interval
*/

*Chest-xray
joinby patid using "${covar}chest_xray_7days.dta", unmatched(master)
drop _m 

/*
*sputum
joinby patid obsdate using "${cohort2}sputum.dta", unmatched(master)
drop _m obsdate_sputum date_interval
*/

*sputum sent
joinby patid using "${covar}sputum_sent_7days.dta", unmatched(master)
drop _m 

*sputum culture positive
joinby patid using "${covar}sputum_positive_7days.dta", unmatched(master)
drop _m 

*sputum looks abnormal
joinby patid using "${covar}sputum_abnormal_7days.dta", unmatched(master)
drop _m 

**assigning value labels
*************************
  *antibiotics
recode abx .=0
label define abxlabel 1 "antibiotics prescribed" 0 "no antibiotics precribed"
label values abx abxlabel
 
/* 
 *ocs
 recode ocs . = 0
label define ocslabel 1 "yes" 0 "no"
label values ocs ocslabel



 **blood culture
 recode bculture . = 0
label define bclabel 1 "blood culture" 0 "no blood culture"
label values  bculture  bclabel

*/ 
 
 *blood culture taken
 recode blood_sent . = 0
label define bctlabel 1 "yes" 0 "no"
label values blood_sent bctlabel

*Chest-xray
recode chest_xray . = 0
label define xraylabel 1 "chest x-ray" 0 "no chest x-ray"
label values chest_xray xraylabel
 
/* 
 *sputum
 recode sputum . = 0
label define splabel 1 "sputum" 0 "no sputum"
label values sputum splabel
*/


*sputum sent
recode sputum_sent . = 0
label define splabel2 1 "yes" 0 "no"
label values sputum_sent splabel2

*sputum looks abnormal
recode sputum_abnormal . = 0
label define splabel3 1 " yes" 0 "no"
label values sputum_abnormal splabel3

*positive sputum culture
recode sputum_positive . = 0
label define splabel4 1 "yes" 0 "no"
label values sputum_positive splabel4

*breathlessness
recode breathless .=0
label define brlabel 1 "yes" 0 "no"
label values breathless brlabel

*cough
recode cough . = 0
label define clabel 1 "yes" 0 "no cough"
label values cough clabel

*fever
recode fever . = 0
label define fevlabel 1 "yes" 0 "no"
label values fever fevlabel

*lethargy

recode lethargy . = 0
label define lethlabel  1 "yes" 0 "no"
label values lethargy lethlabel

*Tachycardia
recode tachycardia . = 0
label define tachylabel 1 "yes" 0 "no"
label values tachycardia tachylabel

/*
*Tachypnoea
recode  tachyp . = 0
label define tachyplabel 1 "yes" 0 "no"
label values tachyp tachyplabel
*/

  
  
*1) Pneumonia 
gen pneumonia_primary = 1

*(2) Pneumonia code and symptoms of pneumonia (include two of the following symptoms, new cough, sputum, lethargy, fever, tachycardia, breathlessness)
egen pneumo_symp = rowtotal( breath cough lethargy fever tachycardia sputum_sent)
 generate pneumo_symp2  = 0
replace pneumo_symp2 = 1 if pneumo_symp >= 2
label define pslabel  1 "yes" 0 "no"
label values pneumo_symp2 pslabel
 
*(3) pneumonia code and chest x-ray referal
 tab chest_xray 
 
*(4) Pneumonia code and evidence of sputum or blood culture sent
egen bc_sp_sent = rowtotal (blood_sent sputum_sent)
gen bc_sp_sent2 = 0
replace bc_sp_sent2 =1 if bc_sp_sent >=1 
label define bcslabel 1 "yes" 0 "no"
label values bc_sp_sent2 bcslabel  
 tab bc_sp_sent2 
 
**(5) Pneumonia code and evidence of sputum or blood culture positive result
* no observations for blood culture positive
* same as sputum positive result
tab sputum_positive


**(6)Pneumonia code and symptoms of pneumonia and referral for chest X-ray
egen symp_cxray = rowtotal( pneumo_symp2 chest_xray)
gen symp_cxray2 = 0
replace symp_cxray2 = 1 if symp_cxray ==2
label define scxlabel  0 "no" 1"yes"
label values symp_cxray2 scxlabel 

**(7)Pneumonia code and antibiotics
tab abx 

**(8) Pneumonia code, symptoms and antibiotics
egen symp_abx = rowtotal( pneumo_symp2 abx)
gen symp_abx2 = 0
replace symp_abx2 = 1 if symp_abx ==2
label define sabxlabel  0 "no" 1"yes"
label values symp_abx2 sabxlabel 

**(9) Pneumonia code, referral for chest X-ray, and antibiotics 
egen cxray_abx = rowtotal( chest_xray abx)
gen cxray_abx2 = 0
replace cxray_abx2 = 1 if cxray_abx ==2
label define cxabxlabel  0 "no" 1"yes"
label values cxray_abx2 cxabxlabel 

**(10) Pneumonia code, antibiotics and evidence of sputum or blood culture sent
egen abx_bc_sp_sent = rowtotal(bc_sp_sent2  abx)
gen abx_bc_sp_sent2 = 0
replace abx_bc_sp_sent2 = 1 if abx_bc_sp_sent ==2
label define abxbcslabel  0 "no" 1"yes"
label values abx_bc_sp_sent2 abxbcslabel 

*(11) Pneumonia code, antibiotics and evidence of sputum or blood culture positive result
* no observations for blood culture positive
* same as sputum positive result
egen abx_sputum_positive = rowtotal(sputum_positive  abx)
gen abx_sputum_positive2 = 0
replace abx_sputum_positive2 = 1 if abx_sputum_positive ==2
label define abxsplabel  0 "no" 1"yes"
label values abx_sputum_positive2 abxsplabel 

*(12) Pneumonia code, referral for chest X-ray, and evidence of sputum or blood culture sent
egen cxray_bc_sp_sent = rowtotal (chest_xray bc_sp_sent2)
gen cxray_bc_sp_sent2 = 0
replace cxray_bc_sp_sent2 =1 if cxray_bc_sp_sent ==2 
label define cxbslabel 1 "yes" 0 "no"
label values cxray_bc_sp_sent2 cxbslabel 

**(13) Pneumonia code, referral for chest X-ray, and evidence of sputum or blood culture positive result
* no observations for blood culture positive
* same as sputum positive result
egen cxray_sputum_positive = rowtotal(sputum_positive  chest_xray)
gen cxray_sputum_positive2 = 0
replace cxray_sputum_positive2 = 1 if cxray_sputum_positive ==2
label define cxsplabel  0 "no" 1"yes"
label values cxray_sputum_positive2 cxsplabel 

**(14) Pneumonia code, symptoms of pneumonia and evidence of sputum or blood culture sent
egen symp_bc_sp_sent = rowtotal (pneumo_symp2 bc_sp_sent2)
gen symp_bc_sp_sent2 = 0
replace symp_bc_sp_sent2 =1 if symp_bc_sp_sent ==2 
label define sysbclabel 1 "yes" 0 "no"
label values symp_bc_sp_sent2 sysbclabel 

**(15) Pneumonia code, symptoms of pneumonia and evidence of sputum or blood culture positive result
* no observations for blood culture positive
* same as sputum positive result
egen symp_sputum_positive = rowtotal(sputum_positive  pneumo_symp2)
gen symp_sputum_positive2 = 0
replace symp_sputum_positive2 = 1 if symp_sputum_positive ==2
label define symsplabel  0 "no" 1"yes"
label values symp_sputum_positive2 symsplabel 

**(16)	Pneumonia code, referral for chest X-ray, symptoms of pneumonia and antibiotics
egen cxray_symp_abx = rowtotal(chest_xray pneumo_symp2 abx)
gen cxray_symp_abx2 = 0 
replace cxray_symp_abx2 = 1 if cxray_symp_abx ==3
label define cxsablabel 1 "yes" 0 "no"
label values cxray_symp_abx2 cxsablabel 

**(17) Pneumonia code, referral for chest X-ray, symptoms of pneumonia and antibiotics and evidence of sputum or blood culture sent
egen cxray_symp_abx_bc_sp_sent = rowtotal(chest_xray pneumo_symp2 abx bc_sp_sent2)
gen cxray_symp_abx_bc_sp_sent2 = 0 
replace cxray_symp_abx_bc_sp_sent2 = 1 if cxray_symp_abx_bc_sp_sent ==4
label define cxsabslabel 1 "yes" 0 "no"
label values cxray_symp_abx_bc_sp_sent2 cxsabslabel 

** (18)	Pneumonia code, referral for chest X-ray, symptoms of pneumonia and antibiotics and evidence of sputum or blood culture positive result
* no observations for blood culture positive
* same as sputum positive result
egen cxray_symp_abx_blood_sputum_pos = rowtotal(chest_xray pneumo_symp2 abx sputum_positive)
gen cxray_symp_abx_blood_sputum_pos2 = 0
replace cxray_symp_abx_blood_sputum_pos2 = 1 if cxray_symp_abx_blood_sputum_pos == 4
label define cxsabplabel 1 "yes" 0 "no"
label values cxray_symp_abx_blood_sputum_pos2 cxsabplabel 
   
save "${cohort}99_7_all_algorithms_added.dta",replace



log close



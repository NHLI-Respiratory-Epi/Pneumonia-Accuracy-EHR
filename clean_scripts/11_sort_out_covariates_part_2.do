/*******************************************************************************

AUTHOR:					AA
DATE: 					24-12-2021
VERSION:				STATA 16.1
DO FILE NAME:			10_sort_out_covariates

DESCRIPTION OF FILE:	


*******************************************************************************/

capture log close
log using "Logs/11_sort_out_covariates_part_2", replace

global hes_extract "Aurum_linked\"
global cohort "workingCohort\"
*global working_data "workingData\"
global working_data "workingData\"
global extract "extractDataMini\"
*global codelist "Code_lists\CPRD_Aurum\"

*NOTE - FOR THIS DRUG ISSUE ONE, I HAVE USED EMILY'S NEW CODELIST SAVED IN THE ORIGINAL CODELISTS FOLDER
global codelist "codelists\jkq\"

global covar "covariates\"
	

*list of all the code lists to sort out here: 
	
/* anaemia_clean
 annual_review_clean 
 anxiety_clean 
 asthma_clean 
 atrial_fibrillation_clean 
 BMI 
 chest_xray_clean 
 depression_clean 
 diabetes_clean 
 hf_clean 
 hypertension_clean 
 pulmonary_rehab_clean 
 referral_clean 
 smoking_cessation_obs_clean 
 smoking_status 
 spirometry 
 stroke_clean
 full_blood_count_clean
 
 CCI!!!
 
 oxygen_clean
 COPD_meds_combined_clean 
 smoking_cessation_drugs_clean
 
 */

**** anaemia
use ${working_data}anaemia_clean_most_recent, clear

*drop crazy values (i.e. before patient is born)
* we read in the most recent value so if this is before patient is born, it means it's missing

*drop if anaemia_clean_date < pneumonia_pc_date - (age*365.25)

gen anaemia_to_diag = pneumonia_pc_date - anaemia_clean_date
codebook anaemia_clean_date 
keep patid anaemia_clean_date anaemia_to_diag anaemia
rename anaemia_clean_date anaemia_date
 
save ${covar}anaemia, replace
*********

 
**** annual_review
use ${working_data}annual_review_clean, clear


keep if obsdate >= pneumonia_pc_date
keep if obsdate < pneumonia_pc_date + 365.25

sort patid obsdate
by patid: keep if _n == 1

rename obsdate COPD_review_1yr_date
rename annual_review COPD_review_1yr

keep patid COPD_review_1yr COPD_review_1yr_date

save ${covar}annual_review, replace

* Alot of people have their review on the same day as their first diagnosis of COPD. 
* I have checked the COPD incident codelist hower, and there is no overlap between the two. 
*Therefore, I conclude that people really are being diagnosed and receiving their review on the same day. 
*********



*******************
*  anxiety       
*******************

use ${working_data}anxiety_clean_most_recent, clear

*drop crazy values (i.e. before patient is born)
* we read in the most recent value so if this is before patient is born, it means it's missing

*drop if anxiety_clean_date < pneumonia_pc_date - (age*365.25)

gen anxiety_to_diag = pneumonia_pc_date - anxiety_clean_date
sum anxiety_to_diag
codebook anxiety_clean_date 
keep patid anxiety_clean_date anxiety_to_diag anxiety
rename anxiety_clean_date anxiety_date
 
save ${covar}anxiety, replace
*********

*******************
*  asthma       
*******************

* Now, we create a variable that looks at the time difference between when the asthma diagnosis occurred and when the COPD diagnosis occurred. 
* As per Jenni's email: 0-2 years previous is misclassification of COPD. 3-5 years is proper COPD. 


* for asthma, we need to remove misdiagnoses. 
* to do this, we remove those that occur up to two years before COPD diagnosis. 

use ${working_data}asthma_clean_most_recent, clear

*drop crazy values (i.e. before patient is born)
* we read in the most recent value so if this is before patient is born, it means it's missing

*drop if asthma_clean_date < pneumonia_pc_date - (age*365.25)

*this is asthma diag any time before
gen asthma_to_diag_any = pneumonia_pc_date - asthma_clean_date
sum asthma_to_diag_any
codebook asthma_clean_date 
keep patid asthma_clean_date asthma_to_diag_any asthma
rename asthma_clean_date asthma_date_any_pre
rename asthma asthma_any_pre
 
save ${covar}asthma_any_pre, replace

* now we do it with the two year period removed.

use ${working_data}asthma_clean_pre_diagnosis, clear

*drop crazy values (i.e. before patient is born)
* we read in the most recent value so if this is before patient is born, it means it's missing

*drop if obsdate < pneumonia_pc_date - (age*365.25)

*and also the two year period...

drop if obsdate > pneumonia_pc_date - (2*365.25)


*and now we take the most recent asthma obs. 

sort patid obsdate

by patid: keep if _n == _N

rename obsdate asthma_date

*this is asthma diag any time before
gen asthma_to_diag = pneumonia_pc_date - asthma_date
sum asthma_to_diag
codebook asthma_date 
keep patid asthma_date asthma_to_diag asthma


save ${covar}asthma_2yr_excl, replace

merge 1:1 patid using ${covar}asthma_any_pre

*most really have asthma, but 4,373 may be misdiagnosed.


* now we see if they had evidence of asthma in 2-5 years before their COPD diagnosis.

use ${working_data}asthma_clean_pre_diagnosis, clear

*drop crazy values (i.e. before patient is born)
* we read in the most recent value so if this is before patient is born, it means it's missing

*drop if obsdate < pneumonia_pc_date - (age*365.25)

*and also the two-five year period...

drop if obsdate > pneumonia_pc_date - (2*365.25) 
drop if obsdate < pneumonia_pc_date - (5*365.25) 


*and now we take the most recent asthma obs. 

sort patid obsdate

by patid: keep if _n == _N

rename obsdate asthma_2to5_yrs_date

*this is asthma diag any time before
rename asthma asthma_2to5_yrs
keep patid asthma_2to5_yrs_date asthma_2to5_yrs

save ${covar}asthma_2to5_yrs, replace



* we see if they are still getting asthma diagnoses after their COPD diagnosis...

use ${working_data}asthma_clean, clear

drop if obsdate <= pneumonia_pc_date

sort patid obsdate

by patid: keep if _n == 1

rename obsdate asthma_date_post
rename asthma asthma_post

gen diag_to_asthma_post = asthma_date_post - pneumonia_pc_date

keep patid asthma_date_post asthma_post diag_to_asthma_post


save ${covar}asthma_post, replace

merge 1:1 patid using ${covar}asthma_any_pre

drop _m

merge 1:1 patid using ${covar}asthma_2yr_excl
drop _m
* So, it looks like 2900 people really do have asthma still, and 1,473 do not.
tab asthma_any_pre asthma_post if asthma == ., m

codebook diag_to_asthma_post if asthma == . & asthma_any_pre != .
*hist diag_to_asthma_post if asthma == . & asthma_any_pre != .

merge 1:1 patid using ${covar}asthma_2to5_yrs
drop _m

*No clear cut-off
* might as well just use in the 3 years post-COPD diagnosis though.

*so, we create our final asthma variable


count if asthma == 1 & asthma_2to5_yrs == .
count if asthma == 1 & asthma_2to5_yrs == . & asthma_post == 1

gen asthma_definite = 1 if asthma_2to5_yrs == 1
replace asthma_definite = 1 if asthma_any_pre == 1 & asthma == . & diag_to_asthma_post < 365.25*3

gen asthma_historic = 1 if asthma_2to5_yrs == . & asthma == 1 

keep patid asthma asthma_definite asthma_historic asthma_date_post asthma_date_any_pre asthma_date asthma_2to5_yrs_date

save ${covar}asthma, replace

*********

*******************
*  atrial_fibrillation       
*******************

use ${working_data}atrial_fibrillation_clean_most_recent, clear

*drop crazy values (i.e. before patient is born)
* we read in the most recent value so if this is before patient is born, it means it's missing

*drop if atrial_fibrillation_clean_date < pneumonia_pc_date - (age*365.25)

gen atrial_fibrillation_to_diag = pneumonia_pc_date - atrial_fibrillation_clean_date
sum atrial_fibrillation_to_diag
codebook atrial_fibrillation_clean_date 
keep patid atrial_fibrillation_clean_date atrial_fibrillation_to_diag af
rename atrial_fibrillation_clean_date atrial_fibrillation_date
 
save ${covar}atrial_fibrillation, replace
*********

*******************
*  chest_xray       
*******************

use ${working_data}chest_xray_clean_most_recent, clear

*drop crazy values (i.e. before patient is born)
* we read in the most recent value so if this is before patient is born, it means it's missing

*drop if chest_xray_clean_date < pneumonia_pc_date - (age*365.25)

gen chest_xray_to_diag = pneumonia_pc_date - chest_xray_clean_date
sum chest_xray_to_diag
codebook chest_xray_clean_date 
keep patid chest_xray_clean_date chest_xray_to_diag chestxray
rename chest_xray_clean_date chest_xray_date
 
save ${covar}chest_xray, replace
*********

*******************
*  depression       
*******************

use ${working_data}depression_clean_most_recent, clear

*drop crazy values (i.e. before patient is born)
* we read in the most recent value so if this is before patient is born, it means it's missing

*drop if depression_clean_date < pneumonia_pc_date - (age*365.25)

gen depression_to_diag = pneumonia_pc_date - depression_clean_date
sum depression_to_diag
codebook depression_clean_date 
keep patid depression_clean_date depression_to_diag depression
rename depression_clean_date depression_date
 
save ${covar}depression, replace
*********

*******************
*  diabetes       
*******************

use ${working_data}diabetes_clean_most_recent, clear

*drop crazy values (i.e. before patient is born)
* we read in the most recent value so if this is before patient is born, it means it's missing

*drop if diabetes_clean_date < pneumonia_pc_date - (age*365.25)

gen diabetes_to_diag = pneumonia_pc_date - diabetes_clean_date
sum diabetes_to_diag
codebook diabetes_clean_date 
keep patid diabetes_clean_date diabetes_to_diag diabetes
rename diabetes_clean_date diabetes_date
 
save ${covar}diabetes, replace
*********

*******************
*  hf       
*******************

use ${working_data}hf_clean_most_recent, clear

*drop crazy values (i.e. before patient is born)
* we read in the most recent value so if this is before patient is born, it means it's missing

*drop if hf_clean_date < pneumonia_pc_date - (age*365.25)

gen hf_to_diag = pneumonia_pc_date - hf_clean_date
sum hf_to_diag
codebook hf_clean_date 
keep patid hf_clean_date hf_to_diag hf
rename hf_clean_date hf_date
 
save ${covar}hf, replace
*********

*******************
*  hypertension       
*******************

use ${working_data}hypertension_clean_most_recent, clear

*drop crazy values (i.e. before patient is born)
* we read in the most recent value so if this is before patient is born, it means it's missing

*drop if hypertension_clean_date < pneumonia_pc_date - (age*365.25)

gen hypertension_to_diag = pneumonia_pc_date - hypertension_clean_date
sum hypertension_to_diag
codebook hypertension_clean_date 
keep patid hypertension_clean_date hypertension_to_diag hypertension
rename hypertension_clean_date hypertension_date
 
save ${covar}hypertension, replace
*********


*******************
*  pulmonary_rehab - POST 1 YEAR       
*******************



use ${working_data}pulmonary_rehab_clean, clear

keep if obsdate >= pneumonia_pc_date
keep if obsdate < pneumonia_pc_date + 365.25

sort patid obsdate
by patid: keep if _n == 1

rename obsdate pulmonary_rehab_1yr_date
rename pulmonary_rehab pulmonary_rehab_1yr

keep patid pulmonary_rehab_1yr pulmonary_rehab_1yr_date
 
save ${covar}pulmonary_rehab, replace
*********

*******************
*  referral       
*******************

use ${working_data}referral_clean_most_recent, clear

*drop crazy values (i.e. before patient is born)
* we read in the most recent value so if this is before patient is born, it means it's missing

*drop if referral_clean_date < pneumonia_pc_date - (age*365.25)

gen referral_to_diag = pneumonia_pc_date - referral_clean_date
sum referral_to_diag
codebook referral_clean_date 
keep patid referral_clean_date referral_to_diag referral
rename referral_clean_date referral_date
 
save ${covar}referral, replace
*********

*******************
*  smoking_cessation_obs       
*******************

*use ${working_data}smoking_cessation_obs_clean_most_recent, clear
*
**drop crazy values (i.e. before patient is born)
** we read in the most recent value so if this is before patient is born, it means it's missing
*
*drop if smoking_cessation_obs_clean_date < pneumonia_pc_date - (age*365.25)
*
*gen smoking_cessation_obs_to_diag = pneumonia_pc_date - smoking_cessation_obs_clean_date
*sum smoking_cessation_obs_to_diag
*codebook smoking_cessation_obs_clean_date 
*keep patid smoking_cessation_obs_clean_date smoking_cessation_obs_to_diag smoking_cessation_obs
*rename smoking_cessation_obs_clean_date smoking_cessation_obs_date
 
use ${working_data}smoking_cessation_obs_clean, clear

keep if obsdate >= pneumonia_pc_date
keep if obsdate < pneumonia_pc_date + 365.25

sort patid obsdate
by patid: keep if _n == 1

rename obsdate smoking_cessation_obs_1yr_date
rename smoking_cessation_obs smoking_cessation_obs_1yr

keep patid smoking_cessation_obs_1yr smoking_cessation_obs_1yr_date
 
save ${covar}smoking_cessation_obs, replace
*********

*******************
*  smoking_status       
*******************
use ${working_data}smoking_status_most_recent, clear

*drop crazy values (i.e. before patient is born)
* we read in the most recent value so if this is before patient is born, it means it's missing

*drop if smoking_status_date < pneumonia_pc_date - (age*365.25)

gen smoking_status_to_diag = pneumonia_pc_date - smoking_status_date
sum smoking_status_to_diag
codebook smoking_status_date 
keep patid smoking_status_date smoking_status_to_diag smoking_status

tab smoking_status
 
save ${covar}smoking_status, replace
*********

*******************
*  stroke       
*******************

use ${working_data}stroke_clean_most_recent, clear

*drop crazy values (i.e. before patient is born)
* we read in the most recent value so if this is before patient is born, it means it's missing

*drop if stroke_clean_date < pneumonia_pc_date - (age*365.25)

gen stroke_to_diag = pneumonia_pc_date - stroke_clean_date
sum stroke_to_diag
codebook stroke_clean_date 
keep patid stroke_clean_date stroke_to_diag stroke
rename stroke_clean_date stroke_date
 
save ${covar}stroke, replace
*********

*******************
*  full_blood_count       
*******************

*********

 
 
 
*Ones to do differently:
 
* BMI 
* CCI
* spirometry 
* oxygen_clean
* COPD_meds_combined_clean 
* smoking_cessation_drugs_clean



log close


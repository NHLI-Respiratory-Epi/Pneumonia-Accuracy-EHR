clear all
set more off, perm
macro drop _all


capture log close
log using "Logs/18_add_covariates_to_cohort", replace

global extract_HES "Aurum_linked\"
global cohort "workingCohort\"
*global working_data "workingData\"
global working_data "workingData\"
global extract "extractDataMini\"
*global codelist "Code_lists\CPRD_Aurum\"

*NOTE - FOR THIS DRUG ISSUE ONE, I HAVE USED EMILY'S NEW CODELIST SAVED IN THE ORIGINAL CODELISTS FOLDER
global codelist "Code_lists\CPRD_Aurum\"

global covar "covariates\"


use ${cohort}17_add_IMD, clear


local files : dir "${covar}" files "*.dta"
foreach file in `files' {  //extract list of practice IDs
                
				display "`file'"
				merge 1:1 patid using ${covar}/`file'
				*we accidentally did too many, so drop if _m == 2
				drop if _m == 2
				*doesn't matter if they merge or not, we have to keep them.
	     		drop _m

}

*do some tidying up.

*let's just select the variables we need for the poster

*BMI blood pressure age goldstage CCI IMD gender


rename af atrial_fibrillation

*local addzero "smoking_status CCI_any_malignancy CCI_cerebrovascular CCI_CPD CCI_congestive_heart_failure CCI_dementia CCI_diabetes_uncomplicated CCI_diabetes_end_organ_damage CCI_HIV CCI_hemi_paraplegia CCI_metastatic CCI_liver_disease_mild CCI_liver_disease_mod_sev CCI_MI CCI_peptic_ulcer CCI_peripheral_vascular CCI_CKD CCI_rheumatic" 

local addzero "asthma atrial_fibrillation bmi CCI_any_malignancy CCI_cerebrovascular CCI_CPD CCI_congestive_heart_failure CCI_dementia CCI_diabetes_uncomplicated CCI_diabetes_end_organ_damage CCI_HIV CCI_hemi_paraplegia CCI_metastatic CCI_liver_disease_mild CCI_liver_disease_mod_sev CCI_MI CCI_peptic_ulcer CCI_peripheral_vascular CCI_CKD CCI_rheumatic chestxray depression diabetes hf hypertension  pulmonary_rehab_1yr referral  smoking_status stroke lama_laba_5yr ics_laba_5yr triple_5yr lama_5yr laba_5yr ics_5yr ocs_5yr saba_5yr sama_5yr " 

*removed: fbc oxygen_1yr smoking_cessation_drugs_1yr smoking_cessation_obs_1yr lama_laba_1yr ics_laba_1yr triple_1yr lama_1yr laba_1yr ics_1yr ocs_1yr saba_1yr sama_1yr arrhythmia breathless_diag_no breathless_diag_no_5yr cough_diag_no cough_diag_no_5yr chronic_cough_diag_no chronic_cough_diag_no_5yr lrti_diag_no lrti_diag_no_5yr  osteoporosis  spirometry_gold_standard sputum_diag_no sputum_diag_no_5yr wheeze_diag_no wheeze_diag_no_5yr BP_diastolic BP_systolic first_spirometry hf_referral fluvac_admin_1yr fluvac_offer_1yr echocardiogram BNP spirometry_postdiag_1yr

foreach vari in `addzero' {
	replace `vari' = 0 if `vari' == .
}

*add a new label for smoking_status


label define smoking_status 0 "Missing", add

tab smoking_status, m

codebook icd01

gen icd_pneumo_20 = .
replace icd_pneumo_20 = 0 if hosp_7days == 1

forvalues x = 1/20  {
	replace icd_pneumo_20 = 1 if substr(icd0`x',1,3) == "J12"
	replace icd_pneumo_20 = 1 if substr(icd0`x',1,3) == "J13"
	replace icd_pneumo_20 = 1 if substr(icd0`x',1,3) == "J14"
	replace icd_pneumo_20 = 1 if substr(icd0`x',1,3) == "J15"
	replace icd_pneumo_20 = 1 if substr(icd0`x',1,3) == "J16"
	replace icd_pneumo_20 = 1 if substr(icd0`x',1,3) == "J17"
	replace icd_pneumo_20 = 1 if substr(icd0`x',1,3) == "J18"
}

gen icd_pneumo_first = .
replace icd_pneumo_first = 0 if hosp_7days == 1

forvalues x = 1/1  {
	replace icd_pneumo_first = 1 if substr(icd0`x',1,3) == "J12"
	replace icd_pneumo_first = 1 if substr(icd0`x',1,3) == "J13"
	replace icd_pneumo_first = 1 if substr(icd0`x',1,3) == "J14"
	replace icd_pneumo_first = 1 if substr(icd0`x',1,3) == "J15"
	replace icd_pneumo_first = 1 if substr(icd0`x',1,3) == "J16"
	replace icd_pneumo_first = 1 if substr(icd0`x',1,3) == "J17"
	replace icd_pneumo_first = 1 if substr(icd0`x',1,3) == "J18"
}

tab icd_pneumo_20
tab icd_pneumo_first



forvalues x = 1/20  {
	gen icd0`x'_3d = substr(icd0`x',1,3)
    gen icd0`x'_1d = substr(icd0`x',1,1)
}

codebook patid


gen pneumo_term_over20_again = pneumo_term

tab pneumo_term


replace pneumo_term_over20_again = "" if hosp_7days == 0

sort pneumo_term_over20_again 

by pneumo_term_over20_again: replace pneumo_term_over20_again = "Other term" if _N < 20 & pneumo_term_over20_again != ""

tab pneumo_term_over20_again icd_pneumo_first

format admidate %td

save ${cohort}18_add_covariates, replace

log close




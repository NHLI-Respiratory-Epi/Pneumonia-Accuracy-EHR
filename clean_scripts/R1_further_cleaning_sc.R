#-------------------------------------------------------#
# Clean up the dataset     #
#-------------------------------------------------------#

library(dplyr)
library(readstata13)
library(finalfit)
library(forcats)
library(lme4)


dat <- read.dta13("workingCohort/18_add_covariates.dta", nonint.factors = TRUE)

# smoking edit

smoking <- read.dta13("workingData/smoking_full_end.dta", nonint.factors = TRUE)


smoking <- smoking %>% filter(patid %in% dat$patid)
smoking %>% select(patid) %>% unique() %>% nrow()

# smoking_save <- smoking
# smoking <- smoking_save


smoking <- smoking %>% filter(!is.na(smoking_status))
smoking <- left_join(smoking, (dat %>% select(patid, admidate)), by = "patid")

smoking <- smoking %>% filter(obsdate <= admidate)

# for those who are never-smokers, check to see if they have previous smoking codes
# if they do, they are ex-smokers
# if they don't, they are never-smokers (*bear in mind that all of these do have records of smoking history after their admission date)
# if missing, no smoking history

true_never_smokers <- smoking %>% arrange(patid, desc(obsdate)) %>% group_by(patid) %>% select(patid, smoking_status) %>% unique() %>%
  mutate(n = n()) %>% slice(1) %>% ungroup(patid) %>% filter(n == 1 & smoking_status == "Never smoker") %>% pull(patid) # 75 people are apparently never smokers


smoking <- smoking %>% arrange(patid, desc(obsdate)) %>% group_by(patid) %>% slice(1) %>% ungroup()

# remove the old one:
dat$smoking_status <- NULL

# add the new one:
dat <- left_join(dat, (smoking %>% select(patid, smoking_status)), by = "patid")

dat$smoking_status <- as.character(dat$smoking_status)

str(dat$smoking_status)
table(dat$smoking_status)

# recode it 
dat$smoking_status[is.na(dat$smoking_status)] <- "No evidence of smoking history"
dat$smoking_status[dat$smoking_status == "Never smoker" & !(dat$patid %in% true_never_smokers) ] <- "Ex-smoker" 
dat$smoking_status[dat$smoking_status == "Never smoker" & (dat$patid %in% true_never_smokers) ] <- "No evidence of smoking history" 

table(dat$smoking_status)


colnames(dat)

table(dat$pneumo_term)

table(dat$GP_hosp_code_42, useNA = "ifany")
dat %>% select(time_to_GP_hospital_code, time_to_pneumo_recording, same_day_GP_code_pneumo, GP_hosp_code_42) %>% summary()

table(dat$pneumonia, dat$pneumo_term, useNA = "ifany")
table(dat$pneumonia)

dat %>% filter(pneumo_term == "") %>% nrow()

dat %>% select(time_to_pneumo_recording) %>% summary()
dat %>% filter(!is.na(time_to_pneumo_recording)) %>% select(time_to_pneumo_recording) %>% summary()
dat %>% filter(!is.na(time_to_pneumo_recording)) %>% nrow() 
dat %>% filter(is.na(time_to_pneumo_recording)) %>% nrow() 

dat %>% select(time_to_pneumo_recording, pneumonia) %>% table(useNA = "ifany")

17990+22158

colnames(dat)

nrow(dat)

# sort out a few here:
dat <- dat %>% mutate(smoking_status = factor(smoking_status, levels = c("Current smoker","Ex-smoker", "No evidence of smoking history")))
dat$asthma_definite[is.na(dat$asthma_definite)] <- 0
dat$anxiety[is.na(dat$anxiety)] <- 0

summary(dat$asthma_definite)

summary(dat$smoking_status)
dat %>% select(starts_with("CCI")) %>% summary()
dat %>% filter(CCI_CPD == 0) %>% nrow()

table(dat$asthma_definite)
table(dat$asthma_2to5_yrs)
table(dat$asthma_any_pre)
table(dat$asthma_post)
table(dat$asthma_any_pre)

table(dat$spirometry, useNA = "ifany")

dat$pracid <- factor(dat$pracid)
dat$imd_quintile <- factor(dat$imd_quintile)

dat$imd_quintile <- fct_explicit_na(dat$imd_quintile, na_level = "Missing IMD quintile")

# create the '4 recommended actions' variable

# everyone in the dataset has CPD so change the 11 people who for some reason don't seem to have it so thye do have it.

dat$CCI_CPD[dat$CCI_CPD == 0] <- 1

# also, let's do some CCI recoding, and separate out the disease progression CCIs

dat %>% select(CCI_liver_disease_mod_sev, CCI_liver_disease_mild) %>% table()
dat %>% select(CCI_diabetes_end_organ_damage, CCI_diabetes_uncomplicated) %>% table()

dat$CCI_any_malignancy[dat$CCI_metastatic == 1] <- 0
dat$CCI_diabetes_uncomplicated[dat$CCI_diabetes_end_organ_damage == 1] <- 0
dat$CCI_liver_disease_mild[dat$CCI_liver_disease_mod_sev == 1] <- 0

dat %>% select(CCI_liver_disease_mod_sev, CCI_liver_disease_mild) %>% table()
dat %>% select(CCI_diabetes_end_organ_damage, CCI_diabetes_uncomplicated) %>% table()
dat %>% select(CCI_metastatic, CCI_any_malignancy) %>% table()


colnames(dat)

# and let's calculate the CCI index

dat$CI

summary(dat$CCI_any_malignancy)

# dat$CCI_count <-

dat$CCI_count <- dat %>% select(starts_with("CCI")) %>% rowSums()
table(dat$CCI_count)

CCI_calculate <- function(x) {
  x <- x %>% select(starts_with("CCI_")) 
    x$CCI_any_malignancy <- x$CCI_any_malignancy*2 # (mutually exclusive with metastatic)
    x$CCI_cerebrovascular <- x$CCI_cerebrovascular*0
    x$CCI_CPD <- x$CCI_CPD*1
    x$CCI_congestive_heart_failure <- x$CCI_congestive_heart_failure*2
    x$CCI_dementia <- x$CCI_dementia*2
    x$CCI_diabetes_uncomplicated <- x$CCI_diabetes_uncomplicated*0 
    x$CCI_diabetes_end_organ_damage <- x$CCI_diabetes_end_organ_damage*1 # (mutually exclusive with uncomplicated)
    x$CCI_HIV <- x$CCI_HIV*4
    x$CCI_hemi_paraplegia <- x$CCI_hemi_paraplegia*2
    x$CCI_metastatic <- x$CCI_metastatic*6
    x$CCI_liver_disease_mild <- x$CCI_liver_disease_mild*2
    x$CCI_liver_disease_mod_sev <- x$CCI_liver_disease_mod_sev*4 # (mutually exclusive with mild)
    x$CCI_MI <- x$CCI_MI*0
    x$CCI_peptic_ulcer <- x$CCI_peptic_ulcer*0
    x$CCI_peripheral_vascular <- x$CCI_peripheral_vascular*0
    x$CCI_CKD <- x$CCI_CKD*1
    x$CCI_rheumatic <- x$CCI_rheumatic*1

    x$CCI_score <- x %>% select(CCI_any_malignancy, CCI_cerebrovascular, CCI_CPD, CCI_congestive_heart_failure, CCI_dementia,
                                CCI_diabetes_uncomplicated, CCI_diabetes_end_organ_damage, CCI_HIV, CCI_hemi_paraplegia,
                                CCI_metastatic, CCI_liver_disease_mild, CCI_liver_disease_mod_sev, CCI_MI, CCI_peptic_ulcer,
                                CCI_peripheral_vascular, CCI_CKD, CCI_rheumatic) %>% rowSums()
    
    return(x$CCI_score)
}


dat$CCI_score <- CCI_calculate(dat)

table(dat$CCI_score, dat$CCI_count)

dat$CCI_any_malignancy

# these are:

# chest x-ray, full blood count, spirometry, bmi.
# This should be the most recent before diagnosis

# All variables added from codelists are in general the most recent occurrence before diagnosis.
# For some variables, such as the symptoms variables, we need their earliest occurrence before diagnosis.

# This has been done. Still have to wait for the referrals codelist before I do more though. 

# Earliest variables: symptoms
# referral ?
# spirometry ?

# GOLD status is just in most recent year before study start.



# other:
# spirometry - +-6 months around diagnosis?

# For one year following diagnosis:

# Oxygen therapy
# Smoking cessation (prescriptions and GP advice etc)
# COPD review
# PR referral


# OPTIONS

# time from first symptom to first investigation.
# time from first symptom, not including cough, to first investigation.
# time from first symptom to first investigation (restricting to 5yrs).
# time from first symptom, not including cough, to first investigation (restricting to 5yrs).



# in the abstract interested in 1 year since the onset of symptoms.
# in reality, interested in one year before diagnosis.
# we create another variable for 1 year before.

# and make them like 

# create the GOLD levels
dat$gold <- "Missing FEV1 %-pred measurement"
dat$gold[dat$fev1_perc_pred_combo < 30] <- "Gold stage 4: <30%"
dat$gold[dat$fev1_perc_pred_combo >= 30 & dat$fev1_perc_pred_combo < 50 ] <- "Gold stage 3: 30-49%"
dat$gold[dat$fev1_perc_pred_combo >= 50 & dat$fev1_perc_pred_combo < 80 ] <- "Gold stage 2: 50-79%"
dat$gold[dat$fev1_perc_pred_combo >= 80 ] <- "Gold stage 1: >=80%"

dat$gold <- factor(dat$gold)

table(dat$gold, dat$hosp_7days, useNA = "ifany")

dat$gender <- as.character(dat$gender)
dat$gender[dat$gender == "[1] Male"] <- "Male"
dat$gender[dat$gender == "[2] Female"] <- "Female"
dat$gender <- factor(dat$gender, levels = c("Male", "Female"))

dat$bmi_group <- cut(dat$bmi_value, breaks = c(-1, 18.5, 25, 30, Inf), labels = c("Underweight", "Normal", "Overweight", "Obese"))
dat$bmi_group <- fct_explicit_na(dat$bmi_group, "Missing")

table(dat$bmi_group, useNA = "ifany")


# rename spirometry

dat <- dat %>% rename(spirometry_date = any_spirometry_date)

# make all the non-hospitalisations missing

colnames(dat)


# create the groups for the table

dat$primary42 <- "Pneumonia not recorded in primary care within 42 days"
dat$primary42[!is.na(dat$time_to_pneumo_recording)] <- "Pneumonia recorded in primary care within 42 days"


dat$primary42 <- factor(dat$primary42, levels = c("Pneumonia not recorded in primary care within 42 days",
                                                          "Pneumonia recorded in primary care within 42 days"))

dat_analysis <- dat

saveRDS(dat_analysis, "cleanCohort/1_further_cleaning_cohort_for_analysis_sc.RDS")

# doing this seems to interfere with ff_label if done the other way around (i.e. if done after using ff_label).

factorthis <- dat %>%  summarise(across(where(is.numeric), max)) %>% select_if(~(. == 1)) %>% colnames()
# factorthis <- c(factorthis, "smoking_cessation_drugs_1yr", "smoking_cessation_obs_1yr", 
#                 "smoking_cessation_evidence_1yr", "first_aecopd_event", "first_aecopd_event_equiv", "first_aecopd_event_max")
factorthis <- factorthis[c(-2, -3)]

dat <- dat %>% mutate_at(vars(all_of(factorthis)), ~factor(., levels = c("1", "0")))
dat <- dat %>% mutate_at(vars(all_of(factorthis)), ~fct_recode(., Yes = "1", No = "0"))

table(dat$smoking_cessation_drugs_1yr)

colnames(dat)

# For asthma:
# 0-2 years previous is misclassification of COPD. 3-5 years is proper COPD

# summary_factorlist(dat, "hosp_7days", "age")




table(dat$breathless)

summary(dat)

dat <- dat %>% mutate(
  patid = ff_label(patid,"Patient ID"),
 #  hosp_7days = ff_label(hosp_7days,"Hospitalised within 7 days of GP-diagnosed pneumonia"),
 primary42 = ff_label(primary42, "Pneumonia recorded in primary care within 42 days of hospitalised pneumonia"),
 age = ff_label(age,"Age (years)"),
  imd_quintile = ff_label(imd_quintile,"IMD quintile"),
  pracid = ff_label(pracid,"Practice ID"),
  gender = ff_label(gender,"Gender"),
#   died = ff_label(died,"Died"),
  lama_laba_5yr = ff_label(lama_laba_5yr,"LAMA-LABA dual therapy prescribed in the 5 years preceding pneumonia diagnosis"),
  ics_laba_5yr = ff_label(ics_laba_5yr,"ICS-LABA dual therapy prescribed in the 5 years preceding pneumonia diagnosis"),
  triple_5yr = ff_label(triple_5yr,"LAMA-LABA-ICS triple therapy prescribed in the 5 years preceding pneumonia diagnosis"),
#  lama_laba_5yr_date = ff_label(lama_laba_5yr_date,""),
#  ics_laba_5yr_date = ff_label(ics_laba_5yr_date,""),
#  triple_5yr_date = ff_label(triple_5yr_date,""),
  lama_5yr = ff_label(lama_5yr,"LAMA therapy prescribed in the 5 years preceding pneumonia diagnosis"),
  laba_5yr = ff_label(laba_5yr,"LABA therapy prescribed in the 5 years preceding pneumonia diagnosis"),
  ics_5yr = ff_label(ics_5yr,"ICS therapy prescribed in the 5 years preceding pneumonia diagnosis"),
#  lama_5yr_date = ff_label(lama_5yr_date,""),
#  laba_5yr_date = ff_label(laba_5yr_date,""),
#  ics_5yr_date = ff_label(ics_5yr_date,""),
#  anaemia_date = ff_label(anaemia_date,""),
  anaemia = ff_label(anaemia,"Anaemia"),
#  anaemia_to_diag = ff_label(anaemia_to_diag,"Anaemia to COPD diagnosis (days)"),
  # COPD_review_1yr_date = ff_label(COPD_review_1yr_date,""),
#  COPD_review_1yr = ff_label(COPD_review_1yr,"COPD review within 1 year of diagnosis"),
#  annual_review_to_diag = ff_label(annual_review_to_diag,"Annual review to COPD diagnosis (days)"),
#  anxiety_date = ff_label(anxiety_date,""),
  anxiety = ff_label(anxiety,"Anxiety"),
#  anxiety_to_diag = ff_label(anxiety_to_diag,"Anxiety to COPD diagnosis (days)"),
#  spirometry_MR_date = ff_label(spirometry_MR_date,""),
  spirometry = ff_label(spirometry, "Record of spirometry any time before pneumonia diagnosis"),
#  spirometry_MR = ff_label(spirometry_MR,"Spirometry (pre-diagnosis)"),
#  arrhythmia_date = ff_label(arrhythmia_date,""),
# arrhythmia = ff_label(arrhythmia,"Arrhythmia"),
#  asthma_date_post = ff_label(asthma_date_post,""),
#  asthma_date_any_pre = ff_label(asthma_date_any_pre,""),
#  asthma_date = ff_label(asthma_date,""),
  asthma = ff_label(asthma,"Asthma (ignores diagnoses 0-2 years before start date as potential for misclassification)"),
  asthma_2to5_yrs_date = ff_label(asthma_2to5_yrs_date,""),
  asthma_definite = ff_label(asthma_definite,"Asthma diagnosis"), # 2-5 years before start date, or asthma diagnosis 0-2 years before start date with asthma diagnosis after start date too"),
  asthma_historic = ff_label(asthma_historic,"Historic asthma (most recent diagnosis >5 years before start date)"),
  asthma_2to5_yrs = ff_label(asthma_2to5_yrs,"Asthma (evidence of asthma 2-5 years before start date)"),
#  asthma_to_diag = ff_label(asthma_to_diag,""),
  asthma_any_pre = ff_label(asthma_any_pre,"Asthma (any diagnosis before start date)"),
#  asthma_to_diag_any = ff_label(asthma_to_diag_any,""),
  asthma_post = ff_label(asthma_post,"Asthma (any diagnosis after COPD diagnosis"),
#  diag_to_asthma_post = ff_label(diag_to_asthma_post,""),
#  atrial_fibrillation_date = ff_label(atrial_fibrillation_date,""),
  atrial_fibrillation = ff_label(atrial_fibrillation,"Atrial fibrillation"),
#  atrial_fibrillation_to_diag = ff_label(atrial_fibrillation_to_diag,""),
#  bmi_date = ff_label(bmi_date,""),
  bmi_value = ff_label(bmi_value,"BMI value"),
  bmi = ff_label(bmi,"BMI"),
#  bmi_to_diag = ff_label(bmi_to_diag, "BMI measurement to COPD diagnosis (days)"),
#  BP_diastolic_date = ff_label(BP_diastolic_date,""),
  BP_diastolic_value = ff_label(BP_diastolic_value,"Diastolic blood pressure (mmHg)"),
  BP_diastolic = ff_label(BP_diastolic,"Diastolic blood pressure taken"),
#  BP_systolic_date = ff_label(BP_systolic_date,""),
  BP_systolic_value = ff_label(BP_systolic_value,"Systolic blood pressure (mmHg)"),
  BP_systolic = ff_label(BP_systolic,"Systolic blood pressure taken"),
 # breathless_date = ff_label(breathless_date,""),
 # breathless_diag_no = ff_label(breathless_diag_no,"No. breathlessness diagnoses preceding COPD diagnosis"),
#  breathless_date_5yr = ff_label(breathless_date_5yr,""),
#  breathless_diag_no_5yr = ff_label(breathless_diag_no_5yr,"No. breathlessness diagnoses within 5 years preceding COPD diagnosis"),
  CCI_any_malignancy = ff_label(CCI_any_malignancy,"Any malignancy, including leukemia and lymphoma (CCI)"),
  CCI_cerebrovascular = ff_label(CCI_cerebrovascular,"Cerebrovascular disease (CCI)"),
  CCI_CPD = ff_label(CCI_CPD,"Chronic pulmonary disease (CCI)"),
  CCI_congestive_heart_failure = ff_label(CCI_congestive_heart_failure,"Congestive heart failure (CCI)"),
  CCI_dementia = ff_label(CCI_dementia,"Dementia (CCI)"),
  CCI_diabetes_uncomplicated = ff_label(CCI_diabetes_uncomplicated,"Diabetes without chronic complications (CCI)"),
  CCI_diabetes_end_organ_damage = ff_label(CCI_diabetes_end_organ_damage,"Diabetes with chronic complications (CCI)"),
  CCI_HIV = ff_label(CCI_HIV,"AIDS/HIV (CCI)"),
  CCI_hemi_paraplegia = ff_label(CCI_hemi_paraplegia,"Hemiplegia or paraplegia (CCI)"),
  CCI_metastatic = ff_label(CCI_metastatic,"Metastatic solid tumor (CCI)"),
  CCI_liver_disease_mild = ff_label(CCI_liver_disease_mild,"Mild liver disease (CCI)"),
  CCI_liver_disease_mod_sev = ff_label(CCI_liver_disease_mod_sev,"Moderate or severe liver disease (CCI)"),
  CCI_MI = ff_label(CCI_MI,"Myocardial infarction (CCI)"),
  CCI_peptic_ulcer = ff_label(CCI_peptic_ulcer,"Peptic ulcer disease (CCI)"),
  CCI_peripheral_vascular = ff_label(CCI_peripheral_vascular,"Peripheral vascular disease (CCI)"),
  CCI_CKD = ff_label(CCI_CKD,"Renal disease (CCI)"),
  CCI_rheumatic = ff_label(CCI_rheumatic,"Rheumatologic disease (CCI)"),
 # chest_xray_date = ff_label(chest_xray_date,""),
 # chestxray = ff_label(chestxray,"Chest X-ray"),
#  chest_xray_to_diag = ff_label(chest_xray_to_diag,"Time from chest X-ray to COPD diagnosis (days)"),
#  cough_date = ff_label(cough_date,""),
 # cough_diag_no = ff_label(cough_diag_no,"No. cough diagnoses preceding COPD diagnosis"),
#  cough_date_5yr = ff_label(cough_date_5yr,""),
#  cough_diag_no_5yr = ff_label(cough_diag_no_5yr,"No. cough diagnoses within 5 years preceding COPD diagnosis"),
#  depression_date = ff_label(depression_date,""),
  depression = ff_label(depression,"Depression"),
#  depression_to_diag = ff_label(depression_to_diag,""),
#  diabetes_date = ff_label(diabetes_date,""),
  diabetes = ff_label(diabetes,"Diabetes"),
#  diabetes_to_diag = ff_label(diabetes_to_diag,""),
#  fev1_date = ff_label(fev1_date,""),
  fev1 = ff_label(fev1,"FEV1"),
#  fev1_percent_pred_GP_date = ff_label(fev1_percent_pred_GP_date,""),
#  fev1_percent_pred_GP = ff_label(fev1_percent_pred_GP,""),
#  fev1_perc_pred_calc2 = ff_label(fev1_perc_pred_calc2,""),
#  fev1_perc_pred_calc1 = ff_label(fev1_perc_pred_calc1,""),
#  fev1_perc_pred_type = ff_label(fev1_perc_pred_type,""),
  fev1_perc_pred_combo = ff_label(fev1_perc_pred_combo,"FEV1 % predicted"),
#  fev1_perc_pred_combo_date = ff_label(fev1_perc_pred_combo_date,""),
#  fev1_pred_calc_date = ff_label(fev1_pred_calc_date,""),
#  fev1_pred_calc = ff_label(fev1_pred_calc,""),
#  fev1_pred_GP_date = ff_label(fev1_pred_GP_date,""),
#  fev1_pred_GP = ff_label(fev1_pred_GP,""),
#  full_blood_count_date = ff_label(full_blood_count_date,""),
#  fbc = ff_label(fbc,"Full blood count"),
#  full_blood_count_to_diag = ff_label(full_blood_count_to_diag,"Time from FBC to COPD diagnosis (days)"),
#  height_date = ff_label(height_date,""),
  height = ff_label(height,"Height"),
#  hf_date = ff_label(hf_date,""),
  hf = ff_label(hf,"Heart failure"),
#  hf_to_diag = ff_label(hf_to_diag,""),
#  hypertension_date = ff_label(hypertension_date,""),
  hypertension = ff_label(hypertension,"Hypertension"),
#  hypertension_to_diag = ff_label(hypertension_to_diag,""),
#  lrti_date = ff_label(lrti_date,""),
#  lrti_diag_no = ff_label(lrti_diag_no,"No. LRTI diagnoses preceding COPD diagnosis"),
#  lrti_date_5yr = ff_label(lrti_date_5yr,""),
 # lrti_diag_no_5yr = ff_label(lrti_diag_no_5yr,"No. LRTI diagnoses in 5 years preceding COPD diagnosis"),
#  ocs_1yr = ff_label(ocs_1yr,"Oral corticosteroids prescribed in the year after COPD diagnosis"),
#  ocs_1yr_date = ff_label(ocs_1yr_date,""),
  ocs_5yr = ff_label(ocs_5yr,"Oral corticosteroids prescribed in the 5 years preceding pneumonia diagnosis"),
#  ocs_5yr_date = ff_label(ocs_5yr_date,""),
#  osteoporosis_date = ff_label(osteoporosis_date,""),
 # osteoporosis = ff_label(osteoporosis,"Osteoporosis"),
#  oxygen_1yr_date = ff_label(oxygen_1yr_date,""),
#  oxygen_1yr = ff_label(oxygen_1yr,"Oxygen prescription within 1 year of COPD diagnosis"),
#  pulmonary_rehab_date = ff_label(pulmonary_rehab_date,""),
 # pulmonary_rehab_1yr = ff_label(pulmonary_rehab_1yr, "Pulmonary rehabilitation within 1 year of COPD diagnosis"),
#  pulmonary_rehab_to_diag = ff_label(pulmonary_rehab_to_diag,""),
#  referral_date = ff_label(referral_date,""),
#  referral = ff_label(referral,"Respiratory referral before COPD diagnosis"),
#  referral_to_diag = ff_label(referral_to_diag,""),
 # saba_1yr = ff_label(saba_1yr,"SABA prescribed in the year after COPD diagnosis"),
 # saba_1yr_date = ff_label(saba_1yr_date,""),
  saba_5yr = ff_label(saba_5yr,"SABA prescribed in the 5 years preceding pneumonia diagnosis"),
#  saba_5yr_date = ff_label(saba_5yr_date,""),
#  sama_1yr = ff_label(sama_1yr,"SAMA prescribed in the year after COPD diagnosis"),
#  sama_1yr_date = ff_label(sama_1yr_date,""),
  sama_5yr = ff_label(sama_5yr,"SAMA prescribed in the 5 years preceding pneumonia diagnosis"),
#  sama_5yr_date = ff_label(sama_5yr_date,""),
#  smoking_cessation_drugs_1yr_date = ff_label(smoking_cessation_drugs_1yr_date,""),
 # smoking_cessation_drugs_1yr = ff_label(smoking_cessation_drugs_1yr,"Smoking cessation drugs prescribed within 1 year of COPD diagnosis"),
#  smoking_cessation_obs_1yr_date = ff_label(smoking_cessation_obs_date,""),
#  smoking_cessation_obs_1yr = ff_label(smoking_cessation_obs_1yr,"Smoking cessation advice within 1 year of COPD diagnosis"),
#  smoking_cessation_obs_to_diag = ff_label(smoking_cessation_obs_to_diag,""),
#  smoking_status_date = ff_label(smoking_status_date,""),
  smoking_status = ff_label(smoking_status,"Smoking status"),
#  smoking_status_to_diag = ff_label(smoking_status_to_diag,""),
#  spirometry_gold_standard_date = ff_label(spirometry_gold_standard_date,""),
 # spirometry_gold_standard = ff_label(spirometry_gold_standard,"Spirometry +-6 months of COPD diagnosis"),
#  sputum_date = ff_label(sputum_date,""),
#  sputum_diag_no = ff_label(sputum_diag_no,"No. sputum diagnoses preceding COPD diagnosis"),
#  sputum_date_5yr = ff_label(sputum_date_5yr,""),
#  sputum_diag_no_5yr = ff_label(sputum_diag_no_5yr, "No. sputum diagnoses in 5 years preceding COPD diagnosis"),
#  stroke_date = ff_label(stroke_date,""),
  stroke = ff_label(stroke,"Stroke"),
#  stroke_to_diag = ff_label(stroke_to_diag,""),
#  wheeze_date = ff_label(wheeze_date,""),
#  wheeze_diag_no = ff_label(wheeze_diag_no,"No. wheeze diagnoses preceding COPD diagnosis"),
#  wheeze_date_5yr = ff_label(wheeze_date_5yr,""),
#   wheeze_diag_no_5yr = ff_label(wheeze_diag_no_5yr,"No. wheeze diagnoses in 5 years preceding COPD diagnosis"),
#   wheeze_diag_bin = ff_label(wheeze_diag_bin,"Any wheeze diagnosis preceding COPD diagnosis"),
#   wheeze_diag_bin_5yr = ff_label(wheeze_diag_bin_5yr,"Any wheeze diagnosis in 5 years preceding COPD diagnosis"),
#   breathless_diag_bin = ff_label(breathless_diag_bin,"Any breathlessness diagnosis preceding COPD diagnosis"),
#   breathless_diag_bin_5yr = ff_label(breathless_diag_bin_5yr,"Any breathlessness diagnosis in 5 years preceding COPD diagnosis"),
#   cough_diag_bin = ff_label(cough_diag_bin,"Any cough diagnosis preceding COPD diagnosis"),
#   cough_diag_bin_5yr = ff_label(cough_diag_bin_5yr,"Any cough diagnosis in 5 years preceding COPD diagnosis"),
#   sputum_diag_bin = ff_label(sputum_diag_bin,"Any sputum diagnosis preceding COPD diagnosis"),
#   sputum_diag_bin_5yr = ff_label(sputum_diag_bin_5yr,"Any sputum diagnosis in 5 years preceding COPD diagnosis"),
#   lrti_diag_bin = ff_label(lrti_diag_bin,"Any LRTI diagnosis preceding COPD diagnosis"),
#   lrti_diag_bin_5yr = ff_label(lrti_diag_bin_5yr,"Any LRTI diagnosis in 5 years preceding COPD diagnosis"),
#   symptom_no = ff_label(symptom_no,"Any COPD symptoms preceding COPD diagnosis"),
#   symptom_no_5yr = ff_label(symptom_no_5yr,"Any COPD symptoms in 5 years preceding COPD diagnosis"),
# #  first_symptom_date = ff_label(first_symptom_date,""),
# #  first_symptom_date_5yr = ff_label(first_symptom_date_5yr,""),
#   breathless_to_diag = ff_label(breathless_to_diag,"Time from earliest breathlessness diagnosis to COPD diagnosis (days)"),
#   wheeze_to_diag = ff_label(wheeze_to_diag,"Time from earliest wheeze diagnosis to COPD diagnosis (days)"),
#   cough_to_diag = ff_label(cough_to_diag,"Time from earliest cough diagnosis to COPD diagnosis (days)"),
#   sputum_to_diag = ff_label(sputum_to_diag,"Time from earliest sputum diagnosis to COPD diagnosis (days)"),
#   lrti_to_diag = ff_label(lrti_to_diag,"Time from earliest LRTI diagnosis to COPD diagnosis (days)"),
#   first_symptom_to_diag = ff_label(first_symptom_to_diag,"Time from earliest COPD symptom to COPD diagnosis (days)"),
#   breathless_to_diag_5yr = ff_label(breathless_to_diag_5yr,"Time from earliest breathlessness diagnosis to COPD diagnosis, restricted to 5 years (days)"),
#   wheeze_to_diag_5yr = ff_label(wheeze_to_diag_5yr,"Time from earliest wheeze diagnosis to COPD diagnosis, restricted to 5 years (days)"),
#   cough_to_diag_5yr = ff_label(cough_to_diag_5yr,"Time from earliest cough diagnosis to COPD diagnosis, restricted to 5 years (days)"),
#   sputum_to_diag_5yr = ff_label(sputum_to_diag_5yr,"Time from earliest sputum diagnosis to COPD diagnosis, restricted to 5 years (days)"),
#   lrti_to_diag_5yr = ff_label(lrti_to_diag_5yr,"Time from earliest LRTI diagnosis to COPD diagnosis, restricted to 5 years (days)"),
#   first_symptom_to_diag_5yr = ff_label(first_symptom_to_diag_5yr,"Time from earliest COPD symptom to COPD diagnosis, restricted to 5 years (days)"),
  gold = ff_label(gold,"GOLD status"),
  bmi_group = ff_label(bmi_group,"BMI category"),
#   diagnosis_situation_bin = ff_label(diagnosis_situation_bin,"Diagnosis location"),
#   cohort_and_diagnosis = ff_label(cohort_and_diagnosis,"Diagnosis location and cohort"),
#   patient_disease_type = ff_label(patient_disease_type,"Patient disease type"),
#   cohort_and_disease_type = ff_label(cohort_and_disease_type,"Patient disease type and cohort"),
#   spiro_and_3tests_cat = ff_label(spiro_and_3tests_cat, "Spirometry, CXR, BMI, FBC"),
#   spiro_and_3tests_cat_1yr = ff_label(spiro_and_3tests_cat_1yr, "Spirometry, CXR, BMI, FBC"),
#   first_symptom_to_chest_xray = ff_label(first_symptom_to_chest_xray, "Time from first symptom to chest X-ray (days)"),
#   first_symptom_to_chest_xray_5yr = ff_label(first_symptom_to_chest_xray_5yr, "Time from first symptom (restricted to 5 years) to chest X-ray (days)"), 
#   first_symptom_to_fbc = ff_label(first_symptom_to_fbc, "Time from first symptom to FBC (days)"),
#   first_symptom_to_fbc_5yr = ff_label(first_symptom_to_fbc_5yr, "Time from first symptom (restricted to 5 years) to FBC (days)"),
#   first_symptom_to_first_spirometry = ff_label(first_symptom_to_first_spirometry, "Time from first symptom to first recorded spirometry (days)"),
#   first_symptom_to_first_spirometry_5yr = ff_label(first_symptom_to_first_spirometry_5yr, "Time from first symptom (restricted to 5 years) to first recorded spirometry (days)"),
# spirometry_1yr = ff_label(spirometry_1yr, "Spirometry in the year before COPD diagnosis"),
# fbc_1yr = ff_label(fbc_1yr, "Full blood count in the year before COPD diagnosis"),
# chestxray_1yr = ff_label(chestxray_1yr, "Chest X-ray in the year before COPD diagnosis"),
# bmi_1yr = ff_label(bmi_1yr, "BMI measurement in the year before COPD diagnosis"),
# all_4_tests = ff_label(all_4_tests, "All of spirometry, FBC, CXR, and BMI measurement before COPD diagnosis"),
# all_4_tests_1yr = ff_label(all_4_tests_1yr, "All of spirometry, FBC, CXR, and BMI measurement in the year before COPD diagnosis"),
# at_least_1_of_3_tests = ff_label(at_least_1_of_3_tests, "At least one of FBC, CXR, and BMI measurement before COPD diagnosis"),
# at_least_1_of_3_tests_1yr = ff_label(at_least_1_of_3_tests_1yr, "At least one of FBC, CXR, and BMI measurement in the year before COPD diagnosis"),
# smoking_cessation_evidence_1yr = ff_label(smoking_cessation_evidence_1yr, "Evidence of discussion of smoking cessation within 1 year of COPD diagnosis"),
# diag_to_aecopd = ff_label(diag_to_aecopd, "Time between first diagnosis of COPD and first AECOPD (years), in those diagnosed in primary care"),
# diag_to_aecopd_equiv = ff_label(diag_to_aecopd_equiv, "Time between first diagnosis of COPD and first AECOPD (years), in those diagnosed in primary care"),
# diag_to_aecopd_max = ff_label(diag_to_aecopd_max, "Time between first diagnosis of COPD and first AECOPD (years), in those diagnosed in primary care"),
CCI_count = ff_label(CCI_count, "Total number of comorbidities"),
# hf_referral = ff_label(hf_referral, "Cardiology referral before COPD diagnosis"), 
# BNP = ff_label(BNP, "Natriuretic peptide test (BNP, NT-proBNP) before COPD diagnosis"), 
# echocardiogram = ff_label(echocardiogram, "Echocardiogram before COPD diagnosis"), 
# fluvac_offer_1yr = ff_label(fluvac_offer_1yr, "Influenza vaccine offered within 1 year of COPD diagnosis"), 
# fluvac_admin_1yr = ff_label(fluvac_admin_1yr, "Influenza vaccine administered within 1 year of COPD diagnosis"),
CCI_score = ff_label(CCI_score, "CCI score"),
pneumo_term = ff_label(pneumo_term, "Pneumonia term used in primary care"),
pneumo_term_over20_again = ff_label(pneumo_term_over20_again, "Pneumonia term used in primary care"),
breathless = ff_label(breathless, "Recording of breathlessness before penumonia diagnosis"),
cough = ff_label(cough, "Recording of cough before penumonia diagnosis"),
fever = ff_label(fever, "Recording of fever before penumonia diagnosis"),
lethargy = ff_label(lethargy, "Recording of lethargy before penumonia diagnosis"),
tachycardia = ff_label(tachycardia, "Recording of tachycardia before penumonia diagnosis"))
# icd_pneumo_first = ff_label(icd_pneumo_first, "Pneumonia code in first position"),
# icd_pneumo_20 = ff_label(icd_pneumo_20, "Pneumonia code in any position"),
# hosp_pneumo_combo = ff_label(hosp_pneumo_combo, "Hospitalisation within 7 days and diagnosis in hospital"))



colnames(dat)


saveRDS(dat, "cleanCohort/1_further_cleaning_cohort_sc.RDS")
summary(dat$primary42)
summary(dat$time_to_pneumo_recording)


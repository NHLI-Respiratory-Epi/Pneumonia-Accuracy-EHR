
# Load necessary libraries
library(dplyr)
library(tidyr)
library(binom)

dat <- readRDS("cleanCohort/1_further_cleaning_cohort_for_analysis_sc.RDS")

colnames(dat)

summary(dat$primary42)

dat$primary42_bin <- 0
dat$primary42_bin[dat$primary42 == "Pneumonia recorded in primary care within 42 days"] <- 1

# Define a function to calculate PPV and CI
ppv_ci <- function(x, y) {
  x <- x[!is.na(x) & !is.na(y)]
  y <- y[!is.na(x) & !is.na(y)]
  
  tp <- sum(x & y, na.rm = TRUE)    # True Positives
  fp <- sum(!x & y, na.rm = TRUE)   # False Positives
  ppv <- tp / (tp + fp)
  ci <- binom.confint(tp, (tp + fp), methods = "wilson")
  return(list(ppv = ppv, ci_lower = ci$lower, ci_upper = ci$upper))
}

sensitivity_ci <- function(x, y) {
  x <- x[!is.na(x) & !is.na(y)]
  y <- y[!is.na(x) & !is.na(y)]
  
  tp <- sum(x & y, na.rm = TRUE)    # True Positives
  fn <- sum(x & !y, na.rm = TRUE)   # False Negatives
  sensitivity <- tp / (tp + fn)
  ci <- binom.confint(tp, (tp + fn), methods = "wilson")
  return(list(sensitivity = sensitivity, ci_lower = ci$lower, ci_upper = ci$upper))
}


# based on 'primary42' table

summary(dat$primary42)

  tp <- 11445    # True Positives
  fn <- 22158   # False Positives
  sensitivity <- tp / (tp + fn)
  ci <- binom.confint(tp, (tp + fn), methods = "wilson")


  
  colnames(dat)
  
dat %>% select(same_day_GP_code_pneumo, primary42_bin) %>% table()  

# then, restrict to those with a pneumonia code within 42 days who had a hospitalisation code on the same day

table(dat$same_day_GP_code_pneumo)

tp <- 6805    # True Positives
fn <- 26798   # False Positives
sensitivity <- tp / (tp + fn)
ci <- binom.confint(tp, (tp + fn), methods = "wilson")

sensitivity
ci

# Create an empty data frame for the results
diagnostic_table <- data.frame()

# List of diagnostic criteria
diagnostic_criteria <- c("pneumonia_primary", "pneumo_symp2", "chest_xray", "bc_sp_sent2", 
                         "sputum_positive", "symp_cxray2", "abx", "abx_all_dur",
                         "symp_abx2", "cxray_abx2", "abx_bc_sp_sent2",
                         "abx_sputum_positive2", "cxray_bc_sp_sent2", 
                         "cxray_sputum_positive2", "symp_bc_sp_sent2", 
                         "symp_sputum_positive2", "cxray_symp_abx2", 
                         "cxray_symp_abx_bc_sp_sent2", "cxray_symp_abx_blood_sputum_pos2")

# Loop through the diagnostic criteria
for (criteria in diagnostic_criteria) {
  # Exclude rows with missing data for current criteria
  dat_sub <- dat[!is.na(dat$icd_pneumo_first) & !is.na(dat[[criteria]]), ]
#  dat_sub <- dat[!is.na(dat$icd_pneumo_first) & dat[[criteria]] == 1, ]
  
  # Perform Chi-square test
  chisq_test <- chisq.test(table(dat_sub$icd_pneumo_first, dat_sub[[criteria]]))
  # n_eligible <- sum(dat_sub[[criteria]], na.rm = TRUE)
  n_eligible <- sum(dat[[criteria]], na.rm = TRUE)
  
  # Calculate the number and percentage of those admitted within 7 days
  n_admitted_7_days <- sum(dat_sub[[criteria]] & dat_sub$hosp_7days, na.rm = TRUE)
  perc_admitted_7_days <- n_admitted_7_days / n_eligible * 100
  
  # Calculate the number and percentage of those with a primary diagnosis of pneumonia
  n_primary_diagnosis <- sum(dat_sub[[criteria]] & dat_sub$icd_pneumo_first, na.rm = TRUE)
  perc_primary_diagnosis <- n_primary_diagnosis / n_eligible * 100
  
  # Calculate PPV and 95% CI
  ppv_result <- ppv_ci(dat_sub$icd_pneumo_first, dat_sub[[criteria]])
  
  # Add results to the data frame
  diagnostic_table <- rbind(diagnostic_table, data.frame(
    Criteria = criteria,
    Eligible_N = n_eligible,
    Admitted_7_days_N = n_admitted_7_days,
    Admitted_7_days_Perc = perc_admitted_7_days,
    Primary_Diagnosis_N = n_primary_diagnosis,
    Primary_Diagnosis_Perc = ppv_result$ppv,
#    Primary_Diagnosis_Perc = perc_primary_diagnosis,
    PPV = ppv_result$ppv,
    CI_lower = ppv_result$ci_lower,
    CI_upper = ppv_result$ci_upper
  ))
}

diagnostic_table <- diagnostic_table %>% mutate(Admitted_7_days_Perc = sprintf("%.1f", round(Admitted_7_days_Perc, 1)),
                            Primary_Diagnosis_Perc = sprintf("%.1f", round(Primary_Diagnosis_Perc*100, 1)),
                            PPV = sprintf("%.1f", round(PPV*100, 1)),
                            CI_lower = sprintf("%.1f", round(CI_lower*100, 1)),
                            CI_upper = sprintf("%.1f", round(CI_upper*100, 1))) %>%
  mutate_all(as.character)


diagnostic_table <- diagnostic_table %>% mutate(across(c(Eligible_N, Admitted_7_days_N, Primary_Diagnosis_N),
                                                       ~ ifelse(.x %in% c("1", "2", "3", "4"), "<5", .x)))


diagnostic_table$Admitted_7_days_N <- paste0(diagnostic_table$Admitted_7_days_N, " (", diagnostic_table$Admitted_7_days_Perc, "%)")
diagnostic_table$Primary_Diagnosis_N <- paste0(diagnostic_table$Primary_Diagnosis_N, " (", diagnostic_table$Primary_Diagnosis_Perc, "%)")
diagnostic_table$PPV <- paste0(diagnostic_table$PPV, " (", diagnostic_table$CI_lower, " - ", diagnostic_table$CI_upper, ")")

diagnostic_table$Admitted_7_days_N[diagnostic_table$Admitted_7_days_N == "0 (NaN%)"] <- 0
diagnostic_table$Primary_Diagnosis_N[diagnostic_table$Primary_Diagnosis_N == "0 (NaN%)"] <- 0
diagnostic_table$PPV[diagnostic_table$PPV == "NaN (NaN - NaN)"] <- "-"

diagnostic_table <- diagnostic_table %>% select(Criteria, Eligible_N, Admitted_7_days_N, Primary_Diagnosis_N, PPV)

write.csv(diagnostic_table, file = "Outputs/diagnostic_criteria_table.csv", row.names = FALSE)
str(diagnostic_table)
diagnostic_table

dat %>% filter(hosp_7days == 1) %>% filter(abx_all_dur == 1) %>% select(pneumo_term_over20_again, icd01_3d) %>% table()


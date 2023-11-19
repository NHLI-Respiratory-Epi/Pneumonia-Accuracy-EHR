
library(dplyr)
library(readstata13)
library(finalfit)
library(forcats)
library(lme4)
library(officer)

dat <- readRDS("cleanCohort/1_further_cleaning_cohort_pc.RDS")


attributes(dat)

test <- summary_factorlist(dat, dependent = "hosp_pneumo_combo", explanatory = c("bmi_group", "gold"),)
test

# doc_1 <- read_docx() %>%
#   body_add_par("Hello world!", style = "heading 1") %>%
#   body_add_par("", style = "Normal") %>%
#   body_add_table(test, style = "table_template")
# 
# print(doc_1, target = "Outputs/example_1.docx")

# Table 1.

table(dat$smoking_status)


glimpse(dat)
dat %>% select(contains("oxygen")) %>% colnames()
table(dat$cohort_and_diagnosis)


# Table 1

table1_dependent <- "hosp_pneumo_combo"
table1_explanatory <- dat %>% select(gender, age, imd_quintile, smoking_status, bmi_group,
                                     BP_diastolic_value, BP_systolic_value, hypertension, gold,
                                     starts_with("CCI"), asthma_definite, anxiety, depression, lama_laba_5yr, ics_laba_5yr, 
                                     triple_5yr, lama_5yr, laba_5yr, ics_5yr, ocs_5yr, saba_5yr, sama_5yr) %>% select(-CCI_CPD) %>% colnames()

table(dat$asthma_definite)

dat %>% select(all_of(table1_explanatory)) %>% summary()

table1 <- summary_factorlist(dat, table1_dependent, table1_explanatory, p = TRUE, total_col = FALSE)


colnames(table1)[1] <- "Variable"
colnames(table1)[2] <- " "



doc_1 <- read_docx() %>%
  body_add_par("Table 1A", style = "heading 1") %>%
  body_add_table(table1, style = "table_template")

print(doc_1, target = "Outputs/Table1A_new_pc.docx")


table(dat$icd01_3d[dat$hosp_7days == "Yes" & dat$icd_pneumo_first == 0])
table(dat$icd01_1d[dat$hosp_7days == "Yes" & dat$icd_pneumo_first == 0])
prop.table(table(dat$icd01_1d[dat$hosp_7days == "Yes" & dat$icd_pneumo_first == 0]))
sum(table(dat$icd01_1d[dat$hosp_7days == "Yes" & dat$icd_pneumo_first == 0]))

284/886
(398 - 284)/886
109/886
summary(dat$hosp_7days)


library(ggplot2)

unique(dat$pneumo_term_over20_again)

# dat <- dat %>% filter(!is.na(dat$pneumo_term_over20_again) & icd_pneumo_first == 1)
dat <- dat %>% filter(!is.na(icd_pneumo_first))

# Calculate frequency of the categorical variable
dat_freq <- table(dat$pneumo_term_over20_again)
sum(dat_freq)
# Convert the table to a data frame for plotting
dat_freq <- as.data.frame(table(dat$pneumo_term_over20_again))
names(dat_freq) <- c("category", "frequency")

# Create the plot
ggplot(dat_freq, aes(x = category, y = frequency)) +
  geom_bar(stat = "identity", fill = "steelblue") +
  theme_minimal() +
  labs(x = "Pneumonia term", y = "Frequency", title = "Frequency of pneumonia terms recorded in primary care that result in hospitalisation\nwith pneumonia") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) # Rotate x-axis labels if needed

dat_freq$group <- rep(c("A", "B"), 6)

ggplot(dat_freq, aes(x = category, y = frequency, fill = group)) +
  geom_bar(stat = "identity", position = "dodge") +
  scale_fill_manual(values = c("with" = "steelblue", "without" = "salmon")) +
  theme_minimal() +
  labs(x = "Pneumonia term", y = "Frequency", fill = "Group",
       title = "Frequency of pneumonia terms recorded in primary care that result in hospitalisation\nwith pneumonia") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) # Rotate x-axis labels if needed

# Load the ggplot2 package
library(ggplot2)


dat$icd_pneumo_first_det <- NA
dat$icd_pneumo_first_det[dat$icd_pneumo_first == 1] <- "Pneumonia"
dat$icd_pneumo_first_det[dat$icd_pneumo_first == 0] <- "Other"
dat$icd_pneumo_first_det <- factor(dat$icd_pneumo_first_det, levels = c("Other", "Pneumonia"))

# Create the bar chart
ggplot(dat, aes(x=pneumo_term_over20_again, fill=icd_pneumo_first_det)) +
  geom_bar(position="dodge") +
  theme_minimal() +
  labs(x = "Pneumonia term", y = "Frequency", fill = "Primary diagnosis\n in hospital") +
#       title = "Frequency of pneumonia terms recorded in primary care that result in hospitalisation\nwith pneumonia") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))


ggsave("Outputs/pneumonia_codes_breakdown_pc.jpeg")

summary(dat$icd_pneumo_first)

# Table 2

table2_dependent <- "cohort_and_diagnosis"
table2_explanatory <- dat %>% select(gender, age, imd_quintile, smoking_status, bmi, bmi_group,
                                     BP_diastolic, BP_diastolic_value, BP_systolic, BP_systolic_value, asthma_definite,
                                     starts_with("CCI"), hypertension, anxiety, depression, osteoporosis, anaemia, 
                                     lrti_diag_bin, arrhythmia, stroke, atrial_fibrillation, comorbidity_count, gold) %>% colnames()

table2 <- summary_factorlist(dat, table2_dependent, table2_explanatory, p = TRUE, total_col = TRUE)
colnames(table2)[1] <- "Variable"
colnames(table2)[2] <- " "


doc_2 <- read_docx() %>%
  body_add_par("Table 2", style = "heading 1") %>%
  body_add_par("", style = "Normal") %>%
  body_add_table(table2, style = "table_template") %>%
  body_end_block_section(
  value = block_section(property = prop_section(page_size = page_size(orient = "landscape"))))


print(doc_2, target = "Outputs/table2.docx")
  


# Table 3a

table3_dependent <- "cohort"


table3_explanatory <- dat %>% select(spirometry_MR, chestxray, fbc, bmi, all_4_tests, at_least_1_of_3_tests, spiro_and_3tests_cat,
               spirometry_1yr, chestxray_1yr, fbc_1yr, bmi_1yr, all_4_tests_1yr, at_least_1_of_3_tests_1yr, spiro_and_3tests_cat_1yr,
               contains("wheeze"), contains("lrti"), contains("sputum"), contains("breathless"), contains("cough"), contains("symptom")) %>%
  select(-contains("date")) %>% colnames()
    

table3a_dat <- dat %>% filter(patient_disease_type == "None")
table3b_dat <- dat %>% filter(patient_disease_type == "Asthma")
table3c_dat <- dat %>% filter(patient_disease_type == "Heart failure")
table3d_dat <- dat %>% filter(patient_disease_type == "Asthma and heart failure")

str(dat$first_symptom_to_chest_xray)

# table 3a

table3a <- summary_factorlist(table3a_dat, table3_dependent, table3_explanatory, p = TRUE, total_col = TRUE, cont_nonpara = TRUE)
colnames(table3a)[1] <- "Variable"
colnames(table3a)[2] <- " "


doc_3a <- read_docx() %>%
  body_add_par("Table 3a - No asthma or heart failure", style = "heading 1") %>%
  body_add_par("", style = "Normal") %>%
  body_add_table(table3a, style = "table_template")


print(doc_3a, target = "Outputs/table3a.docx")


# table 3b

table3b <- summary_factorlist(table3b_dat, table3_dependent, table3_explanatory, p = TRUE, total_col = TRUE, cont_nonpara = TRUE)
colnames(table3b)[1] <- "Variable"
colnames(table3b)[2] <- " "


doc_3b <- read_docx() %>%
  body_add_par("Table 3b - Asthma, no heart failure", style = "heading 1") %>%
  body_add_par("", style = "Normal") %>%
  body_add_table(table3b, style = "table_template")


print(doc_3b, target = "Outputs/table3b.docx")


# table 3c

table3c <- summary_factorlist(table3c_dat, table3_dependent, table3_explanatory, p = TRUE, total_col = TRUE, cont_nonpara = TRUE)
colnames(table3c)[1] <- "Variable"
colnames(table3c)[2] <- " "


doc_3c <- read_docx() %>%
  body_add_par("Table 3c - Heart failure, no asthma", style = "heading 1") %>%
  body_add_par("", style = "Normal") %>%
  body_add_table(table3c, style = "table_template")


print(doc_3c, target = "Outputs/table3c.docx")

# table 3d

table3d <- summary_factorlist(table3d_dat, table3_dependent, table3_explanatory, p = TRUE, total_col = TRUE, cont_nonpara = TRUE)
colnames(table3d)[1] <- "Variable"
colnames(table3d)[2] <- " "


doc_3d <- read_docx() %>%
  body_add_par("Table 3d - Asthma and heart failure", style = "heading 1") %>%
  body_add_par("", style = "Normal") %>%
  body_add_table(table3d, style = "table_template")


print(doc_3d, target = "Outputs/table3d.docx")


# Table 4... easy again...



table4_dependent <- "cohort"
table4_explanatory <- dat %>% select(contains("_5yr"), referral, hf_referral, echocardiogram, BNP) %>% 
  select(-contains("_no_"), -contains("date"), -contains("diag"), -contains("_to_")) %>%
  colnames()


table4 <- summary_factorlist(dat, table4_dependent, table4_explanatory, p = TRUE, total_col = TRUE)
colnames(table4)[1] <- "Variable"
colnames(table4)[2] <- " "

table4

doc_4 <- read_docx() %>%
  body_add_par("Table 4", style = "heading 1") %>%
  body_add_par("", style = "Normal") %>%
  body_add_table(table4, style = "table_template") 


print(doc_4, target = "Outputs/table4.docx")


# Table 5 - leave for now.


# Table 6 (and 7)

dat %>% select(ends_with("_1yr")) %>% colnames()

table6_dependent <- "cohort"
table6_explanatory <- dat %>% select(lama_laba_1yr, ics_laba_1yr, triple_1yr, lama_1yr, laba_1yr, ics_1yr, ocs_1yr, saba_1yr, sama_1yr,
               oxygen_1yr, pulmonary_rehab_1yr, smoking_cessation_drugs_1yr, smoking_cessation_obs_1yr, smoking_cessation_evidence_1yr,
               fluvac_offer_1yr, fluvac_admin_1yr) %>%
  colnames()


table6 <- summary_factorlist(dat, table6_dependent, table6_explanatory, p = TRUE, total_col = TRUE)
colnames(table6)[1] <- "Variable"
colnames(table6)[2] <- " "

table6


doc_6 <- read_docx() %>%
  body_add_par("Table 6", style = "heading 1") %>%
  body_add_par("", style = "Normal") %>%
  body_add_table(table6, style = "table_template") 


print(doc_6, target = "Outputs/table6.docx")


# table 8 


table8_dependent <- "cohort"
table8_explanatory1 <- dat %>% select(gender, age, imd_quintile, smoking_status, bmi, bmi_group,
                                     BP_diastolic, BP_diastolic_value, BP_systolic, BP_systolic_value, asthma_definite,
                                     starts_with("CCI"), hypertension, anxiety, depression, osteoporosis, anaemia, 
                                     lrti_diag_bin, arrhythmia, stroke, atrial_fibrillation, comorbidity_count, gold) %>% colnames()

table8_explanatory2 <- dat %>% select(spirometry_MR, chestxray, fbc, bmi, all_4_tests, at_least_1_of_3_tests, spiro_and_3tests_cat,
               spirometry_1yr, chestxray_1yr, fbc_1yr, bmi_1yr, all_4_tests_1yr, at_least_1_of_3_tests_1yr, spiro_and_3tests_cat_1yr) %>%
  select(-contains("date")) %>% colnames()

table8_explanatory <- c(table8_explanatory1, table8_explanatory2)

table8_dat <- dat %>% filter(diagnosis_situation_bin == "Secondary care")

table8 <- summary_factorlist(table8_dat, table8_dependent, table8_explanatory, p = TRUE, total_col = TRUE)
colnames(table8)[1] <- "Variable"
colnames(table8)[2] <- " "

doc_8 <- read_docx() %>%
  body_add_par("Table 8", style = "heading 1") %>%
  body_add_par("", style = "Normal") %>%
  body_add_table(table8, style = "table_template") # %>%
 # body_end_block_section(
 #   value = block_section(property = prop_section(page_size = page_size(orient = "landscape"))))

print(doc_8, target = "Outputs/table8.docx")



# table 9a

table9_dependent <- "cohort"
table9_explanatory <- dat %>% select(first_aecopd_event_equiv, diag_to_aecopd_equiv) %>% colnames()


table9a_dat <- dat %>% filter(patient_disease_type == "None")
table9b_dat <- dat %>% filter(patient_disease_type == "Asthma")
table9c_dat <- dat %>% filter(patient_disease_type == "Heart failure")
table9d_dat <- dat %>% filter(patient_disease_type == "Asthma and heart failure")

str(dat$first_symptom_to_chest_xray)

# table 9a

table9a <- summary_factorlist(table9a_dat, table9_dependent, table9_explanatory, p = TRUE, total_col = TRUE, cont_nonpara = TRUE)
colnames(table9a)[1] <- "Variable"
colnames(table9a)[2] <- " "


doc_9a <- read_docx() %>%
  body_add_par("Table 9a - No asthma or heart failure", style = "heading 1") %>%
  body_add_par("", style = "Normal") %>%
  body_add_table(table9a, style = "table_template")


print(doc_9a, target = "Outputs/table9a.docx")


# table 9b

table9b <- summary_factorlist(table9b_dat, table9_dependent, table9_explanatory, p = TRUE, total_col = TRUE, cont_nonpara = TRUE)
colnames(table9b)[1] <- "Variable"
colnames(table9b)[2] <- " "


doc_9b <- read_docx() %>%
  body_add_par("Table 9b - Asthma, no heart failure", style = "heading 1") %>%
  body_add_par("", style = "Normal") %>%
  body_add_table(table9b, style = "table_template")


print(doc_9b, target = "Outputs/table9b.docx")


# table 9c

table9c <- summary_factorlist(table9c_dat, table9_dependent, table9_explanatory, p = TRUE, total_col = TRUE, cont_nonpara = TRUE)
colnames(table9c)[1] <- "Variable"
colnames(table9c)[2] <- " "


doc_9c <- read_docx() %>%
  body_add_par("Table 9c - Heart failure, no asthma", style = "heading 1") %>%
  body_add_par("", style = "Normal") %>%
  body_add_table(table9c, style = "table_template")


print(doc_9c, target = "Outputs/table9c.docx")

# table 9d

table9d <- summary_factorlist(table9d_dat, table9_dependent, table9_explanatory, p = TRUE, total_col = TRUE, cont_nonpara = TRUE)
colnames(table9d)[1] <- "Variable"
colnames(table9d)[2] <- " "


doc_9d <- read_docx() %>%
  body_add_par("Table 9d - Asthma and heart failure", style = "heading 1") %>%
  body_add_par("", style = "Normal") %>%
  body_add_table(table9d, style = "table_template")


print(doc_9d, target = "Outputs/table9d.docx")


# table 9a
# table 9a


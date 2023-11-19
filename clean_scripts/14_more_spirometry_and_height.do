/*******************************************************************************

AUTHOR:					AA
DATE: 					24-12-2021
VERSION:				STATA 16.1
DO FILE NAME:			25_extract height and lung function

DESCRIPTION OF FILE:	


*******************************************************************************/
clear all
set more off, perm
macro drop _all


capture log close
log using "Logs/14_more_spirometry_and_height", replace

global hes_extract "Aurum_linked\"
global cohort "workingCohort\"
*global working_data "workingData\"
global working_data "workingData\"
global extract "extractDataMini\"
*global codelist "Code_lists\CPRD_Aurum\"

*NOTE - FOR THIS DRUG ISSUE ONE, I HAVE USED EMILY'S NEW CODELIST SAVED IN THE ORIGINAL CODELISTS FOLDER
global codelist "Code_lists\CPRD_Aurum\"

global covar "covariates\"




forvalues f=1/84{
	local i=string(`f',"%03.0f")
use ${extract}Observation_`i'.dta, clear


*using the medcode ids first is probably faster?




merge m:1 patid using ${cohort}10_add_patient_demographics.dta
keep if _m==3 
drop _m


save ${working_data}height_`i', replace
}


use ${working_data}height_001, clear
forvalues f=2/84{
	local i=string(`f',"%03.0f")
append using ${working_data}height_`i'
}

save ${working_data}height, replace


use ${working_data}height, clear

* We need height as well for GOLD

drop if value == .
drop if value == 0

sort value

list value in 1/30

tab numunitid, m

*122 = cm
*408 = cm
*173 = m
*432 = m

*don't need any others so drop.

keep if numunitid == 122 | numunitid == 173 | numunitid == 408 | numunitid == 432 

gen unit="cm" if numunitid==122 | numunitid==408
replace unit="m" if numunitid==173 | numunitid==432

drop if unit == ""

* Sort out ridic values
replace unit="cm" if value > 2.72 & unit == "m"
replace unit="m" if value < 3 & unit == "cm"

replace value = value*100 if unit == "m"

* everything is now in cm so we drop the unit
drop unit

sort value


count if value > 272
count if value < 101

*drop if taller than the tallest person ever
drop if value > 272
* drop if shorter than the shortest person ever to live to 105
* Also, the value "100" could easily be mixed up with other things.
drop if value < 101

*just take the most recent height to starting the study

drop if obsdate > pneumonia_pc_date

*also, drop if the values are before they're born or before they've stopped growing...
* so, drop if height measure before the age of 25.


sort patid obsdate

by patid: gen litn=_n
by patid: gen bign=_N
keep if litn==bign

keep patid obsdate value



rename obsdate height_date
rename value height

save ${covar}height_final, replace

*we need the height to calculate the fev1_pred_calc
* to make it consistent with FEV1_pred_GP, we should take the age at the time the height is measured.



* These are the ECSC equations

*we need to create the age at which the height was measured...

use ${covar}height_final, clear



merge 1:1 patid using ${cohort}10_add_patient_demographics
keep if _m == 3
drop _m


drop if height_date < pneumonia_pc_date - ((age-25)*365.25)



gen diff = pneumonia_pc_date - height_date

gen ageatmeasurement = (age*365.25 - diff)/365.25

sum ageatmeasurement

tab gender
codebook gender


gen fev1_pred_calc=((0.043*height) - (0.0290*ageatmeasurement)-2.490) if gender==1
replace fev1_pred_calc=((0.0395*height) - (0.025*ageatmeasurement)-2.6) if gender==2

codebook fev1_pred_calc

*height date is going to be fev1_pred_calc_date

rename height_date fev1_pred_calc_date

*We keep the most recent one


keep patid fev1_pred_calc fev1_pred_calc_date

save ${covar}fev1_pred_calc, replace

* now we make our %-predicteds

*fev1_perc_pred_calc1 is calculated using GP-derived predicted FEV1
*fev1_perc_pred_calc2 is calculated using ECSC equations for predicted FEV1


use ${covar}fev1, clear



merge 1:1 patid using ${covar}fev1_pred_calc
*we need people with FEV1, so if they're missing the exercise is pointless
keep if _m == 1 | _m == 3
drop _m

gen fev1_perc_pred_calc2 = (fev1/fev1_pred_calc)*100


merge 1:1 patid using ${covar}fev1_pred_GP
keep if _m == 1 | _m == 3
drop _m

gen fev1_perc_pred_calc1 = (fev1/fev1_pred_GP)*100


replace fev1_perc_pred_calc1=. if fev1_perc_pred_calc1>151 
replace fev1_perc_pred_calc1=.  if fev1_perc_pred_calc1<8 

replace fev1_perc_pred_calc2=. if fev1_perc_pred_calc2>151 
replace fev1_perc_pred_calc2=.  if fev1_perc_pred_calc2<8 

keep if fev1_perc_pred_calc1 != . | fev1_perc_pred_calc2 != .

*keep the things we want and save them
* the correct dates will be derived from fev1 and the calculation dates.

keep patid fev1_perc_pred_calc1 fev1_perc_pred_calc2

save ${covar}fev1_perc_pred_calc, replace


*and finally we create the FEV1 perc-pred combo.
* we go from GP documented > GP calculated predicted > our prediction calculation

use ${covar}fev1_percent_pred_GP, clear
gen fev1_perc_pred_type = 1

merge 1:1 patid using ${covar}fev1_perc_pred_calc
* We want everyone...
drop _m

gen fev1_perc_pred_combo = fev1_percent_pred_GP

replace fev1_perc_pred_type = 2 if fev1_perc_pred_combo == . & fev1_perc_pred_calc1 != .
replace fev1_perc_pred_combo = fev1_perc_pred_calc1 if fev1_perc_pred_combo == .

replace fev1_perc_pred_type = 3 if fev1_perc_pred_combo == . & fev1_perc_pred_calc2 != .
replace fev1_perc_pred_combo = fev1_perc_pred_calc2 if fev1_perc_pred_combo == .

gen fev1_perc_pred_combo_date = fev1_percent_pred_GP_date

merge 1:1 patid using ${covar}fev1
keep if _m == 3 | _m == 1

replace fev1_perc_pred_combo_date = fev1_date if fev1_perc_pred_combo_date == .
codebook fev1_perc_pred_combo_date

format %td fev1_perc_pred_combo_date

codebook fev1_perc_pred_combo_date

label define fev1_perc_pred_type 1 "GP" 2 "GP-calculated %-pred" 3 "ECSC-calculated %-pred"

label variable fev1_perc_pred_type fev1_perc_pred_type

keep patid fev1_perc_pred_combo fev1_perc_pred_combo_date fev1_perc_pred_type
codebook
save ${covar}fev1_perc_pred_calc_all, replace

log close


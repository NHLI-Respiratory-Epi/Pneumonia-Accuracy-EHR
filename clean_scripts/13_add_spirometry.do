* Add lung function

clear all
set more off, perm
macro drop _all



capture log close
log using "Logs/13_add_spirometry", replace

global hes_extract "Aurum_linked\"
global cohort "workingCohort\"
*global working_data "workingData\"
global working_data "workingData/"
global extract "extractDataMini\"
*global codelist "Code_lists\CPRD_Aurum\"

*NOTE - FOR THIS DRUG ISSUE ONE, I HAVE USED EMILY'S NEW CODELIST SAVED IN THE ORIGINAL CODELISTS FOLDER
global codelist "Code_lists\CPRD_Aurum\"

global covar "covariates\"

forvalues f=1/84{
	local i=string(`f',"%03.0f")		
	use ${extract}Observation_`i'.dta, clear

	drop pracid
	

	merge m:1 medcodeid using ${codelist}spirometry
	keep if _m==3 
	drop _m
		
	merge m:1 patid using ${cohort}10_add_patient_demographics.dta
	keep if _m==3 
	drop _m

	save ${working_data}spirometry_`i'.dta, replace

}

use ${working_data}spirometry_001.dta, clear

	forvalues f = 2/84{ 
		local i=string(`f',"%03.0f")	
	append using ${working_data}spirometry_`i'
	}
	
save ${working_data}spirometry.dta, replace


*all lung function
use ${working_data}spirometry, clear


* create the most recent spirometry yes/no variables

drop if obsdate > pneumonia_pc_date

sort patid obsdate
drop if obsdate < pneumonia_pc_date - age*365.25

by patid: keep if _n == _N

rename obsdate any_spirometry_date

keep patid spirometry any_spirometry_date

save ${covar}any_spirometry, replace

* create earliest spirometry date

*all lung function
use ${working_data}spirometry, clear


* create the first spirometry yes/no variables

drop if obsdate > pneumonia_pc_date
drop if obsdate < pneumonia_pc_date - age*365.25

sort patid obsdate
by patid: keep if _n == 1

rename obsdate first_spirometry_date
rename spirometry first_spirometry
keep patid first_spirometry first_spirometry_date

save ${covar}first_spirometry, replace




*specific lung function

use ${working_data}spirometry, clear

rename fev1_predicted fev1_pred
rename fvc_predicted fvc_pred

tab numunitid if fev1!=.

* Some of the bigger ones that we don't pick up here are in liters/min, which isn't appropriate for what we want.

tab fvc_pred


*1=%, 160=litres, 166=litres, 167=litres, 200=ml, 315=ml, 839=litres, 928=litres, 334=L (maybe)
keep if fev1==1 | fev1_percent_pred==1 | fev1_pred == 1 | fvc==1 | fvc_percent_pred==1 | fvc_pred == 1 |fev1_fvc_ratio == 1 
gen fev1_1=value if fev1==1 
gen fev1_pred_1=value if fev1_pred==1
gen fev1_percent_pred_1=value if fev1_percent_pred==1
gen fvc_1=value if fvc==1
gen fvc_pred_1=value if fvc_pred==1
gen fvc_percent_pred_1=value if fvc_percent_pred==1
gen fev1_fvc_ratio_1 = value if fev1_fvc_ratio == 1
gen unit="L" if numunitid==160 | numunitid==167 | numunitid==839 | numunitid==928 | numunit==166 | numunit==334
replace unit="ml" if numunitid==200 | numunitid==315
replace unit="%" if numunitid==1 
drop fev1 fev1_pred fev1_percent_pred fvc fvc_pred fvc_percent_pred fev1_fvc_ratio fev1_fvc_ratio_predicted fev1_fvc_ratio_percent_pred
rename fev1_1 fev1
rename fev1_pred_1 fev1_pred
rename fev1_percent_pred_1 fev1_percent_pred
rename fvc_1 fvc
rename fvc_pred_1 fvc_pred
rename fvc_percent_pred_1 fvc_percent_pred
rename fev1_fvc_ratio_1 fev1_fvc_ratio

tab unit

*transform ml to litres
replace unit="L" if fev1<=20 & fev1 != .
replace unit="L" if fvc<=20 & fvc != .
replace fev1=fev1/1000 if unit=="ml"
replace fvc=fvc/1000 if unit=="ml"
replace unit="L" if fev1_pred<=20 & fev1_pred != .
replace unit="L" if fvc_pred<=20 & fvc_pred != .
replace fev1_pred=fev1_pred/1000 if unit=="ml"
replace fvc_pred=fvc_pred/1000 if unit=="ml"

replace unit = "L" if unit=="ml"



* Don't drop according to obstype, it's not that consistent
*keep if obstypeid == 10
* Instead, drop if missing a value

drop if value == .



*93% of observations don't specify whether a bronchodilator was used. No point in dealing with the post-broncho anymore.


* If FEV1 and FVC has been incorrectly calculated as %-predicted, we change it to the right measurement.



replace fev1_percent_pred = fev1 if fev1 != . & unit == "%"
replace fev1 = . if fev1 != . & unit == "%"

*hist fvc if fvc != . & unit == "%"


replace fvc_percent_pred = fvc if fvc != . & unit == "%"
replace fvc = . if fvc != . & unit == "%"

*The same thing has happened with the %-predicted.
* I don't think we can change these ones though because it's not obvious whether the value is meant to be the patient value or the predicted value. So instead we drop them.

*replace fev1_pred = fev1_percent_pred if fev1_percent_pred != . & unit == "L"
replace fev1_percent_pred = . if fev1_percent_pred != . & unit == "L"

*replace fvc_pred = fvc_percent_pred if fvc_percent_pred != . & unit == "L"
replace fvc_percent_pred = . if fvc_percent_pred != . & unit == "L"



* There are a lot of crazy fev1 values

*hist if fev1 > 5 & fev1 != .
*bro if fev1 > 20 & fev1 != .

*from looking at the histograms, I think we should drop values >5.5.
* Seem to be a fair amount of miscoding.
* Some code be miscoded as %-predicted, some might be height, some might be ml instead of litres... it's not possible to clean it so we have to drop it.

drop if fev1 != . & fev1 > 5.5
drop if fvc > 8 & fvc != .
drop if fev1_pred != . & fev1_pred > 5.5
drop if fvc_pred != . & fvc_pred > 8



codebook fev1
*hist fev1 if fev1 < 0.85 & fev1 > 0
*hist fev1 if fev1 > 0

* fev1 also literally can't be less than 0
drop if fev1 != . & fev1 <= 0
drop if fvc != . & fvc <= 0
drop if fev1_pred != . & fev1_pred <= 0
drop if fvc_pred != . & fvc_pred <= 0


* There are still a few crazy values for fev1_percent_pred as well. For the lower ones, it's not really possible to clean them because they could be proportion instead of %, or they could be expected fev1 (L) OR patient's fev1. 
* Therefore we just have to drop them. 

*bro if fev1_percent_pred != . & fev1_percent_pred > 151
*bro if fev1_percent_pred != . & fev1_percent_pred < 8

drop if fev1_percent_pred != . & fev1_percent_pred < 8
drop if fev1_percent_pred != . & fev1_percent_pred > 151
drop if fvc_percent_pred != . & fvc_percent_pred < 8
drop if fvc_percent_pred != . & fvc_percent_pred > 151


sum, det

* How do 75,000 people have a ratio greater than 1???
count if fev1_fvc_ratio > 1 & fev1_fvc_ratio != .
count if fev1_fvc_ratio <= 1 & fev1_fvc_ratio != .
count if fev1_fvc_ratio > 100 & fev1_fvc_ratio != .



*It's because some are fvc or fev1, and most are expressed as percentages. Will just calculate it myself...

*a ratio <0.2 is crazy so we drop it.

drop if fev1_fvc_ratio != . & fev1_fvc_ratio > 100
drop if fev1_fvc_ratio != . & fev1_fvc_ratio > 1 & fev1_fvc_ratio < 20

count if fev1_fvc_ratio == .
count if fev1_fvc_ratio != .

count if fev1_fvc_ratio > 1 & fev1_fvc_ratio != .




replace fev1_fvc_ratio = fev1_fvc_ratio/100 if fev1_fvc_ratio > 1
drop if fev1_fvc_ratio < 0.2 & fev1_fvc_ratio != .
drop if fev1_fvc_ratio > 1 & fev1_fvc_ratio != .

sum fev1_fvc_ratio, det

* Not in %s any more

replace unit = "" if fev1_fvc_ratio != .


*We don't need predicted fev1_fvc_ratio or %-pred.

*Everything is now clean!!!


sum fev1-fev1_fvc_ratio, det

*rename the variables so it's obvious whether they've been calculated by us or by the GP.

rename fev1_pred fev1_pred_GP
rename fev1_percent_pred fev1_percent_pred_GP
rename fvc_pred fvc_pred_GP
rename fvc_percent_pred fvc_percent_pred_GP
rename fev1_fvc_ratio fev1_fvc_ratio_GP


rename obsdate spirometry_date

keep patid spirometry_date fev1-fev1_fvc_ratio_GP

save ${working_data}clean_spirometry_details_all, replace

*and finally we take the perc-pred spirometry we need to calculate GOLD status:

use ${working_data}clean_spirometry_details_all, clear

merge m:1 patid using ${cohort}10_add_patient_demographics.dta

keep if _m == 3

drop if spirometry_date > pneumonia_pc_date

drop if spirometry_date < pneumonia_pc_date - (age*365.25)

codebook patid

*55,129 people still in dataset

* we only want percent predicted

keep if fev1_percent_pred_GP != .

*this results in only 31,764 patients remaining

sort patid spirometry_date

by patid: keep if _n == _N

rename spirometry_date fev1_percent_pred_GP_date
keep patid fev1_percent_pred_GP_date fev1_percent_pred_GP

codebook patid

save ${covar}fev1_percent_pred_GP, replace


* and for FEV1...

use ${working_data}clean_spirometry_details_all, clear

merge m:1 patid using ${cohort}10_add_patient_demographics.dta

keep if _m == 3

drop if spirometry_date > pneumonia_pc_date

drop if spirometry_date < pneumonia_pc_date - (age*365.25)

codebook patid

*55,129 people still in dataset

* we only want percent predicted

keep if fev1 != .


sort patid spirometry_date

by patid: keep if _n == _N

rename spirometry_date fev1_date
keep patid fev1_date fev1

codebook patid fev1

save ${covar}fev1, replace



* for FEV1_pred:


use ${working_data}clean_spirometry_details_all, clear

merge m:1 patid using ${cohort}10_add_patient_demographics.dta

keep if _m == 3

drop if spirometry_date > pneumonia_pc_date

drop if spirometry_date < pneumonia_pc_date - (age*365.25)

codebook patid

*55,129 people still in dataset

* we only want percent predicted

keep if fev1_pred_GP != .


sort patid spirometry_date

by patid: keep if _n == _N

rename spirometry_date fev1_pred_GP_date
keep patid fev1_pred_GP_date fev1_pred_GP

save ${covar}fev1_pred_GP, replace




log close






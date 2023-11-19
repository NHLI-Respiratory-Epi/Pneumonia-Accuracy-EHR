clear

*** Open a log file to save your screen results

capture log close /*closes any open log files*/


* PATH FOR LOG FILES: useful for record keeping but not essential

log using "Analysis\Logs\0_HES_linked_to_dta", replace



* time for each command run and overall run time

set rmsg on

macro drop _all




*********************************************************************
* CREATE LOCAL MACROS

* PATH FOR THE DATA TO GO TO
local path_goto "extractHES" 
*
*
* PATH WHERE DATA ORIGINALLY COMES FROM:
local path_from "21_000468\Final"

*********************************************************************

clear
set more off
 
cd "`path'"

/*
The commands below basically say - look in the directory you have specified as
path_orig and memorise all the file names.  Then, for each of the file names 
perform the command in the loop. In this case its import. The imported files
will be put where you have specific 'path' goes in your local macros.

*/

*


local filelist: dir "`path_from'" files "*.txt", respectcase
local counter=1
foreach file of local filelist {
	* Read in the data
	import delimited "`path_from'/`file'", stringcols(1) clear
	save "`path_goto'/`file'"

	*I'm not using replace because I don't want something to go wrong and I delete all my data
	
}
*

	
frame reset

macro drop _all

set rmsg off

clear

log close



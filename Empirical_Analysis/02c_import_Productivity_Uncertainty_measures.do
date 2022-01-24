// import the proudctivity uncertainty (PU) measures created in Wenxi's
// program measure_productivity_uncertainty.m


/*housekeeping*/

	set more off

	/*change to project directory (exact file path differs by user)*/
	cd "C:\Users\tuk40836\Dropbox\Research\BCLR\1_SafeCapital"
	
	/*path where analysis specific intermediate or final datasets are saved*/
	global dtapath     = "Empirical_Analysis\dta"
	global PUdatapath  = "Empirical_Analysis\data_for_Productivity_Uncertainty"
	global VARdatapath = "Empirical_Analysis\data_for_VAR"
	global outFigure = "Empirical_Analysis\figures"

	
	
/*********************************************************************************************/		
// productivity uncertainty measure computed in Wenxi's "measure_productivity_uncertainty.m"

	import delimited "${PUdatapath}\data_inv_reg_qtr_1961_2016.csv", clear
	gen dateqtr = yq(year,qtr)
	format dateqtr %tq	
	order dateqtr
	label var expvol "Productivity Uncertainty"
	save "${dtapath}\data_inv_reg_qtr_1961_2016", replace
	
	// compare against ivol
	merge 1:1 dateqtr using "${dtapath}\integrated_volatility_quarterly", nogen noreport keep(master match) keepusing(ivol)

	// some simple checks
	corr ivol expvol
	local mycorr = `r(rho)'
	twoway (line ivol dateqtr, yaxis(1)) || (line expvol dateqtr, yaxis(2)), title("ivol vs expvol (corr=`mycorr')")
	graph export "${outFigure}\tsline_ivol_vs_expvol.png", replace
	
	gen ln_expvol = ln(expvol)
	corr ivol ln_expvol
	local mycorr = `r(rho)'
	twoway (line ivol dateqtr, yaxis(1)) || (line ln_expvol dateqtr, yaxis(2)), title("ivol vs ln(expvol) (corr=`mycorr')")
	graph export "${outFigure}\tsline_ivol_vs_ln_expvol.png", replace	
	
	gen pu = 100*(expvol-1)
	corr ivol pu
	local mycorr = `r(rho)'
	twoway (line ivol dateqtr, yaxis(1)) || (line pu dateqtr, yaxis(2)), title("ivol vs expvol (corr=`mycorr')")
	graph export "${outFigure}\tsline_ivol_vs_pu.png", replace	
	
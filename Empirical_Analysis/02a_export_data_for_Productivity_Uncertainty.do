/*export data to use in estimating our productivity uncertainty measure*/


/*housekeeping*/

	set more off

	/*change to project directory (exact file path differs by user)*/
	cd "C:\Users\tuk40836\Dropbox\Research\BCLR\1_SafeCapital"
	
	/*path where analysis specific intermediate or final datasets are saved*/
	global dtapath    = "Empirical_Analysis\dta"
	global PUdatapath = "Empirical_Analysis\data_for_Productivity_Uncertainty"
	

	
/*********************************************************************************************/		
/*quarterly data*/

	// compute dtfp 
	use "${dtapath}\tfp_data_from_frbsf_quarterly", clear
	keep dateqtr dtfp_busi_sector_reg_frbsf 
	rename dtfp_busi_sector_reg_frbsf tfpgrowth // to match original file

	
	// treasury yields
	merge 1:1 dateqtr using "${dtapath}\treasury_zero_coupon_yields_quarterly", nogen 
	forvalues j=1/7 {
		rename sveny0`j' bondy`j'q // to match original file
	}
	
	
	// inflation
	merge 1:1 dateqtr using "${dtapath}\inflation_quarterly", nogen keepusing(inflation)
	rename inflation inflationq // to match original file
	
	
	// long-term government bond returns
	merge 1:1 dateqtr using "${dtapath}\ibbotson_quarterly", nogen keepusing(ltgovbd)
	rename ltgovbd ltgovbond // to match original file
	
	
	// PD ratio	
	merge 1:1 dateqtr using "${dtapath}\pd_ratio_quarterly", nogen keepusing(pd_ratio_end)
	rename pd_ratio_end pdratio	
	
	
	// integrated volatility
	merge 1:1 dateqtr using "${dtapath}\integrated_volatility_quarterly", nogen keepusing(ivol)
		

	/*separate dateqtr to year and qtr vars*/
	gen year = year(dofq(dateqtr))
	gen month = month(dofq(dateqtr))
	gen qtr  = 1
	replace qtr = 2 if month== 4
	replace qtr = 3 if month== 7
	replace qtr = 4 if month==10
	drop month		

	
	// export the file
	sort dateqtr
	drop dateqtr // not needed
	// to keep same order as Wenxi's file	
	order tfpgrowth year qtr bondy1q bondy2q bondy3q bondy4q bondy5q bondy6q bondy7q inflationq ltgovbond pdratio ivol
	save "${dtapath}\data_for_PU_measure", replace
	
		// 1961-2016
		use "${dtapath}\data_for_PU_measure", clear
		keep if year>=1961 & year<=2016
		drop if year==1961 & qtr==1 // no yield curve data
		outsheet using "${PUdatapath}\data_for_PU_measure_1961_2016.csv", replace comma
	
		// 1969-2016
		use "${dtapath}\data_for_PU_measure", clear
		keep if year>=1969 & year<=2016
		outsheet using "${PUdatapath}\data_for_PU_measure_1969_2016.csv", replace comma	
	
		// 1972-2016
		use "${dtapath}\data_for_PU_measure", clear
		keep if year>=1972 & year<=2016
		outsheet using "${PUdatapath}\data_for_PU_measure_1972_2016.csv", replace comma		

		
		
		
		
/*********************************************************************************************/		
/*annual data*/

	// compute dtfp 
	use "${dtapath}\tfp_data_from_frbsf_annual", clear
	keep year dtfp_busi_sector_reg_frbsf 
	rename dtfp_busi_sector_reg_frbsf tfpyg // to match original file

	
	// treasury yields
	merge 1:1 year using "${dtapath}\treasury_zero_coupon_yields_annual", nogen 
	forvalues j=1/7 {
		rename sveny0`j' bondy`j'y // to match original file
	}
	
	
	// inflation
	merge 1:1 year using "${dtapath}\inflation_annual", nogen keepusing(inflation)
	rename inflation inflationy // to match original file
	
	
	// long-term government bond returns
	merge 1:1 year using "${dtapath}\ibbotson_annual", nogen keepusing(ltgovbd)
	rename ltgovbd ltgovbond // to match original file
	
	
	// PD ratio	
	merge 1:1 year using "${dtapath}\pd_ratio_annual", nogen keepusing(pd_ratio_end)
	rename pd_ratio_end pdratioy	
	
	
	// integrated volatility
	merge 1:1 year using "${dtapath}\integrated_volatility_annual", nogen keepusing(ivol)
	rename ivol ivoly
		

	// export the file
	sort year
	// to keep same order as Wenxi's file	
	order tfpyg year bondy1y bondy2y bondy3y bondy4y bondy5y bondy6y bondy7y inflationy ltgovbond pdratioy ivoly
	save "${dtapath}\data_for_ann_PU_measure", replace
	
		// 1961-2016
		use "${dtapath}\data_for_ann_PU_measure", clear
		keep if year>=1961 & year<=2016
		outsheet using "${PUdatapath}\data_for_ann_PU_measure_1961_2016.csv", replace comma
	
		// 1969-2016
		use "${dtapath}\data_for_ann_PU_measure", clear
		keep if year>=1969 & year<=2016
		outsheet using "${PUdatapath}\data_for_ann_PU_measure_1969_2016.csv", replace comma	
	
		// 1972-2016
		use "${dtapath}\data_for_ann_PU_measure", clear
		keep if year>=1972 & year<=2016
		outsheet using "${PUdatapath}\data_for_ann_PU_measure_1972_2016.csv", replace comma		
		
/*export macro and aggregated data for use in Wenxi's empirical analysis that
  predicts TFP growth using an array of forecasting variables including ratios
  of capital. this program uses data created in 03_micro_summ_stats_and_regs*/


/*housekeeping*/

	set more off

	/*change to project directory (exact file path differs by user)*/
	cd "C:\Users\tuk40836\Dropbox\Research\BCLR\1_SafeCapital"
	
	/*path where analysis specific intermediate or final datasets are saved*/
	global dtapath     = "Empirical_Analysis\dta"
	global TFPpredPath = "Empirical_Analysis\data_for_tfpg_prediction"

	
/*********************************************************************************************/		
// redo the data export in June 2020 only series that are needed
	
// compustat-based data at monthly freq
use lpermno datemo at_F0 xrd_F0 capx_F0 using "${dtapath}\crsp_merged_with_monthly_compustat", clear
merge 1:1 lpermno datemo using "${dtapath}\port_rebal_monthly", nogen // should be exact match with all obs	
keep if ~missing(port)
gen year = year(dofm(datemo))
// values for high R&D portfolio
gen at_5   = at_F0   if port==5 
gen xrd_5  = xrd_F0  if port==5 // high R&D
gen capx_5 = capx_F0 if port==5 // high R&D
collapse ///
	(sum) ///
		at_all=at_F0 ///
		xrd_all=xrd_F0 ///
		capx_all=capx_F0 ///
		at_5 ///
		xrd_5 ///
		capx_5 ///
	(count) ///
		Nfirms_all=at_F0 ///
		Nfirms_5=at_5 ///
	, by(year datemo) 	

// compute ratios and then convert to annual. use end-of-year value because
// that corresponds to the BEA value
gen comp_pct_at_high_rnd  = 100 * at_5 / at_all
gen comp_pct_inv_high_rnd = 100 * (xrd_5+capx_5) / (xrd_all+capx_all)
//gen comp_rnd_to_assets_all = xrd_all / at_all
//gen comp_rnd_to_assets_5   = xrd_5 / at_5
keep if month(dofm(datemo))==12	
drop datemo	
keep year comp_*
	
// annual data used in the annual productivity uncertainty (PU) measure
// see 02a_export_data_for_Productivity_Uncertainty.do
merge 1:1 year using "${dtapath}\data_for_ann_PU_measure", nogen
	
// multiply inflation by 100 to make in percent as well
replace inflationy = 100 * inflationy
	
// national aggregates
merge 1:1 year using "${dtapath}\bea_annual", nogen keepusing(gross_priv_inv_nom gross_govt_inv_nom gross_fpi_ipp_rnd gross_fpi_ipp_tot)
// fixed assets (or book capital or produced assets) from the BEA
merge 1:1 year using "${dtapath}\bea_fixed_assets_tables_data_annual", nogen keepusing(govt_fa_tot govt_fa_ipp_rnd priv_fa_tot priv_fa_ipp_rnd)
/*descriptions:
	priv_fa_tot: "Produced Fixed Assets (Private), Billions of Dollars"	
	govt_fa_tot: "Produced Fixed Assets (Govt), Billions of Dollars"
*/		
// measures of financial conditions
merge 1:1 year using "${dtapath}\chicago_fed_fci_ann", nogen keep(master match) keepusing(anfci nfci)
merge 1:1 year using "${dtapath}\credit_spreads_ann", nogen keep(master match) keepusing(aaa10ym baa10ym)	
	
// compute additional ratios in percent needed vars
gen bea_pct_kg_ktot = 100 * govt_fa_tot / (govt_fa_tot+priv_fa_tot)
gen bea_pct_kgnonrnd_ktot = 100 * (govt_fa_tot-govt_fa_ipp_rnd) / (govt_fa_tot+priv_fa_tot) // take out govt R&D capital
gen bea_pct_ig_itot = 100 * gross_govt_inv_nom / (gross_priv_inv_nom+gross_govt_inv_nom)
gen bea_pct_krnd_kpriv = 100 * priv_fa_ipp_rnd / priv_fa_tot
gen bea_pct_irnd_ipriv = 100 * gross_fpi_ipp_rnd / gross_priv_inv_nom

// only keep years we use in analysis
keep if year>=1972 & year<=2016

// save and export
save "${dtapath}\data_for_tfpg_prediction_june2020", replace
outsheet using "${TFPpredPath}\data_for_tfpg_prediction_june2020.csv", replace comma
	
// test regressions

	// create forward moving averages
	tsset year	
	gen  fma5yr_tfpyg = (tfpyg + F1.tfpyg + F2.tfpyg + F3.tfpyg + F4.tfpyg)/5
	gen  fma7yr_tfpyg = (tfpyg + F1.tfpyg + F2.tfpyg + F3.tfpyg + F4.tfpyg + F5.tfpyg + F6.tfpyg)/7
	gen fma10yr_tfpyg = (tfpyg + F1.tfpyg + F2.tfpyg + F3.tfpyg + F4.tfpyg + F5.tfpyg + F6.tfpyg + F7.tfpyg + F8.tfpyg + F9.tfpyg)/10
	
	// differences in ratios
	gen diff_ratios_bea_krnd_kgovt = bea_pct_krnd_kpriv - bea_pct_kg_ktot
	
	// detrend
	foreach myvar in "fma5yr_tfpyg" "fma7yr_tfpyg" "fma10yr_tfpyg" "comp_pct_at_high_rnd" "bea_pct_krnd_kpriv" "bea_pct_kg_ktot" "diff_ratios_bea_krnd_kgovt" {
		tsfilter hp `myvar'_dt = `myvar', smooth(10000) // set smooth param very high b/c essentially want to de-mean	
	}
	//tsline fma10yr_tfpyg_dt fma10yr_tfpyg

	// compustat high rnd capital percentage
	reg fma10yr_tfpyg_dt comp_pct_at_high_rnd_dt bondy1y bondy2y bondy3y bondy4y bondy5y bondy6y inflationy ltgovbond pdratioy ivoly nfci anfci baa10ym, robust
	reg fma10yr_tfpyg_dt comp_pct_at_high_rnd_dt bondy1y bondy2y bondy3y bondy4y bondy5y bondy6y inflationy ltgovbond pdratioy ivoly nfci anfci baa10ym, nocons robust	
	
	// bea private rnd capital percentage
	reg fma10yr_tfpyg_dt bea_pct_krnd_kpriv_dt bondy1y bondy2y bondy3y bondy4y bondy5y bondy6y inflationy ltgovbond pdratioy ivoly nfci anfci baa10ym, robust
	reg fma10yr_tfpyg_dt bea_pct_krnd_kpriv_dt bondy1y bondy2y bondy3y bondy4y bondy5y bondy6y inflationy ltgovbond pdratioy ivoly nfci anfci baa10ym, nocons robust
		
	// bea govt capital percentage
	reg fma10yr_tfpyg_dt bea_pct_kg_ktot_dt bondy1y bondy2y bondy3y bondy4y bondy5y bondy6y inflationy ltgovbond pdratioy ivoly nfci anfci baa10ym, robust
	reg fma10yr_tfpyg_dt bea_pct_kg_ktot_dt bondy1y bondy2y bondy3y bondy4y bondy5y bondy6y inflationy ltgovbond pdratioy ivoly nfci anfci baa10ym, nocons robust
		
	// bea govt capital percentage
	reg fma10yr_tfpyg_dt diff_ratios_bea_krnd_kgovt_dt bondy1y bondy2y bondy3y bondy4y bondy5y bondy6y inflationy ltgovbond pdratioy ivoly nfci anfci baa10ym, robust
	reg fma10yr_tfpyg_dt diff_ratios_bea_krnd_kgovt_dt bondy1y bondy2y bondy3y bondy4y bondy5y bondy6y inflationy ltgovbond pdratioy ivoly nfci anfci baa10ym, nocons robust		
		
	

/*********************************************************************************************/		
// compile main dataset of aggregated micro data and macro data
	
	// combined data
	use lpermno datemo at_F0 xrd_F0 capx_F0 using "${dtapath}\crsp_merged_with_monthly_compustat", clear
	merge 1:1 lpermno datemo using "${dtapath}\port_rebal_monthly", nogen // should be exact match with all obs	
	keep if ~missing(port)
	gen year = year(dofm(datemo))
	gen comp_assets_5 = at   if port==5 // high R&D
	gen comp_rnd_5    = xrd  if port==5 // high R&D
	gen comp_capx_5   = capx if port==5 // high R&D
	collapse (sum)  comp_assets_all=at comp_assets_5 ///
					comp_rnd_all=xrd   comp_rnd_5 ///
					comp_capx_all=capx comp_capx_5 ///				
		, by(year datemo) 	
	
	// average over the year instead of taking just a single month (e.g., July or December)
	collapse (mean) comp_* , by(year)

	// total investment
	gen comp_totinv_all = comp_rnd_all + comp_capx_all
	gen comp_totinv_5   = comp_rnd_5 + comp_capx_5
	
	// national aggregates
	merge 1:1 year using "${dtapath}\bea_annual", nogen
	// fixed assets (or book capital or produced assets) from the BEA
	merge 1:1 year using "${dtapath}\bea_fixed_assets_tables_data_annual", nogen keep(master match) 
	/*descriptions:
		priv_fa_tot: "Produced Fixed Assets (Private), Billions of Dollars"	
		govt_fa_tot: "Produced Fixed Assets (Govt), Billions of Dollars"
	*/		
	// measures of financial conditions
	merge 1:1 year using "${dtapath}\chicago_fed_fci_ann", nogen keep(master match) keepusing(anfci nfci)
	merge 1:1 year using "${dtapath}\credit_spreads_ann", nogen keep(master match) keepusing(aaa10ym baa10ym)		
	
	// total investment
	gen bea_priv_totinv = gross_priv_inv_nom
	gen bea_govt_totinv = gross_govt_inv_nom			
	
	// rename other variables for convenience			
	gen bea_priv_rnd = gross_fpi_ipp_rnd	
	gen bea_govt_rnd = gross_govt_inv_nom_rnd	
	//gen bea_govt_rnd_fed_def    = govt_inv_rnd_fed_def
	//gen bea_govt_rnd_fed_nondef = govt_inv_rnd_fed_nondef
	//gen bea_govt_rnd_snl        = govt_inv_rnd_snl			
	
	// back out capx investment
	gen bea_govt_capx = bea_govt_totinv - bea_govt_rnd
	gen bea_priv_capx = bea_priv_totinv - bea_priv_rnd
	
	// fixed assets
	gen bea_govt_capital = govt_fa_tot
	//gen bea_govt_capital_ipp = govt_fa_ipp_tot
	gen bea_govt_capital_rnd = govt_fa_ipp_rnd			
	gen bea_priv_capital = priv_fa_tot
	//gen bea_priv_capital_ipp = priv_fa_ipp_tot
	gen bea_priv_capital_rnd = priv_fa_ipp_rnd
	
	// keep only compustat or bea aggregated figures
	keep year comp_* bea_*	
	
	// only missing series compared to original file
	// "combined_compustat_and_bea_data_for_Wenxi.csv""
	// bea_govt_rnd_fed_def	bea_govt_rnd_fed_nondef	bea_govt_rnd_snl	

	// computed a few ratios of interest
	gen comp_pct_assets_port5      = 100 * comp_assets_5 / comp_assets_all // assets in portfolio 5 as share of total assets
	gen comp_pct_totinv_port5      = 100 * comp_totinv_5 / comp_totinv_all 
	gen comp_pct_rnd_to_totinv_all = 100 * comp_rnd_all / comp_totinv_all
	gen bea_priv_pct_capital_rnd   = 100 * bea_priv_capital_rnd / bea_priv_capital 
	gen bea_priv_pct_rnd_to_totinv = 100 * bea_priv_rnd / bea_priv_totinv
	gen bea_inv_priv_pct_rnd_to_capx   = 100 * bea_priv_rnd / bea_priv_capx
	gen bea_cap_priv_pct_rnd_to_capx   = 100 * bea_priv_capital_rnd / bea_priv_capital
	
	// only keep years we use in analysis
	keep if year>=1972 & year<=2016
	
	// save and export
	save "${dtapath}\data_for_tfpg_prediction_1of2", replace
	outsheet using "${TFPpredPath}\data_for_tfpg_prediction_1of2.csv", replace comma

	
	
/*********************************************************************************************/		
// additional data for tfpg prediction (not sure if it is used)

	// fraction of assets in high R&D firms
	use lpermno datemo at_F0 xrd_F0 using "${dtapath}\crsp_merged_with_monthly_compustat", clear
	merge 1:1 lpermno datemo using "${dtapath}\port_rebal_monthly", nogen // should be exact match with all obs	
	keep if ~missing(port)
	gen year = year(dofm(datemo))
	gen at_5   = at_F0   if port==5 // high R&D
	gen xrd_5  = xrd_F0  if port==5 // high R&D
	collapse (sum) at_all=at_F0 at_5 xrd_all=xrd_F0 xrd_5 ///
		(count) Nfirms_all=at_F0 Nfirms_5=at_5 ///
		, by(year datemo) 	
	gen frac_at_high_rnd = at_5 / at_all
	gen rnd_to_assets_all = xrd_all / at_all
	gen rnd_to_assets_5   = xrd_5 / at_5
	keep if month(dofm(datemo))==12	
	drop datemo
	save "${dtapath}\temp_frac_at_for_firms_high_rnd_intensity", replace
	
	
	// fraction of obs with missing values
	use "${dtapath}\compustat_annual_for_merge", clear
	gen missing_xrd = missing(xrd)
	collapse (sum) xrd capx missing_xrd (count) num_firms=lpermno, by(fyear)
	gen total_inv = (xrd + capx)
	gen pct_xrd_compustat = xrd / total_inv
	label var pct_xrd_compustat "pct_xrd_compustat=xrd/total_inv; sample is all firms in compustat"
	gen pct_missing_xrd = missing_xrd / num_firms
	keep if fyear>=1972 // when xrd becomes non-missing much more often
	drop missing_xrd pct_missing_xrd 	
	gen year = fyear // for merging
	tab year
	keep year pct_xrd_compustat
	save "${dtapath}\temp_pct_xrd_compustat", replace


	// first part of file is just the annual data used in the
	// annual productivity uncertainty (PU) measure
	// see 02a_export_data_for_Productivity_Uncertainty.do
	use "${dtapath}\data_for_ann_PU_measure", clear
	
	// national aggregates
	merge 1:1 year using "${dtapath}\bea_annual", nogen
	// fixed assets (or book capital or produced assets) from the BEA
	merge 1:1 year using "${dtapath}\bea_fixed_assets_tables_data_annual", nogen keep(master match) 
	/*descriptions:
		priv_fa_tot: "Produced Fixed Assets (Private), Billions of Dollars"	
		govt_fa_tot: "Produced Fixed Assets (Govt), Billions of Dollars"
	*/		
	// measures of financial conditions
	merge 1:1 year using "${dtapath}\chicago_fed_fci_ann", nogen keep(master match) keepusing(anfci nfci)
	merge 1:1 year using "${dtapath}\credit_spreads_ann", nogen keep(master match) keepusing(aaa10ym baa10ym)	
	
	// compute additionally needed vars
	gen kg_ktot = govt_fa_tot / (govt_fa_tot+priv_fa_tot)
	gen Cg_nom = consumption_govt_fed + consumption_govt_snl
	gen G  = Cg_nom + gross_govt_inv_nom
	gen G_y  = G / gdp_nom		
	gen ig_itot = gross_govt_inv_nom / (gross_priv_inv_nom+gross_govt_inv_nom)
	gen ig_y = gross_govt_inv_nom / gdp_nom
	gen ipptot_itot = gross_fpi_ipp_tot / (gross_priv_inv_nom+gross_govt_inv_nom)
	gen ipprnd_itot = gross_fpi_ipp_rnd / (gross_priv_inv_nom+gross_govt_inv_nom)
	
	// rename some vars for consistency with Wenxi's previously file
	rename gross_priv_inv_nom priv_inv
	rename gross_govt_inv_nom govt_inv
	//rename gross_govt_inv_nom_nondef govt_inv_nondef
	rename gross_fpi_ipp_rnd priv_inv_rnd
	rename gross_govt_inv_nom_rnd govt_inv_rnd
	//rename gross_govt_inv_nom_rnd_nondef govt_inv_rnd_nondef	

	// merge on vars computed separately above
	merge 1:1 year using "${dtapath}\temp_frac_at_for_firms_high_rnd_intensity", nogen 
	merge 1:1 year using "${dtapath}\temp_pct_xrd_compustat", nogen 
	
	// keep only vars needed for the file in the same order as old file
	gen fakevar=0
	order tfpyg year bondy1y bondy2y bondy3y bondy4y bondy5y bondy6y bondy7y inflationy ///
		ltgovbond pdratioy ivoly kg_ktot G_y ig_itot ig_y ipptot_itot ipprnd_itot anfci nfci aaa10ym baa10ym ///
		frac_at_high_rnd priv_inv_rnd priv_inv pct_xrd_compustat govt_inv govt_inv_rnd ///
		fakevar
	keep tfpyg year-fakevar
	drop fakevar

	// only keep years we use in analysis
	keep if year>=1972 & year<=2016
	
	// save and export
	save "${dtapath}\data_for_tfpg_prediction_2of2", replace
	outsheet using "${TFPpredPath}\data_for_tfpg_prediction_2of2.csv", replace comma

	
	

	
	
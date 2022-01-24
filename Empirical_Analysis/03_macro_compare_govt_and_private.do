/*create the tables and figures in the draft/slides

  datasets for this program often come from 01_import_and_clean_data.do
  
*/

	set more off

	/*change to project directory (exact file path differs by user)*/
	cd "C:\Users\tuk40836\Dropbox\Research\BCLR\1_SafeCapital"

	/*path where analysis specific intermediate or final datasets are saved*/
	global rawPath = "Empirical_Analysis\raw"
	global dtapath = "Empirical_Analysis\dta"

	// tables, figures and spreadsheets
	global outPath   = "Empirical_Analysis\output_for_paper"
	global outFigure = "Empirical_Analysis\figures"
	global outFigureForDraft = "Empirical_Analysis\output_for_paper\Figures"

	
	
/****************************************************************************/
// compare govt and private investment in terms of share, vol, and correlation	
	
	use "${dtapath}\bea_quarterly", clear	
	gen year = year(dofq(dateqtr))	
	keep if year<=2016 // don't truncate beginning of sample because not needed for these summ sats
		
	// method 1: estimate real private fixed investment (i.e., without inventories)
	//           by deflating nominal series
	gen inv_deflate = gross_priv_inv_incl_inventories / gross_private_investment_real
	gen gross_priv_inv_real = gross_priv_inv_nom / inv_deflate	
	//line gross_priv_inv_nom gross_priv_inv_real dateqtr, legend(cols(1))
		
	// method 2: use direct measure of percent change in real private fixed investment
	gen delta_ln_Ip_v2 = ln(1+(fixed_priv_investment_real_pchg/400))
	//br fixed_priv_investment_real_pchg delta_ln_Ip
		
	//br dateqtr gross_govt_investment_real_pchg
	tsset dateqtr
	gen gross_govt_inv_to_priv_inv = 100*gross_govt_inv_nom / gross_priv_inv_nom
	gen ln_Ig = ln(gross_govt_investment_real)
	//gen ln_Ip = ln(gross_private_investment_real) // includes inventories, don't use
	gen ln_Ip = ln(gross_priv_inv_real) // without inventories to match govt investment
	gen delta_ln_Ig = D1.ln_Ig
	gen delta_ln_Ip = D1.ln_Ip
	
	// correlation
	//corr delta_ln_Ig delta_ln_Ip
	//local myval3 = r(rho)
	//disp "corr(growth real Ig, growth real Ip) = `r(rho)'"
	corr gross_govt_investment_real_pchg fixed_priv_investment_real_pchg // more direct measure also negative
	local myval3 = r(rho)
	
	// relative size and vol
	collapse (mean) gross_govt_inv_to_priv_inv ///
		(sd) delta_ln_Ig delta_ln_Ip delta_ln_Ip_v2 ///
			gross_govt_investment_real_pchg fixed_priv_investment_real_pchg 
	gen vol_Ig_to_Ip = delta_ln_Ig / delta_ln_Ip
	gen vol_Ig_to_Ip_v2 = delta_ln_Ig / delta_ln_Ip_v2
	gen vol_Ig_to_Ip_v3 = gross_govt_investment_real_pchg / fixed_priv_investment_real_pchg
	label var gross_govt_inv_to_priv_inv "Avg Ig/Itot"
	label var vol_Ig_to_Ip "vol(d_lnIg)/vol(d_lnIp)"
	list gross_govt_inv_to_priv_inv vol_Ig_to_Ip, display
	local myval1 = gross_govt_inv_to_priv_inv[1]	
	local myval2 = vol_Ig_to_Ip[1]
	
	// print to log
	disp "Avg Ig/Itot = `myval1'%"
	disp "vol(d_lnIg)/vol(d_lnIp) = `myval2'%"	
	disp "corr(growth real Ig, growth real Ip) = `myval3'"
	
	
	
/*********************************************************************************************/		
/*govt investment and expenditure shares during recessions (quarterly)*/

	use "${dtapath}\bea_quarterly", clear
	merge 1:1 dateqtr using "${dtapath}\nber_recession_dummies_quarterly", nogen noreport keep(master match)
	merge 1:1 dateqtr using "${dtapath}\bea_quarterly_additional_saving_investment_series", nogen keep(master match) ///
		keepusing(gross_national_income national_income)	
	
	// truncate to our analysis sample end date
	keep if dateqtr<=yq(2016,4)
	tsset dateqtr
	
		/*re-label recession dummy to shorter name*/
		label var rec_dum "Recession Dummy"
		
		/*govt gross investment to GDP*/
		gen gross_govt_inv_to_gdp = 100*gross_govt_inv_nom / gdp_nom
		label var gross_govt_inv_to_gdp "Gross Govt Investment to GDP (%)"

		/*non-defense govt gross investment to GDP*/
		gen gross_nondef_govt_inv_to_gdp = 100*(gross_govt_inv_fed_nondef_nom+gross_govt_inv_snl_nom) / gdp_nom
		label var gross_nondef_govt_inv_to_gdp "Gross NonDef Govt Investment to GDP (%)"
		
		/*govt gross investment (which is only fixed) to total fixed investment*/
		gen gross_govt_inv_to_total_inv = 100*gross_govt_inv_nom / (gross_govt_inv_nom+gross_priv_inv_nom)
		label var gross_govt_inv_to_total_inv "Gross Govt Investment to Total Domestic (%)"
		// note: both are fixed investment series
		//gen test = abs( (gross_priv_inv_nom) - )
		//summ test	

		/*non-defense govt gross investment (which is only fixed) to total fixed investment excluding defense govt investment*/		
		gen gross_nondef_govt_inv_to_total = 100*(gross_govt_inv_fed_nondef_nom+gross_govt_inv_snl_nom) / (gross_govt_inv_fed_nondef_nom+gross_govt_inv_snl_nom+gross_priv_inv_nom)
		label var gross_nondef_govt_inv_to_total "Gross NonDef Govt Investment to Total Domestic (%)"		
		
		/*G/(C+Ip+G) where letters represent parts of GDP formula*/
		gen G_over_C_plus_I = 100*govt_con_and_inv_nom / (pce_nom + govt_con_and_inv_nom + gross_priv_inv_nom)
		label var G_over_C_plus_I "G/(C+Ip+G) (%)"

		/*Ig/G where letters represent parts of GDP formula*/
		gen Ig_over_G = 100*gross_govt_inv_nom / govt_con_and_inv_nom
		label var Ig_over_G "Ig/G(%)"		

		/*govt private investment to GDP*/
		gen gross_priv_inv_to_gdp = 100*gross_priv_inv_nom / gdp_nom
		label var gross_priv_inv_to_gdp "Gross Priv Investment to GDP (%)"		

		/*govt total investment to GDP*/
		gen gross_total_inv_nom = gross_govt_inv_nom+gross_priv_inv_nom
		gen gross_total_inv_to_gdp = 100*(gross_govt_inv_nom+gross_priv_inv_nom) / gdp_nom
		label var gross_total_inv_to_gdp "Gross Total Investment to GDP (%)"				

		
		// repeat for ratios of investment to gross national income
		gen gni = gross_national_income 
		gen ni = national_income
		foreach mydenom in "gni" "ni" {
		  foreach mynumer in "gross_priv_inv" "gross_govt_inv" "gross_total_inv" {		
			gen `mynumer'_to_`mydenom' = 100*`mynumer'_nom / `mydenom'
		  }
		}

		
		/*full quarterly series (back to 1947 for most) charts with recession shading*/
		foreach var in "gross_govt_inv_to_gdp" "gross_nondef_govt_inv_to_gdp" "gross_govt_inv_to_total_inv" "gross_nondef_govt_inv_to_total" "G_over_C_plus_I" "Ig_over_G" {
			qui summ `var'			
			local ymaxshade = r(max)
			local yminshade = r(min)
			//nbercycles gross_govt_inv_to_gdp, file(testnber.do) replace // generates lines of code below
			twoway function y=`ymaxshade',range(-45 -41) recast(area) color(gs12) base(`yminshade') || /// 
			function y=`ymaxshade',range(-26 -23) recast(area) color(gs12) base(`yminshade') || /// 
			function y=`ymaxshade',range(-10 -7) recast(area) color(gs12) base(`yminshade') || /// 
			function y=`ymaxshade',range(1 4) recast(area) color(gs12) base(`yminshade') || /// 
			function y=`ymaxshade',range(39 43) recast(area) color(gs12) base(`yminshade') || /// 
			function y=`ymaxshade',range(55 60) recast(area) color(gs12) base(`yminshade') || /// 
			function y=`ymaxshade',range(80 82) recast(area) color(gs12) base(`yminshade') || /// 
			function y=`ymaxshade',range(86 91) recast(area) color(gs12) base(`yminshade') || /// 
			function y=`ymaxshade',range(122 124) recast(area) color(gs12) base(`yminshade') || /// 
			function y=`ymaxshade',range(164 167) recast(area) color(gs12) base(`yminshade') || /// 
			function y=`ymaxshade',range(191 197) recast(area) color(gs12) base(`yminshade') || ///
			tsline `var', ytitle("Percent") legend(off) lcolor(black) xlabel(-60(40)200,format(%tq))
			graph export "${outFigure}/`var'_with_rec_bars_full_qtr.png", replace
			window manage close graph				
		}
			

		/*repeat pictures for subsample 1951q1 through 2013q4 to match the period for which we have annual government capital data (1951-2013)*/
		preserve
			keep if dateqtr>=yq(1951,1) 
			//keep if dateqtr<=yq(2013,4) // subset at the beginning instead			
			foreach var in "gross_govt_inv_to_gdp" "gross_nondef_govt_inv_to_gdp" "gross_govt_inv_to_total_inv" "gross_nondef_govt_inv_to_total" "G_over_C_plus_I" "Ig_over_G" {
				qui summ `var'			
				local ymaxshade = r(max)
				local yminshade = r(min)
				//nbercycles gross_govt_inv_to_gdp, file(testnber.do) replace // generates lines of code below
				twoway function y=`ymaxshade',range(-45 -41) recast(area) color(gs12) base(`yminshade') || /// 
				function y=`ymaxshade',range(-26 -23) recast(area) color(gs12) base(`yminshade') || /// 
				function y=`ymaxshade',range(-10 -7) recast(area) color(gs12) base(`yminshade') || /// 
				function y=`ymaxshade',range(1 4) recast(area) color(gs12) base(`yminshade') || /// 
				function y=`ymaxshade',range(39 43) recast(area) color(gs12) base(`yminshade') || /// 
				function y=`ymaxshade',range(55 60) recast(area) color(gs12) base(`yminshade') || /// 
				function y=`ymaxshade',range(80 82) recast(area) color(gs12) base(`yminshade') || /// 
				function y=`ymaxshade',range(86 91) recast(area) color(gs12) base(`yminshade') || /// 
				function y=`ymaxshade',range(122 124) recast(area) color(gs12) base(`yminshade') || /// 
				function y=`ymaxshade',range(164 167) recast(area) color(gs12) base(`yminshade') || /// 
				function y=`ymaxshade',range(191 197) recast(area) color(gs12) base(`yminshade') || ///
				tsline `var' , ytitle("Percent") legend(off) lcolor(black) xlabel(-40(40)220,format(%tq))
				graph export "${outFigure}/`var'_with_rec_bars_1951q1_through_2013q4_qtr.png", replace
				//window manage close graph				
			}
		restore
			
			
		/*compare chart showing Ig/I and G/(C+I) with recession shading*/
		//line gross_govt_inv_to_total_inv G_over_C_plus_I dateqtr
		qui summ gross_govt_inv_to_total_inv			
		local ymaxshade = r(max)
		local yminshade = r(min)	
		//nbercycles gross_govt_inv_to_gdp, file(testnber.do) replace // generates lines of code below
		twoway function y=`ymaxshade',range(-45 -41) recast(area) color(gs12) base(`yminshade') || /// 
		function y=`ymaxshade',range(-26 -23) recast(area) color(gs12) base(`yminshade') || /// 
		function y=`ymaxshade',range(-10 -7) recast(area) color(gs12) base(`yminshade') || /// 
		function y=`ymaxshade',range(1 4) recast(area) color(gs12) base(`yminshade') || /// 
		function y=`ymaxshade',range(39 43) recast(area) color(gs12) base(`yminshade') || /// 
		function y=`ymaxshade',range(55 60) recast(area) color(gs12) base(`yminshade') || /// 
		function y=`ymaxshade',range(80 82) recast(area) color(gs12) base(`yminshade') || /// 
		function y=`ymaxshade',range(86 91) recast(area) color(gs12) base(`yminshade') || /// 
		function y=`ymaxshade',range(122 124) recast(area) color(gs12) base(`yminshade') || /// 
		function y=`ymaxshade',range(164 167) recast(area) color(gs12) base(`yminshade') || /// 
		function y=`ymaxshade',range(191 197) recast(area) color(gs12) base(`yminshade') || ///
		tsline gross_govt_inv_to_total_inv G_over_C_plus_I , /// Ig_over_G
			   legend(off)  lcolor(black red) lpattern(solid dash) lwidth(0.2 0.5) ///
			   ytitle("Percent") xlabel(-60(40)200,format(%tq))
		graph export "${outFigure}/compare_gross_govt_inv_to_total_inv_G_over_C_plus_I_with_rec_bars_full_qtr.png", replace
		window manage close graph				
			

		/*compare chart showing Ig/I and IgNonDef/I with recession shading*/
		local ymaxshade = 35
		local yminshade = 5	
		//nbercycles gross_govt_inv_to_gdp, file(testnber.do) replace // generates lines of code below
		twoway function y=`ymaxshade',range(-45 -41) recast(area) color(gs12) base(`yminshade') || /// 
		function y=`ymaxshade',range(-26 -23) recast(area) color(gs12) base(`yminshade') || /// 
		function y=`ymaxshade',range(-10 -7) recast(area) color(gs12) base(`yminshade') || /// 
		function y=`ymaxshade',range(1 4) recast(area) color(gs12) base(`yminshade') || /// 
		function y=`ymaxshade',range(39 43) recast(area) color(gs12) base(`yminshade') || /// 
		function y=`ymaxshade',range(55 60) recast(area) color(gs12) base(`yminshade') || /// 
		function y=`ymaxshade',range(80 82) recast(area) color(gs12) base(`yminshade') || /// 
		function y=`ymaxshade',range(86 91) recast(area) color(gs12) base(`yminshade') || /// 
		function y=`ymaxshade',range(122 124) recast(area) color(gs12) base(`yminshade') || /// 
		function y=`ymaxshade',range(164 167) recast(area) color(gs12) base(`yminshade') || /// 
		function y=`ymaxshade',range(191 197) recast(area) color(gs12) base(`yminshade') || ///
		tsline gross_govt_inv_to_total_inv gross_nondef_govt_inv_to_total , /// Ig_over_G
			   legend(off)  lcolor(black red) lpattern(solid dash) lwidth(0.2 0.5) ///
			   ytitle("Percent") xlabel(-60(40)200,format(%tq))
		graph export "${outFigure}/compare_gross_govt_inv_ratios_nondefense_with_rec_bars_full_qtr.png", replace
		window manage close graph				
			

			
		
		/*charts showing percent change in ratios from start of recessions*/
		foreach data_var in "gross_govt_inv_to_gdp" "gross_govt_inv_to_total_inv" "gross_nondef_govt_inv_to_total" ///
			"G_over_C_plus_I" "Ig_over_G" ///
			"gross_priv_inv_to_gdp" ///
			"gross_total_inv_to_gdp" ///
			"gross_priv_inv_to_gni" "gross_govt_inv_to_gni" "gross_total_inv_to_gni" ///
			"gross_priv_inv_to_ni" "gross_govt_inv_to_ni" "gross_total_inv_to_ni" ///
		{
		
		  preserve // preserve dataset before creating output for given data_var		
		
		  //foreach regime_var in "rec_dum" "shift_rec_dum" "high_ivol_80" "high_ivol_90" "high_ivol_95" {
		  local regime_var = "rec_dum"
			
			/*make the data var actually called data_var to avoid names too long*/
			gen data_var = `data_var'
			
			/*loop through each regime var and calculate average percent change in data_var from start of each period*/		
			qui desc
			local T = r(N)
		
			/*label each unique stress period and calculate related stats*/
			gen per_start = (`regime_var'==1)*(l1.`regime_var'==0)
			gen per_num = per_start if _n==1
			gen data_var_start = per_start*l1.data_var
			forvalues t=2/`T' {
				set more off
				qui replace per_num = per_start[_n] + per_num[_n-1] if _n==`t' // periods must be consecutive 
				replace data_var_start = l1.data_var_start if data_var_start==0 // base value from period before start
			}
			bysort per_num: gen rel_t = _n
			by per_num: egen duration = sum(`regime_var') // length of the period
			
			/*grab the start year of the period to help label the per_num*/
			gen year = year(dofq(dateqtr))
			egen per_num_start_yr = min(year), by(per_num)
			gen per_num_detail = per_num*10^5 + per_num_start_yr
			// so per_num_detail is "X0YYYY" where X is per_num and YYYY is start yeat of that per_num
			
			/*generate percent change from the beginning of the stress period*/
			gen data_var_pchg = 100*((data_var/data_var_start) - 1)
			
			/*keep nonmissing data and reshape*/
			keep if ~missing(data_var_pchg)
			keep per_num_detail rel_t data_var_pchg
			reshape wide data_var_pchg, i(rel_t) j(per_num_detail)
				
			/*add a time-0 obs that is set to 0*/
			expand 2 in 1
			replace rel_t = 0 if _n==_N
			ds rel_t, not
			local retvars `r(varlist)'		
			local k_retvars : word count `retvars'	
			tokenize `retvars'		
			forvalues i = 1/`k_retvars' {
				replace ``i'' = 0 if rel_t==0
			}			
			sort rel_t
			
			/*save for use outside of loop*/
			save "${dtapath}\\`data_var'_pchg_during_`regime_var'", replace		
							
			/*chart all lines up to X months from event start*/
			keep if rel_t <=12
			tsset rel_t				
			tsline data_var*, xlabel(0/12) legend(off) ytitle("Percent") xtitle("Quarters from Recession Start") graphregion(color(white)) bgcolor(white)			
			graph export "${outFigure}\\`data_var'_pchg_during_`regime_var'_all_individual_lines.png", replace
			window manage close graph
			
			/*chart recessions with legend starting since 1969*/
			label var  data_var_pchg501969 "1969"
			label var  data_var_pchg601973 "1973"
			label var  data_var_pchg701980 "1980"
			label var  data_var_pchg801981 "1981"
			label var  data_var_pchg901990 "1990"
			label var data_var_pchg1002001 "2001"
			label var data_var_pchg1102007 "2007"
			tsline data_var_pchg501969 data_var_pchg601973 data_var_pchg701980 data_var_pchg801981 data_var_pchg901990 data_var_pchg1002001 data_var_pchg1102007, ///
				   lcolor(  yellow red    red    orange green    green  black) ///
				   lwidth(  vthick vthick vthick thick medthick vthick vthick) /// 
				   lpattern(solid  dash   solid  solid   solid    dash   solid) /// 
				   legend(cols(4)) xlabel(0/12) ytitle("Percent") xtitle("Quarters from Recession Start") graphregion(color(white)) bgcolor(white)			
			graph export "${outFigure}\\`data_var'_pchg_during_`regime_var'_selected_recessions.png", replace
			window manage close graph			
			
			
			/*chart the averages*/
			egen mean_data_var_pchg = rowmean(data_var*)
			egen count_data_var_pchg = rownonmiss(data_var*)				
			summ count_data_var_pchg
			local count_max = r(max)
			local count_min = r(min)
			//tsline mean_data_var_pchg, xlabel(0/12) legend(off) ytitle("Percent") xtitle("Qtrs from Regime Start") note("Average based on `count_max' obs at t=1 and `count_min' obs at t=12.")
			tsline mean_data_var_pchg, xlabel(0/12) legend(off) ytitle("Percent") xtitle("Quarters from Recession Start") graphregion(color(white)) bgcolor(white)			
			graph export "${outFigure}\\`data_var'_pchg_during_`regime_var'_all_mean_line.png", replace
			window manage close graph		
			
			/*repeat above charts dropping periods earlier than 1952*/
			forvalues x=1/200 {
			  forvalues year = 1947/1951 {
				capture confirm variable data_var_pchg`x'0`year'
				if !_rc {
				  drop data_var_pchg`x'0`year'
				}
			  }
			}
			tsline data_var*, xlabel(0/12) legend(off) ytitle("Percent") xtitle("Quarters from Recession Start") graphregion(color(white)) bgcolor(white)			
			graph export "${outFigure}\\`data_var'_pchg_during_`regime_var'_drop_pre_1952_individual_lines.png", replace
			window manage close graph
			drop mean_data_var_pchg count_data_var_pchg
			egen mean_data_var_pchg = rowmean(data_var*)
			egen count_data_var_pchg = rownonmiss(data_var*)				
			summ count_data_var_pchg
			local count_max = r(max)
			local count_min = r(min)
			//tsline mean_data_var_pchg, xlabel(0/12) legend(off) ytitle("Percent") xtitle("Qtrs from Regime Start") note("Average based on `count_max' obs at t=1 and `count_min' obs at t=4.")
			tsline mean_data_var_pchg, xlabel(0/12) legend(off) ytitle("Percent") xtitle("Quarters from Recession Start") graphregion(color(white)) bgcolor(white)			
			graph export "${outFigure}\\`data_var'_pchg_during_`regime_var'_drop_pre_1952_mean_line.png", replace
			window manage close graph						
			
		  restore // restore dataset for next data_var
		}				
	

	/*compare change in investment share to G/(C+I)*/
		
		/*bring in government investment share and rename/relabel*/
		use "${dtapath}\gross_govt_inv_to_total_inv_pchg_during_rec_dum", clear
		local i = 1
		foreach year in 1948 1953 1957 1960 1969 1973 1980 1981 1990 2001 2007 {
			rename data_var_pchg`i'0`year' govt_inv_share_`year'
			label var govt_inv_share_`year' "Ig/(Ig+Ip)"
			local i = `i' + 1
		}
		
		/*bring in government expenditure share and rename/relabel*/
		merge 1:1 rel_t using "${dtapath}\G_over_C_plus_I_pchg_during_rec_dum", nogen
		local i = 1
		foreach year in 1948 1953 1957 1960 1969 1973 1980 1981 1990 2001 2007 {
			rename data_var_pchg`i'0`year' govt_expnd_share_`year'
			label var govt_expnd_share_`year' "G/(C+Ip+G)"
			local i = `i' + 1
		}

		/*bring in government expenditure share and rename/relabel*/
		merge 1:1 rel_t using "${dtapath}\Ig_over_G_pchg_during_rec_dum", nogen
		local i = 1
		foreach year in 1948 1953 1957 1960 1969 1973 1980 1981 1990 2001 2007 {
			rename data_var_pchg`i'0`year' Ig_G_share_`year'
			label var Ig_G_share_`year' "Ig/G"
			local i = `i' + 1
		}		

		/*govt investment ratio with only nondefense investment*/
		merge 1:1 rel_t using "${dtapath}\gross_nondef_govt_inv_to_total_pchg_during_rec_dum", nogen
		local i = 1
		foreach year in 1948 1953 1957 1960 1969 1973 1980 1981 1990 2001 2007 {
			rename data_var_pchg`i'0`year' govt_ND_inv_share_`year'
			label var govt_ND_inv_share_`year' "IgND/(IgND+Ip)"
			local i = `i' + 1
		}
		
		
		/*compare average change across all recessions*/
		egen govt_inv_share_mean_post1952   = rowmean(govt_inv_share_195* govt_inv_share_196* govt_inv_share_197* govt_inv_share_198* govt_inv_share_199* govt_inv_share_20*)
		label var govt_inv_share_mean_post1952 "Ig/(Ig+Ip)"
		egen govt_expnd_share_mean_post1952 = rowmean(govt_expnd_share_195* govt_expnd_share_196* govt_expnd_share_197* govt_expnd_share_198* govt_expnd_share_199* govt_expnd_share_20*)
		label var govt_expnd_share_mean_post1952 "G/(C+Ip+G)"
		egen Ig_G_share_mean_post1952 = rowmean(Ig_G_share_195* Ig_G_share_196* Ig_G_share_197* Ig_G_share_198* Ig_G_share_199* Ig_G_share_20*)
		label var Ig_G_share_mean_post1952 "Ig/G"
		egen govt_ND_inv_share_mean_post1952 = rowmean(govt_ND_inv_share_195* govt_ND_inv_share_196* govt_ND_inv_share_197* govt_ND_inv_share_198* govt_ND_inv_share_199* govt_ND_inv_share_20*)
		label var govt_ND_inv_share_mean_post1952 "IgND/(IgND+Ip)"		
		
		//line govt_inv_share_mean_post1952 govt_expnd_share_mean_post1952 Ig_G_share_mean_post1952 rel_t if rel_t<=12, ///
		line govt_inv_share_mean_post1952 govt_expnd_share_mean_post1952 rel_t if rel_t<=12, ///
			 lcolor(black red blue) lpattern(solid dash solid) lwidth(0.2 0.2 0.5) ///
			 xlabel(0/12) ytitle("Percent") xtitle("Quarters from Recession Start") graphregion(color(white)) bgcolor(white)			
		graph export "${outFigure}\\compare_govt_inv_and_govt_expnd_shares_during_rec_dum_mean_post1952.png", replace
		// also save this figure for the draft
		graph export "${outFigureForDraft}\\compare_govt_inv_and_govt_expnd_shares_during_rec_dum_mean_post1952.png", replace
		window manage close graph									 
		
		/*compare change in ratios for each recession one at a time*/		 
		foreach year in 1948 1953 1957 1960 1969 1973 1980 1981 1990 2001 2007 {
			set more off
			//line govt_inv_share_`year' govt_expnd_share_`year' Ig_G_share_`year' rel_t if rel_t<=12, ///
			line govt_inv_share_`year' govt_expnd_share_`year' rel_t if rel_t<=12, ///
				 lcolor(black red blue) lpattern(solid dash solid) lwidth(0.2 0.2 0.5) ///
				 xlabel(0/12) ytitle("Percent") xtitle("Quarters from Recession Start") graphregion(color(white)) bgcolor(white)			
			graph export "${outFigure}\\compare_govt_inv_and_govt_expnd_shares_during_rec_dum_`year'.png", replace
			// save 2007 figure for the draft
			if `year'==2007 {
				graph export "${outFigureForDraft}\\compare_govt_inv_and_govt_expnd_shares_during_rec_dum_`year'.png", replace
			}
			window manage close graph									 
		}

		
		

	// compare investment to GDP ratios
	foreach mydenom in "gdp" "gni" "ni" {
		
		use "${dtapath}\gross_govt_inv_to_`mydenom'_pchg_during_rec_dum", clear
		local i = 1
		foreach year in 1948 1953 1957 1960 1969 1973 1980 1981 1990 2001 2007 {
			rename data_var_pchg`i'0`year' govt_inv_to_`mydenom'_`year'
			label var govt_inv_to_`mydenom'_`year' "Ig/`mydenom'"
			local i = `i' + 1
		}		
		
		merge 1:1 rel_t using "${dtapath}\gross_priv_inv_to_`mydenom'_pchg_during_rec_dum", nogen
		local i = 1
		foreach year in 1948 1953 1957 1960 1969 1973 1980 1981 1990 2001 2007 {
			rename data_var_pchg`i'0`year' priv_inv_to_`mydenom'_`year'
			label var priv_inv_to_`mydenom'_`year' "Ip/`mydenom'"
			local i = `i' + 1
		}		
		
		merge 1:1 rel_t using "${dtapath}\gross_total_inv_to_`mydenom'_pchg_during_rec_dum", nogen
		local i = 1
		foreach year in 1948 1953 1957 1960 1969 1973 1980 1981 1990 2001 2007 {
			rename data_var_pchg`i'0`year' total_inv_to_`mydenom'_`year'
			label var total_inv_to_`mydenom'_`year' "(Ip+Ig)/`mydenom'"
			local i = `i' + 1
		}		
				
		
		/*compare average change across all recessions*/
		foreach myvar in "priv_inv_to_`mydenom'" "govt_inv_to_`mydenom'" "total_inv_to_`mydenom'" {
			egen `myvar'_mean_post1952   = rowmean(`myvar'_195* `myvar'_196* `myvar'_197* `myvar'_198* `myvar'_199* `myvar'_20*)
		}
		label var priv_inv_to_`mydenom'_mean_post1952 "Ip/`mydenom'"
		label var govt_inv_to_`mydenom'_mean_post1952 "Ig/`mydenom'"
		label var total_inv_to_`mydenom'_mean_post1952 "(Ip+Ig)/`mydenom'"
		
		//line govt_inv_share_mean_post1952 govt_expnd_share_mean_post1952 Ig_G_share_mean_post1952 rel_t if rel_t<=12, ///
		line total_inv_to_`mydenom'_mean_post1952 priv_inv_to_`mydenom'_mean_post1952 govt_inv_to_`mydenom'_mean_post1952 rel_t if rel_t<=12, ///
			 lcolor(black red blue) lpattern(solid dash dash_dot) lwidth(0.5 0.2 0.2) ///
			 legend(cols(3)) ///
			 xlabel(0/12) ytitle("Percent") xtitle("Quarters from Recession Start") graphregion(color(white)) bgcolor(white)			
		graph export "${outFigure}\\compare_invest_to_`mydenom'_ratios_during_rec_dum_mean_post1952.png", replace
		
	}
		
		
		
		
		
/****************************************************************************/
// tables showing conditional investment growth/differences in stress 
// periods across private sector and government sector.
// it's like the firm-level portfolio process but at the sector level

	// check sums of periods by regime
	use datemo rec_dum using "${dtapath}\nber_recession_dummies", clear
	merge m:1 datemo using "${dtapath}\integrated_volatility_monthly", nogen noreport keep(master match) ///
		keepusing(high_ivol_80 high_ivol_90 high_ivol_95)	
	merge m:1 datemo using "${dtapath}\epu_hist_index_monthly", nogen keep(master match) ///
		keepusing( high_epu_hist_full_80 high_epu_hist_full_90 high_epu_hist_full_95 )
	
	// merge together aggregate data and stress period indicators
	use datemo rec_dum using "${dtapath}\nber_recession_dummies", clear
	merge m:1 datemo using "${dtapath}\integrated_volatility_monthly", nogen noreport keep(master match) ///
		keepusing(high_ivol_80 high_ivol_90 high_ivol_95)	
	merge m:1 datemo using "${dtapath}\epu_hist_index_monthly", nogen keep(master match) ///
		keepusing( high_epu_hist_full_80 high_epu_hist_full_90 high_epu_hist_full_95 )
	save "${dtapath}\temp_indicators", replace
		
	// check sums of periods
	use "${dtapath}\temp_indicators", clear
	// truncate sample for analysis period consistent with other tables
	gen year = year(dofm(datemo))
	keep if year>=1972 & year<=2016	
	collapse (sum) *
	drop datemo year
	// br
	// manually record these figures in the Excel workbook for reference
	
				
	// merge on national aggregates
	use "${dtapath}\temp_indicators", clear
	gen year = year(dofm(datemo))
	merge m:1 year using "${dtapath}\bea_annual", nogen keep(master match) ///
		keepusing( ///
			gross_fpi_ipp_tot gross_fpi_ipp_rnd ///
			gross_priv_inv_nom gross_govt_inv_nom gross_govt_inv_nom_rnd ///
		)	
	merge m:1 year using "${dtapath}\bea_fixed_assets_tables_data_annual", nogen keep(master match) 	
	merge 1:1 datemo using "${dtapath}\national_employment_monthly", nogen keep(master match) 

	// back out capx investment
	gen govt_capx = gross_govt_inv_nom - gross_govt_inv_nom_rnd
	gen priv_capx = gross_priv_inv_nom - gross_fpi_ipp_rnd		
	
	// non-defense government R&D investment
	//gen govt_rnd_nondef = govt_inv_rnd_fed_nondef+govt_inv_rnd_snl
	
	// R&D intensities
	gen rnd_to_inv_1 = gross_govt_inv_nom_rnd / gross_govt_inv_nom
	gen rnd_to_inv_2 = gross_fpi_ipp_rnd 	  / gross_priv_inv_nom
	gen rnd_to_k_1 = gross_govt_inv_nom_rnd / govt_fa_tot
	gen rnd_to_k_2 = gross_fpi_ipp_rnd 	  / priv_fa_tot
	//gen rnd_nondef_to_k_1 = govt_rnd_nondef / govt_fa_tot
	
	// levels of capital
	gen ktot_1 = govt_fa_tot
	gen ktot_2 = priv_fa_tot
	gen krnd_1 = govt_fa_ipp_rnd
	gen krnd_2 = priv_fa_ipp_rnd
	
	// aggregate shares capital
	gen share_ktot_1 = govt_fa_tot  / (priv_fa_tot + govt_fa_tot)		
	gen share_ktot_2 = priv_fa_tot  / (priv_fa_tot + govt_fa_tot)		
	gen rnd_share_ktot_1 = govt_fa_ipp_rnd  / (priv_fa_tot + govt_fa_tot)		
	gen rnd_share_ktot_2 = priv_fa_ipp_rnd  / (priv_fa_tot + govt_fa_tot)				
	gen agg_rnd_share_ktot_1 = (govt_fa_ipp_rnd+priv_fa_ipp_rnd) / (priv_fa_tot + govt_fa_tot)
	gen agg_rnd_share_ktot_2 = (govt_fa_ipp_rnd+priv_fa_ipp_rnd) / (priv_fa_tot + govt_fa_tot)
	gen rnd_share_ktang_1 = govt_fa_ipp_rnd  / (priv_fa_tot + govt_fa_tot - priv_fa_ipp_tot - govt_fa_ipp_tot)		
	gen rnd_share_ktang_2 = priv_fa_ipp_rnd  / (priv_fa_tot + govt_fa_tot - priv_fa_ipp_tot - govt_fa_ipp_tot)		
	gen agg_rnd_share_ktang_1 = (govt_fa_ipp_rnd+priv_fa_ipp_rnd) / (priv_fa_tot + govt_fa_tot - priv_fa_ipp_tot - govt_fa_ipp_tot)		
	gen agg_rnd_share_ktang_2 = (govt_fa_ipp_rnd+priv_fa_ipp_rnd) / (priv_fa_tot + govt_fa_tot - priv_fa_ipp_tot - govt_fa_ipp_tot)	

	
	// deflate investment variables. use same index that we
	// use for the micro data to be consistent
	merge m:1 datemo using "${dtapath}\inflation_index_monthly", nogen keep(master match)
	gen real_inv_tot_1 = gross_govt_inv_nom 		/ inflation_index
	gen real_inv_tot_2 = gross_priv_inv_nom 		/ inflation_index		
	gen real_inv_rnd_1 = gross_govt_inv_nom_rnd 	/ inflation_index
	//gen real_inv_rnd_2 = gross_fpi_ipp_tot 		/ inflation_index
	gen real_inv_rnd_2 = gross_fpi_ipp_rnd 		/ inflation_index
	gen real_inv_cap_1 = govt_capx 				/ inflation_index
	gen real_inv_cap_2 = priv_capx 				/ inflation_index	
	//gen real_inv_rnd_nondef_1 = govt_rnd_nondef	/ inflation_index
	gen real_ktot_1 = ktot_1 / inflation_index
	gen real_ktot_2 = ktot_2 / inflation_index		
	gen real_krnd_1 = krnd_1 / inflation_index
	gen real_krnd_2 = krnd_2 / inflation_index		
	
	// levels of employment (people). call "real" just so loop in next step works
	gen real_employees_1 = employees_govt_all_sa
	gen real_employees_2 = employees_priv_all_sa
	tsset datemo	
	
	// shares of labor by sector
	gen share_empl_1 = employees_govt_all_sa / employees_total_sa
	gen share_empl_2 = employees_priv_all_sa / employees_total_sa
	//gen test = share_empl_govt + share_empl_priv
	//summ test, detail						
	
	// normal indicator
	gen uncond = 1
	
	// truncate sample for analysis period consistent with other tables
	keep if year>=1972 & year<=2016
	
	save "${dtapath}\temp_data", replace		
		
		
	// create time series figures
	if 1==0 {
	
		foreach myvar in "agg_rnd_share_ktot_1" "rnd_share_ktot_2" "agg_rnd_share_ktang_1" "rnd_share_ktang_2" {
			
			local mytitle = "`myvar'"
			if "`myvar'"=="agg_rnd_share_ktot_1" {
				local mytitle="R&D Capital Share"
			}				
			if "`myvar'"=="rnd_share_ktot_2" {
				local mytitle="Private R&D Capital Share"
			}
			if "`myvar'"=="agg_rnd_share_ktang_1" {
				local mytitle="R&D Capital Share of Tangible"
			}				
			if "`myvar'"=="rnd_share_ktang_2" {
				local mytitle="Private R&D Capital Share of Tangible"
			}				
			
			use "${dtapath}\temp_data", clear
			gen var_to_plot = `myvar'
			keep datemo var_to_plot
			
			tsline var_to_plot ///
				, graphregion(color(white)) ///
				legend(off) lcolor(blue) ///
				lwidth(0.7 0.5 0.5 0.5 0.7) ///
				title("`mytitle'") ///
				// ytitle("Fraction") // xline(1972, lpattern(dash) lcolor(black)) 
			//graph export "Data_BCLR_oparated_by_Sam\sams_notes\2018-09 investment growth rate tables\tsline_macro_`myvar'.png", replace
			graph export "${outFigure}\\tsline_macro_`myvar'.png", replace
			window manage close graph		
			
		}
		
	}		
	
		
		
	// compute growth rates of investment values or differences in ratios
	foreach fval in 12 24 36 48 60 { 
	  foreach regime in "uncond" "rec_dum" ///
		"high_ivol_95" "high_ivol_90" "high_ivol_80" ///
		"high_epu_hist_full_80" "high_epu_hist_full_90" "high_epu_hist_full_95" ///
	  {

		//local fval=60		  
		//local regime="uncond"	  

		use "${dtapath}\temp_data", clear
		tsset datemo
	
		set more off
	
		foreach mygrovar in "inv_tot_1" "inv_tot_2" "inv_cap_1" "inv_cap_2" "inv_rnd_1" "inv_rnd_2" ///
			"employees_1" "employees_2" /// "inv_rnd_nondef_1" 
			"ktot_1" "ktot_2" "krnd_1" "krnd_2" ///
		{			
			gen fval_var = F`fval'.real_`mygrovar'			
			gen endval   = fval_var if `regime'==1
			gen startval = real_`mygrovar' if `regime'==1
			gen gro_`mygrovar' = 100*(endval/startval-1)
			drop fval_var endval startval
							
		}	
		
		foreach mydiffvar in "rnd_to_inv_1" "rnd_to_inv_2" "rnd_to_k_1" "rnd_to_k_2" ///
			"share_empl_1" "share_empl_2" /// "rnd_nondef_to_k_1" 
			"share_ktot_1" "share_ktot_2" ///
			"rnd_share_ktot_1" "rnd_share_ktot_2" ///
			"agg_rnd_share_ktot_1" "agg_rnd_share_ktot_2" ///
			"rnd_share_ktang_1" "rnd_share_ktang_2" ///
			"agg_rnd_share_ktang_1" "agg_rnd_share_ktang_2" ///				
		{
			// note: use F24 and F12 because annual values already lagged by
			//       one year from creating portfolio assignments
			gen fval_var = F`fval'.`mydiffvar'
			gen endval   = fval_var if `regime'==1
			gen startval = `mydiffvar' if `regime'==1
			gen diff_`mydiffvar' = 100*(endval-startval)
			drop fval_var endval startval
		}				

		// new variable: difference in R&D over average assets			

			gen fval_inv_rnd_1 = F`fval'.gross_govt_inv_nom_rnd
			gen fval_inv_rnd_2 = F`fval'.gross_fpi_ipp_rnd
			gen end_inv_rnd_1 = fval_inv_rnd_1 if `regime'==1
			gen end_inv_rnd_2 = fval_inv_rnd_2 if `regime'==1
			gen start_inv_rnd_1 = gross_govt_inv_nom_rnd if `regime'==1
			gen start_inv_rnd_2 = gross_fpi_ipp_rnd if `regime'==1
			
			gen fval_k_1 = F`fval'.govt_fa_tot
			gen fval_k_2 = F`fval'.priv_fa_tot
			gen end_k_1 = fval_k_1 if `regime'==1
			gen end_k_2 = fval_k_2 if `regime'==1			
			gen start_k_1 = govt_fa_tot if `regime'==1
			gen start_k_2 = priv_fa_tot if `regime'==1				
			
			gen diff_rnd_to_avgk_1 = 100*(end_inv_rnd_1-start_inv_rnd_1)/((start_k_1+end_k_1)/2)
			gen diff_rnd_to_avgk_2 = 100*(end_inv_rnd_2-start_inv_rnd_2)/((start_k_2+end_k_2)/2)
			
			drop fval* end_* start_*
			
		// make long for easier collapse
		keep datemo `regime' gro_* diff_*
		reshape long ///
			gro_inv_tot_ gro_inv_cap_ gro_inv_rnd_ gro_employees_ /// gro_inv_rnd_nondef_ 
			gro_ktot_ gro_krnd_ ///
			diff_rnd_to_inv_ diff_rnd_to_k_ diff_share_empl_ /// diff_rnd_nondef_to_k_ 
			diff_share_ktot_ diff_rnd_share_ktot_ diff_agg_rnd_share_ktot_ ///
			diff_rnd_share_ktang_ diff_agg_rnd_share_ktang_ ///
			diff_rnd_to_avgk_ ///
			, i(datemo `regime') j(groupnum) 
		
		gen port_name = ""
		replace port_name = "Govt" if groupnum==1
		replace port_name = "Private" if groupnum==2
		
		collapse (mean) gro_* diff_*, by(port_name)		

		gen regime = "`regime'"
		order regime
		
		// combine regime stats
		if "`regime'"=="uncond" {
			save "${dtapath}\temp_macro_avgs_table", replace
		}
		else {
			append using "${dtapath}\temp_macro_avgs_table"
			save "${dtapath}\temp_macro_avgs_table", replace						
		}				
				
		use "${dtapath}\temp_macro_avgs_table", clear
		//export excel using "Data_BCLR_oparated_by_Sam\sams_notes\2018-09 investment growth rate tables\investment_data_v3.xlsx", ///
			//firstrow(var) sheet("macro_avgs_F`fval'_raw") sheetreplace					
		export excel using "${outPath}\tables_for_paper.xlsx", ///
			sheet("macro_avgs_F`fval'_raw") sheetreplace firstrow(variables)
		
	  }
	}		
		
		
		
	// govt bond returns
	use "${dtapath}\ibbotson_govt_bond_ret_monthly_long", clear
	gen port_ret_vw = port_ret if inlist(port_name,"ltgovbd","itgovbd","tbill")		

	// recession, ivol, and epu indicators
	merge m:1 datemo using "${dtapath}\nber_recession_dummies", nogen noreport keep(master match) keepusing(rec_dum)
	merge m:1 datemo using "${dtapath}\integrated_volatility_monthly", nogen noreport keep(master match) ///
		keepusing(high_ivol_80 high_ivol_90 high_ivol_95)	
	merge m:1 datemo using "${dtapath}\epu_hist_index_monthly", nogen keep(master match) ///
		keepusing( high_epu_hist_full_80 high_epu_hist_full_90 high_epu_hist_full_95 )
				
	// analysis window
	keep if datemo>=ym(1972, 1)
	//keep if datemo<=ym(2013,12)
	keep if datemo<=ym(2016,12)
	gen full=1

	/*deflate returns from nominal to real using a cpi deflator*/
	local deflator = "ibbotson" // either choose "cpi" or "ibbotson"
	if "`deflator'"=="ibbotson" {
		merge m:1 datemo using "${dtapath}\inflation_monthly", nogen noreport keep(match)					
		gen port_ret_vw_real = 100*((1+(port_ret_vw/100))/inflation_deflator - 1)
		//gen port_ret_ew_real = 100*((1+(port_ret_ew/100))/inflation_deflator - 1)		
		//gen port_ret_un_vw_real = 100*((1+(port_ret_un_vw/100))/inflation_deflator - 1)
		//gen port_ret_un_ew_real = 100*((1+(port_ret_un_ew/100))/inflation_deflator - 1)			
	}
	else {
		error "choose either cpi or inflation to deflate returns"
	}			
				  
	// save temporary data			
	save "${dtapath}\temp_govt_bond_ret_data", replace
			
	// averages of returns
	foreach myport in "ltgovbd" "itgovbd" "tbill" {		
		foreach myregime in "full" "rec_dum" "high_ivol_80" "high_ivol_90" "high_ivol_95" ///
			"high_epu_hist_full_80" "high_epu_hist_full_90" "high_epu_hist_full_95" ///
		{			
			
			// by portfolio
			use "${dtapath}\temp_govt_bond_ret_data", clear
			keep if `myregime'==1
			keep if port_name=="`myport'"
			collapse (mean) port_ret*, by(port_name) // nomiss_diff_* nomiss_gro_* 

			/*annualize returns*/
			foreach retvar in "port_ret_vw_real" /// "port_ret_un_vw_real"  "port_ret_ew_real" "port_ret_un_ew_real" 		
			{
				replace `retvar' = 100*( (1+`retvar'/100)^(12) - 1 )
			}		
			
			gen regime = "`myregime'"
			order regime port_name
			
			// combine regime stats
			if "`myregime'"=="full" {
				save "${dtapath}\temp_avgs_by_port_table", replace
			}
			else {
				append using "${dtapath}\temp_avgs_by_port_table"
				save "${dtapath}\temp_avgs_by_port_table", replace						
			}					

		}		
					
		use "${dtapath}\temp_avgs_by_port_table", clear
		//export excel using "Data_BCLR_oparated_by_Sam\sams_notes\2018-09 investment growth rate tables\investment_data_v3.xlsx", ///
			//firstrow(var) sheet("avgs_`myport'") sheetreplace			
		export excel using "${outPath}\tables_for_paper.xlsx", ///
			sheet("avgs_`myport'") sheetreplace firstrow(variables)			
	}		

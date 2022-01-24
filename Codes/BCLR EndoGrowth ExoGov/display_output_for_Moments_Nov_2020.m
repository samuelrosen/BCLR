function display_output_for_Moments_Nov_2020;
% a program to grab the parameter values and moment values from
% a set of calibrations and put into a single table for easy comparison

%cal_no_list = [81:88, 90:99];
%cal_no_list = [81:88, 90:99, 130:139];
%cal_no_list = [81:88, 90:99, 101, 130:149];
%cal_no_list = [81:84];
%cal_no_list = [81:84,78:79];
%cal_no_list = [122, 123, 150, 151];
cal_no_list = [77];
if 1==0 
% run the calibrations if needed
    cal_no_list = [101, 81:88];
    for nnn = 1:length(cal_no_list)
        cal_no=cal_no_list(nnn);
        MAIN(cal_no);
    end    
end

firstloop=1;
for nnn = 1:length(cal_no_list)
    
% load data

    %cal_no=81;
    cal_no=cal_no_list(nnn);
    fname=strcat('Monopoly_Power_Approx_',num2str(cal_no)); mod_name=strcat(fname,'.mod'); %#ok<*NODEF>
    load(strcat('Results/',fname,'/',fname,'.mat'));
    
% calibration table
    
    param_list={'ORDER';
               'alphap';
               'alphac';
               'xi';
               'cxi';
               'gamma';
               'psi';           
               'rho';           
               'rhovol';           
               'beta';           
               'sigma';           
               'sigmax';           
               'tau';           
               'w';           
               'con_shocka';           
               'sigmas';           
               'phi_growth';           
               'phi_growth_f';           
               'voltense';           
               'arc';           
               'theta_sla';           
               'omega';           
               'theta_P';           
               'theta_G';           
               'phi_o_s';           
               'xi_p';           
               'eta';           
               'chi';           
               'rhoar';           
               'biga';           
               'bigv';           
               'bnca';           
               'bncv';      
               'rho_ig';  
               'rho_nc';  
               ...'IcYratio'; 
               'simul_fast';  
               'bundle_labor';  
               'exo_gov_switch';  
               'stoch_vol_switch';                  
               'cal_no';
               };       
        
    
    global gamma psi beta sigma
    param_vals = [ ...
       ORDER; ...       = 3; 
       alphap; ... = 0.3;                    % Production function exponent
       alphac; ... = 0.3;       % Production function exponent
        xi; ...    = 4;                     % Adjustment cost exponent 3.5
       cxi; ... = 4;           % Adjustment cost exponent 3.5
        gamma; ...    = 10;                      % Risk aversion
        psi; ... =2;
        rho; ... =0.98;
        rhovol; ... = 0.74;
        beta; ...   = 0.98^(1/frEq);          % Subjective discount factor
        sigma; ...  = 0.0315/sqrt(frEq);        % Std of short-run shock
        sigmax; ... = 0.2*sigma;               % Std of long-run shock     
        tau; ... = 5;
        w; ... = 0.8;      
       con_shocka; ... =-3.5;
       sigmas; ...  = 0.1538;
       phi_growth; ... = 0;
       phi_growth_f; ... = 0;
      voltense; ... = 3; % SAM: new line
      arc; ... = -0.4322;
      theta_sla; ... = 0.1;
      omega; ... = 1.5; 
      theta_P; ... = 0;
      theta_G; ... = 0;
      phi_o_s; ... = 0;
      xi_p; ... = 0.49;
        eta; ... = 0.76;
        chi; ... = 0.128;
        rhoar; ... = 0.99;
        biga; ... = -0.1;
        bigv; ... = 0.1;
        bnca; ... = -0.1;
        bncv; ... = 0.1;
        rho_ig; ... = 0.9;
        rho_nc; ... = 0.9;
        ...IcYratio; ...
        simul_fast; ... = 1;     
        bundle_labor; ... = 1;
        exo_gov_switch; ... = 0;
        stoch_vol_switch; ... = 1;   % STOCHASTIC VOLATILITY
        cal_no]; % new row
    

% moments tables

    % row identifiers for output(1:23,1)
    rowLabels={'$\sigma(\Delta y)$ (\%)';
               '$\sigma(\Delta c)/\sigma(\Delta y)$';
               '$\sigma(\Delta i_{tot})/\sigma(\Delta y)$';
               '$\sigma(\Delta s)$';
               '$E\left[(I_p+S)/Y\right] (\%)$';
               '$\sigma((I_p+S)/Y)(\%)$ ';
               '$\rho(\Delta c,\Delta \ln(I_p+S))$';           
               '$E\left[I_g/Y\right] (\%)$';
               '$\sigma(I_g/Y)$ (\%)';
               '$E\left[\frac{K_g}{K_p+K_g}\right] (\%)$';
               '$E\left[Q_g\right]$';
               '$E\left[r_{p,ex}^{LEV}\right]$ (\%)';
               '$\sigma(r_{p,ex}^{LEV})$ (\%)';
               '$E\left[r_{g,ex}\right]$ (\%)';
               '$\sigma(r_{g,ex})$ (\%)';    
               '$E\left[r_{R\&D,ex}^{LEV}\right]$ (\%)';  % sam changed from '$E\left[{HML-R\&D}^{LEV}\right]$ (\%)';  to avoid confusion 
               '$E\left[r^{f}\right]$ (\%)';
               '$\sigma(r^{f})$ (\%)';
               '$b^{10}_g$';
                '$\beta_{\Delta a_{10}|K^{H}_{R\&D}/K_{H}}-K_L/K_{tot}$';
                 '$\beta_{\Delta a_{10}|K^{H}_{R\&D}/K_{H}}$';
               '$\beta_{\Delta a_{10}|I_{R\&D}/I_{Fixed}}$';
                 '$\beta_{\Delta a_{10}|I_{g}/I_{tot}}$';
                 '$E\left[\Delta y\right]$ (\%)';                              
           '$\sigma(\Delta L_{g} )$ (\%)'; ...                 
           '$\sigma(\Delta L_{p} )$ (\%)'; ...     
           '$\sigma(\Delta w_{g} )$ (\%)'; ...  
           '$\sigma(\Delta w_{p} )$ (\%)'; ...   
           '$\sigma(\Delta w_{g}L_{g} )$ (\%)'; ...
           '$\sigma(\Delta w_{p}L_{p} )$ (\%)'; ...                           
           '$\rho(\Delta L_{p},\Delta L_{g} )$';   
           '$E\left[L_H/ L_L\right] (\%)$';    
           '$\sigma(L_H / L_L )$ (\%)'; ...              
           '$E\left[L_H/ (L_H+L_L) \right] (\%)$';
           '$\sigma(L_H / (L_H+L_L) )$ (\%)'; ...     
               };          
           
    % annualized time series moments in percent corresponding to above labels
    %ts_moments = output(1:23,1);
    ts_moments = output(1:35,1);
    
    % individual moments to check ad hoc
    ratio_C_Ctilde = exp(dyn_ss(dyn_i_ca)) ./ exp(dyn_ss(dyn_i_tca));
    %ratio_C_Ctilde_v2 = exp(dyn_ss(dyn_i_ca) - dyn_ss(dyn_i_tca))
    exp(dyn_ss(dyn_i_np));
    exp(dyn_ss(dyn_i_ntotal));
    exp(dyn_ss(dyn_i_np)) ./ exp(dyn_ss(dyn_i_ntotal));
    100*dyn_ss(dyn_i_npnt); % '$E\left[L_H/L^{TOT}] (\%)$';
    100*dyn_ss(dyn_i_ncnt); % '$E\left[L_C/L^{TOT}] (\%)$';   
    100*exp(dyn_ss(dyn_i_ipa,:))/exp(dyn_ss(dyn_i_gdp,:)); % E[Ip/Y]
    100*exp(dyn_ss(dyn_i_s,:))  /exp(dyn_ss(dyn_i_gdp,:)); % E[Irnd/Y]
    100*exp(dyn_ss(dyn_i_s,:))  / (exp(dyn_ss(dyn_i_ipa,:))+exp(dyn_ss(dyn_i_s,:))); % E[Irnd/(Ip+Irnd)]
    100*(exp(dyn_ss(dyn_i_ipa,:))+exp(dyn_ss(dyn_i_s,:))) / exp(dyn_ss(dyn_i_gdp,:)); % E[(Ip+Irnd)/Y], should be very close to '$E\left[(I_p+S)/Y\right] (\%)$' in ts_moments 
    

    % moments from dynare output in same order that are also annualized and
    % converted to percent
    dynss_moments = [ ...
        100*2*sqrt(dyn_vcov(dyn_i_dy,dyn_i_dy)); ...
        sqrt(dyn_vcov(dyn_i_dc,dyn_i_dc)) / sqrt(dyn_vcov(dyn_i_dy,dyn_i_dy)); ...
        NaN; ...
        100*2*sqrt(dyn_vcov(dyn_i_ds,dyn_i_ds)); ...
        NaN; ... % '$E\left[(I_p+S)/Y\right] (\%)$';
        NaN; ... % '$\sigma((I_p+S)/Y)(\%)$ ';               
        NaN; ... % '$\rho(\Delta c,\Delta \ln(I_p+S))$';   
        100*dyn_ss(dyn_i_Iyg); ... % '$E\left[I_g/Y\right] (\%)$';
        100*sqrt(dyn_vcov(dyn_i_Iyg,dyn_i_Iyg)); ... % '$\sigma(I_g/Y)$ (\%)';
        NaN; ... % '$E\left[\frac{K_g}{K_p+K_g}\right] (\%)$';
        100*dyn_ss(dyn_i_qc); ... '$E\left[Q_g\right]$';
        NaN; ... % '$E\left[r_{p,ex}^{LEV}\right]$ (\%)';
        NaN; ... % '$\sigma(r_{p,ex}^{LEV})$ (\%)';
        NaN; ... % '$E\left[r_{g,ex}\right]$ (\%)';
        NaN; ... % '$\sigma(r_{g,ex})$ (\%)';    
        100*4*dyn_ss(dyn_i_exrrnd); ... % '$E\left[{HML-R\&D}^{LEV}\right]$ (\%)';   
        100*4*dyn_ss(dyn_i_rf); ... % '$E\left[r^{f}\right]$ (\%)';
        100*2*sqrt(dyn_vcov(dyn_i_rf,dyn_i_rf)); ... '$E\left[Q_g\right]$';; ... '$\sigma(r^{f})$ (\%)';
        NaN; ... % '$b^{10}_g$';
        NaN; ... % '$\beta_{\Delta a_{10}|K^{H}_{R\&D}/K_{H}}-K_L/K_{tot}$';
        NaN; ... % '$\beta_{\Delta a_{10}|K^{H}_{R\&D}/K_{H}}$';
        NaN; ... % '$\beta_{\Delta a_{10}|I_{R\&D}/I_{Fixed}}$';
        NaN; ... % '$\beta_{\Delta a_{10}|I_{g}/I_{tot}}$';  
        100*4*dyn_ss(dyn_i_dy); ...
        NaN; ... % labor moment
        NaN; ... % labor moment
        NaN; ... % labor moment
        NaN; ... % labor moment
        NaN; ... % labor moment
        NaN; ... % labor moment
        NaN; ... % labor moment
        NaN; ... % labor moment
        NaN; ... % labor moment
        NaN; ... % labor moment
        NaN; ... % labor moment
        cal_no]; % new row
    
    % check deterministic steady state value
    %100*dyn_steady_states(dyn_i_Iyg)

        
    
    
% save output    
    
    eval(strcat('ts_vs_dynss_',num2str(cal_no),' = [ts_moments, dynss_moments(1:length(ts_moments),1)];'));    
    if firstloop==1
        param_vals_combined = param_vals;
        ts_moments_combined = ts_moments;
        dynss_moments_combined = dynss_moments;
        firstloop=0;
    else
        param_vals_combined = [param_vals_combined, param_vals];
        ts_moments_combined = [ts_moments_combined, ts_moments];
        dynss_moments_combined = [dynss_moments_combined, dynss_moments];        
    end
    
end


clearvars -except dynss_moments_combined param_vals_combined ts_moments_combined rowLabels
dynss_moments_combined
param_vals_combined
ts_moments_combined
keyboard;

end
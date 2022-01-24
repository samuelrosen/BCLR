%% Housekeeping
tic
%% Say which calibration is solved
%disp(['Calibration: ' num2str(cal_no)]);
clear all;
close all;
% Write mod file
disp('Write the mod...');
Two_Sector_Model_Consumption_Adjustment_Costs_Wenxi;
% Execute dynare++
disp('Running...')

!dynare++ --order 3 --sim 3 --per 10 --no-irfs --ss-tol 1e-10 TSM_Consumption_Ratio.mod

disp('Done!')

fname='TSM_Consumption_Ratio.mat';
name='test3';
labor_switch=0;
irf_sim=500;
stoch_vol_switch=1;
gold_switch=0;
shock_direction_switch=1;
conditional_moments_switch=1;
%eval(strcat(['!dynare++_4.',dynare_ver,' --sim 3 --per 10 --no-irfs --ss-tol 1e-10 ',mod_name]))


% To speed up
% load(strcat(fname,'.mat'));
% JESUS=[dyn_steady_states dyn_ss];
%     disp('RF_Steady RF_SS')
%     disp(num2str(JESUS(dyn_i_rf,:)*frEq*100));
%     disp('EP_Steady EP_SS (unlevered, %)')
%     disp(num2str(JESUS(dyn_i_exr,:)*frEq*100));
%     if gold_switch==1
%     disp(['J/I: ' num2str(dyn_ss(dyn_i_JA)/exp(dyn_ss(dyn_i_ia)))]);
%     end
% toc

% Plot IRF
disp('IRFs...');
irfmax
toc


% Calculate statistics
disp('Simulating ...');
sim_dyn_mod
toc



disp('Writing the Report ...');

% Generate Table 5
load(fname);
saved_dir=strcat('Results\',name); mkdir(saved_dir)

% % Parameters table
% param = str2num(num2str([beta psi gam varphi f alpha delta tau a1 eps mu rho sigma_a phi_x v*stoch_vol_switch rho_sigma ],'%3.4f ')); % SAM EDIT
% columnLabels={'$\beta$';'$\psi$';'$\gamma$';'$\varphi$'; 'f'; '$\alpha$';'$\delta$';'$\tau$';'$a_{1}$'; '$\epsilon$';'$\mu$';'$\rho$';'$\sigma_{a}$';'$\sigma_{x}/\sigma_{a}$';'$\sigma_{\sigma}$'; '$\rho_{\sigma}$'};
% rowLabels={' '};
% matrix2latex(param,strcat([saved_dir,'\table_parameters.tex']),'rowLabels',rowLabels,'columnLabels',columnLabels,'alignment','c')

% Moments table
clear rowLabels columnLabels

rowLabels={'$\sigma(\Delta y)$ (\%)';
           '$\sigma(\Delta c)/\sigma(\Delta y)$';
           '$\sigma(\Delta i)/\sigma(\Delta y)$';
           '$E\left[I/Y\right] (\%)$';
           '$\sigma(I/Y)$ (\%)';
           '$\rho(\Delta c,\Delta i)$';
           '$\rho(\Delta c,r^{LEV})$'; 
           '$\frac{K_s}{K_n+K_s}$'; 
           
           '$E\left[r_{ex}^{LEV}\right]$ (\%)';
           '$\sigma(r_{ex}^{LEV})$ (\%)';
           '$E\left[r_{s}\right]$ (\%)';
           '$\sigma(r_{s})$ (\%)';
           '$\sigma(q)$';
                      
           '$E\left[r^{f}\right]$ (\%)';
           '$\sigma(r^{f})$ (\%)';
           
           '$ACF(r_{ex}^{LEV})$';
           '$ACF(r^{f})$';
           '$ACF(q)$';
           '$ACF(\Delta c)$';
           
%            '$\beta_{\Delta c|x}$';
%            '$\beta_{\Delta c|\epsilon_a}$';
%            '$\beta_{\Delta c|\epsilon_x}$';
%            '$\beta_{iy|\epsilon_a}$';
%            '$\beta_{iy|\epsilon_x}$';
%            '$\beta_{q|\epsilon_a}$';
%            '$\beta_{q|\epsilon_x}$'
};

columnLabels={'Moments'};
matrix2latex(output(1:19,1),strcat([saved_dir,'\table_moments.tex']),'rowLabels',rowLabels,'columnLabels',columnLabels,'alignment','c')

output_copy_paste = output(1:19,1);



% Conditional moments table
% if ep_cov_calc_switch==1
%     
%     clear rowLabels columnLabels
% 
%     columnLabels={'Moments'};
% 
%     if gold_switch==1
%     rowLabels={'$E_t\left[r^{f}\right]$ (\%)';
%                '$E_t\left[r_{k,ex}^{LEV}\right]$ (\%)';
%                '$E_t\left[r_{g,ex}\right]$ (\%)'};
%     matrix2latex([cond_sim_RF; cond_sim_EP_lev; cond_sim_EP_G],strcat([saved_dir,'\table_cond_moments.tex']),'rowLabels',rowLabels,'columnLabels',columnLabels,'alignment','c')
%     else
%     rowLabels={'$E_t\left[r^{f}\right]$ (\%)';
%                '$E_t\left[r_{ex}^{LEV}\right]$ (\%)'};    
%     matrix2latex([cond_sim_RF; cond_sim_EP_lev],strcat([saved_dir,'\table_cond_moments.tex']),'rowLabels',rowLabels,'columnLabels',columnLabels,'alignment','c')
%     end
% 
% end
% 
% 
% % Gold parameters and moments tables (SAM ADD)
% if gold_switch==1  
%     
%     % parameters table
%     clear rowLabels columnLabels
%     param_gold = str2num(num2str([varphi_g G_ss Gbar_ss f_g coint_g a1_g tau_g phi0_g phi1_g eps_g sigma_g corr_g ],'%3.5f ')); % SAM EDIT
%     columnLabels={'$\varphi_g$';'$Gpct_{SS}$';'$\overline{G}_{ss}/K_{ss}$';'$f_g$'; '$\tau_{coint}$'; '$a_{1g}$'; '$\tau_{g}$'; '$\phi_{0}$'; '$\phi_{1}$'; '$\epsilon_{g}$'; '$\sigma_{g}$'; '$\rho_{x,g}$'};
%     rowLabels={' '};
%     matrix2latex(param_gold,strcat([saved_dir,'\table_parameters_gold.tex']),'rowLabels',rowLabels,'columnLabels',columnLabels,'alignment','c')
% 
%     % moments table
%     rowLabels={'$E\left[r_{G}^{ex}\right]$ (\%)';
%                '$\sigma(r_{G}^{ex})$ (\%)';
%                '$E\left[J/Y\right] (\%)$';
%                '$\sigma(J/Y)$ (\%)'};
%     columnLabels={'Moments'};
%     matrix2latex(output_G(:,1),strcat([saved_dir,'\table_moments_gold.tex']),'rowLabels',rowLabels,'columnLabels',columnLabels,'alignment','c')
%     
%     disp('G moments')
%     output_copy_paste = [output_copy_paste; 
%                          output_G(:,1)];
%     
% end



%% Write tex report
% write_tex
% eval(strcat(['cd ',saved_dir]))
% eval(strcat(['!pdflatex.exe "Report.tex" -jobname Report_',num2str(cal_no)]))
% cd ..
% cd ..

%% Housekeeping
% disp('Housekeeping ...');
% movefile(strcat(fname,'*'),saved_dir)
% open(strcat(saved_dir,'\Report_',num2str(cal_no),'.pdf'));


% disp('output_copy_paste:')
% output_copy_paste

clear all; %clc
beep;
toc
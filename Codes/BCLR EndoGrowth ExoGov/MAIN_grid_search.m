%% Run a grid search over a select set of parameters and
%  then compute/save the time series moments of interest

%% Housekeeping and common settings

% SAM add the following lines so he can use dynare_simul for PC
if strcmp(getenv('COMPUTERNAME'),'FIN-SROSE-T480S')
    addpath(genpath('Monopoly Power - Sam'));
else
    addpath(genpath('Monopoly Power'));
end
clearvars -global -except cal_no_; clc
warning off %#ok<WNOFF>
global cal_no saved_dir fname beta psi gamma alphap alphac rhoar arc rhotest deltap deltac w tau xi kappa  mu rho sigma rhovol stoch_vol_switch f con_shocka con_shockx;
% Gold Addition
global gold_switch varphi_g f_g Gbar_ss coint_g tau_g a1_g eps_g phi0_g phi1_g sigma_g corr_g G_ss
global ep_cov_calc_switch conditional_moments_switch shock_direction_switch simul_fast

% base calibartion
cal_no=81;
disp(['Calibration: ' num2str(cal_no)]);

% parameter grids
frEq = 4;
beta_grid  = [0.98^(1/frEq), 0.985^(1/frEq)]; 
gamma_grid = [10, 12, 15, 20];
chi_grid   = [0.128, 0.126, 0.124, 0.122];
eta_grid   = [0.76, 0.77, 0.78, 0.79, 0.80];




%% run grid search



% final matrix to store
N_total = length(beta_grid)*length(gamma_grid)*length(chi_grid)*length(eta_grid);
disp(char(strcat({'There are '},num2str(N_total),{' loops to run through'})));
%save_results = nan(N_total, 29);
save_results = nan(N_total, 27);

N_loop = 0;
for i_beta=1:length(beta_grid)
 for i_gamma=1:length(gamma_grid)
  for i_chi=1:length(chi_grid)
   for i_eta=1:length(eta_grid)

    N_loop = N_loop+1;
    disp(char(strcat({'Loop number '},num2str(N_loop),{'...'})));
       
%     i_beta = 1;
%     i_gamma = 2;
%     i_chi = 1;
%     i_eta = 1;

    % start timer
    t_loop_start = tic;

    % Write mod file
    disp('Write the mod...'); 
    calibrations
    beta  = beta_grid(i_beta);
    gamma = gamma_grid(i_gamma);
    chi   = chi_grid(i_chi);
    eta   = eta_grid(i_eta);
    write_mod_grid_search
    
    % Choose dynare++
    Use_New_Dynare=0;
    if Use_New_Dynare==0
        dynare_ver='2.1'; 
    elseif Use_New_Dynare==1
        dynare_ver='3.1';
        disp('Using Dynare++ 4.3.1')
    elseif Use_New_Dynare==2
        dynare_ver='3.2';
        disp('Using Dynare++ 4.3.2')
    end

    % Execute dynare++
    disp('Solving...');
    fname=strcat('Monopoly_Power_Approx_',num2str(cal_no)); mod_name=strcat(fname,'.mod'); %#ok<*NODEF>
    %mac_switch = 1;
    % SAM add below flexibility to running MAIN code
    if strcmp(getenv('COMPUTERNAME'),'FIN-SROSE-T480S')
        mac_switch = 0;
    else
        mac_switch = 1;
    end
    if mac_switch == 1
       system(strcat(['/Applications/Dynare/4.6.1/dynare++/dynare++ --sim 3 --per 10 --no-irfs --ss-tol 1e-10 ',mod_name]));
    else
    eval(strcat(['!dynare++_4.',dynare_ver,' --sim 3 --per 10 --no-irfs --ss-tol 1e-10 ',mod_name]))
    end

    % Create extra variables outside of the mod file
    create_var    
    
    % run simulation and save time series stats
    sim_dyn_mod_grid_search
    
    % end
    t_loop_end = toc(t_loop_start);    
    disp(char(strcat({'Loop took '},num2str(t_loop_end),{' seconds'})));

    % dyn_ss avlues
    dyn_ss_avg_exrrnd = 100*4*dyn_ss(dyn_i_exrrnd); 
    dyn_ss_avg_rf = 100*4*dyn_ss(dyn_i_rf); 
    dyn_ss_avg_growth = 100*4*dyn_ss(dyn_i_dy);
    
    % compile vector to save
    %vec_to_save = [beta; gamma; chi; eta; t_loop_end-t_loop_start; output]';
    %ts_moments = mean(output_N,3);
    ts_moments = output;
    vec_to_save = [beta; gamma; chi; eta; t_loop_end; dyn_ss_avg_exrrnd; dyn_ss_avg_rf; dyn_ss_avg_growth; ts_moments]'; 
    save_results(N_loop,:) = vec_to_save;
    
    % export every loop just in case the program crashes
    filename = 'Main_grid_search_results.xlsx';
    varnames = {'beta','gamma','chi','eta','loop_time', 'dyn_ss_avg_exrrnd', 'dyn_ss_avg_rf', 'dyn_ss_avg_growth', output_varlabels{:}};
    results_table = array2table(save_results, 'VariableNames', varnames);
    %results_table = array2table(save_results);
    writetable(results_table, filename,'Sheet',1);    
    
   end % i_eta
  end % i_chi
 end % i_gamma
end % i_beta
           


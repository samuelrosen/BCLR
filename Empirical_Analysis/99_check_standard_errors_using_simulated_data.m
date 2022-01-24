%% compute standard errors based on simulated data as a way to
%  check the SEs that we currently used in the empirical analysis

clear; clc;
addpath(genpath('matlab')); 


%% Table 5: Reallocation and Growth

% import data to be used

    T = readtable('data_for_tfpg_prediction/data_for_tfpg_prediction_june2020.csv');
    smoothing = 10000;

    [~,comp_rnd_cap_dt] = one_sided_hp_filter_kalman(T.comp_pct_at_high_rnd,smoothing);
    [~,comp_rnd_inv_dt] = one_sided_hp_filter_kalman(T.comp_pct_inv_high_rnd,smoothing);

    % standard deviations used in interpreting reg results
    std_comp_rnd_cap_dt = std(comp_rnd_cap_dt);
    std_comp_rnd_inv_dt = std(comp_rnd_inv_dt);
    disp(char(strcat({'std dev of dt compusat Krnd/Ktot is '},num2str(std_comp_rnd_cap_dt))));
    disp(char(strcat({'std dev of dt compusat Irnd/Itot is '},num2str(std_comp_rnd_inv_dt))));

    
% set seed for easy replicating finders
seed=934098;  % starting seed so that same sim results each time
rng(seed);            
    
% run given reg and simulate data based on Beta and std(Resid)    
var = [comp_rnd_cap_dt];
for lag = [5 7 10]
    
    % run reg
    tfpygr_avr = tsmovavg(T.tfpyg(2:end), 's', lag, 1);
    F=[T.bondy1y T.bondy2y T.bondy3y T.bondy4y T.bondy5y T.bondy6y T.inflationy T.pdratioy T.ivoly T.anfci T.nfci T.baa10ym var];
    % Run Regression da   = ca + b_x * F(-1) + ea; %1973-2011
    lags = 2;
    weight = 1;
    start = 0;
    Y = tfpygr_avr(lag+start:end,1); %74-83
    X = [ones(length(Y),1) F(1+start:end-lag,:)];
    [BetaseEA,SesEA,RsqrEA,RsqradjEA,VCVEA,FEA]=olsgmm(Y,X,lags,weight);
    Resid = Y-X*BetaseEA;
    
    [H,P,JBSTAT,CRITVAL] = jbtest(Resid, 0.05)
    
    % simulate residuals and then new sample
%     sim_resid = normrnd(0, std(Resid), length(Y), 1000);
%     sim_Y = X*BetaseEA + sim_resid;
%     
%     % run estimation on each sample
%     var_beta = nan(1000,1);
%     for j=1:1000
%         disp(j);
%         [sim_BetaseEA, sim_SesEA, sim_RsqrEA, sim_RsqradjEA, sim_VCVEA, sim_FEA]=olsgmm(sim_Y(:,j), X, lags, weight);
%         var_beta(j,1) = sim_BetaseEA(end);
%     end
%     %mean(var_beta)
%     %std(var_beta)
%     close all;
%     figure(1);
%         hist(var_beta);
%         title(strcat('Compustat Capital Measure Estimates Lag=',num2str(lag),' (mean=',num2str(mean(var_beta)),', std=',num2str(std(var_beta)),')'));
%         xline(BetaseEA(end),'--r');
%     fname=strcat(['figures\check_table5_reg_sim_comp_rnd_cap_dt_hist_lag',num2str(lag)]);    
%     %saveas(1,strcat(fname))
%     saveas(1,strcat(fname),'jpg')
%     %saveas(1,strcat(fname),'png')
%     close all;
%     
end    


% run given reg and simulate data based on Beta and std(Resid)    
var = [comp_rnd_inv_dt];
for lag = [5 7 10]
    
    % run reg   
    tfpygr_avr = tsmovavg(T.tfpyg(2:end), 's', lag, 1);
    F=[T.bondy1y T.bondy2y T.bondy3y T.bondy4y T.bondy5y T.bondy6y T.inflationy T.pdratioy T.ivoly T.anfci T.nfci T.baa10ym var];
    % Run Regression da   = ca + b_x * F(-1) + ea; %1973-2011
    lags = 2;
    weight = 1;
    start = 0;
    Y = tfpygr_avr(lag+start:end,1); %74-83
    X = [ones(length(Y),1) F(1+start:end-lag,:)];
    [BetaseEA,SesEA,RsqrEA,RsqradjEA,VCVEA,FEA]=olsgmm(Y,X,lags,weight);
    Resid = Y-X*BetaseEA;
    
    [H,P,JBSTAT,CRITVAL] = jbtest(Resid, 0.05)
    
%     % simulate residuals and then new sample
%     sim_resid = normrnd(0, std(Resid), length(Y), 1000);
%     sim_Y = X*BetaseEA + sim_resid;
%     
%     % run estimation on each sample
%     var_beta = nan(1000,1);
%     for j=1:1000
%         disp(j);
%         [sim_BetaseEA, sim_SesEA, sim_RsqrEA, sim_RsqradjEA, sim_VCVEA, sim_FEA]=olsgmm(sim_Y(:,j), X, lags, weight);
%         var_beta(j,1) = sim_BetaseEA(end);
%     end
%     %mean(var_beta)
%     %std(var_beta)
%     close all;
%     figure(1);
%         hist(var_beta);
%         title(strcat('Compustat Investment Measure Estimates Lag=',num2str(lag),' (mean=',num2str(mean(var_beta)),', std=',num2str(std(var_beta)),')'));
%         xline(BetaseEA(end),'--r');
%     fname=strcat(['figures\check_table5_reg_sim_comp_rnd_inv_dt_hist_lag',num2str(lag)]);    
%     %saveas(1,strcat(fname))
%     saveas(1,strcat(fname),'jpg')
%     %saveas(1,strcat(fname),'png')
%     close all;
    
end    
    

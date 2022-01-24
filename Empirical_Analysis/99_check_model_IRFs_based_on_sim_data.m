%% program to do the following:
%   - create nice time series plots from the data
%   - estimate VARs from actual or simulated data
%   - plot IRFs from the data VARs for either
%       - a 1-unit impulse (standard)
%       - a sequence of shocks as in the great recession
%   - compare IRF from data VAR to IRF from model equations

    % toolbox that includes some pre-made VAR functions such as vectorar
    addpath(genpath('matlab')); 
    addpath(genpath('matlab/MFEToolbox')); 
    addpath(genpath('matlab/PattonWebsite')); 
    addpath(genpath('matlab/CominGertler')); 
    addpath(genpath('data_for_Productivity_Uncertainty')); 
    addpath(genpath('data_for_VAR'));
    
    % housekeeping
    clear; clc;

 
%% data

    % data series computed from investment regressions:
    % - log tfp growth (dtfp)
    % - long-run productivity (x)
    % - fitted volatility (expvol)
    % - standard errors of fitted volatility (expvol_se)
    % note: these mat files were produced from Wenix's program
    %       measure_productivity_uncertainty.m
    
        % declare start year for data_inv_reg, which we run
        % over different sample periods because we are not sure
        % which choice is most consistent with rest of empirical
        % analysis.
        % as of july 2019 draft: we use 1972 and 1961 as robustness. to
        % avoid confusion, the robustness figures from 1961 need to be
        % created and then manually renamed in order to be updated if
        % needed
        sample_start_year = 1972
    
        if sample_start_year==1969
            load data_inv_reg_qtr_1969_2016                     
            load data_inv_reg_ann_1969_2016   
        elseif sample_start_year==1961
            load data_inv_reg_qtr_1961_2016                     
            load data_inv_reg_ann_1961_2016               
        elseif sample_start_year==1972
            % load the 1961 version in case we need to run VAR on longer sample
            load data_inv_reg_qtr_1961_2016                     
            load data_inv_reg_ann_1961_2016               
            data_inv_reg_ann_1961 = data_inv_reg_ann;
            data_inv_reg_qtr_1961 = data_inv_reg_qtr;
            clearvars data_inv_reg_qtr data_inv_reg_qtr
            
            load data_inv_reg_qtr_1972_2016                     
            load data_inv_reg_ann_1972_2016                           
        else
            error('sample_start_year not accounted for above');
        end

        
    % macro data series (nominal and real)
    % note: these data series were compiled and cleaned in Stata. the 
    %       specific program that created these csv files is 
    %       "02b_export_macro_data_for_VAR.do". 

        

        % quarterly
        T = readtable('data_macro_qtr_from_1947.csv');
        data_macro_qtr = table2struct(T,'ToScalar',true);            
        clear T

    
%% simulate model data for computing IRFs using data VAR method

Nsim = 1000;
Nper=180; % num quarterly obs from 1972q1--2016q4 as in data VAR

mod_num = 81;
model_out_81 = gen_model_sim_data( mod_num, Nsim, Nper );

mod_num = 82;
model_out_82 = gen_model_sim_data( mod_num, Nsim, Nper );

save('model_sim_data/model_out_save.mat')


%% model IRFs vs simulated-then-data-VAR IRFs
%  create 2x3 figure that compares model vs 4-variable data VAR for a
%  set of var4 choices that include govt variables that we label as G

load('model_sim_data/model_out_save.mat')

clc;

ccvarlist = {'none'};
%ccvarlist = {'baa10ym'}; % how do we control for baa spread in the model sim data?

% var4 set
var_set = {'Ig_Y';'IPPrnd_real';'Ip_real';'labor_share_govt';'labor_priv';'Yp_real'}; 
My_Ylims_c1 = [-2.0, 1.0];
My_Ylims_c2 = [-2.0, 1.0];
My_Ylims_c3 = [-2.0, 1.0];
My_Ylims_c4 = [-1.0, 0.5];    
My_Ylims_c5 = [-1.0, 0.5];    
My_Ylims_c6 = [-1.0, 0.5];    

% VAR specs choice
%myVARspec = 'hpfilter';
myVARspec = 'bandpass'; % doesn't seem to work with raw data for some reason
%myVARspec = 'levels';

%modnum_list = [81,82,83];
% 81 = Benchmark govt (endogenous investment L sector)
% 82 = EGI
% 83 = EGE, which has weaker reallocation because deltaG=100%
%modnum_list = [93,94]; % alternate cals we explore in october 2020
%modnum_list = [96,97]; % alternate cals we explore in october 2020
%modnum_list = [135];
%modnum_list = [82];
modnum_list = [81, 82];


for mmm = 1:length(modnum_list)
my_modnum = modnum_list(mmm);
eval(strcat('model_out_data = model_out_',num2str(my_modnum),';'));
 for ccc = 1:length(ccvarlist)
 % cc control var
 myccvar = char(ccvarlist{ccc});

 
     % compute data VAR IRFs for different var4 choices
     for vvv = 1:length(var_set)
           
            %myVARspec = char(VARspecs{vvv});
            var4_choice = var_set{vvv} ;

            % figure out starting and ending positions
            sample_start_year = 1972;
            sample_end_year   = 2016;     
            if strcmp(myVARspec,'levels')
                pos_start_macro  = find((data_macro_qtr.year>=sample_start_year),1,'first');        
            else % need extra period for filtering        
                pos_start_macro = find((data_macro_qtr.year>=sample_start_year),1,'first') - 1; 
            end    
            pos_end_macro   = find((data_macro_qtr.year<=sample_end_year),1,'last');
            pos_start_invreg = find((data_inv_reg_qtr.year>=sample_start_year),1,'first');        
            pos_end_invreg   = find((data_inv_reg_qtr.year<=sample_end_year),1,'last');  
            disp(char(strcat({'macro var data from '},num2str(data_macro_qtr.year(pos_start_macro)),'q',num2str(data_macro_qtr.qtr(pos_start_macro)))))
            disp(char(strcat({'macro var data to '},  num2str(data_macro_qtr.year(pos_end_macro)),  'q',num2str(data_macro_qtr.qtr(pos_end_macro)))))
            disp(char(strcat({'inv reg data from '},num2str(data_inv_reg_qtr.year(pos_start_invreg)),'q',num2str(data_inv_reg_qtr.qtr(pos_start_invreg)))))
            disp(char(strcat({'inv reg data to '},num2str(data_inv_reg_qtr.year(pos_end_invreg)),'q',num2str(data_inv_reg_qtr.qtr(pos_end_invreg)))))    

            % first three variables from investment regression
            if strcmp(myVARspec,'levels')
                var1 = data_macro_qtr.tfp( pos_start_macro:pos_end_macro); % tfp in levels
            else
                var1 = data_macro_qtr.dtfp( pos_start_macro+1:pos_end_macro)/4; % dtfp from macro data. need to convert back to quarterly rates from annualized rate
                %var1_chk = data_inv_reg_qtr.dtfp( pos_start_invreg:pos_end_invreg); % dtfp from inv reg data
                %chk_diff = abs(var1 - var1_chk);
                %max(chk_diff)
                %[var1, var1_chk]
            end
            var2 = data_inv_reg_qtr.x( pos_start_invreg:pos_end_invreg);
            var3 = data_inv_reg_qtr.expvol( pos_start_invreg:pos_end_invreg);

            % 4th variable that may be filtered depending myVARspec
            eval(strcat('var4_raw_qtr = data_macro_qtr.',var4_choice,';'));
            var4_trunc = var4_raw_qtr(pos_start_macro:pos_end_macro); % truncated series to match other series
            if strcmp(myVARspec,'levels') % simply compute in log levels
                temp_var4_qtr = log(var4_trunc); 
            else % de-trend 4th variable 

                temp_var4_qtr = nan(size(var4_trunc));

                % HP filter. use pos_start+1 because no need to take first differences
                if strcmp(myVARspec,'hpfilter')            
                    raw_var4_qtr     = log(var4_trunc(2:end));
                    smooth_var4_qtr  = hpfilter(raw_var4_qtr, 1600); % quarterly data smoothing 
                    temp_var4_qtr    = raw_var4_qtr - smooth_var4_qtr;
                end   

                % Comin Gertler (2006) band-pass
                % The function is bandpass(X,pl,pu). X is the raw data, pl and pu is the range of frequencies we want to extract. 
                % Recommended by Comin and Gertler (attached below), we should choose pl = 2 and pu = 200 for the quarterly data 
                % to extract the medium-term cycles. 
                if strcmp(myVARspec,'bandpass')  
                    size(var4_trunc);
                    raw_var4_qtr = log(var4_trunc(2:end)); % no reduction in size from bandpass --> need to cut first obs for VAR
                    temp_var4_qtr = bandpass(raw_var4_qtr, 2, 200);
                    size(temp_var4_qtr); % no reduction in size from bandpass                                
                end  

            end

            % series to enter VAR in levels 
            if strcmp(var4_choice,'Ig_Itot') ...
            || strcmp(var4_choice,'Ip_Itot') ...
            || strcmp(var4_choice,'Ig_Y') ...
            || strcmp(var4_choice,'Ig_less_def_Y') ...    
            || strcmp(var4_choice,'labor_share_govt') ...
            || strcmp(var4_choice,'labor_share_priv') 
                var4 = exp(temp_var4_qtr);
            else
                var4 = temp_var4_qtr; % keep in logs
            end    

            % endogenous vars matrix
            temp_y_qtr = [var1, var2, var3, var4];

            % exogenous vars matrix
            temp_x_qtr = ones(size(temp_y_qtr,1),1);
            if ~strcmp(myccvar, 'none')
                % commnet out until we can figure out a way to have Baa
                % control in model sim VAR
%                 eval(strcat('ccvar_raw_qtr = data_macro_qtr.',myccvar,';'));
%                 if strcmp(myVARspec,'levels') 
%                     temp_ccvar_qtr = ccvar_raw_qtr(pos_start_macro:pos_end_macro);
%                 else
%                     temp_ccvar_qtr = ccvar_raw_qtr(pos_start_macro+1:pos_end_macro);
%                 end
%                 temp_x_qtr = [temp_x_qtr, temp_ccvar_qtr];        
            end      

            eval(strcat('y_qtr_',num2str(vvv),' = temp_y_qtr;'));
            eval(strcat('x_exo_qtr_',num2str(vvv),' = temp_x_qtr;'));

            clear var4_raw_qtr var4_trunc temp_var4_qtr temp_y_qtr temp_x_qtr

            % define different shock matrices

                std_IRF_length_qtr = 24;

                % 1-std dtfp shock
                std_dtfp_shk_mat_qtr      = zeros(4 , std_IRF_length_qtr);
                std_dtfp_shk_mat_qtr(1,1) = 1;            

                % 1-std ivol shock
                std_ivol_shk_mat_qtr      = zeros(4 , std_IRF_length_qtr);
                std_ivol_shk_mat_qtr(3,1) = 1;             

                % compute IRFs for ivol shk
                eval(strcat('IRFout_ivolshk_qtr_',num2str(vvv),' = gen_IRF_vectors_dataVAR_nvars( y_qtr_',num2str(vvv),', x_exo_qtr_',num2str(vvv),', [], std_ivol_shk_mat_qtr, 0);'));

     end % vvv     

     
  % compute set of model-sim-data-VAR results
  for nsim=1:Nsim        

     disp(strcat('compute data VAR for nsim=',num2str(nsim),'...'));
      
     % compute IRFs for different var4 choices
     for vvv = 1:length(var_set)

        %myVARspec = char(VARspecs{vvv});
        var4_choice = var_set{vvv} ;

        % first three variables from investment regression
        if strcmp(myVARspec,'levels')
            var1 = model_out_data.tfp(nsim,:); % tfp in levels
        else
            var1 = model_out_data.dtfp(nsim,:); % already a quarterly rate so do not divide by 4
            %var1_chk = data_inv_reg_qtr.dtfp( pos_start_invreg:pos_end_invreg); % dtfp from inv reg data
            %chk_diff = abs(var1 - var1_chk);
            %max(chk_diff)
            %[var1, var1_chk]
        end
        var2 = model_out_data.x(nsim,:);
        var3 = model_out_data.expvol(nsim,:);

        % 4th variable that may be filtered depending myVARspec
        eval(strcat('var4_raw_qtr = model_out_data.',var4_choice,'(nsim,:);'));
        var4_trunc = var4_raw_qtr; % truncated series to match other series
        if strcmp(myVARspec,'levels') % simply compute in log levels
            temp_var4_qtr = log(var4_trunc); 
        else % de-trend 4th variable 

            temp_var4_qtr = nan(size(var4_trunc));

            % HP filter. use pos_start+1 because no need to take first differences
            if strcmp(myVARspec,'hpfilter')            
                raw_var4_qtr     = log(var4_trunc(2:end));
                smooth_var4_qtr  = hpfilter(raw_var4_qtr, 1600); % quarterly data smoothing 
                temp_var4_qtr    = raw_var4_qtr - smooth_var4_qtr;
            end   

            % Comin Gertler (2006) band-pass
            % The function is bandpass(X,pl,pu). X is the raw data, pl and pu is the range of frequencies we want to extract. 
            % Recommended by Comin and Gertler (attached below), we should choose pl = 2 and pu = 200 for the quarterly data 
            % to extract the medium-term cycles. 
            if strcmp(myVARspec,'bandpass')  
                size(var4_trunc);
                %raw_var4_qtr = log(var4_trunc(2:end)); % no reduction in size from bandpass --> need to cut first obs for VAR
                raw_var4_qtr = log(var4_trunc); % use full time series to match dimensions.
                %plot(var4_trunc)
                %bandpass(var4_trunc, 2, 32)
                %plot(raw_var4_qtr)                
                %bandpass(raw_var4_qtr, 2, 32)
                temp_var4_qtr = bandpass(raw_var4_qtr', 2, 200);
                size(temp_var4_qtr); % no reduction in size from bandpass                                
            end  

        end
        

        % series to enter VAR in levels 
        if strcmp(var4_choice,'Ig_Itot') ...
        || strcmp(var4_choice,'Ip_Itot') ...
        || strcmp(var4_choice,'Ig_Y') ...
        || strcmp(var4_choice,'Ig_less_def_Y') ...    
        || strcmp(var4_choice,'labor_share_govt') ...
        || strcmp(var4_choice,'labor_share_priv') 
            var4 = exp(temp_var4_qtr);
        else
            var4 = temp_var4_qtr; % keep in logs
        end    
       
        % endogenous vars matrix
        temp_y_qtr = [var1', var2', var3', var4];

        % exogenous vars matrix
        temp_x_qtr = ones(size(temp_y_qtr,1),1);
        if ~strcmp(myccvar, 'none')
            eval(strcat('ccvar_raw_qtr = data_macro_qtr.',myccvar,';'));
            if strcmp(myVARspec,'levels') 
                temp_ccvar_qtr = ccvar_raw_qtr(pos_start_macro:pos_end_macro);
            else
                temp_ccvar_qtr = ccvar_raw_qtr(pos_start_macro+1:pos_end_macro);
            end
            temp_x_qtr = [temp_x_qtr, temp_ccvar_qtr];        
        end      

        eval(strcat('y_qtr_',num2str(vvv),' = temp_y_qtr;'));
        eval(strcat('x_exo_qtr_',num2str(vvv),' = temp_x_qtr;'));
        
        clear var4_raw_qtr var4_trunc temp_var4_qtr temp_y_qtr temp_x_qtr

        % define different shock matrices

            std_IRF_length_qtr = 24;

            % 1-std dtfp shock
            std_dtfp_shk_mat_qtr      = zeros(4 , std_IRF_length_qtr);
            std_dtfp_shk_mat_qtr(1,1) = 1;            

            % 1-std ivol shock
            std_ivol_shk_mat_qtr      = zeros(4 , std_IRF_length_qtr);
            std_ivol_shk_mat_qtr(3,1) = 1;             

            % compute IRFs for ivol shk
            %eval(strcat('IRFout_ivolshk_qtr_',num2str(vvv),' = gen_IRF_vectors_dataVAR_nvars( y_qtr_',num2str(vvv),', x_exo_qtr_',num2str(vvv),', [], std_ivol_shk_mat_qtr, 0);'));
            eval(strcat('temp_IRFout_ivolshk_qtr = gen_IRF_vectors_dataVAR_nvars( y_qtr_',num2str(vvv),', x_exo_qtr_',num2str(vvv),', [], std_ivol_shk_mat_qtr, 0);'));

            % response of 4th varialbe in VAR
            eval(strcat('pan',num2str(vvv),'_oirf_var4(nsim,:) = temp_IRFout_ivolshk_qtr.oirf_var4;'));
            
     end % vvv var4 list

    end % nsim
    
   
%     pan1_oirf_var4
%     pan2_oirf_var4
%     pan3_oirf_var4
%     pan4_oirf_var4
%     pan5_oirf_var4
%     pan6_oirf_var4
     
   
     % generate IRF vectors from the model

        %my_modnum = modnumlist(mmm);

        % single unit impulse to exp(vol)

            std_IRF_length_qtr = 24;

            % std volatility level shock
            vol_shk_lev_mat_qtr      = zeros(2 , std_IRF_length_qtr);
            %vol_shk_lev_mat_qtr(2,1) = log( std(data_inv_reg_qtr.expvol)+1 ); % log shock val to get 1-std dev in level of vol
            vol_shk_lev_mat_qtr(2,1) = 0.206709344348183; % hard code value from other program
            % NOTE: ex removed as shock in BCLR EndoGrowth

            % std tfp shock. note that TFP growth in the data VAR is in log
            % units according to Wenxi
            tfp_val_shk_mat_qtr      = zeros(2 , std_IRF_length_qtr);
            %tfp_val_shk_mat_qtr(1,1) = std(data_inv_reg_qtr.dtfp); % shock val to log TFP growth
            tfp_val_shk_mat_qtr(1,1) = 0.007536602407817; % hard code value from other program

            disp(char(strcat({'Computing IRFs for model '},num2str(my_modnum),{'...'})));

            % compute irfs for 1-unit vol shock and 1-unit tfp shock

                model_IRFout_1unit_tfp_qtr = gen_IRF_vectors_model( my_modnum, [], [], 'lev', tfp_val_shk_mat_qtr);
                model_IRFout_1unit_vol_qtr = gen_IRF_vectors_model( my_modnum, [], [], 'lev', vol_shk_lev_mat_qtr);

             % save IRF vectors
             for vvv = 1:length(var_set)    
                var4_choice = var_set{vvv} ;
                if strcmp(var4_choice,'Yp_real')
                    temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_logYp;
                    temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_logYp;                                                            
                elseif strcmp(var4_choice,'Ig_Itot')
                    temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_Ig_Itot;
                    temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_Ig_Itot;                                           
                elseif strcmp(var4_choice,'Ip_Itot')
                    temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_Ip_Itot;
                    temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_Ip_Itot;            
                elseif strcmp(var4_choice,'Ig_Y')
                    temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_Ig_Y;
                    temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_Ig_Y;       
                elseif strcmp(var4_choice,'Ig_less_def_Y')
                    temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_Ig_Y;
                    temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_Ig_Y;                                       
                elseif strcmp(var4_choice,'IPPrnd_real')
                    temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_logIPPrnd;
                    temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_logIPPrnd;            
                elseif strcmp(var4_choice,'Ig_real')
                    temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_logIg;
                    temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_logIg;                        
                elseif strcmp(var4_choice,'Ip_real')
                    temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_logIp;
                    temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_logIp;                                  
                elseif strcmp(var4_choice,'labor_share_govt')
                    temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_ncnt;
                    temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_ncnt;          
                elseif strcmp(var4_choice,'labor_share_priv')
                    temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_npnt;
                    temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_npnt;                 
                elseif strcmp(var4_choice,'labor_govt')
                    temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_nc; % already in logs
                    temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_nc; % already in logs
                elseif strcmp(var4_choice,'labor_priv')
                    temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_np; % already in logs
                    temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_np; % already in logs
                else
                    error('var4_choice not recognized');
                end

                eval(strcat('model_IRF_vol_line_',num2str(vvv),' = temp_model_IRF_vol_line;'));
             end % vvv

            disp(char(strcat({'Done computing model IRFs!'})));


  
            
    % save data for the future
    save(strcat('model_sim_data/model_and_modsim_and_data_IRFs_mod',num2str(my_modnum),'_ccvar_',myccvar,'.mat'))

    
    end % ccc ccvarlist
end % mmm modnum_list   


%% create plots

my_modnum = 81;
%my_modnum = 82;
myccvar = 'none'; % cc control var

load(strcat('model_sim_data/model_and_modsim_and_data_IRFs_mod',num2str(my_modnum),'_ccvar_',myccvar,'.mat'))

% how large of standard error band around mean of VAR responses from
% IRFs based on VARs using simulated model data
SE_band_size = 1.3;

    % create the 2x3 figure of model IRF against modsimdataVAR IRF
    close ALL
    figure(1);

    
        fname = strcat('IRFs_OnlyVol_model_',num2str(my_modnum),'_irf_vs_simdataVAR_median_iqr_',myVARspec,'_control_',myccvar,'_2x3_',char(var_set{1}),'_',char(var_set{2}),'_',char(var_set{3}),'_',char(var_set{4}),'_',char(var_set{5}),'_',char(var_set{6}));    

        % panel titles
        for vvv = 1:length(var_set)    

            var4_choice = var_set{vvv}; 

            %if alt_panel_titles==1 
                if strcmp(var4_choice,'Yp_real')
                    temp_MyVar_title = 'log(Y_H)';
                elseif strcmp(var4_choice,'Ig_Y')
                    temp_MyVar_title = 'I_L / Y';
                elseif strcmp(var4_choice,'Ig_real')
                    temp_MyVar_title = 'log(I_L)';
                elseif strcmp(var4_choice,'Ip_real')
                    temp_MyVar_title = 'log(I_H)';
                elseif strcmp(var4_choice,'IPPrnd_real')
                    temp_MyVar_title = 'log(I_R_&_D)';
                elseif strcmp(var4_choice,'labor_share_govt')
                    temp_MyVar_title = 'L_L / (L_L + L_H))';            
                elseif strcmp(var4_choice,'labor_share_priv')
                    temp_MyVar_title = 'L_H / (L_L + L_H)';
                elseif strcmp(var4_choice,'labor_govt')
                    temp_MyVar_title = 'log(L_L)';            
                elseif strcmp(var4_choice,'labor_priv')
                    temp_MyVar_title = 'log(L_H)';                                          
                else
                    error('var4_choice not recognized');        
                end              
%             else
%                 if strcmp(var4_choice,'Yp_real')
%                     temp_MyVar_title = 'Priv. Output (log(Y_p))';
%                     temp_MyVar_title = 'log(Y_p)';
%                 elseif strcmp(var4_choice,'Ig_Itot')
%                     temp_MyVar_title = 'Govt. to Total Inv. (I_g / (I_g + I_p))';
%                 elseif strcmp(var4_choice,'Ip_Itot')
%                     temp_MyVar_title = 'Priv. to Total Inv. (I_p / (I_g + I_p))';
%                 elseif strcmp(var4_choice,'Ig_Y')
%                     temp_MyVar_title = 'Govt. to GDP (I_g / Y)';
%                     temp_MyVar_title = 'I_g / Y';
%                 elseif strcmp(var4_choice,'Ig_less_def_Y')
%                     temp_MyVar_title = 'Govt. to GDP (I_g / Y)';
%                     temp_MyVar_title = 'I_g_,_n_o_n_d_e_f / Y';                                
%                 elseif strcmp(var4_choice,'Ig_real')
%                     temp_MyVar_title = 'Govt. Inv. (log(I_g))';
%                 elseif strcmp(var4_choice,'Ip_real')
%                     temp_MyVar_title = 'Priv. Total Inv. (log(I_p))';
%                     temp_MyVar_title = 'log(I_p)';
%                 elseif strcmp(var4_choice,'IPPrnd_real')
%                     temp_MyVar_title = 'Priv. R&D Inv. (log(I_R_&_D))';
%                     temp_MyVar_title = 'log(I_R_&_D)';
%                 elseif strcmp(var4_choice,'labor_share_govt')
%                     temp_MyVar_title = 'Govt. Labor Share (L_g / (L_g + L_p))';            
%                     temp_MyVar_title = 'L_g / (L_g + L_p)';            
%                 elseif strcmp(var4_choice,'labor_share_priv')
%                     temp_MyVar_title = 'Private Labor Share (L_p / (L_g + L_p))';              
%                     temp_MyVar_title = 'L_p / (L_g + L_p)';              
%                 elseif strcmp(var4_choice,'labor_govt')
%                     temp_MyVar_title = 'Govt. Labor (log(L_g))';            
%                     temp_MyVar_title = 'log(L_g)';            
%                 elseif strcmp(var4_choice,'labor_priv')
%                     temp_MyVar_title = 'Private Labor (log(L_p))';
%                     temp_MyVar_title = 'log(L_p)';
%                 else
%                     error('var4_choice not recognized');        
%                 end    
%             end

            eval(strcat('mytitle_',num2str(vvv),'=temp_MyVar_title;'));

        end % vvv

        % set size of figure so it fills page
        set(gcf, 'PaperPositionMode', 'manual');
        set(gcf, 'PaperUnits', 'inches');
        set(gcf, 'PaperPosition', [0 0 14.00 7.00]);            
        %set(gcf, 'PaperPosition', [0 0 7.00 3.50]); % 1x2 plot

        %IRF_length_plot = std_IRF_length_qtr+1;
        % per May 18 2019 call with max, change length of IRF to 20 
        % periods when comparing data vs model
        IRF_length_plot = std_IRF_length_qtr+1-4;    

        subplot(2,3,1); hold on; box on;
        plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
        plot(0:IRF_length_plot-1, 100*prctile(pan1_oirf_var4(:,1:IRF_length_plot),50), '-b', 'Linewidth', 2);
            plot(0:IRF_length_plot-1, 100*prctile(pan1_oirf_var4(:,1:IRF_length_plot),25), '--b', 'Linewidth', 1);
            plot(0:IRF_length_plot-1, 100*prctile(pan1_oirf_var4(:,1:IRF_length_plot),75), '--b', 'Linewidth', 1);
        plot(0:IRF_length_plot-1, 100*model_IRF_vol_line_1(1:IRF_length_plot), ':r', 'Linewidth', 3);
        title(strcat('\fontsize{12}',mytitle_1),'FontWeight','normal');
        xlabel(' ');
        ylabel('Percent');               
        axis('tight');
        %ylim(My_Ylims_c1);

        subplot(2,3,2); hold on; box on;
        plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
        plot(0:IRF_length_plot-1, 100*prctile(pan2_oirf_var4(:,1:IRF_length_plot),50), '-b', 'Linewidth', 2);
            plot(0:IRF_length_plot-1, 100*prctile(pan2_oirf_var4(:,1:IRF_length_plot),25), '--b', 'Linewidth', 1);
            plot(0:IRF_length_plot-1, 100*prctile(pan2_oirf_var4(:,1:IRF_length_plot),75), '--b', 'Linewidth', 1);
        plot(0:IRF_length_plot-1, 100*model_IRF_vol_line_2(1:IRF_length_plot), ':r', 'Linewidth', 3);
        title(strcat('\fontsize{12}',mytitle_2),'FontWeight','normal');
        xlabel(' ');
        %ylabel(temp_MyVar_ylabel);               
        axis('tight');
        %ylim(My_Ylims_c2);

        subplot(2,3,3); hold on; box on;
        plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
        h(1) = plot(0:IRF_length_plot-1, 100*prctile(pan3_oirf_var4(:,1:IRF_length_plot),50), '-b', 'Linewidth', 2);
            plot(0:IRF_length_plot-1, 100*prctile(pan3_oirf_var4(:,1:IRF_length_plot),25), '--b', 'Linewidth', 1);
            plot(0:IRF_length_plot-1, 100*prctile(pan3_oirf_var4(:,1:IRF_length_plot),75), '--b', 'Linewidth', 1);
        h(2) = plot(0:IRF_length_plot-1, 100*model_IRF_vol_line_3(1:IRF_length_plot), ':r', 'Linewidth', 3);
        title(strcat('\fontsize{12}',mytitle_3),'FontWeight','normal');
        xlabel(' ');
        %ylabel(temp_MyVar_ylabel);               
        axis('tight');
        %ylim(My_Ylims_c3);                  
        legend(h,'Sim. Data','Model','Location','northeast');
        clear h;

        subplot(2,3,4); hold on; box on;
        plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
        plot(0:IRF_length_plot-1, 100*prctile(pan4_oirf_var4(:,1:IRF_length_plot),50), '-b', 'Linewidth', 2);
            plot(0:IRF_length_plot-1, 100*prctile(pan4_oirf_var4(:,1:IRF_length_plot),25), '--b', 'Linewidth', 1);
            plot(0:IRF_length_plot-1, 100*prctile(pan4_oirf_var4(:,1:IRF_length_plot),75), '--b', 'Linewidth', 1);
        plot(0:IRF_length_plot-1, 100*model_IRF_vol_line_4(1:IRF_length_plot), ':r', 'Linewidth', 3);
        title(strcat('\fontsize{12}',mytitle_4),'FontWeight','normal');
        xlabel(' ');
        ylabel('Percent');               
        axis('tight');
        %ylim(My_Ylims_c4);

        subplot(2,3,5); hold on; box on;
        plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
        plot(0:IRF_length_plot-1, 100*prctile(pan5_oirf_var4(:,1:IRF_length_plot),50), '-b', 'Linewidth', 2);
            plot(0:IRF_length_plot-1, 100*prctile(pan5_oirf_var4(:,1:IRF_length_plot),25), '--b', 'Linewidth', 1);
            plot(0:IRF_length_plot-1, 100*prctile(pan5_oirf_var4(:,1:IRF_length_plot),75), '--b', 'Linewidth', 1);
        h(2) = plot(0:IRF_length_plot-1, 100*model_IRF_vol_line_5(1:IRF_length_plot), ':r', 'Linewidth', 3);
        title(strcat('\fontsize{12}',mytitle_5),'FontWeight','normal');
        xlabel(' ');
        %ylabel(temp_MyVar_ylabel);               
        axis('tight');
        %ylim(My_Ylims_c5);   
        %legend(h,'Data','Model','FontSize',14,'Position',[0.75 0.25 0.08 0.1]);
        clear h;

        subplot(2,3,6); hold on; box on;
        plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
        plot(0:IRF_length_plot-1, 100*prctile(pan6_oirf_var4(:,1:IRF_length_plot),50), '-b', 'Linewidth', 2);
            plot(0:IRF_length_plot-1, 100*prctile(pan6_oirf_var4(:,1:IRF_length_plot),25), '--b', 'Linewidth', 1);
            plot(0:IRF_length_plot-1, 100*prctile(pan6_oirf_var4(:,1:IRF_length_plot),75), '--b', 'Linewidth', 1);
        h(2) = plot(0:IRF_length_plot-1, 100*model_IRF_vol_line_6(1:IRF_length_plot), ':r', 'Linewidth', 3);
        title(strcat('\fontsize{12}',mytitle_6),'FontWeight','normal');
        xlabel(' ');
        %ylabel(temp_MyVar_ylabel);               
        axis('tight');
        %ylim(My_Ylims_c6);       

        % save jpg        
        saveas(1,strcat('figures/',fname),'png')
        saveas(1,strcat('figures/',fname)) 
        %saveas(1,strcat('output_for_paper/Figures/',fname),'png')
        %saveas(1,strcat('output_for_paper/Figures/',fname))                     
        close(1)                           

        
        
    % create the 2x3 figure of modsimdataVAR IRF against data IRF 
    close ALL
    figure(2);

    
        fname = strcat('IRFs_OnlyVol_model_',num2str(my_modnum),'_irf_vs_simdataVAR_median_iqr_data_',myVARspec,'_control_',myccvar,'_2x3_',char(var_set{1}),'_',char(var_set{2}),'_',char(var_set{3}),'_',char(var_set{4}),'_',char(var_set{5}),'_',char(var_set{6}));    

        % panel titles
        for vvv = 1:length(var_set)    

            var4_choice = var_set{vvv}; 

            %if alt_panel_titles==1 
                if strcmp(var4_choice,'Yp_real')
                    temp_MyVar_title = 'log(Y_H)';
                elseif strcmp(var4_choice,'Ig_Y')
                    temp_MyVar_title = 'I_L / Y';
                elseif strcmp(var4_choice,'Ig_real')
                    temp_MyVar_title = 'log(I_L)';
                elseif strcmp(var4_choice,'Ip_real')
                    temp_MyVar_title = 'log(I_H)';
                elseif strcmp(var4_choice,'IPPrnd_real')
                    temp_MyVar_title = 'log(I_R_&_D)';
                elseif strcmp(var4_choice,'labor_share_govt')
                    temp_MyVar_title = 'L_L / (L_L + L_H))';            
                elseif strcmp(var4_choice,'labor_share_priv')
                    temp_MyVar_title = 'L_H / (L_L + L_H)';
                elseif strcmp(var4_choice,'labor_govt')
                    temp_MyVar_title = 'log(L_L)';            
                elseif strcmp(var4_choice,'labor_priv')
                    temp_MyVar_title = 'log(L_H)';                                          
                else
                    error('var4_choice not recognized');        
                end              
%             else
%                 if strcmp(var4_choice,'Yp_real')
%                     temp_MyVar_title = 'Priv. Output (log(Y_p))';
%                     temp_MyVar_title = 'log(Y_p)';
%                 elseif strcmp(var4_choice,'Ig_Itot')
%                     temp_MyVar_title = 'Govt. to Total Inv. (I_g / (I_g + I_p))';
%                 elseif strcmp(var4_choice,'Ip_Itot')
%                     temp_MyVar_title = 'Priv. to Total Inv. (I_p / (I_g + I_p))';
%                 elseif strcmp(var4_choice,'Ig_Y')
%                     temp_MyVar_title = 'Govt. to GDP (I_g / Y)';
%                     temp_MyVar_title = 'I_g / Y';
%                 elseif strcmp(var4_choice,'Ig_less_def_Y')
%                     temp_MyVar_title = 'Govt. to GDP (I_g / Y)';
%                     temp_MyVar_title = 'I_g_,_n_o_n_d_e_f / Y';                                
%                 elseif strcmp(var4_choice,'Ig_real')
%                     temp_MyVar_title = 'Govt. Inv. (log(I_g))';
%                 elseif strcmp(var4_choice,'Ip_real')
%                     temp_MyVar_title = 'Priv. Total Inv. (log(I_p))';
%                     temp_MyVar_title = 'log(I_p)';
%                 elseif strcmp(var4_choice,'IPPrnd_real')
%                     temp_MyVar_title = 'Priv. R&D Inv. (log(I_R_&_D))';
%                     temp_MyVar_title = 'log(I_R_&_D)';
%                 elseif strcmp(var4_choice,'labor_share_govt')
%                     temp_MyVar_title = 'Govt. Labor Share (L_g / (L_g + L_p))';            
%                     temp_MyVar_title = 'L_g / (L_g + L_p)';            
%                 elseif strcmp(var4_choice,'labor_share_priv')
%                     temp_MyVar_title = 'Private Labor Share (L_p / (L_g + L_p))';              
%                     temp_MyVar_title = 'L_p / (L_g + L_p)';              
%                 elseif strcmp(var4_choice,'labor_govt')
%                     temp_MyVar_title = 'Govt. Labor (log(L_g))';            
%                     temp_MyVar_title = 'log(L_g)';            
%                 elseif strcmp(var4_choice,'labor_priv')
%                     temp_MyVar_title = 'Private Labor (log(L_p))';
%                     temp_MyVar_title = 'log(L_p)';
%                 else
%                     error('var4_choice not recognized');        
%                 end    
%             end

            eval(strcat('mytitle_',num2str(vvv),'=temp_MyVar_title;'));

        end % vvv

        % set size of figure so it fills page
        set(gcf, 'PaperPositionMode', 'manual');
        set(gcf, 'PaperUnits', 'inches');
        set(gcf, 'PaperPosition', [0 0 14.00 7.00]);            
        %set(gcf, 'PaperPosition', [0 0 7.00 3.50]); % 1x2 plot

        %IRF_length_plot = std_IRF_length_qtr+1;
        % per May 18 2019 call with max, change length of IRF to 20 
        % periods when comparing data vs model
        IRF_length_plot = std_IRF_length_qtr+1-4;    

        subplot(2,3,1); hold on; box on;
        plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
        plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_1.oirf_var4(1:IRF_length_plot), '-b', 'Linewidth', 2);
            plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_1.oirf_var4_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
            plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_1.oirf_var4_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);        
        plot(0:IRF_length_plot-1, 100*prctile(pan1_oirf_var4(:,1:IRF_length_plot),50), '-r', 'Linewidth', 2);
            plot(0:IRF_length_plot-1, 100*prctile(pan1_oirf_var4(:,1:IRF_length_plot),25), '--r', 'Linewidth', 1);
            plot(0:IRF_length_plot-1, 100*prctile(pan1_oirf_var4(:,1:IRF_length_plot),75), '--r', 'Linewidth', 1);
        plot(0:IRF_length_plot-1, 100*model_IRF_vol_line_1(1:IRF_length_plot), ':g', 'Linewidth', 3);
        title(strcat('\fontsize{12}',mytitle_1),'FontWeight','normal');
        xlabel(' ');
        ylabel('Percent');               
        axis('tight');
        %ylim(My_Ylims_c1);

        subplot(2,3,2); hold on; box on;
        plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
        plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_2.oirf_var4(1:IRF_length_plot), '-b', 'Linewidth', 2);
            plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_2.oirf_var4_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
            plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_2.oirf_var4_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);        
        plot(0:IRF_length_plot-1, 100*prctile(pan2_oirf_var4(:,1:IRF_length_plot),50), '-r', 'Linewidth', 2);
            plot(0:IRF_length_plot-1, 100*prctile(pan2_oirf_var4(:,1:IRF_length_plot),25), '--r', 'Linewidth', 1);
            plot(0:IRF_length_plot-1, 100*prctile(pan2_oirf_var4(:,1:IRF_length_plot),75), '--r', 'Linewidth', 1);
        plot(0:IRF_length_plot-1, 100*model_IRF_vol_line_2(1:IRF_length_plot), ':g', 'Linewidth', 3);
        title(strcat('\fontsize{12}',mytitle_2),'FontWeight','normal');
        xlabel(' ');
        %ylabel(temp_MyVar_ylabel);               
        axis('tight');
        %ylim(My_Ylims_c2);

        subplot(2,3,3); hold on; box on;
        plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
        h(1) = plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_3.oirf_var4(1:IRF_length_plot), '-b', 'Linewidth', 2);
            plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_3.oirf_var4_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
            plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_3.oirf_var4_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);        
        h(2) = plot(0:IRF_length_plot-1, 100*prctile(pan3_oirf_var4(:,1:IRF_length_plot),50), '-r', 'Linewidth', 2);
            plot(0:IRF_length_plot-1, 100*prctile(pan3_oirf_var4(:,1:IRF_length_plot),25), '--r', 'Linewidth', 1);
            plot(0:IRF_length_plot-1, 100*prctile(pan3_oirf_var4(:,1:IRF_length_plot),75), '--r', 'Linewidth', 1);
        h(3) = plot(0:IRF_length_plot-1, 100*model_IRF_vol_line_3(1:IRF_length_plot), ':g', 'Linewidth', 3);
        title(strcat('\fontsize{12}',mytitle_3),'FontWeight','normal');
        xlabel(' ');
        %ylabel(temp_MyVar_ylabel);               
        axis('tight');
        %ylim(My_Ylims_c3);                  
        legend(h,'Data','Sim. Data','Model','Location','northeast');
        clear h;

        subplot(2,3,4); hold on; box on;
        plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
        plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_4.oirf_var4(1:IRF_length_plot), '-b', 'Linewidth', 2);
            plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_4.oirf_var4_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
            plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_4.oirf_var4_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);        
        plot(0:IRF_length_plot-1, 100*prctile(pan4_oirf_var4(:,1:IRF_length_plot),50), '-r', 'Linewidth', 2);
            plot(0:IRF_length_plot-1, 100*prctile(pan4_oirf_var4(:,1:IRF_length_plot),25), '--r', 'Linewidth', 1);
            plot(0:IRF_length_plot-1, 100*prctile(pan4_oirf_var4(:,1:IRF_length_plot),75), '--r', 'Linewidth', 1);
        plot(0:IRF_length_plot-1, 100*model_IRF_vol_line_4(1:IRF_length_plot), ':g', 'Linewidth', 3);
        title(strcat('\fontsize{12}',mytitle_4),'FontWeight','normal');
        xlabel(' ');
        ylabel('Percent');               
        axis('tight');
        %ylim(My_Ylims_c4);

        subplot(2,3,5); hold on; box on;
        plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
        h(1) = plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_5.oirf_var4(1:IRF_length_plot), '-b', 'Linewidth', 2);
            plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_5.oirf_var4_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
            plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_5.oirf_var4_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);        
        plot(0:IRF_length_plot-1, 100*prctile(pan5_oirf_var4(:,1:IRF_length_plot),50), '-r', 'Linewidth', 2);
            plot(0:IRF_length_plot-1, 100*prctile(pan5_oirf_var4(:,1:IRF_length_plot),25), '--r', 'Linewidth', 1);
            plot(0:IRF_length_plot-1, 100*prctile(pan5_oirf_var4(:,1:IRF_length_plot),75), '--r', 'Linewidth', 1);
        h(2) = plot(0:IRF_length_plot-1, 100*model_IRF_vol_line_5(1:IRF_length_plot), ':g', 'Linewidth', 3);
        title(strcat('\fontsize{12}',mytitle_5),'FontWeight','normal');
        xlabel(' ');
        %ylabel(temp_MyVar_ylabel);               
        axis('tight');
        %ylim(My_Ylims_c5);   
        %legend(h,'Data','Model','FontSize',14,'Position',[0.75 0.25 0.08 0.1]);
        clear h;

        subplot(2,3,6); hold on; box on;
        plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
        h(1) = plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_6.oirf_var4(1:IRF_length_plot), '-b', 'Linewidth', 2);
            plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_6.oirf_var4_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
            plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_6.oirf_var4_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);        
        plot(0:IRF_length_plot-1, 100*prctile(pan6_oirf_var4(:,1:IRF_length_plot),50), '-r', 'Linewidth', 2);
            plot(0:IRF_length_plot-1, 100*prctile(pan6_oirf_var4(:,1:IRF_length_plot),25), '--r', 'Linewidth', 1);
            plot(0:IRF_length_plot-1, 100*prctile(pan6_oirf_var4(:,1:IRF_length_plot),75), '--r', 'Linewidth', 1);
        h(2) = plot(0:IRF_length_plot-1, 100*model_IRF_vol_line_6(1:IRF_length_plot), ':g', 'Linewidth', 3);
        title(strcat('\fontsize{12}',mytitle_6),'FontWeight','normal');
        xlabel(' ');
        %ylabel(temp_MyVar_ylabel);               
        axis('tight');
        %ylim(My_Ylims_c6);       

        % save jpg        
        saveas(2,strcat('figures/',fname),'png')
        saveas(2,strcat('figures/',fname)) 
        %saveas(1,strcat('output_for_paper/Figures/',fname),'png')
        %saveas(1,strcat('output_for_paper/Figures/',fname))                     
        close(2)                           
        
        

        
    % repeat but use mean and plus minus 1.3 SEs
    close ALL
    figure(2);
    
        fname = strcat('IRFs_OnlyVol_model_',num2str(my_modnum),'_irf_vs_simdataVAR_mean_pm_',num2str(SE_band_size*100),'bp_SE_data_',myVARspec,'_control_',myccvar,'_2x3_',char(var_set{1}),'_',char(var_set{2}),'_',char(var_set{3}),'_',char(var_set{4}),'_',char(var_set{5}),'_',char(var_set{6}));    

        % panel titles
        for vvv = 1:length(var_set)    

            var4_choice = var_set{vvv}; 

            %if alt_panel_titles==1 
                if strcmp(var4_choice,'Yp_real')
                    temp_MyVar_title = 'log(Y_H)';
                elseif strcmp(var4_choice,'Ig_Y')
                    temp_MyVar_title = 'I_L / Y';
                elseif strcmp(var4_choice,'Ig_real')
                    temp_MyVar_title = 'log(I_L)';
                elseif strcmp(var4_choice,'Ip_real')
                    temp_MyVar_title = 'log(I_H)';
                elseif strcmp(var4_choice,'IPPrnd_real')
                    temp_MyVar_title = 'log(I_R_&_D)';
                elseif strcmp(var4_choice,'labor_share_govt')
                    temp_MyVar_title = 'L_L / (L_L + L_H))';            
                elseif strcmp(var4_choice,'labor_share_priv')
                    temp_MyVar_title = 'L_H / (L_L + L_H)';
                elseif strcmp(var4_choice,'labor_govt')
                    temp_MyVar_title = 'log(L_L)';            
                elseif strcmp(var4_choice,'labor_priv')
                    temp_MyVar_title = 'log(L_H)';                                          
                else
                    error('var4_choice not recognized');        
                end              
%             else
%                 if strcmp(var4_choice,'Yp_real')
%                     temp_MyVar_title = 'Priv. Output (log(Y_p))';
%                     temp_MyVar_title = 'log(Y_p)';
%                 elseif strcmp(var4_choice,'Ig_Itot')
%                     temp_MyVar_title = 'Govt. to Total Inv. (I_g / (I_g + I_p))';
%                 elseif strcmp(var4_choice,'Ip_Itot')
%                     temp_MyVar_title = 'Priv. to Total Inv. (I_p / (I_g + I_p))';
%                 elseif strcmp(var4_choice,'Ig_Y')
%                     temp_MyVar_title = 'Govt. to GDP (I_g / Y)';
%                     temp_MyVar_title = 'I_g / Y';
%                 elseif strcmp(var4_choice,'Ig_less_def_Y')
%                     temp_MyVar_title = 'Govt. to GDP (I_g / Y)';
%                     temp_MyVar_title = 'I_g_,_n_o_n_d_e_f / Y';                                
%                 elseif strcmp(var4_choice,'Ig_real')
%                     temp_MyVar_title = 'Govt. Inv. (log(I_g))';
%                 elseif strcmp(var4_choice,'Ip_real')
%                     temp_MyVar_title = 'Priv. Total Inv. (log(I_p))';
%                     temp_MyVar_title = 'log(I_p)';
%                 elseif strcmp(var4_choice,'IPPrnd_real')
%                     temp_MyVar_title = 'Priv. R&D Inv. (log(I_R_&_D))';
%                     temp_MyVar_title = 'log(I_R_&_D)';
%                 elseif strcmp(var4_choice,'labor_share_govt')
%                     temp_MyVar_title = 'Govt. Labor Share (L_g / (L_g + L_p))';            
%                     temp_MyVar_title = 'L_g / (L_g + L_p)';            
%                 elseif strcmp(var4_choice,'labor_share_priv')
%                     temp_MyVar_title = 'Private Labor Share (L_p / (L_g + L_p))';              
%                     temp_MyVar_title = 'L_p / (L_g + L_p)';              
%                 elseif strcmp(var4_choice,'labor_govt')
%                     temp_MyVar_title = 'Govt. Labor (log(L_g))';            
%                     temp_MyVar_title = 'log(L_g)';            
%                 elseif strcmp(var4_choice,'labor_priv')
%                     temp_MyVar_title = 'Private Labor (log(L_p))';
%                     temp_MyVar_title = 'log(L_p)';
%                 else
%                     error('var4_choice not recognized');        
%                 end    
%             end

            eval(strcat('mytitle_',num2str(vvv),'=temp_MyVar_title;'));

        end % vvv

        % set size of figure so it fills page
        set(gcf, 'PaperPositionMode', 'manual');
        set(gcf, 'PaperUnits', 'inches');
        set(gcf, 'PaperPosition', [0 0 14.00 7.00]);            
        %set(gcf, 'PaperPosition', [0 0 7.00 3.50]); % 1x2 plot

        %IRF_length_plot = std_IRF_length_qtr+1;
        % per May 18 2019 call with max, change length of IRF to 20 
        % periods when comparing data vs model
        IRF_length_plot = std_IRF_length_qtr+1-4;    

        subplot(2,3,1); hold on; box on;
        plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
        plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_1.oirf_var4(1:IRF_length_plot), '-b', 'Linewidth', 2);
            plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_1.oirf_var4_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
            plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_1.oirf_var4_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);        
        plot(0:IRF_length_plot-1, 100*mean(pan1_oirf_var4(:,1:IRF_length_plot)), '-r', 'Linewidth', 2);
            plot(0:IRF_length_plot-1, 100*(mean(pan1_oirf_var4(:,1:IRF_length_plot))-SE_band_size*std(pan1_oirf_var4(:,1:IRF_length_plot))), '--r', 'Linewidth', 1);
            plot(0:IRF_length_plot-1, 100*(mean(pan1_oirf_var4(:,1:IRF_length_plot))+SE_band_size*std(pan1_oirf_var4(:,1:IRF_length_plot))), '--r', 'Linewidth', 1);
        plot(0:IRF_length_plot-1, 100*model_IRF_vol_line_1(1:IRF_length_plot), ':g', 'Linewidth', 3);
        title(strcat('\fontsize{12}',mytitle_1),'FontWeight','normal');
        xlabel(' ');
        ylabel('Percent');               
        axis('tight');
        %ylim(My_Ylims_c1);

        subplot(2,3,2); hold on; box on;
        plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
        plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_2.oirf_var4(1:IRF_length_plot), '-b', 'Linewidth', 2);
            plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_2.oirf_var4_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
            plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_2.oirf_var4_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);        
        plot(0:IRF_length_plot-1, 100*mean(pan2_oirf_var4(:,1:IRF_length_plot)), '-r', 'Linewidth', 2);
            plot(0:IRF_length_plot-1, 100*(mean(pan2_oirf_var4(:,1:IRF_length_plot))-SE_band_size*std(pan2_oirf_var4(:,1:IRF_length_plot))), '--r', 'Linewidth', 1);
            plot(0:IRF_length_plot-1, 100*(mean(pan2_oirf_var4(:,1:IRF_length_plot))+SE_band_size*std(pan2_oirf_var4(:,1:IRF_length_plot))), '--r', 'Linewidth', 1);
        plot(0:IRF_length_plot-1, 100*model_IRF_vol_line_2(1:IRF_length_plot), ':g', 'Linewidth', 3);
        title(strcat('\fontsize{12}',mytitle_2),'FontWeight','normal');
        xlabel(' ');
        %ylabel(temp_MyVar_ylabel);               
        axis('tight');
        %ylim(My_Ylims_c2);

        subplot(2,3,3); hold on; box on;
        plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
        h(1) = plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_3.oirf_var4(1:IRF_length_plot), '-b', 'Linewidth', 2);
            plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_3.oirf_var4_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
            plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_3.oirf_var4_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);        
        h(2) = plot(0:IRF_length_plot-1, 100*mean(pan3_oirf_var4(:,1:IRF_length_plot)), '-r', 'Linewidth', 2);
            plot(0:IRF_length_plot-1, 100*(mean(pan3_oirf_var4(:,1:IRF_length_plot))-SE_band_size*std(pan3_oirf_var4(:,1:IRF_length_plot))), '--r', 'Linewidth', 1);
            plot(0:IRF_length_plot-1, 100*(mean(pan3_oirf_var4(:,1:IRF_length_plot))+SE_band_size*std(pan3_oirf_var4(:,1:IRF_length_plot))), '--r', 'Linewidth', 1);
        h(3) = plot(0:IRF_length_plot-1, 100*model_IRF_vol_line_3(1:IRF_length_plot), ':g', 'Linewidth', 3);
        title(strcat('\fontsize{12}',mytitle_3),'FontWeight','normal');
        xlabel(' ');
        %ylabel(temp_MyVar_ylabel);               
        axis('tight');
        %ylim(My_Ylims_c3);                  
        legend(h,'Data','Sim. Data','Model','Location','northeast');
        clear h;

        subplot(2,3,4); hold on; box on;
        plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
        plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_4.oirf_var4(1:IRF_length_plot), '-b', 'Linewidth', 2);
            plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_4.oirf_var4_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
            plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_4.oirf_var4_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);        
        plot(0:IRF_length_plot-1, 100*mean(pan4_oirf_var4(:,1:IRF_length_plot)), '-r', 'Linewidth', 2);
            plot(0:IRF_length_plot-1, 100*(mean(pan4_oirf_var4(:,1:IRF_length_plot))-SE_band_size*std(pan4_oirf_var4(:,1:IRF_length_plot))), '--r', 'Linewidth', 1);
            plot(0:IRF_length_plot-1, 100*(mean(pan4_oirf_var4(:,1:IRF_length_plot))+SE_band_size*std(pan4_oirf_var4(:,1:IRF_length_plot))), '--r', 'Linewidth', 1);
        plot(0:IRF_length_plot-1, 100*model_IRF_vol_line_4(1:IRF_length_plot), ':g', 'Linewidth', 3);
        title(strcat('\fontsize{12}',mytitle_4),'FontWeight','normal');
        xlabel(' ');
        ylabel('Percent');               
        axis('tight');
        %ylim(My_Ylims_c4);

        subplot(2,3,5); hold on; box on;
        plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
        h(1) = plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_5.oirf_var4(1:IRF_length_plot), '-b', 'Linewidth', 2);
            plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_5.oirf_var4_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
            plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_5.oirf_var4_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);        
        plot(0:IRF_length_plot-1, 100*mean(pan5_oirf_var4(:,1:IRF_length_plot)), '-r', 'Linewidth', 2);
            plot(0:IRF_length_plot-1, 100*(mean(pan5_oirf_var4(:,1:IRF_length_plot))-SE_band_size*std(pan5_oirf_var4(:,1:IRF_length_plot))), '--r', 'Linewidth', 1);
            plot(0:IRF_length_plot-1, 100*(mean(pan5_oirf_var4(:,1:IRF_length_plot))+SE_band_size*std(pan5_oirf_var4(:,1:IRF_length_plot))), '--r', 'Linewidth', 1);
        h(2) = plot(0:IRF_length_plot-1, 100*model_IRF_vol_line_5(1:IRF_length_plot), ':g', 'Linewidth', 3);
        title(strcat('\fontsize{12}',mytitle_5),'FontWeight','normal');
        xlabel(' ');
        %ylabel(temp_MyVar_ylabel);               
        axis('tight');
        %ylim(My_Ylims_c5);   
        %legend(h,'Data','Model','FontSize',14,'Position',[0.75 0.25 0.08 0.1]);
        clear h;

        subplot(2,3,6); hold on; box on;
        plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
        h(1) = plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_6.oirf_var4(1:IRF_length_plot), '-b', 'Linewidth', 2);
            plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_6.oirf_var4_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
            plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_6.oirf_var4_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);        
        plot(0:IRF_length_plot-1, 100*mean(pan6_oirf_var4(:,1:IRF_length_plot)), '-r', 'Linewidth', 2);
            plot(0:IRF_length_plot-1, 100*(mean(pan6_oirf_var4(:,1:IRF_length_plot))-SE_band_size*std(pan6_oirf_var4(:,1:IRF_length_plot))), '--r', 'Linewidth', 1);
            plot(0:IRF_length_plot-1, 100*(mean(pan6_oirf_var4(:,1:IRF_length_plot))+SE_band_size*std(pan6_oirf_var4(:,1:IRF_length_plot))), '--r', 'Linewidth', 1);
        h(2) = plot(0:IRF_length_plot-1, 100*model_IRF_vol_line_6(1:IRF_length_plot), ':g', 'Linewidth', 3);
        title(strcat('\fontsize{12}',mytitle_6),'FontWeight','normal');
        xlabel(' ');
        %ylabel(temp_MyVar_ylabel);               
        axis('tight');
        %ylim(My_Ylims_c6);       

        % save jpg        
        saveas(2,strcat('figures/',fname),'png')
        saveas(2,strcat('figures/',fname)) 
        %saveas(1,strcat('output_for_paper/Figures/',fname),'png')
        %saveas(1,strcat('output_for_paper/Figures/',fname))                     
        close(2)                           
        
        

    % repeat but remove model IRF regular and use mean and plus minus 1.3
    % SEs and shade between lines
    close ALL
    figure(2);
    
        fname = strcat('IRFs_OnlyVol_model_',num2str(my_modnum),'_irf_vs_simdataVAR_mean_pm_',num2str(SE_band_size*100),'bp_SE_data_with_shading_',myVARspec,'_control_',myccvar,'_2x3_',char(var_set{1}),'_',char(var_set{2}),'_',char(var_set{3}),'_',char(var_set{4}),'_',char(var_set{5}),'_',char(var_set{6}));    

        % panel titles
        for vvv = 1:length(var_set)    

            var4_choice = var_set{vvv}; 

                if strcmp(var4_choice,'Yp_real')
                    temp_MyVar_title = 'log(Y_H)';
                elseif strcmp(var4_choice,'Ig_Y')
                    temp_MyVar_title = 'I_L / Y';
                elseif strcmp(var4_choice,'Ig_real')
                    temp_MyVar_title = 'log(I_L)';
                elseif strcmp(var4_choice,'Ip_real')
                    temp_MyVar_title = 'log(I_H)';
                elseif strcmp(var4_choice,'IPPrnd_real')
                    temp_MyVar_title = 'log(I_R_&_D)';
                elseif strcmp(var4_choice,'labor_share_govt')
                    temp_MyVar_title = 'L_L / (L_L + L_H))';            
                elseif strcmp(var4_choice,'labor_share_priv')
                    temp_MyVar_title = 'L_H / (L_L + L_H)';
                elseif strcmp(var4_choice,'labor_govt')
                    temp_MyVar_title = 'log(L_L)';            
                elseif strcmp(var4_choice,'labor_priv')
                    temp_MyVar_title = 'log(L_H)';                                          
                else
                    error('var4_choice not recognized');        
                end              

            eval(strcat('mytitle_',num2str(vvv),'=temp_MyVar_title;'));

        end % vvv

        % set size of figure so it fills page
        set(gcf, 'PaperPositionMode', 'manual');
        set(gcf, 'PaperUnits', 'inches');
        set(gcf, 'PaperPosition', [0 0 14.00 7.00]);            
        %set(gcf, 'PaperPosition', [0 0 7.00 3.50]); % 1x2 plot

        %IRF_length_plot = std_IRF_length_qtr+1;
        % per May 18 2019 call with max, change length of IRF to 20 
        % periods when comparing data vs model
        IRF_length_plot = std_IRF_length_qtr+1-4;    

        subplot(2,3,1); hold on; box on;
        plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
        xvals = 0:(IRF_length_plot-1);
        % data
        plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_1.oirf_var4(1:IRF_length_plot), '-b', 'Linewidth', 2);
        lineL = 100*IRFout_ivolshk_qtr_1.oirf_var4_ciL(1:IRF_length_plot);
        lineU = 100*IRFout_ivolshk_qtr_1.oirf_var4_ciU(1:IRF_length_plot);        
        patch([xvals fliplr(xvals)], [lineU fliplr(lineL)], 'b','EdgeColor','none','FaceAlpha',.3);            
        % model-sim
        plot(0:IRF_length_plot-1, 100*mean(pan1_oirf_var4(:,1:IRF_length_plot)), '-r', 'Linewidth', 2);
        lineL = 100*(mean(pan1_oirf_var4(:,1:IRF_length_plot))-SE_band_size*std(pan1_oirf_var4(:,1:IRF_length_plot)));
        lineU = 100*(mean(pan1_oirf_var4(:,1:IRF_length_plot))+SE_band_size*std(pan1_oirf_var4(:,1:IRF_length_plot)));
        patch([xvals fliplr(xvals)], [lineU fliplr(lineL)], 'r','EdgeColor','none','FaceAlpha',.3);                    
        % model
        plot(0:IRF_length_plot-1, 100*model_IRF_vol_line_1(1:IRF_length_plot), ':g', 'Linewidth', 3);
        title(strcat('\fontsize{12}',mytitle_1),'FontWeight','normal');
        xlabel(' ');
        ylabel('Percent');               
        axis('tight');
        %ylim(My_Ylims_c1);

        subplot(2,3,2); hold on; box on;
        plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
        % data
        plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_2.oirf_var4(1:IRF_length_plot), '-b', 'Linewidth', 2);
        lineL = 100*IRFout_ivolshk_qtr_2.oirf_var4_ciL(1:IRF_length_plot);
        lineU = 100*IRFout_ivolshk_qtr_2.oirf_var4_ciU(1:IRF_length_plot);        
        patch([xvals fliplr(xvals)], [lineU fliplr(lineL)], 'b','EdgeColor','none','FaceAlpha',.3);            
        % model-sim
        plot(0:IRF_length_plot-1, 100*mean(pan2_oirf_var4(:,1:IRF_length_plot)), '-r', 'Linewidth', 2);
        lineL = 100*(mean(pan2_oirf_var4(:,1:IRF_length_plot))-SE_band_size*std(pan2_oirf_var4(:,1:IRF_length_plot)));
        lineU = 100*(mean(pan2_oirf_var4(:,1:IRF_length_plot))+SE_band_size*std(pan2_oirf_var4(:,1:IRF_length_plot)));
        patch([xvals fliplr(xvals)], [lineU fliplr(lineL)], 'r','EdgeColor','none','FaceAlpha',.3);                    
        % model
        plot(0:IRF_length_plot-1, 100*model_IRF_vol_line_2(1:IRF_length_plot), ':g', 'Linewidth', 3);
        title(strcat('\fontsize{12}',mytitle_2),'FontWeight','normal');
        xlabel(' ');
        %ylabel(temp_MyVar_ylabel);               
        axis('tight');
        %ylim(My_Ylims_c2);

        subplot(2,3,3); hold on; box on;
        plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
        % data
        h(1) = plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_3.oirf_var4(1:IRF_length_plot), '-b', 'Linewidth', 2);
        lineL = 100*IRFout_ivolshk_qtr_3.oirf_var4_ciL(1:IRF_length_plot);
        lineU = 100*IRFout_ivolshk_qtr_3.oirf_var4_ciU(1:IRF_length_plot);        
        patch([xvals fliplr(xvals)], [lineU fliplr(lineL)], 'b','EdgeColor','none','FaceAlpha',.3);            
        % model-sim
        h(2) = plot(0:IRF_length_plot-1, 100*mean(pan3_oirf_var4(:,1:IRF_length_plot)), '-r', 'Linewidth', 2);
        lineL = 100*(mean(pan3_oirf_var4(:,1:IRF_length_plot))-SE_band_size*std(pan3_oirf_var4(:,1:IRF_length_plot)));
        lineU = 100*(mean(pan3_oirf_var4(:,1:IRF_length_plot))+SE_band_size*std(pan3_oirf_var4(:,1:IRF_length_plot)));
        patch([xvals fliplr(xvals)], [lineU fliplr(lineL)], 'r','EdgeColor','none','FaceAlpha',.3);                    
        % model
        h(3) = plot(0:IRF_length_plot-1, 100*model_IRF_vol_line_3(1:IRF_length_plot), ':g', 'Linewidth', 3);
        title(strcat('\fontsize{12}',mytitle_3),'FontWeight','normal');
        xlabel(' ');
        %ylabel(temp_MyVar_ylabel);               
        axis('tight');
        %ylim(My_Ylims_c3);                  
        legend(h,'Data','Sim. Data','Model','Location','northeast');
        clear h;

        subplot(2,3,4); hold on; box on;
        plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
        % data
        plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_4.oirf_var4(1:IRF_length_plot), '-b', 'Linewidth', 2);
        lineL = 100*IRFout_ivolshk_qtr_4.oirf_var4_ciL(1:IRF_length_plot);
        lineU = 100*IRFout_ivolshk_qtr_4.oirf_var4_ciU(1:IRF_length_plot);        
        patch([xvals fliplr(xvals)], [lineU fliplr(lineL)], 'b','EdgeColor','none','FaceAlpha',.3);            
        % model-sim
        plot(0:IRF_length_plot-1, 100*mean(pan4_oirf_var4(:,1:IRF_length_plot)), '-r', 'Linewidth', 2);
        lineL = 100*(mean(pan4_oirf_var4(:,1:IRF_length_plot))-SE_band_size*std(pan4_oirf_var4(:,1:IRF_length_plot)));
        lineU = 100*(mean(pan4_oirf_var4(:,1:IRF_length_plot))+SE_band_size*std(pan4_oirf_var4(:,1:IRF_length_plot)));
        patch([xvals fliplr(xvals)], [lineU fliplr(lineL)], 'r','EdgeColor','none','FaceAlpha',.3);                    
        % model
        plot(0:IRF_length_plot-1, 100*model_IRF_vol_line_4(1:IRF_length_plot), ':g', 'Linewidth', 3);
        title(strcat('\fontsize{12}',mytitle_4),'FontWeight','normal');
        xlabel(' ');
        ylabel('Percent');               
        axis('tight');
        %ylim(My_Ylims_c4);

        subplot(2,3,5); hold on; box on;
        plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
        % data
        plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_5.oirf_var4(1:IRF_length_plot), '-b', 'Linewidth', 2);
        lineL = 100*IRFout_ivolshk_qtr_5.oirf_var4_ciL(1:IRF_length_plot);
        lineU = 100*IRFout_ivolshk_qtr_5.oirf_var4_ciU(1:IRF_length_plot);        
        patch([xvals fliplr(xvals)], [lineU fliplr(lineL)], 'b','EdgeColor','none','FaceAlpha',.3);            
        % model-sim
        plot(0:IRF_length_plot-1, 100*mean(pan5_oirf_var4(:,1:IRF_length_plot)), '-r', 'Linewidth', 2);
        lineL = 100*(mean(pan5_oirf_var4(:,1:IRF_length_plot))-SE_band_size*std(pan5_oirf_var4(:,1:IRF_length_plot)));
        lineU = 100*(mean(pan5_oirf_var4(:,1:IRF_length_plot))+SE_band_size*std(pan5_oirf_var4(:,1:IRF_length_plot)));
        patch([xvals fliplr(xvals)], [lineU fliplr(lineL)], 'r','EdgeColor','none','FaceAlpha',.3);                    
        % model
        plot(0:IRF_length_plot-1, 100*model_IRF_vol_line_5(1:IRF_length_plot), ':g', 'Linewidth', 3);
        title(strcat('\fontsize{12}',mytitle_5),'FontWeight','normal');
        xlabel(' ');
        %ylabel(temp_MyVar_ylabel);               
        axis('tight');
        %ylim(My_Ylims_c5);   
        %legend(h,'Data','Model','FontSize',14,'Position',[0.75 0.25 0.08 0.1]);
        clear h;

        subplot(2,3,6); hold on; box on;
        plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
        % data
        plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_6.oirf_var4(1:IRF_length_plot), '-b', 'Linewidth', 2);
        lineL = 100*IRFout_ivolshk_qtr_6.oirf_var4_ciL(1:IRF_length_plot);
        lineU = 100*IRFout_ivolshk_qtr_6.oirf_var4_ciU(1:IRF_length_plot);        
        patch([xvals fliplr(xvals)], [lineU fliplr(lineL)], 'b','EdgeColor','none','FaceAlpha',.3);            
        % model-sim
        plot(0:IRF_length_plot-1, 100*mean(pan6_oirf_var4(:,1:IRF_length_plot)), '-r', 'Linewidth', 2);
        lineL = 100*(mean(pan6_oirf_var4(:,1:IRF_length_plot))-SE_band_size*std(pan6_oirf_var4(:,1:IRF_length_plot)));
        lineU = 100*(mean(pan6_oirf_var4(:,1:IRF_length_plot))+SE_band_size*std(pan6_oirf_var4(:,1:IRF_length_plot)));
        patch([xvals fliplr(xvals)], [lineU fliplr(lineL)], 'r','EdgeColor','none','FaceAlpha',.3);                    
        % model
        plot(0:IRF_length_plot-1, 100*model_IRF_vol_line_6(1:IRF_length_plot), ':g', 'Linewidth', 3);
        title(strcat('\fontsize{12}',mytitle_6),'FontWeight','normal');
        xlabel(' ');
        %ylabel(temp_MyVar_ylabel);               
        axis('tight');
        %ylim(My_Ylims_c6);       

        % save jpg        
        saveas(2,strcat('figures/',fname),'png')
        saveas(2,strcat('figures/',fname)) 
        %saveas(1,strcat('output_for_paper/Figures/',fname),'png')
        %saveas(1,strcat('output_for_paper/Figures/',fname))                     
        close(2)                         



%%
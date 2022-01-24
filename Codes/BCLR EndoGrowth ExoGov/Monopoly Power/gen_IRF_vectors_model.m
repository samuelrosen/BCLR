% function model_out = gen_IRF_vectors_model( mod_num, expvol_init, expvol_irf_vals, shk_type, all_shks_mat)
% Generate the IRF vector to the sequence of vol shocks observed in the
% great recession using model equations

    % mat file data path (may change in the future but should be obvious)
    %MyMat = strcat('../Monopoly Power Lower Gov TFP/Results/Monopoly_Power_Approx_',num2str(mod_num),'/Monopoly_Power_Approx_',num2str(mod_num),'_short.mat'); 
    %MyMat_for_simul = strcat('../Monopoly'' Power Lower Gov TFP''/Results/Monopoly_Power_Approx_',num2str(mod_num),'/Monopoly_Power_Approx_',num2str(mod_num),'_short.mat');
    %MyMat = strcat('../Monopoly Power Lower Gov TFP/Results/Monopoly_Power_Approx_',num2str(mod_num),'/Monopoly_Power_Approx_',num2str(mod_num),'.mat'); 
    %MyMat_for_simul = strcat('../Monopoly'' Power Lower Gov TFP''/Results/Monopoly_Power_Approx_',num2str(mod_num),'/Monopoly_Power_Approx_',num2str(mod_num),'.mat');
    % SAM: change path here to
    % "C:\Users\Samuel\Dropbox\Research\BCLR\1_SafeCapital\Codes\BCLR EndoGrowth\Results"
    mod_num = 105;
     % std volatility level shock
     std_IRF_length_qtr = 24;
            vol_shk_lev_mat_qtr      = zeros(2 , std_IRF_length_qtr);
            vol_shk_lev_mat_qtr(2,1) = 0.1983;
    all_shks_mat = vol_shk_lev_mat_qtr;
    MyMat_for_simul           =     strcat('D:\Dropbox\BCLR\1_SafeCapital\Codes\BCLR EndoGrowth\Results\Monopoly_Power_Approx_',num2str(mod_num),'\Monopoly_Power_Approx_',num2str(mod_num),'.mat'); 
%     MyMat_for_simul = strcat('D:\Dropbox\BCLR\1_SafeCapital\Codes\BCLR EndoGrowth\Results\Monopoly_Power_Approx_',num2str(mod_num),'\Monopoly_Power_Approx_',num2str(mod_num),'.mat'); 
    
    % import model data and parameters from mat file
%     load(MyMat);
    
    % recover shocks from great recession if needed
%     if nargin==3
%     
%         % initial value in logs
%         vol1 = log(expvol_init); 
%         
%         % we want to find e such that
%         % exp( rhovol*vol_model(t-1) + es(t) ) - exp( rhovol^(t-1)*vol1 ) = expvol_irf_vals(t)
%         clear vol_model_none vol_model_shk vol_model_none es;
%         for t=1:length(expvol_irf_vals)
%             if t==1
%                 vol_model_none(t) = vol1;
%                 vol_model_shk(t) = vol1;
%                 es(t) = 0;
%             else
%                 vol_model_none(t) = rhovol^(t-1)*vol1;
%                 % alternate: "vol_model_none(t) = rhovol*vol_model_none(t-1)";
%                 es(t) = log( expvol_irf_vals(t) + exp(vol_model_none(t)) ) - rhovol*vol_model_shk(t-1);
%                 vol_model_shk(t) = rhovol*vol_model_shk(t-1) + es(t);
%             end            
%         end
%         
%         % check that these are equal
%         %exp(vol_model_shk) - exp(vol_model_none)
%         %expvol_irf_vals
%         
%         % determine IRF length
%         IRF_length = length(expvol_irf_vals)-1;         
%         
%         % initial value for dynare_simul in loop below is the model SS but
%         % change vol to match the initial value in data
%         my_dyn_irf_start = dyn_ss; % start with basic
%         my_dyn_irf_start(dyn_i_vol) = log(expvol_init);     
%         
%         % start with first real shock for es so have es(2:end)
%         %shocks = [zeros(1,IRF_length); zeros(1,IRF_length); es(2:end)];
%         shocks = [zeros(1,IRF_length); es(2:end)];
%         
%     elseif nargin>3
%         
%         % determine IRF length
%         IRF_length = size(all_shks_mat,2);
%         
%         % initial value for dynare_simul is just stoch SS
%         my_dyn_irf_start = dyn_ss; % start with basic             
%                 
%         % multiply the values in shocks if they are meant to represent the
%         % number of standard deviations
%         if strcmp(shk_type,'std')
%             if size(all_shks_mat,1)==size(vcov)
%                 for j=1:size(all_shks_mat,1)
%                     shocks(j,:) = shocks(j,:)*sqrt(vcov(j,j));
%                 end
%             else
%                 % if user inputs a matrix of shocks, it should match the
%                 % number of shocks in the model to feel confident the
%                 % intended sequence of shocks is in the correct row
%                 error('error: more shocks in model than in all_shks_mat');
%             end
%             clear j;
%         elseif strcmp(shk_type,'lev')
%         % otherwise initialize shocks as if the shock values are levels. 
%         % remember that the shocks input into dynare_simul are treated as 
%         % the level of the shocks, not the number of standard deviations            
%             shocks = all_shks_mat;
%         else
%             error('shk_type must be std or lev');
%         end
%                
%     else
%         error('need at least 3 input arguments');
%     end
%         % determine IRF length
        IRF_length = size(all_shks_mat,2);
%         
%         % initial value for dynare_simul is just stoch SS
        my_dyn_irf_start = dyn_ss; % start with basic   
      shocks = all_shks_mat;

    
    % generate all IRF vectors for recovered es shocks using dynare_simul
        
        dyn_irfp_shks = dynare_simul(MyMat_for_simul, shocks,              my_dyn_irf_start);     
        %dyn_irfp_none = dynare_simul(MyMat_for_simul, zeros(3,IRF_length), my_dyn_irf_start);
        dyn_irfp_none = dynare_simul(MyMat_for_simul, zeros(2,IRF_length), my_dyn_irf_start);
        
        
    % pull out specific variables of interest

        resp_expvol_shks = exp(dyn_irfp_shks(dyn_i_vol,:));
        resp_expvol_none = exp(dyn_irfp_none(dyn_i_vol,:));
        
        resp_da_shks = dyn_irfp_shks(dyn_i_da,:);
        resp_da_none = dyn_irfp_none(dyn_i_da,:);        
    
        resp_logC_shks = cumsum(dyn_irfp_shks(dyn_i_dc,:));
        resp_logC_none = cumsum(dyn_irfp_none(dyn_i_dc,:));
        
        resp_logIp_shks = cumsum(dyn_irfp_shks(dyn_i_dip,:));
        resp_logIp_none = cumsum(dyn_irfp_none(dyn_i_dip,:));                      
        
        %resp_logY_shks = cumsum(dyn_irfp_shks(dyn_i_dy,:));
        %resp_logY_none = cumsum(dyn_irfp_none(dyn_i_dy,:)); 
        % note: in june 2017, we change BCLR EndoGrowth where dgdp now represents
        % aggregate output instead of dy
        resp_logY_shks = cumsum(dyn_irfp_shks(dyn_i_dgdp,:));
        resp_logY_none = cumsum(dyn_irfp_none(dyn_i_dgdp,:));         
        
        resp_logYp_shks = cumsum(dyn_irfp_shks(dyn_i_dyp,:));
        resp_logYp_none = cumsum(dyn_irfp_none(dyn_i_dyp,:));         
        
        resp_logIPPrnd_shks = cumsum(dyn_irfp_shks(dyn_i_ds,:));
        resp_logIPPrnd_none = cumsum(dyn_irfp_none(dyn_i_ds,:));        
        
        % computation for govt investment is a bit more complicated because
        % only model variable Ic is in levels and standardized by productivity

            A_shks = exp(cumsum(dyn_irfp_shks(dyn_i_da,:)));
            A_none = exp(cumsum(dyn_irfp_none(dyn_i_da,:)));

            resp_logIg_shks = log( dyn_irfp_shks(dyn_i_Ic,:).*[1, A_shks(1:end-1)] );
            resp_logIg_none = log( dyn_irfp_none(dyn_i_Ic,:).*[1, A_none(1:end-1)] );

            % note that Ig can be negative but above calcs work as long as it
            % does not in the sample        
        
%         resp_C_Y_shks = exp(dyn_irfp_shks(dyn_i_ca,:)-dyn_irfp_shks(dyn_i_ya,:));
%         resp_C_Y_none = exp(dyn_irfp_none(dyn_i_ca,:)-dyn_irfp_none(dyn_i_ya,:));
%         
%         resp_Ip_Y_shks = exp(dyn_irfp_shks(dyn_i_ipa,:)-dyn_irfp_shks(dyn_i_ya,:));
%         resp_Ip_Y_none = exp(dyn_irfp_none(dyn_i_ipa,:)-dyn_irfp_none(dyn_i_ya,:));        
% 
%         resp_Ig_Y_shks = dyn_irfp_shks(dyn_i_Ic,:)./exp(dyn_irfp_shks(dyn_i_ya,:));
%         resp_Ig_Y_none = dyn_irfp_none(dyn_i_Ic,:)./exp(dyn_irfp_none(dyn_i_ya,:));                

        % note: in june 2017, we change BCLR EndoGrowth where gdp now 
        % represents aggregate output standardized by productivity
        % instead of ya
        
        resp_C_Y_shks = exp(dyn_irfp_shks(dyn_i_ca,:)-dyn_irfp_shks(dyn_i_gdp,:));
        resp_C_Y_none = exp(dyn_irfp_none(dyn_i_ca,:)-dyn_irfp_none(dyn_i_gdp,:));
        
        resp_Ip_Y_shks = exp(dyn_irfp_shks(dyn_i_ipa,:)-dyn_irfp_shks(dyn_i_gdp,:));
        resp_Ip_Y_none = exp(dyn_irfp_none(dyn_i_ipa,:)-dyn_irfp_none(dyn_i_gdp,:));        

        resp_Ig_Y_shks = dyn_irfp_shks(dyn_i_Ic,:)./exp(dyn_irfp_shks(dyn_i_gdp,:));
        resp_Ig_Y_none = dyn_irfp_none(dyn_i_Ic,:)./exp(dyn_irfp_none(dyn_i_gdp,:));                        
        
        resp_Ig_Itot_shks = dyn_irfp_shks(dyn_i_Ic,:)./( dyn_irfp_shks(dyn_i_Ic,:) + exp(dyn_irfp_shks(dyn_i_ipa,:)) );
        resp_Ig_Itot_none = dyn_irfp_none(dyn_i_Ic,:)./( dyn_irfp_none(dyn_i_Ic,:) + exp(dyn_irfp_none(dyn_i_ipa,:)) );
    
        
        % growth rates
        resp_dip_shks = dyn_irfp_shks(dyn_i_dip,:);
        resp_dip_none = dyn_irfp_none(dyn_i_dip,:);                      
        
        
    % compute IRF vectors as difference between responses to shks and none
    for MyVar = {'expvol','da','logC','logIp','logY', 'logYp','logIPPrnd','logIg','C_Y','Ip_Y','Ig_Y','Ig_Itot','dip'}

        % quarterly values
        eval(strcat('diff = resp_',char(MyVar),'_shks - resp_',char(MyVar),'_none;'));
        eval(strcat('model_out.oirf_',char(MyVar),' = [0, diff];'));
        
    end

    % time aggregate quarterly log level quantities to annual (sum the
    % values for each year because we want the total quantity value 
    % within the year)
    for MyVar = {'logC','logIp','logY','logYp','logIPPrnd','logIg'}

        num_years = floor(IRF_length/4);
        for tt=1:num_years
            idx = (tt-1)*4+1; % index of the vector corresponding to first quarterly obs in a year
            eval(strcat('ann_resp_shks(tt) = log(sum(exp(resp_',char(MyVar),'_shks(idx:(idx+3)))));'));
            eval(strcat('ann_resp_none(tt) = log(sum(exp(resp_',char(MyVar),'_none(idx:(idx+3)))));'));
            ann_diff(tt) = ann_resp_shks(tt) - ann_resp_none(tt);
        end
        eval(strcat('model_out.oirf_',char(MyVar),'_ta_to_ann = [0, ann_diff];'));
        clear ann_resp_shks ann_resp_none ann_diff;
        
    end    
    
    % time aggregate quarterly ratio levels to annual (choose last
    % quarterly value for each year)
    for MyVar = {'C_Y','Ip_Y','Ig_Y','Ig_Itot'}

        num_years = floor(IRF_length/4);
        for tt=1:num_years
            idx = (tt-1)*4+1; % index of the vector corresponding to first quarterly obs in a year
            eval(strcat('ann_resp_shks(tt) = resp_',char(MyVar),'_shks(idx+3);'));
            eval(strcat('ann_resp_none(tt) = resp_',char(MyVar),'_none(idx+3);'));
            ann_diff(tt) = ann_resp_shks(tt) - ann_resp_none(tt);
        end
        eval(strcat('model_out.oirf_',char(MyVar),'_ta_to_ann = [0, ann_diff];'));
        clear ann_resp_shks ann_resp_none ann_diff;
        
    end        
    
    % cumulative IRF vectors for quantities
    for MyVar = {'logC','logIp','logY','logYp','logIPPrnd','logIg'}
        
        % quarterly values
        eval(strcat('cum_diff = log(cumsum(exp(resp_',char(MyVar),'_shks))) - log(cumsum(exp(resp_',char(MyVar),'_none)));'));
        eval(strcat('model_out.coirf_',char(MyVar),' = [0, cum_diff];'));
        
    end    

        
% end


global fname stoch_vol_switch
global simul_fast  % MAX ADD
global gold_switch % SAM ADD
global psi gam beta % SAM ADD
global ep_cov_calc_switch conditional_moments_switch irf_sim pdratio % SAM ADD
load(strcat(fname,'.mat'));




%% Calculate steady states for new variables
dyn_steady_states=fill_dyn(dyn_steady_states);

%% Options for this part
seed=934098; % starting seed
LEVERAGE = 3;

per=400; %840; % Number of periods for time series shocks

Nn = 1000;     % Maximum number of conditional draws 
Ncross  = 250; % min(250, Nn/2); % number of draws effectively used SUGGESTED: 250

T = 10;%80;  % Number periods conditional moment time series. Maximum of 100 

if conditional_moments_switch == 1
    nsim = 1;     % number of simulations    
else 
    nsim = 100;   % number of simulations
end

if simul_fast ==1
    nsim    = 10;
    per     = 100;%4000 work for exo, 800 works for both with 100 sim
    Ncross  = 250;
end

disp(char(strcat({'num periods for time series shocks is set to '},num2str(per))))
disp(char(strcat({'Ncross is set to '},num2str(Ncross))))
disp(char(strcat({'nsim currently set at '},num2str(nsim)))) % SAM ADD

%% Draw time series and cross-sectional shocks
    
    randn('state',seed); %#ok<RAND>

    if sum([stoch_vol_switch,gold_switch])==0
        for i=1:nsim
            shocks_time{i}=mvnrnd([0 0],dyn_vcov_exo,per)';% draw shocks in the time-series across sims
        end

%         % Draw (always the same) cross-sectional shocks
%         tempaa = mvnrnd([0 0], dyn_vcov_exo, Nn)'; % draw full set of cross-sectional shocks
%         tempaa = tempaa(:,1:Ncross); % picks only the required cross-sectional shocks
%         shocks_cross = [tempaa -tempaa];
    elseif sum([stoch_vol_switch,gold_switch])==1
        for i=1:nsim
            shocks_time{i}=mvnrnd([0 0],dyn_vcov_exo,per)';
        end        

        % Draw (always the same) cross-sectional shocks
%         tempaa = mvnrnd([0 0], dyn_vcov_exo, Nn)'; % draw full set of cross-sectional shocks
%         tempaa = tempaa(:,1:Ncross); % picks only the required cross-sectional shocks
%         shocks_cross = [tempaa -tempaa];        
    elseif sum([stoch_vol_switch,gold_switch])==2
        for i=1:nsim
            shocks_time{i}=mvnrnd([0 0 0],dyn_vcov_exo,per)'; 
        end                

        % Draw (always the same) cross-sectional shocks
%         tempaa = mvnrnd([0 0 0], dyn_vcov_exo, Nn)'; % draw full set of cross-sectional shocks
%         tempaa = tempaa(:,1:Ncross); % picks only the required cross-sectional shocks
%         shocks_cross = [tempaa -tempaa];        
    end      

    
%% Defining the frequency of the aggregation consistently with the calibration frequency     
    FR  = 4; % If the calibration is monthly FR=3 ->TAQuarterly
    FR2 = 1; %12/FR; % This is used to annualize


%% Loop on simulations starts here

stats=zeros(size(dyn_steady_states,1),3,nsim);
corr_mat=zeros(size(dyn_steady_states,1),size(dyn_steady_states,1),nsim);
%output=zeros(30+3+2+2,1,nsim);
output=zeros(19,1,nsim);
%output_G=nan(4,1,nsim);% SAM ADD

disp('Running simulations');
for k=1:nsim
   
    % Simulate
    sim_res=dynare_simul(strcat(fname,'.mat'),shocks_time{k}); % take full set of period of shocks for sim from already drawn shocks
    %sim_res=fill_dyn(sim_res); % SAM EDIT: move after cond. moments section
%     save(strcat(fname,'.mat'),'sim_res','-append')
    % if calculate conditional moments as well
    
    % fill in other vars with zeros before calculating stats  
    sim_res=fill_dyn(sim_res); % SAM MOVE HERE

%    Statistics
    mean_var=mean(sim_res,2);
    std_var=std(sim_res,0,2);
    for i=1:size(sim_res,1)
        temp=autocorr(sim_res(i,1:end),1);
        acf(i,1)=temp; %#ok<SAGROW>
    end
    stats(:,:,k)=[mean_var,std_var,acf];
    corr_mat(:,:,k)=corr(sim_res');

    % Creating levered returns with iid shocks
    Lev_ExR = LEVERAGE*sim_res(dyn_i_exr,:)' + normrnd(0,1,per,1)*((.065)/sqrt(FR2));
    Lev_ExRpatent = LEVERAGE*sim_res(dyn_i_exrpatent,:)' + normrnd(0,1,per,1)*((.065)/sqrt(FR2));
    Lev_ExRrnd = LEVERAGE*sim_res(dyn_i_exrrnd,:)' + normrnd(0,1,per,1)*((.065)/sqrt(FR2));
    Lev_ExRrndns = LEVERAGE*sim_res(dyn_i_exrrnd,:)' ;
    % Time-aggregating whatever is needed
               A=exp(cumsum([sim_res(dyn_i_da,:)]));              
               Ad=exp(cumsum([0 sim_res(dyn_i_da,:)]));
               GDP = exp(sim_res(dyn_i_gdp,:)).*Ad(1:end-1); GDP=ta(GDP',FR,1);
               dGDP = diff(log(GDP));  
               Y=sim_res(dyn_i_Y_A,:).*A(1:end); Y=ta(Y',FR,1);
               dY = diff(log(Y));
               %K=sim_res(dyn_i_K_A,:).*Ad(1:end-1); K=ta(K',FR,5);
               KC=sim_res(dyn_i_KC_A,:).*sim_res(dyn_i_qc,:).*Ad(1:end-1); KC=ta(KC',FR,5);
               KRATIO=sim_res(dyn_i_kratio,:);
               VexpKg=sim_res(dyn_i_VexpKg,:);
               qc=sim_res(dyn_i_qc,:);
%                YRATIO=sim_res(dyn_i_yratio,:);
%                WRATIO=sim_res(dyn_i_wratio,:);
%                GRATIO = KC./(Yp+Yc);
%               GRATIO=sim_res(dyn_i_gratio,:);
%                N=exp(sim_res(dyn_i_n,:)); N=ta(N',FR,5);
               UA = exp(sim_res(dyn_i_ut,:));
               C = exp(sim_res(dyn_i_ca,:)).*Ad(1:end-1); C=ta(C',FR,1);
               dC = diff(log(C));  
               Np = exp(sim_res(dyn_i_np,:)); Np=ta(Np',FR,1);
               dNp = diff(log(Np));  
               Nc = exp(sim_res(dyn_i_nc,:)); Nc=ta(Nc',FR,1);
               dNc = diff(log(Nc));   
               Ntotal = exp(sim_res(dyn_i_ntotal,:)); Ntotal=ta(Ntotal',FR,1);
               dNtotal = diff(log(Ntotal));  
               Ip = exp(sim_res(dyn_i_ipa,:)).*Ad(1:end-1);Iptest=Ip; Ip=ta(Ip',FR,1);
               dIp = diff(log(Ip));
               Ypf = (exp(sim_res(dyn_i_ypa,:)).*sim_res(dyn_i_p,:)./sim_res(dyn_i_ptil,:)).*Ad(1:end-1); Ypf=ta(Ypf',FR,1);
               dYpf = diff(log(Ypf));
               Yp = (exp(sim_res(dyn_i_ypa,:)).*sim_res(dyn_i_p,:)).*Ad(1:end-1); Yp=ta(Yp',FR,1);
               dYp = diff(log(Yp));
               KPA = exp(sim_res(dyn_i_kpa,:)); KPA = ta(KPA',FR,3);
               KCA = exp(sim_res(dyn_i_kca,:)); KCA = ta(KCA',FR,3);
               KTOTA =  exp(sim_res(dyn_i_kca,:))+ exp(sim_res(dyn_i_kpa,:)); KTOTA = ta(KTOTA',FR,3);
               AKP = 1./KPA;
               AKTOT = 1./KTOTA;
               Yc = exp(sim_res(dyn_i_yca,:)).*Ad(1:end-1); Yc=ta(Yc',FR,1);
               dYc = diff(log(Yc));
               dtfp = sim_res(dyn_i_dtfp,:); dtfpy=ta(dtfp',FR,2);
               kg_ktot = ta(KRATIO',FR,3);
               
                Is = sim_res(dyn_i_Ic,:).*Ad(1:end-1);Istest=Is; Is=ta(Is',FR,1);
                S = exp(sim_res(dyn_i_s,:)).*Ad(1:end-1);S=ta(S',FR,1);
                dS = diff(log(S));
                Itot=Ip+Is+S;
                Irnd_tot = S./(Ip+S);
                Ig_tot = Is./Itot;
                I = Ip+S;
                dI = diff(log(I));
                Itottest=Iptest+Istest;
                Ytot=GDP;
                dYtot = diff(log(Ytot));
                dItot = diff(log(Itot));
               % SAM ADD:
               if gold_switch==1
                  J = sim_res(dyn_i_JA,:).*A(1:end); J=ta(J',FR,1);
               end
  
    if stoch_vol_switch==1;
    output(1:19,:,k)=[sqrt(FR2)*100*std(dYtot);
                   std(dC)/std(dYtot);
                   std(dItot)/std(dYtot);
                   sqrt(FR2)*100*std(dS);               
                   100*mean(I./Ytot);
                   100*std(I./Ytot);
                   corr(dC,dI);
                   100*mean(Is./Ytot);
                   100*std(Is./Ytot);                   
                   100*mean(KRATIO);
                   mean(qc);
                 FR2*100*mean( exp( ta(Lev_ExR,FR,2) ) - 1 );
                   sqrt(FR2)*100*std( exp( ta(Lev_ExR,FR,2) ) - 1 );
                   FR2*100*mean(exp(ta(sim_res(dyn_i_exr_G,:)',FR,2))-1);
                   sqrt(FR2)*100*std(exp(ta(sim_res(dyn_i_exr_G,:)',FR,2))-1);
                   FR2*100*mean( exp( ta(Lev_ExRrnd,FR,2) ) - 1 );
                   FR2*100*mean(ta(sim_res(dyn_i_rf,:)',FR,2));
                   sqrt(FR2)*100*std(ta(sim_res(dyn_i_rf,:)',FR,2));
                   FR2*100*mean(dYtot)
                    ];
               
                   shocks_times=shocks_time{k};
    end;          
   
    %save(strcat(fname,'.mat'),'Istest','Itottest','shocks_times','-append') 
    
    %sim_res_all(:,:,k)=sim_res;
end

% for exporting table later                   
output_varlabels = {...
        'sig_dy';...
        'std_dC_std_dYtot'; ...
        'std_dItot_std_dYtot'; ...
       'std_dS'; ...
       'mean_I_Ytot'; ...
       'std_I_Ytot'; ...
       'corr_dC_dI'; ...
       'mean_Is_Ytot'; ...
       'std_Is_Ytot'; ...             
       'mean_KRATIO'; ...
       'mean_qc'; ...
       'mean_Lev_ExR'; ...
       'std_Lev_ExR'; ...
       'mean_exr_G'; ...
       'std_exr_G'; ...
       'mean_Lev_ExRrnd'; ...
       'mean_rf'; ...
       'std_rf'; ...
       'mean_dYtot'};

%save(strcat(fname,'.mat'),'sim_res_all','-append');
% stats_ones=zeros(size(stats)); stats_ones(~isnan(stats))=1;
% stats(isnan(stats))=0;         stats=sum(stats,3)./sum(stats_ones,3);
% 
% corr_ones=zeros(size(corr_mat)); corr_ones(~isnan(corr_mat))=1;
% corr_mat(isnan(corr_mat))=0;     corr_mat=sum(corr_mat,3)./sum(corr_ones,3);

%output_ones=zeros(size(output)); output_ones(~isnan(output))=1;
%output(isnan(output))=0;         output=sum(output,3)./sum(output_ones,3);

clear temp
[a_,b_,c_] = size(output);
for j_j= 1:a_

     I = (isnan(output(j_j,1,:))==0).*(isinf(output(j_j,1,:))==0).*(abs(output(j_j,1,:))<1.e3);
     
     turn_on_new_filter=1;
     if turn_on_new_filter==1
         if j_j==1
             I_all = I;
         else
             I_all = I_all.*I;
         end
         I = I.*I_all;
     end
     
     I = (I==1);
     temp(j_j, 1) = mean(output(j_j,1,I));         
    
     junk(j_j,1:c_) = I(1,1,:);
     
end
output_N=output; % just change the name (it has N repetitions)
output = temp; % Two dimensions
%output_table = [output(7,1);output(8,1);output(9,1);output(33,1);output(12,1);output(13,1); output(19,1);output(10,1);output(11,1);output(16:19,1);output(22:25,1);output(34,1);output(26:27,1);output(35,1);];

%save(strcat(fname,'.mat'),'stats','corr_mat','output','output_N','sim_res','I','junk','shocks1','sim_res_save','shocks_save','-append')
%save(strcat(fname,'.mat'),'stats','corr_mat','output','output_N','output_G','output_G_N','I','output_table','-append')
save(strcat(fname,'.mat'),'output','output_N','-append')
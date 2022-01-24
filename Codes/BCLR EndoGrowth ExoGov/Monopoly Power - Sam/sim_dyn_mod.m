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
    nsim    = 100;
    %per     = 100;%4000 work for exo, 800 works for both with 100 sim
    %(2016-1972+1)*4
    per     = 180;%4000 work for exo, 800 works for both with 100 sim
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

        % Draw (always the same) cross-sectional shocks
        tempaa = mvnrnd([0 0], dyn_vcov_exo, Nn)'; % draw full set of cross-sectional shocks
        tempaa = tempaa(:,1:Ncross); % picks only the required cross-sectional shocks
        shocks_cross = [tempaa -tempaa];
    elseif sum([stoch_vol_switch,gold_switch])==1
        for i=1:nsim
            shocks_time{i}=mvnrnd([0 0],dyn_vcov_exo,per)';
        end        

        % Draw (always the same) cross-sectional shocks
        tempaa = mvnrnd([0 0], dyn_vcov_exo, Nn)'; % draw full set of cross-sectional shocks
        tempaa = tempaa(:,1:Ncross); % picks only the required cross-sectional shocks
        shocks_cross = [tempaa -tempaa];        
    elseif sum([stoch_vol_switch,gold_switch])==2
        for i=1:nsim
            shocks_time{i}=mvnrnd([0 0 0],dyn_vcov_exo,per)'; 
        end                

        % Draw (always the same) cross-sectional shocks
        tempaa = mvnrnd([0 0 0], dyn_vcov_exo, Nn)'; % draw full set of cross-sectional shocks
        tempaa = tempaa(:,1:Ncross); % picks only the required cross-sectional shocks
        shocks_cross = [tempaa -tempaa];        
    end      


%  computing conditional moments
if conditional_moments_switch==1
  
  clear cond_irf_cross CondE CondStd CondCorr
  for t=1:irf_sim
    % cross-sectional shocks starting at different initial values
    for j=1:2*Ncross
        %cond_ea_cross(:,j) = dynare_simul(strcat(fname,'.mat'), shocks_cross(:,j), dyn_irfp_ea_raw(:,t));
        temp_junk = dynare_simul(strcat(fname,'.mat'), shocks_cross(:,j), dyn_irfp_ea_raw(:,t));
        cond_ea_cross(:,j) = fill_dyn(temp_junk);
        temp_junk = dynare_simul(strcat(fname,'.mat'), shocks_cross(:,j), dyn_irfp_ex_raw(:,t));
        cond_ex_cross(:,j) = fill_dyn(temp_junk);
        if stoch_vol_switch==1
            temp_junk = dynare_simul(strcat(fname,'.mat'), shocks_cross(:,j), dyn_irfp_es_raw(:,t));
            cond_es_cross(:,j) = fill_dyn(temp_junk);
        else
            temp_junk = zeros(size(cond_ea_cross,1),1);% use existing shock matrix for ea just for size
            cond_es_cross(:,j) = fill_dyn(temp_junk);
        end
        if gold_switch==1
            temp_junk = dynare_simul(strcat(fname,'.mat'), shocks_cross(:,j), dyn_irfp_eg_raw(:,t));
            cond_eg_cross(:,j) = fill_dyn(temp_junk);
        else
            temp_junk = zeros(size(cond_ea_cross,1),1);% use existing shock matrix for ea just for size
            cond_eg_cross(:,j) = fill_dyn(temp_junk);
        end        
    end          

    
    % CondE and CondStd store conditional mean and std for all dyn vars
    irf_condE_ea(:,t)   = mean(cond_ea_cross,2);
    irf_condStd_ea(:,t) = std(cond_ea_cross,1,2);
    irf_condCorr_ea(:,:,t) = corrcoef(cond_ea_cross');          

    irf_condE_ex(:,t)   = mean(cond_ex_cross,2);
    irf_condStd_ex(:,t) = std(cond_ex_cross,1,2);
    irf_condCorr_ex(:,:,t) = corrcoef(cond_ex_cross');              
    
    irf_condE_es(:,t)   = mean(cond_es_cross,2);
    irf_condStd_es(:,t) = std(cond_es_cross,1,2);
    irf_condCorr_es(:,:,t) = corrcoef(cond_es_cross');                  
    
    irf_condE_eg(:,t)   = mean(cond_eg_cross,2);
    irf_condStd_eg(:,t) = std(cond_eg_cross,1,2);
    irf_condCorr_eg(:,:,t) = corrcoef(cond_eg_cross');                      
    
  end %for t=1:T
  
   % Saving the initial levels (doesn't matter which shock you use on the
   % LHS because they all start from the same level)
     irf_condE_start = irf_condE_ea(:,1);
     irf_condStd_start = irf_condStd_ea(:,1);
     irf_condCorr_start = irf_condCorr_ea(:,:,1);  
         
  % Demean variables for IRF plot

      irf_condE_ea    = irf_condE_ea    - irf_condE_ea(:,1)*ones(1,irf_sim);
      irf_condStd_ea  = irf_condStd_ea  - irf_condStd_ea(:,1)*ones(1,irf_sim);
      for i=1:irf_sim
          irf_condCorr_ea(:,:,i) = irf_condCorr_ea(:,:,i) - irf_condCorr_start;
      end

      irf_condE_ex    = irf_condE_ex    - irf_condE_ex(:,1)*ones(1,irf_sim);
      irf_condStd_ex  = irf_condStd_ex  - irf_condStd_ex(:,1)*ones(1,irf_sim);
      for i=1:irf_sim
          irf_condCorr_ex(:,:,i) = irf_condCorr_ex(:,:,i) - irf_condCorr_start;
      end

      irf_condE_es    = irf_condE_es    - irf_condE_es(:,1)*ones(1,irf_sim);
      irf_condStd_es  = irf_condStd_es  - irf_condStd_es(:,1)*ones(1,irf_sim);
      for i=1:irf_sim
          irf_condCorr_es(:,:,i) = irf_condCorr_es(:,:,i) - irf_condCorr_start;
      end      
  
      irf_condE_eg    = irf_condE_eg    - irf_condE_eg(:,1)*ones(1,irf_sim);
      irf_condStd_eg  = irf_condStd_eg  - irf_condStd_eg(:,1)*ones(1,irf_sim);       
      for i=1:irf_sim
          irf_condCorr_eg(:,:,i) = irf_condCorr_eg(:,:,i) - irf_condCorr_start;
      end      
      
  % Plot and save conditional IRFs
  %condE_irf

else % if conditional_moments_switch~=1 then generate conditional IRF matrices with all zeros
    
    %for XX={'E','Std','Corr'}
    for YY={'ea','ex','es','eg'}
      for XX={'E','Std'}
        eval(strcat('irf_cond',char(XX),'_',char(YY),' = zeros(',num2str(size(dyn_ss,1)),',',num2str(irf_sim),');'));
      end
      % correlation matrix
      eval(strcat('irf_condCorr_',char(YY),' = zeros(',num2str(size(dyn_ss,1)),',',num2str(size(dyn_ss,1)),',',num2str(irf_sim),');'));
    end
    
    % starting value vectors and matrices
    irf_condE_start = zeros(size(dyn_ss,1),1);
    irf_condStd_start = zeros(size(dyn_ss,1),1);
    irf_condCorr_start = zeros(size(dyn_ss,1),size(dyn_ss,1),1);
    
end
      
  % save into .mat file  
      save(strcat(fname,'.mat'),'irf_condE_start','irf_condStd_start','irf_condCorr_start','-append');
      save(strcat(fname,'.mat'),'irf_condE_ea','irf_condStd_ea','irf_condCorr_ea','-append');
      save(strcat(fname,'.mat'),'irf_condE_ex','irf_condStd_ex','irf_condCorr_ex','-append');
      save(strcat(fname,'.mat'),'irf_condE_es','irf_condStd_es','irf_condCorr_es','-append');
      save(strcat(fname,'.mat'),'irf_condE_eg','irf_condStd_eg','irf_condCorr_eg','-append');


      
%% Code required to compute EP=COV
%if ep_cov_calc_switch==1
if 0==1 % SAM
    
    disp('Re-computing RF and EP by simulations ...')
    
    theta     = (1-1/psi)/(1-gam);
    ReCoRd = zeros(nsim,4);   
    
    for j=1:2*Ncross    

        % Simulate (same initial value dyn_ss each loop)
        sim_res=dynare_simul(strcat(fname,'.mat'),shocks_cross(:,j),dyn_ss);
        sim_res=fill_dyn(sim_res);
        
        % Record
        ReCoRd(j,1) = beta*exp(-1/psi*sim_res(dyn_i_dc) ) ;
        ReCoRd(j,1) = ReCoRd(j,1)*exp((1/psi-gam)*(sim_res(dyn_i_uc) + sim_res(dyn_i_dc) ));
        % C.E. 
        ReCoRd(j,3) = exp((sim_res(dyn_i_uc) + sim_res(dyn_i_dc) )*(1-gam));
        % Ex-Returns
        ReCoRd(j,2) = sim_res(dyn_i_exr);
        ReCoRd(j,4) = sim_res(dyn_i_exr_G); % GOLD (should be all zeros if no gold)
    end 
    ReCoRd(:,1) = ReCoRd(:,1)./ (mean(ReCoRd(:,3)).^(1-theta));  
    ReCoRd(:,1) = log(ReCoRd(:,1));
    
    %save TEMP ReCoRd
    
    % Compute E[RF] and EP
    cond_sim_RF   = log(1/(mean( exp(ReCoRd(:,1)) )))*frEq*100;
    cond_sim_RF_2 = -mean(ReCoRd(:,1))*frEq*100;
    temp   = -cov(exp(ReCoRd(:,1)), exp(ReCoRd(:,2)));
    cond_sim_EP_lev = temp(1,2)*LEVERAGE*frEq*100+2;
    % ALSO FOR GOLD (SAM ADD)
    cond_sim_EP_G   = nan; % should be nan if no gold in model
    if gold_switch==1
        temp   = -cov(exp(ReCoRd(:,1)), exp(ReCoRd(:,4)));
        cond_sim_EP_G   = temp(1,2)*frEq*100;
    end    
    
    % display calculated values
    disp('RF          EP (levered)    EP (Gold)')
    disp(num2str([cond_sim_RF  cond_sim_EP_lev  cond_sim_EP_G]))             
    
    disp('End Re-computation ...')
else
    % set to nan if ep_cov_calc_switch==0 
    cond_sim_RF     = nan;
    cond_sim_EP_lev = nan;
    cond_sim_EP_G   = nan;    
end
% save these moments for displaying in report
save(strcat(fname,'.mat'),'cond_sim_RF','cond_sim_EP_lev','cond_sim_EP_G','-append')

%% Defining the frequency of the aggregation consistently with the calibration frequency     
    FR  = 4; % If the calibration is monthly FR=3 ->TAQuarterly
    FR2 = 1; %12/FR; % This is used to annualize


%% Loop on simulations starts here

stats=zeros(size(dyn_steady_states,1),3,nsim);
corr_mat=zeros(size(dyn_steady_states,1),size(dyn_steady_states,1),nsim);
output=zeros(30+3+2+2,1,nsim);
output_G=nan(4,1,nsim);% SAM ADD



disp('Running simulations');
for k=1:nsim
        
    k;
    
    % Simulate
    sim_res=dynare_simul(strcat(fname,'.mat'),shocks_time{k}); % take full set of period of shocks for sim from already drawn shocks
    %sim_res=fill_dyn(sim_res); % SAM EDIT: move after cond. moments section
%     save(strcat(fname,'.mat'),'sim_res','-append')
    % if calculate conditional moments as well
    if conditional_moments_switch==1
      
      clear sim_cross CondE CondStd CondCorr
      for t=1:T
        % cross-sectional shocks starting at different initial values
        for j=1:2*Ncross
            sim_cross(:,j) = dynare_simul(strcat(fname,'.mat'), shocks_cross(:,j), sim_res(:,t));
        end          
        
        %sim_cross=fill_dyn(sim_cross);
        
        % CondE and CondStd store conditional mean and standard deviations for all
        % our variables.       
        CondE(:,t)      = mean(sim_cross,2);
        CondStd(:,t)    = std(sim_cross,1,2);
        CondCorr(:,:,t) = corrcoef(sim_cross');          
        
      end %for t=1:T
      
    end %if conditional_moments==1
    
    % fill in other vars with zeros before calculating stats  
    sim_res=fill_dyn(sim_res); % SAM MOVE HERE
    
    
%     % Temp code to check CG
%     temp1 = sim_res(dyn_i_JA,:); 
%     temp2 = exp(sim_res(dyn_i_qG,:));
%     figure(1001)
%     plot(temp1,temp2,'.-k');
%     pause
    
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
               
               % additional labor moments
               wagec = sim_res(dyn_i_wagec,:); wagec=ta(wagec',FR,3); % take average wage
               wagep = sim_res(dyn_i_wagec,:); wagep=ta(wagep',FR,3); % take average wage
               compc = wagec.*Nc; % total wages
               compp = wagep.*Np; % total wages
               dwagec = diff(log(wagec));  
               dwagep = diff(log(wagep));  
               dcompc = diff(log(compc));  
               dcompp = diff(log(compp));  
               rat_Np_Nc = Np ./ Nc;
               rat_Np_Ntot = Np ./ (Np+Nc);
               
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

    temp = ta(Lev_ExR,FR,2);
    lag = 10;
tfpygr_avr = tsmovavg(dtfpy(2:end), 's', lag, 1);
% F=[bondy1y bondy2y bondy3y bondy4y bondy5y bondy6y inflationy pdratio ivoly anfci nfci baa10ym];
FA=[kg_ktot-AKP];
% FB=[kg_ktot-AKP];

%% Run Regression da   = ca + b_x * F(-1) + ea; %1973-2011
lags = 1;
weight = 1;
% Y = tfpygr(2:end,1);
Y = tfpygr_avr(lag:end,1); %74-83
X = [ones(length(Y),1) FA(1:end-lag,:)];
% X = [ones(length(Y),1) kg_ktot(1:end-lag,:)];
[BetaseEA,SesEA,RsqrEA,RsqradjEA,VCVEA,FEA]=olsgmm(Y,X,lags,weight);

Y = tfpygr_avr(lag:end,1); %74-83
X = [ones(length(Y),1) kg_ktot(1:end-lag,:)];
[BetaseEB,SesEB,RsqrEB,RsqradjEB,VCVEB,FEB]=olsgmm(Y,X,lags,weight);

Y = tfpygr_avr(lag:end,1); %74-83
X = [ones(length(Y),1) AKP(1:end-lag,:)];
[BetaseEC,SesEC,RsqrEC,RsqradjEC,VCVEC,FEC]=olsgmm(Y,X,lags,weight);
% Y = tfpygr_avr(lag:end,1); %74-83
% X = [ones(length(Y),1) FB(1:end-lag,:)];
% [BetaseEB,SesEB,RsqrEB,RsqradjEB,VCVEB,FEB]=olsgmm(Y,X,lags,weight);

tfpygr_avr = tsmovavg(dtfpy(2:end), 's', lag, 1);

Y = tfpygr_avr(lag:end,1); %74-83
X = [ones(length(Y),1) Irnd_tot(1:end-lag,:)];
[BetaseED,SesED,RsqrED,RsqradjED,VCVED,FED]=olsgmm(Y,X,lags,weight);

Y = tfpygr_avr(lag:end,1); %74-83
X = [ones(length(Y),1) Ig_tot(1:end-lag,:)];
[BetaseEE,SesEE,RsqrEE,RsqradjEE,VCVEE,FEE]=olsgmm(Y,X,lags,weight);
    
    if stoch_vol_switch==1;
    output(1:35,:,k)=[sqrt(FR2)*100*std(dYtot);
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
                    BetaseEA(2,1);
                   -BetaseEA(2,1);
                   BetaseEC(2,1);
                   BetaseED(2,1);
                    BetaseEE(2,1);
                    FR2*100*mean(dYtot); % SAM add nov 2020
%                    std(ta(sim_res(dyn_i_q,:)',FR,4)); %% Focus on std(q)
%                   std(dI)/std(dYtot);
%                   std(dI)/std(dYp);                   
%                    100*mean(Itot./Ytot);
%                    100*std(Itot./Ytot);
%                    100*mean(Is./Itot);
%                    100*std(Is./Itot);
%                    100*mean(Is./Ytot);
%                    100*std(Is./Ytot);
%                    
% %                    100*mean(GRATIO);
% %                    100*std(GRATIO);
% %                    100*mean(WRATIO);
% %                    100*mean(YRATIO);
%                    
%                    corr((Is./Ytot),(C./Ytot));
%                    corr(dC, temp(2:end));
%                    
%  
% 
%                    autocorr(ta(Lev_ExR,FR,2),1);
%                    autocorr(ta(sim_res(dyn_i_rf,:)',FR,2),1);
% %                   autocorr(ta(sim_res(dyn_i_q,:)',FR,4),1);   
%                    autocorr(dC,1);
%                    std(sim_res(dyn_i_vol,:));
%                    (mean(UA)-exp(dyn_ss(dyn_i_ut,1)))/exp(dyn_ss(dyn_i_ut,1))*100;
%                   
% 
%                    SesEA(2,1);
%                                     sqrt(FR2)*100*std( exp( ta(Lev_ExRrnd,FR,2) ) - 1 );
%                                     sqrt(FR2)*100*std( exp( ta(Lev_ExRrndns,FR,2) ) - 1 );
%                    RsqrEA;
%                    RsqrEB;
%                    RsqrEC;                    
                    sqrt(FR2)*100*std(dNc); % SAM add feb 2021
                    sqrt(FR2)*100*std(dNp); % SAM add feb 2021
                    sqrt(FR2)*100*std(dwagec); % SAM add feb 2021 
                    sqrt(FR2)*100*std(dwagep); % SAM add feb 2021 
                    sqrt(FR2)*100*std(dcompc); % SAM add feb 2021 
                    sqrt(FR2)*100*std(dcompp); % SAM add feb 2021    
                    corr(dNp,dNc); % SAM add feb 2021  
                    100*mean(rat_Np_Nc);% SAM add feb 2021  
                    100*std(rat_Np_Nc); % SAM add feb 2021  
                    100*mean(rat_Np_Ntot);% SAM add feb 2021  
                    100*std(rat_Np_Ntot); % SAM add feb 2021  
                   ];
               
                   shocks_times=shocks_time{k};
    end;          
    if stoch_vol_switch==0;
    output(1:23,:,k)=[sqrt(FR2)*100*std(dYtot);
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
                   BetaseEA(2,1);
                   -BetaseEA(2,1);
                   BetaseEC(2,1);
                    BetaseED(2,1);
                    BetaseEE(2,1);
%                    std(ta(sim_res(dyn_i_q,:)',FR,4)); %% Focus on std(q)
%                   std(dI)/std(dYtot);
%                   std(dI)/std(dYp);                   
%                    100*mean(Itot./Ytot);
%                    100*std(Itot./Ytot);
%                    100*mean(Is./Itot);
%                    100*std(Is./Itot);
%                    100*mean(Is./Ytot);
%                    100*std(Is./Ytot);
%                    
% %                    100*mean(GRATIO);
% %                    100*std(GRATIO);
% %                    100*mean(WRATIO);
% %                    100*mean(YRATIO);
%                    
%                    corr((Is./Ytot),(C./Ytot));
%                    corr(dC, temp(2:end));
%                    
%  
% 
%                    autocorr(ta(Lev_ExR,FR,2),1);
%                    autocorr(ta(sim_res(dyn_i_rf,:)',FR,2),1);
% %                   autocorr(ta(sim_res(dyn_i_q,:)',FR,4),1);   
%                    autocorr(dC,1);
%                    std(sim_res(dyn_i_vol,:));
%                    (mean(UA)-exp(dyn_ss(dyn_i_ut,1)))/exp(dyn_ss(dyn_i_ut,1))*100;
%                   
% 
%                    SesEA(2,1);
%                                     sqrt(FR2)*100*std( exp( ta(Lev_ExRrnd,FR,2) ) - 1 );
%                                     sqrt(FR2)*100*std( exp( ta(Lev_ExRrndns,FR,2) ) - 1 );
%                    RsqrEA;
%                    RsqrEB;
%                    RsqrEC;
                                    ];

                   shocks_times=shocks_time{k};
    end;     
    
    save(strcat(fname,'.mat'),'Istest','Itottest','shocks_times','-append') 
    
    %% Run Regression;
    vol_reg = 0;
    if vol_reg==1;
     Iqs_Itot = Istest'./Itottest';
          eare = shocks_times(1,:)'; 
           exre = shocks_times(2,:)'; 
            evre = shocks_times(3,:)'; 
      volre = sim_res(dyn_i_vol,:)';    
          Yre = Iqs_Itot(2:end);
Xre=[ones(length(Yre),1) Iqs_Itot(1:end-1) eare(2:end,1).*exp(volre(1:end-1,1)) exre(2:end,1).*exp(volre(1:end-1,1)) evre(2:end,1)];
lags = 4;
weight = 1;
[Betas,Ses,Rsqr,Rsqradj,VCV,Ftest]=olsgmm(Yre,Xre,lags,weight);
Tsta = Betas./Ses;
TCDF = tcdf(Tsta,length(Yre)-5);
Pvalue_ols = 2*(1-tcdf(abs(Tsta),length(Yre)-5));
regresults = zeros(length(Betas)*2+1,1);
cc=0;
for i=1:2:length(Betas)*2-1
    cc=cc+1;
    regresults(i,1)=Betas(cc,1);
    regresults(i+1,1)=Pvalue_ols(cc,1);
end
    regresults(end,1)=Rsqr;


save(strcat(fname,'.mat'),'Betas','Ses','Rsqr','Pvalue_ols','regresults','-append') 
Yvre = volre(2:end);
Xvre=[ones(length(Yvre),1) volre(1:end-1) exre(2:end,1).*exp(volre(1:end-1,1)) eare(2:end,1).*exp(volre(1:end-1,1))];
lags = 4;
weight = 1;
[BetaseEVV,SesEVV,RsqrEVV,RsqradjEVV,VCVEX,FEVV]=olsgmm(Yvre,Xvre,lags,weight);
TstaEVV = BetaseEVV./SesEVV;
TCDFEVV = tcdf(TstaEVV,length(Yvre));
PvalueEVV_ols = 2*(1-tcdf(abs(TstaEVV),length(Yvre)-5));
cc=0;
regresults_vol = zeros(length(BetaseEVV)*2+1,1);
for i=1:2:length(BetaseEVV)*2-1
    cc=cc+1;
    regresults_vol(i,1)=BetaseEVV(cc,1);
    regresults_vol(i+1,1)=PvalueEVV_ols(cc,1);
end
    regresults_vol(end,1)=RsqrEVV;
 save(strcat(fname,'.mat'),'BetaseEVV','SesEVV','RsqrEVV','PvalueEVV_ols','regresults_vol','-append') 
   
    
    end;
 %%  
    if stoch_vol_switch==0;
     Iqs_Itot = Istest'./Itottest';
          eare = shocks_times(1,:)'; 
           exre = shocks_times(2,:)'; 
   %         evre = shocks_times(3,:)'; 
   %   volre = sim_res(dyn_i_vol,:)';    
          Yre = Iqs_Itot(2:end);
Xre=[ones(length(Yre),1) Iqs_Itot(1:end-1) eare(2:end,1) exre(2:end,1)];
lags = 4;
weight = 1;
[Betas,Ses,Rsqr,Rsqradj,VCV,Ftest]=olsgmm(Yre,Xre,lags,weight);
Tsta = Betas./Ses;
TCDF = tcdf(Tsta,length(Yre)-5);
Pvalue_ols = 2*(1-tcdf(abs(Tsta),length(Yre)-5));
regresults = zeros(length(Betas)*2+1,1);
cc=0;
for i=1:2:length(Betas)*2-1
    cc=cc+1;
    regresults(i,1)=Betas(cc,1);
    regresults(i+1,1)=Pvalue_ols(cc,1);
end
    regresults(end,1)=Rsqr;


save(strcat(fname,'.mat'),'Betas','Ses','Rsqr','Pvalue_ols','regresults','-append') 
   
    
    end;
    
    
    
    % SAM ADD:
    if gold_switch==1     
        %tempp = exp(ta(sim_res(dyn_i_exr_G,:)',FR,2) ) - 1 ;
        tempp = ta(sim_res(dyn_i_exr_G,:)',FR,2);
        output_G(1:4,:,k) = [FR2*100*mean( tempp ); 
                             sqrt(FR2)*100*std( tempp);
                             100*mean(J./Y);
                             100*std(J./Y)];                        
                         
                         
    end
    if pdratio==1
   % First step of BKY

               A_est=Y./(K.^alpha.*N.^(1-alpha));
               da=log(A_est(2:end)./A_est(1:end-1));

               PD=exp(ta(sim_res(dyn_i_q,:)',FR,4))./ta(exp(sim_res(dyn_i_d,:))',FR,1);
               %PD = exp(ta(sim_res(dyn_i_q,:)',FR,4) - ta(exp(sim_res(dyn_i_d,:))',FR,4));
               %PD = exp(ta(sim_res(dyn_i_q,:)',FR,4));
               pd=log(PD(1:end-1));

               rf=ta(sim_res(dyn_i_rf,:)',FR,2);
               rf=rf(1:end-1);

               LHS=da;
               RHS=[ones(size(pd,1),1),pd,rf];
               beta=(RHS'*RHS)^-1*RHS'*LHS;
               x=RHS*beta; % This is estimated annual long run risk
               ea=da-x;    % This is estimated annual short run shocks (ea(1) is year 2)

               LHS=x(2:end);
               RHS=x(1:end-1);
               rho=(RHS'*RHS)^-1*RHS'*LHS;
               ex=x(2:end)-rho*x(1:end-1); % This is estimated annual long run shocks (ex(1) is year 3)

               est_shocks = [ea(2:end) ex]; % These are short-run and long-run shocks, where
                                             % the first row corresponds to year 3
    % Second step of BKY           
    % Consumption
    [TT aa] = size(est_shocks);
    XX  = [ones(TT,1)  LHS est_shocks];
    OMM = inv(XX'*XX)*XX';
    temp = OMM*dC(2:end);
    output(17:19,:,k) = temp(2:4);
    % I-Y Ratio
    temp1 = I./Y;
    XX  = [ones(TT,1) temp1(2:end-1)  est_shocks];
    OMM = inv(XX'*XX)*XX';
    temp = OMM*temp1(3:end);
    output(20:21,:,k) = [temp(3:4)];

    % Tobin's Q 
    temp1 = ta(sim_res(dyn_i_q,:)',FR,4);
    XX  = [ones(TT,1) temp1(2:end-1)  est_shocks];
    OMM = inv(XX'*XX)*XX';
    temp = OMM*temp1(3:end);
    output(23:23,:,k) = [temp(3:4)];
        
    end  
    sim_res_all(:,:,k)=sim_res;
    
    
    % december 2020: also save autocorrelations
    %ypa = log(Abar)+(1-alphap)*(ome_p)+ alphap*(kpa(-1))+(1-alphap)*log((exp(np)))
    %zh = log(Abar)+(1-alphap)*(ome_p)+ (1-alphap)*log(N);
    % problem: we don't have N in level, only da= change in log(N)
    dome_p = diff(sim_res(dyn_i_ome_p,:));
    dlogN = sim_res(dyn_i_da,:);
    dzh = (1-alphap)*(dome_p+dlogN(2:end));
    save_acf1(1,:,k) = autocorr(dC,1);
    save_acf1(2,:,k) = autocorr(dY,1);
    save_acf1(3,:,k) = autocorr(dtfp,1);
    save_acf1(4,:,k) = autocorr(dzh,1);
    save_acf1(5,:,k) = autocorr(sim_res(dyn_i_da,:),1);
    
    
end
save(strcat(fname,'.mat'),'sim_res_all','-append');
stats_ones=zeros(size(stats)); stats_ones(~isnan(stats))=1;
stats(isnan(stats))=0;         stats=sum(stats,3)./sum(stats_ones,3);

corr_ones=zeros(size(corr_mat)); corr_ones(~isnan(corr_mat))=1;
corr_mat(isnan(corr_mat))=0;     corr_mat=sum(corr_mat,3)./sum(corr_ones,3);

% check autocorrelations

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
     if simul_fast==1
         temp(j_j, 1) = median(output(j_j,1,I));         
     else
         temp(j_j, 1) = mean(output(j_j,1,I));         
     end
    
     junk(j_j,1:c_) = I(1,1,:);
     
end
%temp(22:23)
%keyboard;
output_N=output; % just change the name (it has N repetitions)
output = temp; % Two dimensions
output_table = [output(7,1);output(8,1);output(9,1);output(33,1);output(12,1);output(13,1); output(19,1);output(10,1);output(11,1);output(16:19,1);output(22:25,1);output(34,1);output(26:27,1);output(35,1);];
% SAM ADD:
clear temp_G
[a_,b_,c_] = size(output_G);
for j_j= 1:a_

     I = (isnan(output_G(j_j,1,:))==0).*(isinf(output_G(j_j,1,:))==0).*(abs(output_G(j_j,1,:))<1.e5);
     
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
     temp_G(j_j, 1) = mean(output_G(j_j,1,I));         
    
     junk(j_j,1:c_) = I(1,1,:);
     
end
output_G_N=output_G; % just change the name (it has N repetitions)
output_G = temp_G; % Two dimensions

% check autocorrelations
clear temp
[a_,b_,c_] = size(save_acf1);
for j_j= 1:a_

     I = (isnan(save_acf1(j_j,1,:))==0).*(isinf(save_acf1(j_j,1,:))==0).*(abs(save_acf1(j_j,1,:))<1.e3);
     
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
     temp(j_j, 1) = mean(save_acf1(j_j,1,I));         
    
     junk(j_j,1:c_) = I(1,1,:);
     
end
save_acf1_N=save_acf1; % just change the name (it has N repetitions)
save_acf1 = temp; % Two dimensions

%save(strcat(fname,'.mat'),'stats','corr_mat','output','output_N','sim_res','I','junk','shocks1','sim_res_save','shocks_save','-append')
save(strcat(fname,'.mat'),'stats','corr_mat','output','output_N','output_G','output_G_N','I','output_table','-append')
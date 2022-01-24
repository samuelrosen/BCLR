%% run all tfp growth rate regressions

clear all;
clc;
addpath(genpath('MFEToolbox')); 
addpath(genpath('data_for_tfpg_prediction')); 
addpath(genpath('matlab')); 


%% Import data and set smoothing param

T = readtable('data_for_tfpg_prediction_june2020.csv');
%data = table2struct(T,'ToScalar',true);            
%clear T    

smoothing = 10000;


%% Compustat ratios high R&D only

[~,comp_rnd_cap_dt] = one_sided_hp_filter_kalman(T.comp_pct_at_high_rnd,smoothing);
[~,comp_rnd_inv_dt] = one_sided_hp_filter_kalman(T.comp_pct_inv_high_rnd,smoothing);

% standard deviations used in interpreting reg results
std_comp_rnd_cap_dt = std(comp_rnd_cap_dt);
std_comp_rnd_inv_dt = std(comp_rnd_inv_dt);
disp(char(strcat({'std dev of dt compusat Krnd/Ktot is '},num2str(std_comp_rnd_cap_dt))));
disp(char(strcat({'std dev of dt compusat Irnd/Itot is '},num2str(std_comp_rnd_inv_dt))));

% [~,frac_at_high_rnd_dt] = hp_filter(frac_at_high_rnd,smoothing);
jj = 1;
RAWS = 3;
COLUMNS = 2;
count = 0;
table = cell(RAWS*COLUMNS);
figure(jj)
Stdvars = [];
%tables = zeros(8,3);
tables = zeros(12,3);
pvals = zeros(3,3);

for lag = [5 7 10]
    
tfpygr_avr = tsmovavg(T.tfpyg(2:end), 's', lag, 1);
ii = 0;
    for var = [comp_rnd_cap_dt comp_rnd_inv_dt]
        Stdvars = [Stdvars std(var)];
        ii = ii + 1;
        count = count+1;

        F=[T.bondy1y T.bondy2y T.bondy3y T.bondy4y T.bondy5y T.bondy6y T.inflationy T.pdratioy T.ivoly T.anfci T.nfci T.baa10ym var];

        % Run Regression da   = ca + b_x * F(-1) + ea; %1973-2011
        lags = 2; % main setting up through june 2021
        %lags = 3; % try using another lag
        weight = 1;
        start = 0;
        % Y = tfpygr(2:end,1);
        Y = tfpygr_avr(lag+start:end,1); %74-83
        X = [ones(length(Y),1) F(1+start:end-lag,:)];
        [BetaseEA,SesEA,RsqrEA,RsqradjEA,VCVEA,FEA]=olsgmm(Y,X,lags,weight);
        TstaEA = BetaseEA./SesEA;
        TCDFEA = tcdf(TstaEA,length(T.tfpyg(2:end,1)-5));
        PvalueEA_ols = 2*(1-tcdf(abs(TstaEA),length(Y)-2));
        Resid = Y-X*BetaseEA;  % added june 2021 for jpe ref report
        [H,P,JBSTAT,CRITVAL] = jbtest(Resid, 0.05); % added june 2021 for jpe ref report        
        table{count} = [BetaseEA SesEA PvalueEA_ols];
        R2(:,count) = RsqradjEA;
        Betaplot = BetaseEA;
        Betaplot(end,1) = 0;
        %disp(count); 
             subplot(RAWS,COLUMNS,count);
             box on; hold on;
             scatter(X(:,end),Y-X*Betaplot,10,'b','*');
        if lag == 5
        %  ylabel('Agg 5 year MA minus controls')
         ylabel('TFP Growth Rate (5 year MA)')
        yy = 1;
        end
        if lag == 7
        %  ylabel('Agg 7 year MA minus controls')
         ylabel('TFP Growth Rate (7 year MA)')
        yy = 2;
        end
        if lag == 10
        %  ylabel('Agg 10 year MA minus controls')
         ylabel('TFP Growth Rate (10 year MA)')
        yy = 3;
        end
         %tables(1+(ii-1)*4:3+(ii-1)*4,yy) = [BetaseEA(end,1);SesEA(end,1);RsqradjEA];
         tables(1+(ii-1)*6:3+(ii-1)*6,yy) = [BetaseEA(end,1);SesEA(end,1);RsqradjEA];
         pvals(ii,yy) =  PvalueEA_ols(end,1);
        if ii == 1
         xlabel(['$K^{Comp}_{HighR\&D}/K^{Comp}_{Total}$'],'interpreter','latex')
        end
        if ii == 2
         xlabel(['$I^{Comp}_{HighR\&D}/I^{Comp}_{Total}$'],'interpreter','latex')
        end
        if ii == 1
         %axis([-0.25 0.25 -0.01 0.01]) 
         axis([-2 5 -1.5 1.5]) 
        else
         %axis([-0.6 0.6 -0.01 0.01]) 
         axis([-5 15 -1.5 1.5]) 
        end
            %F=[bondy1y bondy2y bondy3y bondy4y bondy5y bondy6y inflationy pdratio ivoly anfci nfci baa10ym];
            F =[T.bondy1y T.bondy2y T.bondy3y T.bondy4y T.bondy5y T.bondy6y T.inflationy T.pdratioy T.ivoly T.anfci T.nfci T.baa10ym];


        % Run Regression da   = ca + b_x * F(-1) + ea; %1973-2011
        lags = 4;
        weight = 1;
        start = 4;
        % Y = tfpygr(2:end,1);
        Y = tfpygr_avr(lag+start:end,1); %74-83
        X = [ones(length(Y),1) F(1+start:end-lag,:)];
        [BetaseEA,SesEA,RsqrEA,RsqradjEA,VCVEA,FEA]=olsgmm(Y,X,lags,weight);
          %tables(4+(ii-1)*4,yy) = [RsqradjEA];
          tables(4+(ii-1)*6,yy) = [RsqradjEA];

          % added on june 2021
          tables(5+(ii-1)*6,yy) = [JBSTAT];
          tables(6+(ii-1)*6,yy) = [CRITVAL];
         
    end

 
end

disp('Compustat rnd ratios results');
[[1:size(tables,1)]',tables]

std_comp_rnd_cap_dt_rounded = round(std_comp_rnd_cap_dt/100,3);
beta_5yr_cap_rounded = round(tables(1,1),2);
implied_cum_gro_compustat_cap_pct = 100*5*2*std_comp_rnd_cap_dt_rounded*beta_5yr_cap_rounded;
% 5 years, 2 std devs, use capital ratio std dev, use beta for 5-yr horizon
disp(char(strcat({'rounded StDevs of compustat high rnd capital ratio is '},num2str(std_comp_rnd_cap_dt_rounded))));
disp(char(strcat({'round beta in capital ratio reg for 5-year horizon is '},num2str(beta_5yr_cap_rounded))));
disp(char(strcat({'--> capital measure increase by 2 StDevs implies cumulative prod. growth '},num2str(round(implied_cum_gro_compustat_cap_pct,1)),'% over 5 years.')));

fname=strcat(['output_for_paper\Figures\comp_rnd_ratios']);    
saveas(jj,strcat(fname))
saveas(jj,strcat(fname),'jpg')
saveas(jj,strcat(fname),'png')
print(strcat(fname),'-dpdf')



%% BEA ratios high R&D only

[~,bea_rnd_cap_dt] = one_sided_hp_filter_kalman(T.bea_pct_krnd_kpriv,smoothing);
[~,bea_rnd_inv_dt] = one_sided_hp_filter_kalman(T.bea_pct_irnd_ipriv,smoothing);

% standard deviations used in interpreting reg results
std_bea_rnd_cap_dt = std(bea_rnd_cap_dt);
std_bea_rnd_inv_dt = std(bea_rnd_inv_dt);
disp(char(strcat({'std dev of dt bea Krnd/Kpriv is '},num2str(std_bea_rnd_cap_dt))));
disp(char(strcat({'std dev of dt bea Irnd/Ipriv is '},num2str(std_bea_rnd_inv_dt))));

% [~,frac_at_high_rnd_dt] = hp_filter(frac_at_high_rnd,smoothing);
jj = 2;
RAWS = 3;
COLUMNS = 2;
count = 0;
table = cell(RAWS*COLUMNS);
figure(jj)
Stdvars = [];
tables = zeros(8,3);
pvals = zeros(3,3);

for lag = [5 7 10]
    
tfpygr_avr = tsmovavg(T.tfpyg(2:end), 's', lag, 1);
ii = 0;
    for var = [bea_rnd_cap_dt bea_rnd_inv_dt]
        Stdvars = [Stdvars std(var)];
        ii = ii + 1;
        count = count+1;

        F=[T.bondy1y T.bondy2y T.bondy3y T.bondy4y T.bondy5y T.bondy6y T.inflationy T.pdratioy T.ivoly T.anfci T.nfci T.baa10ym var];

        % Run Regression da   = ca + b_x * F(-1) + ea; %1973-2011
        lags = 2;
        weight = 1;
        start = 0;
        % Y = tfpygr(2:end,1);
        Y = tfpygr_avr(lag+start:end,1); %74-83
        X = [ones(length(Y),1) F(1+start:end-lag,:)];
        [BetaseEA,SesEA,RsqrEA,RsqradjEA,VCVEA,FEA]=olsgmm(Y,X,lags,weight);
        TstaEA = BetaseEA./SesEA;
        TCDFEA = tcdf(TstaEA,length(T.tfpyg(2:end,1)-5));
        PvalueEA_ols = 2*(1-tcdf(abs(TstaEA),length(Y)-2));
        table{count} = [BetaseEA SesEA PvalueEA_ols];
        R2(:,count) = RsqradjEA;
        Betaplot = BetaseEA;
        Betaplot(end,1) = 0;
        %disp(count); 
             subplot(RAWS,COLUMNS,count);
             box on; hold on;
             scatter(X(:,end),Y-X*Betaplot,10,'b','*');
        if lag == 5
        %  ylabel('Agg 5 year MA minus controls')
         ylabel('TFP Growth Rate (5 year MA)')
        yy = 1;
        end
        if lag == 7
        %  ylabel('Agg 7 year MA minus controls')
         ylabel('TFP Growth Rate (7 year MA)')
        yy = 2;
        end
        if lag == 10
        %  ylabel('Agg 10 year MA minus controls')
         ylabel('TFP Growth Rate (10 year MA)')
        yy = 3;
        end
         tables(1+(ii-1)*4:3+(ii-1)*4,yy) = [BetaseEA(end,1);SesEA(end,1);RsqradjEA];
         pvals(ii,yy) =  PvalueEA_ols(end,1);
        if ii == 1
         xlabel(['$K^{BEA}_{Priv,R\&D}/K^{BEA}_{Priv,Tot}$'],'interpreter','latex')
        end
        if ii == 2
         xlabel(['$I^{BEA}_{Priv,R\&D}/I^{BEA}_{Priv,Tot}$'],'interpreter','latex')
        end
        if ii == 1
         %axis([-0.25 0.25 -0.01 0.01]) 
         axis([-2 2 -1.5 1.5]) 
        else
         %axis([-0.6 0.6 -0.01 0.01]) 
         axis([-2 2 -1.5 1.5]) 
        end
            %F=[bondy1y bondy2y bondy3y bondy4y bondy5y bondy6y inflationy pdratio ivoly anfci nfci baa10ym];
            F =[T.bondy1y T.bondy2y T.bondy3y T.bondy4y T.bondy5y T.bondy6y T.inflationy T.pdratioy T.ivoly T.anfci T.nfci T.baa10ym];


        % Run Regression da   = ca + b_x * F(-1) + ea; %1973-2011
        lags = 4;
        weight = 1;
        start = 4;
        % Y = tfpygr(2:end,1);
        Y = tfpygr_avr(lag+start:end,1); %74-83
        X = [ones(length(Y),1) F(1+start:end-lag,:)];
        [BetaseEA,SesEA,RsqrEA,RsqradjEA,VCVEA,FEA]=olsgmm(Y,X,lags,weight);
          tables(4+(ii-1)*4,yy) = [RsqradjEA];

    end

 
end

disp('BEA rnd ratios results');
[[1:size(tables,1)]',tables]

std_bea_rnd_cap_dt_rounded = round(std_bea_rnd_cap_dt/100,3);
beta_5yr_cap_rounded = round(tables(1,1),2);
implied_cum_gro_bea_cap_pct = 100*5*2*std_bea_rnd_cap_dt_rounded*beta_5yr_cap_rounded;
% 5 years, 2 std devs, use capital ratio std dev, use beta for 5-yr horizon
disp(char(strcat({'rounded StDevs of bea high rnd capital ratio is '},num2str(std_bea_rnd_cap_dt_rounded))));
disp(char(strcat({'round beta in capital ratio reg for 5-year horizon is '},num2str(beta_5yr_cap_rounded))));
disp(char(strcat({'--> capital measure increase by 2 StDevs implies cumulative prod. growth '},num2str(round(implied_cum_gro_bea_cap_pct,1)),'% over 5 years.')));


fname=strcat(['output_for_paper\Figures\bea_rnd_ratios']);    
saveas(jj,strcat(fname))
saveas(jj,strcat(fname),'jpg')
saveas(jj,strcat(fname),'png')
print(strcat(fname),'-dpdf')





%% BEA ratios govt only

[~,bea_govt_cap_dt] = one_sided_hp_filter_kalman(T.bea_pct_kg_ktot,smoothing);
% note: can also try T.bea_pct_kgnonrnd_ktot
[~,bea_govt_inv_dt] = one_sided_hp_filter_kalman(T.bea_pct_ig_itot,smoothing);

% standard deviations used in interpreting reg results
std_bea_govt_cap_dt = std(bea_govt_cap_dt);
std_bea_govt_inv_dt = std(bea_govt_inv_dt);
disp(char(strcat({'std dev of dt bea Kgovt/Ktot is '},num2str(std_bea_govt_cap_dt))));
disp(char(strcat({'std dev of dt bea Igovt/Itot is '},num2str(std_bea_govt_inv_dt))));

% [~,frac_at_high_rnd_dt] = hp_filter(frac_at_high_rnd,smoothing);
jj = 3;
RAWS = 3;
COLUMNS = 2;
count = 0;
table = cell(RAWS*COLUMNS);
figure(jj)
Stdvars = [];
tables = zeros(8,3);
pvals = zeros(3,3);

for lag = [5 7 10]
    
tfpygr_avr = tsmovavg(T.tfpyg(2:end), 's', lag, 1);
ii = 0;
    for var = [bea_govt_cap_dt bea_govt_inv_dt]
        Stdvars = [Stdvars std(var)];
        ii = ii + 1;
        count = count+1;

        F=[T.bondy1y T.bondy2y T.bondy3y T.bondy4y T.bondy5y T.bondy6y T.inflationy T.pdratioy T.ivoly T.anfci T.nfci T.baa10ym var];

        % Run Regression da   = ca + b_x * F(-1) + ea; %1973-2011
        lags = 2;
        weight = 1;
        start = 0;
        % Y = tfpygr(2:end,1);
        Y = tfpygr_avr(lag+start:end,1); %74-83
        X = [ones(length(Y),1) F(1+start:end-lag,:)];
        [BetaseEA,SesEA,RsqrEA,RsqradjEA,VCVEA,FEA]=olsgmm(Y,X,lags,weight);
        TstaEA = BetaseEA./SesEA;
        TCDFEA = tcdf(TstaEA,length(T.tfpyg(2:end,1)-5));
        PvalueEA_ols = 2*(1-tcdf(abs(TstaEA),length(Y)-2));
        table{count} = [BetaseEA SesEA PvalueEA_ols];
        R2(:,count) = RsqradjEA;
        Betaplot = BetaseEA;
        Betaplot(end,1) = 0;
        %disp(count); 
             subplot(RAWS,COLUMNS,count);
             box on; hold on;
             scatter(X(:,end),Y-X*Betaplot,10,'b','*');
        if lag == 5
        %  ylabel('Agg 5 year MA minus controls')
         ylabel('TFP Growth Rate (5 year MA)')
        yy = 1;
        end
        if lag == 7
        %  ylabel('Agg 7 year MA minus controls')
         ylabel('TFP Growth Rate (7 year MA)')
        yy = 2;
        end
        if lag == 10
        %  ylabel('Agg 10 year MA minus controls')
         ylabel('TFP Growth Rate (10 year MA)')
        yy = 3;
        end
         tables(1+(ii-1)*4:3+(ii-1)*4,yy) = [BetaseEA(end,1);SesEA(end,1);RsqradjEA];
         pvals(ii,yy) =  PvalueEA_ols(end,1);
        if ii == 1
         xlabel(['$K^{BEA}_{Priv,R\&D}/K^{BEA}_{Priv,Tot}$'],'interpreter','latex')
        end
        if ii == 2
         xlabel(['$I^{BEA}_{Priv,R\&D}/I^{BEA}_{Priv,Tot}$'],'interpreter','latex')
        end
        if ii == 1
         %axis([-0.25 0.25 -0.01 0.01]) 
         axis([-2 5 -1.5 1.5]) 
        else
         %axis([-0.6 0.6 -0.01 0.01]) 
         axis([-5 15 -1.5 1.5]) 
        end
            %F=[bondy1y bondy2y bondy3y bondy4y bondy5y bondy6y inflationy pdratio ivoly anfci nfci baa10ym];
            F =[T.bondy1y T.bondy2y T.bondy3y T.bondy4y T.bondy5y T.bondy6y T.inflationy T.pdratioy T.ivoly T.anfci T.nfci T.baa10ym];


        % Run Regression da   = ca + b_x * F(-1) + ea; %1973-2011
        lags = 4;
        weight = 1;
        start = 4;
        % Y = tfpygr(2:end,1);
        Y = tfpygr_avr(lag+start:end,1); %74-83
        X = [ones(length(Y),1) F(1+start:end-lag,:)];
        [BetaseEA,SesEA,RsqrEA,RsqradjEA,VCVEA,FEA]=olsgmm(Y,X,lags,weight);
          tables(4+(ii-1)*4,yy) = [RsqradjEA];

    end

 
end

disp('BEA govt ratios results');
[[1:size(tables,1)]',tables]

fname=strcat(['output_for_paper\Figures\bea_govt_ratios']);    
saveas(jj,strcat(fname))
saveas(jj,strcat(fname),'jpg')
saveas(jj,strcat(fname),'png')
print(strcat(fname),'-dpdf')





%% BEA ratios high R&D minus government

[~,bea_diff_rnd_cap_dt] = one_sided_hp_filter_kalman(T.bea_pct_krnd_kpriv - T.bea_pct_kg_ktot,smoothing);
[~,bea_diff_rnd_inv_dt] = one_sided_hp_filter_kalman(T.bea_pct_irnd_ipriv - T.bea_pct_ig_itot,smoothing);

% standard deviations used in interpreting reg results
std_bea_diff_rnd_cap_dt = std(bea_diff_rnd_cap_dt);
std_bea_diff_rnd_inv_dt = std(bea_diff_rnd_inv_dt);
disp(char(strcat({'std dev of dt bea (Krnd/Kpriv-Kg/Ktot) is '},num2str(std_bea_diff_rnd_cap_dt))));
disp(char(strcat({'std dev of dt bea (Irnd/Ipriv-Ig/Itot) is '},num2str(std_bea_diff_rnd_inv_dt))));

% [~,frac_at_high_rnd_dt] = hp_filter(frac_at_high_rnd,smoothing);
jj = 4;
RAWS = 3;
COLUMNS = 2;
count = 0;
table = cell(RAWS*COLUMNS);
figure(jj)
Stdvars = [];
tables = zeros(8,3);
pvals = zeros(3,3);

for lag = [5 7 10]
    
tfpygr_avr = tsmovavg(T.tfpyg(2:end), 's', lag, 1);
ii = 0;
    for var = [bea_diff_rnd_cap_dt bea_diff_rnd_inv_dt]
        Stdvars = [Stdvars std(var)];
        ii = ii + 1;
        count = count+1;

        F=[T.bondy1y T.bondy2y T.bondy3y T.bondy4y T.bondy5y T.bondy6y T.inflationy T.pdratioy T.ivoly T.anfci T.nfci T.baa10ym var];

        % Run Regression da   = ca + b_x * F(-1) + ea; %1973-2011
        lags = 2;
        weight = 1;
        start = 0;
        % Y = tfpygr(2:end,1);
        Y = tfpygr_avr(lag+start:end,1); %74-83
        X = [ones(length(Y),1) F(1+start:end-lag,:)];
        [BetaseEA,SesEA,RsqrEA,RsqradjEA,VCVEA,FEA]=olsgmm(Y,X,lags,weight);
        TstaEA = BetaseEA./SesEA;
        TCDFEA = tcdf(TstaEA,length(T.tfpyg(2:end,1)-5));
        PvalueEA_ols = 2*(1-tcdf(abs(TstaEA),length(Y)-2));
        table{count} = [BetaseEA SesEA PvalueEA_ols];
        R2(:,count) = RsqradjEA;
        Betaplot = BetaseEA;
        Betaplot(end,1) = 0;
        %disp(count); 
             subplot(RAWS,COLUMNS,count);
             box on; hold on;
             scatter(X(:,end),Y-X*Betaplot,10,'b','*');
        if lag == 5
        %  ylabel('Agg 5 year MA minus controls')
         ylabel('TFP Growth Rate (5 year MA)')
        yy = 1;
        end
        if lag == 7
        %  ylabel('Agg 7 year MA minus controls')
         ylabel('TFP Growth Rate (7 year MA)')
        yy = 2;
        end
        if lag == 10
        %  ylabel('Agg 10 year MA minus controls')
         ylabel('TFP Growth Rate (10 year MA)')
        yy = 3;
        end
         tables(1+(ii-1)*4:3+(ii-1)*4,yy) = [BetaseEA(end,1);SesEA(end,1);RsqradjEA];
         pvals(ii,yy) =  PvalueEA_ols(end,1);
        if ii == 1
         xlabel(['$K^{BEA}_{Priv,R\&D}/K^{BEA}_{Priv,Tot}$'],'interpreter','latex')
        end
        if ii == 2
         xlabel(['$I^{BEA}_{Priv,R\&D}/I^{BEA}_{Priv,Tot}$'],'interpreter','latex')
        end
        if ii == 1
         %axis([-0.25 0.25 -0.01 0.01]) 
         axis([-2 5 -1.5 1.5]) 
        else
         %axis([-0.6 0.6 -0.01 0.01]) 
         axis([-5 15 -1.5 1.5]) 
        end
            %F=[bondy1y bondy2y bondy3y bondy4y bondy5y bondy6y inflationy pdratio ivoly anfci nfci baa10ym];
            F =[T.bondy1y T.bondy2y T.bondy3y T.bondy4y T.bondy5y T.bondy6y T.inflationy T.pdratioy T.ivoly T.anfci T.nfci T.baa10ym];


        % Run Regression da   = ca + b_x * F(-1) + ea; %1973-2011
        lags = 4;
        weight = 1;
        start = 4;
        % Y = tfpygr(2:end,1);
        Y = tfpygr_avr(lag+start:end,1); %74-83
        X = [ones(length(Y),1) F(1+start:end-lag,:)];
        [BetaseEA,SesEA,RsqrEA,RsqradjEA,VCVEA,FEA]=olsgmm(Y,X,lags,weight);
          tables(4+(ii-1)*4,yy) = [RsqradjEA];

    end

 
end

disp('BEA rnd minus govt ratios results');
[[1:size(tables,1)]',tables]

fname=strcat(['output_for_paper\Figures\bea_diff_rnd_ratios']);    
saveas(jj,strcat(fname))
saveas(jj,strcat(fname),'jpg')
saveas(jj,strcat(fname),'png')
print(strcat(fname),'-dpdf')




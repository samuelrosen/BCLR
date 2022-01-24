%function compare_mod_long_for_Referee3_response(mod1,mod2,varargin)

% note: figure in BCLR_101 is "1_vs_4_ea_es_irf1"

% used in BCLR_101 as of early September
%mod1 = 105;
%mod2 = 402;
% equivalent calibrations in BCLR_102 as of december 2020
mod1 = 81;
mod2 = 88;

close all

addpath(genpath('Monopoly Power'))
%clearvars -global -except mod1 varargin; clc;
clearvars -global -except mod1 mod2; clc;

COLUMNS =2; % By default, only 2 shocks and hence 2 cols of IRFs

tex_variables; % add lookup table for tex variable names for vars

irf_sim=20;


%% Choose shocks and corresponding titles for each column
% if length(varargin)>=2
%   shocks = {varargin{1}; varargin{2}};
% else
    disp('Using default shocks ea and es');
    shocks = {'ea'; 'es'};
% end

MyTitles = {'NEED TITLE'; 'NEED TITLE'};
for z=1:COLUMNS
    if strcmp(shocks(z),'ea')
        MyTitles{z}='Short-Run Shock ($\varepsilon_a$)';
    elseif strcmp(shocks(z),'ex')
        MyTitles{z}='Long-Run Shock ($\varepsilon_x$)';        
    elseif strcmp(shocks(z),'es')
        MyTitles{z}='Vol Shock ($\varepsilon_{\sigma}$)';              
    end    
end


%% Choose variables for IRF
% if length(varargin)==3
%     irf_vars={varargin{3}};
% else
%       irf_vars={{'x';'x_f'}};
%     irf_vars={{'ia';'Ic';'kpkg'}};
%     irf_vars={{'dgdp';'da';'dyp';'dc';'dip';'igitot';'qp';'VexpK';'ds'},{'ipitot';'sitot';'igitot';'ipiptot'},{'ntotal';'npnt'}};
%       irf_vars={{'dgdp';'da';'dyp';'dc';'dip';'ds';'igitot';'qp';'v_p';'qc'},{'dgdp';'da';'dc';'dip';'ds';'igitot'}};
%      irf_vars={{'dgdp';'da';'dc';'dip';'ds';'igitot'}};
    irf_vars={{'dgdp';'da';'dyp';'dc';'dip';'ds';'igitot';'qp';'v_p';'qc'}};

%     irf_vars={{'dy';'da';'dyp';'dc';'dip';'igitot';'qp';'VexpK'}};
    
    %irf_vars={{'da';'condE_exr';'corr_m&exr';'condStd_m';'condStd_exr';'covar_m&exr'}};
    %irf_vars={{'dc';'di';'rf';'covar_m&r';'covar_m&rc'}};
% end

%compare_mod(5,5,'ea','ex',{'dc';'di';'rf';'covar_m&r';'covar_m&rc'})
%compare_mod(5,5,'ex','es',{'dc';'di';'rf';'covar_m&r';'covar_m&rc'})


%% Plot of IRFs using Dynare++ IRF output
for j=1:length(irf_vars) %% Loop over lists within irf_vars
    
    % set size of figure so it fills page
    set(gcf, 'PaperPositionMode', 'manual');
    set(gcf, 'PaperUnits', 'inches');
    set(gcf, 'PaperPosition', [0 0 7.00 7.00]);
%     set(gca,'fontsize',100) 
    temp_irf=irf_vars{j};
    figure(j)
    
    for i=1:3 %% Loop over models
        % Just loading what we need and setting the line styles
        if i==1
            %% Fake: just to have something
            load(strcat('Results/Monopoly_Power_Approx_',num2str(mod1),'/Monopoly_Power_Approx_',num2str(mod1),'.mat'));
            style='-k';
        elseif i==2    
            load(strcat('Results/Monopoly_Power_Approx_',num2str(mod1),'/Monopoly_Power_Approx_',num2str(mod1),'.mat'));
            style='-b';
        elseif i==3
            load(strcat('Results/Monopoly_Power_Approx_',num2str(mod2),'/Monopoly_Power_Approx_',num2str(mod2),'.mat'));
            style='--r';
        end
                       
        counter=1;
        
        % Starting the loop across variables
        for k=1:length(temp_irf)
            
            % Extract first 5 letters to determine if conditional moment
            var_string = char(temp_irf{k});
            var_first_5 = var_string(1:min(5,length(var_string)));
            % if conditional corr or covar then extract more info
            if strcmp(var_first_5,'corr_') || strcmp(var_first_5,'covar')
                bothvars = var_string((strfind(var_string,'_')+1):length(var_string));
                sep = strfind(bothvars,'&');
                corr_var1 = bothvars(1:sep-1);
                corr_var2 = bothvars(sep+1:length(bothvars));    
                % grab actual values so can add back starting value to demeaned series
                corr_start = eval(strcat(['irf_condCorr_start(dyn_i_',corr_var1,',dyn_i_',corr_var2,',1)']));
                std_var1_start = eval(strcat(['irf_condStd_start(dyn_i_',corr_var1,',1)']));
                std_var2_start = eval(strcat(['irf_condStd_start(dyn_i_',corr_var2,',1)']));                             
            end
            
            %% First COLUMN
            subplot(length(temp_irf),COLUMNS,counter);
            box on; hold on;
            if i~=1 && exist(strcat(['dyn_irfp_',shocks{1},'_mean'])) % also checks if shock is in calibration
%                 if strcmp(var_first_5,'condE') % if conditional expected value
%                     plot(1:irf_sim,[eval(strcat(['irf_condE_',shocks{1},'(dyn_i_',temp_irf{k}(7:end),',1:irf_sim)']))],style,'LineWidth',2);
%                 else
%                     plot(1:irf_sim,[eval(strcat(['dyn_irfp_',shocks{1},'_mean(dyn_i_',temp_irf{k},',1:irf_sim)']))],style,'LineWidth',2);
%                 end
                if strcmp(var_first_5,'condE') % if conditional expected value
                    plot(1:irf_sim,[eval(strcat(['irf_condE_',shocks{1},'(dyn_i_',temp_irf{k}(7:end),',1:irf_sim)']))],style,'LineWidth',2);
                elseif strcmp(var_first_5,'condS') % if conditional standard deviation
                    plot(1:irf_sim,[eval(strcat(['irf_condStd_',shocks{1},'(dyn_i_',temp_irf{k}(9:end),',1:irf_sim)']))],style,'LineWidth',2);
                elseif strcmp(var_first_5,'corr_') || strcmp(var_first_5,'covar') % if conditional correlation or covariance
                    for w=1:irf_sim
                        corr(w) = eval(strcat(['irf_condCorr_',shocks{1},'(dyn_i_',corr_var1,',dyn_i_',corr_var2,',w)']));
                        corr_check(w) = eval(strcat(['irf_condCorr_',shocks{1},'(dyn_i_',corr_var2,',dyn_i_',corr_var1,',w)']));
                        std_var1(w)= eval(strcat(['irf_condStd_',shocks{1},'(dyn_i_',corr_var1,',w)'])) + std_var1_start;
                        std_var2(w)= eval(strcat(['irf_condStd_',shocks{1},'(dyn_i_',corr_var2,',w)'])) + std_var2_start;
                    end
                    if corr~=corr_check % make sure pulling the right values
                        %error('correlations not equal. something is wrong.')
                    end
                    if strcmp(var_first_5,'corr_') % actually plot correlation
                        plot(1:irf_sim,corr,style,'LineWidth',2);
                        clear corr
                    elseif strcmp(var_first_5,'covar') % actually plot covariance
                        covar_raw = (corr+corr_start).*std_var1.*std_var2; % added back corr_start so actual corr values
                        covar_start = corr_start*std_var1_start*std_var2_start;
                        covar = covar_raw - covar_start;
                        plot(1:irf_sim,covar,style,'LineWidth',2);
                        clear covar_raw covar_start covar
                    end                                  
                else
                    plot(1:irf_sim,[eval(strcat(['dyn_irfp_',shocks{1},'_mean(dyn_i_',temp_irf{k},',1:irf_sim)']))],style,'LineWidth',2);
                end                    
            else
                plot(1:irf_sim,zeros(1,irf_sim),style,'LineWidth',2)
            end
            
            
            if k==1, title(MyTitles{1},'interpreter','latex'); end
            if k==length(temp_irf), xlabel('Quarters'); end
            
            if strcmp(var_first_5,'condE')
                short_var_name = temp_irf{k}(7:end);
                ylabel(['$E_{t-1} [$ ' variable_names{strcmp(short_var_name,variable_names(:,1)),2} ' $ ]$'],'interpreter','latex')
            elseif strcmp(var_first_5,'condS')
                short_var_name = temp_irf{k}(9:end);
                ylabel(['$Std_{t-1} [$ ' variable_names{strcmp(short_var_name,variable_names(:,1)),2} ' $ ]$'],'interpreter','latex')
            elseif strcmp(var_first_5,'corr_')
                ylabel(['$corr_{t-1} [$ ' variable_names{strcmp(corr_var1,variable_names(:,1)),2} ',' variable_names{strcmp(corr_var2,variable_names(:,1)),2} ' $ ]$'],'interpreter','latex')                
            elseif strcmp(var_first_5,'covar')
                ylabel(['$cov_{t-1} [$ ' variable_names{strcmp(corr_var1,variable_names(:,1)),2} ',' variable_names{strcmp(corr_var2,variable_names(:,1)),2} ' $ ]$'],'interpreter','latex')                                
            else
                ylabel(variable_names{strcmp(temp_irf{k},variable_names(:,1)),2},'interpreter','latex','FontSize', 14) %#ok<*NODEF>
            end
            ytickformat('%.2f')
%             if k == 1;
%                 axis([1,irf_sim -0.025 0.025])
%             else
            axis('tight')
%             end;
            counter=counter+1;
            
            
            %% Second COLUMN
            subplot(length(temp_irf),COLUMNS,counter);
            box on; hold on;
            if i~=1 && exist(strcat(['dyn_irfp_',shocks{2},'_mean'])) % also checks if shock is in calibration
%                 if strcmp(var_first_5,'condE') % if conditional expected value
%                     h(i)=plot(1:irf_sim,[eval(strcat(['irf_condE_',shocks{2},'(dyn_i_',temp_irf{k}(7:end),',1:irf_sim)']))],style,'LineWidth',2);
%                 else
%                     h(i)=plot(1:irf_sim,[eval(strcat(['dyn_irfp_',shocks{2},'_mean(dyn_i_',temp_irf{k},',1:irf_sim)']))],style,'LineWidth',2);
%                 end   
                if strcmp(var_first_5,'condE') % if conditional expected value
                    h(i)=plot(1:irf_sim,[eval(strcat(['irf_condE_',shocks{2},'(dyn_i_',temp_irf{k}(7:end),',1:irf_sim)']))],style,'LineWidth',2);
                elseif strcmp(var_first_5,'condS') % if conditional standard deviation
                    h(i)=plot(1:irf_sim,[eval(strcat(['irf_condStd_',shocks{2},'(dyn_i_',temp_irf{k}(9:end),',1:irf_sim)']))],style,'LineWidth',2);                    
                elseif strcmp(var_first_5,'corr_') || strcmp(var_first_5,'covar') % if conditional correlation or covariance
                    for w=1:irf_sim
                        corr(w) = eval(strcat(['irf_condCorr_',shocks{2},'(dyn_i_',corr_var1,',dyn_i_',corr_var2,',w)']));
                        corr_check(w) = eval(strcat(['irf_condCorr_',shocks{2},'(dyn_i_',corr_var2,',dyn_i_',corr_var1,',w)']));
                        std_var1(w)= eval(strcat(['irf_condStd_',shocks{2},'(dyn_i_',corr_var1,',w)'])) + std_var1_start;
                        std_var2(w)= eval(strcat(['irf_condStd_',shocks{2},'(dyn_i_',corr_var2,',w)'])) + std_var2_start;
                    end
                    if corr~=corr_check % make sure pulling the right values
                        %error('correlations not equal. something is wrong.')
                    end
                    if strcmp(var_first_5,'corr_') % actually plot correlation
                        h(i)=plot(1:irf_sim,corr,style,'LineWidth',2);
                        clear corr
                    elseif strcmp(var_first_5,'covar') % actually plot covariance
                        covar_raw = (corr+corr_start).*std_var1.*std_var2; % added back corr_start so actual corr values
                        covar_start = corr_start*std_var1_start*std_var2_start;
                        covar = covar_raw - covar_start;
                        h(i)=plot(1:irf_sim,covar,style,'LineWidth',2);
                        clear covar_raw covar_start covar
                    end   
                else
                    h(i)=plot(1:irf_sim,[eval(strcat(['dyn_irfp_',shocks{2},'_mean(dyn_i_',temp_irf{k},',1:irf_sim)']))],style,'LineWidth',2);
                end                                    
            else
                h(i)=plot(1:irf_sim,zeros(1,irf_sim),style,'LineWidth',2);
            end
            
            if k==1, title(MyTitles{2},'interpreter','latex'); end
            if k==length(temp_irf), xlabel('Quarters'); end
            
% %             if k == 1;
%                 axis([1,irf_sim -0.025 0.025])
%             else
            axis('tight')
%             end;
            counter=counter+1;
             
            
            %% Fixing the legend
            if k==length(temp_irf) && i==3 
                legend(h(2:3),strcat(['Model ',num2str(mod1)]),strcat(['Model ',num2str(mod2)]));
                set(legend,'Orientation','horizontal','FontSize',8,'Position',[0.4019 0.007035 0.1896 0.03571]);
            end
            
         end  
    end 
        fname=strcat([num2str(mod1),'_vs_',num2str(mod2),'_',shocks{1},'_',shocks{2},'_long_irf', num2str(j)]);    
    saveas(j,strcat('Results/for_R3_chk_from_dynout_',fname))
    saveas(j,strcat('Results/for_R3_chk_from_dynout_',fname),'jpg')
    saveas(j,strcat('Results/for_R3_chk_from_dynout_',fname),'png')

    print(strcat('Results/for_R3_chk_from_dynout_',fname),'-dpdf')
    %print(strcat('Results/',fname),'-dpsc')
    close(j)
end
    
   

%% Plot of IRFs using simulations from dyn_ss
for j=1:length(irf_vars) %% Loop over lists within irf_vars
    
    % set size of figure so it fills page
    set(gcf, 'PaperPositionMode', 'manual');
    set(gcf, 'PaperUnits', 'inches');
    set(gcf, 'PaperPosition', [0 0 7.00 7.00]);
%     set(gca,'fontsize',100) 
    temp_irf=irf_vars{j};
    figure(j)
    
    for i=1:3 %% Loop over models
        % Just loading what we need and setting the line styles
        if i==1
            % Fake: just to have something
            load(strcat('Results/Monopoly_Power_Approx_',num2str(mod1),'/Monopoly_Power_Approx_',num2str(mod1),'.mat'));
            style='-k';
            MyMat_for_simul = strcat('Results/Monopoly_Power_Approx_',num2str(mod1),'/Monopoly_Power_Approx_',num2str(mod1),'.mat'); 
        elseif i==2    
            load(strcat('Results/Monopoly_Power_Approx_',num2str(mod1),'/Monopoly_Power_Approx_',num2str(mod1),'.mat'));
            style='-b';
            MyMat_for_simul = strcat('Results/Monopoly_Power_Approx_',num2str(mod1),'/Monopoly_Power_Approx_',num2str(mod1),'.mat'); 
        elseif i==3
            load(strcat('Results/Monopoly_Power_Approx_',num2str(mod2),'/Monopoly_Power_Approx_',num2str(mod2),'.mat'));
            style='--r';
            MyMat_for_simul = strcat('Results/Monopoly_Power_Approx_',num2str(mod2),'/Monopoly_Power_Approx_',num2str(mod2),'.mat'); 
        end
                       
        counter=1;
        
        % simulate shocks from dyn_ss
        shocks_none = zeros(2,irf_sim+1);
        shocks_dtfp = shocks_none;
        shocks_dtfp(1,2) = sqrt(dyn_vcov_exo(1,1));
        shocks_pvol = shocks_none;
        shocks_pvol(2,2) = sqrt(dyn_vcov_exo(2,2));              
        dyn_sim_none = dynare_simul_pc(MyMat_for_simul, shocks_none, dyn_ss); % dynare_simul_pc is dynare_simul that will work on PCs
        dyn_sim_dtfp = dynare_simul_pc(MyMat_for_simul, shocks_dtfp, dyn_ss); % dynare_simul_pc is dynare_simul that will work on PCs
        dyn_sim_pvol = dynare_simul_pc(MyMat_for_simul, shocks_pvol, dyn_ss); % dynare_simul_pc is dynare_simul that will work on PCs
        
        sim_irf_ea = dyn_sim_dtfp - dyn_sim_none;
        sim_irf_es = dyn_sim_pvol - dyn_sim_none;
             
        % save select mod1 series for later figure
        if i==1
            save_irf_dynss_ea_igitot = sim_irf_ea(dyn_i_igitot, 1:irf_sim+1);
            save_irf_dynss_ea_qc     = sim_irf_ea(dyn_i_qc,     1:irf_sim+1);
        end        
        
        % Starting the loop across variables
        for k=1:length(temp_irf)

            % First COLUMN
            subplot(length(temp_irf),COLUMNS,counter);
            box on; hold on;
            if i~=1 % also checks if shock is in calibration
                plot(1:irf_sim,[eval(strcat(['sim_irf_',shocks{1},'(dyn_i_',temp_irf{k},',1:irf_sim)']))],style,'LineWidth',2);
            else
                plot(1:irf_sim,zeros(1,irf_sim),style,'LineWidth',2)
            end
            
            
            if k==1, title(MyTitles{1},'interpreter','latex'); end
            if k==length(temp_irf), xlabel('Quarters'); end
            
            ylabel(variable_names{strcmp(temp_irf{k},variable_names(:,1)),2},'interpreter','latex','FontSize', 14) %#ok<*NODEF>
            ytickformat('%.2f')
            axis('tight')
            counter=counter+1;
                        
            % Second COLUMN
            subplot(length(temp_irf),COLUMNS,counter);
            box on; hold on;
            if i~=1 
                h(i)=plot(1:irf_sim,[eval(strcat(['sim_irf_',shocks{2},'(dyn_i_',temp_irf{k},',1:irf_sim)']))],style,'LineWidth',2);
            else
                h(i)=plot(1:irf_sim,zeros(1,irf_sim),style,'LineWidth',2);
            end
            
            if k==1, title(MyTitles{2},'interpreter','latex'); end
            if k==length(temp_irf), xlabel('Quarters'); end
            
            axis('tight')
            counter=counter+1;
                         
            % Fixing the legend
            if k==length(temp_irf) && i==3 
                legend(h(2:3),strcat(['Model ',num2str(mod1)]),strcat(['Model ',num2str(mod2)]));
                set(legend,'Orientation','horizontal','FontSize',8,'Position',[0.4019 0.007035 0.1896 0.03571]);
            end
            
         end  
    end 
        fname=strcat([num2str(mod1),'_vs_',num2str(mod2),'_',shocks{1},'_',shocks{2},'_long_irf', num2str(j)]);    
    saveas(j,strcat('Results/for_R3_sim_from_dynss_',fname))
    saveas(j,strcat('Results/for_R3_sim_from_dynss_',fname),'jpg')
    saveas(j,strcat('Results/for_R3_sim_from_dynss_',fname),'png')

    print(strcat('Results/for_R3_sim_from_dynss_',fname),'-dpdf')
    %print(strcat('Results/',fname),'-dpsc')
    close(j)
end
    


%% Plot of IRFs using simulations from a different point
for j=1:length(irf_vars) %% Loop over lists within irf_vars
    
    % set size of figure so it fills page
    set(gcf, 'PaperPositionMode', 'manual');
    set(gcf, 'PaperUnits', 'inches');
    set(gcf, 'PaperPosition', [0 0 7.00 7.00]);
%     set(gca,'fontsize',100) 
    temp_irf=irf_vars{j};
    figure(j)
    
    for i=1:3 %% Loop over models
        % Just loading what we need and setting the line styles
        if i==1
            % Fake: just to have something
            load(strcat('Results/Monopoly_Power_Approx_',num2str(mod1),'/Monopoly_Power_Approx_',num2str(mod1),'.mat'));
            style='-k';
            MyMat_for_simul = strcat('Results/Monopoly_Power_Approx_',num2str(mod1),'/Monopoly_Power_Approx_',num2str(mod1),'.mat'); 
        elseif i==2    
            load(strcat('Results/Monopoly_Power_Approx_',num2str(mod1),'/Monopoly_Power_Approx_',num2str(mod1),'.mat'));
            style='-b';
            MyMat_for_simul = strcat('Results/Monopoly_Power_Approx_',num2str(mod1),'/Monopoly_Power_Approx_',num2str(mod1),'.mat'); 
        elseif i==3
            load(strcat('Results/Monopoly_Power_Approx_',num2str(mod2),'/Monopoly_Power_Approx_',num2str(mod2),'.mat'));
            style='--r';
            MyMat_for_simul = strcat('Results/Monopoly_Power_Approx_',num2str(mod2),'/Monopoly_Power_Approx_',num2str(mod2),'.mat'); 
        end
                       
        counter=1;
        
        % simulate shocks from dyn_ss
        N_dtfp_shk_lead = 100;
        shocks_none = zeros(2,N_dtfp_shk_lead+irf_sim+1);
        shocks_none(1,1:N_dtfp_shk_lead) = -0.0064; % small dtfp shock size
        dyn_sim_none = dynare_simul_pc(MyMat_for_simul, shocks_none, dyn_ss); % dynare_simul_pc is dynare_simul that will work on PCs
        %figure(9);
        %plot(dyn_sim_none(dyn_i_kratio,:));
        disp(strcat('new kg/ktot ratio =',num2str(dyn_sim_none(dyn_i_kratio,100))));
        shocks_dtfp = shocks_none;
        shocks_dtfp(1,N_dtfp_shk_lead+1) = sqrt(dyn_vcov_exo(1,1));
        shocks_pvol = shocks_none;
        shocks_pvol(2,N_dtfp_shk_lead+1) = sqrt(dyn_vcov_exo(2,2));                      
        dyn_sim_dtfp = dynare_simul_pc(MyMat_for_simul, shocks_dtfp, dyn_ss); % dynare_simul_pc is dynare_simul that will work on PCs
        dyn_sim_pvol = dynare_simul_pc(MyMat_for_simul, shocks_pvol, dyn_ss); % dynare_simul_pc is dynare_simul that will work on PCs
        
        sim_irf_ea = dyn_sim_dtfp - dyn_sim_none;
        sim_irf_es = dyn_sim_pvol - dyn_sim_none;
               
        % save select mod1 series for later figure
        if i==1
            save_irf_lowkg_ea_igitot = sim_irf_ea(dyn_i_igitot, (N_dtfp_shk_lead):(irf_sim+N_dtfp_shk_lead));
            save_irf_lowkg_ea_qc     = sim_irf_ea(dyn_i_qc,     (N_dtfp_shk_lead):(irf_sim+N_dtfp_shk_lead));
        end
        
        % Starting the loop across variables
        for k=1:length(temp_irf)

            % First COLUMN
            subplot(length(temp_irf),COLUMNS,counter);
            box on; hold on;
            if i~=1 % also checks if shock is in calibration
                plot(1:irf_sim,[eval(strcat(['sim_irf_',shocks{1},'(dyn_i_',temp_irf{k},',(N_dtfp_shk_lead):(irf_sim+N_dtfp_shk_lead-1))']))],style,'LineWidth',2);
            else
                plot(1:irf_sim,zeros(1,irf_sim),style,'LineWidth',2)
            end
            
            
            if k==1, title(MyTitles{1},'interpreter','latex'); end
            if k==length(temp_irf), xlabel('Quarters'); end
            
            ylabel(variable_names{strcmp(temp_irf{k},variable_names(:,1)),2},'interpreter','latex','FontSize', 14) %#ok<*NODEF>
            ytickformat('%.2f')
            axis('tight')
            counter=counter+1;
                        
            % Second COLUMN
            subplot(length(temp_irf),COLUMNS,counter);
            box on; hold on;
            if i~=1 
                h(i)=plot(1:irf_sim,[eval(strcat(['sim_irf_',shocks{2},'(dyn_i_',temp_irf{k},',(N_dtfp_shk_lead):(irf_sim+N_dtfp_shk_lead-1))']))],style,'LineWidth',2);
            else
                h(i)=plot(1:irf_sim,zeros(1,irf_sim),style,'LineWidth',2);
            end
            
            if k==1, title(MyTitles{2},'interpreter','latex'); end
            if k==length(temp_irf), xlabel('Quarters'); end
            
            axis('tight')
            counter=counter+1;
                         
            % Fixing the legend
            if k==length(temp_irf) && i==3 
                legend(h(2:3),strcat(['Model ',num2str(mod1)]),strcat(['Model ',num2str(mod2)]));
                set(legend,'Orientation','horizontal','FontSize',8,'Position',[0.4019 0.007035 0.1896 0.03571]);
            end
            
         end  
    end 
    fname=strcat([num2str(mod1),'_vs_',num2str(mod2),'_',shocks{1},'_',shocks{2},'_long_irf', num2str(j)]);    
    saveas(j,strcat('Results/for_R3_sim_from_lowkgratio_',fname))
    saveas(j,strcat('Results/for_R3_sim_from_lowkgratio_',fname),'jpg')
    saveas(j,strcat('Results/for_R3_sim_from_lowkgratio_',fname),'png')

    print(strcat('Results/for_R3_sim_from_lowkgratio_',fname),'-dpdf')
    %print(strcat('Results/',fname),'-dpsc')
    close(j)
end
    


%% final figure comparing mod1 for select panels
  
close all;
clear h;
figure(1)                  

    % set size of figure so it fills page
    set(gcf, 'PaperPositionMode', 'manual');
    set(gcf, 'PaperUnits', 'inches');
    set(gcf, 'PaperPosition', [0 0 10.00 4.00]);

    counter = 1;
   
    subplot(1,2,counter);
    box on; hold on;
    plot(0:irf_sim, save_irf_dynss_ea_igitot,  '-b', 'LineWidth', 2);
    plot(0:irf_sim, save_irf_lowkg_ea_igitot, '--r', 'LineWidth', 2);
    plot(0:irf_sim,zeros(1,irf_sim+1),'-k','LineWidth',1)
    title(variable_names{strcmp('igitot',variable_names(:,1)),2},'interpreter','latex','FontSize', 14) %#ok<*NODEF>
    xlabel('Quarters');  
    axis('tight');
    counter = counter+1;
            
    subplot(1,2,counter);
    box on; hold on;
    h(1) = plot(0:irf_sim, save_irf_dynss_ea_qc,  '-b', 'LineWidth', 2);
    h(2) = plot(0:irf_sim, save_irf_lowkg_ea_qc, '--r', 'LineWidth', 2);
    plot(0:irf_sim,zeros(1,irf_sim+1),'-k','LineWidth',1)
    title(variable_names{strcmp('qc',variable_names(:,1)),2},'interpreter','latex','FontSize', 14) %#ok<*NODEF>
    xlabel('Quarters');
    axis('tight');
    counter = counter+1;    
    
    % legend
    legend(h, {strcat('$\frac{K_{g,0}}{K_{total,0}}=35$\%'),strcat('$\frac{K_{g,0}}{K_{total,0}}=25$\%')},'interpreter','latex','FontSize', 12,'Location','northwest')
    %set(legend,'Orientation','horizontal','FontSize',8,'Position',[0.4019 0.007035 0.1896 0.03571]);

    fname=strcat('for_R3_irf_compare_tfp_shk_scarcity_safer_capital');    
    saveas(j,strcat('Results/',fname))
    saveas(j,strcat('Results/',fname),'png')    
    
function compare_mod_long(mod1,mod2,varargin)

close all

addpath(genpath('Monopoly Power'))
clearvars -global -except mod1 varargin; clc;

COLUMNS =2; % By default, only 2 shocks and hence 2 cols of IRFs

tex_variables; % add lookup table for tex variable names for vars

irf_sim=20;


%% Choose shocks and corresponding titles for each column
if length(varargin)>=2
  shocks = {varargin{1}; varargin{2}};
else
    disp('Using default shocks ea and es');
    shocks = {'ea'; 'es'};
end

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
if length(varargin)==3
    irf_vars={varargin{3}};
else
%       irf_vars={{'x';'x_f'}};
%     irf_vars={{'ia';'Ic';'kpkg'}};
%     irf_vars={{'dgdp';'da';'dyp';'dc';'dip';'igitot';'qp';'VexpK';'ds'},{'ipitot';'sitot';'igitot';'ipiptot'},{'ntotal';'npnt'}};
%       irf_vars={{'dgdp';'da';'dyp';'dc';'dip';'ds';'igitot';'qp';'v_p';'qc'},{'dgdp';'da';'dc';'dip';'ds';'igitot'}};
%      irf_vars={{'dgdp';'da';'dc';'dip';'ds';'igitot'}};
%     irf_vars={{'dgdp';'da';'dyp';'dc';'dip';'ds';'igitot';'qp';'v_p';'qc'}};
    irf_vars={{'dgdp';'da';'dyp';'dc';'dip';'ds';'igitot';'qp';'v_p';'qc'},{'dip';'ntotal';'nc';'np';'ncnt';'wagec';'wagep'}};
%       irf_vars={{'dgdp';'da';'dyp';'dc';'dip';'ds';'igitot';'qp';'v_p';'qc'}};
%     irf_vars={{'dy';'da';'dyp';'dc';'dip';'igitot';'qp';'VexpK'}};
    
    %irf_vars={{'da';'condE_exr';'corr_m&exr';'condStd_m';'condStd_exr';'covar_m&exr'}};
    %irf_vars={{'dc';'di';'rf';'covar_m&r';'covar_m&rc'}};
end

%compare_mod(5,5,'ea','ex',{'dc';'di';'rf';'covar_m&r';'covar_m&rc'})
%compare_mod(5,5,'ex','es',{'dc';'di';'rf';'covar_m&r';'covar_m&rc'})


%% Plot of IRFs
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
                if mod2 == 3
                legend(h(2:3),strcat(['Model ',num2str(mod1)]),strcat(['Benchmark']));
                else
                legend(h(2:3),strcat(['Model ',num2str(mod1)]),strcat(['Model ',num2str(mod2)]));
                end
                set(legend,'Orientation','horizontal','FontSize',8,'Position',[0.4019 0.007035 0.1896 0.03571]);
            end
            
         end  
    end 
        fname=strcat([num2str(mod1),'_vs_',num2str(mod2),'_',shocks{1},'_',shocks{2},'_long_irf', num2str(j)]);    
    saveas(j,strcat('Results/',fname))
    saveas(j,strcat('Results/',fname),'jpg')
    saveas(j,strcat('Results/',fname),'png')

    print(strcat('Results/',fname),'-dpdf')
    %print(strcat('Results/',fname),'-dpsc')
    %close(j)
    end
    
   
    
end
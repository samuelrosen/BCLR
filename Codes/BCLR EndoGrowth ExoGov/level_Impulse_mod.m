function level_Impulse_mod(mod,irfsimnum)

close all

addpath(genpath('Monopoly Power'))
clearvars -global -except mod1 varargin; clc;

COLUMNS =3; % By default, only 2 shocks and hence 2 cols of IRFs

tex_variables; % add lookup table for tex variable names for vars

irf_sim=irfsimnum;

priceunit = 3;

% %% Choose shocks and corresponding titles for each column
% if length(varargin)>=2
%   shocks = {varargin{1}; varargin{2}};
% else
%     disp('Using default shocks ea and es');
%     shocks = {'ex'; 'es'};
% end
% 
% MyTitles = {'NEED TITLE'; 'NEED TITLE'};

    
        MyTitles{1}='Final Output ($Y_t$)';
   
        MyTitles{2}='Private Ouput ($Y_{p.t}$)';        
   
        MyTitles{3}='Gov Output ($Y_{g,t}$)';   
   
temp_irf=4;

% %% Choose variables for IRF
% if length(varargin)==3
%     irf_vars={varargin{3}};
% else
%     %irf_vars={{'da';'dc';'di';'m';'exr';'q';'n'}};
%     irf_vars={{'dy';'dyp';'dc';'kratio';'dip';'igitot';'Vexp'}};
%     %irf_vars={{'da';'condE_exr';'corr_m&exr';'condStd_m';'condStd_exr';'covar_m&exr'}};
%     %irf_vars={{'dc';'di';'rf';'covar_m&r';'covar_m&rc'}};
% end
% 
% %compare_mod(5,5,'ea','ex',{'dc';'di';'rf';'covar_m&r';'covar_m&rc'})
% %compare_mod(5,5,'ex','es',{'dc';'di';'rf';'covar_m&r';'covar_m&rc'})

shocks = {'ea';'es';'ea_es'};
%% Plot of IRFs
for j=1:3 %% Loop over lists within irf_vars
    
    % set size of figure so it fills page
    set(gcf, 'PaperPositionMode', 'manual');
    set(gcf, 'PaperUnits', 'inches');
    set(gcf, 'PaperPosition', [0.25 2.5 8.00 8.00]);
    
    
    figure(j)
    
  % for i=1:3 %% Loop over models
        % Just loading what we need and setting the line styles
        
           
            load(strcat('Results/Monopoly_Power_Approx_',num2str(mod),'/Monopoly_Power_Approx_',num2str(mod),'.mat'));
            style='-r';

                       
        counter=1;
        
        % Starting the loop across variables
        for k=1:temp_irf
            
            %% First COLUMN
            subplot(temp_irf,COLUMNS,counter);
            box on; hold on;
           if k==1
                    plot(1:irf_sim,[eval(strcat(['dyn_irfp_',shocks{j},'_mean_cum(dyn_i_dy,1:irf_sim)']))],style,'LineWidth',2);  
                    ylabel('$log(Y_t)$','interpreter','latex') %#ok<*NODEF>
           end;
           if k==2
                    plot(1:irf_sim,[eval(strcat(['dyn_irfp_',shocks{j},'_mean_cum(dyn_i_dgdpa,1:irf_sim)']))],style,'LineWidth',2);  
                    ylabel('Gov Goods Unit: $log(\tilde{p}_tY_t)$' ,'interpreter','latex') %#ok<*NODEF>
           end;
           if k==3
                    plot(1:irf_sim,[eval(strcat(['dyn_irfp_',shocks{j},'_mean_cum(dyn_i_dy,1:irf_sim)']))],style,'LineWidth',2);  
                    ylabel('Final Goods Unit: $log(Y_t)$','interpreter','latex') %#ok<*NODEF>
           end;
           if k==4
                    plot(1:irf_sim,[eval(strcat(['dyn_irfp_',shocks{j},'_mean_cum(dyn_i_dgdpp,1:irf_sim)']))],style,'LineWidth',2);  
                    ylabel('Private Goods Unit: $log(\frac{\tilde{p}_tY_t}{p})$','interpreter','latex') %#ok<*NODEF>
           end;
            
            if k==1, title(MyTitles{1},'interpreter','latex'); end
            if k==temp_irf, xlabel('Quarters'); end
            
            
                
            axis('tight')
            counter=counter+1;
            
            
            %% Second COLUMN
            subplot(temp_irf,COLUMNS,counter);
            box on; hold on;
            if k==1
                    plot(1:irf_sim,[eval(strcat(['dyn_irfp_',shocks{j},'_mean_cum(dyn_i_dyp,1:irf_sim)']))],style,'LineWidth',2);  
                    ylabel('$log(Y_{p,t})$','interpreter','latex') %#ok<*NODEF>
           end;
           if k==2
                    plot(1:irf_sim,[eval(strcat(['dyn_irfp_',shocks{j},'_mean_cum(dyn_i_dgdppa,1:irf_sim)']))],style,'LineWidth',2);  
                    ylabel('Gov Goods Unit: $log(p_tY_{p,t})$' ,'interpreter','latex') %#ok<*NODEF>
           end;
           if k==3
                    plot(1:irf_sim,[eval(strcat(['dyn_irfp_',shocks{j},'_mean_cum(dyn_i_dfyp,1:irf_sim)']))],style,'LineWidth',2);  
                    ylabel('Final Goods Unit: $log(\frac{p_tY_{p,t}}{\tilde{p}_t})$','interpreter','latex') %#ok<*NODEF>
           end;
           if k==4
                    plot(1:irf_sim,[eval(strcat(['dyn_irfp_',shocks{j},'_mean_cum(dyn_i_dyp,1:irf_sim)']))],style,'LineWidth',2);  
                    ylabel('Private Goods Unit: $log(Y_{p,t})$','interpreter','latex') %#ok<*NODEF>
           end;
           
            
    
            if k==1, title(MyTitles{2},'interpreter','latex'); end
            if k==temp_irf, xlabel('Quarters'); end
            
            axis('tight')
            counter=counter+1;
            
             %% Third COLUMN
            subplot(temp_irf,COLUMNS,counter);
            box on; hold on;
            if k==1
                    plot(1:irf_sim,[eval(strcat(['dyn_irfp_',shocks{j},'_mean_cum(dyn_i_dyc,1:irf_sim)']))],style,'LineWidth',2);  
                    ylabel('$log(Y_{g,t})$','interpreter','latex') %#ok<*NODEF>
           end;
           if k==2
                    plot(1:irf_sim,[eval(strcat(['dyn_irfp_',shocks{j},'_mean_cum(dyn_i_dyc,1:irf_sim)']))],style,'LineWidth',2);  
                    ylabel('Gov Goods Unit: $log(Y_{g,t})$' ,'interpreter','latex') %#ok<*NODEF>
           end;
           if k==3
                    plot(1:irf_sim,[eval(strcat(['dyn_irfp_',shocks{j},'_mean_cum(dyn_i_dfyc,1:irf_sim)']))],style,'LineWidth',2);  
                    ylabel('Final Goods Unit: $log(\frac{Y_{g,t}}{\tilde{p}_t})$','interpreter','latex') %#ok<*NODEF>
           end;
           if k==4
                    plot(1:irf_sim,[eval(strcat(['dyn_irfp_',shocks{j},'_mean_cum(dyn_i_dycp,1:irf_sim)']))],style,'LineWidth',2);  
                    ylabel('Private Goods Unit: $log(\frac{Y_{g,t}}{p_t})$','interpreter','latex') %#ok<*NODEF>
           end;
           
            
    
            if k==1, title(MyTitles{3},'interpreter','latex'); end
            if k==temp_irf, xlabel('Quarters'); end
            
            axis('tight')
            counter=counter+1;
            
            %% Fixing the legend
%             if k==length(temp_irf) && j==3 
%                 legend(h(2:3),strcat(['Model ',num2str(mod1)]),strcat(['Model ',num2str(mod2)]));
%                 set(legend,'Orientation','horizontal','FontSize',8,'Position',[0.4019 0.007035 0.1896 0.03571]);
%             end
            
         end  
      % end 

    fname=strcat([num2str(mod),'_',shocks{j},'_',num2str(irf_sim)]);    
    saveas(j,strcat('Results/Monopoly_Power_Approx_',num2str(mod),'/',fname))
    saveas(j,strcat('Results/Monopoly_Power_Approx_',num2str(mod),'/',fname),'jpg')
    print(strcat('Results/Monopoly_Power_Approx_',num2str(mod),'/',fname),'-dpdf')
    %print(strcat('Results/',fname),'-dpsc')
    close
   end 
end
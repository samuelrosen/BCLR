    function level_Impulse_compare_data(mod1)

close all

addpath(genpath('Monopoly Power'))
clearvars -global -except mod1 varargin; clc;

COLUMNS =3; % By default, only 2 shocks and hence 2 cols of IRFs

tex_variables; % add lookup table for tex variable names for vars

irf_sim=22;

plot_ig_ratio_instead = 1; % whether or not to plot the Ig/Itotal ration in third panel (if not then plot Ig)

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
   
temp_irf=1;

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
% for j=1:3 %% Loop over lists within irf_vars
    j=2;
    
    figure(j)

    % set size of figure so it fills page
    set(gcf, 'PaperPositionMode', 'manual');
    %set(gcf, 'PaperOrientation','landscape');
    set(gcf, 'PaperUnits', 'inches');
    set(gcf, 'PaperPosition', [0.25 2.5 8.00 4.00]);    
    
  % for i=1:3 %% Loop over models
        % Just loading what we need and setting the line styles
        
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
            %load(strcat('Compare Mod\VAR\VARdata.mat'));
            %load(strcat('Compare Mod\VAR\Data VAR\Matlab\VARdata.mat'));            
            load(strcat('Compare Mod\VAR\Data VAR\Stata\VARdata.mat'));      
            style='-r';
        end
       
                       
        counter=1;
        if i<=2
        % Starting the loop across variables
        for k=1:temp_irf
            
            %% First COLUMN
            subplot(temp_irf,COLUMNS,counter);
            box on; hold on;         
           if k==1
                    plot(1:irf_sim,[eval(strcat(['dyn_irfp_',shocks{j},'_mean_cum(dyn_i_dc,1:irf_sim)']))],style,'LineWidth',2);  
                    ylabel('Final Goods Unit: $log(C_t)$','interpreter','latex') %#ok<*NODEF>
                    title('Aggregate Consumption','interpreter','latex')
           end;
 
            
            if k==temp_irf, xlabel('Quarters'); end
            
            
                
            axis('tight')
            counter=counter+1;
            
            
            %% Second COLUMN
            subplot(temp_irf,COLUMNS,counter);
            box on; hold on;
          
           if k==1
                    plot(1:irf_sim,[eval(strcat(['dyn_irfp_',shocks{j},'_mean_cum(dyn_i_dip,1:irf_sim)']))],style,'LineWidth',2);  
                    ylabel('Final Goods Unit: $log(I_{p,t})$','interpreter','latex') %#ok<*NODEF>
                    title('Private Investment','interpreter','latex')
           end;      
            if k==temp_irf, xlabel('Quarters'); end
            
            axis('tight')
            counter=counter+1;
                %% Third COLUMN
            subplot(temp_irf,COLUMNS,counter);
            box on; hold on;
           if k==1
               if plot_ig_ratio_instead
                    chg_igitot = dyn_irfp_es_raw(dyn_i_igitot,1:irf_sim)-dyn_irfp_es_raw(dyn_i_igitot,1);
                    h(i)=plot(1:irf_sim,[eval(strcat('chg_igitot'))],style,'LineWidth',2);  
                    ylabel('Share','interpreter','latex') %#ok<*NODEF>
                    title('Govt Investment Share','interpreter','latex')                                       
               else
                    h(i)=plot(1:irf_sim,[eval(strcat(['dyn_irfp_',shocks{j},'_raw_lev(dyn_i_Ic,1:irf_sim)']))],style,'LineWidth',2);  
                    ylabel('Final Goods Unit: $\frac{I_{g,t}-I_{g,ss}}{I_{g,ss}}$','interpreter','latex') %#ok<*NODEF>
                    title('Govt Investment','interpreter','latex')
               end
           end;
            
            if k==temp_irf, xlabel('Quarters'); end
            
            axis('tight')
            counter=counter+1;
        end;
        end;
        if i==3
            for k=1:temp_irf
            
            %% First COLUMN
            subplot(temp_irf,COLUMNS,counter);
            box on; hold on;         
           if k==1
                    plot(1:irf_sim,[0; logc]',style,1:irf_sim,[0; logcU]','--',1:irf_sim,[0; logcL]','--','LineWidth',2);  
                    ylabel('Final Goods Unit: $log(C_t)$','interpreter','latex') %#ok<*NODEF>
                    title('Aggregate Consumption','interpreter','latex')
           end;
 
            
            if k==temp_irf, xlabel('Quarters'); end
            
            
                
            axis('tight')
            counter=counter+1;
            
            
            %% Second COLUMN
            subplot(temp_irf,COLUMNS,counter);
            box on; hold on;
          
           if k==1
                    plot(1:irf_sim,[0; logi_p]',style,1:irf_sim,[0; logi_pU]','--',1:irf_sim,[0; logi_pL]','--','LineWidth',2);   
                    ylabel('Final Goods Unit: $log(I_{p,t})$','interpreter','latex') %#ok<*NODEF>
                    title('Private Investment','interpreter','latex')
           end;      
            if k==temp_irf, xlabel('Quarters'); end
            
            axis('tight')
            counter=counter+1;
                %% Third COLUMN
            subplot(temp_irf,COLUMNS,counter);
            box on; hold on;
           if k==1               
               if plot_ig_ratio_instead
                    h(i)=plot(1:irf_sim,[0; is_itot]',style,'LineWidth',2); 
                    plot(1:irf_sim,[0; is_itotU]','--',1:irf_sim,[0; is_itotL]','--','LineWidth',2);                    
                    ylabel('Share','interpreter','latex') %#ok<*NODEF>
                    title('Gov Investment Share','interpreter','latex')                                                           
               else
                    h(i)=plot(1:irf_sim,[0; logi_g]',style,'LineWidth',2); 
                    plot(1:irf_sim,[0; logi_gU]','--',1:irf_sim,[0; logi_gL]','--','LineWidth',2);
                    ylabel('Final Goods Unit: $\frac{I_{g,t}-I_{g,ss}}{I_{g,ss}}$','interpreter','latex') %#ok<*NODEF>
                    title('Gov Investment','interpreter','latex')                   
               end
           end;
            
            if k==temp_irf, xlabel('Quarters'); end
            
            axis('tight')
            counter=counter+1;
        end;
        end;  
        end
            
            % Fixing the legend
            if k==temp_irf && i==3 
                legend(h(2:3),strcat(['Model ',num2str(mod1),' IRF']),strcat(['VAR IRF']));
                set(legend,'Orientation','horizontal','FontSize',8,'Position',[0.4019 0.007035 0.1896 0.03571]);
                %set(legend,'Orientation','horizontal','FontSize',8,'Position','South');
            end
            
       
     

    fname=strcat([num2str(mod1),'_vs_VAR_',shocks{j},'_',num2str(irf_sim)]);    
    saveas(j,strcat('Results/',fname))
    saveas(j,strcat('Results/',fname),'png')
    print(strcat('Results/',fname),'-dpdf')
    %print(strcat('Results/',fname),'-dpsc')
    close
%    end 
end
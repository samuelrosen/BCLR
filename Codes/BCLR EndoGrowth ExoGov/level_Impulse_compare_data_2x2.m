function level_Impulse_compare_data_2x2(mod1,use_ann_data_switch,switch_2x2)

close all

addpath(genpath('Monopoly Power'));
clearvars -global -except mod1 varargin; clc;

% how to run all figures of interest at once
% for modnum=36:37
%     level_Impulse_compare_data_2x2(modnum,0,0)
%     level_Impulse_compare_data_2x2(modnum,1,0)
%     level_Impulse_compare_data_2x2(modnum,0,2)
%     level_Impulse_compare_data_2x2(modnum,1,2)
% end


%use_ann_data_switch = 0;
%use_ann_data_switch = 1;
% ==1 then use IRF vectors computed from annual data VAR
% otherwise use IRF vectors computed from quarterly data VAR


%switch_2x2 = 0;
% ==0 --> 1x3 panel with C/Y, Ip/Y, and Ig/Y
% ==1 --> 2x2 panel with AggC, C/Y, Ip/Y, and Ig/Y
% ==2 --> 1x2 panel with Ip/Y and Ig/Y

if switch_2x2==0
    ROWS=1;
    COLUMNS=3; 
    fname_suffix = '_1x3';
elseif switch_2x2==1
    ROWS=2;
    COLUMNS=2; 
    fname_suffix = '_2x2';
elseif switch_2x2==2
    ROWS=1;
    COLUMNS=2;     
    fname_suffix = '_1x2';
else    
    error('switch_2x2 needs to be 0, 1, or 2')
end




tex_variables; % add lookup table for tex variable names for vars

irf_sim=22;

shocks = {'ea';'es';'ea_es'};


%% Plot of IRFs
% for j=1:3 %% Loop over different shocks
j=2;
    
    figure(j)
    
    % set size of figure so it fills page
    set(gcf, 'PaperPositionMode', 'manual');
    %set(gcf, 'PaperOrientation','landscape');
    set(gcf, 'PaperUnits', 'inches');
    set(gcf, 'PaperPosition', [0.25 2.5 9.00 5.00]);     
    
    for i=1:3 %% Loop over models

        % Just loading what we need and setting the line styles
        if i==1
            % Fake: just to have something
            %load(strcat('Results/Monopoly_Power_Approx_',num2str(mod1),'/Monopoly_Power_Approx_',num2str(mod1),'.mat'));
            style='-k';
        elseif i==2    
            load(strcat('Results/Monopoly_Power_Approx_',num2str(mod1),'/Monopoly_Power_Approx_',num2str(mod1),'.mat'));
            style=':b';
        elseif i==3
            %load(strcat('Compare Mod\VAR\Data VAR\Matlab\VARdata.mat'));            
            if use_ann_data_switch==1
                load(strcat('Compare Mod\VAR\Data VAR\Matlab\VARdata_ann.mat'));
            else
                load(strcat('Compare Mod\VAR\Data VAR\Stata\VARdata.mat'));      
            end
            style='-r';
        end
       
                       
        counter=1;
            
        % multiplier for each of the values in the share IRF plots        
        quantity_mult = 400;        
        % 400 means annualized percent
        
        % logC           
        if switch_2x2==1
            subplot(ROWS,COLUMNS,counter); box on; hold on;
            if i==1
                h(i)=plot(0:irf_sim-1, zeros(1,irf_sim),style,'LineWidth', 0.5);  
            elseif i==2
                h(i)=plot(0:irf_sim-1, quantity_mult*[eval(strcat(['dyn_irfp_',shocks{j},'_mean_cum(dyn_i_dc,1:irf_sim)']))],style,'LineWidth',2);  
            elseif i==3
                if use_ann_data_switch==1
                    error('code not currently set up to compute annual data logC IRFs')
                else
                    h(i)=plot(0:irf_sim-1, [0; quantity_mult*logc]',style, 'LineWidth',2);  
                    plot(0:irf_sim-1,[0; quantity_mult*logcU]','--r','LineWidth',2);  
                    plot(0:irf_sim-1,[0; quantity_mult*logcL]','--r','LineWidth',2);  
                end
            end
            counter=counter+1;
            if i==3;
                ylabel('\% Dev. from Trend','interpreter','latex');
                title('Aggregate Consumption','interpreter','latex');
                axis('tight');            
                if counter>COLUMNS*(ROWS-1)+1
                    xlabel('Quarters'); 
                end
            end          
        end
        
        % multiplier for each of the values in the share IRF plots        
        share_mult = 100;                
        
        % set ylimits across share charts the same
        if use_ann_data_switch==1
            share_ylim = [-5,2];
        else
            share_ylim = [-2,1];
        end
        
        % C/Y           
        if switch_2x2==0 || switch_2x2==1
            subplot(ROWS,COLUMNS,counter); box on; hold on;
            if i==1
                h(i)=plot(0:irf_sim-1, zeros(1,irf_sim),style,'LineWidth', 0.5);  
            elseif i==2
                C_Y = exp( dyn_irfp_es_raw(dyn_i_ca,1:irf_sim) - dyn_irfp_es_raw(dyn_i_ya,1:irf_sim) );
                chg_C_Y = C_Y-C_Y(1);             
                h(i)=plot(0:irf_sim-1, share_mult*chg_C_Y, style, 'LineWidth',2);
            elseif i==3
                if use_ann_data_switch==1
                    data_pts      = dataVAR_C_Y.oirf_var4_qtr_pts(1:irf_sim);
                    data_fill     = dataVAR_C_Y.oirf_var4_qtr_fill(1:irf_sim);
                    data_ciL_fill = dataVAR_C_Y.oirf_var4_ciL_qtr_fill(1:irf_sim);
                    data_ciU_fill = dataVAR_C_Y.oirf_var4_ciU_qtr_fill(1:irf_sim);
                    
                    h(i)=plot(0:irf_sim-1,[share_mult*data_pts]','*r','LineWidth',2,'MarkerSize',10);  
                    plot(0:irf_sim-1,[share_mult*data_fill]',':r','LineWidth',2);  
                    plot(0:irf_sim-1,[share_mult*data_ciL_fill]','--r','LineWidth',2);  
                    plot(0:irf_sim-1,[share_mult*data_ciU_fill]','--r','LineWidth',2);  
                else
                    h(i)=plot(0:irf_sim-1,[0; share_mult*c_y]',style,'LineWidth',2);  
                    plot(0:irf_sim-1,[0; share_mult*c_yU]','--r','LineWidth',2);  
                    plot(0:irf_sim-1,[0; share_mult*c_yL]','--r','LineWidth',2);                      
                end
            end
            counter=counter+1;
            if i==3;
                %ylabel('Pct Chg from Trend','interpreter','latex');
                title('Consumption to GDP','interpreter','latex');
                axis('tight');            
                ylim(share_ylim);
                if counter>COLUMNS*(ROWS-1)+1
                    xlabel('Quarters'); 
                end
            end       
        end
        
        % Ip/Y           
        subplot(ROWS,COLUMNS,counter); box on; hold on;
        if i==1
            h(i)=plot(0:irf_sim-1, zeros(1,irf_sim),style,'LineWidth', 0.5);  
        elseif i==2
            Ip_Y = exp( dyn_irfp_es_raw(dyn_i_ipa,1:irf_sim) - dyn_irfp_es_raw(dyn_i_ya,1:irf_sim) );
            chg_Ip_Y = Ip_Y-Ip_Y(1);             
            h(i)=plot(0:irf_sim-1, share_mult*chg_Ip_Y, style, 'LineWidth',2);
        elseif i==3
            if use_ann_data_switch==1
                data_pts      = dataVAR_Ip_Y.oirf_var4_qtr_pts(1:irf_sim);
                data_fill     = dataVAR_Ip_Y.oirf_var4_qtr_fill(1:irf_sim);
                data_ciL_fill = dataVAR_Ip_Y.oirf_var4_ciL_qtr_fill(1:irf_sim);
                data_ciU_fill = dataVAR_Ip_Y.oirf_var4_ciU_qtr_fill(1:irf_sim);

                h(i)=plot(0:irf_sim-1,[share_mult*data_pts]','*r','LineWidth',2,'MarkerSize',10);  
                plot(0:irf_sim-1,[share_mult*data_fill]',':r','LineWidth',2);  
                plot(0:irf_sim-1,[share_mult*data_ciL_fill]','--r','LineWidth',2);  
                plot(0:irf_sim-1,[share_mult*data_ciU_fill]','--r','LineWidth',2);  
            else            
                h(i)=plot(0:irf_sim-1,[0; share_mult*ip_y]',style,'LineWidth',2);  
                plot(0:irf_sim-1,[0; share_mult*ip_yU]','--r','LineWidth',2);  
                plot(0:irf_sim-1,[0; share_mult*ip_yL]','--r','LineWidth',2);  
            end
        end
        counter=counter+1;
        if i==3;
            %ylabel('Pct Chg from Trend','interpreter','latex');
            title('Private Investment to GDP','interpreter','latex');
            axis('tight');            
            ylim(share_ylim);
            if counter>COLUMNS*(ROWS-1)+1
                xlabel('Quarters'); 
            end
        end               

        
        % Ig/Y           
        subplot(ROWS,COLUMNS,counter); box on; hold on;
        if i==1
            h(i)=plot(0:irf_sim-1, zeros(1,irf_sim),style,'LineWidth', 0.5);  
        elseif i==2
            Ig_Y = dyn_irfp_es_raw(dyn_i_Ic,1:irf_sim)./exp(dyn_irfp_es_raw(dyn_i_ya,1:irf_sim) );
            chg_Ig_Y = Ig_Y-Ig_Y(1);         
            h(i)=plot(0:irf_sim-1, share_mult*chg_Ig_Y, style, 'LineWidth',2);
        elseif i==3
            if use_ann_data_switch==1
                data_pts      = dataVAR_Ig_Y.oirf_var4_qtr_pts(1:irf_sim);
                data_fill     = dataVAR_Ig_Y.oirf_var4_qtr_fill(1:irf_sim);
                data_ciL_fill = dataVAR_Ig_Y.oirf_var4_ciL_qtr_fill(1:irf_sim);
                data_ciU_fill = dataVAR_Ig_Y.oirf_var4_ciU_qtr_fill(1:irf_sim);

                h(i)=plot(0:irf_sim-1,[share_mult*data_pts]','*r','LineWidth',2,'MarkerSize',10);  
                plot(0:irf_sim-1,[share_mult*data_fill]',':r','LineWidth',2);  
                plot(0:irf_sim-1,[share_mult*data_ciL_fill]','--r','LineWidth',2);  
                plot(0:irf_sim-1,[share_mult*data_ciU_fill]','--r','LineWidth',2);  
            else                        
                h(i)=plot(0:irf_sim-1,[0; share_mult*ig_y]',style,'LineWidth',2);  
                plot(0:irf_sim-1,[0; share_mult*ig_yU]','--r','LineWidth',2);  
                plot(0:irf_sim-1,[0; share_mult*ig_yL]','--r','LineWidth',2);  
            end
        end
        counter=counter+1;
        if i==3;
            %ylabel('Pct Chg from Trend','interpreter','latex');
            title('Govt Investment to GDP','interpreter','latex');
            axis('tight');       
            ylim(share_ylim);
            if counter>COLUMNS*(ROWS-1)+1
                xlabel('Quarters'); 
            end
        end                              
        
    end;
            
    % fix the legend
    legend(h(2:3),strcat(['Model ',num2str(mod1),' IRF']),strcat(['VAR IRF']));
    if switch_2x2==1
        set(legend,'Orientation','horizontal','FontSize',8,'Position',[0.4019 0.007035 0.1896 0.03571]);
    else
        set(legend,'Location','southeast');
    end
    %set(legend,'Orientation','horizontal','FontSize',8,'Position','South');

    
    % output files
    if use_ann_data_switch==1
        fname=strcat([num2str(mod1),'_vs_annVAR_',shocks{j},'_',num2str(irf_sim),fname_suffix]);    
    else
        fname=strcat([num2str(mod1),'_vs_qtrVAR_',shocks{j},'_',num2str(irf_sim),fname_suffix]);    
    end    
    saveas(j,strcat('Results/',fname))
    saveas(j,strcat('Results/',fname),'png')
    print(strcat('Results/',fname),'-dpdf')
    %print(strcat('Results/',fname),'-dpsc')
    %close

end
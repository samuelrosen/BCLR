global fname irf_sim dyn_irfp_ea_mean dyn_irfp_ex_mean dyn_irfp_ea_es_mean labor_switch
global dyn_irfp_eg_mean gold_switch shock_direction_switch allshocks shortlongshocks % SAM ADD
global stoch_vol_switch dyn_irfp_es_mean % SAM ADD

load(strcat(fname,'.mat'));
irf_sim=100;
irfsim
irf_sim_plot=20;
if labor_switch==0
    irf1={'dy';'dyp';'dyc';'dip';'p';'ptil';'igitot'};
    %irf1={'dy';'dyp';'dc';'wratio';'dip';'igitot';'Vexp';'da';'qp';'qc'};
elseif labor_switch==1 && gold_switch==0 % SAM EDIT
    irf1={'da';'dc';'di';'m';'exr';'q';'n'};
elseif labor_switch==1 && gold_switch==1 % SAM EDIT
    irf1={'da';'dc';'di';'J_I'; 'qKqG';'m';'exr';'exr_G';'n'};    
    %irf1={'da';'dc';'di';'J_I'; 'm';'exr';'exr_G';'n'};    
end
if test==1
%     irf1={'dytotalg';'dc';'di';'tig';'dic';'Ic';'kratio'};
%     irf1={'dc';'di';'tig';'dic';'r';'rc';'kratio'};
%     irf1={'dc';'di';'tig';'dic'};
%     irf1={'r';'rc';'q';'p'};
irf1={'pqr';'kratio'};
end

irf_cell={irf1};
tex_variables;

% Plot of IRFs

% % IRF showing SRR and LRR shocks
% for j=1:length(irf_cell)
%     temp_irf=irf_cell{j};
%     figure(j)
%     counter=1;
%     for k=1:length(temp_irf)
%         subplot(length(temp_irf),2,counter);
%         box on; hold on;
%         plot(1:irf_sim_plot,[dyn_irfp_ea_mean(eval(strcat(['dyn_i_',temp_irf{k}])),1:irf_sim_plot)],'-b','LineWidth',2)
%         
%         if k==1, title('Short Run Shock'); end
%         
%         ylabel(variable_names{strcmp(temp_irf{k},variable_names(:,1)),2},'interpreter','latex') %#ok<*NODEF>
%         axis('tight')
%         counter=counter+1;
%         
%         subplot(length(temp_irf),2,counter);
%         box on; hold on;
%         plot(1:irf_sim_plot,[dyn_irfp_ex_mean(eval(strcat(['dyn_i_',temp_irf{k}])),1:irf_sim_plot)],'-b','LineWidth',2)
%          
%         if k==1, title('Long Run Shock'); end
%         
%         axis('tight')
%         counter=counter+1;
%         
%         if k==length(temp_irf)
%             
%             temp_legend = [num2str(shock_direction_switch) ' StDev(s) Shock'];
%             legend(temp_legend);
%             %if shock_direction_switch==1
%             %legend('1 SD Positive Shock');
%             %else
%             %legend('1 SD Negative Shock');
%             %end
%                         
%             set(legend,'Orientation','horizontal','FontSize',8,'Position',[0.4019 0.007035 0.1896 0.03571]);
%         end
%         
%     end % Variable loop within IRF
% 
%     mkdir(strcat('Results/',fname))
%     saveas(j,strcat('Results/',fname,'/IRF_SRR_LRR'))
%     print(strcat('Results/',fname,'/IRF_SRR_LRR'),'-dpdf')
%     print(strcat('Results/',fname,'/IRF_SRR_LRR'),'-dpsc')
%     close(j)
% end

% IRF showing LRR and vol shocks
if shock_test==1
    for j=1:length(irf_cell)
        temp_irf=irf_cell{j};
        figure(j)
        counter=1;
        for k=1:length(temp_irf)
            subplot(length(temp_irf),2,counter);
            box on; hold on;
            plot(1:irf_sim_plot,[dyn_irfp_ea_mean(eval(strcat(['dyn_i_',temp_irf{k}])),1:irf_sim_plot)],'-b','LineWidth',2)

            if k==1, title('Short Run Shock'); end

            ylabel(variable_names{strcmp(temp_irf{k},variable_names(:,1)),2},'interpreter','latex') %#ok<*NODEF>
            axis('tight')
            counter=counter+1;

            subplot(length(temp_irf),2,counter);
            box on; hold on;
            plot(1:irf_sim_plot,[dyn_irfp_es_mean(eval(strcat(['dyn_i_',temp_irf{k}])),1:irf_sim_plot)],'-b','LineWidth',2)            
            
            if k==1, title('Volatility Shock'); end

            axis('tight')
            counter=counter+1;

            if k==length(temp_irf)
                
                temp_legend = [num2str(shock_direction_switch) ' StDev(s) Shock'];
                legend(temp_legend);
            
%                 if shock_direction_switch==1
%                 legend('1 SD Positive Shock');
%                 else
%                 legend('1 SD Negative Shock');
%                 end

                set(legend,'Orientation','horizontal','FontSize',8,'Position',[0.4019 0.007035 0.1896 0.03571]);
            end

        end % Variable loop within IRF

        mkdir(strcat('Results/',fname))
        saveas(j,strcat('Results/',fname,'/IRF_SRR_vol'))
        print(strcat('Results/',fname,'/IRF_SRR_vol'),'-dpdf')
        print(strcat('Results/',fname,'/IRF_SRR_vol'),'-dpsc')
        close(j)
    end
    
     for j=1:length(irf_cell)
        temp_irf=irf_cell{j};
        figure(j)
        counter=1;
        for k=1:length(temp_irf)
            subplot(length(temp_irf),1,counter);
            box on; hold on;
            plot(1:irf_sim_plot,[dyn_irfp_ea_es_mean(eval(strcat(['dyn_i_',temp_irf{k}])),1:irf_sim_plot)],'-b','LineWidth',2)

            if k==1, title('Short Run Shock and Volatility Shock'); end

            ylabel(variable_names{strcmp(temp_irf{k},variable_names(:,1)),2},'interpreter','latex') %#ok<*NODEF>
            axis('tight')
            counter=counter+1;


            if k==length(temp_irf)
                
                temp_legend = [num2str(shock_direction_switch) ' StDev(s) Shock'];
                legend(temp_legend);
            
%                 if shock_direction_switch==1
%                 legend('1 SD Positive Shock');
%                 else
%                 legend('1 SD Negative Shock');
%                 end

                set(legend,'Orientation','horizontal','FontSize',8,'Position',[0.4019 0.007035 0.1896 0.03571]);
            end

        end % Variable loop within IRF

        mkdir(strcat('Results/',fname))
        saveas(j,strcat('Results/',fname,'/IRF_SRR_and_vol'))
        print(strcat('Results/',fname,'/IRF_SRR_and_vol'),'-dpdf')
        print(strcat('Results/',fname,'/IRF_SRR_and_vol'),'-dpsc')
        close(j)
    end
end

% IRF showing LRR and gold shocks
if gold_switch==1
    for j=1:length(irf_cell)
        temp_irf=irf_cell{j};
        figure(j)
        counter=1;
        for k=1:length(temp_irf)
            subplot(length(temp_irf),2,counter);
            box on; hold on;
            plot(1:irf_sim_plot,[dyn_irfp_ex_mean(eval(strcat(['dyn_i_',temp_irf{k}])),1:irf_sim_plot)],'-b','LineWidth',2)

            if k==1, title('Long Run Shock'); end

            ylabel(variable_names{strcmp(temp_irf{k},variable_names(:,1)),2},'interpreter','latex') %#ok<*NODEF>
            axis('tight')
            counter=counter+1;

            subplot(length(temp_irf),2,counter);
            box on; hold on;
            plot(1:irf_sim_plot,[dyn_irfp_eg_mean(eval(strcat(['dyn_i_',temp_irf{k}])),1:irf_sim_plot)],'-b','LineWidth',2)            
            
            if k==1, title('Gold Shock'); end

            axis('tight')
            counter=counter+1;

            if k==length(temp_irf)
                
                temp_legend = [num2str(shock_direction_switch) ' StDev(s) Shock'];
                legend(temp_legend);
                
%                 if shock_direction_switch==1
%                 legend('1 SD Positive Shock');
%                 else
%                 legend('1 SD Negative Shock');
%                 end

                set(legend,'Orientation','horizontal','FontSize',8,'Position',[0.4019 0.007035 0.1896 0.03571]);
            end

        end % Variable loop within IRF

        mkdir(strcat('Results/',fname))
        saveas(j,strcat('Results/',fname,'/IRF_LRR_gold'))
        print(strcat('Results/',fname,'/IRF_LRR_gold'),'-dpdf')
        print(strcat('Results/',fname,'/IRF_LRR_gold'),'-dpsc')
        close(j)
    end
end

% IRF showing gold and vol shocks
if gold_switch==1 && stoch_vol_switch==1
    for j=1:length(irf_cell)
        temp_irf=irf_cell{j};
        figure(j)
        counter=1;
        for k=1:length(temp_irf)
            subplot(length(temp_irf),2,counter);
            box on; hold on;
            plot(1:irf_sim_plot,[dyn_irfp_eg_mean(eval(strcat(['dyn_i_',temp_irf{k}])),1:irf_sim_plot)],'-b','LineWidth',2)

            if k==1, title('Gold Shock'); end

            ylabel(variable_names{strcmp(temp_irf{k},variable_names(:,1)),2},'interpreter','latex') %#ok<*NODEF>
            axis('tight')
            counter=counter+1;

            subplot(length(temp_irf),2,counter);
            box on; hold on;
            plot(1:irf_sim_plot,[dyn_irfp_es_mean(eval(strcat(['dyn_i_',temp_irf{k}])),1:irf_sim_plot)],'-b','LineWidth',2)            
            
            if k==1, title('Volatility Shock'); end

            axis('tight')
            counter=counter+1;

            if k==length(temp_irf)
                
                temp_legend = [num2str(shock_direction_switch) ' StDev(s) Shock'];
                legend(temp_legend);
                
%                 if shock_direction_switch==1
%                 legend('1 SD Positive Shock');
%                 else
%                 legend('1 SD Negative Shock');
%                 end

                set(legend,'Orientation','horizontal','FontSize',8,'Position',[0.4019 0.007035 0.1896 0.03571]);
            end

        end % Variable loop within IRF

        mkdir(strcat('Results/',fname))
        saveas(j,strcat('Results/',fname,'/IRF_gold_vol'))
        print(strcat('Results/',fname,'/IRF_gold_vol'),'-dpdf')
        print(strcat('Results/',fname,'/IRF_gold_vol'),'-dpsc')
        close(j)
    end
end
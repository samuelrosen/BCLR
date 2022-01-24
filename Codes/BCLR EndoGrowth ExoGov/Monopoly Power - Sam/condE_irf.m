global fname irf_sim irf_condE_ea irf_condE_ex labor_switch
global irf_condE_eg gold_switch shock_direction_switch % SAM ADD
global stoch_vol_switch irf_condE_es % SAM ADD

% big difference between this program and irf is that .mat not loaded here
% and the conditional IRF sim is done in sim_dyn_mod.
% don't use these lines:
%    load(strcat(fname,'.mat'));
%    irf_sim=20;
%    irfsim

if labor_switch==0
    irf1={'da';'dc';'kratio';'di';'m';'rf';'exr';'exr_G'};
elseif labor_switch==1 && gold_switch==0 % SAM EDIT
    irf1={'da';'dc';'di';'m';'exr';'q';'n'};
elseif labor_switch==1 && gold_switch==1 % SAM EDIT
    irf1={'da';'dc';'di';'dJoverA';'m';'exr';'exr_G';'n'};    
end

irf_cell={irf1};
tex_variables;

% Plot of IRFs

% IRF showing SRR and LRR shocks
for j=1:length(irf_cell)
    temp_irf=irf_cell{j};
    figure(j)
    counter=1;
    for k=1:length(temp_irf)
        subplot(length(temp_irf),2,counter);
        box on; hold on;
        plot(1:irf_sim,[irf_condE_ea(eval(strcat(['dyn_i_',temp_irf{k}])),1:irf_sim)],'-b','LineWidth',2)
        
        if k==1, title('Short Run Shock'); end
        
        ylabel(variable_names{strcmp(temp_irf{k},variable_names(:,1)),2},'interpreter','latex') %#ok<*NODEF>
        axis('tight')
        counter=counter+1;
        
        subplot(length(temp_irf),2,counter);
        box on; hold on;
        plot(1:irf_sim,[irf_condE_ex(eval(strcat(['dyn_i_',temp_irf{k}])),1:irf_sim)],'-b','LineWidth',2)
         
        if k==1, title('Long Run Shock'); end
        
        axis('tight')
        counter=counter+1;
        
        if k==length(temp_irf)
            if shock_direction_switch==1
            legend('1 SD Positive Shock');
            else
            legend('1 SD Negative Shock');
            end
                        
            set(legend,'Orientation','horizontal','FontSize',8,'Position',[0.4019 0.007035 0.1896 0.03571]);
        end
        
    end % Variable loop within IRF

    mkdir(strcat('Results/',fname))
    saveas(j,strcat('Results/',fname,'/IRF_condE_SRR_LRR'))
    print(strcat('Results/',fname,'/IRF_condE_SRR_LRR'),'-dpdf')
    print(strcat('Results/',fname,'/IRF_condE_SRR_LRR'),'-dpsc')
    close(j)
end

% IRF showing LRR and vol shocks
if stoch_vol_switch==1
    for j=1:length(irf_cell)
        temp_irf=irf_cell{j};
        figure(j)
        counter=1;
        for k=1:length(temp_irf)
            subplot(length(temp_irf),2,counter);
            box on; hold on;
            plot(1:irf_sim,[irf_condE_ex(eval(strcat(['dyn_i_',temp_irf{k}])),1:irf_sim)],'-b','LineWidth',2)

            if k==1, title('Long Run Shock'); end

            ylabel(variable_names{strcmp(temp_irf{k},variable_names(:,1)),2},'interpreter','latex') %#ok<*NODEF>
            axis('tight')
            counter=counter+1;

            subplot(length(temp_irf),2,counter);
            box on; hold on;
            plot(1:irf_sim,[irf_condE_es(eval(strcat(['dyn_i_',temp_irf{k}])),1:irf_sim)],'-b','LineWidth',2)            
            
            if k==1, title('Volatility Shock'); end

            axis('tight')
            counter=counter+1;

            if k==length(temp_irf)
                if shock_direction_switch==1
                legend('1 SD Positive Shock');
                else
                legend('1 SD Negative Shock');
                end

                set(legend,'Orientation','horizontal','FontSize',8,'Position',[0.4019 0.007035 0.1896 0.03571]);
            end

        end % Variable loop within IRF

        mkdir(strcat('Results/',fname))
        saveas(j,strcat('Results/',fname,'/IRF_condE_LRR_vol'))
        print(strcat('Results/',fname,'/IRF_condE_LRR_vol'),'-dpdf')
        print(strcat('Results/',fname,'/IRF_condE_LRR_vol'),'-dpsc')
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
            plot(1:irf_sim,[irf_condE_ex(eval(strcat(['dyn_i_',temp_irf{k}])),1:irf_sim)],'-b','LineWidth',2)

            if k==1, title('Long Run Shock'); end

            ylabel(variable_names{strcmp(temp_irf{k},variable_names(:,1)),2},'interpreter','latex') %#ok<*NODEF>
            axis('tight')
            counter=counter+1;

            subplot(length(temp_irf),2,counter);
            box on; hold on;
            plot(1:irf_sim,[irf_condE_eg(eval(strcat(['dyn_i_',temp_irf{k}])),1:irf_sim)],'-b','LineWidth',2)            
            
            if k==1, title('Gold Shock'); end

            axis('tight')
            counter=counter+1;

            if k==length(temp_irf)
                if shock_direction_switch==1
                legend('1 SD Positive Shock');
                else
                legend('1 SD Negative Shock');
                end

                set(legend,'Orientation','horizontal','FontSize',8,'Position',[0.4019 0.007035 0.1896 0.03571]);
            end

        end % Variable loop within IRF

        mkdir(strcat('Results/',fname))
        saveas(j,strcat('Results/',fname,'/IRF_condE_LRR_gold'))
        print(strcat('Results/',fname,'/IRF_condE_LRR_gold'),'-dpdf')
        print(strcat('Results/',fname,'/IRF_condE_LRR_gold'),'-dpsc')
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
            plot(1:irf_sim,[irf_condE_eg(eval(strcat(['dyn_i_',temp_irf{k}])),1:irf_sim)],'-b','LineWidth',2)

            if k==1, title('Gold Shock'); end

            ylabel(variable_names{strcmp(temp_irf{k},variable_names(:,1)),2},'interpreter','latex') %#ok<*NODEF>
            axis('tight')
            counter=counter+1;

            subplot(length(temp_irf),2,counter);
            box on; hold on;
            plot(1:irf_sim,[irf_condE_es(eval(strcat(['dyn_i_',temp_irf{k}])),1:irf_sim)],'-b','LineWidth',2)            
            
            if k==1, title('Volatility Shock'); end

            axis('tight')
            counter=counter+1;

            if k==length(temp_irf)
                if shock_direction_switch==1
                legend('1 SD Positive Shock');
                else
                legend('1 SD Negative Shock');
                end

                set(legend,'Orientation','horizontal','FontSize',8,'Position',[0.4019 0.007035 0.1896 0.03571]);
            end

        end % Variable loop within IRF

        mkdir(strcat('Results/',fname))
        saveas(j,strcat('Results/',fname,'/IRF_condE_gold_vol'))
        print(strcat('Results/',fname,'/IRF_condE_gold_vol'),'-dpdf')
        print(strcat('Results/',fname,'/IRF_condE_gold_vol'),'-dpsc')
        close(j)
    end
end
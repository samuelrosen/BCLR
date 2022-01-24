%% program to do the following:
%   - create nice time series plots from the data
%   - estimate VARs from actual or simulated data
%   - plot IRFs from the data VARs for either
%       - a 1-unit impulse (standard)
%       - a sequence of shocks as in the great recession
%   - compare IRF from data VAR to IRF from model equations

    % toolbox that includes some pre-made VAR functions such as vectorar
    addpath(genpath('matlab')); 
    addpath(genpath('matlab/MFEToolbox')); 
    addpath(genpath('matlab/PattonWebsite')); 
    addpath(genpath('matlab/CominGertler')); 
    addpath(genpath('data_for_Productivity_Uncertainty')); 
    addpath(genpath('data_for_VAR'));
    
    % housekeeping
    clear; clc;

    
%% import all data series (qtrly and annual) used in the data VARs

    % data series computed from investment regressions:
    % - log tfp growth (dtfp)
    % - long-run productivity (x)
    % - fitted volatility (expvol)
    % - standard errors of fitted volatility (expvol_se)
    % note: these mat files were produced from Wenix's program
    %       measure_productivity_uncertainty.m
    
        % declare start year for data_inv_reg, which we run
        % over different sample periods because we are not sure
        % which choice is most consistent with rest of empirical
        % analysis.
        % as of july 2019 draft: we use 1972 and 1961 as robustness. to
        % avoid confusion, the robustness figures from 1961 need to be
        % created and then manually renamed in order to be updated if
        % needed
        sample_start_year = 1972
    
        if sample_start_year==1969
            load data_inv_reg_qtr_1969_2016                     
            load data_inv_reg_ann_1969_2016   
        elseif sample_start_year==1961
            load data_inv_reg_qtr_1961_2016                     
            load data_inv_reg_ann_1961_2016               
        elseif sample_start_year==1972
            % load the 1961 version in case we need to run VAR on longer sample
            load data_inv_reg_qtr_1961_2016                     
            load data_inv_reg_ann_1961_2016               
            data_inv_reg_ann_1961 = data_inv_reg_ann;
            data_inv_reg_qtr_1961 = data_inv_reg_qtr;
            clearvars data_inv_reg_qtr data_inv_reg_qtr
            
            load data_inv_reg_qtr_1972_2016                     
            load data_inv_reg_ann_1972_2016                           
        else
            error('sample_start_year not accounted for above');
        end
        
        
    % macro data series (nominal and real)
    % note: these data series were compiled and cleaned in Stata. the 
    %       specific program that created these csv files is 
    %       "02b_export_macro_data_for_VAR.do". 

    
        % quarterly
        T = readtable('data_macro_qtr_from_1947.csv');
        data_macro_qtr = table2struct(T,'ToScalar',true);            
        clear T

        % annual
        T = readtable('data_macro_ann_from_1929.csv');
        data_macro_ann = table2struct(T,'ToScalar',true);      
        clear T

        % double check new var quarterly data availability
        %[[1:length(data_macro_qtr.year)]', data_macro_qtr.year/1000, data_macro_qtr.qtr,  data_macro_qtr.tobinQ]
        %[[1:length(data_macro_qtr.year)]', data_macro_qtr.total_iss] 
        % tobinQ from 1951q4 (row 25)
        % total_iss from 1981q1 to 2017q4 (row 142 to 277)
        
        % double check new var annual data availability
        %[[1:length(data_macro_ann.year)]', data_macro_ann.year/1000]        
        %[[1:length(data_macro_ann.year)]', data_macro_ann.dtfp]
        %[[1:length(data_macro_ann.year)]', data_macro_ann.ivol]
        %[[1:length(data_macro_ann.year)]', data_macro_ann.baa10ym]
        %[[1:length(data_macro_ann.year)]', data_macro_ann.total_app]        
        %[[1:length(data_macro_ann.year)]', data_macro_ann.total_app_usa]   
        % dtfp from 1948 through 2016 (from row 20)
        % ivol from 1929 through 2016 (full sample)
        % baa10ym from 1953 through 2016 (from row 25)
        % total_app from 1929 through 2016 (full sample)
        % dtfp from 1963 through 2016 (from row 35)
        
        
        
    % HML returns data series 
    % note: these data series were compiled and cleaned in Stata. the 
    %       specific program that created these csv files is 
    %       "02b_export_macro_data_for_VAR.do". 

    
        % quarterly
        T = readtable('hml_retuns_qtr_1972_2016.csv');
        data_hml_qtr = table2struct(T,'ToScalar',true);  
        data_hml_qtr.m = data_hml_qtr.year;
        clear T        

        
        
%% 2x3 figure of 3-variable VAR in levels

clc;

    % main specification without government
    var2_set = {'ivol'}; 
    var3_set = {'ln_IPPrnd_real'; 'ln_Ip_real'; 'ln_Yp_real'}; 
    My_Ylims_c1 = [-1.0, 1.0];
    My_Ylims_c2 = [-3.0, 4.0];    
    My_Ylims_c3 = [-1.0, 1.2];
    
    % credit control variable sets
    ccvarlist = {'baa10ym'}; % benchmark
    %ccvarlist = {'none'};    
    %ccvarlist = {'none'; 'baa10ym';'aaa10ym'};
    %ccvarlist = {'none'; 'baa10ym';'aaa10ym';'nfci';'anfci'};
    
    % include time trend?
    %time_trend_list = {'yestt', 'nott'};
    time_trend_list = {'nott'};
    
    % sample start year
    start_year_list = [1961, 1972, 1982];
    %sample_start_year = 1972; % default value
    %sample_start_year = 1982; % referee robustness request
    
    
bbb = 1;    
ccc = 1;    
ttt = 1;
for bbb = 1:length(var2_set)
 for ccc = 1:length(ccvarlist)
  for ttt = 1:length(time_trend_list)
   for yyy = 1:length(start_year_list)
       
    % assign variables
    %myfilter = char(filterlist{fff});
    myvar2     = char(var2_set{bbb});
    myinvvar_1 = char(var3_set{1});
    myinvvar_2 = char(var3_set{2});
    myinvvar_3 = char(var3_set{3});
    myccvar = char(ccvarlist{ccc});
    myttchoice = char(time_trend_list{ttt});
    sample_start_year = start_year_list(yyy);

    % assign variable labels
    for varnum=1:3
        
        % temporary loop var name
        eval(strcat('temp_invvar = myinvvar_',num2str(varnum),';'));
        
        % figure out label based on name
        temp_MyVar_ylabel = 'NEED LABEL';
        temp_MyVar_title  = 'NEED TITLE';
        if strcmp(temp_invvar,'Ig_Itot')
            temp_MyVar_ylabel = 'I_g / (I_g + I_p)';
            temp_MyVar_title = 'Govt. to Total Inv. (I_g / (I_g + I_p))';
        end
        if strcmp(temp_invvar,'Ip_Itot')
            temp_MyVar_ylabel = 'I_p / (I_g + I_p)';
            temp_MyVar_title = 'Priv. to Total Inv. (I_p / (I_g + I_p))';
        end    
        if strcmp(temp_invvar,'IPPtot_real')
            temp_MyVar_ylabel = texlabel('log(I_I_P_P)');
            temp_MyVar_title = 'Priv. IPP (incl. R&D) Inv. (log(I_I_P_P))';
        end
        if strcmp(temp_invvar,'IPPrnd_real')
            temp_MyVar_ylabel = texlabel('log(I_R_&_D)');
            temp_MyVar_title = 'Priv. R&D Inv. (log(I_R_&_D))';
        end
        if strcmp(temp_invvar,'Ig_real')
            temp_MyVar_ylabel = texlabel('log(I_g)');
            temp_MyVar_title = 'Govt. Inv. (log(I_g))';
        end
        if strcmp(temp_invvar,'Ip_real')
            temp_MyVar_ylabel = texlabel('log(I_p)');
            temp_MyVar_title = 'Priv. Total Inv. (log(I_p))';
        end    
        if strcmp(temp_invvar,'Ip_NOTrnd_real')
            temp_MyVar_ylabel = texlabel('log(I_p-I_R_&_D)');
            temp_MyVar_title = 'Priv. Non-R&D Inv. (log(I_p-I_R_&_D))';
        end    
        if strcmp(temp_invvar,'Itot_real')
            temp_MyVar_ylabel = texlabel('log(I_g+I_p)');
            temp_MyVar_title = 'Total Inv. (log(I_g+I_p))';
        end            
        if strcmp(temp_invvar,'Itang_v1_real')
            temp_MyVar_ylabel = texlabel('log(I_g+I_p-I_R_&_D)');
            temp_MyVar_title = 'Tangible Inv. (log(I_g+I_p-I_R_&_D))';
        end                    
        if strcmp(temp_invvar,'Itang_v2_real')
            temp_MyVar_ylabel = texlabel('log(I_g+I_p-I_I_P_P)');
            temp_MyVar_title = 'Tangible Inv. (log(I_g+I_p-I_I_P_P))';
        end                                    
        if strcmp(temp_invvar,'Yp_real')
            temp_MyVar_ylabel = texlabel('log(Y_p)');
            temp_MyVar_title = 'Priv. Output (log(Y_p))';
        end          
        if strcmp(temp_invvar,'Y_real')
            temp_MyVar_ylabel = texlabel('log(Y_G_D_P)');
            temp_MyVar_title = 'GDP (log(Y_G_D_P))';
        end    
        if strcmp(temp_invvar,'dtfp_FMA05')
            temp_MyVar_ylabel = texlabel('Delta a_t_,_t_+_5yrs}');
            temp_MyVar_title = '5-year FMA dtfp';
        end         
        if strcmp(temp_invvar,'Ig_Y')
            temp_MyVar_ylabel = 'I_g / Y';
            temp_MyVar_title = 'Govt. to GDP (I_g / Y)';
        end  
        if strcmp(temp_invvar,'tobinQ')
            temp_MyVar_ylabel = texlabel('log(V/E)');
            temp_MyVar_title = 'Tobin Q (log(V/E))';
        end         
        if strcmp(temp_invvar,'labor_share_govt')
            temp_MyVar_ylabel = texlabel('E_g/(E_g+E_p)');
            temp_MyVar_title = 'Govt Empl. Share (E_g/(E_g+E_p))';
        end           
        if strcmp(temp_invvar,'labor_share_priv')
            temp_MyVar_ylabel = texlabel('E_p/(E_g+E_p)');
            temp_MyVar_title = 'Private Empl. Share (E_p/(E_g+E_p))';
        end   
        if strcmp(temp_invvar,'ln_IPPrnd_real')
            temp_MyVar_ylabel = texlabel('log(I_R_&_D)');
            temp_MyVar_title = 'Priv. R&D Inv. (log(I_R_&_D))';
        end
        if strcmp(temp_invvar,'ln_Ig_real')
            temp_MyVar_ylabel = texlabel('log(I_g)');
            temp_MyVar_title = 'Govt. Inv. (log(I_g))';
        end
        if strcmp(temp_invvar,'ln_Ip_real')
            temp_MyVar_ylabel = texlabel('log(I_p)');
            temp_MyVar_title = 'Priv. Total Inv. (log(I_p))';
        end        
        if strcmp(temp_invvar,'ln_Yp_real')
            temp_MyVar_ylabel = texlabel('log(Y_p)');
            temp_MyVar_title = 'Priv. Output (log(Y_p))';
        end         
        if strcmp(temp_invvar,'dln_IPPrnd_real')
            temp_MyVar_ylabel = texlabel('log(I_R_&_D)');
            temp_MyVar_title = 'Change in Priv. R&D Inv. (Delta log(I_R_&_D))';
        end
        if strcmp(temp_invvar,'dln_Ig_real')
            temp_MyVar_ylabel = texlabel('\Delta log(I_g)');
            temp_MyVar_title = 'Change in Govt. Inv. (Delta log(I_g))';
        end
        if strcmp(temp_invvar,'dln_Ip_real')
            temp_MyVar_ylabel = texlabel('\Delta log(I_p)');
            temp_MyVar_title = 'Change in Priv. Total Inv. (Delta log(I_p))';
        end        
        if strcmp(temp_invvar,'dln_Yp_real')
            temp_MyVar_ylabel = texlabel('\Delta log(Y_p)');
            temp_MyVar_title = 'Change in Priv. Output (Delta log(Y_p))';
        end         
        
        % assign label
        if varnum==1
            MyVar_ylabel_1 = texlabel(temp_MyVar_ylabel);
            MyVar_title_1  = texlabel(temp_MyVar_title);
        end
        if varnum==2
            MyVar_ylabel_2 = texlabel(temp_MyVar_ylabel);
            MyVar_title_2  = texlabel(temp_MyVar_title);
        end
        if varnum==3
            MyVar_ylabel_3 = texlabel(temp_MyVar_ylabel);
            MyVar_title_3  = texlabel(temp_MyVar_title);
        end
        if varnum==4
            MyVar_ylabel_4 = texlabel(temp_MyVar_ylabel);
            MyVar_title_4  = texlabel(temp_MyVar_title);
        end        
        if varnum==5
            MyVar_ylabel_5 = texlabel(temp_MyVar_ylabel);
            MyVar_title_5  = texlabel(temp_MyVar_title);
        end                
        
    end

    % figure out starting and ending positions
    %sample_start_year = 1972; % assigned above instead
    sample_end_year   = 2016;        
    pos_start = find((data_macro_qtr.year>=sample_start_year),1,'first');        
    pos_end   = find((data_macro_qtr.year<=sample_end_year),1,'last');
    disp(char(strcat({'macro var data from '},num2str(data_macro_qtr.year(pos_start)),'q',num2str(data_macro_qtr.qtr(pos_start)))))
    disp(char(strcat({'macro var data to '},  num2str(data_macro_qtr.year(pos_end)),  'q',num2str(data_macro_qtr.qtr(pos_end)))))
    
    % first two variables
    %temp_dtfp_qtr   = data_macro_qtr.dtfp( pos_start:pos_end);
    temp_tfp_qtr   = data_macro_qtr.tfp( pos_start:pos_end); % tfp in levels
    eval(strcat('temp_var2_qtr = data_macro_qtr.',myvar2,'(pos_start:pos_end);'));    
    
    % third variable (economic aggregate)
    for varnum=1:3             
        
        % name of var
        eval(strcat('tempvarname = myinvvar_',num2str(varnum),';'));
        
        % grab the full time series of the var
        eval(strcat('var3_raw_qtr = data_macro_qtr.',tempvarname,';'));
        
        % truncated series to match same period as other series
        var3_trunc = var3_raw_qtr(pos_start:pos_end);
        
        % final matrix for VAR                
        %temp_y_qtr = [temp_dtfp_qtr, temp_var2_qtr, var3_trunc];    
        temp_y_qtr = [temp_tfp_qtr, temp_var2_qtr, var3_trunc];    
       
        % final exogenous variable dataset for quarterly VAR
        temp_x_qtr = ones(size(temp_y_qtr,1),1);
        if ~strcmp(myccvar, 'none')
            eval(strcat('ccvar_raw_qtr = data_macro_qtr.',myccvar,';'));
            temp_ccvar_qtr = ccvar_raw_qtr(pos_start:pos_end);
            temp_x_qtr = [temp_x_qtr, temp_ccvar_qtr];        
        end     
        if strcmp(myttchoice,'yestt')
            time_var = [1:length(temp_x_qtr)]';
            temp_x_qtr = [temp_x_qtr, time_var];        
        end
        
        eval(strcat('y_qtr_',num2str(varnum),' = temp_y_qtr;'));
        eval(strcat('x_exo_qtr_',num2str(varnum),' = temp_x_qtr;'));
        
        clear var3_raw_qtr var3_trunc temp_var3_qtr temp_y_qtr temp_x_qtr
        
        % define different shock matrices

            std_IRF_length_qtr = 24;

            % 1-std dtfp shock
            std_dtfp_shk_mat_qtr      = zeros(3 , std_IRF_length_qtr);
            std_dtfp_shk_mat_qtr(1,1) = 1;           

            % 1-std ivol shock
            std_ivol_shk_mat_qtr      = zeros(3 , std_IRF_length_qtr);
            std_ivol_shk_mat_qtr(2,1) = 1;             
            
        % compute IRFs 

            % dtfp shk
            eval(strcat('IRFout_dtfpshk_qtr_',num2str(varnum),' = gen_IRF_vectors_dataVAR_nvars( y_qtr_',num2str(varnum),', x_exo_qtr_',num2str(varnum),', [], std_dtfp_shk_mat_qtr, 0);'))

            % ivol shk           
            eval(strcat('IRFout_ivolshk_qtr_',num2str(varnum),' = gen_IRF_vectors_dataVAR_nvars( y_qtr_',num2str(varnum),', x_exo_qtr_',num2str(varnum),', [], std_ivol_shk_mat_qtr, 0);'));
            
    end

    
    % plot 2x3 IRF    
    close ALL
    %fname = strcat('IRFs_2x4_dtfp_',myvar2,'_',myinvvar_1,'_or_',myinvvar_2,'_or_',myinvvar_3,'_or_',myinvvar_4,'_control_',myccvar,'_',num2str(sample_start_year),'_',num2str(sample_end_year));    
    %fname = strcat('IRFs_2x5_tfp_',myvar2,'_',myinvvar_1,'_or_',myinvvar_2,'_or_',myinvvar_3,'_or_',myinvvar_4,'_control_',myccvar,'_',myttchoice,'_',num2str(sample_start_year),'_',num2str(sample_end_year));    
    fname = strcat('IRFs_2x3_tfp_',myvar2,'_',myinvvar_1,'_or_',myinvvar_2,'_or_',myinvvar_3,'_control_',myccvar,'_',myttchoice,'_',num2str(sample_start_year),'_',num2str(sample_end_year));    
    figure(1);
    
        % set size of figure so it fills page
        set(gcf, 'PaperPositionMode', 'manual');
        set(gcf, 'PaperUnits', 'inches');
        set(gcf, 'PaperPosition', [0 0 14.00 7.00]);            
  
        IRF_length_plot = std_IRF_length_qtr+1;
        
        % quarterly data for var 1

            subplot(2,3,1); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_dtfpshk_qtr_1.oirf_var3, '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_dtfpshk_qtr_1.oirf_var3_ciL, '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_dtfpshk_qtr_1.oirf_var3_ciU, '--b', 'Linewidth', 1);
            %title(strcat('\fontsize{12}','Productivity Shock'));
            %xlabel('Quarters');
            %ylabel(MyVar_ylabel_1);
            title(strcat('\fontsize{12}', MyVar_title_1),'FontWeight','normal');
            xlabel(' ');
            ylabel('Percent');            
            axis('tight');
            ylim(My_Ylims_c1);

            subplot(2,3,4); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_1.oirf_var3, '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_1.oirf_var3_ciL, '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_1.oirf_var3_ciU, '--b', 'Linewidth', 1);
            %title(strcat('\fontsize{12}','Volatility Shock'));
            %xlabel('Quarters');
            %ylabel(MyVar_ylabel_1);
            title(strcat('\fontsize{12}',' '));
            xlabel('Quarters');
            ylabel('Percent');                        
            axis('tight');
            ylim(My_Ylims_c1);        
        
            
        % quarterly data for var 2

            subplot(2,3,2); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_dtfpshk_qtr_2.oirf_var3, '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_dtfpshk_qtr_2.oirf_var3_ciL, '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_dtfpshk_qtr_2.oirf_var3_ciU, '--b', 'Linewidth', 1);
            %title(strcat('\fontsize{12}','Productivity Shock'));
            %xlabel('Quarters');
            %ylabel(MyVar_ylabel_2);
            title(strcat('\fontsize{12}', MyVar_title_2),'FontWeight','normal');
            xlabel(' ');
            ylabel(' ');              
            axis('tight');
            ylim(My_Ylims_c2);

            subplot(2,3,5); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_2.oirf_var3, '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_2.oirf_var3_ciL, '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_2.oirf_var3_ciU, '--b', 'Linewidth', 1);
            %title(strcat('\fontsize{12}','Volatility Shock'));
            %xlabel('Quarters');
            %ylabel(MyVar_ylabel_2);
            title(strcat('\fontsize{12}',' '));
            xlabel('Quarters');
            ylabel(' ');               
            axis('tight');
            ylim(My_Ylims_c2);
   
            
        % quarterly data for var 3

            subplot(2,3,3); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_dtfpshk_qtr_3.oirf_var3, '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_dtfpshk_qtr_3.oirf_var3_ciL, '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_dtfpshk_qtr_3.oirf_var3_ciU, '--b', 'Linewidth', 1);
            %title(strcat('\fontsize{12}','Productivity Shock'));
            %xlabel('Quarters');
            %ylabel(MyVar_ylabel_3);
            title(strcat('\fontsize{12}', MyVar_title_3),'FontWeight','normal');
            xlabel(' ');
            ylabel(' ');                          
            axis('tight');
            ylim(My_Ylims_c3);

            subplot(2,3,6); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_3.oirf_var3, '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_3.oirf_var3_ciL, '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_3.oirf_var3_ciU, '--b', 'Linewidth', 1);
            %title(strcat('\fontsize{12}','Volatility Shock'));
            %xlabel('Quarters');
            %ylabel(MyVar_ylabel_3);
            title(strcat('\fontsize{12}',' '));
            xlabel('Quarters');
            ylabel(' ');                           
            axis('tight');
            ylim(My_Ylims_c3);      
                       
            
            % add shock labels
            
                myfig = gcf;
            
                annotation(myfig,'textbox',...
                    [0.0265625 0.71496062992126 0.0515625 0.0840311679790023],...
                    'String',{'Productivity','Shock'},...
                    'LineStyle','none',...
                    'HorizontalAlignment','center',...
                    'FontWeight','bold',...
                    'FontSize',12,...
                    'FitBoxToText','off');    
            
                annotation(myfig,'textbox',...
                    [0.025 0.244094488188976 0.0515625 0.0840311679790026],...
                    'String',{'Volatility','Shock'},...
                    'LineStyle','none',...
                    'HorizontalAlignment','center',...
                    'FontWeight','bold',...
                    'FontSize',12,...
                    'FitBoxToText','off');
            
            
        % save jpg        
        saveas(1,strcat('figures/',fname),'png')
        saveas(1,strcat('figures/',fname)) 
        %saveas(1,strcat('output_for_paper/Figures/',fname),'png')
        %saveas(1,strcat('output_for_paper/Figures/',fname))  
        %close(1)                    

   end % yyy
  end % ttt
 end % ccc
end % bbb



%% 2x3 figure of 3-variable VAR: compare hpfilter vs bandpass

clc;

% must do both filters in this section because they are both plotted
filterlist = {'hpfilter','bandpass'}; % 
    
    % benchmark
    %var_set = {'Ig_real';'IPPrnd_real';'Ip_real';'labor_share_govt';'Yp_real'}; 
    var_set = {'IPPrnd_real';'Ip_real';'Yp_real';'Ig_real';'labor_share_govt'}; 
    % note: only first 3 vars will be plotted. doing this way to avoid editing
    % below code too much
    
        % ylim used here for tighter fit        
        My_Ylims_c1 = [-1.0, 0.5];
        My_Ylims_c2 = [-3.0, 1.0];   
        My_Ylims_c3 = [-1.0, 0.5];
        My_Ylims_c4 = [-0.5, 0.5];
        My_Ylims_c5 = [-0.5, 1.0];        
    
    % try with Itotal
    %var_set = {'Ig_real';'Itot_real';'Ip_real';'labor_share_govt';'Yp_real'}; 
    %My_Ylims_c2 = [-1.5, 0.5];
      
        
    % credit control
    ccvarlist = {'baa10ym'}; % benchmark
    %ccvarlist = {'none'};     
    %ccvarlist = {'none'; 'baa10ym';'aaa10ym'};
    %ccvarlist = {'none'; 'baa10ym';'aaa10ym';'nfci';'anfci'};
    
    % sample start year
    sample_start_year = 1972; % default value
    %sample_start_year = 1982; % referee robustness request
    
    % sample end year
    sample_end_year   = 2016;        


for ccc = 1:length(ccvarlist)
  for fff = 1:length(filterlist)
     
    % assign variables
    myfilter = char(filterlist{fff});
    myinvvar_1 = char(var_set{1});
    myinvvar_2 = char(var_set{2});
    myinvvar_3 = char(var_set{3});
    myinvvar_4 = char(var_set{4});
    myinvvar_5 = char(var_set{5});
    myccvar = char(ccvarlist{ccc});

  
    % assign variable labels
    for varnum=1:5
        
        % temporary loop var name
        eval(strcat('temp_invvar = myinvvar_',num2str(varnum),';'));
             
        % figure out label based on name
        temp_MyVar_ylabel = 'NEED LABEL';
        temp_MyVar_title  = 'NEED TITLE';
        if strcmp(temp_invvar,'Ig_Itot')
            temp_MyVar_ylabel = 'I_g / (I_g + I_p)';
            temp_MyVar_title = 'Govt. to Total Inv. (I_g / (I_g + I_p))';
        end        
        if strcmp(temp_invvar,'Ip_Itot')
            temp_MyVar_ylabel = 'I_p / (I_g + I_p)';
            temp_MyVar_title = 'Priv. to Total Inv. (I_p / (I_g + I_p))';
        end    
        if strcmp(temp_invvar,'IPPtot_real')
            temp_MyVar_ylabel = texlabel('log(I_I_P_P)');
            temp_MyVar_title = 'Priv. IPP (incl. R&D) Inv. (log(I_I_P_P))';
        end
        if strcmp(temp_invvar,'IPPrnd_real')
            temp_MyVar_ylabel = texlabel('log(I_R_&_D)');
            temp_MyVar_title = 'Priv. R&D Inv. (log(I_R_&_D))';
        end
        if strcmp(temp_invvar,'Ig_real')
            temp_MyVar_ylabel = texlabel('log(I_g)');
            temp_MyVar_title = 'Govt. Inv. (log(I_g))';
        end
        if strcmp(temp_invvar,'Ip_real')
            temp_MyVar_ylabel = texlabel('log(I_p)');
            temp_MyVar_title = 'Priv. Total Inv. (log(I_p))';
        end    
        if strcmp(temp_invvar,'Ip_NOTrnd_real')
            temp_MyVar_ylabel = texlabel('log(I_p-I_R_&_D)');
            temp_MyVar_title = 'Priv. Non-R&D Inv. (log(I_p-I_R_&_D))';
        end    
        if strcmp(temp_invvar,'Itot_real')
            temp_MyVar_ylabel = texlabel('log(I_g+I_p)');
            temp_MyVar_title = 'Total Inv. (log(I_g+I_p))';
        end            
        if strcmp(temp_invvar,'Itang_v1_real')
            temp_MyVar_ylabel = texlabel('log(I_g+I_p-I_R_&_D)');
            temp_MyVar_title = 'Tangible Inv. (log(I_g+I_p-I_R_&_D))';
        end                    
        if strcmp(temp_invvar,'Itang_v2_real')
            temp_MyVar_ylabel = texlabel('log(I_g+I_p-I_I_P_P)');
            temp_MyVar_title = 'Tangible Inv. (log(I_g+I_p-I_I_P_P))';
        end                                    
        if strcmp(temp_invvar,'Yp_real')
            temp_MyVar_ylabel = texlabel('log(Y_p)');
            temp_MyVar_title = 'Priv. Output (log(Y_p))';
        end          
        if strcmp(temp_invvar,'Y_real')
            temp_MyVar_ylabel = texlabel('log(Y_G_D_P)');
            temp_MyVar_title = 'GDP (log(Y_G_D_P))';
        end    
        if strcmp(temp_invvar,'dtfp_FMA05')
            temp_MyVar_ylabel = texlabel('Delta a_t_,_t_+_5yrs}');
            temp_MyVar_title = '5-year FMA dtfp';
        end         
        if strcmp(temp_invvar,'Ig_Y')
            temp_MyVar_ylabel = 'I_g / Y';
            temp_MyVar_title = 'Govt. to GDP (I_g / Y)';
        end      
        if strcmp(temp_invvar,'labor_share_govt')
            temp_MyVar_ylabel = 'L_g / (L_g + L_p)';
            temp_MyVar_title = 'Govt. Labor Share (L_g / (L_g + L_p))';            
        end          
        
        % assign label
        if varnum==1
            MyVar_ylabel_1 = texlabel(temp_MyVar_ylabel);
            MyVar_title_1  = texlabel(temp_MyVar_title);
        end
        if varnum==2
            MyVar_ylabel_2 = texlabel(temp_MyVar_ylabel);
            MyVar_title_2  = texlabel(temp_MyVar_title);
        end
        if varnum==3
            MyVar_ylabel_3 = texlabel(temp_MyVar_ylabel);
            MyVar_title_3  = texlabel(temp_MyVar_title);
        end
        if varnum==4
            MyVar_ylabel_4 = texlabel(temp_MyVar_ylabel);
            MyVar_title_4  = texlabel(temp_MyVar_title);
        end        
        if varnum==5
            MyVar_ylabel_5 = texlabel(temp_MyVar_ylabel);
            MyVar_title_5  = texlabel(temp_MyVar_title);
        end             

                
        clearvars temp_MyVar_ylabel temp_MyVar_title;
        
    end

    
%     % compile quarterly data for each variable    
%     start_year_qtr = min(data_inv_reg_qtr.year);
%     if sample_start_year==1961
%         pos_start      = find((data_macro_qtr.year>=start_year_qtr),1,'first'); % start 1 qtr later so macro data is 1961Q1:2016Q4
%     else        
%         pos_start      = find((data_macro_qtr.year>=start_year_qtr),1,'first') - 1;        
%     end
%     disp(char(strcat({'macro var data from '},num2str(data_macro_qtr.year(pos_start)),'q',num2str(data_macro_qtr.qtr(pos_start)))))
%     disp(char(strcat({'inv reg data from '},num2str(data_inv_reg_qtr.year(1)),'q',num2str(data_inv_reg_qtr.qtr(1)))))
%     disp(char(strcat({'note: we want macro data to start 1 qtr before inv reg data b/c we take diffs of macro data to prepare them for VAR'})))  
%     
%     % choose ending position such that de-meaned macro data series will be
%     % the same length as the investment regression data series
%     length_qtr_VAR = length(data_inv_reg_qtr.x);
%     pos_end = pos_start+length_qtr_VAR;   
%         
%     %temp_year_qtr_chk = [data_macro_qtr.year(pos_start:pos_end), data_macro_qtr.qtr(pos_start:pos_end)]
%     % add one to pos_start b/c not detrending
%     temp_dtfp_qtr = data_macro_qtr.dtfp(pos_start+1:pos_end);
%     temp_ivol_qtr = data_macro_qtr.ivol(pos_start+1:pos_end);

    % compile quarterly data for each variable    
    if sample_start_year==1961
        pos_start      = find((data_macro_qtr.year>=sample_start_year),1,'first'); % start 1 qtr later so macro data is 1961Q1:2016Q4
    else        
        pos_start      = find((data_macro_qtr.year>=sample_start_year),1,'first') - 1;        
    end
    pos_end   = find((data_macro_qtr.year<=sample_end_year),1,'last');
    disp(char(strcat({'macro var data from '},num2str(data_macro_qtr.year(pos_start)),'q',num2str(data_macro_qtr.qtr(pos_start)))))
    disp(char(strcat({'note: we want macro data to start 1 qtr before inv reg data b/c we take diffs of macro data to prepare them for VAR'})))  
        
    %temp_year_qtr_chk = [data_macro_qtr.year(pos_start:pos_end), data_macro_qtr.qtr(pos_start:pos_end)]
    % add one to pos_start b/c not detrending
    temp_dtfp_qtr = data_macro_qtr.dtfp(pos_start+1:pos_end);
    temp_ivol_qtr = data_macro_qtr.ivol(pos_start+1:pos_end);        
        
        
    for varnum=1:5          
        
        eval(strcat('tempvarname = myinvvar_',num2str(varnum),';'));
        
        eval(strcat('var3_raw_qtr = data_macro_qtr.',tempvarname,';'));
        
        % truncated series to match other series
        var3_trunc = var3_raw_qtr(pos_start:pos_end);

        % de-trend 4th variable using HP filter or something else                    
        
            temp_var3_qtr = nan(size(var3_trunc));
        
            % HP filter. use pos_start+1 because no need to take first differences
            if strcmp(myfilter,'hpfilter')            
                raw_var3_qtr     = log(var3_trunc(2:end));
                smooth_var3_qtr  = hpfilter(raw_var3_qtr, 1600); % quarterly data smoothing 
                temp_var3_qtr    = raw_var3_qtr - smooth_var3_qtr;
            end

            % linear de-trend
            if strcmp(myfilter,'lindetrend')          
                temp_var3_qtr = prep_raw_data_for_VAR( var3_trunc) ;
            end
            
            % Comin Gertler (2006) band-pass
            % The function is bandpass(X,pl,pu). X is the raw data, pl and pu is the range of frequencies we want to extract. 
            % Recommended by Comin and Gertler (attached below), we should choose pl = 2 and pu = 200 for the quarterly data 
            % to extract the medium-term cycles. 
            if strcmp(myfilter,'bandpass')  
                
                size(var3_trunc);
                raw_var3_qtr = log(var3_trunc(2:end)); % no reduction in size from bandpass --> need to cut first obs for VAR
                temp_var3_qtr = bandpass(raw_var3_qtr, 2, 200);
                %temp_var3_qtr = bandpass(raw_var3_qtr, 32, 200);
                size(temp_var3_qtr); % no reduction in size from bandpass                                

            end

            
        % final dataset for VAR             
        y_qtr_reg = [temp_dtfp_qtr, temp_ivol_qtr];    
        %if strcmp(tempvarname,'Ig_Itot') || strcmp(tempvarname,'Ip_Itot') % series to enter VAR in levels
        % series to enter VAR in levels
        if strcmp(tempvarname,'Ig_Itot') ...
                || strcmp(tempvarname,'Ip_Itot') ...
                || strcmp(tempvarname,'Ig_Y') ...
                || strcmp(tempvarname,'labor_share_priv') ...
                || strcmp(tempvarname,'labor_share_govt') 
            temp_y_qtr = [y_qtr_reg, exp(temp_var3_qtr)];    
        else
            temp_y_qtr = [y_qtr_reg, temp_var3_qtr];    
        end

        % final exogenous variable dataset for quarterly VAR
        temp_x_qtr = ones(size(temp_y_qtr,1),1);
        if ~strcmp(myccvar, 'none')
            eval(strcat('ccvar_raw_qtr = data_macro_qtr.',myccvar,';'));
            temp_ccvar_qtr = ccvar_raw_qtr(pos_start+1:pos_end);
            temp_x_qtr = [temp_x_qtr, temp_ccvar_qtr];        
        end      
        
        eval(strcat('y_qtr_',num2str(varnum),' = temp_y_qtr;'));
        eval(strcat('x_exo_qtr_',num2str(varnum),' = temp_x_qtr;'));
        
        clear var3_raw_qtr var3_trunc temp_var3_qtr temp_y_qtr temp_x_qtr
        
        % define different shock matrices

            std_IRF_length_qtr = 24;

            % 1-std dtfp shock
            %std_dtfp_shk_mat_qtr      = zeros(3 , std_IRF_length_qtr);
            std_dtfp_shk_mat_qtr      = zeros(3 , std_IRF_length_qtr+176); % compute longer vector and then truncate in plots as needed
            std_dtfp_shk_mat_qtr(1,1) = 1;            

            % 1-std ivol shock
            %std_ivol_shk_mat_qtr      = zeros(3 , std_IRF_length_qtr);
            std_ivol_shk_mat_qtr      = zeros(3 , std_IRF_length_qtr+176); % compute longer vector and then truncate in plots as needed
            std_ivol_shk_mat_qtr(2,1) = 1;             
    
        % compute IRFs 

            % dtfp shk
            %eval(strcat('IRFout_dtfpshk_qtr_',num2str(varnum),' = gen_IRF_vectors_dataVAR_nvars( y_qtr_',num2str(varnum),', x_exo_qtr_',num2str(varnum),', [], std_dtfp_shk_mat_qtr, 0);'))

            % ivol shk
            eval(strcat('IRFout_ivolshk_qtr_',num2str(varnum),' = gen_IRF_vectors_dataVAR_nvars( y_qtr_',num2str(varnum),', x_exo_qtr_',num2str(varnum),', [], std_ivol_shk_mat_qtr, 0);'));

    end
    
    % save out IRF vectors by filter type
    if strcmp(myfilter,'hpfilter')
        IRFout_hpfilter_ivolshk_1 = IRFout_ivolshk_qtr_1;
        IRFout_hpfilter_ivolshk_2 = IRFout_ivolshk_qtr_2;
        IRFout_hpfilter_ivolshk_3 = IRFout_ivolshk_qtr_3;
        IRFout_hpfilter_ivolshk_4 = IRFout_ivolshk_qtr_4;        
        IRFout_hpfilter_ivolshk_5 = IRFout_ivolshk_qtr_5;  
    elseif strcmp(myfilter,'bandpass')
        IRFout_bandpass_ivolshk_1 = IRFout_ivolshk_qtr_1;
        IRFout_bandpass_ivolshk_2 = IRFout_ivolshk_qtr_2;
        IRFout_bandpass_ivolshk_3 = IRFout_ivolshk_qtr_3;
        IRFout_bandpass_ivolshk_4 = IRFout_ivolshk_qtr_4;                
        IRFout_bandpass_ivolshk_5 = IRFout_ivolshk_qtr_5;                
    else
        error('myfilter not recognized');
    end
    
  end
   

  % plot 2x3 IRF where first row is hpfilter and second row is bandpass    
  for plot_model_lines = 0:0
    close ALL
    if plot_model_lines
        %fname = strcat('IRFs_OnlyVol_data_vs_model_hpfilter_vs_bandpass_2x4_dtfp_x_expvol_',myinvvar_1,'_or_',myinvvar_2,'_or_',myinvvar_3,'_or_',myinvvar_4,'_control_',myccvar);    
        error('do not run with model lines for VAR(3)');
    else
        %fname = strcat('IRFs_OnlyVol_hpfilter_vs_bandpass_2x4_dtfp_ivol_',myinvvar_1,'_or_',myinvvar_2,'_or_',myinvvar_3,'_or_',myinvvar_4,'_control_',myccvar);    
        %fname = strcat('IRFs_OnlyVol_hpfilter_vs_bandpass_2x4_dtfp_ivol_',myinvvar_1,'_or_',myinvvar_2,'_or_',myinvvar_3,'_or_',myinvvar_4,'_control_',myccvar,'_',num2str(sample_start_year));            
        fname = strcat('IRFs_OnlyVol_hpfilter_vs_bandpass_2x3_dtfp_ivol_',myinvvar_1,'_or_',myinvvar_2,'_or_',myinvvar_3,'_control_',myccvar,'_',num2str(sample_start_year));            
    end
    figure(1);
    
        % set size of figure so it fills page
        set(gcf, 'PaperPositionMode', 'manual');
        set(gcf, 'PaperUnits', 'inches');
        set(gcf, 'PaperPosition', [0 0 14.00 7.00]);            
  
        %IRF_length_plot = std_IRF_length_qtr+1;
        % per May 18 2019 call with max, change length of IRF to 20 
        % periods when comparing data vs model
        if plot_model_lines
            IRF_length_plot = std_IRF_length_qtr+1-4;
        else
            IRF_length_plot = std_IRF_length_qtr+1;
        end        
        
        % quarterly data for var 1

            subplot(2,3,1); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_hpfilter_ivolshk_1.oirf_var3(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_hpfilter_ivolshk_1.oirf_var3_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_hpfilter_ivolshk_1.oirf_var3_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);
            if plot_model_lines
                plot(0:IRF_length_plot-1, 100*model_IRF_vol_line_1(1:IRF_length_plot), '-r', 'Linewidth', 2);
            end           
            title(strcat('\fontsize{12}',MyVar_title_1),'FontWeight','normal');
            xlabel(' ');
            ylabel('Percent');
            axis('tight');
            if plot_model_lines
                ylim(My_Ylims_c1);
            else
                ylim(My_Ylims_c1);
            end
            

            subplot(2,3,4); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_bandpass_ivolshk_1.oirf_var3(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_bandpass_ivolshk_1.oirf_var3_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_bandpass_ivolshk_1.oirf_var3_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);
            if plot_model_lines
                plot(0:IRF_length_plot-1, 100*model_IRF_vol_line_1(1:IRF_length_plot), '-r', 'Linewidth', 2);
            end                
            %title(strcat('\fontsize{12}','Volatility Shock'));
            %xlabel('Quarters');
            %ylabel(MyVar_ylabel_1);
            title(strcat('\fontsize{12}',' '));
            xlabel('Quarters');
            ylabel('Percent');            
            axis('tight');
            ylim(My_Ylims_c1);        
        
            
        % quarterly data for var 2

            subplot(2,3,2); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_hpfilter_ivolshk_2.oirf_var3(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_hpfilter_ivolshk_2.oirf_var3_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_hpfilter_ivolshk_2.oirf_var3_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);
            if plot_model_lines
                plot(0:IRF_length_plot-1, 100*model_IRF_vol_line_2(1:IRF_length_plot), '-r', 'Linewidth', 2);
            end                  
            title(strcat('\fontsize{12}',MyVar_title_2),'FontWeight','normal');
            xlabel(' ');
            ylabel(' ');            
            axis('tight');
            if plot_model_lines
                ylim(My_Ylims_c2);
            else
                ylim(My_Ylims_c2);
            end

            subplot(2,3,5); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_bandpass_ivolshk_2.oirf_var3(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_bandpass_ivolshk_2.oirf_var3_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_bandpass_ivolshk_2.oirf_var3_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);
            if plot_model_lines
                plot(0:IRF_length_plot-1, 100*model_IRF_vol_line_2(1:IRF_length_plot), '-r', 'Linewidth', 2);
            end                                
            %title(strcat('\fontsize{12}','Volatility Shock'));
            %xlabel('Quarters');
            %ylabel(MyVar_ylabel_2);
            title(strcat('\fontsize{12}',' '));
            xlabel('Quarters');
            ylabel(' ');                
            axis('tight');
            ylim(My_Ylims_c2);
   
            
        % quarterly data for var 3

            subplot(2,3,3); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_hpfilter_ivolshk_3.oirf_var3(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_hpfilter_ivolshk_3.oirf_var3_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_hpfilter_ivolshk_3.oirf_var3_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);
            if plot_model_lines
                plot(0:IRF_length_plot-1, 100*model_IRF_vol_line_3(1:IRF_length_plot), '-r', 'Linewidth', 2);
            end                                
            %title(strcat('\fontsize{12}','Productivity Shock'));
            %xlabel('Quarters');
            %ylabel(MyVar_ylabel_3);
            title(strcat('\fontsize{12}',MyVar_title_3),'FontWeight','normal');
            xlabel(' ');
            ylabel(' ');               
            axis('tight');
            if plot_model_lines
                ylim(My_Ylims_c3);
            else
                ylim(My_Ylims_c3);
            end            
            

            subplot(2,3,6); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_bandpass_ivolshk_3.oirf_var3(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_bandpass_ivolshk_3.oirf_var3_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_bandpass_ivolshk_3.oirf_var3_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);
            if plot_model_lines
                plot(0:IRF_length_plot-1, 100*model_IRF_vol_line_3(1:IRF_length_plot), '-r', 'Linewidth', 2);
            end                                                
            %title(strcat('\fontsize{12}','Volatility Shock'));
            %xlabel('Quarters');
            %ylabel(MyVar_ylabel_3);
            title(strcat('\fontsize{12}',' '));
            xlabel('Quarters');
            ylabel(' ');                            
            axis('tight');
            ylim(My_Ylims_c3);      
       
            
            % add shock labels
            
                myfig = gcf;
            
                annotation(myfig,'textbox',...
                    [0.0265625 0.71496062992126 0.0515625 0.0840311679790023],...
                    'String',{'Business','Cycle'},...
                    'LineStyle','none',...
                    'HorizontalAlignment','center',...
                    'FontWeight','bold',...
                    'FontSize',12,...
                    'FitBoxToText','off');    
            
                annotation(myfig,'textbox',...
                    [0.025 0.244094488188976 0.0515625 0.0840311679790026],...
                    'String',{'Medium','Cycle'},...
                    'LineStyle','none',...
                    'HorizontalAlignment','center',...
                    'FontWeight','bold',...
                    'FontSize',12,...
                    'FitBoxToText','off');            
            
        % save jpg        
        saveas(1,strcat('figures/',fname),'png')
        saveas(1,strcat('figures/',fname)) 
        saveas(1,strcat('output_for_paper/Figures/',fname),'png')
        saveas(1,strcat('output_for_paper/Figures/',fname))  
        %close(1)                          
  end  
   
    
end 



%% create 2x3 figure that compares vol shock IRFs from different
%  VAR specifications for different QUARTERLY variables

clc;

VAR_start_year = 1972
sample_end_year = 2016

% cc control var
%ccvarlist = {'none'};
ccvarlist = {'baa10ym'};
%ccvarlist = {'none'; 'baa10ym';'aaa10ym'};
ccc = 1;
myccvar = char(ccvarlist{ccc});

% VAR specs for columns 1, 2, and 3
%VARspecs = {'levels','levels','levels'}; % 
VARspecs = {'levels'}; % 
VARorder = 1;
%VARorder = 2;

% varaibles
last_var_choice_list = {'IPPrnd_real'; 'Ip_real'; 'Yp_real'};
My_Ylims_c1 = [-2.0, 1.0];
My_Ylims_c2 = [-3.0, 1.0];    
My_Ylims_c3 = [-1.0, 1.2];

% loop across last var choices
for aaa = 1:length(last_var_choice_list)
    
    last_var_choice = char(last_var_choice_list{aaa});
    
    % compute IRFs for data VARs for 3-variable VAR
    %for vvv = 1:length(VARspecs)
    vvv=1

        myVARspec = char(VARspecs{vvv});

        % figure out starting and ending positions
        %sample_start_year = 1961;
        %sample_end_year   = 2016;     
        if strcmp(myVARspec,'levels')
            pos_start_macro  = find((data_macro_qtr.year>=VAR_start_year),1,'first');        
        else % need extra period for filtering        
            pos_start_macro = find((data_macro_qtr.year>=VAR_start_year),1,'first') - 1; 
        end    
        pos_end_macro   = find((data_macro_qtr.year<=sample_end_year),1,'last');
        disp(char(strcat({'macro var data from '},num2str(data_macro_qtr.year(pos_start_macro)),'q',num2str(data_macro_qtr.qtr(pos_start_macro)))))
        disp(char(strcat({'macro var data to '},  num2str(data_macro_qtr.year(pos_end_macro)),  'q',num2str(data_macro_qtr.qtr(pos_end_macro)))))

        % first two variables
        if strcmp(myVARspec,'levels')
            var1 = data_macro_qtr.tfp( pos_start_macro:pos_end_macro); % tfp in levels
            var2 = data_macro_qtr.ivol( pos_start_macro:pos_end_macro); 
        else
            var1 = data_macro_qtr.dtfp( pos_start_macro+1:pos_end_macro)/4; % dtfp from macro data. need to convert back to quarterly rates from annualized rate
            var2 = data_macro_qtr.ivol( pos_start_macro+1:pos_end_macro); 
        end

        % 3rd variable that may be filtered depending myVARspec
        eval(strcat('var3_raw = data_macro_qtr.',last_var_choice,';'));
        var3_trunc = var3_raw(pos_start_macro:pos_end_macro); % truncated series to match other series
        if strcmp(myVARspec,'levels') % simply compute in log levels
            temp_var3_qtr = log(var3_trunc); 
        else % de-trend 4th variable 

            temp_var3_qtr = nan(size(var3_trunc));

            % HP filter. use pos_start+1 because no need to take first differences
            if strcmp(myVARspec,'hpfilter')            
                raw_var3_qtr     = log(var3_trunc(2:end));
                smooth_var3_qtr  = hpfilter(raw_var3_qtr, 1600); % quarterly data smoothing 
                temp_var3_qtr    = raw_var3_qtr - smooth_var3_qtr;
            end   

            % Comin Gertler (2006) band-pass
            % The function is bandpass(X,pl,pu). X is the raw data, pl and pu is the range of frequencies we want to extract. 
            % Recommended by Comin and Gertler (attached below), we should choose pl = 2 and pu = 200 for the quarterly data 
            % to extract the medium-term cycles. 
            if strcmp(myVARspec,'bandpass')  
                size(var3_trunc);
                raw_var3_qtr = log(var3_trunc(2:end)); % no reduction in size from bandpass --> need to cut first obs for VAR
                temp_var3_qtr = bandpass(raw_var3_qtr, 2, 200);
                size(temp_var3_qtr); % no reduction in size from bandpass                                
            end  

        end

        % series to enter VAR in levels 
        if strcmp(last_var_choice,'Ig_Itot') ...
        || strcmp(last_var_choice,'Ip_Itot') ...
        || strcmp(last_var_choice,'Ig_Y') ...
        || strcmp(last_var_choice,'labor_share_govt') ...
        || strcmp(last_var_choice,'labor_share_priv') ...
        || strcmp(last_var_choice,'itot_y') ...
        || strcmp(last_var_choice,'ip_y') ...
        || strcmp(last_var_choice,'sp_y') ...
        || strcmp(last_var_choice,'priv_saving_to_gdp') ...
            var3 = exp(temp_var3_qtr);
        else
            var3 = temp_var3_qtr; % keep in logs
        end    

        % endogenous vars matrix
        temp_y_qtr = [var1, var2, var3];

        % exogenous vars matrix
        temp_x_qtr = ones(size(temp_y_qtr,1),1);
        if ~strcmp(myccvar, 'none')
            eval(strcat('ccvar_raw_qtr = data_macro_qtr.',myccvar,';'));
            if strcmp(myVARspec,'levels') 
                temp_ccvar_qtr = ccvar_raw_qtr(pos_start_macro:pos_end_macro);
            else
                temp_ccvar_qtr = ccvar_raw_qtr(pos_start_macro+1:pos_end_macro);
            end
            temp_x_qtr = [temp_x_qtr, temp_ccvar_qtr];        
        end      


        % define different shock matrices

            std_IRF_length_qtr = 24;

            % 1-std dtfp shock
            std_dtfp_shk_mat_qtr      = zeros(3 , std_IRF_length_qtr);
            std_dtfp_shk_mat_qtr(1,1) = 1;            

            % 1-std ivol shock
            std_ivol_shk_mat_qtr      = zeros(3 , std_IRF_length_qtr);
            std_ivol_shk_mat_qtr(2,1) = 1;             

            % compute IRFs for ivol shk
            if VARorder==1 
                temp_IRFOUT = gen_IRF_vectors_dataVAR_nvars( temp_y_qtr, temp_x_qtr, [], std_ivol_shk_mat_qtr, 0);
            elseif VARorder==2 
                temp_IRFOUT = gen_IRF_vectors_dataVAR2_nvars( temp_y_qtr, temp_x_qtr, [], std_ivol_shk_mat_qtr, 0);
            else
                error('VARorder not specified');
            end
            %eval(strcat('IRFout_ivolshk_3var_qtr_',num2str(vvv),' = temp_IRFOUT;'));
            eval(strcat('IRFout_ivolshk_3var_qtr_',num2str(aaa),' = temp_IRFOUT;'));

        % clean up
        clear var3_raw_qtr var3_trunc temp_var3_qtr temp_y_qtr temp_x_qtr

    %end % vvv myVARspec list



    % compute IRFs for data VARs for 4-variable VAR
    %for vvv = 1:length(VARspecs)
    vvv=1

        myVARspec = char(VARspecs{vvv});

        % figure out starting and ending positions
        %sample_start_year = 1961;
        %sample_end_year   = 2016;     
        if strcmp(myVARspec,'levels')
            pos_start_macro  = find((data_macro_qtr.year>=VAR_start_year),1,'first');        
        else % need extra period for filtering        
            pos_start_macro = find((data_macro_qtr.year>=VAR_start_year),1,'first') - 1; 
        end    
        pos_end_macro   = find((data_macro_qtr.year<=sample_end_year),1,'last');
        pos_start_invreg = find((data_inv_reg_qtr.year>=VAR_start_year),1,'first');        
        pos_end_invreg   = find((data_inv_reg_qtr.year<=sample_end_year),1,'last');  
        disp(char(strcat({'macro var data from '},num2str(data_macro_qtr.year(pos_start_macro)))));
        disp(char(strcat({'macro var data to '},  num2str(data_macro_qtr.year(pos_end_macro)))));
        disp(char(strcat({'inv reg data from '},num2str(data_inv_reg_qtr.year(pos_start_invreg)))));
        disp(char(strcat({'inv reg data to '},num2str(data_inv_reg_qtr.year(pos_end_invreg)))));

        % first three variables from investment regression
        if strcmp(myVARspec,'levels')
            var1 = data_macro_qtr.tfp( pos_start_macro:pos_end_macro); % tfp in levels
        else
            var1 = data_macro_qtr.dtfp( pos_start_macro+1:pos_end_macro)/4; % dtfp from macro data. need to convert back to quarterly rates from annualized rate
            %var1_chk = data_inv_reg_qtr.dtfp( pos_start_invreg:pos_end_invreg); % dtfp from inv reg data
            %chk_diff = abs(var1 - var1_chk);
            %max(chk_diff)
            %[var1, var1_chk]
        end
        var2 = data_inv_reg_qtr.x( pos_start_invreg:pos_end_invreg);
        var3 = data_inv_reg_qtr.expvol( pos_start_invreg:pos_end_invreg);

        % 4th variable that may be filtered depending myVARspec
        eval(strcat('var4_raw = data_macro_qtr.',last_var_choice,';'));
        var4_trunc = var4_raw(pos_start_macro:pos_end_macro); % truncated series to match other series
        if strcmp(myVARspec,'levels') % simply compute in log levels
            temp_var4_qtr = log(var4_trunc); 
        else % de-trend 4th variable 

            temp_var4_qtr = nan(size(var4_trunc));

            % HP filter. use pos_start+1 because no need to take first differences
            if strcmp(myVARspec,'hpfilter')            
                raw_var4_qtr     = log(var4_trunc(2:end));
                smooth_var4_qtr  = hpfilter(raw_var4_qtr, 1600); % quarterly data smoothing 
                temp_var4_qtr    = raw_var4_qtr - smooth_var4_qtr;
            end   

            % Comin Gertler (2006) band-pass
            % The function is bandpass(X,pl,pu). X is the raw data, pl and pu is the range of frequencies we want to extract. 
            % Recommended by Comin and Gertler (attached below), we should choose pl = 2 and pu = 200 for the quarterly data 
            % to extract the medium-term cycles. 
            if strcmp(myVARspec,'bandpass')  
                size(var4_trunc);
                raw_var4_qtr = log(var4_trunc(2:end)); % no reduction in size from bandpass --> need to cut first obs for VAR
                temp_var4_qtr = bandpass(raw_var4_qtr, 2, 200);
                size(temp_var4_qtr); % no reduction in size from bandpass                                
            end  

        end

        % series to enter VAR in levels 
        if strcmp(last_var_choice,'Ig_Itot') ...
        || strcmp(last_var_choice,'Ip_Itot') ...
        || strcmp(last_var_choice,'Ig_Y') ...
        || strcmp(last_var_choice,'labor_share_govt') ...
        || strcmp(last_var_choice,'labor_share_priv') ...
        || strcmp(last_var_choice,'itot_y') ...
        || strcmp(last_var_choice,'ip_y') ...
        || strcmp(last_var_choice,'sp_y') ...
        || strcmp(last_var_choice,'priv_saving_to_gdp') 
            var4 = exp(temp_var4_qtr);
        else
            var4 = temp_var4_qtr; % keep in logs
        end    

        % endogenous vars matrix
        temp_y_qtr = [var1, var2, var3, var4];

        % exogenous vars matrix
        temp_x_qtr = ones(size(temp_y_qtr,1),1);
        if ~strcmp(myccvar, 'none')
            eval(strcat('ccvar_raw_qtr = data_macro_qtr.',myccvar,';'));
            if strcmp(myVARspec,'levels') 
                temp_ccvar_qtr = ccvar_raw_qtr(pos_start_macro:pos_end_macro);
            else
                temp_ccvar_qtr = ccvar_raw_qtr(pos_start_macro+1:pos_end_macro);
            end
            temp_x_qtr = [temp_x_qtr, temp_ccvar_qtr];        
        end      

        % define different shock matrices

            std_IRF_length_qtr = 24;

            % 1-std dtfp shock
            std_dtfp_shk_mat_qtr      = zeros(4 , std_IRF_length_qtr);
            std_dtfp_shk_mat_qtr(1,1) = 1;            

            % 1-std ivol shock
            std_ivol_shk_mat_qtr      = zeros(4 , std_IRF_length_qtr);
            std_ivol_shk_mat_qtr(3,1) = 1;             

            % compute IRFs for ivol shk
            if VARorder==1 
                temp_IRFOUT = gen_IRF_vectors_dataVAR_nvars( temp_y_qtr, temp_x_qtr, [], std_ivol_shk_mat_qtr, 0);
            elseif VARorder==2
                temp_IRFOUT = gen_IRF_vectors_dataVAR2_nvars( temp_y_qtr, temp_x_qtr, [], std_ivol_shk_mat_qtr, 0);
            else
                error('VARorder not specified');
            end
            %eval(strcat('IRFout_ivolshk_4var_qtr_',num2str(vvv),' = temp_IRFOUT;'));
            eval(strcat('IRFout_ivolshk_4var_qtr_',num2str(aaa),' = temp_IRFOUT;'));

        % clean up
        clear var4_raw_qtr var4_trunc temp_var4_qtr temp_y_qtr temp_x_qtr

    %end % vvv myVARspec list

end % aaa last_var_choice_list    


    % create the 2x3 figure
    close ALL
    figure(1);

        fname = strcat('IRFs_OnlyVol_VAR',num2str(VARorder),'_sample_startyr_',num2str(VAR_start_year),'_to_',num2str(sample_end_year),'_3var_qtr_or_4var_qtr_',last_var_choice,'_control_',myccvar,'_2x3_',char(last_var_choice_list{1}),'_and_',char(last_var_choice_list{2}),'_and_',char(last_var_choice_list{3}));    

        % y label
        temp_MyVar_ylabel = texlabel('Percent');
        if strcmp(last_var_choice,'Yp_real')
            temp_MyVar_ylabel = texlabel('log(Y_p)');
        end    

        % panel titles
%         for vvv = 1:length(VARspecs)
%             myVARspec = char(VARspecs{vvv});    
%             if strcmp(myVARspec,'hpfilter')
%                 temp_mytitle = 'Business Cycle';
%             elseif strcmp(myVARspec,'bandpass') 
%                 temp_mytitle = 'Medium Cycle';
%             elseif strcmp(myVARspec,'levels')
%                 temp_mytitle = 'VAR in Levels';
%             else
%                 error('myVARspec not recognized');
%             end
%             eval(strcat('mytitle_',num2str(vvv),'=temp_mytitle;'));
%         end
        for aaa = 1:length(last_var_choice_list)
            myvar = char(last_var_choice_list{aaa});    
            if strcmp(myvar,'IPPrnd_real')
                temp_mytitle = 'Priv. R&D Inv. (log(I_R_&_D))';
            elseif strcmp(myvar,'Ip_real') 
                temp_mytitle = 'Priv. Total Inv. (log(I_p))';
            elseif strcmp(myvar,'Yp_real')
                temp_mytitle = 'Priv. Output (log(Y_p))';
            else
                error('myVARspec not recognized');
            end
            eval(strcat('mytitle_',num2str(aaa),'=temp_mytitle;'));
        end        
        
        % set size of figure so it fills page
        set(gcf, 'PaperPositionMode', 'manual');
        set(gcf, 'PaperUnits', 'inches');
        set(gcf, 'PaperPosition', [0 0 14.00 7.00]);            
        %set(gcf, 'PaperPosition', [0 0 7.00 3.50]); % 1x2 plot

        %IRF_length_plot = std_IRF_length_qtr+1;
        % per May 18 2019 call with max, change length of IRF to 20 
        % periods when comparing data vs model
        IRF_length_plot = std_IRF_length_qtr+1;    

        % VARspec 1

            subplot(2,3,1); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_3var_qtr_1.oirf_var3(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_3var_qtr_1.oirf_var3_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_3var_qtr_1.oirf_var3_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);
            title(strcat('\fontsize{12}',mytitle_1),'FontWeight','normal');
            xlabel(' ');
            %ylabel(temp_MyVar_ylabel);               
            ylabel('Percent');               
            axis('tight');
            ylim(My_Ylims_c1);

            subplot(2,3,4); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_4var_qtr_1.oirf_var4(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_4var_qtr_1.oirf_var4_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_4var_qtr_1.oirf_var4_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);
            %title(strcat('\fontsize{12}',mytitle_1),'FontWeight','normal');
            xlabel('Quarters');
            %ylabel(temp_MyVar_ylabel);               
            ylabel('Percent');               
            axis('tight');
            ylim(My_Ylims_c1);

        % VARspec 2

            subplot(2,3,2); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_3var_qtr_2.oirf_var3(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_3var_qtr_2.oirf_var3_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_3var_qtr_2.oirf_var3_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);
            title(strcat('\fontsize{12}',mytitle_2),'FontWeight','normal');
            xlabel(' ');
            %ylabel(temp_MyVar_ylabel);               
            axis('tight');
            ylim(My_Ylims_c2);

            subplot(2,3,5); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_4var_qtr_2.oirf_var4(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_4var_qtr_2.oirf_var4_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_4var_qtr_2.oirf_var4_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);
            %title(strcat('\fontsize{12}',mytitle_1),'FontWeight','normal');
            xlabel('Quarters');
            %ylabel(temp_MyVar_ylabel);               
            axis('tight');  
            ylim(My_Ylims_c2);


        % VARspec 3

            subplot(2,3,3); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_3var_qtr_3.oirf_var3(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_3var_qtr_3.oirf_var3_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_3var_qtr_3.oirf_var3_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);
            title(strcat('\fontsize{12}',mytitle_3),'FontWeight','normal');
            xlabel(' ');
            %ylabel(temp_MyVar_ylabel);               
            axis('tight');
            ylim(My_Ylims_c3);

            subplot(2,3,6); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_4var_qtr_3.oirf_var4(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_4var_qtr_3.oirf_var4_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_4var_qtr_3.oirf_var4_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);
            %title(strcat('\fontsize{12}',mytitle_1),'FontWeight','normal');
            xlabel('Quarters');
            %ylabel(temp_MyVar_ylabel);               
            axis('tight');
            ylim(My_Ylims_c3);

        % add row labels

            myfig = gcf;

            annotation(myfig,'textbox',...
                [0.0265625 0.71496062992126 0.0515625 0.0840311679790023],...
                'String',{'3-variable','VAR','iVol'},...
                'LineStyle','none',...
                'HorizontalAlignment','center',...
                'FontWeight','bold',...
                'FontSize',12,...
                'FitBoxToText','off');    

            annotation(myfig,'textbox',...
                [0.0265625 0.21496062992126 0.0515625 0.0840311679790023],...
                'String',{'4-variable','VAR','PU'},...
                'LineStyle','none',...
                'HorizontalAlignment','center',...
                'FontWeight','bold',...
                'FontSize',12,...
                'FitBoxToText','off');          


        % save jpg        
        saveas(1,strcat('figures/',fname),'png')
        saveas(1,strcat('figures/',fname)) 
        %saveas(1,strcat('output_for_paper/Figures/',fname),'png')
        %saveas(1,strcat('output_for_paper/Figures/',fname))                     
        %close(1)                           

        
        
        
%% create 2x3 figure that shows tfp and vol shock IRFs from 4-variable VAR
%  using levels and from different starting years

clc;

%VAR_start_year = 1972
VAR_start_year_list = [1961, 1972, 1982];
sample_end_year = 2016

% cc control var
%ccvarlist = {'none'};
ccvarlist = {'baa10ym'};
%ccvarlist = {'none'; 'baa10ym';'aaa10ym'};
ccc = 1;
myccvar = char(ccvarlist{ccc});

% VAR specs for columns 1, 2, and 3
%VARspecs = {'levels','levels','levels'}; % 
VARspecs = {'levels'}; % 
VARorder = 1;
%VARorder = 2;

% varaibles
last_var_choice_list = {'IPPrnd_real'; 'Ip_real'; 'Yp_real'};
My_Ylims_c1 = [-2.0, 1.0];
My_Ylims_c2 = [-3.0, 4.0];    
My_Ylims_c3 = [-1.0, 1.2];

% loop across start years
for yyy = 1:length(VAR_start_year_list)

VAR_start_year = VAR_start_year_list(yyy);    

 % loop across last var choices
 for aaa = 1:length(last_var_choice_list)
    
    last_var_choice = char(last_var_choice_list{aaa});
    
    % compute IRFs for data VARs for 4-variable VAR
    %for vvv = 1:length(VARspecs)
    vvv=1;

        myVARspec = char(VARspecs{vvv});

        % figure out starting and ending positions
        %sample_start_year = 1961;
        %sample_end_year   = 2016;     
        if strcmp(myVARspec,'levels')
            pos_start_macro  = find((data_macro_qtr.year>=VAR_start_year),1,'first');  
            if VAR_start_year==1961   
                % add 1 because investment reg data starts in 1961q2
                pos_start_macro  = find((data_macro_qtr.year>=VAR_start_year),1,'first')+1;
            end
        else % need extra period for filtering        
            pos_start_macro = find((data_macro_qtr.year>=VAR_start_year),1,'first') - 1; 
        end    
        pos_end_macro   = find((data_macro_qtr.year<=sample_end_year),1,'last');
        % account for starting year
        if VAR_start_year==1961        
            temp_data_inv_reg_qtr = data_inv_reg_qtr_1961;
        else
            temp_data_inv_reg_qtr = data_inv_reg_qtr;
        end
        pos_start_invreg = find((temp_data_inv_reg_qtr.year>=VAR_start_year),1,'first');        
        pos_end_invreg   = find((temp_data_inv_reg_qtr.year<=sample_end_year),1,'last');  
        disp(char(strcat({'macro var data from '},num2str(data_macro_qtr.year(pos_start_macro)))));
        disp(char(strcat({'macro var data to '},  num2str(data_macro_qtr.year(pos_end_macro)))));
        disp(char(strcat({'inv reg data from '},num2str(temp_data_inv_reg_qtr.year(pos_start_invreg)))));
        disp(char(strcat({'inv reg data to '},num2str(temp_data_inv_reg_qtr.year(pos_end_invreg)))));

        % first three variables from investment regression
        if strcmp(myVARspec,'levels')
            var1 = data_macro_qtr.tfp( pos_start_macro:pos_end_macro); % tfp in levels
        else
            var1 = data_macro_qtr.dtfp( pos_start_macro+1:pos_end_macro)/4; % dtfp from macro data. need to convert back to quarterly rates from annualized rate
        end
        var2 = temp_data_inv_reg_qtr.x( pos_start_invreg:pos_end_invreg);
        var3 = temp_data_inv_reg_qtr.expvol( pos_start_invreg:pos_end_invreg);

        % 4th variable that may be filtered depending myVARspec
        eval(strcat('var4_raw = data_macro_qtr.',last_var_choice,';'));
        var4_trunc = var4_raw(pos_start_macro:pos_end_macro); % truncated series to match other series
        if strcmp(myVARspec,'levels') % simply compute in log levels
            temp_var4_qtr = log(var4_trunc); 
        else % de-trend 4th variable 

            temp_var4_qtr = nan(size(var4_trunc));

            % HP filter. use pos_start+1 because no need to take first differences
            if strcmp(myVARspec,'hpfilter')            
                raw_var4_qtr     = log(var4_trunc(2:end));
                smooth_var4_qtr  = hpfilter(raw_var4_qtr, 1600); % quarterly data smoothing 
                temp_var4_qtr    = raw_var4_qtr - smooth_var4_qtr;
            end   

            % Comin Gertler (2006) band-pass
            % The function is bandpass(X,pl,pu). X is the raw data, pl and pu is the range of frequencies we want to extract. 
            % Recommended by Comin and Gertler (attached below), we should choose pl = 2 and pu = 200 for the quarterly data 
            % to extract the medium-term cycles. 
            if strcmp(myVARspec,'bandpass')  
                size(var4_trunc);
                raw_var4_qtr = log(var4_trunc(2:end)); % no reduction in size from bandpass --> need to cut first obs for VAR
                temp_var4_qtr = bandpass(raw_var4_qtr, 2, 200);
                size(temp_var4_qtr); % no reduction in size from bandpass                                
            end  

        end

        % series to enter VAR in levels 
        if strcmp(last_var_choice,'Ig_Itot') ...
        || strcmp(last_var_choice,'Ip_Itot') ...
        || strcmp(last_var_choice,'Ig_Y') ...
        || strcmp(last_var_choice,'labor_share_govt') ...
        || strcmp(last_var_choice,'labor_share_priv') ...
        || strcmp(last_var_choice,'itot_y') ...
        || strcmp(last_var_choice,'ip_y') ...
        || strcmp(last_var_choice,'sp_y') ...
        || strcmp(last_var_choice,'priv_saving_to_gdp') 
            var4 = exp(temp_var4_qtr);
        else
            var4 = temp_var4_qtr; % keep in logs
        end    

        % endogenous vars matrix
        temp_y_qtr = [var1, var2, var3, var4];

        % exogenous vars matrix
        temp_x_qtr = ones(size(temp_y_qtr,1),1);
        if ~strcmp(myccvar, 'none')
            eval(strcat('ccvar_raw_qtr = data_macro_qtr.',myccvar,';'));
            if strcmp(myVARspec,'levels') 
                temp_ccvar_qtr = ccvar_raw_qtr(pos_start_macro:pos_end_macro);
            else
                temp_ccvar_qtr = ccvar_raw_qtr(pos_start_macro+1:pos_end_macro);
            end
            temp_x_qtr = [temp_x_qtr, temp_ccvar_qtr];        
        end      

        % define different shock matrices

            std_IRF_length_qtr = 24;

            % 1-std dtfp shock
            std_dtfp_shk_mat_qtr      = zeros(4 , std_IRF_length_qtr);
            std_dtfp_shk_mat_qtr(1,1) = 1;            

            % 1-std ivol shock
            std_ivol_shk_mat_qtr      = zeros(4 , std_IRF_length_qtr);
            std_ivol_shk_mat_qtr(3,1) = 1;             

            % compute IRFs for ivol shk
            if VARorder==1 
                temp_IRFOUT_tfp = gen_IRF_vectors_dataVAR_nvars( temp_y_qtr, temp_x_qtr, [], std_dtfp_shk_mat_qtr, 0);
                temp_IRFOUT_vol = gen_IRF_vectors_dataVAR_nvars( temp_y_qtr, temp_x_qtr, [], std_ivol_shk_mat_qtr, 0);
            elseif VARorder==2
                temp_IRFOUT_tfp = gen_IRF_vectors_dataVAR2_nvars( temp_y_qtr, temp_x_qtr, [], std_ivol_shk_mat_qtr, 0);
                temp_IRFOUT_vol = gen_IRF_vectors_dataVAR2_nvars( temp_y_qtr, temp_x_qtr, [], std_dtfp_shk_mat_qtr, 0);
            else
                error('VARorder not specified');
            end
            %eval(strcat('IRFout_ivolshk_4var_qtr_',num2str(vvv),' = temp_IRFOUT;'));
            eval(strcat('IRFout_dtfpshk_4var_qtr_',num2str(aaa),' = temp_IRFOUT_tfp;'));
            eval(strcat('IRFout_ivolshk_4var_qtr_',num2str(aaa),' = temp_IRFOUT_vol;'));

        % clean up
        clear var4_raw_qtr var4_trunc temp_var4_qtr temp_y_qtr temp_x_qtr

    %end % vvv myVARspec list

 end % aaa last_var_choice_list    


    % create the 2x3 figure
    close ALL
    figure(1);

        %fname = strcat('IRFs_OnlyVol_VAR',num2str(VARorder),'_sample_startyr_',num2str(VAR_start_year),'_to_',num2str(sample_end_year),'_3var_qtr_or_4var_qtr_',last_var_choice,'_control_',myccvar,'_2x3_',char(last_var_choice_list{1}),'_and_',char(last_var_choice_list{2}),'_and_',char(last_var_choice_list{3}));    
        fname = strcat('IRFs_VAR',num2str(VARorder),'_sample_startyr_',num2str(VAR_start_year),'_to_',num2str(sample_end_year),'_4var_qtr_resp_tfpshk_or_volshk_',last_var_choice,'_control_',myccvar,'_2x3_',char(last_var_choice_list{1}),'_and_',char(last_var_choice_list{2}),'_and_',char(last_var_choice_list{3}));    

        % y label
        temp_MyVar_ylabel = texlabel('Percent');
        if strcmp(last_var_choice,'Yp_real')
            temp_MyVar_ylabel = texlabel('log(Y_p)');
        end    

        % panel titles
%         for vvv = 1:length(VARspecs)
%             myVARspec = char(VARspecs{vvv});    
%             if strcmp(myVARspec,'hpfilter')
%                 temp_mytitle = 'Business Cycle';
%             elseif strcmp(myVARspec,'bandpass') 
%                 temp_mytitle = 'Medium Cycle';
%             elseif strcmp(myVARspec,'levels')
%                 temp_mytitle = 'VAR in Levels';
%             else
%                 error('myVARspec not recognized');
%             end
%             eval(strcat('mytitle_',num2str(vvv),'=temp_mytitle;'));
%         end
        for aaa = 1:length(last_var_choice_list)
            myvar = char(last_var_choice_list{aaa});    
            if strcmp(myvar,'IPPrnd_real')
                temp_mytitle = 'Priv. R&D Inv. (log(I_R_&_D))';
            elseif strcmp(myvar,'Ip_real') 
                temp_mytitle = 'Priv. Total Inv. (log(I_p))';
            elseif strcmp(myvar,'Yp_real')
                temp_mytitle = 'Priv. Output (log(Y_p))';
            else
                error('myVARspec not recognized');
            end
            eval(strcat('mytitle_',num2str(aaa),'=temp_mytitle;'));
        end        
        
        % set size of figure so it fills page
        set(gcf, 'PaperPositionMode', 'manual');
        set(gcf, 'PaperUnits', 'inches');
        set(gcf, 'PaperPosition', [0 0 14.00 7.00]);            
        %set(gcf, 'PaperPosition', [0 0 7.00 3.50]); % 1x2 plot

        %IRF_length_plot = std_IRF_length_qtr+1;
        % per May 18 2019 call with max, change length of IRF to 20 
        % periods when comparing data vs model
        IRF_length_plot = std_IRF_length_qtr+1;    

        % VARspec 1

            subplot(2,3,1); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_dtfpshk_4var_qtr_1.oirf_var4(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_dtfpshk_4var_qtr_1.oirf_var4_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_dtfpshk_4var_qtr_1.oirf_var4_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);
            title(strcat('\fontsize{12}',mytitle_1),'FontWeight','normal');
            xlabel(' ');
            %ylabel(temp_MyVar_ylabel);               
            ylabel('Percent');               
            axis('tight');
            ylim(My_Ylims_c1);

            subplot(2,3,4); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_4var_qtr_1.oirf_var4(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_4var_qtr_1.oirf_var4_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_4var_qtr_1.oirf_var4_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);
            %title(strcat('\fontsize{12}',mytitle_1),'FontWeight','normal');
            xlabel('Quarters');
            %ylabel(temp_MyVar_ylabel);               
            ylabel('Percent');               
            axis('tight');
            ylim(My_Ylims_c1);

        % VARspec 2

            subplot(2,3,2); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_dtfpshk_4var_qtr_2.oirf_var4(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_dtfpshk_4var_qtr_2.oirf_var4_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_dtfpshk_4var_qtr_2.oirf_var4_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);
            title(strcat('\fontsize{12}',mytitle_2),'FontWeight','normal');
            xlabel(' ');
            %ylabel(temp_MyVar_ylabel);               
            axis('tight');
            ylim(My_Ylims_c2);

            subplot(2,3,5); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_4var_qtr_2.oirf_var4(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_4var_qtr_2.oirf_var4_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_4var_qtr_2.oirf_var4_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);
            %title(strcat('\fontsize{12}',mytitle_1),'FontWeight','normal');
            xlabel('Quarters');
            %ylabel(temp_MyVar_ylabel);               
            axis('tight');  
            ylim(My_Ylims_c2);


        % VARspec 3

            subplot(2,3,3); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_dtfpshk_4var_qtr_3.oirf_var4(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_dtfpshk_4var_qtr_3.oirf_var4_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_dtfpshk_4var_qtr_3.oirf_var4_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);
            title(strcat('\fontsize{12}',mytitle_3),'FontWeight','normal');
            xlabel(' ');
            %ylabel(temp_MyVar_ylabel);               
            axis('tight');
            ylim(My_Ylims_c3);

            subplot(2,3,6); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_4var_qtr_3.oirf_var4(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_4var_qtr_3.oirf_var4_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_4var_qtr_3.oirf_var4_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);
            %title(strcat('\fontsize{12}',mytitle_1),'FontWeight','normal');
            xlabel('Quarters');
            %ylabel(temp_MyVar_ylabel);               
            axis('tight');
            ylim(My_Ylims_c3);

        % add row labels

            myfig = gcf;

            annotation(myfig,'textbox',...
                [0.0265625 0.71496062992126 0.0515625 0.0840311679790023],...
                'String',{'Productivity','Shock'},...
                'LineStyle','none',...
                'HorizontalAlignment','center',...
                'FontWeight','bold',...
                'FontSize',12,...
                'FitBoxToText','off');    

            annotation(myfig,'textbox',...
                [0.0265625 0.21496062992126 0.0515625 0.0840311679790023],...
                'String',{'Volatility','Shock'},...
                'LineStyle','none',...
                'HorizontalAlignment','center',...
                'FontWeight','bold',...
                'FontSize',12,...
                'FitBoxToText','off');          


        % save jpg        
        saveas(1,strcat('figures/',fname),'png')
        saveas(1,strcat('figures/',fname)) 
        %saveas(1,strcat('output_for_paper/Figures/',fname),'png')
        %saveas(1,strcat('output_for_paper/Figures/',fname))                     
        %close(1)                           

end % yyy start year
        




%% 2x4 figure that compares model vs 4-variable data VAR for a
%  set of var4 choices. label figure with H and L b/c govt not revealed
%  and also hide data lines for L-based panels

clc;

% panel titles option
% option for panel titles to use H and L
alt_panel_titles= 1;

%ccvarlist = {'none'};
ccvarlist = {'baa10ym'};
%ccvarlist = {'none'; 'baa10ym';'aaa10ym'};

% var4 set
var_set = {'Ig_Y';'IPPrnd_real';'Ip_real';'labor_share_govt';'Yp_real'}; 
% m unlev_ret51 lev_ret51
var_set = {'m'; 'Ig_Y'; 'IPPrnd_real'; 'Ip_real'; 'lev_ret51'; 'labor_share_govt'; 'labor_priv'; 'Yp_real'}; 
%var_set = {'IPPrnd_real'; 'Ig_Y'; 'Itot_real'; 'Ip_real'; 'Ig_real'; 'labor_share_govt'; 'labor_priv'; 'Yp_real'}; 
My_Ylims_c1 = [-20.0, 20.0];
My_Ylims_c2 = [-2.0, 2.0];
My_Ylims_c3 = [-2.0, 2.0];
My_Ylims_c4 = [-2.0, 2.0];
My_Ylims_c5 = [-3.0, 3.0];
My_Ylims_c6 = [-1.0, 1.0];    
My_Ylims_c7 = [-1.0, 1.0];    
My_Ylims_c8 = [-1.0, 1.0];    

% focus on labor set
% var_set = {'labor_share_govt';'labor_share_priv';'Yp_real';'labor_govt';'labor_priv'}; 
% My_Ylims_c1 = [-1.0, 1.0];
% My_Ylims_c2 = [-1.0, 1.0];
% My_Ylims_c3 = [-1.0, 1.0];
% My_Ylims_c4 = [-1.0, 1.0];    
% My_Ylims_c5 = [-1.0, 1.0];  

% modnum choice
%my_modnum = 3;
%my_modnum = 51;
%my_modnum = 54;
%my_modnum = 64;
%my_modnum = 71; 
my_modnum = 81; % benchmark
%my_modnum = 93; % potential alternate benchmark
%my_modnum = 94; % potential alternate benchmark
%my_modnum = 96; % potential alternate benchmark
%my_modnum = 97; % potential alternate benchmark
%my_modnum = 105;
%my_modnum = 801;
%my_modnum = 78; % benchmark but lower Ig/Y by increasing deltac
%my_modnum = 82; % EGI 
%my_modnum = 79; % EGI but lower Ig/Y by lowering IcYratio

% VAR specs choice
%myVARspec = 'hpfilter';
myVARspec = 'bandpass';
%myVARspec = 'levels';

for ccc = 1:length(ccvarlist)
  
 % cc control var
 myccvar = char(ccvarlist{ccc});
    
 % compute IRFs for different var4 choices
 for vvv = 1:length(var_set)
     
    %myVARspec = char(VARspecs{vvv});
    var4_choice = var_set{vvv};
     
    % figure out starting and ending positions
    sample_start_year = 1972;
    sample_end_year   = 2016;    
    if strcmp(myVARspec,'levels') 
        pos_start_macro  = find((data_macro_qtr.year>=sample_start_year),1,'first');     
    else % need extra period for filtering        
        pos_start_macro = find((data_macro_qtr.year>=sample_start_year),1,'first') - 1; 
    end    
    pos_end_macro   = find((data_macro_qtr.year<=sample_end_year),1,'last');
    pos_start_hml   = find((data_hml_qtr.year>=sample_start_year),1,'first');     
    pos_end_hml     = find((data_hml_qtr.year<=sample_end_year),1,'last');
    pos_start_invreg = find((data_inv_reg_qtr.year>=sample_start_year),1,'first');        
    pos_end_invreg   = find((data_inv_reg_qtr.year<=sample_end_year),1,'last');  
    disp(char(strcat({'macro var data from '},num2str(data_macro_qtr.year(pos_start_macro)),'q',num2str(data_macro_qtr.qtr(pos_start_macro)))))
    disp(char(strcat({'macro var data to '},  num2str(data_macro_qtr.year(pos_end_macro)),  'q',num2str(data_macro_qtr.qtr(pos_end_macro)))))
    disp(char(strcat({'inv reg data from '},num2str(data_inv_reg_qtr.year(pos_start_invreg)),'q',num2str(data_inv_reg_qtr.qtr(pos_start_invreg)))))
    disp(char(strcat({'inv reg data to '},num2str(data_inv_reg_qtr.year(pos_end_invreg)),'q',num2str(data_inv_reg_qtr.qtr(pos_end_invreg)))))    
    
    % first three variables from investment regression
    if  strcmp(var4_choice,'unlev_ret51') ...
      | strcmp(var4_choice,'lev_ret51') ...
      | strcmp(var4_choice,'unlev_ret5') ...
      | strcmp(var4_choice,'lev_ret5') ...
      | strcmp(var4_choice,'unlev_ret1') ...
      | strcmp(var4_choice,'lev_ret1') ...      
      | strcmp(var4_choice,'m')  
        if strcmp(myVARspec,'levels')
            var1 = data_macro_qtr.dtfp( pos_start_macro:pos_end_macro)/4; % must use dtfp b/c the above vars are not stationary
        else
            var1 = data_macro_qtr.dtfp( pos_start_macro+1:pos_end_macro)/4; % dtfp from macro data. need to convert back to quarterly rates from annualized rate
        end
    elseif strcmp(myVARspec,'levels')
        var1 = data_macro_qtr.tfp( pos_start_macro:pos_end_macro); % tfp in levels       
    else
        var1 = data_macro_qtr.dtfp( pos_start_macro+1:pos_end_macro)/4; % dtfp from macro data. need to convert back to quarterly rates from annualized rate
        %var1_chk = data_inv_reg_qtr.dtfp( pos_start_invreg:pos_end_invreg); % dtfp from inv reg data
        %chk_diff = abs(var1 - var1_chk);
        %max(chk_diff)
        %[var1, var1_chk]
    end
    var2 = data_inv_reg_qtr.x( pos_start_invreg:pos_end_invreg);
    var3 = data_inv_reg_qtr.expvol( pos_start_invreg:pos_end_invreg);
    
    % 4th variable that may be filtered depending myVARspec
    %eval(strcat('var4_raw_qtr = data_macro_qtr.',var4_choice,';'));
    %var4_trunc = var4_raw_qtr(pos_start_macro:pos_end_macro); % truncated series to match other series
    if  strcmp(var4_choice,'unlev_ret51') ...
      | strcmp(var4_choice,'lev_ret51') ...
      | strcmp(var4_choice,'unlev_ret5') ...
      | strcmp(var4_choice,'lev_ret5') ... 
      | strcmp(var4_choice,'unlev_ret1') ...
      | strcmp(var4_choice,'lev_ret1') ...       
      | strcmp(var4_choice,'m') 
        eval(strcat('var4_raw_qtr = data_hml_qtr.',var4_choice,';'));
        var4_trunc = var4_raw_qtr(pos_start_hml:pos_end_hml); % truncated series to match other series        
        temp_var4_qtr = var4_trunc; % truncated series to match other series        
    else
        eval(strcat('var4_raw_qtr = data_macro_qtr.',var4_choice,';'));
        var4_trunc = var4_raw_qtr(pos_start_macro:pos_end_macro); % truncated series to match other series
        if strcmp(myVARspec,'levels') % simply compute in log levels
            temp_var4_qtr = log(var4_trunc); 
        else % de-trend 4th variable 

            temp_var4_qtr = nan(size(var4_trunc));

            % HP filter. use pos_start+1 because no need to take first differences
            if strcmp(myVARspec,'hpfilter')            
                raw_var4_qtr     = log(var4_trunc(2:end));
                smooth_var4_qtr  = hpfilter(raw_var4_qtr, 1600); % quarterly data smoothing 
                temp_var4_qtr    = raw_var4_qtr - smooth_var4_qtr;
            end   

            % Comin Gertler (2006) band-pass
            % The function is bandpass(X,pl,pu). X is the raw data, pl and pu is the range of frequencies we want to extract. 
            % Recommended by Comin and Gertler (attached below), we should choose pl = 2 and pu = 200 for the quarterly data 
            % to extract the medium-term cycles. 
            if strcmp(myVARspec,'bandpass')  
                size(var4_trunc);
                raw_var4_qtr = log(var4_trunc(2:end)); % no reduction in size from bandpass --> need to cut first obs for VAR
                temp_var4_qtr = bandpass(raw_var4_qtr, 2, 200);
                size(temp_var4_qtr); % no reduction in size from bandpass                                
            end  

        end
    end
        
    % series to enter VAR in levels 
    if strcmp(var4_choice,'Ig_Itot') ...
    || strcmp(var4_choice,'Ip_Itot') ...
    || strcmp(var4_choice,'Ig_Y') ...
    || strcmp(var4_choice,'labor_share_govt') ...
    || strcmp(var4_choice,'labor_share_priv') 
        var4 = exp(temp_var4_qtr);
    else
        var4 = temp_var4_qtr; % keep in logs
    end    
    
    % endogenous vars matrix
    temp_y_qtr = [var1, var2, var3, var4];
 
    % exogenous vars matrix
    temp_x_qtr = ones(size(temp_y_qtr,1),1);
    if ~strcmp(myccvar, 'none')
        eval(strcat('ccvar_raw_qtr = data_macro_qtr.',myccvar,';'));
        if strcmp(myVARspec,'levels') & temp_var4_qtr~=var4_trunc
            temp_ccvar_qtr = ccvar_raw_qtr(pos_start_macro:pos_end_macro);
        else
            temp_ccvar_qtr = ccvar_raw_qtr(pos_start_macro+1:pos_end_macro);
        end
        temp_x_qtr = [temp_x_qtr, temp_ccvar_qtr];        
    end      

    eval(strcat('y_qtr_',num2str(vvv),' = temp_y_qtr;'));
    eval(strcat('x_exo_qtr_',num2str(vvv),' = temp_x_qtr;'));

    clear var4_raw_qtr var4_trunc temp_var4_qtr temp_y_qtr temp_x_qtr

    % define different shock matrices

        std_IRF_length_qtr = 24;

        % 1-std dtfp shock
        std_dtfp_shk_mat_qtr      = zeros(4 , std_IRF_length_qtr);
        std_dtfp_shk_mat_qtr(1,1) = 1;            

        % 1-std ivol shock
        std_ivol_shk_mat_qtr      = zeros(4 , std_IRF_length_qtr);
        std_ivol_shk_mat_qtr(3,1) = 1;             

        % compute IRFs for ivol shk
        eval(strcat('IRFout_ivolshk_qtr_',num2str(vvv),' = gen_IRF_vectors_dataVAR_nvars( y_qtr_',num2str(vvv),', x_exo_qtr_',num2str(vvv),', [], std_ivol_shk_mat_qtr, 0);'));
        eval(strcat('IRFout_dtfpshk_qtr_',num2str(vvv),' = gen_IRF_vectors_dataVAR_nvars( y_qtr_',num2str(vvv),', x_exo_qtr_',num2str(vvv),', [], std_dtfp_shk_mat_qtr, 0);'));

 end % vvv var4 list

 % generate IRF vectors from the model

    %my_modnum = modnumlist(mmm);

    % single unit impulse to exp(vol)

        std_IRF_length_qtr = 24;

        % std volatility level shock
        vol_shk_lev_mat_qtr      = zeros(2 , std_IRF_length_qtr);
        vol_shk_lev_mat_qtr(2,1) = log( std(data_inv_reg_qtr.expvol)+1 ); % log shock val to get 1-std dev in level of vol
        % NOTE: ex removed as shock in BCLR EndoGrowth

        % std tfp shock. note that TFP growth in the data VAR is in log
        % units according to Wenxi
        tfp_val_shk_mat_qtr      = zeros(2 , std_IRF_length_qtr);
        tfp_val_shk_mat_qtr(1,1) = std(data_inv_reg_qtr.dtfp); % shock val to log TFP growth

        disp(char(strcat({'Computing IRFs for model '},num2str(my_modnum),{'...'})));

        % compute irfs for 1-unit vol shock and 1-unit tfp shock

            model_IRFout_1unit_vol_qtr = gen_IRF_vectors_model( my_modnum, [], [], 'lev', vol_shk_lev_mat_qtr);
            model_IRFout_1unit_tfp_qtr = gen_IRF_vectors_model( my_modnum, [], [], 'lev', tfp_val_shk_mat_qtr);
            
         % save IRF vectors
         for vvv = 1:length(var_set)    
            var4_choice = var_set{vvv} ;
            if strcmp(var4_choice,'Yp_real')
                temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_logYp;
                temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_logYp;                                                            
            elseif strcmp(var4_choice,'Ig_Itot')
                temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_Ig_Itot;
                temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_Ig_Itot;                                           
            elseif strcmp(var4_choice,'Ip_Itot')
                temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_Ip_Itot;
                temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_Ip_Itot;            
            elseif strcmp(var4_choice,'Ig_Y')
                temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_Ig_Y;
                temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_Ig_Y;       
            elseif strcmp(var4_choice,'IPPrnd_real')
                temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_logIPPrnd;
                temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_logIPPrnd;            
            elseif strcmp(var4_choice,'Ig_real')
                temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_logIg;
                temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_logIg;                        
            elseif strcmp(var4_choice,'Ip_real')
                %temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_logIp;
                %temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_logIp;      
                temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_logIptot;
                temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_logIptot;                      
            elseif strcmp(var4_choice,'Itot_real')
                temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_logItot;
                temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_logItot;                 
            elseif strcmp(var4_choice,'labor_share_govt')
                temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_ncnt;
                temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_ncnt;          
            elseif strcmp(var4_choice,'labor_share_priv')
                temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_npnt;
                temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_npnt;                 
            elseif strcmp(var4_choice,'labor_govt')
                temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_nc; % already in logs
                temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_nc; % already in logs
            elseif strcmp(var4_choice,'labor_priv')
                temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_np; % already in logs
                temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_np; % already in logs
            elseif strcmp(var4_choice,'lev_ret51')
                temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_lev_ret51;
                temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_lev_ret51;                 
            elseif strcmp(var4_choice,'unlev_ret51')
                temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_unlev_ret51;
                temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_unlev_ret51; 
            elseif strcmp(var4_choice,'lev_ret5')
                temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_lev_ret5;
                temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_lev_ret5;                 
            elseif strcmp(var4_choice,'unlev_ret5')
                temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_unlev_ret5;
                temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_unlev_ret5;   
            elseif strcmp(var4_choice,'lev_ret1')
                temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_lev_ret1;
                temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_lev_ret1;                 
            elseif strcmp(var4_choice,'unlev_ret1')
                temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_unlev_ret1;
                temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_unlev_ret1;                   
            elseif strcmp(var4_choice,'m')
                temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_m;
                temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_m;                   
            else
                error('var4_choice not recognized');
            end
            
            eval(strcat('model_IRF_vol_line_',num2str(vvv),' = temp_model_IRF_vol_line;'));
            eval(strcat('model_IRF_tfp_line_',num2str(vvv),' = temp_model_IRF_tfp_line;'));
         end % vvv
            
        disp(char(strcat({'Done computing model IRFs!'})));
 

        
        
        
        
% create the 2x4 figure
close ALL
figure(1);

    if alt_panel_titles==1
        fname = strcat('IRFs_OnlyVol_data_',myVARspec,'_control_',myccvar,'_vs_model_alt_panel_titles_',num2str(my_modnum),'_2x4_',char(var_set{1}),'_',char(var_set{2}),'_',char(var_set{3}),'_',char(var_set{4}),'_',char(var_set{5}),'_',char(var_set{6}),'_',char(var_set{7}),'_',char(var_set{8}));    
    else
        fname = strcat('IRFs_OnlyVol_data_',myVARspec,'_control_',myccvar,'_vs_model_',num2str(my_modnum),'_2x4_',char(var_set{1}),'_',char(var_set{2}),'_',char(var_set{3}),'_',char(var_set{4}),'_',char(var_set{5}),'_',char(var_set{6}),'_',char(var_set{7}),'_',char(var_set{8}));    
    end

    % panel titles
    for vvv = 1:length(var_set)    
        
        var4_choice = var_set{vvv}; 
        
        if alt_panel_titles==1 
            if strcmp(var4_choice,'Yp_real')
                temp_MyVar_title = 'log(Y_H)';
            elseif strcmp(var4_choice,'Ig_Y')
                temp_MyVar_title = 'I_L / Y';
            elseif strcmp(var4_choice,'Ig_real')
                temp_MyVar_title = 'log(I_L)';
            elseif strcmp(var4_choice,'Ip_real')
                %temp_MyVar_title = 'log(I_H)';
                temp_MyVar_title = 'log(I_H+I_R_&_D)';
            elseif strcmp(var4_choice,'Itot_real')
                temp_MyVar_title = 'log(I_L+I_H+I_R_&_D)';                
            elseif strcmp(var4_choice,'IPPrnd_real')
                temp_MyVar_title = 'log(I_R_&_D)';
            elseif strcmp(var4_choice,'labor_share_govt')
                temp_MyVar_title = 'L_L / (L_L + L_H))';            
            elseif strcmp(var4_choice,'labor_share_priv')
                temp_MyVar_title = 'L_H / (L_L + L_H)';
            elseif strcmp(var4_choice,'labor_govt')
                temp_MyVar_title = 'log(L_L)';            
            elseif strcmp(var4_choice,'labor_priv')
                temp_MyVar_title = 'log(L_H)'; 
            elseif strcmp(var4_choice,'unlev_ret51')
                temp_MyVar_title = texlabel('R^u^n^l^e^v_H_M_L');   
            elseif strcmp(var4_choice,'lev_ret51')
                temp_MyVar_title = texlabel('R^l^e^v_H_M_L');   
            elseif strcmp(var4_choice,'unlev_ret5')
                temp_MyVar_title = texlabel('R^u^n^l^e^v_H');   
            elseif strcmp(var4_choice,'lev_ret5')
                temp_MyVar_title = texlabel('R^l^e^v_H');  
            elseif strcmp(var4_choice,'unlev_ret1')
                temp_MyVar_title = texlabel('R^u^n^l^e^v_L');   
            elseif strcmp(var4_choice,'lev_ret1')
                temp_MyVar_title = texlabel('R^l^e^v_L');                  
            elseif strcmp(var4_choice,'m')
                temp_MyVar_title = texlabel('log(M)');                  
            else
                error('var4_choice not recognized');        
            end              
        else
            if strcmp(var4_choice,'Yp_real')
                temp_MyVar_title = 'Priv. Output (log(Y_p))';
            elseif strcmp(var4_choice,'Ig_Itot')
                temp_MyVar_title = 'Govt. to Total Inv. (I_g / (I_g + I_p))';
            elseif strcmp(var4_choice,'Ip_Itot')
                temp_MyVar_title = 'Priv. to Total Inv. (I_p / (I_g + I_p))';
            elseif strcmp(var4_choice,'Ig_Y')
                temp_MyVar_title = 'Govt. to GDP (I_g / Y)';
            elseif strcmp(var4_choice,'Ig_real')
                temp_MyVar_title = 'Govt. Inv. (log(I_g))';
            elseif strcmp(var4_choice,'Ip_real')
                temp_MyVar_title = 'Priv. Total Inv. (log(I_p))';
            elseif strcmp(var4_choice,'IPPrnd_real')
                temp_MyVar_title = 'Priv. R&D Inv. (log(I_R_&_D))';
            elseif strcmp(var4_choice,'labor_share_govt')
                temp_MyVar_title = 'Govt. Labor Share (L_g / (L_g + L_p))';            
            elseif strcmp(var4_choice,'labor_share_priv')
                temp_MyVar_title = 'Private Labor Share (L_p / (L_g + L_p))';              
            elseif strcmp(var4_choice,'labor_govt')
                temp_MyVar_title = 'Govt. Labor (log(L_g))';            
            elseif strcmp(var4_choice,'labor_priv')
                temp_MyVar_title = 'Private Labor (log(L_p))';                          
            else
                error('var4_choice not recognized');        
            end    
        end
        
        eval(strcat('mytitle_',num2str(vvv),'=temp_MyVar_title;'));
        
    end % vvv

    % set size of figure so it fills page
    set(gcf, 'PaperPositionMode', 'manual');
    set(gcf, 'PaperUnits', 'inches');
    set(gcf, 'PaperPosition', [0 0 14.00 7.00]);            
    %set(gcf, 'PaperPosition', [0 0 7.00 3.50]); % 1x2 plot

    %IRF_length_plot = std_IRF_length_qtr+1;
    % per May 18 2019 call with max, change length of IRF to 20 
    % periods when comparing data vs model
    IRF_length_plot = std_IRF_length_qtr+1-4;    

    subplot(2,4,1); hold on; box on;
    plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
    %plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_1.oirf_var4(1:IRF_length_plot), '-b', 'Linewidth', 2);
        %plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_1.oirf_var4_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
        %plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_1.oirf_var4_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);
    plot(0:IRF_length_plot-1, 100*model_IRF_vol_line_1(1:IRF_length_plot), ':r', 'Linewidth', 3);
    title(strcat('\fontsize{12}',mytitle_1),'FontWeight','normal');
    xlabel(' ');
    ylabel('Percent');               
    axis('tight');
    ylim(My_Ylims_c1);
          
    subplot(2,4,2); hold on; box on;
    plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
    %plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_2.oirf_var4(1:IRF_length_plot), '-b', 'Linewidth', 2);
    %    plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_2.oirf_var4_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
    %    plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_2.oirf_var4_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);
    plot(0:IRF_length_plot-1, 100*model_IRF_vol_line_2(1:IRF_length_plot), ':r', 'Linewidth', 3);
    title(strcat('\fontsize{12}',mytitle_2),'FontWeight','normal');
    xlabel(' ');
    %ylabel(temp_MyVar_ylabel);               
    axis('tight');
    ylim(My_Ylims_c2);

    subplot(2,4,3); hold on; box on;
    plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
    h(1) = plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_3.oirf_var4(1:IRF_length_plot), '-b', 'Linewidth', 2);
        plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_3.oirf_var4_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
        plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_3.oirf_var4_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);
    h(2) = plot(0:IRF_length_plot-1, 100*model_IRF_vol_line_3(1:IRF_length_plot), ':r', 'Linewidth', 3);
    title(strcat('\fontsize{12}',mytitle_3),'FontWeight','normal');
    xlabel(' ');
    %ylabel(temp_MyVar_ylabel);               
    axis('tight');
    ylim(My_Ylims_c3);                  
    %legend(h,'Data','Model','Location','northeast');
    clear h;

    subplot(2,4,4); hold on; box on;
    plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
    h(1) = plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_4.oirf_var4(1:IRF_length_plot), '-b', 'Linewidth', 2);
        plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_4.oirf_var4_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
        plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_4.oirf_var4_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);
    h(2) = plot(0:IRF_length_plot-1, 100*model_IRF_vol_line_4(1:IRF_length_plot), ':r', 'Linewidth', 3);
    title(strcat('\fontsize{12}',mytitle_4),'FontWeight','normal');
    xlabel(' ');                  
    axis('tight');
    ylim(My_Ylims_c4);
    legend(h,'Data','Model','Location','northeast');
    clear h;    
    
    subplot(2,4,5); hold on; box on;
    plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
    h(1) = plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_5.oirf_var4(1:IRF_length_plot), '-b', 'Linewidth', 2);
        plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_5.oirf_var4_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
        plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_5.oirf_var4_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);
    h(2) = plot(0:IRF_length_plot-1, 100*model_IRF_vol_line_5(1:IRF_length_plot), ':r', 'Linewidth', 3);
    title(strcat('\fontsize{12}',mytitle_5),'FontWeight','normal');
    xlabel(' ');
    %ylabel(temp_MyVar_ylabel);     
    ylabel('Percent'); 
    axis('tight');
    ylim(My_Ylims_c5);   
    %legend(h,'Data','Model','FontSize',14,'Position',[0.75 0.25 0.08 0.1]);
    clear h;
    
    subplot(2,4,6); hold on; box on;
    plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
    %h(1) = plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_6.oirf_var4(1:IRF_length_plot), '-b', 'Linewidth', 2);
    %    plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_6.oirf_var4_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
    %    plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_6.oirf_var4_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);
    h(2) = plot(0:IRF_length_plot-1, 100*model_IRF_vol_line_6(1:IRF_length_plot), ':r', 'Linewidth', 3);
    title(strcat('\fontsize{12}',mytitle_6),'FontWeight','normal');
    xlabel(' ');
    %ylabel(temp_MyVar_ylabel);               
    axis('tight');
    ylim(My_Ylims_c6);       
    
    subplot(2,4,7); hold on; box on;
    plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
    h(1) = plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_7.oirf_var4(1:IRF_length_plot), '-b', 'Linewidth', 2);
        plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_7.oirf_var4_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
        plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_7.oirf_var4_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);
    h(2) = plot(0:IRF_length_plot-1, 100*model_IRF_vol_line_7(1:IRF_length_plot), ':r', 'Linewidth', 3);
    title(strcat('\fontsize{12}',mytitle_7),'FontWeight','normal');
    xlabel(' ');
    %ylabel(temp_MyVar_ylabel);               
    axis('tight');
    ylim(My_Ylims_c7);   
    %legend(h,'Data','Model','FontSize',14,'Position',[0.75 0.25 0.08 0.1]);
    clear h;
    
    subplot(2,4,8); hold on; box on;
    plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
    h(1) = plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_8.oirf_var4(1:IRF_length_plot), '-b', 'Linewidth', 2);
        plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_8.oirf_var4_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
        plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_8.oirf_var4_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);
    h(2) = plot(0:IRF_length_plot-1, 100*model_IRF_vol_line_8(1:IRF_length_plot), ':r', 'Linewidth', 3);
    title(strcat('\fontsize{12}',mytitle_8),'FontWeight','normal');
    xlabel(' ');
    %ylabel(temp_MyVar_ylabel);               
    axis('tight');
    ylim(My_Ylims_c8);      
    
    % save jpg        
    saveas(1,strcat('figures/',fname),'png')
    saveas(1,strcat('figures/',fname)) 
    %saveas(1,strcat('output_for_paper/Figures/',fname),'png')
    %saveas(1,strcat('output_for_paper/Figures/',fname))                     
    %close(1)                           
  
    
end % ccc ccvarlist
   



%% 1x3 figures: compare response vol shk of 4-variable VAR against model

clc;

% list of modnum values to run
% revised list starting in June 2020
modnumlist = [81, 84, 85, 86 ]; 
%modnumlist = [81]; 
%modnumlist = [81]; 
%modnumlist = [150, 151]; 
%modnumlist = [152, 153]; 
%modnumlist = [154]; 
%modnumlist = [93, 94]; % alternate list to try when testing new cals in october 2020
%modnumlist = [96, 97]; % alternate list to try when testing new cals in october 2020
% Benchmark: model 81
% No government aka No L sector: model 84
% CRRA gamma = 0.5: model 86
% CRRA gamma = 10: model 85

sample_start_year=1972; % consistent with micro data

%filterlist = {'hpfilter'}; % note that filterlist = {'lindetrend'} works 
filterlist = {'bandpass'}; % 
%filterlist = {'hpfilter','bandpass'}; % 

% credit control var
ccvarlist = {'baa10ym'};
%ccvarlist = {'none'};
%ccvarlist = {'none'; 'baa10ym';'aaa10ym'};
%ccvarlist = {'none'; 'baa10ym';'aaa10ym';'nfci';'anfci'};

for myset = 1:1
 for mmm = 1:length(modnumlist)
  for fff = 1:length(filterlist)
   for ccc = 1:length(ccvarlist)


    if myset==1
        var_set = {'IPPrnd_real';'Ip_real';'Yp_real'}; 
        %My_Ylims_c1 = [-1.0, 1.0];
        %My_Ylims_c2 = [-3.0, 3.0];
        My_Ylims_c1 = [-2.0, 1.0];
        My_Ylims_c2 = [-2.0, 1.0];        
        My_Ylims_c3 = [-1.0, 1.0];
        
        % just for figures using model 150 and 151
        My_Ylims_c1 = [-2.0, 2.0];
        My_Ylims_c2 = [-2.0, 2.0];        
        My_Ylims_c3 = [-1.0, 1.0];        
    elseif myset==2
        var_set = {'m';'unlev_ret51';'unlev_ret51'}; 
        My_Ylims_c1 = [-1.0, 1.0];
        My_Ylims_c2 = [-3.0, 3.0];
        My_Ylims_c3 = [-1.0, 1.0];              
    elseif myset==3
        var_set = {'ln_labor_priv';'ln_labor_govt';'ln_labor_tot'}; 
        My_Ylims_c1 = [-0.5, 0.5];
        My_Ylims_c2 = [-0.5, 0.5];
        My_Ylims_c3 = [-0.5, 0.5];          
    else
        error('var_set for myset value not specified above');
    end
       
       
    % model to compare against
    %modnum_to_compare = 105; % benchmark
    %modnum_to_compare = 603; 
    %modnum_to_compare = 405; 
    %modnum_to_compare = 404;    
    modnum_to_compare = modnumlist(mmm);       
       
    % assign variables
    myfilter = char(filterlist{fff});
    myinvvar_1 = char(var_set{1});
    myinvvar_2 = char(var_set{2});
    myinvvar_3 = char(var_set{3});
    %myinvvar_4 = char(var_set{4});
    myccvar = char(ccvarlist{ccc});

    % generate IRF vectors from the models

        % single unit impulse to exp(vol)
        
            std_IRF_length_qtr = 24;

            % std volatility level shock
            vol_shk_lev_mat_qtr      = zeros(2 , std_IRF_length_qtr);
            vol_shk_lev_mat_qtr(2,1) = log( std(data_inv_reg_qtr.expvol)+1 ); % log shock val to get 1-std dev in level of vol
            % NOTE: ex removed as shock in BCLR EndoGrowth

            % std tfp shock. note that TFP growth in the data VAR is in log
            % units according to Wenxi
            tfp_val_shk_mat_qtr      = zeros(2 , std_IRF_length_qtr);
            tfp_val_shk_mat_qtr(1,1) = std(data_inv_reg_qtr.dtfp); % shock val to log TFP growth

            disp(char(strcat({'Computing IRFs for model '},num2str(modnum_to_compare),{'...'})));

            % compute irfs for 1-unit vol shock and 1-unit tfp shock

                model_IRFout_1unit_tfp_qtr = gen_IRF_vectors_model( modnum_to_compare, [], [], 'lev', tfp_val_shk_mat_qtr);
                model_IRFout_1unit_vol_qtr = gen_IRF_vectors_model( modnum_to_compare, [], [], 'lev', vol_shk_lev_mat_qtr);
                
            disp(char(strcat({'Done computing model IRFs!'})));
    
    % assign variable labels
    for varnum=1:3
        
        % temporary loop var name
        eval(strcat('temp_invvar = myinvvar_',num2str(varnum),';'));
             
        % figure out label based on name
        temp_MyVar_ylabel = 'NEED LABEL';
        temp_MyVar_title  = 'NEED TITLE';
        if strcmp(temp_invvar,'Ig_Itot')
            temp_MyVar_ylabel = 'I_g / (I_g + I_p)';
            temp_MyVar_title = 'Govt. to Total Inv. (I_g / (I_g + I_p))';
            temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_Ig_Itot;
            temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_Ig_Itot;                                           
        end
        if strcmp(temp_invvar,'Ip_Itot')
            temp_MyVar_ylabel = 'I_p / (I_g + I_p)';
            temp_MyVar_title = 'Priv. to Total Inv. (I_p / (I_g + I_p))';
            %error('need to add Ip_Itot to model IRF output');
            temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_Ip_Itot;
            temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_Ip_Itot;            
        end
        if strcmp(temp_invvar,'Ig_Y')
            temp_MyVar_ylabel = 'I_g / Y';
            temp_MyVar_title = 'Govt. to GDP (I_g / Y)';
            temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_Ig_Y;
            temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_Ig_Y;
        end        
        if strcmp(temp_invvar,'IPPtot_real')
            temp_MyVar_ylabel = texlabel('log(I_I_P_P)');
            temp_MyVar_title = 'Priv. IPP (incl. R&D) Inv. (log(I_I_P_P))';
            error('need to add IPPtot_real to model IRF output');         
        end
        if strcmp(temp_invvar,'IPPrnd_real')
            temp_MyVar_ylabel = texlabel('log(I_R_&_D)');
            %temp_MyVar_title = 'Priv. R&D Inv. (log(I_R_&_D))';
            %temp_MyVar_title = 'R&D Inv. (log(I_R_&_D))';
            temp_MyVar_title = 'log(I_R_&_D)';
            temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_logIPPrnd;
            temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_logIPPrnd;            
        end
        if strcmp(temp_invvar,'Ig_real')
            temp_MyVar_ylabel = texlabel('log(I_g)');
            temp_MyVar_title = 'Govt. Inv. (log(I_g))';
            temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_logIg;
            temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_logIg;                        
        end
        if strcmp(temp_invvar,'Ip_real')
            temp_MyVar_ylabel = texlabel('log(I_p)');
            %temp_MyVar_title = 'Priv. Total Inv. (log(I_p))';
            %temp_MyVar_title = 'Tangible Inv. (log(I_H))';
            temp_MyVar_title = 'log(I_H+I_R_&_D)';
            temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_logIp;
            temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_logIp;
            %temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_dip;
            %temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_dip;            
        end    
        if strcmp(temp_invvar,'Ip_NOTrnd_real')
            temp_MyVar_ylabel = texlabel('log(I_p-I_R_&_D)');
            temp_MyVar_title = 'Priv. Non-R&D Inv. (log(I_p-I_R_&_D))';
            error('need to add Ip_NOTrnd_real to model IRF output');         
        end            
        if strcmp(temp_invvar,'Itot_real')
            temp_MyVar_ylabel = texlabel('log(I_p+I_g)');
            temp_MyVar_title = 'Total Inv. (log(I_p+I_g))';
            temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_logIp;
            temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_logIp;
            disp('Need to fix model variable to be correct');
            beep;
        end            
        if strcmp(temp_invvar,'Itang_v1_real')
            temp_MyVar_ylabel = texlabel('log(I_t_a_n_g)');
            temp_MyVar_title = 'Tangible Inv. (log(I_p+I_g-I_R_&_D))';
            temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_logIp;
            temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_logIp;
            disp('Need to fix model variable to be correct');
            beep;
        end            
        if strcmp(temp_invvar,'Itang_v2_real')
            temp_MyVar_ylabel = texlabel('log(I_t_a_n_g)');
            temp_MyVar_title = 'Tangible Inv. (log(I_p+I_g-I_I_P_P))';
            temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_logIp;
            temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_logIp;
            disp('Need to fix model variable to be correct');
            beep;
        end                            
        if strcmp(temp_invvar,'Yp_real')
            temp_MyVar_ylabel = texlabel('log(Y_p)');
            %temp_MyVar_title = 'Priv. Output (log(Y_p))';
            %temp_MyVar_title = 'Output (log(Y))';
            temp_MyVar_title = 'log(Y_H)';
            temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_logYp;
            temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_logYp;                                                            
        end          
        if strcmp(temp_invvar,'Y_real')
            temp_MyVar_ylabel = texlabel('log(Y_G_D_P)');
            temp_MyVar_title = 'GDP (log(Y_G_D_P))';
            temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_logY;
            temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_logY;                                                            
        end                  
        if strcmp(temp_invvar,'ln_labor_priv')
            temp_MyVar_ylabel = texlabel('log(L_P)');
            temp_MyVar_title = 'Private Labor (log(L_P))';
            temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_np;
            temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_np;                                                            
        end   
        if strcmp(temp_invvar,'ln_labor_govt')
            temp_MyVar_ylabel = texlabel('log(L_G)');
            temp_MyVar_title = 'Govt. Labor (log(L_G))';
            temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_nc;
            temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_nc;                                                            
        end           
        if strcmp(temp_invvar,'ln_labor_tot')
            temp_MyVar_ylabel = texlabel('log(L_P+L_G)');
            temp_MyVar_title = 'Total Labor (log(L_P+L_G))';
            temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_ntotal;
            temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_ntotal;                                                            
        end             
        
        % create shells of variables so code below does not break if we
        % comment out the VAR on simulated model data
        model_IRF_from_sim_and_VAR = nan(1);
        temp_model_IRF_sim_vol_line = nan(1);
        temp_model_IRF_sim_vol_line_ciL = nan(1);
        temp_model_IRF_sim_vol_line_ciU = nan(1);
        temp_model_IRF_sim_tfp_line = nan(1);
        temp_model_IRF_sim_tfp_line_ciL = nan(1);
        temp_model_IRF_sim_tfp_line_ciU = nan(1);
        
        % compute IRF from VAR on simulated model data
%         disp(char(strcat({'Computing IRFs for var '},num2str(varnum),{' of 4 from VAR on simulated modnum '},num2str(modnum_to_compare),{'...'})));
%         model_IRF_from_sim_and_VAR = gen_IRF_vectors_model_using_sim_data( modnum_to_compare, temp_invvar, myfilter);
%         temp_model_IRF_sim_vol_line = model_IRF_from_sim_and_VAR.evol_oirf_var4;
%         temp_model_IRF_sim_vol_line_ciL = model_IRF_from_sim_and_VAR.evol_oirf_var4_ciL;
%         temp_model_IRF_sim_vol_line_ciU = model_IRF_from_sim_and_VAR.evol_oirf_var4_ciU;        
%         temp_model_IRF_sim_tfp_line = model_IRF_from_sim_and_VAR.dtfp_oirf_var4;
%         temp_model_IRF_sim_tfp_line_ciL = model_IRF_from_sim_and_VAR.dtfp_oirf_var4_ciL;
%         temp_model_IRF_sim_tfp_line_ciU = model_IRF_from_sim_and_VAR.dtfp_oirf_var4_ciU;                 
%         disp(char(strcat({'Done with IRF from simulated model for var '},num2str(varnum),{'!'})));
        
        % assign label
        if varnum==1
            MyVar_ylabel_1 = texlabel(temp_MyVar_ylabel);
            MyVar_title_1  = texlabel(temp_MyVar_title);
            model_IRF_vol_line_1 = temp_model_IRF_vol_line;
            model_IRF_tfp_line_1 = temp_model_IRF_tfp_line;                        
            model_IRF_sim_vol_line_1     = temp_model_IRF_sim_vol_line;
            model_IRF_sim_vol_line_1_ciL = temp_model_IRF_sim_vol_line_ciL;
            model_IRF_sim_vol_line_1_ciU = temp_model_IRF_sim_vol_line_ciU;
            model_IRF_sim_tfp_line_1     = temp_model_IRF_sim_tfp_line;
            model_IRF_sim_tfp_line_1_ciL = temp_model_IRF_sim_tfp_line_ciL;
            model_IRF_sim_tfp_line_1_ciU = temp_model_IRF_sim_tfp_line_ciU;            
        end
        if varnum==2
            MyVar_ylabel_2 = texlabel(temp_MyVar_ylabel);
            MyVar_title_2  = texlabel(temp_MyVar_title);
            model_IRF_vol_line_2 = temp_model_IRF_vol_line;
            model_IRF_tfp_line_2 = temp_model_IRF_tfp_line;     
            model_IRF_sim_vol_line_2     = temp_model_IRF_sim_vol_line;
            model_IRF_sim_vol_line_2_ciL = temp_model_IRF_sim_vol_line_ciL;
            model_IRF_sim_vol_line_2_ciU = temp_model_IRF_sim_vol_line_ciU;
            model_IRF_sim_tfp_line_2     = temp_model_IRF_sim_tfp_line;
            model_IRF_sim_tfp_line_2_ciL = temp_model_IRF_sim_tfp_line_ciL;
            model_IRF_sim_tfp_line_2_ciU = temp_model_IRF_sim_tfp_line_ciU;                  
        end
        if varnum==3
            MyVar_ylabel_3 = texlabel(temp_MyVar_ylabel);
            MyVar_title_3  = texlabel(temp_MyVar_title);
            model_IRF_vol_line_3 = temp_model_IRF_vol_line;
            model_IRF_tfp_line_3 = temp_model_IRF_tfp_line; 
            model_IRF_sim_vol_line_3     = temp_model_IRF_sim_vol_line;
            model_IRF_sim_vol_line_3_ciL = temp_model_IRF_sim_vol_line_ciL;
            model_IRF_sim_vol_line_3_ciU = temp_model_IRF_sim_vol_line_ciU;
            model_IRF_sim_tfp_line_3     = temp_model_IRF_sim_tfp_line;
            model_IRF_sim_tfp_line_3_ciL = temp_model_IRF_sim_tfp_line_ciL;
            model_IRF_sim_tfp_line_3_ciU = temp_model_IRF_sim_tfp_line_ciU;               
        end
        if varnum==4
            MyVar_ylabel_4 = texlabel(temp_MyVar_ylabel);
            MyVar_title_4  = texlabel(temp_MyVar_title);
            model_IRF_vol_line_4 = temp_model_IRF_vol_line;
            model_IRF_tfp_line_4 = temp_model_IRF_tfp_line;                        
            model_IRF_sim_vol_line_4     = temp_model_IRF_sim_vol_line;
            model_IRF_sim_vol_line_4_ciL = temp_model_IRF_sim_vol_line_ciL;
            model_IRF_sim_vol_line_4_ciU = temp_model_IRF_sim_vol_line_ciU;
            model_IRF_sim_tfp_line_4     = temp_model_IRF_sim_tfp_line;
            model_IRF_sim_tfp_line_4_ciL = temp_model_IRF_sim_tfp_line_ciL;
            model_IRF_sim_tfp_line_4_ciU = temp_model_IRF_sim_tfp_line_ciU;               
        end        
        
        clearvars temp_model_IRF_vol_line temp_model_IRF_tfp_line;
        
    end
    
    % for checking: what is repsonse of vol to itself
    chk_model_expvol_resp_to_vol_shk = model_IRFout_1unit_vol_qtr.oirf_expvol;

    % compile quarterly data for each variable
    
    start_year_qtr = min(data_inv_reg_qtr.year);
    if sample_start_year==1961
        pos_start      = find((data_macro_qtr.year>=start_year_qtr),1,'first'); % start 1 qtr later so macro data is 1961Q1:2016Q4
    else        
        pos_start      = find((data_macro_qtr.year>=start_year_qtr),1,'first') - 1;        
    end
    disp(char(strcat({'macro var data from '},num2str(data_macro_qtr.year(pos_start)),'q',num2str(data_macro_qtr.qtr(pos_start)))))
    disp(char(strcat({'inv reg data from '},num2str(data_inv_reg_qtr.year(1)),'q',num2str(data_inv_reg_qtr.qtr(1)))))
    disp(char(strcat({'note: we want macro data to start 1 qtr before inv reg data b/c we take diffs of macro data to prepare them for VAR'})))

    % choose ending position such that de-meaned macro data series will be
    % the same length as the investment regression data series
    length_qtr_VAR = length(data_inv_reg_qtr.x);
    pos_end = pos_start+length_qtr_VAR;    
    
    % move pos_start later if credit variable with shorter history
    if strcmp(myccvar,'nfci') || strcmp(myccvar,'anfci') || strcmp(myccvar,'gzspr')
        pos_start = 105; % 1973q1: first date with FCIs and GZ index
        length_qtr_VAR = pos_end - pos_start; % update length
    end              
    
    for varnum=1:3           
        
        eval(strcat('tempvarname = myinvvar_',num2str(varnum),';'));
        
        eval(strcat('var4_raw_qtr = data_macro_qtr.',tempvarname,';'));
        
        % truncated series to match other series
        var4_trunc = var4_raw_qtr(pos_start:pos_end);

        % de-trend 4th variable using HP filter or something else                    
        
            temp_var4_qtr = nan(size(var4_trunc));
        
            % HP filter. use pos_start+1 because no need to take first differences
            if strcmp(myfilter,'hpfilter')            
                raw_var4_qtr     = log(var4_trunc(2:end));
                smooth_var4_qtr  = hpfilter(raw_var4_qtr, 1600); % quarterly data smoothing 
                temp_var4_qtr    = raw_var4_qtr - smooth_var4_qtr;
            end

            % linear de-trend
            if strcmp(myfilter,'lindetrend')          
                temp_var4_qtr = prep_raw_data_for_VAR( var4_trunc) ;
            end
            
            % Comin Gertler (2006) band-pass
            % The function is bandpass(X,pl,pu). X is the raw data, pl and pu is the range of frequencies we want to extract. 
            % Recommended by Comin and Gertler (attached below), we should choose pl = 2 and pu = 200 for the quarterly data 
            % to extract the medium-term cycles. 
            if strcmp(myfilter,'bandpass')  
                
                size(var4_trunc);
                raw_var4_qtr = log(var4_trunc(2:end)); % no reduction in size from bandpass --> need to cut first obs for VAR
                temp_var4_qtr = bandpass(raw_var4_qtr, 2, 200);
                size(temp_var4_qtr); % no reduction in size from bandpass
                
                % visually compare to raw series                
%                 figure(1); box on; hold on;
% 
%                     yyaxis left
%                     h(1) = plot(temp_var4_qtr_plus_one,'-k', 'Linewidth', 0.7);
%                     yyaxis right
%                     h(2) = plot(raw_var4_qtr,'-r', 'Linewidth', 0.5);
%                     legend(h,['Bandpass(2,200)'],['Raw'],'Location','Northwest');
%                     title(strcat({'Raw vs Bandpass Series: '}, MyVar_title_1));
%                     clear h;
%                     fname = strcat('compare_bandpass_',tempvarname,'_vs_raw');
%                     saveas(1,strcat('Figures/',fname),'png')
%                     saveas(1,strcat('Figures/',fname))                 
%                     close(1)                       
                    
                % visually compare to hpfilter
%                 smooth_var4_qtr = hpfilter(raw_var4_qtr, 1600); % quarterly data smoothing 
%                 var_hpfilter    = raw_var4_qtr - smooth_var4_qtr;                
%                 figure(1); box on; hold on;
% 
%                     yyaxis left
%                     h(1) = plot(temp_var4_qtr,'-k', 'Linewidth', 0.7);
%                     yyaxis right
%                     h(2) = plot(100*var_hpfilter,'-r', 'Linewidth', 0.7);
%                     legend(h,['Bandpass(2,200), Left Axis'],['HP Filter(1600), Right Axis'],'Location','Northwest');
%                     title(strcat({'Bandpass vs HP Filter Series: '}, MyVar_title_1));
%                     clear h;
%                     fname = strcat('compare_bandpass_',tempvarname,'_vs_hpfilter');
%                     saveas(1,strcat('Figures/',fname),'png')
%                     saveas(1,strcat('Figures/',fname))                 
%                     close(1)                                           

            end

            
        % final dataset for VAR             
        y_qtr_reg = [data_inv_reg_qtr.dtfp(1:length_qtr_VAR), data_inv_reg_qtr.x(1:length_qtr_VAR), data_inv_reg_qtr.expvol(1:length_qtr_VAR)];    
        %if strcmp(tempvarname,'Ig_Itot') || strcmp(tempvarname,'Ip_Itot') % series to enter VAR in levels
        if strcmp(tempvarname,'Ig_Itot') || strcmp(tempvarname,'Ip_Itot') || strcmp(tempvarname,'Ig_Y') % series to enter VAR in levels
            temp_y_qtr = [y_qtr_reg, exp(temp_var4_qtr)];    
        else
            temp_y_qtr = [y_qtr_reg, temp_var4_qtr];    
        end

        % final exogenous variable dataset for quarterly VAR
        temp_x_qtr = ones(size(temp_y_qtr,1),1);
        if ~strcmp(myccvar, 'none')
            eval(strcat('ccvar_raw_qtr = data_macro_qtr.',myccvar,';'));
            temp_ccvar_qtr = ccvar_raw_qtr(pos_start+1:pos_end);
            temp_x_qtr = [temp_x_qtr, temp_ccvar_qtr];        
        end      
        
        eval(strcat('y_qtr_',num2str(varnum),' = temp_y_qtr;'));
        eval(strcat('x_exo_qtr_',num2str(varnum),' = temp_x_qtr;'));
        
        clear var4_raw_qtr var4_trunc temp_var4_qtr temp_y_qtr temp_x_qtr
        
        % define different shock matrices

            std_IRF_length_qtr = 24;

            % 1-std dtfp shock
            std_dtfp_shk_mat_qtr      = zeros(4 , std_IRF_length_qtr);
            std_dtfp_shk_mat_qtr(1,1) = 1;            

            % 1-std ivol shock
            std_ivol_shk_mat_qtr      = zeros(4 , std_IRF_length_qtr);
            std_ivol_shk_mat_qtr(3,1) = 1;             
    
           
        % compute IRFs 

            % dtfp shk
            %IRFout_dtfpshk_qtr_1 = gen_IRF_vectors_dataVAR_nvars( y_qtr_1, x_exo_qtr_1, [], std_dtfp_shk_mat_qtr, 0);
            %IRFout_dtfpshk_qtr_2 = gen_IRF_vectors_dataVAR_nvars( y_qtr_2, x_exo_qtr_2, [], std_dtfp_shk_mat_qtr, 0);  
            eval(strcat('IRFout_dtfpshk_qtr_',num2str(varnum),' = gen_IRF_vectors_dataVAR_nvars( y_qtr_',num2str(varnum),', x_exo_qtr_',num2str(varnum),', [], std_dtfp_shk_mat_qtr, 0);'))
            %eval(strcat('IRFout_dtfpshk_qtr_',num2str(varnum),' = gen_IRF_vectors_dataVAR_nvars( y_qtr_',num2str(varnum),', x_exo_qtr_',num2str(varnum),', [], std_dtfp_shk_mat_qtr, 0, w_loop_val);'))

            % ivol shk
            %IRFout_ivolshk_qtr_1 = gen_IRF_vectors_dataVAR_nvars( y_qtr_1, x_exo_qtr_1, [], std_ivol_shk_mat_qtr, 0);
            %IRFout_ivolshk_qtr_2 = gen_IRF_vectors_dataVAR_nvars( y_qtr_2, x_exo_qtr_2, [], std_ivol_shk_mat_qtr, 0);              
            eval(strcat('IRFout_ivolshk_qtr_',num2str(varnum),' = gen_IRF_vectors_dataVAR_nvars( y_qtr_',num2str(varnum),', x_exo_qtr_',num2str(varnum),', [], std_ivol_shk_mat_qtr, 0);'));
            %eval(strcat('IRFout_ivolshk_qtr_',num2str(varnum),' = gen_IRF_vectors_dataVAR_nvars( y_qtr_',num2str(varnum),', x_exo_qtr_',num2str(varnum),', [], std_ivol_shk_mat_qtr, 0, w_loop_val);'));
            
    end

    

  
  % plot 1x3 IRF for vol shock only
  for plot_model_lines = 1:1; % run only with model lines for draft
    close ALL
    if plot_model_lines
        fname = strcat('IRFs_OnlyVol_data_vs_model_',num2str(modnum_to_compare),'_1x3_dtfp_x_expvol_',myinvvar_1,'_or_',myinvvar_2,'_or_',myinvvar_3,'_',myfilter,'_control_',myccvar);    
    else
        fname = strcat('IRFs_OnlyVol_1x3_dtfp_x_expvol_',myinvvar_1,'_or_',myinvvar_2,'_or_',myinvvar_3,'_',myfilter,'_control_',myccvar);    
    end
    figure(1);
    
        % set size of figure so it fills page
        set(gcf, 'PaperPositionMode', 'manual');
        set(gcf, 'PaperUnits', 'inches');
        %set(gcf, 'PaperPosition', [0 0 14.00 3.50]);  
        %set(gcf, 'DefaultAxesPosition', [0.05, 0.1, 0.9, 0.9]);
        % make the figure fill the slide better
        set(gcf, 'PaperPosition', [0 0 11.00 3.50]);  
        set(gcf, 'DefaultAxesPosition', [0.05, 0.1, 0.92, 0.9]);
  
        % per May 18 2019 call with max, change length of IRF to 20 
        % periods when comparing data vs model
        if plot_model_lines
            IRF_length_plot = std_IRF_length_qtr+1-4;
        else
            IRF_length_plot = std_IRF_length_qtr+1;
        end
        
        % quarterly data for var 1

            subplot(1,3,1); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_1.oirf_var4(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_1.oirf_var4_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_1.oirf_var4_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);
            if plot_model_lines
                plot(0:IRF_length_plot-1, 100*model_IRF_vol_line_1(1:IRF_length_plot), '-r', 'Linewidth', 2);
            end                
            title(strcat('\fontsize{12}',MyVar_title_1),'FontWeight','normal');
            xlabel('Quarters');
            ylabel('Percent');            
            axis('tight');
            ylim(My_Ylims_c1);        
        
            
        % quarterly data for var 2

            subplot(1,3,2); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_2.oirf_var4(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_2.oirf_var4_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_2.oirf_var4_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);
            if plot_model_lines
                plot(0:IRF_length_plot-1, 100*model_IRF_vol_line_2(1:IRF_length_plot), '-r', 'Linewidth', 2);
            end                                
            title(strcat('\fontsize{12}',MyVar_title_2),'FontWeight','normal');
            xlabel('Quarters');
            ylabel(' ');                
            axis('tight');
            ylim(My_Ylims_c2);
   
            
        % quarterly data for var 3

            subplot(1,3,3); hold on; box on;
            h(2) = plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            h(1) = plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_3.oirf_var4(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_3.oirf_var4_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_3.oirf_var4_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);
            if plot_model_lines
                h(2) = plot(0:IRF_length_plot-1, 100*model_IRF_vol_line_3(1:IRF_length_plot), '-r', 'Linewidth', 2);
            end                                                
            title(strcat('\fontsize{12}',MyVar_title_3),'FontWeight','normal');
            xlabel('Quarters');
            ylabel(' ');                            
            axis('tight');
            ylim(My_Ylims_c3);    
            legend(h,'Data','Model','Location','northeast');
            clear h;                

        % save jpg        
        saveas(1,strcat('figures/',fname),'png')
        saveas(1,strcat('figures/',fname)) 
        %saveas(1,strcat('output_for_paper/Figures/',fname),'png')
        %saveas(1,strcat('output_for_paper/Figures/',fname))
        %close(1)                  
  
  end
  
  
  % check response of vol to a vol shock model vs data
  if 1==0 

    fname = strcat('IRFs_chk_vol_shock_resp_to_itself_data_vs_model_',num2str(modnum_to_compare),'_1x3_dtfp_x_expvol_',myinvvar_1,'_',myfilter,'_control_',myccvar);    
      
    figure(2);
    
        % set size of figure so it fills page
        set(gcf, 'PaperPositionMode', 'manual');
        set(gcf, 'PaperUnits', 'inches');
        %set(gcf, 'PaperPosition', [0 0 14.00 3.50]);  
        %set(gcf, 'DefaultAxesPosition', [0.05, 0.1, 0.9, 0.9]);
        % make the figure fill the slide better
        %set(gcf, 'PaperPosition', [0 0 11.00 3.50]);  
        set(gcf, 'PaperPosition', [0 0 3.50 3.50]); % 1x1 plot
        %set(gcf, 'DefaultAxesPosition', [0.05, 0.1, 0.92, 0.9]);
  
        % per May 18 2019 call with max, change length of IRF to 20 
        % periods when comparing data vs model
        %if plot_model_lines
            IRF_length_plot = std_IRF_length_qtr+1-4;
        %else
            %IRF_length_plot = std_IRF_length_qtr+1;
        %end
         
        % quarterly data for 3rd var in data VAR based on var 1 as 4th var

            %subplot(1,3,3); hold on; box on;
            hold on; box on;
            h(2) = plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            h(1) = plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_1.oirf_var3(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_1.oirf_var3_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_1.oirf_var3_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);
            %if plot_model_lines
                h(2) = plot(0:IRF_length_plot-1, 100*chk_model_expvol_resp_to_vol_shk(1:IRF_length_plot), '-r', 'Linewidth', 2);
            %end                                                
            %title(strcat('\fontsize{12}',MyVar_title_3),'FontWeight','normal');
            title(strcat('\fontsize{12}','Reponse of Vol to a Vol Shock'),'FontWeight','normal');
            xlabel('Quarters');
            ylabel(' ');                            
            axis('tight');
            %ylim(My_Ylims_c3);    
            legend(h,'Data','Model','Location','northeast');
            clear h;                

        % save jpg        
        saveas(2,strcat('figures/',fname),'png')
        saveas(2,strcat('figures/',fname)) 
        %close(2)                        
      
  end
    

   end % ccc
  end % fff
 end % mmm
end % myset



%% create 2x3 figure that compares model vs 4-variable data VAR for a
%  set of var4 choices that include govt variables that we label as G

clc;

% panel titles option
% option for panel titles to use H and L
alt_panel_titles= 0;
%alt_panel_titles= 1;

%ccvarlist = {'none'};
ccvarlist = {'baa10ym'};
%ccvarlist = {'none'; 'baa10ym';'aaa10ym'};

% var4 set
%var_set = {'Ig_Y';'IPPrnd_real';'Ip_real';'labor_share_govt';'Yp_real'}; 
var_set = {'Ig_Y';'IPPrnd_real';'Ip_real';'labor_share_govt';'labor_priv';'Yp_real'}; 
%var_set = {'Ig_less_def_Y';'IPPrnd_real';'Ip_real';'labor_share_govt';'labor_priv';'Yp_real'}; 
% XXX
My_Ylims_c1 = [-2.0, 1.0];
My_Ylims_c2 = [-2.0, 1.0];
My_Ylims_c3 = [-2.0, 1.0];
My_Ylims_c4 = [-1.0, 0.5];    
My_Ylims_c5 = [-1.0, 0.5];    
My_Ylims_c6 = [-1.0, 0.5];    

% VAR specs choice
%myVARspec = 'hpfilter';
myVARspec = 'bandpass';
%myVARspec = 'levels';

%modnum_list = [81,82,83];
% 81 = Benchmark govt (endogenous investment L sector)
% 82 = EGI
% 83 = EGE, which has weaker reallocation because deltaG=100%
%modnum_list = [93,94]; % alternate cals we explore in october 2020
%modnum_list = [96,97]; % alternate cals we explore in october 2020
%modnum_list = [135];
modnum_list = [82];

for mmm = 1:length(modnum_list)
% modnum choice
%my_modnum = 3;
%my_modnum = 51;
%my_modnum = 54;
%my_modnum = 64;
%my_modnum = 81;
my_modnum = modnum_list(mmm);

for ccc = 1:length(ccvarlist)
  
 % cc control var
 myccvar = char(ccvarlist{ccc});
    
 % compute IRFs for different var4 choices
 for vvv = 1:length(var_set)

    %myVARspec = char(VARspecs{vvv});
    var4_choice = var_set{vvv} ;
     
    % figure out starting and ending positions
    sample_start_year = 1972;
    sample_end_year   = 2016;     
    if strcmp(myVARspec,'levels')
        pos_start_macro  = find((data_macro_qtr.year>=sample_start_year),1,'first');        
    else % need extra period for filtering        
        pos_start_macro = find((data_macro_qtr.year>=sample_start_year),1,'first') - 1; 
    end    
    pos_end_macro   = find((data_macro_qtr.year<=sample_end_year),1,'last');
    pos_start_invreg = find((data_inv_reg_qtr.year>=sample_start_year),1,'first');        
    pos_end_invreg   = find((data_inv_reg_qtr.year<=sample_end_year),1,'last');  
    disp(char(strcat({'macro var data from '},num2str(data_macro_qtr.year(pos_start_macro)),'q',num2str(data_macro_qtr.qtr(pos_start_macro)))))
    disp(char(strcat({'macro var data to '},  num2str(data_macro_qtr.year(pos_end_macro)),  'q',num2str(data_macro_qtr.qtr(pos_end_macro)))))
    disp(char(strcat({'inv reg data from '},num2str(data_inv_reg_qtr.year(pos_start_invreg)),'q',num2str(data_inv_reg_qtr.qtr(pos_start_invreg)))))
    disp(char(strcat({'inv reg data to '},num2str(data_inv_reg_qtr.year(pos_end_invreg)),'q',num2str(data_inv_reg_qtr.qtr(pos_end_invreg)))))    
    
    % first three variables from investment regression
    if strcmp(myVARspec,'levels')
        var1 = data_macro_qtr.tfp( pos_start_macro:pos_end_macro); % tfp in levels
    else
        var1 = data_macro_qtr.dtfp( pos_start_macro+1:pos_end_macro)/4; % dtfp from macro data. need to convert back to quarterly rates from annualized rate
        %var1_chk = data_inv_reg_qtr.dtfp( pos_start_invreg:pos_end_invreg); % dtfp from inv reg data
        %chk_diff = abs(var1 - var1_chk);
        %max(chk_diff)
        %[var1, var1_chk]
    end
    var2 = data_inv_reg_qtr.x( pos_start_invreg:pos_end_invreg);
    var3 = data_inv_reg_qtr.expvol( pos_start_invreg:pos_end_invreg);
    
    % 4th variable that may be filtered depending myVARspec
    eval(strcat('var4_raw_qtr = data_macro_qtr.',var4_choice,';'));
    var4_trunc = var4_raw_qtr(pos_start_macro:pos_end_macro); % truncated series to match other series
    if strcmp(myVARspec,'levels') % simply compute in log levels
        temp_var4_qtr = log(var4_trunc); 
    else % de-trend 4th variable 
        
        temp_var4_qtr = nan(size(var4_trunc));

        % HP filter. use pos_start+1 because no need to take first differences
        if strcmp(myVARspec,'hpfilter')            
            raw_var4_qtr     = log(var4_trunc(2:end));
            smooth_var4_qtr  = hpfilter(raw_var4_qtr, 1600); % quarterly data smoothing 
            temp_var4_qtr    = raw_var4_qtr - smooth_var4_qtr;
        end   
        
        % Comin Gertler (2006) band-pass
        % The function is bandpass(X,pl,pu). X is the raw data, pl and pu is the range of frequencies we want to extract. 
        % Recommended by Comin and Gertler (attached below), we should choose pl = 2 and pu = 200 for the quarterly data 
        % to extract the medium-term cycles. 
        if strcmp(myVARspec,'bandpass')  
            size(var4_trunc);
            raw_var4_qtr = log(var4_trunc(2:end)); % no reduction in size from bandpass --> need to cut first obs for VAR
            temp_var4_qtr = bandpass(raw_var4_qtr, 2, 200);
            size(temp_var4_qtr); % no reduction in size from bandpass                                
        end  
        
    end

    % series to enter VAR in levels 
    if strcmp(var4_choice,'Ig_Itot') ...
    || strcmp(var4_choice,'Ip_Itot') ...
    || strcmp(var4_choice,'Ig_Y') ...
    || strcmp(var4_choice,'Ig_less_def_Y') ...    
    || strcmp(var4_choice,'labor_share_govt') ...
    || strcmp(var4_choice,'labor_share_priv') 
        var4 = exp(temp_var4_qtr);
    else
        var4 = temp_var4_qtr; % keep in logs
    end    
    
    % endogenous vars matrix
    temp_y_qtr = [var1, var2, var3, var4];
 
    % exogenous vars matrix
    temp_x_qtr = ones(size(temp_y_qtr,1),1);
    if ~strcmp(myccvar, 'none')
        eval(strcat('ccvar_raw_qtr = data_macro_qtr.',myccvar,';'));
        if strcmp(myVARspec,'levels') 
            temp_ccvar_qtr = ccvar_raw_qtr(pos_start_macro:pos_end_macro);
        else
            temp_ccvar_qtr = ccvar_raw_qtr(pos_start_macro+1:pos_end_macro);
        end
        temp_x_qtr = [temp_x_qtr, temp_ccvar_qtr];        
    end      

    eval(strcat('y_qtr_',num2str(vvv),' = temp_y_qtr;'));
    eval(strcat('x_exo_qtr_',num2str(vvv),' = temp_x_qtr;'));

    clear var4_raw_qtr var4_trunc temp_var4_qtr temp_y_qtr temp_x_qtr

    % define different shock matrices

        std_IRF_length_qtr = 24;

        % 1-std dtfp shock
        std_dtfp_shk_mat_qtr      = zeros(4 , std_IRF_length_qtr);
        std_dtfp_shk_mat_qtr(1,1) = 1;            

        % 1-std ivol shock
        std_ivol_shk_mat_qtr      = zeros(4 , std_IRF_length_qtr);
        std_ivol_shk_mat_qtr(3,1) = 1;             

        % compute IRFs for ivol shk
        eval(strcat('IRFout_ivolshk_qtr_',num2str(vvv),' = gen_IRF_vectors_dataVAR_nvars( y_qtr_',num2str(vvv),', x_exo_qtr_',num2str(vvv),', [], std_ivol_shk_mat_qtr, 0);'));

 end % vvv var4 list

 % generate IRF vectors from the model

    %my_modnum = modnumlist(mmm);

    % single unit impulse to exp(vol)

        std_IRF_length_qtr = 24;

        % std volatility level shock
        vol_shk_lev_mat_qtr      = zeros(2 , std_IRF_length_qtr);
        vol_shk_lev_mat_qtr(2,1) = log( std(data_inv_reg_qtr.expvol)+1 ); % log shock val to get 1-std dev in level of vol
        % NOTE: ex removed as shock in BCLR EndoGrowth

        % std tfp shock. note that TFP growth in the data VAR is in log
        % units according to Wenxi
        tfp_val_shk_mat_qtr      = zeros(2 , std_IRF_length_qtr);
        tfp_val_shk_mat_qtr(1,1) = std(data_inv_reg_qtr.dtfp); % shock val to log TFP growth

        disp(char(strcat({'Computing IRFs for model '},num2str(my_modnum),{'...'})));

        % compute irfs for 1-unit vol shock and 1-unit tfp shock

            model_IRFout_1unit_tfp_qtr = gen_IRF_vectors_model( my_modnum, [], [], 'lev', tfp_val_shk_mat_qtr);
            model_IRFout_1unit_vol_qtr = gen_IRF_vectors_model( my_modnum, [], [], 'lev', vol_shk_lev_mat_qtr);

         % save IRF vectors
         for vvv = 1:length(var_set)    
            var4_choice = var_set{vvv} ;
            if strcmp(var4_choice,'Yp_real')
                temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_logYp;
                temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_logYp;                                                            
            elseif strcmp(var4_choice,'Ig_Itot')
                temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_Ig_Itot;
                temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_Ig_Itot;                                           
            elseif strcmp(var4_choice,'Ip_Itot')
                temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_Ip_Itot;
                temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_Ip_Itot;            
            elseif strcmp(var4_choice,'Ig_Y')
                temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_Ig_Y;
                temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_Ig_Y;       
            elseif strcmp(var4_choice,'Ig_less_def_Y')
                temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_Ig_Y;
                temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_Ig_Y;                                       
            elseif strcmp(var4_choice,'IPPrnd_real')
                temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_logIPPrnd;
                temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_logIPPrnd;            
            elseif strcmp(var4_choice,'Ig_real')
                temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_logIg;
                temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_logIg;                        
            elseif strcmp(var4_choice,'Ip_real')
                temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_logIp;
                temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_logIp;                                  
            elseif strcmp(var4_choice,'labor_share_govt')
                temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_ncnt;
                temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_ncnt;          
            elseif strcmp(var4_choice,'labor_share_priv')
                temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_npnt;
                temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_npnt;                 
            elseif strcmp(var4_choice,'labor_govt')
                temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_nc; % already in logs
                temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_nc; % already in logs
            elseif strcmp(var4_choice,'labor_priv')
                temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_np; % already in logs
                temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_np; % already in logs
            else
                error('var4_choice not recognized');
            end
            
            eval(strcat('model_IRF_vol_line_',num2str(vvv),' = temp_model_IRF_vol_line;'));
         end % vvv
            
        disp(char(strcat({'Done computing model IRFs!'})));
 

% create the 2x3 figure
close ALL
figure(1);

    if alt_panel_titles==1
        fname = strcat('IRFs_OnlyVol_data_',myVARspec,'_control_',myccvar,'_vs_model_alt_panel_titles_',num2str(my_modnum),'_2x3_',char(var_set{1}),'_',char(var_set{2}),'_',char(var_set{3}),'_',char(var_set{4}),'_',char(var_set{5}),'_',char(var_set{6}));    
    else
        fname = strcat('IRFs_OnlyVol_data_',myVARspec,'_control_',myccvar,'_vs_model_',num2str(my_modnum),'_2x3_',char(var_set{1}),'_',char(var_set{2}),'_',char(var_set{3}),'_',char(var_set{4}),'_',char(var_set{5}),'_',char(var_set{6}));    
    end

    % panel titles
    for vvv = 1:length(var_set)    
        
        var4_choice = var_set{vvv}; 
        
        if alt_panel_titles==1 
            if strcmp(var4_choice,'Yp_real')
                temp_MyVar_title = 'log(Y_H)';
            elseif strcmp(var4_choice,'Ig_Y')
                temp_MyVar_title = 'I_L / Y';
            elseif strcmp(var4_choice,'Ig_real')
                temp_MyVar_title = 'log(I_L)';
            elseif strcmp(var4_choice,'Ip_real')
                temp_MyVar_title = 'log(I_H)';
            elseif strcmp(var4_choice,'IPPrnd_real')
                temp_MyVar_title = 'log(I_R_&_D)';
            elseif strcmp(var4_choice,'labor_share_govt')
                temp_MyVar_title = 'L_L / (L_L + L_H))';            
            elseif strcmp(var4_choice,'labor_share_priv')
                temp_MyVar_title = 'L_H / (L_L + L_H)';
            elseif strcmp(var4_choice,'labor_govt')
                temp_MyVar_title = 'log(L_L)';            
            elseif strcmp(var4_choice,'labor_priv')
                temp_MyVar_title = 'log(L_H)';                                          
            else
                error('var4_choice not recognized');        
            end              
        else
            if strcmp(var4_choice,'Yp_real')
                %temp_MyVar_title = 'Priv. Output (log(Y_p))';
                temp_MyVar_title = 'log(Y_p)';
            elseif strcmp(var4_choice,'Ig_Itot')
                temp_MyVar_title = 'Govt. to Total Inv. (I_g / (I_g + I_p))';
            elseif strcmp(var4_choice,'Ip_Itot')
                temp_MyVar_title = 'Priv. to Total Inv. (I_p / (I_g + I_p))';
            elseif strcmp(var4_choice,'Ig_Y')
                %temp_MyVar_title = 'Govt. to GDP (I_g / Y)';
                temp_MyVar_title = 'I_g / Y';
            elseif strcmp(var4_choice,'Ig_less_def_Y')
                %temp_MyVar_title = 'Govt. to GDP (I_g / Y)';
                temp_MyVar_title = 'I_g_,_n_o_n_d_e_f / Y';                                
            elseif strcmp(var4_choice,'Ig_real')
                temp_MyVar_title = 'Govt. Inv. (log(I_g))';
            elseif strcmp(var4_choice,'Ip_real')
                %temp_MyVar_title = 'Priv. Total Inv. (log(I_p))';
                temp_MyVar_title = 'log(I_p)';
            elseif strcmp(var4_choice,'IPPrnd_real')
                %temp_MyVar_title = 'Priv. R&D Inv. (log(I_R_&_D))';
                temp_MyVar_title = 'log(I_R_&_D)';
            elseif strcmp(var4_choice,'labor_share_govt')
                %temp_MyVar_title = 'Govt. Labor Share (L_g / (L_g + L_p))';            
                temp_MyVar_title = 'L_g / (L_g + L_p)';            
            elseif strcmp(var4_choice,'labor_share_priv')
                %temp_MyVar_title = 'Private Labor Share (L_p / (L_g + L_p))';              
                temp_MyVar_title = 'L_p / (L_g + L_p)';              
            elseif strcmp(var4_choice,'labor_govt')
                %temp_MyVar_title = 'Govt. Labor (log(L_g))';            
                temp_MyVar_title = 'log(L_g)';            
            elseif strcmp(var4_choice,'labor_priv')
                %temp_MyVar_title = 'Private Labor (log(L_p))';
                temp_MyVar_title = 'log(L_p)';
            else
                error('var4_choice not recognized');        
            end    
        end
        
        eval(strcat('mytitle_',num2str(vvv),'=temp_MyVar_title;'));
        
    end % vvv

    % set size of figure so it fills page
    set(gcf, 'PaperPositionMode', 'manual');
    set(gcf, 'PaperUnits', 'inches');
    set(gcf, 'PaperPosition', [0 0 14.00 7.00]);            
    %set(gcf, 'PaperPosition', [0 0 7.00 3.50]); % 1x2 plot

    %IRF_length_plot = std_IRF_length_qtr+1;
    % per May 18 2019 call with max, change length of IRF to 20 
    % periods when comparing data vs model
    IRF_length_plot = std_IRF_length_qtr+1-4;    

    subplot(2,3,1); hold on; box on;
    plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
    plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_1.oirf_var4(1:IRF_length_plot), '-b', 'Linewidth', 2);
        plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_1.oirf_var4_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
        plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_1.oirf_var4_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);
    plot(0:IRF_length_plot-1, 100*model_IRF_vol_line_1(1:IRF_length_plot), ':r', 'Linewidth', 3);
    title(strcat('\fontsize{12}',mytitle_1),'FontWeight','normal');
    xlabel(' ');
    ylabel('Percent');               
    axis('tight');
    ylim(My_Ylims_c1);
          
    subplot(2,3,2); hold on; box on;
    plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
    plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_2.oirf_var4(1:IRF_length_plot), '-b', 'Linewidth', 2);
        plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_2.oirf_var4_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
        plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_2.oirf_var4_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);
    plot(0:IRF_length_plot-1, 100*model_IRF_vol_line_2(1:IRF_length_plot), ':r', 'Linewidth', 3);
    title(strcat('\fontsize{12}',mytitle_2),'FontWeight','normal');
    xlabel(' ');
    %ylabel(temp_MyVar_ylabel);               
    axis('tight');
    ylim(My_Ylims_c2);

    subplot(2,3,3); hold on; box on;
    plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
    h(1) = plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_3.oirf_var4(1:IRF_length_plot), '-b', 'Linewidth', 2);
        plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_3.oirf_var4_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
        plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_3.oirf_var4_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);
    h(2) = plot(0:IRF_length_plot-1, 100*model_IRF_vol_line_3(1:IRF_length_plot), ':r', 'Linewidth', 3);
    title(strcat('\fontsize{12}',mytitle_3),'FontWeight','normal');
    xlabel(' ');
    %ylabel(temp_MyVar_ylabel);               
    axis('tight');
    ylim(My_Ylims_c3);                  
    legend(h,'Data','Model','Location','northeast');
    clear h;

    subplot(2,3,4); hold on; box on;
    plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
    plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_4.oirf_var4(1:IRF_length_plot), '-b', 'Linewidth', 2);
        plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_4.oirf_var4_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
        plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_4.oirf_var4_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);
    plot(0:IRF_length_plot-1, 100*model_IRF_vol_line_4(1:IRF_length_plot), ':r', 'Linewidth', 3);
    title(strcat('\fontsize{12}',mytitle_4),'FontWeight','normal');
    xlabel(' ');
    ylabel('Percent');               
    axis('tight');
    ylim(My_Ylims_c4);
    
    subplot(2,3,5); hold on; box on;
    plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
    h(1) = plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_5.oirf_var4(1:IRF_length_plot), '-b', 'Linewidth', 2);
        plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_5.oirf_var4_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
        plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_5.oirf_var4_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);
    h(2) = plot(0:IRF_length_plot-1, 100*model_IRF_vol_line_5(1:IRF_length_plot), ':r', 'Linewidth', 3);
    title(strcat('\fontsize{12}',mytitle_5),'FontWeight','normal');
    xlabel(' ');
    %ylabel(temp_MyVar_ylabel);               
    axis('tight');
    ylim(My_Ylims_c5);   
    %legend(h,'Data','Model','FontSize',14,'Position',[0.75 0.25 0.08 0.1]);
    clear h;
    
    subplot(2,3,6); hold on; box on;
    plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
    h(1) = plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_6.oirf_var4(1:IRF_length_plot), '-b', 'Linewidth', 2);
        plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_6.oirf_var4_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
        plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_6.oirf_var4_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);
    h(2) = plot(0:IRF_length_plot-1, 100*model_IRF_vol_line_6(1:IRF_length_plot), ':r', 'Linewidth', 3);
    title(strcat('\fontsize{12}',mytitle_6),'FontWeight','normal');
    xlabel(' ');
    %ylabel(temp_MyVar_ylabel);               
    axis('tight');
    ylim(My_Ylims_c6);       
    
    % save jpg        
    saveas(1,strcat('figures/',fname),'png')
    saveas(1,strcat('figures/',fname)) 
    %saveas(1,strcat('output_for_paper/Figures/',fname),'png')
    %saveas(1,strcat('output_for_paper/Figures/',fname))                     
    %close(1)                           


end % ccc ccvarlist
end % mmm modnum_list   



%% create 1x1 figure that compares model vs 4-variable data VAR for a
%  single var4 choice

clc;

% panel titles option
% option for panel titles to use H and L
%alt_panel_titles= 0;
alt_panel_titles= 1;

%ccvarlist = {'none'};
ccvarlist = {'baa10ym'};
%ccvarlist = {'none'; 'baa10ym';'aaa10ym'};

% var4 set
%var_set = {'Ig_Y';'IPPrnd_real';'Ip_real';'labor_share_govt';'Yp_real'}; 
%var_set = {'Ig_Y';'IPPrnd_real';'Ip_real';'labor_share_govt';'labor_priv';'Yp_real'}; 
var_set = {'Itot_real'};
My_Ylims_c1 = [-2.0, 2.0];   

% VAR specs choice
%myVARspec = 'hpfilter';
myVARspec = 'bandpass';
%myVARspec = 'levels';

modnum_list = [81];
% 81 = Benchmark govt (endogenous investment L sector)
% 82 = EGI
% 83 = EGE, which has weaker reallocation because deltaG=100%
%modnum_list = [93,94]; % alternate cals we explore in october 2020
%modnum_list = [96,97]; % alternate cals we explore in october 2020
%modnum_list = [135];

for mmm = 1:length(modnum_list)
% modnum choice
%my_modnum = 3;
%my_modnum = 51;
%my_modnum = 54;
%my_modnum = 64;
%my_modnum = 81;
my_modnum = modnum_list(mmm);

for ccc = 1:length(ccvarlist)
  
 % cc control var
 myccvar = char(ccvarlist{ccc});
    
 % compute IRFs for different var4 choices
 for vvv = 1:length(var_set)

    %myVARspec = char(VARspecs{vvv});
    var4_choice = var_set{vvv} ;
     
    % figure out starting and ending positions
    sample_start_year = 1972;
    sample_end_year   = 2016;     
    if strcmp(myVARspec,'levels')
        pos_start_macro  = find((data_macro_qtr.year>=sample_start_year),1,'first');        
    else % need extra period for filtering        
        pos_start_macro = find((data_macro_qtr.year>=sample_start_year),1,'first') - 1; 
    end    
    pos_end_macro   = find((data_macro_qtr.year<=sample_end_year),1,'last');
    pos_start_invreg = find((data_inv_reg_qtr.year>=sample_start_year),1,'first');        
    pos_end_invreg   = find((data_inv_reg_qtr.year<=sample_end_year),1,'last');  
    disp(char(strcat({'macro var data from '},num2str(data_macro_qtr.year(pos_start_macro)),'q',num2str(data_macro_qtr.qtr(pos_start_macro)))))
    disp(char(strcat({'macro var data to '},  num2str(data_macro_qtr.year(pos_end_macro)),  'q',num2str(data_macro_qtr.qtr(pos_end_macro)))))
    disp(char(strcat({'inv reg data from '},num2str(data_inv_reg_qtr.year(pos_start_invreg)),'q',num2str(data_inv_reg_qtr.qtr(pos_start_invreg)))))
    disp(char(strcat({'inv reg data to '},num2str(data_inv_reg_qtr.year(pos_end_invreg)),'q',num2str(data_inv_reg_qtr.qtr(pos_end_invreg)))))    
    
    % first three variables from investment regression
    if strcmp(myVARspec,'levels')
        var1 = data_macro_qtr.tfp( pos_start_macro:pos_end_macro); % tfp in levels
    else
        var1 = data_macro_qtr.dtfp( pos_start_macro+1:pos_end_macro)/4; % dtfp from macro data. need to convert back to quarterly rates from annualized rate
        %var1_chk = data_inv_reg_qtr.dtfp( pos_start_invreg:pos_end_invreg); % dtfp from inv reg data
        %chk_diff = abs(var1 - var1_chk);
        %max(chk_diff)
        %[var1, var1_chk]
    end
    var2 = data_inv_reg_qtr.x( pos_start_invreg:pos_end_invreg);
    var3 = data_inv_reg_qtr.expvol( pos_start_invreg:pos_end_invreg);
    
    % 4th variable that may be filtered depending myVARspec
    eval(strcat('var4_raw_qtr = data_macro_qtr.',var4_choice,';'));
    var4_trunc = var4_raw_qtr(pos_start_macro:pos_end_macro); % truncated series to match other series
    if strcmp(myVARspec,'levels') % simply compute in log levels
        temp_var4_qtr = log(var4_trunc); 
    else % de-trend 4th variable 
        
        temp_var4_qtr = nan(size(var4_trunc));

        % HP filter. use pos_start+1 because no need to take first differences
        if strcmp(myVARspec,'hpfilter')            
            raw_var4_qtr     = log(var4_trunc(2:end));
            smooth_var4_qtr  = hpfilter(raw_var4_qtr, 1600); % quarterly data smoothing 
            temp_var4_qtr    = raw_var4_qtr - smooth_var4_qtr;
        end   
        
        % Comin Gertler (2006) band-pass
        % The function is bandpass(X,pl,pu). X is the raw data, pl and pu is the range of frequencies we want to extract. 
        % Recommended by Comin and Gertler (attached below), we should choose pl = 2 and pu = 200 for the quarterly data 
        % to extract the medium-term cycles. 
        if strcmp(myVARspec,'bandpass')  
            size(var4_trunc);
            raw_var4_qtr = log(var4_trunc(2:end)); % no reduction in size from bandpass --> need to cut first obs for VAR
            temp_var4_qtr = bandpass(raw_var4_qtr, 2, 200);
            size(temp_var4_qtr); % no reduction in size from bandpass                                
        end  
        
    end

    % series to enter VAR in levels 
    if strcmp(var4_choice,'Ig_Itot') ...
    || strcmp(var4_choice,'Ip_Itot') ...
    || strcmp(var4_choice,'Ig_Y') ...
    || strcmp(var4_choice,'labor_share_govt') ...
    || strcmp(var4_choice,'labor_share_priv') 
        var4 = exp(temp_var4_qtr);
    else
        var4 = temp_var4_qtr; % keep in logs
    end    
    
    % endogenous vars matrix
    temp_y_qtr = [var1, var2, var3, var4];
 
    % exogenous vars matrix
    temp_x_qtr = ones(size(temp_y_qtr,1),1);
    if ~strcmp(myccvar, 'none')
        eval(strcat('ccvar_raw_qtr = data_macro_qtr.',myccvar,';'));
        if strcmp(myVARspec,'levels') 
            temp_ccvar_qtr = ccvar_raw_qtr(pos_start_macro:pos_end_macro);
        else
            temp_ccvar_qtr = ccvar_raw_qtr(pos_start_macro+1:pos_end_macro);
        end
        temp_x_qtr = [temp_x_qtr, temp_ccvar_qtr];        
    end      

    eval(strcat('y_qtr_',num2str(vvv),' = temp_y_qtr;'));
    eval(strcat('x_exo_qtr_',num2str(vvv),' = temp_x_qtr;'));

    clear var4_raw_qtr var4_trunc temp_var4_qtr temp_y_qtr temp_x_qtr

    % define different shock matrices

        std_IRF_length_qtr = 24;

        % 1-std dtfp shock
        std_dtfp_shk_mat_qtr      = zeros(4 , std_IRF_length_qtr);
        std_dtfp_shk_mat_qtr(1,1) = 1;            

        % 1-std ivol shock
        std_ivol_shk_mat_qtr      = zeros(4 , std_IRF_length_qtr);
        std_ivol_shk_mat_qtr(3,1) = 1;             

        % compute IRFs for ivol shk
        eval(strcat('IRFout_ivolshk_qtr_',num2str(vvv),' = gen_IRF_vectors_dataVAR_nvars( y_qtr_',num2str(vvv),', x_exo_qtr_',num2str(vvv),', [], std_ivol_shk_mat_qtr, 0);'));

 end % vvv var4 list

 % generate IRF vectors from the model

    %my_modnum = modnumlist(mmm);

    % single unit impulse to exp(vol)

        std_IRF_length_qtr = 24;

        % std volatility level shock
        vol_shk_lev_mat_qtr      = zeros(2 , std_IRF_length_qtr);
        vol_shk_lev_mat_qtr(2,1) = log( std(data_inv_reg_qtr.expvol)+1 ); % log shock val to get 1-std dev in level of vol
        % NOTE: ex removed as shock in BCLR EndoGrowth

        % std tfp shock. note that TFP growth in the data VAR is in log
        % units according to Wenxi
        tfp_val_shk_mat_qtr      = zeros(2 , std_IRF_length_qtr);
        tfp_val_shk_mat_qtr(1,1) = std(data_inv_reg_qtr.dtfp); % shock val to log TFP growth

        disp(char(strcat({'Computing IRFs for model '},num2str(my_modnum),{'...'})));

        % compute irfs for 1-unit vol shock and 1-unit tfp shock

            model_IRFout_1unit_tfp_qtr = gen_IRF_vectors_model( my_modnum, [], [], 'lev', tfp_val_shk_mat_qtr);
            model_IRFout_1unit_vol_qtr = gen_IRF_vectors_model( my_modnum, [], [], 'lev', vol_shk_lev_mat_qtr);

         % save IRF vectors
         for vvv = 1:length(var_set)    
            var4_choice = var_set{vvv} ;
            if strcmp(var4_choice,'Yp_real')
                temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_logYp;
                temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_logYp;                                                            
            elseif strcmp(var4_choice,'Ig_Itot')
                temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_Ig_Itot;
                temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_Ig_Itot;                                           
            elseif strcmp(var4_choice,'Ip_Itot')
                temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_Ip_Itot;
                temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_Ip_Itot;            
            elseif strcmp(var4_choice,'Ig_Y')
                temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_Ig_Y;
                temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_Ig_Y;       
            elseif strcmp(var4_choice,'IPPrnd_real')
                temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_logIPPrnd;
                temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_logIPPrnd;            
            elseif strcmp(var4_choice,'Ig_real')
                temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_logIg;
                temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_logIg;                        
            elseif strcmp(var4_choice,'Ip_real')
                temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_logIp;
                temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_logIp;  
            elseif strcmp(var4_choice,'Itot_real')
                temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_logItot;
                temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_logItot;                 
            elseif strcmp(var4_choice,'labor_share_govt')
                temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_ncnt;
                temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_ncnt;          
            elseif strcmp(var4_choice,'labor_share_priv')
                temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_npnt;
                temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_npnt;                 
            elseif strcmp(var4_choice,'labor_govt')
                temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_nc; % already in logs
                temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_nc; % already in logs
            elseif strcmp(var4_choice,'labor_priv')
                temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_np; % already in logs
                temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_np; % already in logs
            else
                error('var4_choice not recognized');
            end
            
            eval(strcat('model_IRF_vol_line_',num2str(vvv),' = temp_model_IRF_vol_line;'));
         end % vvv
            
        disp(char(strcat({'Done computing model IRFs!'})));
 

% create the 1x1 figure
close ALL;
figure(1);

    if alt_panel_titles==1
        fname = strcat('IRFs_OnlyVol_data_',myVARspec,'_control_',myccvar,'_vs_model_alt_panel_titles_',num2str(my_modnum),'_1x1_',char(var_set{1}));    
    else
        fname = strcat('IRFs_OnlyVol_data_',myVARspec,'_control_',myccvar,'_vs_model_',num2str(my_modnum),'_1x1_',char(var_set{1}));    
    end

    % set size of figure so it fills page
    set(gcf, 'PaperPositionMode', 'manual');
    set(gcf, 'PaperUnits', 'inches');
    %set(gcf, 'PaperPosition', [0 0 14.00 7.00]);            
    %set(gcf, 'PaperPosition', [0 0 7.00 3.50]); % 1x2 plot
    set(gcf, 'PaperPosition', [0 0 3.50 3.50]); % 1x1 plot
    
    %subplot(2,4,3); hold on; box on;
    hold on; box on;
    plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
    h(1) = plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_1.oirf_var4(1:IRF_length_plot), '-b', 'Linewidth', 2);
        plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_1.oirf_var4_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
        plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_1.oirf_var4_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);
    h(2) = plot(0:IRF_length_plot-1, 100*model_IRF_vol_line_1(1:IRF_length_plot), ':r', 'Linewidth', 3);
    if strcmp(var_set{1}, 'Itot_real')
        title(strcat('\fontsize{12}','log(I_p+I_g)'),'FontWeight','normal');
    else
        title(strcat('\fontsize{12}',mytitle_1),'FontWeight','normal');
    end
    
    xlabel(' ');
    %ylabel(temp_MyVar_ylabel);               
    ylabel('Percent'); 
    axis('tight');
    ylim(My_Ylims_c1);                  
    legend(h,'Data','Model','Location','northeast');
    clear h;
   
    % save jpg        
    saveas(1,strcat('figures/',fname),'png')
    saveas(1,strcat('figures/',fname)) 
    %saveas(1,strcat('output_for_paper/Figures/',fname),'png')
    %saveas(1,strcat('output_for_paper/Figures/',fname))                     
    %close(1)                      

end % ccc ccvarlist
end % mmm modnum_list   



%% create 1x2 figure that compares models vs 4-variable data VAR
%  for private output 

clc;

% cc control var
%ccvarlist = {'none'};
ccvarlist = {'baa10ym'};
%ccvarlist = {'none'; 'baa10ym';'aaa10ym'};
ccc = 1;
myccvar = char(ccvarlist{ccc});

% var4 choice set
var4_choice = 'Yp_real';
My_Ylims_1 = [-1,0.5];
My_Ylims_2 = [-1,0.5];

% VAR specs for panels 1, 2, 3, and 4
%VARspecs = {'bandpass','bandpass','bandpass','bandpass'}; % 
myVARspec = 'bandpass';

% models for panels 1, 2, 3, and 4
%modnumlist = [51, 54, 51, 54];
modnumlist = [82, 83];
%modnumlist = [137, 83];
%modnumlist = [130, 131];
%modnumlist = [148, 149];
mytitle_1 = 'EGI';    
mytitle_2 = 'EGE';

% compute IRF for data VAR
     
    vvv=1;

    % figure out starting and ending positions
    sample_start_year = 1972;
    sample_end_year   = 2016;     
    if strcmp(myVARspec,'levels')
        pos_start_macro  = find((data_macro_qtr.year>=sample_start_year),1,'first');        
    else % need extra period for filtering        
        pos_start_macro = find((data_macro_qtr.year>=sample_start_year),1,'first') - 1; 
    end    
    pos_end_macro   = find((data_macro_qtr.year<=sample_end_year),1,'last');
    pos_start_invreg = find((data_inv_reg_qtr.year>=sample_start_year),1,'first');        
    pos_end_invreg   = find((data_inv_reg_qtr.year<=sample_end_year),1,'last');  
    disp(char(strcat({'macro var data from '},num2str(data_macro_qtr.year(pos_start_macro)),'q',num2str(data_macro_qtr.qtr(pos_start_macro)))))
    disp(char(strcat({'macro var data to '},  num2str(data_macro_qtr.year(pos_end_macro)),  'q',num2str(data_macro_qtr.qtr(pos_end_macro)))))
    disp(char(strcat({'inv reg data from '},num2str(data_inv_reg_qtr.year(pos_start_invreg)),'q',num2str(data_inv_reg_qtr.qtr(pos_start_invreg)))))
    disp(char(strcat({'inv reg data to '},num2str(data_inv_reg_qtr.year(pos_end_invreg)),'q',num2str(data_inv_reg_qtr.qtr(pos_end_invreg)))))    
    
    % first three variables from investment regression
    if strcmp(myVARspec,'levels')
        var1 = data_macro_qtr.tfp( pos_start_macro:pos_end_macro); % tfp in levels
    else
        var1 = data_macro_qtr.dtfp( pos_start_macro+1:pos_end_macro)/4; % dtfp from macro data. need to convert back to quarterly rates from annualized rate
        %var1_chk = data_inv_reg_qtr.dtfp( pos_start_invreg:pos_end_invreg); % dtfp from inv reg data
        %chk_diff = abs(var1 - var1_chk);
        %max(chk_diff)
        %[var1, var1_chk]
    end
    var2 = data_inv_reg_qtr.x( pos_start_invreg:pos_end_invreg);
    var3 = data_inv_reg_qtr.expvol( pos_start_invreg:pos_end_invreg);
    
    % 4th variable that may be filtered depending myVARspec
    eval(strcat('var4_raw_qtr = data_macro_qtr.',var4_choice,';'));
    var4_trunc = var4_raw_qtr(pos_start_macro:pos_end_macro); % truncated series to match other series
    if strcmp(myVARspec,'levels') % simply compute in log levels
        temp_var4_qtr = log(var4_trunc); 
    else % de-trend 4th variable 
        
        temp_var4_qtr = nan(size(var4_trunc));

        % HP filter. use pos_start+1 because no need to take first differences
        if strcmp(myVARspec,'hpfilter')            
            raw_var4_qtr     = log(var4_trunc(2:end));
            smooth_var4_qtr  = hpfilter(raw_var4_qtr, 1600); % quarterly data smoothing 
            temp_var4_qtr    = raw_var4_qtr - smooth_var4_qtr;
        end   
        
        % Comin Gertler (2006) band-pass
        % The function is bandpass(X,pl,pu). X is the raw data, pl and pu is the range of frequencies we want to extract. 
        % Recommended by Comin and Gertler (attached below), we should choose pl = 2 and pu = 200 for the quarterly data 
        % to extract the medium-term cycles. 
        if strcmp(myVARspec,'bandpass')  
            size(var4_trunc);
            raw_var4_qtr = log(var4_trunc(2:end)); % no reduction in size from bandpass --> need to cut first obs for VAR
            temp_var4_qtr = bandpass(raw_var4_qtr, 2, 200);
            size(temp_var4_qtr); % no reduction in size from bandpass                                
        end  
        
    end
   
    % series to enter VAR in levels 
    if strcmp(var4_choice,'Ig_Itot') ...
    || strcmp(var4_choice,'Ip_Itot') ...
    || strcmp(var4_choice,'Ig_Y') ...
    || strcmp(var4_choice,'labor_share_govt') ...
    || strcmp(var4_choice,'labor_share_priv') 
        var4 = exp(temp_var4_qtr)
    else
        var4 = temp_var4_qtr; % keep in logs
    end    
    
    % endogenous vars matrix
    temp_y_qtr = [var1, var2, var3, var4];
 
    % exogenous vars matrix
    temp_x_qtr = ones(size(temp_y_qtr,1),1);
    if ~strcmp(myccvar, 'none')
        eval(strcat('ccvar_raw_qtr = data_macro_qtr.',myccvar,';'));
        if strcmp(myVARspec,'levels') 
            temp_ccvar_qtr = ccvar_raw_qtr(pos_start_macro:pos_end_macro);
        else
            temp_ccvar_qtr = ccvar_raw_qtr(pos_start_macro+1:pos_end_macro);
        end
        temp_x_qtr = [temp_x_qtr, temp_ccvar_qtr];        
    end      

    eval(strcat('y_qtr_',num2str(vvv),' = temp_y_qtr;'));
    eval(strcat('x_exo_qtr_',num2str(vvv),' = temp_x_qtr;'));

    clear var4_raw_qtr var4_trunc temp_var4_qtr temp_y_qtr temp_x_qtr

    % define different shock matrices

        std_IRF_length_qtr = 24;

        % 1-std dtfp shock
        std_dtfp_shk_mat_qtr      = zeros(4 , std_IRF_length_qtr);
        std_dtfp_shk_mat_qtr(1,1) = 1;            

        % 1-std ivol shock
        std_ivol_shk_mat_qtr      = zeros(4 , std_IRF_length_qtr);
        std_ivol_shk_mat_qtr(3,1) = 1;             

        % compute IRFs for ivol shk
        eval(strcat('IRFout_ivolshk_qtr_',num2str(vvv),' = gen_IRF_vectors_dataVAR_nvars( y_qtr_',num2str(vvv),', x_exo_qtr_',num2str(vvv),', [], std_ivol_shk_mat_qtr, 0);'));

 % generate IRF vectors from the models
 for mmm = 1:length(modnumlist)   

    temp_modnum = modnumlist(mmm);

    % single unit impulse to exp(vol)

        std_IRF_length_qtr = 24;

        % std volatility level shock
        vol_shk_lev_mat_qtr      = zeros(2 , std_IRF_length_qtr);
        vol_shk_lev_mat_qtr(2,1) = log( std(data_inv_reg_qtr.expvol)+1 ); % log shock val to get 1-std dev in level of vol
        % NOTE: ex removed as shock in BCLR EndoGrowth

        % std tfp shock. note that TFP growth in the data VAR is in log
        % units according to Wenxi
        tfp_val_shk_mat_qtr      = zeros(2 , std_IRF_length_qtr);
        tfp_val_shk_mat_qtr(1,1) = std(data_inv_reg_qtr.dtfp); % shock val to log TFP growth

        disp(char(strcat({'Computing IRFs for model '},num2str(temp_modnum),{'...'})));

        % compute irfs for 1-unit vol shock and 1-unit tfp shock

            model_IRFout_1unit_tfp_qtr = gen_IRF_vectors_model( temp_modnum, [], [], 'lev', tfp_val_shk_mat_qtr);
            model_IRFout_1unit_vol_qtr = gen_IRF_vectors_model( temp_modnum, [], [], 'lev', vol_shk_lev_mat_qtr);

            % save IRF vector         
            if strcmp(var4_choice,'Yp_real')
                temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_logYp;
                temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_logYp;                                                                 
            elseif strcmp(var4_choice,'Y_real')
                temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_logY;
                temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_logY;                                                            
            else
                error('var4_choice not recognized above');
            end                  
            eval(strcat('model_IRF_vol_line_',num2str(mmm),' = temp_model_IRF_vol_line;'));
            
        disp(char(strcat({'Done computing model IRFs!'})));
 
 end % mmm modnumlist
 
% create the 1x2 figure
close ALL
figure(1);

    %fname = strcat('IRFs_OnlyVol_data_vs_model_',var4_choice,'_control_',myccvar,'_1x2_',char(VARspecs{1}),'_',num2str(modnumlist(1)),'_vs_',num2str(modnumlist(2)));    
    fname = strcat('IRFs_OnlyVol_data_vs_model_',var4_choice,'_control_',myccvar,'_1x2_',char(myVARspec),'_',num2str(modnumlist(1)),'_vs_',num2str(modnumlist(2)));    

    % y label
    %for vvv = 1:length(var4_choice_set)
    if strcmp(var4_choice,'Yp_real')
        MyVar_ylabel = texlabel('log(Y_p)');
    elseif strcmp(var4_choice,'Y_real')
        MyVar_ylabel = texlabel('log(GDP)');
    else
        error('var4_choice not recognized above');
    end  
   

    % set size of figure so it fills page
    set(gcf, 'PaperPositionMode', 'manual');
    set(gcf, 'PaperUnits', 'inches');
    %set(gcf, 'PaperPosition', [0 0 14.00 7.00]);            
    set(gcf, 'PaperPosition', [0 0 7.00 3.50]); % 1x2 plot

    %IRF_length_plot = std_IRF_length_qtr+1;
    % per May 18 2019 call with max, change length of IRF to 20 
    % periods when comparing data vs model
    IRF_length_plot = std_IRF_length_qtr+1-4;    

    subplot(1,2,1); hold on; box on;
    plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
    plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_1.oirf_var4(1:IRF_length_plot), '-b', 'Linewidth', 2);
        plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_1.oirf_var4_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
        plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_1.oirf_var4_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);
    plot(0:IRF_length_plot-1, 100*model_IRF_vol_line_1(1:IRF_length_plot), ':r', 'Linewidth', 3);
    title(strcat('\fontsize{12}',mytitle_1),'FontWeight','normal');
    xlabel(' ');
    ylabel(MyVar_ylabel);               
    axis('tight');
    ylim(My_Ylims_1);
         
    subplot(1,2,2); hold on; box on;
    plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
    h(1) = plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_1.oirf_var4(1:IRF_length_plot), '-b', 'Linewidth', 2);
        plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_1.oirf_var4_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
        plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_1.oirf_var4_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);
    h(2) = plot(0:IRF_length_plot-1, 100*model_IRF_vol_line_2(1:IRF_length_plot), ':r', 'Linewidth', 3);
    title(strcat('\fontsize{12}',mytitle_2),'FontWeight','normal');
    xlabel(' ');
    %ylabel(temp_MyVar_ylabel);               
    axis('tight');
    ylim(My_Ylims_2);
    legend(h,'Data','Model','Location','northeast');
    clear h;
    
    % save jpg        
    saveas(1,strcat('figures/',fname),'png')
    saveas(1,strcat('figures/',fname)) 
    %saveas(1,strcat('output_for_paper/Figures/',fname),'png')
    %saveas(1,strcat('output_for_paper/Figures/',fname))                     
    %close(1)                           


%% create 1x2 figure that compares different IRFs from same
%  VAR specification across two ANNUAL variables but only
%  for the 4-variable VAR

clc;

% cc control var
%ccvarlist = {'none'};
ccvarlist = {'baa10ym'};
%ccvarlist = {'none'; 'baa10ym';'aaa10ym'};
ccc = 1;
myccvar = char(ccvarlist{ccc});

% VAR specs for columns 1, 2, and 3
%VARspecs = {'hpfilter','bandpass','levels'}; % 
VARspecs = {'levels'}; % 
%VARorder = 1;
%VARorder = 2;
VARorder_list = [1,2];

% set of two variables to use as var4 (first one in top row of IRF figure,
% second in bottom row)
%var4_choice_set = {'total_iss_usa','agg_pat_val_sm'};
var4_choice_set = {'total_app_usa','agg_pat_val_sm'};

% total_iss_usa has data from 1963--2016
% agg_pat_val_sm has data from 1929--2010
% eearliest start year is 1961 because first year of inv reg data

    % longest possible periods for {'total_iss_usa','agg_pat_val_sm'}
    startyr1 = 1963
    endyr1   = 2016
    startyr2 = 1961
    endyr2   = 2010

% loop across last var choices
for ooo = 1:length(VARorder_list)
 VARorder = VARorder_list(ooo);  
  panelnum=0; % start index at zero
  for aaa = 1:length(var4_choice_set)
    
    % get var4 name
    var4_choice = char(var4_choice_set{aaa});
    disp(strcat('var4_choice',num2str(aaa),'=',var4_choice));
    
    % get var4 year range
    eval(strcat('sample_start_year = startyr',num2str(aaa),';'));
    eval(strcat('sample_end_year   = endyr',num2str(aaa),';'));    
    
    % make sure we have the right annual data from investment regs
    if sample_start_year>=1969 & sample_start_year<=1971
        load data_inv_reg_ann_1969_2016   
    elseif sample_start_year>=1972              
        load data_inv_reg_ann_1972_2016                           
    elseif sample_start_year<=1968                     
        load data_inv_reg_ann_1961_2016                   
    else
        error('sample_start_year not accounted for above');
    end    
    
    % compute IRFs for data VARs for 4-variable VAR
    for vvv = 1:length(VARspecs)
    %vvv=1

        panelnum=panelnum+1; % count through panels
        myVARspec = char(VARspecs{vvv});

        % figure out starting and ending positions
        %sample_start_year = 1961;
        %sample_end_year   = 2016;     
        if strcmp(myVARspec,'levels')
            pos_start_macro  = find((data_macro_ann.year>=sample_start_year),1,'first');        
        else % need extra period for filtering        
            pos_start_macro = find((data_macro_ann.year>=sample_start_year),1,'first') - 1; 
        end    
        pos_end_macro   = find((data_macro_ann.year<=sample_end_year),1,'last');
        pos_start_invreg = find((data_inv_reg_ann.year>=sample_start_year),1,'first');        
        pos_end_invreg   = find((data_inv_reg_ann.year<=sample_end_year),1,'last');  
        disp(char(strcat({'macro var data from '},num2str(data_macro_ann.year(pos_start_macro)))));
        disp(char(strcat({'macro var data to '},  num2str(data_macro_ann.year(pos_end_macro)))));
        disp(char(strcat({'inv reg data from '},num2str(data_inv_reg_ann.year(pos_start_invreg)))));
        disp(char(strcat({'inv reg data to '},num2str(data_inv_reg_ann.year(pos_end_invreg)))));

        % first three variables from investment regression
        if strcmp(myVARspec,'levels')
            var1 = data_macro_ann.tfp( pos_start_macro:pos_end_macro); % tfp in levels
        else
            var1 = data_macro_ann.dtfp( pos_start_macro+1:pos_end_macro); % dtfp from macro data
            %var1_chk = data_inv_reg_ann.dtfp( pos_start_invreg:pos_end_invreg); % dtfp from inv reg data
            %chk_diff = abs(var1 - var1_chk);
            %max(chk_diff)
            %[var1, var1_chk]
        end
        var2 = data_inv_reg_ann.x( pos_start_invreg:pos_end_invreg);
        var3 = data_inv_reg_ann.expvol( pos_start_invreg:pos_end_invreg);

        % 4th variable that may be filtered depending myVARspec
        eval(strcat('var4_raw = data_macro_ann.',var4_choice,';'));
        var4_trunc = var4_raw(pos_start_macro:pos_end_macro); % truncated series to match other series
        if strcmp(myVARspec,'levels') % simply compute in log levels
            temp_var4_ann = log(var4_trunc); 
        else % de-trend 4th variable 

            temp_var4_ann = nan(size(var4_trunc));

            % HP filter. use pos_start+1 because no need to take first differences
            if strcmp(myVARspec,'hpfilter')            
                raw_var4_ann     = log(var4_trunc(2:end));
                smooth_var4_ann  = hpfilter(raw_var4_ann, 1600); % quarterly data smoothing 
                temp_var4_ann    = raw_var4_ann - smooth_var4_ann;
            end   

            % Comin Gertler (2006) band-pass
            % The function is bandpass(X,pl,pu). X is the raw data, pl and pu is the range of frequencies we want to extract. 
            % Recommended by Comin and Gertler (attached below), we should choose pl = 2 and pu = 200 for the quarterly data 
            % to extract the medium-term cycles. 
            if strcmp(myVARspec,'bandpass')  
                size(var4_trunc);
                raw_var4_ann = log(var4_trunc(2:end)); % no reduction in size from bandpass --> need to cut first obs for VAR
                temp_var4_ann = bandpass(raw_var4_ann, 2, 200);
                size(temp_var4_ann); % no reduction in size from bandpass                                
            end  

        end

        % series to enter VAR in levels 
        if strcmp(var4_choice,'Ig_Itot') ...
        || strcmp(var4_choice,'Ip_Itot') ...
        || strcmp(var4_choice,'Ig_Y') ...
        || strcmp(var4_choice,'labor_share_govt') ...
        || strcmp(var4_choice,'labor_share_priv') 
            var4 = exp(temp_var4_ann)
        else
            var4 = temp_var4_ann; % keep in logs
        end    

        % endogenous vars matrix
        temp_y_ann = [var1, var2, var3, var4];

        % exogenous vars matrix
        temp_x_ann = ones(size(temp_y_ann,1),1);
        if ~strcmp(myccvar, 'none')
            eval(strcat('ccvar_raw_ann = data_macro_ann.',myccvar,';'));
            if strcmp(myVARspec,'levels') 
                temp_ccvar_ann = ccvar_raw_ann(pos_start_macro:pos_end_macro);
            else
                temp_ccvar_ann = ccvar_raw_ann(pos_start_macro+1:pos_end_macro);
            end
            temp_x_ann = [temp_x_ann, temp_ccvar_ann];        
        end      

        % define different shock matrices

            std_IRF_length_ann = 6;

            % 1-std dtfp shock
            std_dtfp_shk_mat_ann      = zeros(4 , std_IRF_length_ann);
            std_dtfp_shk_mat_ann(1,1) = 1;            

            % 1-std ivol shock
            std_ivol_shk_mat_ann      = zeros(4 , std_IRF_length_ann);
            std_ivol_shk_mat_ann(3,1) = 1;             

            % compute IRFs for ivol shk
            if VARorder==1 
                temp_IRFOUT = gen_IRF_vectors_dataVAR_nvars( temp_y_ann, temp_x_ann, [], std_ivol_shk_mat_ann, 0);
            elseif VARorder==2
                temp_IRFOUT = gen_IRF_vectors_dataVAR2_nvars( temp_y_ann, temp_x_ann, [], std_ivol_shk_mat_ann, 0);
            else
                error('VARorder not specified');
            end
            %eval(strcat('IRFout_ivolshk_4var_ann_',num2str(vvv),' = temp_IRFOUT;'));
            eval(strcat('IRFout_ivolshk_4var_ann_',num2str(panelnum),' = temp_IRFOUT;'));
            
        % clean up
        clear var4_raw_ann var4_trunc temp_var4_ann temp_y_ann temp_x_ann

    end % vvv myVARspec list
    
    % y labels
    temp_MyVar_ylabel = texlabel('Percent');
    %if strcmp(var4_choice,'Yp_real')
    %    temp_MyVar_ylabel = texlabel('log(Y_p)');
    %end     
    eval(strcat('MyVar_ylabel_',num2str(aaa),'=temp_MyVar_ylabel;'));    
    
    % y axis lims
%     if aaa==1        
%         temp_low1 = IRFout_ivolshk_4var_ann_1.oirf_var4_ciL(1:IRF_length_plot);
%         temp_low2 = IRFout_ivolshk_4var_ann_2.oirf_var4_ciL(1:IRF_length_plot);
%         temp_low3 = IRFout_ivolshk_4var_ann_3.oirf_var4_ciL(1:IRF_length_plot);
%         temp_high1 = IRFout_ivolshk_4var_ann_1.oirf_var4_ciU(1:IRF_length_plot);
%         temp_high2 = IRFout_ivolshk_4var_ann_2.oirf_var4_ciU(1:IRF_length_plot);
%         temp_high3 = IRFout_ivolshk_4var_ann_3.oirf_var4_ciU(1:IRF_length_plot);        
%         temp_min_low  = min([ temp_low1,  temp_low2,  temp_low3]);
%         temp_min_high = max([temp_high1, temp_high2, temp_high3]);
%         My_Ylims_row1 = [floor(100*temp_min_low),ceil(100*temp_min_high)];
%     elseif aaa==2
%         temp_low1 = IRFout_ivolshk_4var_ann_4.oirf_var4_ciL(1:IRF_length_plot);
%         temp_low2 = IRFout_ivolshk_4var_ann_5.oirf_var4_ciL(1:IRF_length_plot);
%         temp_low3 = IRFout_ivolshk_4var_ann_6.oirf_var4_ciL(1:IRF_length_plot);
%         temp_high1 = IRFout_ivolshk_4var_ann_4.oirf_var4_ciU(1:IRF_length_plot);
%         temp_high2 = IRFout_ivolshk_4var_ann_5.oirf_var4_ciU(1:IRF_length_plot);
%         temp_high3 = IRFout_ivolshk_4var_ann_6.oirf_var4_ciU(1:IRF_length_plot);        
%         temp_min_low  = min([ temp_low1,  temp_low2,  temp_low3]);
%         temp_min_high = max([temp_high1, temp_high2, temp_high3]);
%         My_Ylims_row2 = [floor(100*temp_min_low),ceil(100*temp_min_high)];        
%     else
%         error('aaa not recognized');
%     end
    
      

  end % aaa var4_choice_set

  
    % create the 1x2 figure
    close ALL
    figure(1);

        fname = strcat('IRFs_OnlyVol_VAR',num2str(VARorder),'_4var_ann_',var4_choice_set{1},'_from_',num2str(startyr1),'_to_',num2str(endyr1),'_',var4_choice_set{2},'_from_',num2str(startyr2),'_to_',num2str(endyr2),'_control_',myccvar,'_1x2_',char(VARspecs{1}));    

        % panel titles
        for aaa = 1:length(var4_choice_set)
            myvar = char(var4_choice_set{aaa});    
            if strcmp(myvar,'total_iss_usa')
                %temp_mytitle = 'Number of Patents Granted';
                temp_mytitle = 'Number of Patents';
            elseif strcmp(myvar,'total_app_usa') 
                %temp_mytitle = 'Number of Patent Applications';
                temp_mytitle = 'Number of Patents';
            elseif strcmp(myvar,'agg_pat_val_sm')
                %temp_mytitle = 'Value of Patents Granted';
                temp_mytitle = 'Value of Patents';
            else
                error('myvar not recognized');
            end
            eval(strcat('mytitle_',num2str(aaa),'=temp_mytitle;'));
        end      

        % set size of figure so it fills page
        set(gcf, 'PaperPositionMode', 'manual');
        set(gcf, 'PaperUnits', 'inches');
        %set(gcf, 'PaperPosition', [0 0 14.00 7.00]);            
        set(gcf, 'PaperPosition', [0 0 7.00 3.50]); % 1x2 plot

        %IRF_length_plot = std_IRF_length_qtr+1;
        % per May 18 2019 call with max, change length of IRF to 20 
        % periods when comparing data vs model
        IRF_length_plot = std_IRF_length_ann+1;    

        % VARspec 1

            subplot(1,2,1); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_4var_ann_1.oirf_var4(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_4var_ann_1.oirf_var4_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_4var_ann_1.oirf_var4_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);
            title(strcat('\fontsize{12}',mytitle_1),'FontWeight','normal');
            xlabel('Years');
            ylabel(MyVar_ylabel_1);               
            %axis('tight');
            %ylim(My_Ylims_row1);

            subplot(1,2,2); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_4var_ann_2.oirf_var4(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_4var_ann_2.oirf_var4_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_4var_ann_2.oirf_var4_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);
            title(strcat('\fontsize{12}',mytitle_2),'FontWeight','normal');
            xlabel('Years');
            %ylabel(temp_MyVar_ylabel);
            %ylabel(MyVar_ylabel_2);    
            %axis('tight');
            %ylim(My_Ylims_row1);

        % add row labels
% 
%             myfig = gcf;
% 
%             annotation(myfig,'textbox',...
%                 [0.0265625 0.71496062992126 0.0515625 0.0840311679790023],...
%                 'String',MyVar_rowlabel_1,...
%                 'LineStyle','none',...
%                 'HorizontalAlignment','center',...
%                 'FontWeight','bold',...
%                 'FontSize',12,...
%                 'FitBoxToText','off');    
% 
%             annotation(myfig,'textbox',...
%                 [0.0265625 0.21496062992126 0.0515625 0.0840311679790023],...
%                 'String',MyVar_rowlabel_2,...
%                 'LineStyle','none',...
%                 'HorizontalAlignment','center',...
%                 'FontWeight','bold',...
%                 'FontSize',12,...
%                 'FitBoxToText','off');          
     
            
        % save jpg        
        saveas(1,strcat('figures/',fname),'png')
        saveas(1,strcat('figures/',fname)) 
        %saveas(1,strcat('output_for_paper/Figures/',fname),'png')
        %saveas(1,strcat('output_for_paper/Figures/',fname))                     
        %close(1)                           

      
        
end % ooo = 1:length(VARorder_list)

    
    
    

%% create 2x3 figure that compares different IRFs from different
%  VAR specifications across two ANNUAL variables but only
%  for the 4-variable VAR

clc;

% cc control var
%ccvarlist = {'none'};
ccvarlist = {'baa10ym'};
%ccvarlist = {'none'; 'baa10ym';'aaa10ym'};
ccc = 1;
myccvar = char(ccvarlist{ccc});

% VAR specs for columns 1, 2, and 3
VARspecs = {'hpfilter','bandpass','levels'}; % 
%VARorder = 1;
%VARorder = 2;
VARorder_list = [1,2];

% set of two variables to use as var4 (first one in top row of IRF figure,
% second in bottom row)
%var4_choice_set = {'total_iss_usa','agg_pat_val_sm'};
var4_choice_set = {'total_app_usa','agg_pat_val_sm'};

% total_iss_usa has data from 1963--2016
% agg_pat_val_sm has data from 1929--2010
% earliest start year is 1961 because first year of inv reg data

    % longest possible periods for {'total_iss_usa','agg_pat_val_sm'}
    startyr1 = 1963
    endyr1   = 2016
    startyr2 = 1961
    endyr2   = 2010

% loop across last var choices
for ooo = 1:length(VARorder_list)
 VARorder = VARorder_list(ooo);  
  panelnum=0; % start index at zero
  for aaa = 1:length(var4_choice_set)
    
    % get var4 name
    var4_choice = char(var4_choice_set{aaa});
    disp(strcat('var4_choice',num2str(aaa),'=',var4_choice));
    
    % get var4 year range
    eval(strcat('sample_start_year = startyr',num2str(aaa),';'));
    eval(strcat('sample_end_year   = endyr',num2str(aaa),';'));    
    
    % make sure we have the right annual data from investment regs
    if sample_start_year>=1969 & sample_start_year<=1971
        load data_inv_reg_ann_1969_2016   
    elseif sample_start_year>=1972              
        load data_inv_reg_ann_1972_2016                           
    elseif sample_start_year<=1968                     
        load data_inv_reg_ann_1961_2016                   
    else
        error('sample_start_year not accounted for above');
    end    
    
    % compute IRFs for data VARs for 4-variable VAR
    for vvv = 1:length(VARspecs)
    %vvv=1

        panelnum=panelnum+1; % count through panels
        myVARspec = char(VARspecs{vvv});

        % figure out starting and ending positions
        %sample_start_year = 1961;
        %sample_end_year   = 2016;     
        if strcmp(myVARspec,'levels')
            pos_start_macro  = find((data_macro_ann.year>=sample_start_year),1,'first');        
        else % need extra period for filtering        
            pos_start_macro = find((data_macro_ann.year>=sample_start_year),1,'first') - 1; 
        end    
        pos_end_macro   = find((data_macro_ann.year<=sample_end_year),1,'last');
        pos_start_invreg = find((data_inv_reg_ann.year>=sample_start_year),1,'first');        
        pos_end_invreg   = find((data_inv_reg_ann.year<=sample_end_year),1,'last');  
        disp(char(strcat({'macro var data from '},num2str(data_macro_ann.year(pos_start_macro)))));
        disp(char(strcat({'macro var data to '},  num2str(data_macro_ann.year(pos_end_macro)))));
        disp(char(strcat({'inv reg data from '},num2str(data_inv_reg_ann.year(pos_start_invreg)))));
        disp(char(strcat({'inv reg data to '},num2str(data_inv_reg_ann.year(pos_end_invreg)))));

        % first three variables from investment regression
        if strcmp(myVARspec,'levels')
            var1 = data_macro_ann.tfp( pos_start_macro:pos_end_macro); % tfp in levels
        else
            var1 = data_macro_ann.dtfp( pos_start_macro+1:pos_end_macro); % dtfp from macro data
            %var1_chk = data_inv_reg_ann.dtfp( pos_start_invreg:pos_end_invreg); % dtfp from inv reg data
            %chk_diff = abs(var1 - var1_chk);
            %max(chk_diff)
            %[var1, var1_chk]
        end
        var2 = data_inv_reg_ann.x( pos_start_invreg:pos_end_invreg);
        var3 = data_inv_reg_ann.expvol( pos_start_invreg:pos_end_invreg);

        % 4th variable that may be filtered depending myVARspec
        eval(strcat('var4_raw = data_macro_ann.',var4_choice,';'));
        var4_trunc = var4_raw(pos_start_macro:pos_end_macro); % truncated series to match other series
        if strcmp(myVARspec,'levels') % simply compute in log levels
            temp_var4_ann = log(var4_trunc); 
        else % de-trend 4th variable 

            temp_var4_ann = nan(size(var4_trunc));

            % HP filter. use pos_start+1 because no need to take first differences
            if strcmp(myVARspec,'hpfilter')            
                raw_var4_ann     = log(var4_trunc(2:end));
                smooth_var4_ann  = hpfilter(raw_var4_ann, 1600); % quarterly data smoothing 
                temp_var4_ann    = raw_var4_ann - smooth_var4_ann;
            end   

            % Comin Gertler (2006) band-pass
            % The function is bandpass(X,pl,pu). X is the raw data, pl and pu is the range of frequencies we want to extract. 
            % Recommended by Comin and Gertler (attached below), we should choose pl = 2 and pu = 200 for the quarterly data 
            % to extract the medium-term cycles. 
            if strcmp(myVARspec,'bandpass')  
                size(var4_trunc);
                raw_var4_ann = log(var4_trunc(2:end)); % no reduction in size from bandpass --> need to cut first obs for VAR
                temp_var4_ann = bandpass(raw_var4_ann, 2, 200);
                size(temp_var4_ann); % no reduction in size from bandpass                                
            end  

        end

        % series to enter VAR in levels 
        if strcmp(var4_choice,'Ig_Itot') ...
        || strcmp(var4_choice,'Ip_Itot') ...
        || strcmp(var4_choice,'Ig_Y') ...
        || strcmp(var4_choice,'labor_share_govt') ...
        || strcmp(var4_choice,'labor_share_priv') 
            var4 = exp(temp_var4_ann)
        else
            var4 = temp_var4_ann; % keep in logs
        end    

        % endogenous vars matrix
        temp_y_ann = [var1, var2, var3, var4];

        % exogenous vars matrix
        temp_x_ann = ones(size(temp_y_ann,1),1);
        if ~strcmp(myccvar, 'none')
            eval(strcat('ccvar_raw_ann = data_macro_ann.',myccvar,';'));
            if strcmp(myVARspec,'levels') 
                temp_ccvar_ann = ccvar_raw_ann(pos_start_macro:pos_end_macro);
            else
                temp_ccvar_ann = ccvar_raw_ann(pos_start_macro+1:pos_end_macro);
            end
            temp_x_ann = [temp_x_ann, temp_ccvar_ann];        
        end      

        % define different shock matrices

            std_IRF_length_ann = 6;

            % 1-std dtfp shock
            std_dtfp_shk_mat_ann      = zeros(4 , std_IRF_length_ann);
            std_dtfp_shk_mat_ann(1,1) = 1;            

            % 1-std ivol shock
            std_ivol_shk_mat_ann      = zeros(4 , std_IRF_length_ann);
            std_ivol_shk_mat_ann(3,1) = 1;             

            % compute IRFs for ivol shk
            if VARorder==1 
                temp_IRFOUT = gen_IRF_vectors_dataVAR_nvars( temp_y_ann, temp_x_ann, [], std_ivol_shk_mat_ann, 0);
            elseif VARorder==2
                temp_IRFOUT = gen_IRF_vectors_dataVAR2_nvars( temp_y_ann, temp_x_ann, [], std_ivol_shk_mat_ann, 0);
            else
                error('VARorder not specified');
            end
            %eval(strcat('IRFout_ivolshk_4var_ann_',num2str(vvv),' = temp_IRFOUT;'));
            eval(strcat('IRFout_ivolshk_4var_ann_',num2str(panelnum),' = temp_IRFOUT;'));
            
        % clean up
        clear var4_raw_ann var4_trunc temp_var4_ann temp_y_ann temp_x_ann

    end % vvv myVARspec list
    
    % y labels
    temp_MyVar_ylabel = texlabel('Percent');
    if strcmp(var4_choice,'Yp_real')
        temp_MyVar_ylabel = texlabel('log(Y_p)');
    end     
    eval(strcat('MyVar_ylabel_',num2str(aaa),'=temp_MyVar_ylabel;'));    
    
    %IRF_length_plot = std_IRF_length_qtr+1;
    % per May 18 2019 call with max, change length of IRF to 20 
    % periods when comparing data vs model
    IRF_length_plot = std_IRF_length_ann+1;       
    
    % y axis lims
    if aaa==1        
        temp_low1 = IRFout_ivolshk_4var_ann_1.oirf_var4_ciL(1:IRF_length_plot);
        temp_low2 = IRFout_ivolshk_4var_ann_2.oirf_var4_ciL(1:IRF_length_plot);
        temp_low3 = IRFout_ivolshk_4var_ann_3.oirf_var4_ciL(1:IRF_length_plot);
        temp_high1 = IRFout_ivolshk_4var_ann_1.oirf_var4_ciU(1:IRF_length_plot);
        temp_high2 = IRFout_ivolshk_4var_ann_2.oirf_var4_ciU(1:IRF_length_plot);
        temp_high3 = IRFout_ivolshk_4var_ann_3.oirf_var4_ciU(1:IRF_length_plot);        
        temp_min_low  = min([ temp_low1,  temp_low2,  temp_low3]);
        temp_min_high = max([temp_high1, temp_high2, temp_high3]);
        My_Ylims_row1 = [floor(100*temp_min_low),ceil(100*temp_min_high)];
    elseif aaa==2
        temp_low1 = IRFout_ivolshk_4var_ann_4.oirf_var4_ciL(1:IRF_length_plot);
        temp_low2 = IRFout_ivolshk_4var_ann_5.oirf_var4_ciL(1:IRF_length_plot);
        temp_low3 = IRFout_ivolshk_4var_ann_6.oirf_var4_ciL(1:IRF_length_plot);
        temp_high1 = IRFout_ivolshk_4var_ann_4.oirf_var4_ciU(1:IRF_length_plot);
        temp_high2 = IRFout_ivolshk_4var_ann_5.oirf_var4_ciU(1:IRF_length_plot);
        temp_high3 = IRFout_ivolshk_4var_ann_6.oirf_var4_ciU(1:IRF_length_plot);        
        temp_min_low  = min([ temp_low1,  temp_low2,  temp_low3]);
        temp_min_high = max([temp_high1, temp_high2, temp_high3]);
        My_Ylims_row2 = [floor(100*temp_min_low),ceil(100*temp_min_high)];        
    else
        error('aaa not recognized');
    end
    
    
    % row labels
    temp_MyVar_rowlabel = 'NEED ROW LABEL';
    if strcmp(var4_choice,'total_iss_usa')
        %temp_MyVar_rowlabel = {'Number of','Patents','Granted'};
        temp_MyVar_rowlabel = {'Number of','Patents'};
    end     
    if strcmp(var4_choice,'total_app_usa')
        %temp_MyVar_rowlabel = {'Number of','Patent','Applications'};
        temp_MyVar_rowlabel = {'Number of','Patents'};
    end         
    if strcmp(var4_choice,'agg_pat_val_sm')
        %temp_MyVar_rowlabel = {'Value of','Patents','Granted'};
        temp_MyVar_rowlabel = {'Value of','Patents'};
    end         
    eval(strcat('MyVar_rowlabel_',num2str(aaa),'=temp_MyVar_rowlabel;'));    

  end % aaa var4_choice_set
    
    % create the 2x3 figure
    close ALL
    figure(1);

        fname = strcat('IRFs_OnlyVol_VAR',num2str(VARorder),'_4var_ann_',var4_choice_set{1},'_from_',num2str(startyr1),'_to_',num2str(endyr1),'_',var4_choice_set{2},'_from_',num2str(startyr2),'_to_',num2str(endyr2),'_control_',myccvar,'_2x3_',char(VARspecs{1}),'_and_',char(VARspecs{2}),'_and_',char(VARspecs{3}));    
        % note: max change names of these files to
        % IRFs_OnlyVol_VAR1_innovation_outcomes
        % IRFs_OnlyVol_VAR2_innovation_outcomes

        % panel titles
        for vvv = 1:length(VARspecs)
            myVARspec = char(VARspecs{vvv});    
            if strcmp(myVARspec,'hpfilter')
                temp_mytitle = 'Business Cycle';
            elseif strcmp(myVARspec,'bandpass') 
                temp_mytitle = 'Medium Cycle';
            elseif strcmp(myVARspec,'levels')
                temp_mytitle = 'VAR in Levels';
            else
                error('myVARspec not recognized');
            end
            eval(strcat('mytitle_',num2str(vvv),'=temp_mytitle;'));
        end

        % set size of figure so it fills page
        set(gcf, 'PaperPositionMode', 'manual');
        set(gcf, 'PaperUnits', 'inches');
        set(gcf, 'PaperPosition', [0 0 14.00 7.00]);            
        %set(gcf, 'PaperPosition', [0 0 7.00 3.50]); % 1x2 plot


        % VARspec 1

            subplot(2,3,1); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_4var_ann_1.oirf_var4(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_4var_ann_1.oirf_var4_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_4var_ann_1.oirf_var4_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);
            title(strcat('\fontsize{12}',mytitle_1),'FontWeight','normal');
            xlabel(' ');
            ylabel(MyVar_ylabel_1);               
            axis('tight');
            ylim(My_Ylims_row1);

            subplot(2,3,4); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_4var_ann_4.oirf_var4(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_4var_ann_4.oirf_var4_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_4var_ann_4.oirf_var4_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);
            %title(strcat('\fontsize{12}',mytitle_1),'FontWeight','normal');
            xlabel('Years');
            ylabel(MyVar_ylabel_2);               
            axis('tight');
            ylim(My_Ylims_row2);

        
        % VARspec 2

            subplot(2,3,2); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_4var_ann_2.oirf_var4(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_4var_ann_2.oirf_var4_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_4var_ann_2.oirf_var4_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);
            title(strcat('\fontsize{12}',mytitle_2),'FontWeight','normal');
            xlabel(' ');
            %ylabel(temp_MyVar_ylabel);               
            axis('tight');
            ylim(My_Ylims_row1);

            subplot(2,3,5); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_4var_ann_5.oirf_var4(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_4var_ann_5.oirf_var4_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_4var_ann_5.oirf_var4_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);
            %title(strcat('\fontsize{12}',mytitle_1),'FontWeight','normal');
            xlabel('Years');
            %ylabel(temp_MyVar_ylabel);               
            axis('tight');       
            ylim(My_Ylims_row2);


        % VARspec 3

            subplot(2,3,3); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_4var_ann_3.oirf_var4(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_4var_ann_3.oirf_var4_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_4var_ann_3.oirf_var4_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);
            title(strcat('\fontsize{12}',mytitle_3),'FontWeight','normal');
            xlabel(' ');
            %ylabel(temp_MyVar_ylabel);               
            axis('tight');
            ylim(My_Ylims_row1);

            subplot(2,3,6); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_4var_ann_6.oirf_var4(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_4var_ann_6.oirf_var4_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_4var_ann_6.oirf_var4_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);
            %title(strcat('\fontsize{12}',mytitle_1),'FontWeight','normal');
            xlabel('Years');
            %ylabel(temp_MyVar_ylabel);               
            axis('tight');      
            ylim(My_Ylims_row2);

        % add row labels

            myfig = gcf;

            annotation(myfig,'textbox',...
                [0.0265625 0.71496062992126 0.0515625 0.0840311679790023],...
                'String',MyVar_rowlabel_1,...
                'LineStyle','none',...
                'HorizontalAlignment','center',...
                'FontWeight','bold',...
                'FontSize',12,...
                'FitBoxToText','off');    

            annotation(myfig,'textbox',...
                [0.0265625 0.21496062992126 0.0515625 0.0840311679790023],...
                'String',MyVar_rowlabel_2,...
                'LineStyle','none',...
                'HorizontalAlignment','center',...
                'FontWeight','bold',...
                'FontSize',12,...
                'FitBoxToText','off');          
     
            
        % save jpg        
        saveas(1,strcat('figures/',fname),'png')
        saveas(1,strcat('figures/',fname)) 
        %saveas(1,strcat('output_for_paper/Figures/',fname),'png')
        %saveas(1,strcat('output_for_paper/Figures/',fname))                     
        %close(1)                           

end % ooo = 1:length(VARorder_list)




%% For R3 responses comparing levels, bandpass, and hpfilter 
%  across 5 variables. for levels VAR, show tfp and vol shock responses
%  also create periodograms

clc;

% must do both filters in this section because they are both plotted
filterlist = {'hpfilter','bandpass'}; % 
    
    % benchmark
    var_set = {'Ig_real';'IPPrnd_real';'Ip_real';'labor_share_govt';'Yp_real'}; 
    
        % ylim used here for tighter fit
        My_Ylims_c1 = [-0.5, 0.5];
        My_Ylims_c2 = [-1.0, 0.5];
        My_Ylims_c3 = [-3.0, 1.0];
        My_Ylims_c4 = [-0.5, 1.0];    
        My_Ylims_c5 = [-1.0, 0.5];
    
    % try with Itotal
    %var_set = {'Ig_real';'Itot_real';'Ip_real';'labor_share_govt';'Yp_real'}; 
    %My_Ylims_c2 = [-1.5, 0.5];
      
        
    % credit control
    ccvarlist = {'baa10ym'}; % benchmark
    %ccvarlist = {'none'};     
    %ccvarlist = {'none'; 'baa10ym';'aaa10ym'};
    %ccvarlist = {'none'; 'baa10ym';'aaa10ym';'nfci';'anfci'};
    
    % sample start year
    sample_start_year = 1972; % default value
    %sample_start_year = 1982; % referee robustness request
    
    % sample end year
    sample_end_year   = 2016;        


for ccc = 1:length(ccvarlist)
  for fff = 1:length(filterlist)
     
    % assign variables
    myfilter = char(filterlist{fff});
    myinvvar_1 = char(var_set{1});
    myinvvar_2 = char(var_set{2});
    myinvvar_3 = char(var_set{3});
    myinvvar_4 = char(var_set{4});
    myinvvar_5 = char(var_set{5});
    myccvar = char(ccvarlist{ccc});

  
    % assign variable labels
    for varnum=1:5
        
        % temporary loop var name
        eval(strcat('temp_invvar = myinvvar_',num2str(varnum),';'));
             
        % figure out label based on name
        temp_MyVar_ylabel = 'NEED LABEL';
        temp_MyVar_title  = 'NEED TITLE';
        if strcmp(temp_invvar,'Ig_Itot')
            temp_MyVar_ylabel = 'I_g / (I_g + I_p)';
            temp_MyVar_title = 'Govt. to Total Inv. (I_g / (I_g + I_p))';
        end        
        if strcmp(temp_invvar,'Ip_Itot')
            temp_MyVar_ylabel = 'I_p / (I_g + I_p)';
            temp_MyVar_title = 'Priv. to Total Inv. (I_p / (I_g + I_p))';
        end    
        if strcmp(temp_invvar,'IPPtot_real')
            temp_MyVar_ylabel = texlabel('log(I_I_P_P)');
            temp_MyVar_title = 'Priv. IPP (incl. R&D) Inv. (log(I_I_P_P))';
        end
        if strcmp(temp_invvar,'IPPrnd_real')
            temp_MyVar_ylabel = texlabel('log(I_R_&_D)');
            temp_MyVar_title = 'Priv. R&D Inv. (log(I_R_&_D))';
        end
        if strcmp(temp_invvar,'Ig_real')
            temp_MyVar_ylabel = texlabel('log(I_g)');
            temp_MyVar_title = 'Govt. Inv. (log(I_g))';
        end
        if strcmp(temp_invvar,'Ip_real')
            temp_MyVar_ylabel = texlabel('log(I_p)');
            temp_MyVar_title = 'Priv. Total Inv. (log(I_p))';
        end    
        if strcmp(temp_invvar,'Ip_NOTrnd_real')
            temp_MyVar_ylabel = texlabel('log(I_p-I_R_&_D)');
            temp_MyVar_title = 'Priv. Non-R&D Inv. (log(I_p-I_R_&_D))';
        end    
        if strcmp(temp_invvar,'Itot_real')
            temp_MyVar_ylabel = texlabel('log(I_g+I_p)');
            temp_MyVar_title = 'Total Inv. (log(I_g+I_p))';
        end            
        if strcmp(temp_invvar,'Itang_v1_real')
            temp_MyVar_ylabel = texlabel('log(I_g+I_p-I_R_&_D)');
            temp_MyVar_title = 'Tangible Inv. (log(I_g+I_p-I_R_&_D))';
        end                    
        if strcmp(temp_invvar,'Itang_v2_real')
            temp_MyVar_ylabel = texlabel('log(I_g+I_p-I_I_P_P)');
            temp_MyVar_title = 'Tangible Inv. (log(I_g+I_p-I_I_P_P))';
        end                                    
        if strcmp(temp_invvar,'Yp_real')
            temp_MyVar_ylabel = texlabel('log(Y_p)');
            temp_MyVar_title = 'Priv. Output (log(Y_p))';
        end          
        if strcmp(temp_invvar,'Y_real')
            temp_MyVar_ylabel = texlabel('log(Y_G_D_P)');
            temp_MyVar_title = 'GDP (log(Y_G_D_P))';
        end    
        if strcmp(temp_invvar,'dtfp_FMA05')
            temp_MyVar_ylabel = texlabel('Delta a_t_,_t_+_5yrs}');
            temp_MyVar_title = '5-year FMA dtfp';
        end         
        if strcmp(temp_invvar,'Ig_Y')
            temp_MyVar_ylabel = 'I_g / Y';
            temp_MyVar_title = 'Govt. to GDP (I_g / Y)';
        end      
        if strcmp(temp_invvar,'labor_share_govt')
            temp_MyVar_ylabel = 'L_g / (L_g + L_p)';
            temp_MyVar_title = 'Govt. Labor Share (L_g / (L_g + L_p))';            
        end          
        
        % assign label
        if varnum==1
            MyVar_ylabel_1 = texlabel(temp_MyVar_ylabel);
            MyVar_title_1  = texlabel(temp_MyVar_title);
        end
        if varnum==2
            MyVar_ylabel_2 = texlabel(temp_MyVar_ylabel);
            MyVar_title_2  = texlabel(temp_MyVar_title);
        end
        if varnum==3
            MyVar_ylabel_3 = texlabel(temp_MyVar_ylabel);
            MyVar_title_3  = texlabel(temp_MyVar_title);
        end
        if varnum==4
            MyVar_ylabel_4 = texlabel(temp_MyVar_ylabel);
            MyVar_title_4  = texlabel(temp_MyVar_title);
        end        
        if varnum==5
            MyVar_ylabel_5 = texlabel(temp_MyVar_ylabel);
            MyVar_title_5  = texlabel(temp_MyVar_title);
        end             

                
        clearvars temp_MyVar_ylabel temp_MyVar_title;
        
    end

    
%     % compile quarterly data for each variable    
%     start_year_qtr = min(data_inv_reg_qtr.year);
%     if sample_start_year==1961
%         pos_start      = find((data_macro_qtr.year>=start_year_qtr),1,'first'); % start 1 qtr later so macro data is 1961Q1:2016Q4
%     else        
%         pos_start      = find((data_macro_qtr.year>=start_year_qtr),1,'first') - 1;        
%     end
%     disp(char(strcat({'macro var data from '},num2str(data_macro_qtr.year(pos_start)),'q',num2str(data_macro_qtr.qtr(pos_start)))))
%     disp(char(strcat({'inv reg data from '},num2str(data_inv_reg_qtr.year(1)),'q',num2str(data_inv_reg_qtr.qtr(1)))))
%     disp(char(strcat({'note: we want macro data to start 1 qtr before inv reg data b/c we take diffs of macro data to prepare them for VAR'})))  
%     
%     % choose ending position such that de-meaned macro data series will be
%     % the same length as the investment regression data series
%     length_qtr_VAR = length(data_inv_reg_qtr.x);
%     pos_end = pos_start+length_qtr_VAR;   
%         
%     %temp_year_qtr_chk = [data_macro_qtr.year(pos_start:pos_end), data_macro_qtr.qtr(pos_start:pos_end)]
%     % add one to pos_start b/c not detrending
%     temp_dtfp_qtr = data_macro_qtr.dtfp(pos_start+1:pos_end);
%     temp_ivol_qtr = data_macro_qtr.ivol(pos_start+1:pos_end);

    % compile quarterly data for each variable    
    if sample_start_year==1961
        pos_start      = find((data_macro_qtr.year>=sample_start_year),1,'first'); % start 1 qtr later so macro data is 1961Q1:2016Q4
    else        
        pos_start      = find((data_macro_qtr.year>=sample_start_year),1,'first') - 1;        
    end
    pos_end   = find((data_macro_qtr.year<=sample_end_year),1,'last');
    disp(char(strcat({'macro var data from '},num2str(data_macro_qtr.year(pos_start)),'q',num2str(data_macro_qtr.qtr(pos_start)))))
    disp(char(strcat({'note: we want macro data to start 1 qtr before inv reg data b/c we take diffs of macro data to prepare them for VAR'})))  
        
    %temp_year_qtr_chk = [data_macro_qtr.year(pos_start:pos_end), data_macro_qtr.qtr(pos_start:pos_end)]
    % add one to pos_start b/c not detrending
    temp_dtfp_qtr = data_macro_qtr.dtfp(pos_start+1:pos_end);
    temp_ivol_qtr = data_macro_qtr.ivol(pos_start+1:pos_end);        
        
        
    for varnum=1:5          
        
        eval(strcat('tempvarname = myinvvar_',num2str(varnum),';'));
        
        eval(strcat('var3_raw_qtr = data_macro_qtr.',tempvarname,';'));
        
        % truncated series to match other series
        var3_trunc = var3_raw_qtr(pos_start:pos_end);

        % de-trend 4th variable using HP filter or something else                    
        
            temp_var3_qtr = nan(size(var3_trunc));
        
            % HP filter. use pos_start+1 because no need to take first differences
            if strcmp(myfilter,'hpfilter')            
                raw_var3_qtr     = log(var3_trunc(2:end));
                smooth_var3_qtr  = hpfilter(raw_var3_qtr, 1600); % quarterly data smoothing 
                temp_var3_qtr    = raw_var3_qtr - smooth_var3_qtr;
            end

            % linear de-trend
            if strcmp(myfilter,'lindetrend')          
                temp_var3_qtr = prep_raw_data_for_VAR( var3_trunc) ;
            end
            
            % Comin Gertler (2006) band-pass
            % The function is bandpass(X,pl,pu). X is the raw data, pl and pu is the range of frequencies we want to extract. 
            % Recommended by Comin and Gertler (attached below), we should choose pl = 2 and pu = 200 for the quarterly data 
            % to extract the medium-term cycles. 
            if strcmp(myfilter,'bandpass')  
                
                size(var3_trunc);
                raw_var3_qtr = log(var3_trunc(2:end)); % no reduction in size from bandpass --> need to cut first obs for VAR
                temp_var3_qtr = bandpass(raw_var3_qtr, 2, 200);
                %temp_var3_qtr = bandpass(raw_var3_qtr, 32, 200);
                size(temp_var3_qtr); % no reduction in size from bandpass                                

            end

            
        % final dataset for VAR             
        y_qtr_reg = [temp_dtfp_qtr, temp_ivol_qtr];    
        %if strcmp(tempvarname,'Ig_Itot') || strcmp(tempvarname,'Ip_Itot') % series to enter VAR in levels
        % series to enter VAR in levels
        if strcmp(tempvarname,'Ig_Itot') ...
                || strcmp(tempvarname,'Ip_Itot') ...
                || strcmp(tempvarname,'Ig_Y') ...
                || strcmp(tempvarname,'labor_share_priv') ...
                || strcmp(tempvarname,'labor_share_govt') 
            temp_y_qtr = [y_qtr_reg, exp(temp_var3_qtr)];    
        else
            temp_y_qtr = [y_qtr_reg, temp_var3_qtr];    
        end

        % final exogenous variable dataset for quarterly VAR
        temp_x_qtr = ones(size(temp_y_qtr,1),1);
        if ~strcmp(myccvar, 'none')
            eval(strcat('ccvar_raw_qtr = data_macro_qtr.',myccvar,';'));
            temp_ccvar_qtr = ccvar_raw_qtr(pos_start+1:pos_end);
            temp_x_qtr = [temp_x_qtr, temp_ccvar_qtr];        
        end      
        
        eval(strcat('y_qtr_',num2str(varnum),' = temp_y_qtr;'));
        eval(strcat('x_exo_qtr_',num2str(varnum),' = temp_x_qtr;'));
        
        clear var3_raw_qtr var3_trunc temp_var3_qtr temp_y_qtr temp_x_qtr
        
        % define different shock matrices

            std_IRF_length_qtr = 24;

            % 1-std dtfp shock
            %std_dtfp_shk_mat_qtr      = zeros(3 , std_IRF_length_qtr);
            std_dtfp_shk_mat_qtr      = zeros(3 , std_IRF_length_qtr+176); % compute longer vector and then truncate in plots as needed
            std_dtfp_shk_mat_qtr(1,1) = 1;            

            % 1-std ivol shock
            %std_ivol_shk_mat_qtr      = zeros(3 , std_IRF_length_qtr);
            std_ivol_shk_mat_qtr      = zeros(3 , std_IRF_length_qtr+176); % compute longer vector and then truncate in plots as needed
            std_ivol_shk_mat_qtr(2,1) = 1;             
    
        % compute IRFs 

            % dtfp shk
            %eval(strcat('IRFout_dtfpshk_qtr_',num2str(varnum),' = gen_IRF_vectors_dataVAR_nvars( y_qtr_',num2str(varnum),', x_exo_qtr_',num2str(varnum),', [], std_dtfp_shk_mat_qtr, 0);'))

            % ivol shk
            eval(strcat('IRFout_ivolshk_qtr_',num2str(varnum),' = gen_IRF_vectors_dataVAR_nvars( y_qtr_',num2str(varnum),', x_exo_qtr_',num2str(varnum),', [], std_ivol_shk_mat_qtr, 0);'));

    end
    
    % save out IRF vectors by filter type
    if strcmp(myfilter,'hpfilter')
        IRFout_hpfilter_ivolshk_1 = IRFout_ivolshk_qtr_1;
        IRFout_hpfilter_ivolshk_2 = IRFout_ivolshk_qtr_2;
        IRFout_hpfilter_ivolshk_3 = IRFout_ivolshk_qtr_3;
        IRFout_hpfilter_ivolshk_4 = IRFout_ivolshk_qtr_4;        
        IRFout_hpfilter_ivolshk_5 = IRFout_ivolshk_qtr_5;  
    elseif strcmp(myfilter,'bandpass')
        IRFout_bandpass_ivolshk_1 = IRFout_ivolshk_qtr_1;
        IRFout_bandpass_ivolshk_2 = IRFout_ivolshk_qtr_2;
        IRFout_bandpass_ivolshk_3 = IRFout_ivolshk_qtr_3;
        IRFout_bandpass_ivolshk_4 = IRFout_ivolshk_qtr_4;                
        IRFout_bandpass_ivolshk_5 = IRFout_ivolshk_qtr_5;                
    else
        error('myfilter not recognized');
    end
    
  end
   

  % plot 2x4 IRF where first row is hpfilter and second row is bandpass    
  for plot_model_lines = 0:0
    close ALL
    if plot_model_lines
        %fname = strcat('IRFs_OnlyVol_data_vs_model_hpfilter_vs_bandpass_2x4_dtfp_x_expvol_',myinvvar_1,'_or_',myinvvar_2,'_or_',myinvvar_3,'_or_',myinvvar_4,'_control_',myccvar);    
        error('do not run with model lines for VAR(3)');
    else
        %fname = strcat('IRFs_OnlyVol_hpfilter_vs_bandpass_2x4_dtfp_ivol_',myinvvar_1,'_or_',myinvvar_2,'_or_',myinvvar_3,'_or_',myinvvar_4,'_control_',myccvar);    
        fname = strcat('IRFs_OnlyVol_hpfilter_vs_bandpass_2x4_dtfp_ivol_',myinvvar_1,'_or_',myinvvar_2,'_or_',myinvvar_3,'_or_',myinvvar_4,'_control_',myccvar,'_',num2str(sample_start_year));            
    end
    figure(1);
    
        % set size of figure so it fills page
        set(gcf, 'PaperPositionMode', 'manual');
        set(gcf, 'PaperUnits', 'inches');
        set(gcf, 'PaperPosition', [0 0 14.00 7.00]);            
  
        %IRF_length_plot = std_IRF_length_qtr+1;
        % per May 18 2019 call with max, change length of IRF to 20 
        % periods when comparing data vs model
        if plot_model_lines
            IRF_length_plot = std_IRF_length_qtr+1-4;
        else
            IRF_length_plot = std_IRF_length_qtr+1;
        end        
        
        % quarterly data for var 1

            subplot(2,5,1); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_hpfilter_ivolshk_1.oirf_var3(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_hpfilter_ivolshk_1.oirf_var3_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_hpfilter_ivolshk_1.oirf_var3_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);
            if plot_model_lines
                plot(0:IRF_length_plot-1, 100*model_IRF_vol_line_1(1:IRF_length_plot), '-r', 'Linewidth', 2);
            end           
            title(strcat('\fontsize{12}',MyVar_title_1),'FontWeight','normal');
            xlabel(' ');
            ylabel('Percent');
            axis('tight');
            if plot_model_lines
                ylim(My_Ylims_c1);
            else
                ylim(My_Ylims_c1);
            end
            

            subplot(2,5,6); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_bandpass_ivolshk_1.oirf_var3(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_bandpass_ivolshk_1.oirf_var3_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_bandpass_ivolshk_1.oirf_var3_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);
            if plot_model_lines
                plot(0:IRF_length_plot-1, 100*model_IRF_vol_line_1(1:IRF_length_plot), '-r', 'Linewidth', 2);
            end                
            %title(strcat('\fontsize{12}','Volatility Shock'));
            %xlabel('Quarters');
            %ylabel(MyVar_ylabel_1);
            title(strcat('\fontsize{12}',' '));
            xlabel('Quarters');
            ylabel('Percent');            
            axis('tight');
            ylim(My_Ylims_c1);        
        
            
        % quarterly data for var 2

            subplot(2,5,2); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_hpfilter_ivolshk_2.oirf_var3(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_hpfilter_ivolshk_2.oirf_var3_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_hpfilter_ivolshk_2.oirf_var3_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);
            if plot_model_lines
                plot(0:IRF_length_plot-1, 100*model_IRF_vol_line_2(1:IRF_length_plot), '-r', 'Linewidth', 2);
            end                  
            title(strcat('\fontsize{12}',MyVar_title_2),'FontWeight','normal');
            xlabel(' ');
            ylabel(' ');            
            axis('tight');
            if plot_model_lines
                ylim(My_Ylims_c2);
            else
                ylim(My_Ylims_c2);
            end

            subplot(2,5,7); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_bandpass_ivolshk_2.oirf_var3(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_bandpass_ivolshk_2.oirf_var3_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_bandpass_ivolshk_2.oirf_var3_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);
            if plot_model_lines
                plot(0:IRF_length_plot-1, 100*model_IRF_vol_line_2(1:IRF_length_plot), '-r', 'Linewidth', 2);
            end                                
            %title(strcat('\fontsize{12}','Volatility Shock'));
            %xlabel('Quarters');
            %ylabel(MyVar_ylabel_2);
            title(strcat('\fontsize{12}',' '));
            xlabel('Quarters');
            ylabel(' ');                
            axis('tight');
            ylim(My_Ylims_c2);
   
            
        % quarterly data for var 3

            subplot(2,5,3); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_hpfilter_ivolshk_3.oirf_var3(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_hpfilter_ivolshk_3.oirf_var3_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_hpfilter_ivolshk_3.oirf_var3_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);
            if plot_model_lines
                plot(0:IRF_length_plot-1, 100*model_IRF_vol_line_3(1:IRF_length_plot), '-r', 'Linewidth', 2);
            end                                
            %title(strcat('\fontsize{12}','Productivity Shock'));
            %xlabel('Quarters');
            %ylabel(MyVar_ylabel_3);
            title(strcat('\fontsize{12}',MyVar_title_3),'FontWeight','normal');
            xlabel(' ');
            ylabel(' ');               
            axis('tight');
            if plot_model_lines
                ylim(My_Ylims_c3);
            else
                ylim(My_Ylims_c3);
            end            
            

            subplot(2,5,8); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_bandpass_ivolshk_3.oirf_var3(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_bandpass_ivolshk_3.oirf_var3_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_bandpass_ivolshk_3.oirf_var3_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);
            if plot_model_lines
                plot(0:IRF_length_plot-1, 100*model_IRF_vol_line_3(1:IRF_length_plot), '-r', 'Linewidth', 2);
            end                                                
            %title(strcat('\fontsize{12}','Volatility Shock'));
            %xlabel('Quarters');
            %ylabel(MyVar_ylabel_3);
            title(strcat('\fontsize{12}',' '));
            xlabel('Quarters');
            ylabel(' ');                            
            axis('tight');
            ylim(My_Ylims_c3);      
            

        % quarterly data for var 4

            subplot(2,5,4); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_hpfilter_ivolshk_4.oirf_var3(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_hpfilter_ivolshk_4.oirf_var3_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_hpfilter_ivolshk_4.oirf_var3_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);
            if plot_model_lines
                plot(0:IRF_length_plot-1, 100*model_IRF_vol_line_4(1:IRF_length_plot), '-r', 'Linewidth', 2);
            end                                
            %title(strcat('\fontsize{12}','Productivity Shock'));
            %xlabel('Quarters');
            %ylabel(MyVar_ylabel_4);
            title(strcat('\fontsize{12}',MyVar_title_4),'FontWeight','normal');
            xlabel(' ');
            ylabel(' ');               
            axis('tight');
            if plot_model_lines
                ylim(My_Ylims_c4);
            else
                ylim(My_Ylims_c4);
            end                    
            

            subplot(2,5,9); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_bandpass_ivolshk_4.oirf_var3(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_bandpass_ivolshk_4.oirf_var3_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_bandpass_ivolshk_4.oirf_var3_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);
            if plot_model_lines
                plot(0:IRF_length_plot-1, 100*model_IRF_vol_line_4(1:IRF_length_plot), '-r', 'Linewidth', 2);
            end                                                
            %title(strcat('\fontsize{12}','Volatility Shock'));
            %xlabel('Quarters');
            %ylabel(MyVar_ylabel_4);
            title(strcat('\fontsize{12}',' '));
            xlabel('Quarters');
            ylabel(' ');                            
            axis('tight');
            ylim(My_Ylims_c4);              

            
        % quarterly data for var 5

            subplot(2,5,5); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_hpfilter_ivolshk_5.oirf_var3(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_hpfilter_ivolshk_5.oirf_var3_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_hpfilter_ivolshk_5.oirf_var3_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);
            if plot_model_lines
                plot(0:IRF_length_plot-1, 100*model_IRF_vol_line_5(1:IRF_length_plot), '-r', 'Linewidth', 2);
            end                                
            %title(strcat('\fontsize{12}','Productivity Shock'));
            %xlabel('Quarters');
            %ylabel(MyVar_ylabel_4);
            title(strcat('\fontsize{12}',MyVar_title_5),'FontWeight','normal');
            xlabel(' ');
            ylabel(' ');               
            axis('tight');
            if plot_model_lines
                ylim(My_Ylims_c4);
            else
                ylim(My_Ylims_c4);
            end                    
            

            subplot(2,5,10); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_bandpass_ivolshk_5.oirf_var3(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_bandpass_ivolshk_5.oirf_var3_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_bandpass_ivolshk_5.oirf_var3_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);
            if plot_model_lines
                plot(0:IRF_length_plot-1, 100*model_IRF_vol_line_5(1:IRF_length_plot), '-r', 'Linewidth', 2);
            end                                                
            %title(strcat('\fontsize{12}','Volatility Shock'));
            %xlabel('Quarters');
            %ylabel(MyVar_ylabel_4);
            title(strcat('\fontsize{12}',' '));
            xlabel('Quarters');
            ylabel(' ');                            
            axis('tight');
            ylim(My_Ylims_c4);             
            
            
            % add shock labels
            
                myfig = gcf;
            
                annotation(myfig,'textbox',...
                    [0.0265625 0.71496062992126 0.0515625 0.0840311679790023],...
                    'String',{'Business','Cycle'},...
                    'LineStyle','none',...
                    'HorizontalAlignment','center',...
                    'FontWeight','bold',...
                    'FontSize',12,...
                    'FitBoxToText','off');    
            
                annotation(myfig,'textbox',...
                    [0.025 0.244094488188976 0.0515625 0.0840311679790026],...
                    'String',{'Medium','Cycle'},...
                    'LineStyle','none',...
                    'HorizontalAlignment','center',...
                    'FontWeight','bold',...
                    'FontSize',12,...
                    'FitBoxToText','off');            
            
        % save jpg        
        saveas(1,strcat('figures/',fname),'png')
        saveas(1,strcat('figures/',fname)) 
        saveas(1,strcat('output_for_paper/Figures/',fname),'png')
        saveas(1,strcat('output_for_paper/Figures/',fname))  
        %close(1)                          
  end  
   
    
end 



% repeat VARs in levels

    % assign variables
    myvar2  = char('ivol'); % level of ivol as in other VARs
    myttchoice = char('nott'); % 'nott' (no time trend) or 'yestt' (yes time trend)
    
    % use variables assigned above otherwise
    %var3_set = {'ln_Ig_real'; 'ln_IPPrnd_real'; 'ln_Ip_real'; 'labor_share_govt'; 'ln_Yp_real'}; % log levels    
%     myinvvar_1 = char(var3_set{1});
%     myinvvar_2 = char(var3_set{2});
%     myinvvar_3 = char(var3_set{3});
%     myinvvar_4 = char(var3_set{4});
%     myinvvar_5 = char(var3_set{5});
%     myccvar = char(ccvarlist{ccc});
    

    % figure out starting and ending positions
    %sample_start_year = 1972;
    %sample_end_year   = 2016;        
    pos_start = find((data_macro_qtr.year>=sample_start_year),1,'first');        
    pos_end   = find((data_macro_qtr.year<=sample_end_year),1,'last');
    disp(char(strcat({'macro var data from '},num2str(data_macro_qtr.year(pos_start)),'q',num2str(data_macro_qtr.qtr(pos_start)))))
    disp(char(strcat({'macro var data to '},  num2str(data_macro_qtr.year(pos_end)),  'q',num2str(data_macro_qtr.qtr(pos_end)))))
    
    % first two variables
    %temp_dtfp_qtr   = data_macro_qtr.dtfp( pos_start:pos_end);
    temp_tfp_qtr   = data_macro_qtr.tfp( pos_start:pos_end); % tfp in levels
    eval(strcat('temp_var2_qtr = data_macro_qtr.',myvar2,'(pos_start:pos_end);'));    
    
    % third variable (economic aggregate)
    for varnum=1:5              
        
        % name of var
        eval(strcat('tempvarname = myinvvar_',num2str(varnum),';'));
        
        % grab the full time series of the var. certain
        % vars enter in levels, not logs
        if strcmp(tempvarname,'Ig_Itot') ...
                || strcmp(tempvarname,'Ip_Itot') ...
                || strcmp(tempvarname,'Ig_Y') ...
                || strcmp(tempvarname,'labor_share_priv') ...
                || strcmp(tempvarname,'labor_share_govt') 
            eval(strcat('var3_raw_qtr = data_macro_qtr.',tempvarname,';'));
        else
            eval(strcat('var3_raw_qtr = log(data_macro_qtr.',tempvarname,');'));
        end        
        
        
        
        % truncated series to match same period as other series
        var3_trunc = var3_raw_qtr(pos_start:pos_end);
        
        % final matrix for VAR                
        %temp_y_qtr = [temp_dtfp_qtr, temp_var2_qtr, var3_trunc];    
        temp_y_qtr = [temp_tfp_qtr, temp_var2_qtr, var3_trunc];    
       
        % final exogenous variable dataset for quarterly VAR
        temp_x_qtr = ones(size(temp_y_qtr,1),1);
        if ~strcmp(myccvar, 'none')
            eval(strcat('ccvar_raw_qtr = data_macro_qtr.',myccvar,';'));
            temp_ccvar_qtr = ccvar_raw_qtr(pos_start:pos_end);
            temp_x_qtr = [temp_x_qtr, temp_ccvar_qtr];        
        end     
        if strcmp(myttchoice,'yestt')
            time_var = [1:length(temp_x_qtr)]';
            temp_x_qtr = [temp_x_qtr, time_var];        
        end
        
        eval(strcat('y_qtr_',num2str(varnum),' = temp_y_qtr;'));
        eval(strcat('x_exo_qtr_',num2str(varnum),' = temp_x_qtr;'));
        
        clear var3_raw_qtr var3_trunc temp_var3_qtr temp_y_qtr temp_x_qtr
        
        % define different shock matrices

            std_IRF_length_qtr = 24;

            % 1-std dtfp shock
            std_dtfp_shk_mat_qtr      = zeros(3 , std_IRF_length_qtr+176);
            std_dtfp_shk_mat_qtr(1,1) = 1;           

            % 1-std ivol shock
            std_ivol_shk_mat_qtr      = zeros(3 , std_IRF_length_qtr+176);
            std_ivol_shk_mat_qtr(2,1) = 1;             
            
        % compute IRFs 

            % tfp shk
            eval(strcat('IRFout_lvl_tfpshk_qtr_',num2str(varnum),' = gen_IRF_vectors_dataVAR_nvars( y_qtr_',num2str(varnum),', x_exo_qtr_',num2str(varnum),', [], std_dtfp_shk_mat_qtr, 0);'))

            % ivol shk           
            eval(strcat('IRFout_lvl_ivolshk_qtr_',num2str(varnum),' = gen_IRF_vectors_dataVAR_nvars( y_qtr_',num2str(varnum),', x_exo_qtr_',num2str(varnum),', [], std_ivol_shk_mat_qtr, 0);'));

    end
   
    
% additional figure with VAR done using level variables and
% then computing periodograms
if 1==1
    
  % length of IRF vector used in computing periodogram
  pgram_input_vector_length = 200;
  %pgram_input_vector_length = 25;
  if 1==0 
      figure(3);
      box on; hold on;
      plot(0:pgram_input_vector_length-1, 100*IRFout_lvl_ivolshk_qtr_4.oirf_var3(1:pgram_input_vector_length), '-b', 'Linewidth', 2);
      plot(0:pgram_input_vector_length-1, 100*IRFout_lvl_ivolshk_qtr_4.oirf_var3_ciL(1:pgram_input_vector_length), '--b', 'Linewidth', 1);
      plot(0:pgram_input_vector_length-1, 100*IRFout_lvl_ivolshk_qtr_4.oirf_var3_ciU(1:pgram_input_vector_length), '--b', 'Linewidth', 1);                                                   
  end
  
  % which lines to show in the periodogram panel
  pxx_show = 'all'; % all three VAR specificatinos
  %pxx_show = 'hp_and_lvls'; % on HP-filter and Levels
  
  % length of periodogram vectors to plot
  %pxx_vec_length = 129; % full
  %pxx_vec_length = 23; % approx first 20% of x-axis
  pxx_vec_length = 10; % approx first 10% of x-axis
  [pxx_hp,  w_hp]  = periodogram(IRFout_hpfilter_ivolshk_1.oirf_var3(1:pgram_input_vector_length));
  length(w_hp)
  w_hp(end)
  w_hp(pxx_vec_length)



  % plot 4x5 IRF where first row is hpfilter and second row is bandpass    
    %close(2);
    %fname = strcat('IRFs_OnlyVol_4x5_dtfp_or_tfp_ivol_',myinvvar_1,'_or_',myinvvar_2,'_or_',myinvvar_3,'_or_',myinvvar_4,'_or_',myinvvar_5,'_control_',myccvar,'_',num2str(pgram_input_vector_length),'_',num2str(pxx_vec_length));    
    fname = strcat('IRFs_OnlyVol_4x5_dtfp_or_tfp_ivol_',myinvvar_1,'_or_',myinvvar_2,'_or_',myinvvar_3,'_or_',myinvvar_4,'_or_',myinvvar_5,'_control_',myccvar,'_',num2str(sample_start_year),'_',num2str(pgram_input_vector_length),'_',num2str(pxx_vec_length));        
    figure(2);
    
        % set size of figure so it fills page
        set(gcf, 'PaperPositionMode', 'manual');
        set(gcf, 'PaperUnits', 'inches');
        set(gcf, 'PaperPosition', [0 0 14.00 7.00]);            
  
        IRF_length_plot = std_IRF_length_qtr+1;
        
        % quarterly data for var 1

            subplot(4,5,11); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_hpfilter_ivolshk_1.oirf_var3(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_hpfilter_ivolshk_1.oirf_var3_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_hpfilter_ivolshk_1.oirf_var3_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);        
            %title(strcat('\fontsize{12}',MyVar_title_1),'FontWeight','normal');
            xlabel('Quarters');
            ylabel('Percent');
            axis('tight');
            ylim(My_Ylims_c1);
            

            subplot(4,5,6); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_bandpass_ivolshk_1.oirf_var3(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_bandpass_ivolshk_1.oirf_var3_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_bandpass_ivolshk_1.oirf_var3_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);              
            %title(strcat('\fontsize{12}','Volatility Shock'));
            %xlabel('Quarters');
            %ylabel(MyVar_ylabel_1);
            title(strcat('\fontsize{12}',' '));
            %xlabel('Quarters');
            ylabel('Percent');            
            axis('tight');
            ylim(My_Ylims_c1);        
        
            
            subplot(4,5,1); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_lvl_ivolshk_qtr_1.oirf_var3(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_lvl_ivolshk_qtr_1.oirf_var3_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_lvl_ivolshk_qtr_1.oirf_var3_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);            
            %xlabel('Quarters');
            %ylabel(MyVar_ylabel_1);
            title(strcat('\fontsize{12}',MyVar_title_1),'FontWeight','normal');
            %xlabel('Quarters');
            ylabel('Percent');            
            axis('tight');
            ylim(My_Ylims_c1);              

            % periodogram panel
            % see, e.g.: https://www.mathworks.com/help/signal/ref/periodogram.html
            [pxx_hp,  w_hp]  = periodogram(IRFout_hpfilter_ivolshk_1.oirf_var3(1:pgram_input_vector_length));
            [pxx_bp,  w_bp]  = periodogram(IRFout_bandpass_ivolshk_1.oirf_var3(1:pgram_input_vector_length));
            [pxx_lvl, w_lvl] = periodogram( IRFout_lvl_ivolshk_qtr_1.oirf_var3(1:pgram_input_vector_length));
            subplot(4,5,16); hold on; box on;
            if strcmp(pxx_show,'all')
                h(1) = plot(w_hp(1:pxx_vec_length),  pxx_hp(1:pxx_vec_length),  '-g', 'Linewidth', 1);
                h(2) = plot(w_bp(1:pxx_vec_length),  pxx_bp(1:pxx_vec_length),  '-b', 'Linewidth', 1);
                h(3) = plot(w_lvl(1:pxx_vec_length), pxx_lvl(1:pxx_vec_length), '-r', 'Linewidth', 2);               
                legend(h, 'HP','BP','Lvls','Location','northeast');
                clear h;
            elseif strcmp(pxx_show,'hp_and_lvls')
                h(1) = plot(w_hp(1:pxx_vec_length),  pxx_hp(1:pxx_vec_length),  '-g', 'Linewidth', 1);
                h(2) = plot(w_lvl(1:pxx_vec_length), pxx_lvl(1:pxx_vec_length), '-r', 'Linewidth', 2);                
                legend(h, 'HP','Lvls','Location','northeast');
                clear h;                
            end
            title(strcat('\fontsize{12}',' '));
            xlabel('\omega');  
            ylabel('Power/frequency'); 
            axis('tight');  
         
            
            
        % quarterly data for var 2

            subplot(4,5,12); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_hpfilter_ivolshk_2.oirf_var3(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_hpfilter_ivolshk_2.oirf_var3_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_hpfilter_ivolshk_2.oirf_var3_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);              
            %title(strcat('\fontsize{12}',MyVar_title_2),'FontWeight','normal');
            xlabel('Quarters');
            ylabel(' ');            
            axis('tight');
            ylim(My_Ylims_c2);

            subplot(4,5,7); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_bandpass_ivolshk_2.oirf_var3(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_bandpass_ivolshk_2.oirf_var3_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_bandpass_ivolshk_2.oirf_var3_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);                          
            %title(strcat('\fontsize{12}','Volatility Shock'));
            %xlabel('Quarters');
            %ylabel(MyVar_ylabel_2);
            title(strcat('\fontsize{12}',' '));
            %xlabel('Quarters');
            ylabel(' ');                
            axis('tight');
            ylim(My_Ylims_c2);
   
            
            subplot(4,5,2); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_lvl_ivolshk_qtr_2.oirf_var3(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_lvl_ivolshk_qtr_2.oirf_var3_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_lvl_ivolshk_qtr_2.oirf_var3_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);                          
            title(strcat('\fontsize{12}',MyVar_title_2),'FontWeight','normal');
            %xlabel('Quarters');
            %ylabel(MyVar_ylabel_2);
            %title(strcat('\fontsize{12}',' '));
            %xlabel('Quarters');
            ylabel(' ');                
            axis('tight');
            ylim(My_Ylims_c2);            
            
            
            % periodogram panel
            % see, e.g.: https://www.mathworks.com/help/signal/ref/periodogram.html
            [pxx_hp,  w_hp]  = periodogram(IRFout_hpfilter_ivolshk_2.oirf_var3(1:pgram_input_vector_length));
            [pxx_bp,  w_bp]  = periodogram(IRFout_bandpass_ivolshk_2.oirf_var3(1:pgram_input_vector_length));
            [pxx_lvl, w_lvl] = periodogram( IRFout_lvl_ivolshk_qtr_2.oirf_var3(1:pgram_input_vector_length));
            subplot(4,5,17); hold on; box on;
            if strcmp(pxx_show,'all')
                h(1) = plot(w_hp(1:pxx_vec_length),  pxx_hp(1:pxx_vec_length),  '-g', 'Linewidth', 1);
                h(2) = plot(w_bp(1:pxx_vec_length),  pxx_bp(1:pxx_vec_length),  '-b', 'Linewidth', 1);
                h(3) = plot(w_lvl(1:pxx_vec_length), pxx_lvl(1:pxx_vec_length), '-r', 'Linewidth', 2);               
                legend(h, 'HP','BP','Lvls','Location','northeast');
                clear h;
            elseif strcmp(pxx_show,'hp_and_lvls')
                h(1) = plot(w_hp(1:pxx_vec_length),  pxx_hp(1:pxx_vec_length),  '-g', 'Linewidth', 1);
                h(2) = plot(w_lvl(1:pxx_vec_length), pxx_lvl(1:pxx_vec_length), '-r', 'Linewidth', 2);                
                legend(h, 'HP','Lvls','Location','northeast');
                clear h;                
            end
            title(strcat('\fontsize{12}',' '));
            xlabel('\omega');  
            ylabel('Power/frequency'); 
            axis('tight');           
            
            
        % quarterly data for var 3

            subplot(4,5,13); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_hpfilter_ivolshk_3.oirf_var3(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_hpfilter_ivolshk_3.oirf_var3_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_hpfilter_ivolshk_3.oirf_var3_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);                              
            %title(strcat('\fontsize{12}','Productivity Shock'));
            %xlabel('Quarters');
            %ylabel(MyVar_ylabel_3);
            %title(strcat('\fontsize{12}',MyVar_title_3),'FontWeight','normal');
            xlabel('Quarters');
            ylabel(' ');               
            axis('tight');
            ylim(My_Ylims_c3);        
            

            subplot(4,5,8); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_bandpass_ivolshk_3.oirf_var3(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_bandpass_ivolshk_3.oirf_var3_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_bandpass_ivolshk_3.oirf_var3_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);                                               
            %title(strcat('\fontsize{12}','Volatility Shock'));
            %xlabel('Quarters');
            %ylabel(MyVar_ylabel_3);
            title(strcat('\fontsize{12}',' '));
            %xlabel('Quarters');
            ylabel(' ');                            
            axis('tight');
            ylim(My_Ylims_c3);      
            
            
            subplot(4,5,3); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_lvl_ivolshk_qtr_3.oirf_var3(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_lvl_ivolshk_qtr_3.oirf_var3_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_lvl_ivolshk_qtr_3.oirf_var3_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);                                               
            %title(strcat('\fontsize{12}','Volatility Shock'));
            %xlabel('Quarters');
            %ylabel(MyVar_ylabel_3);
            title(strcat('\fontsize{12}',MyVar_title_3),'FontWeight','normal');
            %xlabel('Quarters');
            ylabel(' ');                            
            axis('tight');
            ylim(My_Ylims_c3);      
                 
            
            % periodogram panel
            % see, e.g.: https://www.mathworks.com/help/signal/ref/periodogram.html
            [pxx_hp,  w_hp]  = periodogram(IRFout_hpfilter_ivolshk_3.oirf_var3(1:pgram_input_vector_length));
            [pxx_bp,  w_bp]  = periodogram(IRFout_bandpass_ivolshk_3.oirf_var3(1:pgram_input_vector_length));
            [pxx_lvl, w_lvl] = periodogram( IRFout_lvl_ivolshk_qtr_3.oirf_var3(1:pgram_input_vector_length));
            subplot(4,5,18); hold on; box on;
            if strcmp(pxx_show,'all')
                h(1) = plot(w_hp(1:pxx_vec_length),  pxx_hp(1:pxx_vec_length),  '-g', 'Linewidth', 1);
                h(2) = plot(w_bp(1:pxx_vec_length),  pxx_bp(1:pxx_vec_length),  '-b', 'Linewidth', 1);
                h(3) = plot(w_lvl(1:pxx_vec_length), pxx_lvl(1:pxx_vec_length), '-r', 'Linewidth', 2);               
                legend(h, 'HP','BP','Lvls','Location','northeast');
                clear h;
            elseif strcmp(pxx_show,'hp_and_lvls')
                h(1) = plot(w_hp(1:pxx_vec_length),  pxx_hp(1:pxx_vec_length),  '-g', 'Linewidth', 1);
                h(2) = plot(w_lvl(1:pxx_vec_length), pxx_lvl(1:pxx_vec_length), '-r', 'Linewidth', 2);                
                legend(h, 'HP','Lvls','Location','northeast');
                clear h;                
            end
            title(strcat('\fontsize{12}',' '));
            xlabel('\omega');  
            ylabel('Power/frequency'); 
            axis('tight');             
            

        % quarterly data for var 4

            subplot(4,5,14); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_hpfilter_ivolshk_4.oirf_var3(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_hpfilter_ivolshk_4.oirf_var3_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_hpfilter_ivolshk_4.oirf_var3_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);                              
            %title(strcat('\fontsize{12}','Productivity Shock'));
            %xlabel('Quarters');
            %ylabel(MyVar_ylabel_4);
            %title(strcat('\fontsize{12}',MyVar_title_4),'FontWeight','normal');
            xlabel('Quarters');
            ylabel(' ');               
            axis('tight');
            if plot_model_lines
                ylim(My_Ylims_c4);
            else
                ylim(My_Ylims_c4);
            end                    
            

            subplot(4,5,9); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_bandpass_ivolshk_4.oirf_var3(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_bandpass_ivolshk_4.oirf_var3_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_bandpass_ivolshk_4.oirf_var3_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);                                             
            %title(strcat('\fontsize{12}','Volatility Shock'));
            %xlabel('Quarters');
            %ylabel(MyVar_ylabel_4);
            title(strcat('\fontsize{12}',' '));
            %xlabel('Quarters');
            ylabel(' ');                            
            axis('tight');
            ylim(My_Ylims_c4);    
            
            
            subplot(4,5,4); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_lvl_ivolshk_qtr_4.oirf_var3(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_lvl_ivolshk_qtr_4.oirf_var3_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_lvl_ivolshk_qtr_4.oirf_var3_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);                                             
            %title(strcat('\fontsize{12}','Volatility Shock'));
            %xlabel('Quarters');
            %ylabel(MyVar_ylabel_4);
            title(strcat('\fontsize{12}',MyVar_title_4),'FontWeight','normal');
            %xlabel('Quarters');
            ylabel(' ');                            
            axis('tight');
            ylim(My_Ylims_c4);              
            
            
            % periodogram panel
            % see, e.g.: https://www.mathworks.com/help/signal/ref/periodogram.html
            [pxx_hp,  w_hp]  = periodogram(IRFout_hpfilter_ivolshk_4.oirf_var3(1:pgram_input_vector_length));
            [pxx_bp,  w_bp]  = periodogram(IRFout_bandpass_ivolshk_4.oirf_var3(1:pgram_input_vector_length));
            [pxx_lvl, w_lvl] = periodogram( IRFout_lvl_ivolshk_qtr_4.oirf_var3(1:pgram_input_vector_length));
            subplot(4,5,19); hold on; box on;
            if strcmp(pxx_show,'all')
                h(1) = plot(w_hp(1:pxx_vec_length),  pxx_hp(1:pxx_vec_length),  '-g', 'Linewidth', 1);
                h(2) = plot(w_bp(1:pxx_vec_length),  pxx_bp(1:pxx_vec_length),  '-b', 'Linewidth', 1);
                h(3) = plot(w_lvl(1:pxx_vec_length), pxx_lvl(1:pxx_vec_length), '-r', 'Linewidth', 2);               
                legend(h, 'HP','BP','Lvls','Location','northeast');
                clear h;
            elseif strcmp(pxx_show,'hp_and_lvls')
                h(1) = plot(w_hp(1:pxx_vec_length),  pxx_hp(1:pxx_vec_length),  '-g', 'Linewidth', 1);
                h(2) = plot(w_lvl(1:pxx_vec_length), pxx_lvl(1:pxx_vec_length), '-r', 'Linewidth', 2);                
                legend(h, 'HP','Lvls','Location','northeast');
                clear h;                
            end
            title(strcat('\fontsize{12}',' '));
            xlabel('\omega');  
            ylabel('Power/frequency'); 
            axis('tight');                     
            
            
            
        % quarterly data for var 5

            subplot(4,5,15); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_hpfilter_ivolshk_5.oirf_var3(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_hpfilter_ivolshk_5.oirf_var3_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_hpfilter_ivolshk_5.oirf_var3_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);                              
            %title(strcat('\fontsize{12}','Productivity Shock'));
            %xlabel('Quarters');
            %ylabel(MyVar_ylabel_5);
            %title(strcat('\fontsize{12}',MyVar_title_5),'FontWeight','normal');
            xlabel('Quarters');
            ylabel(' ');               
            axis('tight');
            if plot_model_lines
                ylim(My_Ylims_c5);
            else
                ylim(My_Ylims_c5);
            end                    
            

            subplot(4,5,10); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_bandpass_ivolshk_5.oirf_var3(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_bandpass_ivolshk_5.oirf_var3_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_bandpass_ivolshk_5.oirf_var3_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);                                             
            %title(strcat('\fontsize{12}','Volatility Shock'));
            %xlabel('Quarters');
            %ylabel(MyVar_ylabel_5);
            title(strcat('\fontsize{12}',' '));
            %xlabel('Quarters');
            ylabel(' ');                            
            axis('tight');
            ylim(My_Ylims_c5);    
            
            
            subplot(4,5,5); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_lvl_ivolshk_qtr_5.oirf_var3(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_lvl_ivolshk_qtr_5.oirf_var3_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_lvl_ivolshk_qtr_5.oirf_var3_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);                                             
            %title(strcat('\fontsize{12}','Volatility Shock'));
            %xlabel('Quarters');
            %ylabel(MyVar_ylabel_5);
            title(strcat('\fontsize{12}',MyVar_title_5),'FontWeight','normal');
            %xlabel('Quarters');
            ylabel(' ');                            
            axis('tight');
            ylim(My_Ylims_c5);              
            
            
            % periodogram panel
            % see, e.g.: https://www.mathworks.com/help/signal/ref/periodogram.html
            [pxx_hp,  w_hp]  = periodogram(IRFout_hpfilter_ivolshk_5.oirf_var3(1:pgram_input_vector_length));
            [pxx_bp,  w_bp]  = periodogram(IRFout_bandpass_ivolshk_5.oirf_var3(1:pgram_input_vector_length));
            [pxx_lvl, w_lvl] = periodogram( IRFout_lvl_ivolshk_qtr_5.oirf_var3(1:pgram_input_vector_length));
            subplot(4,5,20); hold on; box on;
            if strcmp(pxx_show,'all')
                h(1) = plot(w_hp(1:pxx_vec_length),  pxx_hp(1:pxx_vec_length),  '-g', 'Linewidth', 1);
                h(2) = plot(w_bp(1:pxx_vec_length),  pxx_bp(1:pxx_vec_length),  '-b', 'Linewidth', 1);
                h(3) = plot(w_lvl(1:pxx_vec_length), pxx_lvl(1:pxx_vec_length), '-r', 'Linewidth', 2);               
                legend(h, 'HP','BP','Lvls','Location','northeast');
                clear h;
            elseif strcmp(pxx_show,'hp_and_lvls')
                h(1) = plot(w_hp(1:pxx_vec_length),  pxx_hp(1:pxx_vec_length),  '-g', 'Linewidth', 1);
                h(2) = plot(w_lvl(1:pxx_vec_length), pxx_lvl(1:pxx_vec_length), '-r', 'Linewidth', 2);                
                legend(h, 'HP','Lvls','Location','northeast');
                clear h;                
            end
            title(strcat('\fontsize{12}',' '));
            xlabel('\omega');  
            ylabel('Power/frequency'); 
            axis('tight');               

            % add shock labels
            
                myfig = gcf;
            
                annotation(myfig,'textbox',...
                    [0.0265625 0.78 0.0515625 0.0840311679790023],...
                    'String',{'Variables','in Levels'},...
                    'LineStyle','none',...
                    'HorizontalAlignment','center',...
                    'FontWeight','bold',...
                    'FontSize',12,...
                    'FitBoxToText','off');    
            
                annotation(myfig,'textbox',...
                    [0.025 0.58 0.0515625 0.0840311679790026],...
                    'String',{'Medium','Cycle'},...
                    'LineStyle','none',...
                    'HorizontalAlignment','center',...
                    'FontWeight','bold',...
                    'FontSize',12,...
                    'FitBoxToText','off');      
                
                annotation(myfig,'textbox',...
                    [0.025 0.35 0.0515625 0.0840311679790026],...
                    'String',{'Business','Cycle'},...
                    'LineStyle','none',...
                    'HorizontalAlignment','center',...
                    'FontWeight','bold',...
                    'FontSize',12,...
                    'FitBoxToText','off');                   
                
                annotation(myfig,'textbox',...
                    [0.025 0.16 0.0515625 0.0840311679790026],...
                    'String',{'Periodograms'},...
                    'LineStyle','none',...
                    'HorizontalAlignment','center',...
                    'FontWeight','bold',...
                    'FontSize',12,...
                    'FitBoxToText','off');  
                
                
                annotation(myfig,'textbox',...
                    [0.025 0.13 0.0515625 0.0840311679790026],...
                    'String',{strcat('InputLength=',num2str(pgram_input_vector_length),'qtrs')},...
                    'LineStyle','none',...
                    'HorizontalAlignment','center',...
                    'FontWeight','bold',...
                    'FontSize',10,...
                    'FitBoxToText','off');                 
                
                
            
        % save jpg        
        saveas(2,strcat('figures/',fname),'png')
        saveas(2,strcat('figures/',fname)) 
        %saveas(2,strcat('output_for_paper/Figures/',fname),'png')
        %saveas(2,strcat('output_for_paper/Figures/',fname))  
        %close(2)                          
    
        
end % if 1==1 or 1==0



% additional figure with VAR done using level variables but no periodograms
if 1==1
    
  % plot 3x5 IRF where first row is hpfilter and second row is bandpass    
    %close(3);
    %fname = strcat('IRFs_OnlyVol_3x5_dtfp_or_tfp_ivol_',myinvvar_1,'_or_',myinvvar_2,'_or_',myinvvar_3,'_or_',myinvvar_4,'_or_',myinvvar_5,'_control_',myccvar);    
    fname = strcat('IRFs_OnlyVol_3x5_dtfp_or_tfp_ivol_',myinvvar_1,'_or_',myinvvar_2,'_or_',myinvvar_3,'_or_',myinvvar_4,'_or_',myinvvar_5,'_control_',myccvar,'_',num2str(sample_start_year));        
    figure(3);
    
        % set size of figure so it fills page
        set(gcf, 'PaperPositionMode', 'manual');
        set(gcf, 'PaperUnits', 'inches');
        set(gcf, 'PaperPosition', [0 0 14.00 7.00]);            
  
        IRF_length_plot = std_IRF_length_qtr+1;
        
        % quarterly data for var 1

            subplot(3,5,11); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_hpfilter_ivolshk_1.oirf_var3(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_hpfilter_ivolshk_1.oirf_var3_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_hpfilter_ivolshk_1.oirf_var3_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);        
            %title(strcat('\fontsize{12}',MyVar_title_1),'FontWeight','normal');
            xlabel('Quarters');
            ylabel('Percent');
            axis('tight');
            ylim(My_Ylims_c1);
            

            subplot(3,5,6); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_bandpass_ivolshk_1.oirf_var3(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_bandpass_ivolshk_1.oirf_var3_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_bandpass_ivolshk_1.oirf_var3_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);              
            %title(strcat('\fontsize{12}','Volatility Shock'));
            %xlabel('Quarters');
            %ylabel(MyVar_ylabel_1);
            title(strcat('\fontsize{12}',' '));
            %xlabel('Quarters');
            ylabel('Percent');            
            axis('tight');
            ylim(My_Ylims_c1);        
        
            
            subplot(3,5,1); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_lvl_ivolshk_qtr_1.oirf_var3(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_lvl_ivolshk_qtr_1.oirf_var3_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_lvl_ivolshk_qtr_1.oirf_var3_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);            
            %xlabel('Quarters');
            %ylabel(MyVar_ylabel_1);
            title(strcat('\fontsize{12}',MyVar_title_1),'FontWeight','normal');
            %xlabel('Quarters');
            ylabel('Percent');            
            axis('tight');
            ylim(My_Ylims_c1);              
           
            
        % quarterly data for var 2

            subplot(3,5,12); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_hpfilter_ivolshk_2.oirf_var3(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_hpfilter_ivolshk_2.oirf_var3_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_hpfilter_ivolshk_2.oirf_var3_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);              
            %title(strcat('\fontsize{12}',MyVar_title_2),'FontWeight','normal');
            xlabel('Quarters');
            ylabel(' ');            
            axis('tight');
            ylim(My_Ylims_c2);

            subplot(3,5,7); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_bandpass_ivolshk_2.oirf_var3(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_bandpass_ivolshk_2.oirf_var3_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_bandpass_ivolshk_2.oirf_var3_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);                          
            %title(strcat('\fontsize{12}','Volatility Shock'));
            %xlabel('Quarters');
            %ylabel(MyVar_ylabel_2);
            title(strcat('\fontsize{12}',' '));
            %xlabel('Quarters');
            ylabel(' ');                
            axis('tight');
            ylim(My_Ylims_c2);
   
            
            subplot(3,5,2); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_lvl_ivolshk_qtr_2.oirf_var3(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_lvl_ivolshk_qtr_2.oirf_var3_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_lvl_ivolshk_qtr_2.oirf_var3_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);                          
            title(strcat('\fontsize{12}',MyVar_title_2),'FontWeight','normal');
            %xlabel('Quarters');
            %ylabel(MyVar_ylabel_2);
            %title(strcat('\fontsize{12}',' '));
            %xlabel('Quarters');
            ylabel(' ');                
            axis('tight');
            ylim(My_Ylims_c2);            
            
           
        % quarterly data for var 3

            subplot(3,5,13); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_hpfilter_ivolshk_3.oirf_var3(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_hpfilter_ivolshk_3.oirf_var3_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_hpfilter_ivolshk_3.oirf_var3_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);                              
            %title(strcat('\fontsize{12}','Productivity Shock'));
            xlabel('Quarters');
            %ylabel(MyVar_ylabel_3);
            %title(strcat('\fontsize{12}',MyVar_title_3),'FontWeight','normal');
            %xlabel(' ');
            ylabel(' ');               
            axis('tight');
            ylim(My_Ylims_c3);        
            

            subplot(3,5,8); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_bandpass_ivolshk_3.oirf_var3(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_bandpass_ivolshk_3.oirf_var3_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_bandpass_ivolshk_3.oirf_var3_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);                                               
            %title(strcat('\fontsize{12}','Volatility Shock'));
            %xlabel('Quarters');
            %ylabel(MyVar_ylabel_3);
            title(strcat('\fontsize{12}',' '));
            %xlabel('Quarters');
            ylabel(' ');                            
            axis('tight');
            ylim(My_Ylims_c3);      
            
            
            subplot(3,5,3); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_lvl_ivolshk_qtr_3.oirf_var3(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_lvl_ivolshk_qtr_3.oirf_var3_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_lvl_ivolshk_qtr_3.oirf_var3_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);                                               
            %title(strcat('\fontsize{12}','Volatility Shock'));
            %xlabel('Quarters');
            %ylabel(MyVar_ylabel_3);
            title(strcat('\fontsize{12}',MyVar_title_3),'FontWeight','normal');
            %xlabel('Quarters');
            ylabel(' ');                            
            axis('tight');
            ylim(My_Ylims_c3);      
                 
          

        % quarterly data for var 4

            subplot(3,5,14); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_hpfilter_ivolshk_4.oirf_var3(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_hpfilter_ivolshk_4.oirf_var3_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_hpfilter_ivolshk_4.oirf_var3_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);                              
            %title(strcat('\fontsize{12}','Productivity Shock'));
            xlabel('Quarters');
            %ylabel(MyVar_ylabel_4);
            %title(strcat('\fontsize{12}',MyVar_title_4),'FontWeight','normal');
            %xlabel(' ');
            ylabel(' ');               
            axis('tight');
            if plot_model_lines
                ylim(My_Ylims_c4);
            else
                ylim(My_Ylims_c4);
            end                    
            

            subplot(3,5,9); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_bandpass_ivolshk_4.oirf_var3(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_bandpass_ivolshk_4.oirf_var3_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_bandpass_ivolshk_4.oirf_var3_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);                                             
            %title(strcat('\fontsize{12}','Volatility Shock'));
            %xlabel('Quarters');
            %ylabel(MyVar_ylabel_4);
            title(strcat('\fontsize{12}',' '));
            %xlabel('Quarters');
            ylabel(' ');                            
            axis('tight');
            ylim(My_Ylims_c4);    
            
            
            subplot(3,5,4); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_lvl_ivolshk_qtr_4.oirf_var3(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_lvl_ivolshk_qtr_4.oirf_var3_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_lvl_ivolshk_qtr_4.oirf_var3_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);                                             
            %title(strcat('\fontsize{12}','Volatility Shock'));
            %xlabel('Quarters');
            %ylabel(MyVar_ylabel_4);
            title(strcat('\fontsize{12}',MyVar_title_4),'FontWeight','normal');
            %xlabel('Quarters');
            ylabel(' ');                            
            axis('tight');
            ylim(My_Ylims_c4);              
       
            
        % quarterly data for var 5

            subplot(3,5,15); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_hpfilter_ivolshk_5.oirf_var3(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_hpfilter_ivolshk_5.oirf_var3_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_hpfilter_ivolshk_5.oirf_var3_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);                              
            %title(strcat('\fontsize{12}','Productivity Shock'));
            %xlabel('Quarters');
            %ylabel(MyVar_ylabel_5);
            %title(strcat('\fontsize{12}',MyVar_title_5),'FontWeight','normal');
            xlabel('Quarters');
            ylabel(' ');               
            axis('tight');
            if plot_model_lines
                ylim(My_Ylims_c5);
            else
                ylim(My_Ylims_c5);
            end                    
            

            subplot(3,5,10); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_bandpass_ivolshk_5.oirf_var3(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_bandpass_ivolshk_5.oirf_var3_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_bandpass_ivolshk_5.oirf_var3_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);                                             
            %title(strcat('\fontsize{12}','Volatility Shock'));
            %xlabel('Quarters');
            %ylabel(MyVar_ylabel_5);
            title(strcat('\fontsize{12}',' '));
            %xlabel('Quarters');
            ylabel(' ');                            
            axis('tight');
            ylim(My_Ylims_c5);    
            
            
            subplot(3,5,5); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_lvl_ivolshk_qtr_5.oirf_var3(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_lvl_ivolshk_qtr_5.oirf_var3_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_lvl_ivolshk_qtr_5.oirf_var3_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);                                             
            %title(strcat('\fontsize{12}','Volatility Shock'));
            %xlabel('Quarters');
            %ylabel(MyVar_ylabel_5);
            title(strcat('\fontsize{12}',MyVar_title_5),'FontWeight','normal');
            %xlabel('Quarters');
            ylabel(' ');                            
            axis('tight');
            ylim(My_Ylims_c5);              
               

            % add shock labels
            
                myfig = gcf;
            
                annotation(myfig,'textbox',...
                    [0.0265625 0.78 0.0515625 0.0840311679790023],...
                    'String',{'Variables','in Levels'},...
                    'LineStyle','none',...
                    'HorizontalAlignment','center',...
                    'FontWeight','bold',...
                    'FontSize',12,...
                    'FitBoxToText','off');    
            
                annotation(myfig,'textbox',...
                    [0.025 0.48 0.0515625 0.0840311679790026],...
                    'String',{'Medium','Cycle'},...
                    'LineStyle','none',...
                    'HorizontalAlignment','center',...
                    'FontWeight','bold',...
                    'FontSize',12,...
                    'FitBoxToText','off');      
                
                annotation(myfig,'textbox',...
                    [0.025 0.18 0.0515625 0.0840311679790026],...
                    'String',{'Business','Cycle'},...
                    'LineStyle','none',...
                    'HorizontalAlignment','center',...
                    'FontWeight','bold',...
                    'FontSize',12,...
                    'FitBoxToText','off');                   
                            
            
        % save jpg        
        saveas(3,strcat('figures/',fname),'png')
        saveas(3,strcat('figures/',fname)) 
        %saveas(3,strcat('output_for_paper/Figures/',fname),'png')
        %saveas(3,strcat('output_for_paper/Figures/',fname))  
        %close(3)                          
     
        
        
        
end % if 1==1 or 1==0


%% create 1x2 figure that compares models vs 4-variable data VAR
%  for either Ig/Y or NonDefIg/Y

clc;

% cc control var
%ccvarlist = {'none'};
ccvarlist = {'baa10ym'};
%ccvarlist = {'none'; 'baa10ym';'aaa10ym'};
ccc = 1;
myccvar = char(ccvarlist{ccc});

% VAR specs for panels 1, 2, 3, and 4
%VARspecs = {'bandpass','bandpass','bandpass','bandpass'}; % 
myVARspec = 'bandpass';

% for appendix figure
var4_choice_list = {'Ig_Y','Ig_less_def_Y'};
My_Ylims_1 = [-0.5,1.0];
My_Ylims_2 = [-0.5,1.0];
modnumlist = [82, 79]; % 79 is specifically recalibrated EGI
mytitle_1 = 'Total I_g, Benchmark Model';    
mytitle_2 = 'Nondefense I_g, Recalibrated Model';

% compute IRF for data VAR
for vvv=1:length(var4_choice_list)
    
    var4_choice = var4_choice_list{vvv}; 
    
    % figure out starting and ending positions
    sample_start_year = 1972;
    sample_end_year   = 2016;     
    if strcmp(myVARspec,'levels')
        pos_start_macro  = find((data_macro_qtr.year>=sample_start_year),1,'first');        
    else % need extra period for filtering        
        pos_start_macro = find((data_macro_qtr.year>=sample_start_year),1,'first') - 1; 
    end    
    pos_end_macro   = find((data_macro_qtr.year<=sample_end_year),1,'last');
    pos_start_invreg = find((data_inv_reg_qtr.year>=sample_start_year),1,'first');        
    pos_end_invreg   = find((data_inv_reg_qtr.year<=sample_end_year),1,'last');  
    disp(char(strcat({'macro var data from '},num2str(data_macro_qtr.year(pos_start_macro)),'q',num2str(data_macro_qtr.qtr(pos_start_macro)))))
    disp(char(strcat({'macro var data to '},  num2str(data_macro_qtr.year(pos_end_macro)),  'q',num2str(data_macro_qtr.qtr(pos_end_macro)))))
    disp(char(strcat({'inv reg data from '},num2str(data_inv_reg_qtr.year(pos_start_invreg)),'q',num2str(data_inv_reg_qtr.qtr(pos_start_invreg)))))
    disp(char(strcat({'inv reg data to '},num2str(data_inv_reg_qtr.year(pos_end_invreg)),'q',num2str(data_inv_reg_qtr.qtr(pos_end_invreg)))))    
    
    % first three variables from investment regression
    if strcmp(myVARspec,'levels')
        var1 = data_macro_qtr.tfp( pos_start_macro:pos_end_macro); % tfp in levels
    else
        var1 = data_macro_qtr.dtfp( pos_start_macro+1:pos_end_macro)/4; % dtfp from macro data. need to convert back to quarterly rates from annualized rate
        %var1_chk = data_inv_reg_qtr.dtfp( pos_start_invreg:pos_end_invreg); % dtfp from inv reg data
        %chk_diff = abs(var1 - var1_chk);
        %max(chk_diff)
        %[var1, var1_chk]
    end
    var2 = data_inv_reg_qtr.x( pos_start_invreg:pos_end_invreg);
    var3 = data_inv_reg_qtr.expvol( pos_start_invreg:pos_end_invreg);
    
    % 4th variable that may be filtered depending myVARspec
    eval(strcat('var4_raw_qtr = data_macro_qtr.',var4_choice,';'));
    var4_trunc = var4_raw_qtr(pos_start_macro:pos_end_macro); % truncated series to match other series
    if strcmp(myVARspec,'levels') % simply compute in log levels
        temp_var4_qtr = log(var4_trunc); 
    else % de-trend 4th variable 
        
        temp_var4_qtr = nan(size(var4_trunc));

        % HP filter. use pos_start+1 because no need to take first differences
        if strcmp(myVARspec,'hpfilter')            
            raw_var4_qtr     = log(var4_trunc(2:end));
            smooth_var4_qtr  = hpfilter(raw_var4_qtr, 1600); % quarterly data smoothing 
            temp_var4_qtr    = raw_var4_qtr - smooth_var4_qtr;
        end   
        
        % Comin Gertler (2006) band-pass
        % The function is bandpass(X,pl,pu). X is the raw data, pl and pu is the range of frequencies we want to extract. 
        % Recommended by Comin and Gertler (attached below), we should choose pl = 2 and pu = 200 for the quarterly data 
        % to extract the medium-term cycles. 
        if strcmp(myVARspec,'bandpass')  
            size(var4_trunc);
            raw_var4_qtr = log(var4_trunc(2:end)); % no reduction in size from bandpass --> need to cut first obs for VAR
            temp_var4_qtr = bandpass(raw_var4_qtr, 2, 200);
            size(temp_var4_qtr); % no reduction in size from bandpass                                
        end  
        
    end
   
    % series to enter VAR in levels 
    if strcmp(var4_choice,'Ig_Itot') ...
    || strcmp(var4_choice,'Ip_Itot') ...
    || strcmp(var4_choice,'Ig_Y') ...
    || strcmp(var4_choice,'Ig_less_def_Y') ...
    || strcmp(var4_choice,'labor_share_govt') ...
    || strcmp(var4_choice,'labor_share_priv') 
        var4 = exp(temp_var4_qtr);
    else
        var4 = temp_var4_qtr; % keep in logs
    end    
    
    % endogenous vars matrix
    temp_y_qtr = [var1, var2, var3, var4];
 
    % exogenous vars matrix
    temp_x_qtr = ones(size(temp_y_qtr,1),1);
    if ~strcmp(myccvar, 'none')
        eval(strcat('ccvar_raw_qtr = data_macro_qtr.',myccvar,';'));
        if strcmp(myVARspec,'levels') 
            temp_ccvar_qtr = ccvar_raw_qtr(pos_start_macro:pos_end_macro);
        else
            temp_ccvar_qtr = ccvar_raw_qtr(pos_start_macro+1:pos_end_macro);
        end
        temp_x_qtr = [temp_x_qtr, temp_ccvar_qtr];        
    end      

    eval(strcat('y_qtr_',num2str(vvv),' = temp_y_qtr;'));
    eval(strcat('x_exo_qtr_',num2str(vvv),' = temp_x_qtr;'));

    clear var4_raw_qtr var4_trunc temp_var4_qtr temp_y_qtr temp_x_qtr

    % define different shock matrices

        std_IRF_length_qtr = 24;

        % 1-std dtfp shock
        std_dtfp_shk_mat_qtr      = zeros(4 , std_IRF_length_qtr);
        std_dtfp_shk_mat_qtr(1,1) = 1;            

        % 1-std ivol shock
        std_ivol_shk_mat_qtr      = zeros(4 , std_IRF_length_qtr);
        std_ivol_shk_mat_qtr(3,1) = 1;             

        % compute IRFs for ivol shk
        eval(strcat('IRFout_ivolshk_qtr_',num2str(vvv),' = gen_IRF_vectors_dataVAR_nvars( y_qtr_',num2str(vvv),', x_exo_qtr_',num2str(vvv),', [], std_ivol_shk_mat_qtr, 0);'));

end
        
        
 % generate IRF vectors from the models
 for mmm = 1:length(modnumlist)   

    temp_modnum = modnumlist(mmm);

    % single unit impulse to exp(vol)

        std_IRF_length_qtr = 24;

        % std volatility level shock
        vol_shk_lev_mat_qtr      = zeros(2 , std_IRF_length_qtr);
        vol_shk_lev_mat_qtr(2,1) = log( std(data_inv_reg_qtr.expvol)+1 ); % log shock val to get 1-std dev in level of vol
        % NOTE: ex removed as shock in BCLR EndoGrowth

        % std tfp shock. note that TFP growth in the data VAR is in log
        % units according to Wenxi
        tfp_val_shk_mat_qtr      = zeros(2 , std_IRF_length_qtr);
        tfp_val_shk_mat_qtr(1,1) = std(data_inv_reg_qtr.dtfp); % shock val to log TFP growth

        disp(char(strcat({'Computing IRFs for model '},num2str(temp_modnum),{'...'})));

        % compute irfs for 1-unit vol shock and 1-unit tfp shock

            model_IRFout_1unit_tfp_qtr = gen_IRF_vectors_model( temp_modnum, [], [], 'lev', tfp_val_shk_mat_qtr);
            model_IRFout_1unit_vol_qtr = gen_IRF_vectors_model( temp_modnum, [], [], 'lev', vol_shk_lev_mat_qtr);

            % save IRF vector         
            if strcmp(var4_choice,'Yp_real')
                temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_logYp;
                temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_logYp;                                                                 
            elseif strcmp(var4_choice,'Y_real')
                temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_logY;
                temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_logY;                                                            
            elseif strcmp(var4_choice,'Ig_Y') || strcmp(var4_choice,'Ig_less_def_Y')
                temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_Ig_Y;
                temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_Ig_Y;                                                                            
            else
                error('var4_choice not recognized above');
            end                  
            eval(strcat('model_IRF_vol_line_',num2str(mmm),' = temp_model_IRF_vol_line;'));
            
        disp(char(strcat({'Done computing model IRFs!'})));
 
 end % mmm modnumlist
 
% create the 1x2 figure
close ALL
figure(1);

    %fname = strcat('IRFs_OnlyVol_data_vs_model_',var4_choice,'_control_',myccvar,'_1x2_',char(VARspecs{1}),'_',num2str(modnumlist(1)),'_vs_',num2str(modnumlist(2)));    
    fname = strcat('IRFs_OnlyVol_data_vs_model_',var4_choice,'_control_',myccvar,'_1x2_',char(myVARspec),'_',num2str(modnumlist(1)),'_vs_',num2str(modnumlist(2)));    

    % y label
    %for vvv = 1:length(var4_choice_set)
    if strcmp(var4_choice,'Yp_real')
        MyVar_ylabel = texlabel('log(Y_p)');
    elseif strcmp(var4_choice,'Y_real')
        MyVar_ylabel = texlabel('log(GDP)');
    elseif strcmp(var4_choice,'Ig_less_def_Y')
        MyVar_ylabel = texlabel('I_g / Y');        
    else
        error('var4_choice not recognized above');
    end     

    % set size of figure so it fills page
    set(gcf, 'PaperPositionMode', 'manual');
    set(gcf, 'PaperUnits', 'inches');
    %set(gcf, 'PaperPosition', [0 0 14.00 7.00]);            
    set(gcf, 'PaperPosition', [0 0 7.00 3.50]); % 1x2 plot

    %IRF_length_plot = std_IRF_length_qtr+1;
    % per May 18 2019 call with max, change length of IRF to 20 
    % periods when comparing data vs model
    IRF_length_plot = std_IRF_length_qtr+1-4;    

    subplot(1,2,1); hold on; box on;
    plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
    plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_1.oirf_var4(1:IRF_length_plot), '-b', 'Linewidth', 2);
        plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_1.oirf_var4_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
        plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_1.oirf_var4_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);
    plot(0:IRF_length_plot-1, 100*model_IRF_vol_line_1(1:IRF_length_plot), ':r', 'Linewidth', 3);
    title(strcat('\fontsize{12}',mytitle_1),'FontWeight','normal');
    xlabel(' ');
    ylabel(MyVar_ylabel);               
    axis('tight');
    ylim(My_Ylims_1);
         
    subplot(1,2,2); hold on; box on;
    plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
    h(1) = plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_2.oirf_var4(1:IRF_length_plot), '-b', 'Linewidth', 2);
        plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_2.oirf_var4_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
        plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_2.oirf_var4_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);
    h(2) = plot(0:IRF_length_plot-1, 100*model_IRF_vol_line_2(1:IRF_length_plot), ':r', 'Linewidth', 3);
    title(strcat('\fontsize{12}',mytitle_2),'FontWeight','normal');
    xlabel(' ');
    %ylabel(temp_MyVar_ylabel);               
    axis('tight');
    ylim(My_Ylims_2);
    legend(h,'Data','Model','Location','northeast');
    clear h;
    
    % save jpg        
    saveas(1,strcat('figures/',fname),'png')
    saveas(1,strcat('figures/',fname)) 
    %saveas(1,strcat('output_for_paper/Figures/',fname),'png')
    %saveas(1,strcat('output_for_paper/Figures/',fname))                     
    %close(1)                           




    
%% 1x3 figures: compare response vol shk of 4-variable VAR against model
%: RESTUD response checks december 2021

clc;

% list of modnum values to run
% revised list starting in June 2020
modnumlist = [81, 84, 85, 86 ]; 
%modnumlist = [84]; 
%modnumlist = [82, 83]; 
%modnumlist = [81]; 
%modnumlist = [150, 151]; 
%modnumlist = [152, 153]; 
%modnumlist = [154]; 
%modnumlist = [93, 94]; % alternate list to try when testing new cals in october 2020
%modnumlist = [96, 97]; % alternate list to try when testing new cals in october 2020
% Benchmark: model 81
% No government aka No L sector: model 84
% CRRA gamma = 0.5: model 86
% CRRA gamma = 10: model 85

sample_start_year=1972; % consistent with micro data

%filterlist = {'hpfilter'}; % note that filterlist = {'lindetrend'} works 
%filterlist = {'bandpass'}; % 
filterlist = {'levels'};
%filterlist = {'hpfilter','bandpass'}; % 
%filterlist = {'hpfilter','bandpass','levels'}; % 

% credit control var
ccvarlist = {'baa10ym'};
%ccvarlist = {'none'};
%ccvarlist = {'none'; 'baa10ym';'aaa10ym'};
%ccvarlist = {'none'; 'baa10ym';'aaa10ym';'nfci';'anfci'};

for myset = 2:6
%for myset = 2:2
 for mmm = 1:length(modnumlist)
  for fff = 1:length(filterlist)
   for ccc = 1:length(ccvarlist)

    if myset==1
        var_set = {'IPPrnd_real';'Ip_real';'Ig_real'}; 
        My_Ylims_c1 = [-2.0, 2.0];
        My_Ylims_c2 = [-2.0, 2.0];        
        My_Ylims_c3 = [-12.0, 12.0];      
    elseif myset==2
        var_set = {'IPPrnd_Itot';'IPPrnd_Itot_Incl_Govt';'IPPrnd_Itot_Incl_NonDefGovt'}; 
        My_Ylims_c1 = [-2.0, 1.0];                      
        My_Ylims_c2 = [-2.0, 1.0];    
        My_Ylims_c3 = [-2.0, 1.0];     
    elseif myset==3
        var_set = {'IPPrnd_Ip';'Ipfix_IPPrnd';'ipptot_ip'}; 
        My_Ylims_c1 = [-1.5, 1.5];                      
        My_Ylims_c2 = [-1.5, 1.5];    
        My_Ylims_c3 = [-1.5, 1.5];          
    elseif myset==4
        var_set = {'IPPrnd_Ip';'Igrnd_Igtot';'Igrndexdef_Igtot'}; 
        My_Ylims_c1 = [-1.0, 1.0];                      
        My_Ylims_c2 = [-1.0, 1.0];    
        My_Ylims_c3 = [-1.0, 1.0];  
    elseif myset==5
        var_set = {'IPPrnd_Itot_Incl_Govt';'IPPrnd_Itot_Incl_NonDefGovt';'IPPrnd_Itot_Excl_DefGovt'}; 
        My_Ylims_c1 = [-2.0, 1.0];                      
        My_Ylims_c2 = [-2.0, 1.0];    
        My_Ylims_c3 = [-2.0, 1.0];          
    elseif myset==6
        var_set = {'Ip_IPPrnd';'Ipfix_IPPrnd';'Ipfix_IPPrnd'}; 
        My_Ylims_c1 = [-2.0, 1.0];
        My_Ylims_c2 = [-2.0, 1.0];        
        My_Ylims_c3 = [-2.0, 1.0];    
    elseif myset==7
        var_set = {'IPPrnd_real';'IPPrnd_Ip';'IPPrnd_Itot'}; 
        My_Ylims_c1 = [-5.0, 5.0];
        My_Ylims_c2 = [-5.0, 5.0];        
        My_Ylims_c3 = [-5.0, 5.0];             
    else
        error('var_set for myset value not specified above');
    end
       
       
    % model to compare against
    %modnum_to_compare = 105; % benchmark
    %modnum_to_compare = 603; 
    %modnum_to_compare = 405; 
    %modnum_to_compare = 404;    
    modnum_to_compare = modnumlist(mmm);       
       
    % assign variables
    myfilter = char(filterlist{fff});
    myinvvar_1 = char(var_set{1});
    myinvvar_2 = char(var_set{2});
    myinvvar_3 = char(var_set{3});
    %myinvvar_4 = char(var_set{4});
    myccvar = char(ccvarlist{ccc});

    % generate IRF vectors from the models

        % single unit impulse to exp(vol)
        
            std_IRF_length_qtr = 24;

            % std volatility level shock
            vol_shk_lev_mat_qtr      = zeros(2 , std_IRF_length_qtr);
            vol_shk_lev_mat_qtr(2,1) = log( std(data_inv_reg_qtr.expvol)+1 ); % log shock val to get 1-std dev in level of vol
            % NOTE: ex removed as shock in BCLR EndoGrowth

            % std tfp shock. note that TFP growth in the data VAR is in log
            % units according to Wenxi
            tfp_val_shk_mat_qtr      = zeros(2 , std_IRF_length_qtr);
            tfp_val_shk_mat_qtr(1,1) = std(data_inv_reg_qtr.dtfp); % shock val to log TFP growth

            disp(char(strcat({'Computing IRFs for model '},num2str(modnum_to_compare),{'...'})));

            % compute irfs for 1-unit vol shock and 1-unit tfp shock

                model_IRFout_1unit_tfp_qtr = gen_IRF_vectors_model( modnum_to_compare, [], [], 'lev', tfp_val_shk_mat_qtr);
                model_IRFout_1unit_vol_qtr = gen_IRF_vectors_model( modnum_to_compare, [], [], 'lev', vol_shk_lev_mat_qtr);
                
            disp(char(strcat({'Done computing model IRFs!'})));
    
    % assign variable labels
    for varnum=1:3
        
        % temporary loop var name
        eval(strcat('temp_invvar = myinvvar_',num2str(varnum),';'));
             
        % figure out label based on name
        temp_MyVar_ylabel = 'NEED LABEL';
        temp_MyVar_title  = 'NEED TITLE';
        if strcmp(temp_invvar,'Ig_Itot')
            temp_MyVar_ylabel = 'I_g / (I_g + I_p)';
            temp_MyVar_title = 'Govt. to Total Inv. (I_t_o_t^g^o^v / (I_t_o_t^p^r^i^v+I_t_o_t^g^o^v))';
            temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_Ig_Itot;
            temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_Ig_Itot;                                           
        end
        if strcmp(temp_invvar,'Ip_Itot')
            temp_MyVar_ylabel = 'I_p / (I_g + I_p)';
            temp_MyVar_title = 'Priv. to Total Inv. (I_t_o_t^p^r^i^v / (I_t_o_t^p^r^i^v+I_t_o_t^g^o^v))';
            %error('need to add Ip_Itot to model IRF output');
            temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_Ip_Itot;
            temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_Ip_Itot;            
        end
        % xxx
        if strcmp(temp_invvar,'IPPrnd_Ip') 
            temp_MyVar_ylabel = 'I_R_&_D / (I_H + I_R_&_D)';
            temp_MyVar_title = 'I_R_&_D^p^r^i^v / I_t_o_t^p^r^i^v';
            %error('need to add Ip_Itot to model IRF output');
            temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_IPPrnd_Ip;
            temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_IPPrnd_Ip;            
        end  
        if strcmp(temp_invvar,'ipptot_ip') 
            temp_MyVar_ylabel = 'I_R_&_D / (I_H + I_R_&_D)';
            temp_MyVar_title = 'I_I_P_P^p^r^i^v / I_t_o_t^p^r^i^v';
            %error('need to add Ip_Itot to model IRF output');
            temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_IPPrnd_Ip;
            temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_IPPrnd_Ip;            
        end          
        if strcmp(temp_invvar,'IPPrnd_Ip_Incl_Govt')
            temp_MyVar_ylabel = 'I_R_&_D^t^o^t / (I_H + I_R_&_D)';
            temp_MyVar_title = 'I_R_&_D^t^o^t / I_t_o_t^p^r^i^v';
            %error('need to add Ip_Itot to model IRF output');
            temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_IPPrnd_Ip;
            temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_IPPrnd_Ip;            
        end       
        if strcmp(temp_invvar,'IPPrnd_Itot_Incl_Govt')
            temp_MyVar_ylabel = 'I_R_&_D^t^o^t / (I_L + I_H + I_R_&_D)';
            temp_MyVar_title = 'I_R_&_D^t^o^t / (I_t_o_t^p^r^i^v+I_t_o_t^g^o^v)';
            %error('need to add Ip_Itot to model IRF output');
            temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_IPPrnd_Itot;
            temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_IPPrnd_Itot;            
        end        
        if strcmp(temp_invvar,'IPPrnd_Itot_Incl_NonDefGovt')
            temp_MyVar_ylabel = 'I_R_&_D^t^o^t^n^o^n^d^e^f / (I_L + I_H + I_R_&_D)';
            temp_MyVar_title  = 'I_R_&_D^t^o^t^n^o^n^d^e^f / (I_t_o_t^p^r^i^v+I_t_o_t^g^o^v)';
            %error('need to add Ip_Itot to model IRF output');
            temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_IPPrnd_Itot;
            temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_IPPrnd_Itot;            
        end          
        if strcmp(temp_invvar,'IPPrnd_Itot_Excl_DefGovt')
            temp_MyVar_ylabel = 'I_R_&_D^t^o^t^n^o^n^d^e^f / (I_L + I_H + I_R_&_D)';
            temp_MyVar_title  = 'I_R_&_D^t^o^t^n^o^n^d^e^f / (I_t_o_t^p^r^i^v+I_n_o_n_d_e_f^g^o^v)';
            %error('need to add Ip_Itot to model IRF output');
            temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_IPPrnd_Itot;
            temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_IPPrnd_Itot;            
        end          
        if strcmp(temp_invvar,'Igrnd_Igtot')
            temp_MyVar_ylabel = 'I_R_&_D^g^o^v^t / I_t_o_t^g^o^v';
            temp_MyVar_title  = 'I_R_&_D^g^o^v^t / I_t_o_t^g^o^v';
            %error('need to add Ip_Itot to model IRF output');
            temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_IPPrnd_Itot;
            temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_IPPrnd_Itot;            
        end           
        if strcmp(temp_invvar,'Igrndexdef_Igtot')
            temp_MyVar_ylabel = 'I_R_&_D^g^o^v^t^n^o^n^d^e^f / I_t_o_t^g^o^v';
            temp_MyVar_title  = 'I_R_&_D^g^o^v^t^n^o^n^d^e^f / I_t_o_t^g^o^v';
            %error('need to add Ip_Itot to model IRF output');
            temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_IPPrnd_Itot;
            temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_IPPrnd_Itot;            
        end           
        if strcmp(temp_invvar,'IPPrnd_Itot')
            temp_MyVar_ylabel = 'I_R_&_D^p^r^i^v / (I_L + I_H + I_R_&_D)';
            temp_MyVar_title = 'I_R_&_D^p^r^i^v / (I_t_o_t^p^r^i^v+I_t_o_t^g^o^v)';
            %error('need to add Ip_Itot to model IRF output');
            temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_IPPrnd_Itot;
            temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_IPPrnd_Itot;            
        end          
        if strcmp(temp_invvar,'COMP_IPPrnd_Ip')
            temp_MyVar_ylabel = 'I_R_&_D / (I_H + I_R_&_D)';
            temp_MyVar_title = 'I_R_&_D / (I_H + I_R_&_D)';
            %error('need to add Ip_Itot to model IRF output');
            temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_IPPrnd_Ip;
            temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_IPPrnd_Ip;            
        end    
        if strcmp(temp_invvar,'Ip_IPPrnd')
            temp_MyVar_ylabel = '(I_H + I_R_&_D) / I_R_&_D';
            temp_MyVar_title = 'I_t_o_t^p^r^i^v / I_R_&_D^p^r^i^v';
            %error('need to add Ip_Itot to model IRF output');
            temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_Ip_IPPrnd;
            temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_Ip_IPPrnd;            
        end        
        if strcmp(temp_invvar,'Ipfix_IPPrnd')
            temp_MyVar_ylabel = 'I_H / I_R_&_D';
            temp_MyVar_title = 'I_n_o_t_r_n_d^p^r^i^v / I_R_&_D^p^r^i^v';
            %error('need to add Ip_Itot to model IRF output');
            temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_Ipfix_IPPrnd;
            temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_Ipfix_IPPrnd;            
        end    
        if strcmp(temp_invvar,'COMP_Ip_IPPrnd')
            temp_MyVar_ylabel = '(I_H + I_R_&_D) / I_R_&_D';
            temp_MyVar_title = '(I_H + I_R_&_D) / I_R_&_D';
            %error('need to add Ip_Itot to model IRF output');
            temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_Ip_IPPrnd;
            temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_Ip_IPPrnd;            
        end          
        if strcmp(temp_invvar,'Ig_Y')
            temp_MyVar_ylabel = 'I_g / Y';
            temp_MyVar_title = 'Govt. to GDP (I_g / Y)';
            temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_Ig_Y;
            temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_Ig_Y;
        end        
        if strcmp(temp_invvar,'IPPtot_real')
            temp_MyVar_ylabel = texlabel('log(I_I_P_P)');
            temp_MyVar_title = 'Priv. IPP (incl. R&D) Inv. (log(I_I_P_P))';
            error('need to add IPPtot_real to model IRF output');         
        end
        if strcmp(temp_invvar,'IPPrnd_real')
            temp_MyVar_ylabel = texlabel('log(I_R_&_D)');
            %temp_MyVar_title = 'Priv. R&D Inv. (log(I_R_&_D))';
            %temp_MyVar_title = 'R&D Inv. (log(I_R_&_D))';
            temp_MyVar_title = 'log(I_R_&_D^p^r^i^v)';
            temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_logIPPrnd;
            temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_logIPPrnd;            
        end
        if strcmp(temp_invvar,'COMP_IPPrnd_real')
            temp_MyVar_ylabel = texlabel('log(I_R_&_D)');
            %temp_MyVar_title = 'Priv. R&D Inv. (log(I_R_&_D))';
            %temp_MyVar_title = 'R&D Inv. (log(I_R_&_D))';
            temp_MyVar_title = 'log(I_R_&_D)';
            temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_logIPPrnd;
            temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_logIPPrnd;            
        end        
        if strcmp(temp_invvar,'Ig_real')
            temp_MyVar_ylabel = texlabel('log(I_g)');
            temp_MyVar_title = 'log(I_t_o_t^g^o^v^t)';
            temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_logIg;
            temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_logIg;                        
        end
        if strcmp(temp_invvar,'Ip_real')
            temp_MyVar_ylabel = texlabel('log(I_p)');
            %temp_MyVar_title = 'Priv. Total Inv. (log(I_p))';
            %temp_MyVar_title = 'Tangible Inv. (log(I_H))';
            temp_MyVar_title = 'log(I_t_o_t^p^r^i^v)';
            temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_logIp;
            temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_logIp;
            %temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_dip;
            %temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_dip;            
        end    
        if strcmp(temp_invvar,'COMP_Ip_real')
            temp_MyVar_ylabel = texlabel('log(I_p)');
            temp_MyVar_title = 'log(I_H+I_R_&_D)';
            temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_logIp;
            temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_logIp;
        end           
        if strcmp(temp_invvar,'Ip_NOTrnd_real')
            temp_MyVar_ylabel = texlabel('log(I_p-I_R_&_D)');
            temp_MyVar_title = 'Priv. Non-R&D Inv. (log(I_p-I_R_&_D))';
            error('need to add Ip_NOTrnd_real to model IRF output');         
        end            
        if strcmp(temp_invvar,'Itot_real')
            temp_MyVar_ylabel = texlabel('log(I_p+I_g)');
            temp_MyVar_title = 'Total Inv. (log(I_p+I_g))';
            temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_logIp;
            temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_logIp;
            disp('Need to fix model variable to be correct');
            beep;
        end            
        if strcmp(temp_invvar,'Itang_v1_real')
            temp_MyVar_ylabel = texlabel('log(I_t_a_n_g)');
            temp_MyVar_title = 'Tangible Inv. (log(I_p+I_g-I_R_&_D))';
            temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_logIp;
            temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_logIp;
            disp('Need to fix model variable to be correct');
            beep;
        end            
        if strcmp(temp_invvar,'Itang_v2_real')
            temp_MyVar_ylabel = texlabel('log(I_t_a_n_g)');
            temp_MyVar_title = 'Tangible Inv. (log(I_p+I_g-I_I_P_P))';
            temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_logIp;
            temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_logIp;
            disp('Need to fix model variable to be correct');
            beep;
        end                            
        if strcmp(temp_invvar,'Yp_real')
            temp_MyVar_ylabel = texlabel('log(Y_p)');
            %temp_MyVar_title = 'Priv. Output (log(Y_p))';
            %temp_MyVar_title = 'Output (log(Y))';
            temp_MyVar_title = 'log(Y_H)';
            temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_logYp;
            temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_logYp;                                                            
        end          
        if strcmp(temp_invvar,'Y_real')
            temp_MyVar_ylabel = texlabel('log(Y_G_D_P)');
            temp_MyVar_title = 'GDP (log(Y_G_D_P))';
            temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_logY;
            temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_logY;                                                            
        end                  
        if strcmp(temp_invvar,'ln_labor_priv')
            temp_MyVar_ylabel = texlabel('log(L_P)');
            temp_MyVar_title = 'Private Labor (log(L_P))';
            temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_np;
            temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_np;                                                            
        end   
        if strcmp(temp_invvar,'ln_labor_govt')
            temp_MyVar_ylabel = texlabel('log(L_G)');
            temp_MyVar_title = 'Govt. Labor (log(L_G))';
            temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_nc;
            temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_nc;                                                            
        end           
        if strcmp(temp_invvar,'ln_labor_tot')
            temp_MyVar_ylabel = texlabel('log(L_P+L_G)');
            temp_MyVar_title = 'Total Labor (log(L_P+L_G))';
            temp_model_IRF_vol_line = model_IRFout_1unit_vol_qtr.oirf_ntotal;
            temp_model_IRF_tfp_line = model_IRFout_1unit_tfp_qtr.oirf_ntotal;                                                            
        end             
        
        % create shells of variables so code below does not break if we
        % comment out the VAR on simulated model data
        model_IRF_from_sim_and_VAR = nan(1);
        temp_model_IRF_sim_vol_line = nan(1);
        temp_model_IRF_sim_vol_line_ciL = nan(1);
        temp_model_IRF_sim_vol_line_ciU = nan(1);
        temp_model_IRF_sim_tfp_line = nan(1);
        temp_model_IRF_sim_tfp_line_ciL = nan(1);
        temp_model_IRF_sim_tfp_line_ciU = nan(1);
        
        % compute IRF from VAR on simulated model data
%         disp(char(strcat({'Computing IRFs for var '},num2str(varnum),{' of 4 from VAR on simulated modnum '},num2str(modnum_to_compare),{'...'})));
%         model_IRF_from_sim_and_VAR = gen_IRF_vectors_model_using_sim_data( modnum_to_compare, temp_invvar, myfilter);
%         temp_model_IRF_sim_vol_line = model_IRF_from_sim_and_VAR.evol_oirf_var4;
%         temp_model_IRF_sim_vol_line_ciL = model_IRF_from_sim_and_VAR.evol_oirf_var4_ciL;
%         temp_model_IRF_sim_vol_line_ciU = model_IRF_from_sim_and_VAR.evol_oirf_var4_ciU;        
%         temp_model_IRF_sim_tfp_line = model_IRF_from_sim_and_VAR.dtfp_oirf_var4;
%         temp_model_IRF_sim_tfp_line_ciL = model_IRF_from_sim_and_VAR.dtfp_oirf_var4_ciL;
%         temp_model_IRF_sim_tfp_line_ciU = model_IRF_from_sim_and_VAR.dtfp_oirf_var4_ciU;                 
%         disp(char(strcat({'Done with IRF from simulated model for var '},num2str(varnum),{'!'})));
        
        % assign label
        if varnum==1
            MyVar_ylabel_1 = texlabel(temp_MyVar_ylabel);
            MyVar_title_1  = texlabel(temp_MyVar_title);
            model_IRF_vol_line_1 = temp_model_IRF_vol_line;
            model_IRF_tfp_line_1 = temp_model_IRF_tfp_line;                        
            model_IRF_sim_vol_line_1     = temp_model_IRF_sim_vol_line;
            model_IRF_sim_vol_line_1_ciL = temp_model_IRF_sim_vol_line_ciL;
            model_IRF_sim_vol_line_1_ciU = temp_model_IRF_sim_vol_line_ciU;
            model_IRF_sim_tfp_line_1     = temp_model_IRF_sim_tfp_line;
            model_IRF_sim_tfp_line_1_ciL = temp_model_IRF_sim_tfp_line_ciL;
            model_IRF_sim_tfp_line_1_ciU = temp_model_IRF_sim_tfp_line_ciU;            
        end
        if varnum==2
            MyVar_ylabel_2 = texlabel(temp_MyVar_ylabel);
            MyVar_title_2  = texlabel(temp_MyVar_title);
            model_IRF_vol_line_2 = temp_model_IRF_vol_line;
            model_IRF_tfp_line_2 = temp_model_IRF_tfp_line;     
            model_IRF_sim_vol_line_2     = temp_model_IRF_sim_vol_line;
            model_IRF_sim_vol_line_2_ciL = temp_model_IRF_sim_vol_line_ciL;
            model_IRF_sim_vol_line_2_ciU = temp_model_IRF_sim_vol_line_ciU;
            model_IRF_sim_tfp_line_2     = temp_model_IRF_sim_tfp_line;
            model_IRF_sim_tfp_line_2_ciL = temp_model_IRF_sim_tfp_line_ciL;
            model_IRF_sim_tfp_line_2_ciU = temp_model_IRF_sim_tfp_line_ciU;                  
        end
        if varnum==3
            MyVar_ylabel_3 = texlabel(temp_MyVar_ylabel);
            MyVar_title_3  = texlabel(temp_MyVar_title);
            model_IRF_vol_line_3 = temp_model_IRF_vol_line;
            model_IRF_tfp_line_3 = temp_model_IRF_tfp_line; 
            model_IRF_sim_vol_line_3     = temp_model_IRF_sim_vol_line;
            model_IRF_sim_vol_line_3_ciL = temp_model_IRF_sim_vol_line_ciL;
            model_IRF_sim_vol_line_3_ciU = temp_model_IRF_sim_vol_line_ciU;
            model_IRF_sim_tfp_line_3     = temp_model_IRF_sim_tfp_line;
            model_IRF_sim_tfp_line_3_ciL = temp_model_IRF_sim_tfp_line_ciL;
            model_IRF_sim_tfp_line_3_ciU = temp_model_IRF_sim_tfp_line_ciU;               
        end
        if varnum==4
            MyVar_ylabel_4 = texlabel(temp_MyVar_ylabel);
            MyVar_title_4  = texlabel(temp_MyVar_title);
            model_IRF_vol_line_4 = temp_model_IRF_vol_line;
            model_IRF_tfp_line_4 = temp_model_IRF_tfp_line;                        
            model_IRF_sim_vol_line_4     = temp_model_IRF_sim_vol_line;
            model_IRF_sim_vol_line_4_ciL = temp_model_IRF_sim_vol_line_ciL;
            model_IRF_sim_vol_line_4_ciU = temp_model_IRF_sim_vol_line_ciU;
            model_IRF_sim_tfp_line_4     = temp_model_IRF_sim_tfp_line;
            model_IRF_sim_tfp_line_4_ciL = temp_model_IRF_sim_tfp_line_ciL;
            model_IRF_sim_tfp_line_4_ciU = temp_model_IRF_sim_tfp_line_ciU;               
        end        
        
        clearvars temp_model_IRF_vol_line temp_model_IRF_tfp_line;
        
    end
    
    % for checking: what is repsonse of vol to itself
    chk_model_expvol_resp_to_vol_shk = model_IRFout_1unit_vol_qtr.oirf_expvol;

    % compile quarterly data for each variable
    
    start_year_qtr = min(data_inv_reg_qtr.year);
    if sample_start_year==1961
        pos_start      = find((data_macro_qtr.year>=start_year_qtr),1,'first'); % start 1 qtr later so macro data is 1961Q1:2016Q4
    else        
        pos_start      = find((data_macro_qtr.year>=start_year_qtr),1,'first') - 1;        
    end
    disp(char(strcat({'macro var data from '},num2str(data_macro_qtr.year(pos_start)),'q',num2str(data_macro_qtr.qtr(pos_start)))))
    disp(char(strcat({'inv reg data from '},num2str(data_inv_reg_qtr.year(1)),'q',num2str(data_inv_reg_qtr.qtr(1)))))
    disp(char(strcat({'note: we want macro data to start 1 qtr before inv reg data b/c we take diffs of macro data to prepare them for VAR'})))

    % choose ending position such that de-meaned macro data series will be
    % the same length as the investment regression data series
    length_qtr_VAR = length(data_inv_reg_qtr.x);
    pos_end = pos_start+length_qtr_VAR;    
    
    % move pos_start later if credit variable with shorter history
    if strcmp(myccvar,'nfci') || strcmp(myccvar,'anfci') || strcmp(myccvar,'gzspr')
        pos_start = 105; % 1973q1: first date with FCIs and GZ index
        length_qtr_VAR = pos_end - pos_start; % update length
    end              
    
    for varnum=1:3           
        
        eval(strcat('tempvarname = myinvvar_',num2str(varnum),';'));
        
        eval(strcat('var4_raw_qtr = data_macro_qtr.',tempvarname,';'));
        
        % truncated series to match other series
        var4_trunc = var4_raw_qtr(pos_start:pos_end);

        % de-trend 4th variable using HP filter or something else                    
        if strcmp(myfilter,'levels') % simply compute in log levels
            temp_var4_qtr = log(var4_trunc(2:end)); 
        else % de-trend 4th variable         
        
        
            temp_var4_qtr = nan(size(var4_trunc));
        
            % HP filter. use pos_start+1 because no need to take first differences
            if strcmp(myfilter,'hpfilter')            
                raw_var4_qtr     = log(var4_trunc(2:end));
                smooth_var4_qtr  = hpfilter(raw_var4_qtr, 1600); % quarterly data smoothing 
                temp_var4_qtr    = raw_var4_qtr - smooth_var4_qtr;
            end

            % linear de-trend
            if strcmp(myfilter,'lindetrend')          
                temp_var4_qtr = prep_raw_data_for_VAR( var4_trunc) ;
            end
            
            % Comin Gertler (2006) band-pass
            % The function is bandpass(X,pl,pu). X is the raw data, pl and pu is the range of frequencies we want to extract. 
            % Recommended by Comin and Gertler (attached below), we should choose pl = 2 and pu = 200 for the quarterly data 
            % to extract the medium-term cycles. 
            if strcmp(myfilter,'bandpass')  
                
                size(var4_trunc);
                raw_var4_qtr = log(var4_trunc(2:end)); % no reduction in size from bandpass --> need to cut first obs for VAR
                temp_var4_qtr = bandpass(raw_var4_qtr, 2, 200);
                size(temp_var4_qtr); % no reduction in size from bandpass
                
                % visually compare to raw series                
%                 figure(1); box on; hold on;
% 
%                     yyaxis left
%                     h(1) = plot(temp_var4_qtr_plus_one,'-k', 'Linewidth', 0.7);
%                     yyaxis right
%                     h(2) = plot(raw_var4_qtr,'-r', 'Linewidth', 0.5);
%                     legend(h,['Bandpass(2,200)'],['Raw'],'Location','Northwest');
%                     title(strcat({'Raw vs Bandpass Series: '}, MyVar_title_1));
%                     clear h;
%                     fname = strcat('compare_bandpass_',tempvarname,'_vs_raw');
%                     saveas(1,strcat('Figures/',fname),'png')
%                     saveas(1,strcat('Figures/',fname))                 
%                     close(1)                       
                    
                % visually compare to hpfilter
%                 smooth_var4_qtr = hpfilter(raw_var4_qtr, 1600); % quarterly data smoothing 
%                 var_hpfilter    = raw_var4_qtr - smooth_var4_qtr;                
%                 figure(1); box on; hold on;
% 
%                     yyaxis left
%                     h(1) = plot(temp_var4_qtr,'-k', 'Linewidth', 0.7);
%                     yyaxis right
%                     h(2) = plot(100*var_hpfilter,'-r', 'Linewidth', 0.7);
%                     legend(h,['Bandpass(2,200), Left Axis'],['HP Filter(1600), Right Axis'],'Location','Northwest');
%                     title(strcat({'Bandpass vs HP Filter Series: '}, MyVar_title_1));
%                     clear h;
%                     fname = strcat('compare_bandpass_',tempvarname,'_vs_hpfilter');
%                     saveas(1,strcat('Figures/',fname),'png')
%                     saveas(1,strcat('Figures/',fname))                 
%                     close(1)                                           

            end
        end
                   
        % final dataset for VAR             
        if strcmp(myfilter,'levels') % simply compute in log levels
            %y_qtr_reg = [cumsum(data_inv_reg_qtr.dtfp(1:length_qtr_VAR)), data_inv_reg_qtr.x(1:length_qtr_VAR), data_inv_reg_qtr.expvol(1:length_qtr_VAR)];    
            % don't do first var as tfp because 4th var should be ratio
            % that is also stationary
            y_qtr_reg = [       data_inv_reg_qtr.dtfp(1:length_qtr_VAR),  data_inv_reg_qtr.x(1:length_qtr_VAR), data_inv_reg_qtr.expvol(1:length_qtr_VAR)];    
        else
            y_qtr_reg = [       data_inv_reg_qtr.dtfp(1:length_qtr_VAR),  data_inv_reg_qtr.x(1:length_qtr_VAR), data_inv_reg_qtr.expvol(1:length_qtr_VAR)];    
        end
        %if strcmp(tempvarname,'Ig_Itot') || strcmp(tempvarname,'Ip_Itot') % series to enter VAR in levels
        if strcmp(tempvarname,'Ig_Itot') ... % series to enter VAR in levels
                    || strcmp(tempvarname,'Ip_Itot') ...
                    || strcmp(tempvarname,'Ig_Y') ... 
                    || strcmp(tempvarname,'IPPrnd_Ip') ... 
                    || strcmp(tempvarname,'IPPrnd_Itot') ... 
                    || strcmp(tempvarname,'IPPrnd_Itot_Incl_Govt') ... 
                    || strcmp(tempvarname,'IPPrnd_Itot_Incl_NonDefGovt') ... 
                    || strcmp(tempvarname,'IPPrnd_Itot_Excl_DefGovt') ... 
                    || strcmp(tempvarname,'ipptot_ip') ... 
                    || strcmp(tempvarname,'IPPrnd_Ip') ... 
                    || strcmp(tempvarname,'Igrnd_Igtot') ... 
                    || strcmp(tempvarname,'Igrndexdef_Igtot') ... 
                    || strcmp(tempvarname,'COMP_IPPrnd_Ip') ...               
                    || strcmp(tempvarname,'Ip_IPPrnd') ...
                    || strcmp(tempvarname,'Ipfix_IPPrnd') ...
                    || strcmp(tempvarname,'COMP_Ip_IPPrnd')
            temp_y_qtr = [y_qtr_reg, exp(temp_var4_qtr)];    
        else
            temp_y_qtr = [y_qtr_reg, temp_var4_qtr];    
        end

        % final exogenous variable dataset for quarterly VAR
        temp_x_qtr = ones(size(temp_y_qtr,1),1);
        if ~strcmp(myccvar, 'none')
            eval(strcat('ccvar_raw_qtr = data_macro_qtr.',myccvar,';'));
            temp_ccvar_qtr = ccvar_raw_qtr(pos_start+1:pos_end);
            temp_x_qtr = [temp_x_qtr, temp_ccvar_qtr];        
        end      
        
        eval(strcat('y_qtr_',num2str(varnum),' = temp_y_qtr;'));
        eval(strcat('x_exo_qtr_',num2str(varnum),' = temp_x_qtr;'));
        
        clear var4_raw_qtr var4_trunc temp_var4_qtr temp_y_qtr temp_x_qtr
        
        % define different shock matrices

            std_IRF_length_qtr = 24;

            % 1-std dtfp shock
            std_dtfp_shk_mat_qtr      = zeros(4 , std_IRF_length_qtr);
            std_dtfp_shk_mat_qtr(1,1) = 1;            

            % 1-std ivol shock
            std_ivol_shk_mat_qtr      = zeros(4 , std_IRF_length_qtr);
            std_ivol_shk_mat_qtr(3,1) = 1;             
    
           
        % compute IRFs 

            % dtfp shk
            %IRFout_dtfpshk_qtr_1 = gen_IRF_vectors_dataVAR_nvars( y_qtr_1, x_exo_qtr_1, [], std_dtfp_shk_mat_qtr, 0);
            %IRFout_dtfpshk_qtr_2 = gen_IRF_vectors_dataVAR_nvars( y_qtr_2, x_exo_qtr_2, [], std_dtfp_shk_mat_qtr, 0);  
            eval(strcat('IRFout_dtfpshk_qtr_',num2str(varnum),' = gen_IRF_vectors_dataVAR_nvars( y_qtr_',num2str(varnum),', x_exo_qtr_',num2str(varnum),', [], std_dtfp_shk_mat_qtr, 0);'))
            %eval(strcat('IRFout_dtfpshk_qtr_',num2str(varnum),' = gen_IRF_vectors_dataVAR_nvars( y_qtr_',num2str(varnum),', x_exo_qtr_',num2str(varnum),', [], std_dtfp_shk_mat_qtr, 0, w_loop_val);'))

            % ivol shk
            %IRFout_ivolshk_qtr_1 = gen_IRF_vectors_dataVAR_nvars( y_qtr_1, x_exo_qtr_1, [], std_ivol_shk_mat_qtr, 0);
            %IRFout_ivolshk_qtr_2 = gen_IRF_vectors_dataVAR_nvars( y_qtr_2, x_exo_qtr_2, [], std_ivol_shk_mat_qtr, 0);              
            eval(strcat('IRFout_ivolshk_qtr_',num2str(varnum),' = gen_IRF_vectors_dataVAR_nvars( y_qtr_',num2str(varnum),', x_exo_qtr_',num2str(varnum),', [], std_ivol_shk_mat_qtr, 0);'));
            %eval(strcat('IRFout_ivolshk_qtr_',num2str(varnum),' = gen_IRF_vectors_dataVAR_nvars( y_qtr_',num2str(varnum),', x_exo_qtr_',num2str(varnum),', [], std_ivol_shk_mat_qtr, 0, w_loop_val);'));
            
    end

  

  
  % plot 1x3 IRF for vol shock only
  for plot_model_lines = 0:1; % run only with model lines for draft
    close ALL
    if plot_model_lines
        fname = strcat('IRFs_OnlyVol_data_vs_model_',num2str(modnum_to_compare),'_1x3_dtfp_x_expvol_',myinvvar_1,'_or_',myinvvar_2,'_or_',myinvvar_3,'_',myfilter,'_control_',myccvar);    
    else
        fname = strcat('IRFs_OnlyVol_1x3_dtfp_x_expvol_',myinvvar_1,'_or_',myinvvar_2,'_or_',myinvvar_3,'_',myfilter,'_control_',myccvar);    
    end  
    
    figure(1);
    
        % set size of figure so it fills page
        set(gcf, 'PaperPositionMode', 'manual');
        set(gcf, 'PaperUnits', 'inches');
        %set(gcf, 'PaperPosition', [0 0 14.00 3.50]);  
        %set(gcf, 'DefaultAxesPosition', [0.05, 0.1, 0.9, 0.9]);
        % make the figure fill the slide better
        set(gcf, 'PaperPosition', [0 0 11.00 3.50]);  
        set(gcf, 'DefaultAxesPosition', [0.05, 0.1, 0.92, 0.9]);
  
        % per May 18 2019 call with max, change length of IRF to 20 
        % periods when comparing data vs model
        if plot_model_lines
            IRF_length_plot = std_IRF_length_qtr+1-4;
        else
            IRF_length_plot = std_IRF_length_qtr+1;
        end
        
        % quarterly data for var 1
       
            subplot(1,3,1); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_1.oirf_var4(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_1.oirf_var4_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_1.oirf_var4_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);
            if plot_model_lines
                plot(0:IRF_length_plot-1, 100*model_IRF_vol_line_1(1:IRF_length_plot), '-r', 'Linewidth', 2);
            end                
            title(strcat('\fontsize{12}',MyVar_title_1),'FontWeight','normal');
            xlabel('Quarters');
            ylabel('Percent');            
            axis('tight');
            ylim(My_Ylims_c1);        
        
            
        % quarterly data for var 2

            subplot(1,3,2); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_2.oirf_var4(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_2.oirf_var4_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_2.oirf_var4_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);
            if plot_model_lines
                plot(0:IRF_length_plot-1, 100*model_IRF_vol_line_2(1:IRF_length_plot), '-r', 'Linewidth', 2);
            end                                
            title(strcat('\fontsize{12}',MyVar_title_2),'FontWeight','normal');
            xlabel('Quarters');
            ylabel(' ');                
            axis('tight');
            ylim(My_Ylims_c2);
   
            
        % quarterly data for var 3

            subplot(1,3,3); hold on; box on;
            h(2) = plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            h(1) = plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_3.oirf_var4(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_3.oirf_var4_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_qtr_3.oirf_var4_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);
            if plot_model_lines
                h(2) = plot(0:IRF_length_plot-1, 100*model_IRF_vol_line_3(1:IRF_length_plot), '-r', 'Linewidth', 2);
            end                                                
            title(strcat('\fontsize{12}',MyVar_title_3),'FontWeight','normal');
            xlabel('Quarters');
            ylabel(' ');                            
            axis('tight');
            ylim(My_Ylims_c3); 
            if plot_model_lines
                legend(h,'Data','Model','Location','northeast');
            end
            clear h;                

        % save jpg        
        saveas(1,strcat('figures/',fname),'png')
        saveas(1,strcat('figures/',fname)) 
        %saveas(1,strcat('output_for_paper/Figures/',fname),'png')
        %saveas(1,strcat('output_for_paper/Figures/',fname))
        %close(1)                  
  
  end
  
  
   end % ccc
  end % fff
 end % mmm
end % myset




%% 2x3 figure of 3-variable VAR: compare hpfilter vs bandpass
% try with R&D intensity ratios

clc;

% must do both filters in this section because they are both plotted
filterlist = {'bandpass','hpfilter','levels'}; % 
    
myvarset=2;

    % benchmark
    My_Ylims_c4 = [-0.5, 0.5];
    My_Ylims_c5 = [-0.5, 1.0];    
    if myvarset==1        
        %var_set = {'Ig_real';'IPPrnd_real';'Ip_real';'labor_share_govt';'Yp_real'}; 
        var_set = {'IPPrnd_real';'Ip_real';'Yp_real';'Ig_real';'labor_share_govt'}; 
        % note: only first 3 vars will be plotted. doing this way to avoid editing
        % below code too much
        My_Ylims_c1 = [-1.0, 0.5];
        My_Ylims_c2 = [-3.0, 1.0];   
        My_Ylims_c3 = [-1.0, 0.5];
    elseif myvarset==2
        var_set = {'IPPrnd_Itot';'IPPrnd_Itot_Incl_Govt';'IPPrnd_Itot_Incl_NonDefGovt';'Yp_real';'labor_share_govt'}; 
        My_Ylims_c1 = [-2.0, 1.0];
        My_Ylims_c2 = [-2.0, 1.0];   
        My_Ylims_c3 = [-2.0, 1.0];      
    elseif myvarset==3
        var_set = {'IPPrnd_Ip';'Ipfix_IPPrnd';'ipptot_ip';'Yp_real';'labor_share_govt'};             
        My_Ylims_c1 = [-1.0, 2.0];
        My_Ylims_c2 = [-4.0, 1.0];   
        My_Ylims_c3 = [-1.0, 2.0];          
    elseif myvarset==4
        var_set = {'IPPrnd_real';'Ip_real';'Ig_real';'Yp_real';'labor_share_govt'}; 
        My_Ylims_c1 = [-2.0, 1.0];
        My_Ylims_c2 = [-2.0, 1.0];   
        My_Ylims_c3 = [-2.0, 1.0];          
    else
        error('myvarset not specified')
    end
    
    % try with Itotal
    %var_set = {'Ig_real';'Itot_real';'Ip_real';'labor_share_govt';'Yp_real'}; 
    %My_Ylims_c2 = [-1.5, 0.5];
      
        
    % credit control
    ccvarlist = {'baa10ym'}; % benchmark
    %ccvarlist = {'none'};     
    %ccvarlist = {'none'; 'baa10ym';'aaa10ym'};
    %ccvarlist = {'none'; 'baa10ym';'aaa10ym';'nfci';'anfci'};
    
    % sample start year
    sample_start_year = 1972; % default value
    %sample_start_year = 1982; % referee robustness request
    
    % sample end year
    sample_end_year   = 2016;        


for ccc = 1:length(ccvarlist)
  for fff = 1:length(filterlist)
     
    % assign variables
    myfilter = char(filterlist{fff});
    myinvvar_1 = char(var_set{1});
    myinvvar_2 = char(var_set{2});
    myinvvar_3 = char(var_set{3});
    myinvvar_4 = char(var_set{4});
    myinvvar_5 = char(var_set{5});
    myccvar = char(ccvarlist{ccc});

  
    % assign variable labels
    for varnum=1:5
        
        % temporary loop var name
        eval(strcat('temp_invvar = myinvvar_',num2str(varnum),';'));
             
        % figure out label based on name
        temp_MyVar_ylabel = 'NEED LABEL';
        temp_MyVar_title  = 'NEED TITLE';
        if strcmp(temp_invvar,'Ig_Itot')
            temp_MyVar_ylabel = 'I_g / (I_g + I_p)';
            temp_MyVar_title = 'Govt. to Total Inv. (I_g / (I_g + I_p))';
        end        
        if strcmp(temp_invvar,'Ip_Itot')
            temp_MyVar_ylabel = 'I_p / (I_g + I_p)';
            temp_MyVar_title = 'Priv. to Total Inv. (I_p / (I_g + I_p))';
        end    
        if strcmp(temp_invvar,'IPPtot_real')
            temp_MyVar_ylabel = texlabel('log(I_I_P_P)');
            temp_MyVar_title = 'Priv. IPP (incl. R&D) Inv. (log(I_I_P_P))';
        end
        if strcmp(temp_invvar,'IPPrnd_real')
            temp_MyVar_ylabel = texlabel('log(I_R_&_D)');
            temp_MyVar_title = 'Priv. R&D Inv. (log(I_R_&_D))';
        end
        if strcmp(temp_invvar,'Ig_real')
            temp_MyVar_ylabel = texlabel('log(I_g)');
            temp_MyVar_title = 'Govt. Inv. (log(I_g))';
        end
        if strcmp(temp_invvar,'Ip_real')
            temp_MyVar_ylabel = texlabel('log(I_p)');
            temp_MyVar_title = 'Priv. Total Inv. (log(I_p))';
        end    
        if strcmp(temp_invvar,'Ip_NOTrnd_real')
            temp_MyVar_ylabel = texlabel('log(I_p-I_R_&_D)');
            temp_MyVar_title = 'Priv. Non-R&D Inv. (log(I_p-I_R_&_D))';
        end    
        if strcmp(temp_invvar,'Itot_real')
            temp_MyVar_ylabel = texlabel('log(I_g+I_p)');
            temp_MyVar_title = 'Total Inv. (log(I_g+I_p))';
        end            
        if strcmp(temp_invvar,'Itang_v1_real')
            temp_MyVar_ylabel = texlabel('log(I_g+I_p-I_R_&_D)');
            temp_MyVar_title = 'Tangible Inv. (log(I_g+I_p-I_R_&_D))';
        end                    
        if strcmp(temp_invvar,'Itang_v2_real')
            temp_MyVar_ylabel = texlabel('log(I_g+I_p-I_I_P_P)');
            temp_MyVar_title = 'Tangible Inv. (log(I_g+I_p-I_I_P_P))';
        end                                    
        if strcmp(temp_invvar,'Yp_real')
            temp_MyVar_ylabel = texlabel('log(Y_p)');
            temp_MyVar_title = 'Priv. Output (log(Y_p))';
        end          
        if strcmp(temp_invvar,'Y_real')
            temp_MyVar_ylabel = texlabel('log(Y_G_D_P)');
            temp_MyVar_title = 'GDP (log(Y_G_D_P))';
        end    
        if strcmp(temp_invvar,'dtfp_FMA05')
            temp_MyVar_ylabel = texlabel('Delta a_t_,_t_+_5yrs}');
            temp_MyVar_title = '5-year FMA dtfp';
        end         
        if strcmp(temp_invvar,'Ig_Y')
            temp_MyVar_ylabel = 'I_g / Y';
            temp_MyVar_title = 'Govt. to GDP (I_g / Y)';
        end      
        if strcmp(temp_invvar,'labor_share_govt')
            temp_MyVar_ylabel = 'L_g / (L_g + L_p)';
            temp_MyVar_title = 'Govt. Labor Share (L_g / (L_g + L_p))';            
        end         
        if strcmp(temp_invvar,'IPPrnd_Itot')
            temp_MyVar_ylabel = 'I_R_&_D^p^r^i^v / (I_L + I_H + I_R_&_D)';
            temp_MyVar_title = 'I_R_&_D^p^r^i^v / (I_t_o_t^p^r^i^v+I_t_o_t^g^o^v)';
        end         
        if strcmp(temp_invvar,'IPPrnd_Itot_Incl_Govt')
            temp_MyVar_ylabel = 'I_R_&_D^t^o^t / (I_L + I_H + I_R_&_D)';
            temp_MyVar_title = 'I_R_&_D^t^o^t / (I_t_o_t^p^r^i^v+I_t_o_t^g^o^v)';
        end        
        if strcmp(temp_invvar,'IPPrnd_Itot_Incl_NonDefGovt')
            temp_MyVar_ylabel = 'I_R_&_D^t^o^t^n^o^n^d^e^f / (I_L + I_H + I_R_&_D)';
            temp_MyVar_title  = 'I_R_&_D^t^o^t^n^o^n^d^e^f / (I_t_o_t^p^r^i^v+I_t_o_t^g^o^v)';
        end          
        if strcmp(temp_invvar,'IPPrnd_Itot_Excl_DefGovt')
            temp_MyVar_ylabel = 'I_R_&_D^t^o^t^n^o^n^d^e^f / (I_L + I_H + I_R_&_D)';
            temp_MyVar_title  = 'I_R_&_D^t^o^t^n^o^n^d^e^f / (I_t_o_t^p^r^i^v+I_n_o_n_d_e_f^g^o^v)';
        end     
        if strcmp(temp_invvar,'IPPrnd_Ip') 
            temp_MyVar_ylabel = 'I_R_&_D / (I_H + I_R_&_D)';
            temp_MyVar_title = 'I_R_&_D^p^r^i^v / I_t_o_t^p^r^i^v';
        end  
        if strcmp(temp_invvar,'ipptot_ip') 
            temp_MyVar_ylabel = 'I_R_&_D / (I_H + I_R_&_D)';
            temp_MyVar_title = 'I_I_P_P^p^r^i^v / I_t_o_t^p^r^i^v';
        end         
        if strcmp(temp_invvar,'Ipfix_IPPrnd') 
            temp_MyVar_ylabel = 'I_H / I_R_&_D';
            temp_MyVar_title = 'I_n_o_t_r_n_d^p^r^i^v / I_R_&_D^p^r^i^v';
        end                 

        
        % assign label
        if varnum==1
            MyVar_ylabel_1 = texlabel(temp_MyVar_ylabel);
            MyVar_title_1  = texlabel(temp_MyVar_title);
        end
        if varnum==2
            MyVar_ylabel_2 = texlabel(temp_MyVar_ylabel);
            MyVar_title_2  = texlabel(temp_MyVar_title);
        end
        if varnum==3
            MyVar_ylabel_3 = texlabel(temp_MyVar_ylabel);
            MyVar_title_3  = texlabel(temp_MyVar_title);
        end
        if varnum==4
            MyVar_ylabel_4 = texlabel(temp_MyVar_ylabel);
            MyVar_title_4  = texlabel(temp_MyVar_title);
        end        
        if varnum==5
            MyVar_ylabel_5 = texlabel(temp_MyVar_ylabel);
            MyVar_title_5  = texlabel(temp_MyVar_title);
        end             

                
        clearvars temp_MyVar_ylabel temp_MyVar_title;
        
    end

    
%     % compile quarterly data for each variable    
%     start_year_qtr = min(data_inv_reg_qtr.year);
%     if sample_start_year==1961
%         pos_start      = find((data_macro_qtr.year>=start_year_qtr),1,'first'); % start 1 qtr later so macro data is 1961Q1:2016Q4
%     else        
%         pos_start      = find((data_macro_qtr.year>=start_year_qtr),1,'first') - 1;        
%     end
%     disp(char(strcat({'macro var data from '},num2str(data_macro_qtr.year(pos_start)),'q',num2str(data_macro_qtr.qtr(pos_start)))))
%     disp(char(strcat({'inv reg data from '},num2str(data_inv_reg_qtr.year(1)),'q',num2str(data_inv_reg_qtr.qtr(1)))))
%     disp(char(strcat({'note: we want macro data to start 1 qtr before inv reg data b/c we take diffs of macro data to prepare them for VAR'})))  
%     
%     % choose ending position such that de-meaned macro data series will be
%     % the same length as the investment regression data series
%     length_qtr_VAR = length(data_inv_reg_qtr.x);
%     pos_end = pos_start+length_qtr_VAR;   
%         
%     %temp_year_qtr_chk = [data_macro_qtr.year(pos_start:pos_end), data_macro_qtr.qtr(pos_start:pos_end)]
%     % add one to pos_start b/c not detrending
%     temp_dtfp_qtr = data_macro_qtr.dtfp(pos_start+1:pos_end);
%     temp_ivol_qtr = data_macro_qtr.ivol(pos_start+1:pos_end);

    % compile quarterly data for each variable    
    if sample_start_year==1961
        pos_start      = find((data_macro_qtr.year>=sample_start_year),1,'first'); % start 1 qtr later so macro data is 1961Q1:2016Q4
    else        
        pos_start      = find((data_macro_qtr.year>=sample_start_year),1,'first') - 1;        
    end
    pos_end   = find((data_macro_qtr.year<=sample_end_year),1,'last');
    disp(char(strcat({'macro var data from '},num2str(data_macro_qtr.year(pos_start)),'q',num2str(data_macro_qtr.qtr(pos_start)))))
    disp(char(strcat({'note: we want macro data to start 1 qtr before inv reg data b/c we take diffs of macro data to prepare them for VAR'})))  
        
    %temp_year_qtr_chk = [data_macro_qtr.year(pos_start:pos_end), data_macro_qtr.qtr(pos_start:pos_end)]
    % add one to pos_start b/c not detrending
    temp_tfp_qtr  =  data_macro_qtr.tfp(pos_start+1:pos_end);
    temp_dtfp_qtr = data_macro_qtr.dtfp(pos_start+1:pos_end);
    temp_ivol_qtr = data_macro_qtr.ivol(pos_start+1:pos_end);        
        
        
    for varnum=1:5          
        
        eval(strcat('tempvarname = myinvvar_',num2str(varnum),';'));
        
        eval(strcat('var3_raw_qtr = data_macro_qtr.',tempvarname,';'));
        
        % truncated series to match other series
        var3_trunc = var3_raw_qtr(pos_start:pos_end);

        % de-trend 3rd variable using HP filter or something else                    
        if strcmp(myfilter,'levels') % simply compute in log levels
            temp_var3_qtr = log(var3_trunc(2:end)); 
        else % de-trend 3rd variable                
        
            temp_var3_qtr = nan(size(var3_trunc));
        
            % HP filter. use pos_start+1 because no need to take first differences
            if strcmp(myfilter,'hpfilter')            
                raw_var3_qtr     = log(var3_trunc(2:end));
                smooth_var3_qtr  = hpfilter(raw_var3_qtr, 1600); % quarterly data smoothing 
                temp_var3_qtr    = raw_var3_qtr - smooth_var3_qtr;
            end

            % linear de-trend
            if strcmp(myfilter,'lindetrend')          
                temp_var3_qtr = prep_raw_data_for_VAR( var3_trunc) ;
            end
            
            % Comin Gertler (2006) band-pass
            % The function is bandpass(X,pl,pu). X is the raw data, pl and pu is the range of frequencies we want to extract. 
            % Recommended by Comin and Gertler (attached below), we should choose pl = 2 and pu = 200 for the quarterly data 
            % to extract the medium-term cycles. 
            if strcmp(myfilter,'bandpass')  
                
                size(var3_trunc);
                raw_var3_qtr = log(var3_trunc(2:end)); % no reduction in size from bandpass --> need to cut first obs for VAR
                temp_var3_qtr = bandpass(raw_var3_qtr, 2, 200);
                %temp_var3_qtr = bandpass(raw_var3_qtr, 32, 200);
                size(temp_var3_qtr); % no reduction in size from bandpass                                

            end
        end
            
        % final dataset for VAR             
        if strcmp(myfilter,'levels') % simply compute in log levels
            %y_qtr_reg = [temp_tfp_qtr, temp_ivol_qtr];    
            % keep dtfp b/c assume 3rd var is also stationary
            y_qtr_reg = [temp_dtfp_qtr, temp_ivol_qtr];    
            if strcmp(temp_invvar,'IPPrnd_real')
                error('should be tfp instead of dtfp?')
            end
        else
            y_qtr_reg = [temp_dtfp_qtr, temp_ivol_qtr];    
        end
        %if strcmp(tempvarname,'Ig_Itot') || strcmp(tempvarname,'Ip_Itot') % series to enter VAR in levels
        % series to enter VAR in levels
        if strcmp(tempvarname,'Ig_Itot') ...
                || strcmp(tempvarname,'Ip_Itot') ...
                || strcmp(tempvarname,'IPPrnd_Itot') ...
                || strcmp(tempvarname,'IPPrnd_Itot_Incl_Govt') ...
                || strcmp(tempvarname,'IPPrnd_Itot_Incl_NonDefGovt') ...
                || strcmp(tempvarname,'IPPrnd_Ip') ...
                || strcmp(tempvarname,'Ipfix_IPPrnd') ...
                || strcmp(tempvarname,'ipptot_ip') ...
                || strcmp(tempvarname,'Ig_Y') ...
                || strcmp(tempvarname,'labor_share_priv') ...
                || strcmp(tempvarname,'labor_share_govt') 
            temp_y_qtr = [y_qtr_reg, exp(temp_var3_qtr)];    
        else
            temp_y_qtr = [y_qtr_reg, temp_var3_qtr];    
        end

        % final exogenous variable dataset for quarterly VAR
        temp_x_qtr = ones(size(temp_y_qtr,1),1);
        if ~strcmp(myccvar, 'none')
            eval(strcat('ccvar_raw_qtr = data_macro_qtr.',myccvar,';'));
            temp_ccvar_qtr = ccvar_raw_qtr(pos_start+1:pos_end);
            temp_x_qtr = [temp_x_qtr, temp_ccvar_qtr];        
        end      
        
        eval(strcat('y_qtr_',num2str(varnum),' = temp_y_qtr;'));
        eval(strcat('x_exo_qtr_',num2str(varnum),' = temp_x_qtr;'));
        
        clear var3_raw_qtr var3_trunc temp_var3_qtr temp_y_qtr temp_x_qtr
        
        % define different shock matrices

            std_IRF_length_qtr = 24;

            % 1-std dtfp shock
            %std_dtfp_shk_mat_qtr      = zeros(3 , std_IRF_length_qtr);
            std_dtfp_shk_mat_qtr      = zeros(3 , std_IRF_length_qtr+176); % compute longer vector and then truncate in plots as needed
            std_dtfp_shk_mat_qtr(1,1) = 1;            

            % 1-std ivol shock
            %std_ivol_shk_mat_qtr      = zeros(3 , std_IRF_length_qtr);
            std_ivol_shk_mat_qtr      = zeros(3 , std_IRF_length_qtr+176); % compute longer vector and then truncate in plots as needed
            std_ivol_shk_mat_qtr(2,1) = 1;             
    
        % compute IRFs 

            % dtfp shk
            %eval(strcat('IRFout_dtfpshk_qtr_',num2str(varnum),' = gen_IRF_vectors_dataVAR_nvars( y_qtr_',num2str(varnum),', x_exo_qtr_',num2str(varnum),', [], std_dtfp_shk_mat_qtr, 0);'))

            % ivol shk
            eval(strcat('IRFout_ivolshk_qtr_',num2str(varnum),' = gen_IRF_vectors_dataVAR_nvars( y_qtr_',num2str(varnum),', x_exo_qtr_',num2str(varnum),', [], std_ivol_shk_mat_qtr, 0);'));

    end
    
    % save out IRF vectors by filter type
    if strcmp(myfilter,'hpfilter')
        IRFout_hpfilter_ivolshk_1 = IRFout_ivolshk_qtr_1;
        IRFout_hpfilter_ivolshk_2 = IRFout_ivolshk_qtr_2;
        IRFout_hpfilter_ivolshk_3 = IRFout_ivolshk_qtr_3;
        IRFout_hpfilter_ivolshk_4 = IRFout_ivolshk_qtr_4;        
        IRFout_hpfilter_ivolshk_5 = IRFout_ivolshk_qtr_5;  
    elseif strcmp(myfilter,'bandpass')
        IRFout_bandpass_ivolshk_1 = IRFout_ivolshk_qtr_1;
        IRFout_bandpass_ivolshk_2 = IRFout_ivolshk_qtr_2;
        IRFout_bandpass_ivolshk_3 = IRFout_ivolshk_qtr_3;
        IRFout_bandpass_ivolshk_4 = IRFout_ivolshk_qtr_4;                
        IRFout_bandpass_ivolshk_5 = IRFout_ivolshk_qtr_5;   
    elseif strcmp(myfilter,'levels')
        IRFout_levels_ivolshk_1 = IRFout_ivolshk_qtr_1;
        IRFout_levels_ivolshk_2 = IRFout_ivolshk_qtr_2;
        IRFout_levels_ivolshk_3 = IRFout_ivolshk_qtr_3;
        IRFout_levels_ivolshk_4 = IRFout_ivolshk_qtr_4;                
        IRFout_levels_ivolshk_5 = IRFout_ivolshk_qtr_5;        
    else
        error('myfilter not recognized');
    end
    
  end
   

  % plot 2x3 IRF where first row is levels and second row is bandpass    
  for plot_model_lines = 0:0
    close ALL
    if plot_model_lines
        %fname = strcat('IRFs_OnlyVol_data_vs_model_hpfilter_vs_bandpass_2x4_dtfp_x_expvol_',myinvvar_1,'_or_',myinvvar_2,'_or_',myinvvar_3,'_or_',myinvvar_4,'_control_',myccvar);    
        error('do not run with model lines for VAR(3)');
    else
        %fname = strcat('IRFs_OnlyVol_hpfilter_vs_bandpass_2x4_dtfp_ivol_',myinvvar_1,'_or_',myinvvar_2,'_or_',myinvvar_3,'_or_',myinvvar_4,'_control_',myccvar);    
        %fname = strcat('IRFs_OnlyVol_hpfilter_vs_bandpass_2x4_dtfp_ivol_',myinvvar_1,'_or_',myinvvar_2,'_or_',myinvvar_3,'_or_',myinvvar_4,'_control_',myccvar,'_',num2str(sample_start_year));            
        %fname = strcat('IRFs_OnlyVol_hpfilter_vs_bandpass_2x3_dtfp_ivol_',myinvvar_1,'_or_',myinvvar_2,'_or_',myinvvar_3,'_control_',myccvar,'_',num2str(sample_start_year));            
        fname = strcat('IRFs_OnlyVol_levels_vs_bandpass_2x3_dtfp_ivol_',myinvvar_1,'_or_',myinvvar_2,'_or_',myinvvar_3,'_control_',myccvar,'_',num2str(sample_start_year));            
    end
    figure(1);
    
        % set size of figure so it fills page
        set(gcf, 'PaperPositionMode', 'manual');
        set(gcf, 'PaperUnits', 'inches');
        set(gcf, 'PaperPosition', [0 0 14.00 7.00]);            
  
        %IRF_length_plot = std_IRF_length_qtr+1;
        % per May 18 2019 call with max, change length of IRF to 20 
        % periods when comparing data vs model
        if plot_model_lines
            IRF_length_plot = std_IRF_length_qtr+1-4;
        else
            IRF_length_plot = std_IRF_length_qtr+1;
        end        
        
        % quarterly data for var 1

            subplot(2,3,1); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_levels_ivolshk_1.oirf_var3(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_levels_ivolshk_1.oirf_var3_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_levels_ivolshk_1.oirf_var3_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);
            if plot_model_lines
                plot(0:IRF_length_plot-1, 100*model_IRF_vol_line_1(1:IRF_length_plot), '-r', 'Linewidth', 2);
            end           
            title(strcat('\fontsize{12}',MyVar_title_1),'FontWeight','normal');
            xlabel(' ');
            ylabel('Percent');
            axis('tight');
            if plot_model_lines
                ylim(My_Ylims_c1);
            else
                ylim(My_Ylims_c1);
            end
            

            subplot(2,3,4); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_bandpass_ivolshk_1.oirf_var3(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_bandpass_ivolshk_1.oirf_var3_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_bandpass_ivolshk_1.oirf_var3_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);
            if plot_model_lines
                plot(0:IRF_length_plot-1, 100*model_IRF_vol_line_1(1:IRF_length_plot), '-r', 'Linewidth', 2);
            end                
            %title(strcat('\fontsize{12}','Volatility Shock'));
            %xlabel('Quarters');
            %ylabel(MyVar_ylabel_1);
            title(strcat('\fontsize{12}',' '));
            xlabel('Quarters');
            ylabel('Percent');            
            axis('tight');
            ylim(My_Ylims_c1);        
        
            
        % quarterly data for var 2

            subplot(2,3,2); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_levels_ivolshk_2.oirf_var3(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_levels_ivolshk_2.oirf_var3_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_levels_ivolshk_2.oirf_var3_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);
            if plot_model_lines
                plot(0:IRF_length_plot-1, 100*model_IRF_vol_line_2(1:IRF_length_plot), '-r', 'Linewidth', 2);
            end                  
            title(strcat('\fontsize{12}',MyVar_title_2),'FontWeight','normal');
            xlabel(' ');
            ylabel(' ');            
            axis('tight');
            if plot_model_lines
                ylim(My_Ylims_c2);
            else
                ylim(My_Ylims_c2);
            end

            subplot(2,3,5); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_bandpass_ivolshk_2.oirf_var3(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_bandpass_ivolshk_2.oirf_var3_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_bandpass_ivolshk_2.oirf_var3_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);
            if plot_model_lines
                plot(0:IRF_length_plot-1, 100*model_IRF_vol_line_2(1:IRF_length_plot), '-r', 'Linewidth', 2);
            end                                
            %title(strcat('\fontsize{12}','Volatility Shock'));
            %xlabel('Quarters');
            %ylabel(MyVar_ylabel_2);
            title(strcat('\fontsize{12}',' '));
            xlabel('Quarters');
            ylabel(' ');                
            axis('tight');
            ylim(My_Ylims_c2);
   
            
        % quarterly data for var 3

            subplot(2,3,3); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_levels_ivolshk_3.oirf_var3(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_levels_ivolshk_3.oirf_var3_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_levels_ivolshk_3.oirf_var3_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);
            if plot_model_lines
                plot(0:IRF_length_plot-1, 100*model_IRF_vol_line_3(1:IRF_length_plot), '-r', 'Linewidth', 2);
            end                                
            %title(strcat('\fontsize{12}','Productivity Shock'));
            %xlabel('Quarters');
            %ylabel(MyVar_ylabel_3);
            title(strcat('\fontsize{12}',MyVar_title_3),'FontWeight','normal');
            xlabel(' ');
            ylabel(' ');               
            axis('tight');
            if plot_model_lines
                ylim(My_Ylims_c3);
            else
                ylim(My_Ylims_c3);
            end            
            

            subplot(2,3,6); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_bandpass_ivolshk_3.oirf_var3(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_bandpass_ivolshk_3.oirf_var3_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_bandpass_ivolshk_3.oirf_var3_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);
            if plot_model_lines
                plot(0:IRF_length_plot-1, 100*model_IRF_vol_line_3(1:IRF_length_plot), '-r', 'Linewidth', 2);
            end                                                
            %title(strcat('\fontsize{12}','Volatility Shock'));
            %xlabel('Quarters');
            %ylabel(MyVar_ylabel_3);
            title(strcat('\fontsize{12}',' '));
            xlabel('Quarters');
            ylabel(' ');                            
            axis('tight');
            ylim(My_Ylims_c3);      
       
            
            % add shock labels
            
                myfig = gcf;
            
                annotation(myfig,'textbox',...
                    [0.0265625 0.71496062992126 0.0515625 0.0840311679790023],...
                    'String',{'Levels','tfp and var3'},... ...'String',{'Business','Cycle'},...
                    'LineStyle','none',...
                    'HorizontalAlignment','center',...
                    'FontWeight','bold',...
                    'FontSize',12,...
                    'FitBoxToText','off');    
            
                annotation(myfig,'textbox',...
                    [0.025 0.244094488188976 0.0515625 0.0840311679790026],...
                    'String',{'Medium','Cycle'},...
                    'LineStyle','none',...
                    'HorizontalAlignment','center',...
                    'FontWeight','bold',...
                    'FontSize',12,...
                    'FitBoxToText','off');            
            
        % save jpg        
        saveas(1,strcat('figures/',fname),'png')
        saveas(1,strcat('figures/',fname)) 
        saveas(1,strcat('output_for_paper/Figures/',fname),'png')
        saveas(1,strcat('output_for_paper/Figures/',fname))  
        %close(1)                          
  end  
   
    
end 




    

%% data vs model responses of ANNUAL compustat-based investment ratios to vol shocks
% note that Compustat data we use for empirical analysis is annual so that
% is why we use annual here as well
% note: levels VAR is set up to run with first var as dtfp, not tfp

clc;

% cc control var
%ccvarlist = {'none'};
ccvarlist = {'baa10ym'};
%ccvarlist = {'none'; 'baa10ym';'aaa10ym'};
ccc = 1;
myccvar = char(ccvarlist{ccc});

% VAR specs for columns 1, 2, and 3
%VARspecs = {'hpfilter'}; % 
%VARspecs = {'bandpass'}; % 
VARspecs = {'levels'}; % 
%VARorder = 1;
%VARorder = 2;
%VARorder_list = [1,2];
VARorder_list = [1];

% set of two variables to use as var4 (first one in top row of IRF figure,
% second in bottom row)
%var4_choice_set = {'total_iss_usa','agg_pat_val_sm'};
%var4_choice_set = {'xrd_to_tot_all','xrd_to_tot_allport'};
%var4_choice_set = {'highrnd_totinv_to_allport_totinv','highrnd_totinv_to_all_totinv'};
var4_choice_set = {'capx_high_to_low','toti_high_to_low'};
%var4_choice_set = {'capx_high_to_low','capx_high_to_low_keepln'};

% total_iss_usa has data from 1963--2016
% agg_pat_val_sm has data from 1929--2010
% eearliest start year is 1961 because first year of inv reg data

    % longest possible periods for compustat measures (same all of them)
    startyr1 = 1972
    endyr1   = 2016
    startyr2 = 1972
    endyr2   = 2016

    startyr1 = 1984
    startyr2 = 1984
    
% loop across last var choices
for ooo = 1:length(VARorder_list)
 VARorder = VARorder_list(ooo);  
  panelnum=0; % start index at zero
  for aaa = 1:length(var4_choice_set)
    
    % get var4 name
    var4_choice = char(var4_choice_set{aaa});
    disp(strcat('var4_choice',num2str(aaa),'=',var4_choice));
    
    % get var4 year range
    eval(strcat('sample_start_year = startyr',num2str(aaa),';'));
    eval(strcat('sample_end_year   = endyr',num2str(aaa),';'));    
    
    % make sure we have the right annual data from investment regs
    if sample_start_year>=1969 & sample_start_year<=1971
        load data_inv_reg_ann_1969_2016   
    elseif sample_start_year>=1972              
        load data_inv_reg_ann_1972_2016                           
    elseif sample_start_year<=1968                     
        load data_inv_reg_ann_1961_2016                   
    else
        error('sample_start_year not accounted for above');
    end    
    
    % compute IRFs for data VARs for 4-variable VAR
    for vvv = 1:length(VARspecs)
    %vvv=1

        panelnum=panelnum+1; % count through panels
        myVARspec = char(VARspecs{vvv});

        % figure out starting and ending positions
        %sample_start_year = 1961;
        %sample_end_year   = 2016;     
        %if strcmp(myVARspec,'levels')
        %    pos_start_macro  = find((data_macro_ann.year>=sample_start_year),1,'first');        
        %else % need extra period for filtering        
            pos_start_macro = find((data_macro_ann.year>=sample_start_year),1,'first') - 1; 
        %end    
        pos_end_macro   = find((data_macro_ann.year<=sample_end_year),1,'last');
        pos_start_invreg = find((data_inv_reg_ann.year>=sample_start_year),1,'first');        
        pos_end_invreg   = find((data_inv_reg_ann.year<=sample_end_year),1,'last');  
        disp(char(strcat({'macro var data from '},num2str(data_macro_ann.year(pos_start_macro)))));
        disp(char(strcat({'macro var data to '},  num2str(data_macro_ann.year(pos_end_macro)))));
        disp(char(strcat({'inv reg data from '},num2str(data_inv_reg_ann.year(pos_start_invreg)))));
        disp(char(strcat({'inv reg data to '},num2str(data_inv_reg_ann.year(pos_end_invreg)))));

        % first three variables from investment regression
        %if strcmp(myVARspec,'levels')
            %var1 = data_macro_ann.tfp( pos_start_macro:pos_end_macro); % tfp in levels
        %else
            var1 = data_macro_ann.dtfp( pos_start_macro+1:pos_end_macro); % dtfp from macro data
            %var1_chk = data_inv_reg_ann.dtfp( pos_start_invreg:pos_end_invreg); % dtfp from inv reg data
            %chk_diff = abs(var1 - var1_chk);
            %max(chk_diff)
            %[var1, var1_chk]
        %end
        var2 = data_inv_reg_ann.x( pos_start_invreg:pos_end_invreg);
        var3 = data_inv_reg_ann.expvol( pos_start_invreg:pos_end_invreg);

        % 4th variable that may be filtered depending myVARspec
        eval(strcat('var4_raw = data_macro_ann.',var4_choice,';'));
        var4_trunc = var4_raw(pos_start_macro:pos_end_macro); % truncated series to match other series
        if strcmp(myVARspec,'levels') % simply compute in log levels
            temp_var4_ann = log(var4_trunc(2:end)); 
        else % de-trend 4th variable 

            temp_var4_ann = nan(size(var4_trunc));

            % HP filter. use pos_start+1 because no need to take first differences
            if strcmp(myVARspec,'hpfilter')            
                raw_var4_ann     = log(var4_trunc(2:end));
                %smooth_var4_ann  = hpfilter(raw_var4_ann, 1600); % quarterly data smoothing 
                smooth_var4_ann  = hpfilter(raw_var4_ann, 6.25); % annual data smoothing 
                temp_var4_ann    = raw_var4_ann - smooth_var4_ann;
            end   

            % Comin Gertler (2006) band-pass
            % The function is bandpass(X,pl,pu). X is the raw data, pl and pu is the range of frequencies we want to extract. 
            % Recommended by Comin and Gertler (attached below), we should choose pl = 2 and pu = 200 for the quarterly data 
            % to extract the medium-term cycles. 
            if strcmp(myVARspec,'bandpass')  
                size(var4_trunc);
                raw_var4_ann = log(var4_trunc(2:end)); % no reduction in size from bandpass --> need to cut first obs for VAR
                %temp_var4_ann = bandpass(raw_var4_ann, 2, 200);
                temp_var4_ann = bandpass(raw_var4_ann, 1, 50); % for annual data 
                size(temp_var4_ann); % no reduction in size from bandpass                                
            end  

        end

        % series to enter VAR in levels 
        if strcmp(var4_choice,'Ig_Itot') ...
        || strcmp(var4_choice,'Ip_Itot') ...
        || strcmp(var4_choice,'Ig_Y') ...
        || strcmp(var4_choice,'xrd_to_tot_all') ...
        || strcmp(var4_choice,'xrd_to_tot_allport') ...
        || strcmp(var4_choice,'highrnd_totinv_to_allport_totinv') ...
        || strcmp(var4_choice,'highrnd_totinv_to_all_totinv') ...           
        || strcmp(var4_choice,'capx_high_to_low') ...           
        || strcmp(var4_choice,'toti_high_to_low') ...               
        || strcmp(var4_choice,'labor_share_govt') ...
        || strcmp(var4_choice,'labor_share_priv') 
            var4 = exp(temp_var4_ann);
        else
            var4 = temp_var4_ann; % keep in logs
        end    

        % endogenous vars matrix
        temp_y_ann = [var1, var2, var3, var4];
        
        % exogenous vars matrix
        temp_x_ann = ones(size(temp_y_ann,1),1);
        if ~strcmp(myccvar, 'none')
            eval(strcat('ccvar_raw_ann = data_macro_ann.',myccvar,';'));
            %if strcmp(myVARspec,'levels') 
                %temp_ccvar_ann = ccvar_raw_ann(pos_start_macro:pos_end_macro);
            %else
                temp_ccvar_ann = ccvar_raw_ann(pos_start_macro+1:pos_end_macro);
            %end
            temp_x_ann = [temp_x_ann, temp_ccvar_ann];        
        end      

        % define different shock matrices

            std_IRF_length_ann = 6;

            % 1-std dtfp shock
            std_dtfp_shk_mat_ann      = zeros(4 , std_IRF_length_ann);
            std_dtfp_shk_mat_ann(1,1) = 1;            

            % 1-std ivol shock
            std_ivol_shk_mat_ann      = zeros(4 , std_IRF_length_ann);
            std_ivol_shk_mat_ann(3,1) = 1;             

            % compute IRFs for ivol shk
            if VARorder==1 
                temp_IRFOUT = gen_IRF_vectors_dataVAR_nvars( temp_y_ann, temp_x_ann, [], std_ivol_shk_mat_ann, 0);
            elseif VARorder==2
                temp_IRFOUT = gen_IRF_vectors_dataVAR2_nvars( temp_y_ann, temp_x_ann, [], std_ivol_shk_mat_ann, 0);
            else
                error('VARorder not specified');
            end
            %eval(strcat('IRFout_ivolshk_4var_ann_',num2str(vvv),' = temp_IRFOUT;'));
            eval(strcat('IRFout_ivolshk_4var_ann_',num2str(panelnum),' = temp_IRFOUT;'));
            
        % clean up
        clear var4_raw_ann var4_trunc temp_var4_ann temp_y_ann temp_x_ann

    end % vvv myVARspec list
    
    % y labels
    temp_MyVar_ylabel = texlabel('Percent');
    %if strcmp(var4_choice,'Yp_real')
    %    temp_MyVar_ylabel = texlabel('log(Y_p)');
    %end     
    eval(strcat('MyVar_ylabel_',num2str(aaa),'=temp_MyVar_ylabel;'));    
    
    % y axis lims
%     if aaa==1        
%         temp_low1 = IRFout_ivolshk_4var_ann_1.oirf_var4_ciL(1:IRF_length_plot);
%         temp_low2 = IRFout_ivolshk_4var_ann_2.oirf_var4_ciL(1:IRF_length_plot);
%         temp_low3 = IRFout_ivolshk_4var_ann_3.oirf_var4_ciL(1:IRF_length_plot);
%         temp_high1 = IRFout_ivolshk_4var_ann_1.oirf_var4_ciU(1:IRF_length_plot);
%         temp_high2 = IRFout_ivolshk_4var_ann_2.oirf_var4_ciU(1:IRF_length_plot);
%         temp_high3 = IRFout_ivolshk_4var_ann_3.oirf_var4_ciU(1:IRF_length_plot);        
%         temp_min_low  = min([ temp_low1,  temp_low2,  temp_low3]);
%         temp_min_high = max([temp_high1, temp_high2, temp_high3]);
%         My_Ylims_row1 = [floor(100*temp_min_low),ceil(100*temp_min_high)];
%     elseif aaa==2
%         temp_low1 = IRFout_ivolshk_4var_ann_4.oirf_var4_ciL(1:IRF_length_plot);
%         temp_low2 = IRFout_ivolshk_4var_ann_5.oirf_var4_ciL(1:IRF_length_plot);
%         temp_low3 = IRFout_ivolshk_4var_ann_6.oirf_var4_ciL(1:IRF_length_plot);
%         temp_high1 = IRFout_ivolshk_4var_ann_4.oirf_var4_ciU(1:IRF_length_plot);
%         temp_high2 = IRFout_ivolshk_4var_ann_5.oirf_var4_ciU(1:IRF_length_plot);
%         temp_high3 = IRFout_ivolshk_4var_ann_6.oirf_var4_ciU(1:IRF_length_plot);        
%         temp_min_low  = min([ temp_low1,  temp_low2,  temp_low3]);
%         temp_min_high = max([temp_high1, temp_high2, temp_high3]);
%         My_Ylims_row2 = [floor(100*temp_min_low),ceil(100*temp_min_high)];        
%     else
%         error('aaa not recognized');
%     end
    
      

  end % aaa var4_choice_set

  
    % create the 1x2 figure
    close ALL
    figure(1);

        fname = strcat('IRFs_OnlyVol_VAR',num2str(VARorder),'_4var_ann_',var4_choice_set{1},'_from_',num2str(startyr1),'_to_',num2str(endyr1),'_',var4_choice_set{2},'_from_',num2str(startyr2),'_to_',num2str(endyr2),'_control_',myccvar,'_1x2_',char(VARspecs{1}));    

        % panel titles
        for aaa = 1:length(var4_choice_set)
            myvar = char(var4_choice_set{aaa});    
            if strcmp(myvar,'total_iss_usa')
                %temp_mytitle = 'Number of Patents Granted';
                temp_mytitle = 'Number of Patents';
            elseif strcmp(myvar,'total_app_usa') 
                %temp_mytitle = 'Number of Patent Applications';
                temp_mytitle = 'Number of Patents';
            elseif strcmp(myvar,'agg_pat_val_sm')
                %temp_mytitle = 'Value of Patents Granted';
                temp_mytitle = 'Value of Patents';
            elseif strcmp(myvar,'xrd_to_tot_all')
                temp_mytitle = {'Compustat:',' XRDall / (XRDall + CAPXall)'};                
            elseif strcmp(myvar,'xrd_to_tot_allport')
                temp_mytitle = {'Compustat:',' XRDall / (XRDnomiss + CAPXnomiss)'};                                
            elseif strcmp(myvar,'highrnd_totinv_to_allport_totinv')
                temp_mytitle = {'Compustat:',' (XRDhigh + CAPXhigh) / (XRDnomiss + CAPXnomiss)'};                                                
            elseif strcmp(myvar,'highrnd_totinv_to_all_totinv')
                temp_mytitle = {'Compustat:','(XRDhigh + CAPXhigh) / (XRDall + CAPXall)'};
            elseif strcmp(myvar,'capx_high_to_low_keepln')
                temp_mytitle = {'Compustat:',' ln(CAPXhigh / CAPXlow)'};                                 
            elseif strcmp(myvar,'capx_high_to_low')
                temp_mytitle = {'Compustat:',' CAPXhigh / CAPXlow)'};                                                
            elseif strcmp(myvar,'toti_high_to_low')
                temp_mytitle = {'Compustat:','(XRDhigh + CAPXhigh) / (XRDlow + CAPXlow)'};                
            else
                error('myvar not recognized');
            end
            eval(strcat('mytitle_',num2str(aaa),'=temp_mytitle;'));
        end      

        % set size of figure so it fills page
        set(gcf, 'PaperPositionMode', 'manual');
        set(gcf, 'PaperUnits', 'inches');
        %set(gcf, 'PaperPosition', [0 0 14.00 7.00]);            
        set(gcf, 'PaperPosition', [0 0 7.00 3.50]); % 1x2 plot

        %IRF_length_plot = std_IRF_length_qtr+1;
        % per May 18 2019 call with max, change length of IRF to 20 
        % periods when comparing data vs model
        IRF_length_plot = std_IRF_length_ann+1;    

        % VARspec 1

            subplot(1,2,1); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_4var_ann_1.oirf_var4(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_4var_ann_1.oirf_var4_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_4var_ann_1.oirf_var4_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);
            title(strcat('\fontsize{8}',mytitle_1),'FontWeight','normal');
            xlabel('Years');
            %ylabel(MyVar_ylabel_1);               
            ylabel('Percentage Points');               
            %axis('tight');
            %ylim(My_Ylims_row1);

            subplot(1,2,2); hold on; box on;
            plot(0:IRF_length_plot-1, zeros(1,IRF_length_plot),'-k', 'Linewidth', 0.5);
            plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_4var_ann_2.oirf_var4(1:IRF_length_plot), '-b', 'Linewidth', 2);
                plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_4var_ann_2.oirf_var4_ciL(1:IRF_length_plot), '--b', 'Linewidth', 1);
                plot(0:IRF_length_plot-1, 100*IRFout_ivolshk_4var_ann_2.oirf_var4_ciU(1:IRF_length_plot), '--b', 'Linewidth', 1);
            title(strcat('\fontsize{8}',mytitle_2),'FontWeight','normal');
            xlabel('Years');
            %ylabel(temp_MyVar_ylabel);
            %ylabel(MyVar_ylabel_2);    
            %axis('tight');
            %ylim(My_Ylims_row1);

        % add row labels
% 
%             myfig = gcf;
% 
%             annotation(myfig,'textbox',...
%                 [0.0265625 0.71496062992126 0.0515625 0.0840311679790023],...
%                 'String',MyVar_rowlabel_1,...
%                 'LineStyle','none',...
%                 'HorizontalAlignment','center',...
%                 'FontWeight','bold',...
%                 'FontSize',12,...
%                 'FitBoxToText','off');    
% 
%             annotation(myfig,'textbox',...
%                 [0.0265625 0.21496062992126 0.0515625 0.0840311679790023],...
%                 'String',MyVar_rowlabel_2,...
%                 'LineStyle','none',...
%                 'HorizontalAlignment','center',...
%                 'FontWeight','bold',...
%                 'FontSize',12,...
%                 'FitBoxToText','off');          
     
            
        % save jpg        
        saveas(1,strcat('figures/',fname),'png')
        saveas(1,strcat('figures/',fname)) 
        %saveas(1,strcat('output_for_paper/Figures/',fname),'png')
        %saveas(1,strcat('output_for_paper/Figures/',fname))                     
        %close(1)                           

      
        
end % ooo = 1:length(VARorder_list)


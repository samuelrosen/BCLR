global saved_dir stoch_vol_switch gold_switch shock_direction_switch % SAM ADD

fid=fopen(strcat(saved_dir,'/Report.tex'),'w+');

fprintf(fid,strcat(...
    '\\documentclass[english]{article} \n',...
    '\\usepackage[T1]{fontenc} \n',...
    '\\usepackage[latin9]{inputenc} \n',...
    '\\usepackage{graphicx} \n',...
    '\\usepackage{amssymb} \n',...
    '\\usepackage{babel} \n',...
    '\\setlength\\parindent{0.0in} \\setlength\\parskip{0.1in} \n',... %SAM ADD
    '\\setlength{\\textwidth}{16.5cm} \\setlength{\\topmargin}{-3cm} \n',... %SAM ADD
    '\\setlength{\\evensidemargin}{-2cm} \\setlength{\\oddsidemargin}{-0cm} \n',... %SAM ADD
    '\\setlength{\\textheight}{23.5cm} \n',... %SAM ADD
    '\\setlength{\\footskip}{65pt}     \n',... %SAM ADD
    '\\begin{document} \n',...
    ' \n',...
    ' \n',...
    '\\begin{table}[ht] \n',...
    '  \\centering \n',...
    '  \\caption{Parameter Values} \n',...
    '  \\input{table_parameters} \n',...
    '\\end{table} \n',...
    ' \n',...
    '\\begin{table}[ht] \n',...
    '    \\centering \n',...
    '    \\caption{Moments} \n',...
    '    \\input{table_moments} \n',...
    '\\end{table} \n',...   
    ' \n'));%' \n',...));

%  if stoch_vol_switch==1
%         fprintf(fid,strcat(...
%          '\\begin{table}[ht] \n',...
%     '  \\centering \n',...
%     '  \\caption{Is Regression Results} \n',...
%     '  \\input{table_regression} \n',...
%     '\\end{table} \n',...
%     ' \n',...
%     '\\begin{table}[ht] \n',...
%     '  \\centering \n',...
%     '  \\caption{Vol Regression Results} \n',...
%     '  \\input{table_regression_vol} \n',...
%     '\\end{table} \n',... 
%         ' \n'));         
%     end

    % SAM ADD:
    if ep_cov_calc_switch==1
        fprintf(fid,strcat(...
        '\\begin{table}[!h] \n',... 
        '  \\centering \n',... 
        '  \\caption{Conditional Moments} \n',... 
        '  \\input{table_cond_moments} \n',... 
        '\\end{table} \n',... 
        ' \n'));         
    end

    % SAM ADD:
    if gold_switch==1
        fprintf(fid,strcat(...
        '\\begin{table}[!h] \n',... 
        '  \\centering \n',... 
        '  \\caption{Gold Parameter Values} \n',... 
        '  \\input{table_parameters_gold} \n',... 
        '\\end{table} \n',... 
        ' \n',...         
        '\\begin{table}[!h] \n',... 
        '  \\centering \n',... 
        '  \\caption{Gold Moments} \n',... 
        '  \\input{table_moments_gold} \n',... 
        '\\end{table} \n',... 
        ' \n'));             
    end
    
    % regular IRF for SRR and LRR
%     fprintf(fid,'\\begin{figure}[ht] \n');
%     fprintf(fid,'\\includegraphics[scale=.75]{IRF_SRR_LRR.pdf} \n');
%     %if shock_direction_switch==1
%         fprintf(fid,['\\caption{Impulse response functions from a ' num2str(shock_direction_switch) ' St.Dev(s) shock.} \n']);
%     %elseif shock_direction_switch==(-1)
%     %    fprintf(fid,'\\caption{Impulse response functions from 1 St.Dev shock.} \n');
%     %else
%     %    error('shock direction switch not properly specified');
%     %end    
%     fprintf(fid,'\\end{figure} \n');
%     
%     % regular IRF for combination of LRR, vol, and gold shocks depending on calibration
%     if gold_switch==1 || stoch_vol_switch==1
%         fprintf(fid,'\\begin{figure}[ht] \n');
%         if gold_switch==0 && stoch_vol_switch==1
%             fprintf(fid,'\\includegraphics[scale=.75]{IRF_SRR_vol.pdf} \n');        
%         elseif gold_switch==1 && stoch_vol_switch==0
%             fprintf(fid,'\\includegraphics[scale=.75]{IRF_LRR_gold.pdf} \n');
%         elseif gold_switch==1 && stoch_vol_switch==1
%             fprintf(fid,'\\includegraphics[scale=.75]{IRF_gold_vol.pdf} \n');
%         end    
%         
%          fprintf(fid,['\\caption{Impulse response functions from a ' num2str(shock_direction_switch) ' St.Dev(s) shock.} \n']);
%     
%         
% %         if shock_direction_switch==1
% %             fprintf(fid,'\\caption{Impulse response functions from 1 S.D. positive shocks.} \n');
% %         elseif shock_direction_switch==(-1)
% %             fprintf(fid,'\\caption{Impulse response functions from 1 S.D. negative shocks.} \n');
% %         end    
%          fprintf(fid,'\\end{figure} \n');    
%     end
    
    
    fprintf(fid,'\\end{document}');    
fclose(fid);
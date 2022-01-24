global fname labor_switch
global gold_switch %SAM EDIT

load(strcat(fname,'.mat'));

no_vars=size(dyn_vars,1);

% Levels / Productivity
dyn_i_Y_A = no_vars+1; no_vars=no_vars+1;
dyn_i_C_A = no_vars+1; no_vars=no_vars+1;
dyn_i_I_A = no_vars+1; no_vars=no_vars+1;
dyn_i_K_A = no_vars+1; no_vars=no_vars+1;
dyn_i_KC_A = no_vars+1; no_vars=no_vars+1;
% Levels / GDP
dyn_i_C_Y = no_vars+1; no_vars=no_vars+1;
dyn_i_I_Y = no_vars+1; no_vars=no_vars+1;
dyn_i_K_Y = no_vars+1; no_vars=no_vars+1;

% Aggregate productivity
dyn_i_a = no_vars+1;
dyn_i_logYp = no_vars+1;

% Relative Investments
% dyn_i_J_I  = no_vars+1; no_vars=no_vars+1;
% dyn_i_qKqG = no_vars+1; no_vars=no_vars+1;

% Gold utilization (SAM ADD)
% dyn_i_G_Gbar = no_vars+1; no_vars=no_vars+1;


% Next section adds variables that might not exist

    % Labor
%     if labor_switch==0
%         dyn_i_n = no_vars+1; no_vars=no_vars+1;
%     end

    % Gold (SAM EDIT SECTION)
%     if gold_switch==0
%         gold_vars = {'JA', 'dhc','dJoverA','ga','ga_bar','gda','BA','BG','pG','qG','rG','exr_G','CG', 'dg', 'dg_bar', 'dB'};%, 'dBG'};
%         for x = 1:size(gold_vars,2)
%             y=char(gold_vars(1,x));
%             eval(strcat('dyn_i_',y,' = no_vars+1; no_vars=no_vars+1;'))
%         end
%     end

save(strcat(fname,'.mat'));
% Clear workspace
clear; clc; close all;

% ========== File Paths ==========
save_dir = '/Users/daa/Documents/Scratch/TD_ASD_CrossSectional/MothersVoice_ID_Analysis';
td_summary_file = fullfile(save_dir, 'TD_summary.csv');
asd_summary_file = fullfile(save_dir, 'ASD_summary.csv');

% ========== Load RT/ACC Summary Data ==========
td_summary = readtable(td_summary_file);
asd_summary = readtable(asd_summary_file);

% Standardize PIDs as 4-digit strings with leading zeros
td_summary.PID = pad(string(td_summary.PID), 4, 'left', '0');
asd_summary.PID = pad(string(asd_summary.PID), 4, 'left', '0');

% Add group labels
td_summary.Group = repmat("TD", height(td_summary), 1);
asd_summary.Group = repmat("ASD", height(asd_summary), 1);

% Combine both groups
summary_all = [td_summary; asd_summary];

% ========== Load PID Lists ==========
asd_pid_table = readtable('/Users/daa/Documents/Scratch/TD_ASD_CrossSectional/Data/ASD_selected_PID_List_n39_ADOS.csv');
td_pid_table  = readtable('/Users/daa/Documents/Scratch/TD_ASD_CrossSectional/Data/TD_selected_PID_List.csv');

% Extract and standardize PIDs
asd_pids = pad(string(asd_pid_table{:,1}), 4, 'left', '0');
td_pids  = pad(string(td_pid_table{:,1}), 4, 'left', '0');

% ========== Load Age Data ==========
asd_age_values = readmatrix('/Users/daa/Documents/Scratch/TD_ASD_CrossSectional/Data/ASD_selected_age_scan_n39_ADOS.txt');
td_age_values  = readmatrix('/Users/daa/Documents/Scratch/TD_ASD_CrossSectional/Data/TD_selected_age_scan.txt');

% ========== Construct Age Tables ==========
asd_age_table = table(asd_pids, asd_age_values, repmat("ASD", length(asd_pids), 1), ...
                      'VariableNames', {'PID', 'Age', 'Group'});
td_age_table  = table(td_pids, td_age_values, repmat("TD", length(td_pids), 1), ...
                      'VariableNames', {'PID', 'Age', 'Group'});
age_table = [asd_age_table; td_age_table];

% ========== Merge Summary with Age Data ==========
summary_all.PID = string(summary_all.PID);
merged = innerjoin(summary_all, age_table, 'Keys', {'PID', 'Group'});

% ========== Run Linear Models ==========
mdl_RT = fitlm(merged, 'MedianRT ~ Age * Group');
mdl_ACC = fitlm(merged, 'MeanACC ~ Age * Group');

% --------- Display Linear Model Summaries ---------
disp('=== MedianRT model ===');
disp(mdl_RT);

disp('=== MeanACC model ===');
disp(mdl_ACC);

% ========== Run Group Comparisons ==========
asd_rt  = merged.MedianRT(merged.Group == "ASD");
td_rt   = merged.MedianRT(merged.Group == "TD");
asd_acc = merged.MeanACC(merged.Group == "ASD");
td_acc  = merged.MeanACC(merged.Group == "TD");

[~, p_rt, ~, stats_rt] = ttest2(asd_rt, td_rt);
[~, p_acc, ~, stats_acc] = ttest2(asd_acc, td_acc);

% --------- Display Group Comparison Results ---------
fprintf('\n=== Group Comparison: MedianRT ===\n');
fprintf('ASD Mean: %.3f, TD Mean: %.3f\n', mean(asd_rt), mean(td_rt));
fprintf('t(%d) = %.2f, p = %.4f\n', stats_rt.df, stats_rt.tstat, p_rt);

fprintf('\n=== Group Comparison: MeanACC ===\n');
fprintf('ASD Mean: %.3f, TD Mean: %.3f\n', mean(asd_acc), mean(td_acc));
fprintf('t(%d) = %.2f, p = %.4f\n', stats_acc.df, stats_acc.tstat, p_acc);

% ========== Show Any Missing PIDs ==========
missing_asd_pids = setdiff(asd_pids, merged.PID(merged.Group == "ASD"));
missing_td_pids  = setdiff(td_pids, merged.PID(merged.Group == "TD"));

fprintf('\nMissing ASD PIDs (not in merged summary):\n');
disp(missing_asd_pids);

fprintf('Missing TD PIDs (not in merged summary):\n');
disp(missing_td_pids);

% ========== SAVE RESULTS TO FILES ==========
writetable(merged, fullfile(save_dir, 'Merged_Summary.csv'));
writetable(mdl_RT.Coefficients, fullfile(save_dir, 'Model_RT_Coefficients.csv'));
writetable(mdl_ACC.Coefficients, fullfile(save_dir, 'Model_ACC_Coefficients.csv'));

group_stats = table(...
    ["MedianRT"; "MeanACC"], ...
    [mean(asd_rt); mean(asd_acc)], ...
    [mean(td_rt); mean(td_acc)], ...
    [stats_rt.tstat; stats_acc.tstat], ...
    [stats_rt.df; stats_acc.df], ...
    [p_rt; p_acc], ...
    'VariableNames', {'Measure', 'ASD_Mean', 'TD_Mean', 'T_Stat', 'DF', 'P_Value'});
writetable(group_stats, fullfile(save_dir, 'Group_Comparisons.csv'));

writematrix(missing_asd_pids, fullfile(save_dir, 'Missing_ASD_PIDs.txt'));
writematrix(missing_td_pids,  fullfile(save_dir, 'Missing_TD_PIDs.txt'));

disp('✅ All results saved.');


% ==========================================================
%   ROI Signal Analysis: Does MeanACC explain Group × Age?
% ==========================================================

td_sig_file  = '/Users/daa/Documents/Scratch/TD_ASD_CrossSectional/Figure_Generation/Scatterplots/MotherOther_Scatters/TDonly_n40_SigLevels_Age_MotherOther.mat';
asd_sig_file = '/Users/daa/Documents/Scratch/TD_ASD_CrossSectional/Figure_Generation/Scatterplots/MotherOther_Scatters/ASDonly_n39_SigLevels_Age_MotherOther.mat';

td_sig_data  = load(td_sig_file);  % contains roi_con (40 x 5) and roi_name
asd_sig_data = load(asd_sig_file); % contains roi_con (39 x 5) and roi_name

TD_SigLevels  = td_sig_data.roi_con;  % participants x ROIs
ASD_SigLevels = asd_sig_data.roi_con;
roi_name      = td_sig_data.roi_name;  % cell array of ROI names

% Combine signal levels into one table
roi_table = array2table([ASD_SigLevels; TD_SigLevels], ...
                        'VariableNames', roi_name(:)');
roi_table.PID   = [asd_pids; td_pids];
roi_table.Group = [repmat("ASD", length(asd_pids), 1);
                   repmat("TD", length(td_pids), 1)];

% Merge ROI levels with existing behavioral table
merged_roi = innerjoin(merged, roi_table, 'Keys', {'PID','Group'});

% ========== Linear Models for Each ROI ==========
nROI = size(ASD_SigLevels, 2);

pvals_groupXage = zeros(nROI,1);
pvals_ACC       = zeros(nROI,1);

for r = 1:nROI
    y = merged_roi.(roi_name{r});  % select current ROI signal level
    
    tbl = table(merged_roi.Age, merged_roi.Group, merged_roi.MeanACC, y, ...
        'VariableNames', {'Age','Group','MeanACC','Signal'});
    
    mdl = fitlm(tbl, 'Signal ~ Age*Group + MeanACC');
    
    % Extract p-values
    coef_table = mdl.Coefficients;
    
    % Find Group × Age interaction row (depends on which group is reference)
    int_row = startsWith(coef_table.Row, 'Age:Group');
    pvals_groupXage(r) = coef_table.pValue(int_row);
    
    % MeanACC covariate p-value
    pvals_ACC(r) = coef_table.pValue(strcmp(coef_table.Row,'MeanACC'));
end

% Save results
roi_results = table(roi_name(:), pvals_groupXage, pvals_ACC, ...
    'VariableNames', {'ROI','P_GroupXAge','P_MeanACC'});
writetable(roi_results, fullfile(save_dir,'ROI_GroupXAge_ACC_Results.csv'));

disp('✅ ROI analysis with MeanACC covariate complete.');

% Display the results in the Command Window
disp('=== ROI Group × Age Interaction Analysis (controlling for MeanACC) ===');
disp(roi_results);

% Highlight any significant effects (p < 0.05)
sig_idx = roi_results.P_GroupXAge < 0.05;
if any(sig_idx)
    disp('--- Significant Group × Age interactions ---');
    disp(roi_results(sig_idx,:));
else
    disp('No Group × Age interactions reached p < 0.05');
end

% Optional: also check which ROIs have ACC effects
sig_acc_idx = roi_results.P_MeanACC < 0.05;
if any(sig_acc_idx)
    disp('--- ROIs where MeanACC significantly predicts signal level ---');
    disp(roi_results(sig_acc_idx,:));
end



% ==========================================================
%   ROI Signal Analysis: Does MedianRT explain Group × Age?
% ==========================================================

pvals_groupXage_rt = zeros(nROI,1);
pvals_RT           = zeros(nROI,1);

for r = 1:nROI
    y = merged_roi.(roi_name{r});  % current ROI signal
    
    tbl_rt = table(merged_roi.Age, merged_roi.Group, merged_roi.MedianRT, y, ...
        'VariableNames', {'Age','Group','MedianRT','Signal'});
    
    mdl_rt = fitlm(tbl_rt, 'Signal ~ Age*Group + MedianRT');
    
    coef_table_rt = mdl_rt.Coefficients;
    
    % Group × Age p-value
    int_row_rt = startsWith(coef_table_rt.Row, 'Age:Group');
    pvals_groupXage_rt(r) = coef_table_rt.pValue(int_row_rt);
    
    % MedianRT covariate p-value
    pvals_RT(r) = coef_table_rt.pValue(strcmp(coef_table_rt.Row,'MedianRT'));
end

% Save RT-based ROI results
roi_results_RT = table(roi_name(:), pvals_groupXage_rt, pvals_RT, ...
    'VariableNames', {'ROI','P_GroupXAge','P_MedianRT'});
writetable(roi_results_RT, fullfile(save_dir,'ROI_GroupXAge_RT_Results.csv'));

disp('✅ ROI analysis with MedianRT covariate complete.');

% Display results
disp('=== ROI Group × Age Interaction Analysis (controlling for MedianRT) ===');
disp(roi_results_RT);

sig_idx_rt = roi_results_RT.P_GroupXAge < 0.05;
if any(sig_idx_rt)
    disp('--- Significant Group × Age interactions after controlling for RT ---');
    disp(roi_results_RT(sig_idx_rt,:));
else
    disp('No Group × Age interactions remain significant after controlling for RT');
end

sig_rt_cov = roi_results_RT.P_MedianRT < 0.05;
if any(sig_rt_cov)
    disp('--- ROIs where MedianRT significantly predicts signal level ---');
    disp(roi_results_RT(sig_rt_cov,:));
end

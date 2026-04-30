% Clear workspace
clear; clc; close all;

% ========== File Paths ==========
save_dir = '/Users/daniela/Documents/Scratch/MothersVoice_ID_Analysis';
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
asd_pid_table = readtable('/Users/daniela/Documents/Scratch/MotherVoice_Analysis/ASD_TD_MothersVoice_Recordings/Data/Sublists_Agelists/ASD_selected_PID_List_n39_ADOS.csv');
td_pid_table  = readtable('/Users/daniela/Documents/Scratch/MotherVoice_Analysis/ASD_TD_MothersVoice_Recordings/Data/Sublists_Agelists/TD_selected_PID_List.csv');

% Extract and standardize PIDs
asd_pids = pad(string(asd_pid_table{:,1}), 4, 'left', '0');
td_pids  = pad(string(td_pid_table{:,1}), 4, 'left', '0');

% ========== Load Age Data ==========
asd_age_values = readmatrix('/Users/daniela/Documents/Scratch/MotherVoice_Analysis/ASD_TD_MothersVoice_Recordings/Data/Sublists_Agelists/ASD_selected_age_scan_n39_ADOS.txt');
td_age_values  = readmatrix('/Users/daniela/Documents/Scratch/MotherVoice_Analysis/ASD_TD_MothersVoice_Recordings/Data/Sublists_Agelists/TD_selected_age_scan.txt');

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

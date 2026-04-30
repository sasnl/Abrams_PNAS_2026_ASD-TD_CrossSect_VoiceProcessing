% ====================================================
% Test Group × Age interactions on ROI signal levels
% With and without controlling for Mother’s Voice ID accuracy
% ====================================================

% ---------- Clear Environment ----------
clear; clc;

% ---------- File Paths ----------
pid_dir = '/oak/stanford/groups/menon/projects/leipold/2022_ASD_CrossDevelop/data/subjectlist';
ASD_pid_fname = 'ASD_selected_PID_List_n39_ADOS.csv';
TD_pid_fname = 'TD_selected_PID_List.csv';

save_dir = '/oak/stanford/groups/menon/projects/leipold/2022_ASD_CrossDevelop/scripts/taskfmri/groupstats/glm_covar/signal_extraction_DA/ROI_Signal_Extract';
ASD_matfile = 'ASDonly_n39_SigLevels_Age_MotherOther.mat';
TD_matfile = 'TDonly_n40_SigLevels_Age_MotherOther.mat';

age_dir = '/oak/stanford/groups/menon/projects/leipold/2022_ASD_CrossDevelop/data/behavior';
ASD_age_fname = 'ASD_selected_age_scan_n39_ADOS.txt';
TD_age_fname = 'TD_selected_age_scan.txt';

ID_dir = '/oak/stanford/groups/menon/projects/leipold/2022_ASD_CrossDevelop/data/behavior/MotherVoiceID_Results';
ASD_ID_fname = 'ASD_summary.csv';
TD_ID_fname = 'TD_summary.csv';

% ---------- Load PID Lists ----------
ASD_pids = readtable(fullfile(pid_dir, ASD_pid_fname), 'ReadVariableNames', false);
TD_pids  = readtable(fullfile(pid_dir, TD_pid_fname),  'ReadVariableNames', false);
ASD_pids = ASD_pids(:, 1); ASD_pids.Properties.VariableNames = {'PID'};
TD_pids  = TD_pids(:, 1); TD_pids.Properties.VariableNames = {'PID'};

% ---------- Load ROI Signal Data ----------
ASD_data = load(fullfile(save_dir, ASD_matfile));
TD_data  = load(fullfile(save_dir, TD_matfile));
ASD_roi = ASD_data.roi_con;  % [n x 5]
TD_roi  = TD_data.roi_con;
roi_names = ASD_data.roi_name;  % 1x5 cell array

% ---------- Load Age Data ----------
ASD_age_raw = readtable(fullfile(age_dir, ASD_age_fname), ...
    'Delimiter', '\t', 'ReadVariableNames', false);
TD_age_raw  = readtable(fullfile(age_dir, TD_age_fname), ...
    'Delimiter', '\t', 'ReadVariableNames', false);
ASD_ages = ASD_age_raw.Var1;
TD_ages  = TD_age_raw.Var1;

% ---------- Load Mother’s Voice ID Accuracy ----------
ASD_ID = readtable(fullfile(ID_dir, ASD_ID_fname));
TD_ID  = readtable(fullfile(ID_dir, TD_ID_fname));
ASD_ID.PID = string(ASD_ID.PID);
TD_ID.PID  = string(TD_ID.PID);

% ---------- Assemble ASD Table ----------
ASD_tbl = table;
ASD_tbl.PID      = string(ASD_pids.PID);
ASD_tbl.Age      = ASD_ages;
ASD_tbl.ROI_all  = ASD_roi(1:height(ASD_pids), :);  % match by row
ASD_tbl.Accuracy = ASD_ID.MeanACC;
ASD_tbl.Group    = repmat("ASD", height(ASD_tbl), 1);

% ---------- Assemble TD Table ----------
TD_tbl = table;
TD_tbl.PID      = string(TD_pids.PID);
TD_tbl.Age      = TD_ages;
TD_tbl.ROI_all  = TD_roi(1:height(TD_pids), :);
TD_tbl.Accuracy = TD_ID.MeanACC;
TD_tbl.Group    = repmat("TD", height(TD_tbl), 1);

% ---------- Combine All Participants ----------
all_data = [ASD_tbl; TD_tbl];
all_data.Group = categorical(all_data.Group);
all_data.Group = reordercats(all_data.Group, {'TD', 'ASD'});  % make TD the reference

% ---------- Loop Through ROIs ----------
n_rois = size(all_data.ROI_all, 2);
fprintf('\n=== Group × Age Analysis for ROI Signal Levels ===\n');

for r = 1:n_rois
    roi_name = roi_names{r};

    % Build stable table for this ROI
    this_data = table;
    this_data.PID      = all_data.PID;
    this_data.Age      = all_data.Age;
    this_data.Accuracy = all_data.Accuracy;
    this_data.Group    = all_data.Group;
    this_data.ROI      = all_data.ROI_all(:, r);

    % Fit full model
    mdl2 = fitlm(this_data, 'ROI ~ Group*Age + Accuracy');

    fprintf('\n----- ROI: %s -----\n', roi_name);

    % Show all coefficients
    disp('Model Coefficients:');
    disp(mdl2.Coefficients);

    % Display Accuracy effect
    acc_idx = find(strcmp(mdl2.CoefficientNames, 'Accuracy'));
    fprintf('Accuracy term:\n');
    disp(mdl2.Coefficients(acc_idx, :));

    % Display Group × Age interaction
    interaction_idx = find(contains(mdl2.Coefficients.Properties.RowNames, 'Age:Group_'));
    if ~isempty(interaction_idx)
        fprintf('Group × Age interaction (controlling for Accuracy):\n');
        disp(mdl2.Coefficients(interaction_idx, :));
    else
        fprintf('No Group × Age interaction term found in model.\n');
    end
end




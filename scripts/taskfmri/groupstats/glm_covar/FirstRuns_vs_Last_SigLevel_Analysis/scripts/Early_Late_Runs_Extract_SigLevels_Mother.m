%% early_late_roi_mother_signal_analysis_multiROI.m
% Extract ROI signal for mother's voice from first-level SPM models
% using the first 3 vs last 3 runs across ASD and TD participants.
%
% Mother's voice signal is defined as:
%   - Exper
%
% ROIs:
%   - Left pSTS
%   - Right pSTS
%   - Left OFC
%
% Outputs:
%   1. Subject-level CSV with early/late values and change scores
%   2. Stats CSV with within-group and Group x Time results

clear; clc;

%% -------------------- USER SETTINGS --------------------
addpath('/oak/stanford/groups/menon/software/spm12');
spm('Defaults','fMRI');
spm_jobman('initcfg');

base_results_dir = '/oak/stanford/groups/menon/projects/leipold/2022_ASD_CrossDevelop/results/taskfmri/participants';
subjectlist_dir  = '/oak/stanford/groups/menon/projects/leipold/2022_ASD_CrossDevelop/data/subjectlist';

td_csv  = fullfile(subjectlist_dir, 'TD_selected_PID_List.csv');
asd_csv = fullfile(subjectlist_dir, 'ASD_selected_PID_List_n39_ADOS.csv');

roi_names = {'Left_pSTS', 'Right_pSTS', 'Left_OFC'};
roi_files = { ...
    '/oak/stanford/groups/menon/projects/leipold/2022_ASD_CrossDevelop/data/imaging/roi/gppi_elife19/left_pSTS.nii', ...
    '/oak/stanford/groups/menon/projects/leipold/2022_ASD_CrossDevelop/data/imaging/roi/gppi_elife19/right_pSTS.nii', ...
    '/oak/stanford/groups/menon/projects/leipold/2022_ASD_CrossDevelop/scripts/taskfmri/groupstats/glm_covar/signal_extraction_DA/ROI_Creation/MotherEnv_ROIs/roi_02_Left_OFC.nii' ...
};

stats_dir = '/oak/stanford/groups/menon/projects/leipold/2022_ASD_CrossDevelop/scripts/taskfmri/groupstats/glm_covar/FirstRuns_vs_Last_SigLevel_Analysis';

subject_output_csv = fullfile(stats_dir, 'ROI_EarlyLate_MotherSignal.csv');
stats_output_csv   = fullfile(stats_dir, 'ROI_EarlyLate_Mother_STATS.csv');

%% -------------------- CHECK ROI FILES --------------------
for r = 1:numel(roi_files)
    if ~exist(roi_files{r}, 'file')
        error('ROI file not found: %s', roi_files{r});
    end
end

if ~exist(stats_dir, 'dir')
    mkdir(stats_dir);
end

%% -------------------- LOAD SUBJECT TABLES --------------------
td_tbl  = readtable(td_csv);
asd_tbl = readtable(asd_csv);

td_tbl.Group  = repmat("TD", height(td_tbl), 1);
asd_tbl.Group = repmat("ASD", height(asd_tbl), 1);

all_tbl = [td_tbl; asd_tbl];

%% -------------------- DETECT COLUMN NAMES --------------------
varnames = all_tbl.Properties.VariableNames;

pid_col = varnames{find(contains(lower(varnames), 'pid'), 1)};
visit_col = varnames{find(contains(lower(varnames), 'visit'), 1)};
session_col = varnames{find(contains(lower(varnames), 'session'), 1)};

fprintf('\nDetected columns:\n');
fprintf('  PID     -> %s\n', pid_col);
fprintf('  Visit   -> %s\n', visit_col);
fprintf('  Session -> %s\n\n', session_col);

%% -------------------- SUBJECT-LEVEL EXTRACTION --------------------
results = table();

for i = 1:height(all_tbl)

    pid_val = all_tbl.(pid_col)(i);
    visit   = all_tbl.(visit_col)(i);
    session = all_tbl.(session_col)(i);
    group   = all_tbl.Group(i);

    if iscell(pid_val)
        pid_val = pid_val{1};
    end

    if ischar(pid_val) || isstring(pid_val)
        pid_num = str2double(regexprep(char(pid_val), '[^\d]', ''));
    else
        pid_num = pid_val;
    end

    pid = sprintf('%04d', pid_num);

    spm_path = fullfile(base_results_dir, pid, ...
        ['visit' num2str(visit)], ...
        ['session' num2str(session)], ...
        'glm', 'stats_spm12', 'stats_swgcar', 'SPM.mat');

    fprintf('Processing %s (%s)\n', pid, group);

    if ~exist(spm_path, 'file')
        warning('Missing SPM.mat for %s: %s', pid, spm_path);
        continue;
    end

    S = load(spm_path);
    SPM = S.SPM;

    run_ids = get_runs(SPM);

    if numel(run_ids) < 6
        warning('Skipping %s: fewer than 6 runs found in SPM.mat', pid);
        continue;
    end

    early_idx = 1:3;
    late_idx  = (numel(run_ids)-2):numel(run_ids);

    row = table(string(pid), string(group), visit, session, ...
        'VariableNames', {'PID','Group','Visit','Session'});

    for r = 1:length(roi_names)

        roi = roi_files{r};
        run_vals = nan(1, length(run_ids));

        for k = 1:length(run_ids)
            run_vals(k) = get_beta(SPM, run_ids(k), 'Exper', roi);
        end

        early_val = mean(run_vals(early_idx), 'omitnan');
        late_val  = mean(run_vals(late_idx), 'omitnan');
        diff_val  = late_val - early_val;

        row.([roi_names{r} '_Early']) = early_val;
        row.([roi_names{r} '_Late'])  = late_val;
        row.([roi_names{r} '_Diff'])  = diff_val;
    end

    results = [results; row];
end

%% -------------------- SAVE SUBJECT-LEVEL RESULTS --------------------
writetable(results, subject_output_csv);
fprintf('\nSaved subject-level results: %s\n', subject_output_csv);

%% -------------------- STATS --------------------
stats_results = table();

% Within-group early vs late
for r = 1:length(roi_names)

    roi = roi_names{r};
    fprintf('\n=== %s ===\n', roi);

    for g = ["ASD","TD"]

        idx = strcmp(results.Group, g);

        early = results.(roi + "_Early")(idx);
        late  = results.(roi + "_Late")(idx);

        [~, p, ~, stats] = ttest(late, early);

        fprintf('%s: t(%d)=%.3f, p=%.4f\n', g, stats.df, stats.tstat, p);

        new_row = table( ...
            string(roi), ...
            string(g), ...
            "Within", ...
            numel(early), ...
            stats.tstat, ...
            stats.df, ...
            p, ...
            'VariableNames', {'ROI','Group','Test','N','t','df','p'});

        stats_results = [stats_results; new_row];
    end
end

% Group x Time
for r = 1:length(roi_names)

    roi = roi_names{r};
    fprintf('\n=== Group x Time: %s ===\n', roi);

    idx_asd = strcmp(results.Group, "ASD");
    idx_td  = strcmp(results.Group, "TD");

    diff_asd = results.(roi + "_Diff")(idx_asd);
    diff_td  = results.(roi + "_Diff")(idx_td);

    [~, p, ~, stats] = ttest2(diff_asd, diff_td);

    fprintf('Group x Time: t(%0.1f)=%.3f, p=%.4f\n', stats.df, stats.tstat, p);

    new_row = table( ...
        string(roi), ...
        "ASD_vs_TD", ...
        "GroupXTime", ...
        numel(diff_asd) + numel(diff_td), ...
        stats.tstat, ...
        stats.df, ...
        p, ...
        'VariableNames', {'ROI','Group','Test','N','t','df','p'});

    stats_results = [stats_results; new_row];
end

%% -------------------- SAVE STATS RESULTS --------------------
writetable(stats_results, stats_output_csv);
fprintf('\nSaved stats results: %s\n', stats_output_csv);

%% -------------------- FUNCTIONS --------------------

function run_ids = get_runs(SPM)
    names = SPM.xX.name;
    run_ids = [];

    for i = 1:length(names)
        tok = regexp(names{i}, 'Sn\((\d+)\)', 'tokens');
        if ~isempty(tok)
            run_ids(end+1) = str2double(tok{1}{1}); %#ok<AGROW>
        end
    end

    run_ids = unique(run_ids);
end

function val = get_beta(SPM, sn, cond, roi)

    pattern = sprintf('Sn\\(%d\\) %s\\*bf\\(1\\)', sn, cond);
    idx = find(~cellfun('isempty', regexp(SPM.xX.name, pattern, 'once')));

    if isempty(idx)
        error('Could not find regressor for Sn(%d) %s*bf(1)', sn, cond);
    end

    if numel(idx) > 1
        error('Multiple regressors matched for Sn(%d) %s*bf(1)', sn, cond);
    end

    beta = fullfile(SPM.swd, SPM.Vbeta(idx).fname);
    val = spm_summarise(beta, roi, @mean);
end
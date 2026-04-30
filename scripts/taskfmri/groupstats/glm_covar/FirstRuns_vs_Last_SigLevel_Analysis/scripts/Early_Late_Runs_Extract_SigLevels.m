%% early_late_roi_mother_signal_analysis_multiROI.m

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

output_dir = '/oak/stanford/groups/menon/projects/leipold/2022_ASD_CrossDevelop/scripts/taskfmri/groupstats/glm_covar/FirstRuns_vs_Last_SigLevel_Analysis/results';
output_csv = fullfile(output_dir, 'ROI_EarlyLate_MotherSignal.csv');

%% -------------------- LOAD SUBJECT LISTS --------------------
td_tbl  = readtable(td_csv);
asd_tbl = readtable(asd_csv);

td_tbl.Group  = repmat("TD", height(td_tbl), 1);
asd_tbl.Group = repmat("ASD", height(asd_tbl), 1);

all_tbl = [td_tbl; asd_tbl];

%% -------------------- LOOP OVER SUBJECTS --------------------
results = table();

for i = 1:height(all_tbl)

    pid     = sprintf('%04d', all_tbl.PID(i));
    visit   = all_tbl.visit(i);
    session = all_tbl.session(i);
    group   = all_tbl.Group(i);

    spm_path = fullfile(base_results_dir, pid, ...
        ['visit' num2str(visit)], ...
        ['session' num2str(session)], ...
        'glm','stats_spm12','stats_swgcar','SPM.mat');

    fprintf('Processing %s (%s)\n', pid, group);

    if ~exist(spm_path,'file')
        warning('Missing SPM: %s', pid);
        continue;
    end

    load(spm_path);

    [run_ids, ~] = get_runs(SPM);

    if numel(run_ids) < 6
        continue;
    end

    early_idx = 1:3;
    late_idx  = (numel(run_ids)-2):numel(run_ids);

    row = table(string(pid), string(group), 'VariableNames', {'PID','Group'});

    for r = 1:length(roi_names)

        roi = roi_files{r};

        run_vals = nan(1,length(run_ids));

        for k = 1:length(run_ids)
            run_vals(k) = get_beta(SPM, run_ids(k), 'Exper', roi);
        end

        early = mean(run_vals(early_idx));
        late  = mean(run_vals(late_idx));

        row.([roi_names{r} '_Early']) = early;
        row.([roi_names{r} '_Late'])  = late;
        row.([roi_names{r} '_Diff'])  = late - early;
    end

    results = [results; row];
end

%% -------------------- SAVE --------------------
writetable(results, output_csv);
fprintf('\nSaved: %s\n', output_csv);

%% -------------------- STATS --------------------
for r = 1:length(roi_names)

    roi = roi_names{r};

    fprintf('\n=== %s ===\n', roi);

    for g = ["ASD","TD"]

        idx = strcmp(results.Group,g);

        early = results.(roi + "_Early")(idx);
        late  = results.(roi + "_Late")(idx);

        [~,p,~,stats] = ttest(late,early);

        fprintf('%s: t(%d)=%.3f, p=%.4f\n', g, stats.df, stats.tstat, p);
    end
end

%% -------------------- GROUP × TIME ANALYSIS --------------------

for r = 1:length(roi_names)

    roi = roi_names{r};

    fprintf('\n=== Group x Time: %s ===\n', roi);

    idx_asd = strcmp(results.Group, "ASD");
    idx_td  = strcmp(results.Group, "TD");

    diff_asd = results.(roi + "_Diff")(idx_asd);
    diff_td  = results.(roi + "_Diff")(idx_td);

    [~,p,~,stats] = ttest2(diff_asd, diff_td);

    fprintf('Group x Time: t(%0.1f)=%.3f, p=%.4f\n', ...
        stats.df, stats.tstat, p);
end


%% -------------------- FUNCTIONS --------------------

function [run_ids, idx] = get_runs(SPM)

    names = SPM.xX.name;
    run_ids = [];

    for i = 1:length(names)
        tok = regexp(names{i}, 'Sn\((\d+)\)', 'tokens');
        if ~isempty(tok)
            run_ids(end+1) = str2double(tok{1});
        end
    end

    run_ids = unique(run_ids);
    idx = [];
end

function val = get_beta(SPM, sn, cond, roi)

    pattern = sprintf('Sn\\(%d\\) %s\\*bf\\(1\\)', sn, cond);
    idx = find(~cellfun('isempty', regexp(SPM.xX.name, pattern)));

    beta = fullfile(SPM.swd, SPM.Vbeta(idx).fname);
    val = spm_summarise(beta, roi, @mean);
end
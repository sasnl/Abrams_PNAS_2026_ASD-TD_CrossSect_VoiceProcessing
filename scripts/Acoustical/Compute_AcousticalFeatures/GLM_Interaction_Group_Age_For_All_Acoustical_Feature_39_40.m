clear all; close all; clc

% =============================
% Load TD Data
% =============================
load('/Users/daa/Documents/Scratch/TD_ASD_CrossSectional/ASD_TD_MothersVoice_Recordings/Results/Results_Praat_Acoustical_Analysis/Results_Praat_Acoustical_Analysis_TD_n40.mat');
td_mean_values_per_mom = mean_vals_per_mom;
load('/Users/daa/Documents/Scratch/TD_ASD_CrossSectional/ASD_TD_MothersVoice_Recordings/Data/Sublists_Agelists/TD_selected_age_scan.txt');
td_age = TD_selected_age_scan;

% =============================
% Load ASD Data
% =============================
load('/Users/daa/Documents/Scratch/TD_ASD_CrossSectional/ASD_TD_MothersVoice_Recordings/Results/Results_Praat_Acoustical_Analysis/Results_Praat_Acoustical_Analysis_ASD_n39.mat');
asd_mean_values_per_mom = mean_vals_per_mom;
load('/Users/daa/Documents/Scratch/TD_ASD_CrossSectional/ASD_TD_MothersVoice_Recordings/Data/Sublists_Agelists/ASD_selected_age_scan_n39_ADOS.txt');
asd_age = ASD_selected_age_scan_n39_ADOS;

% Load column headers (assumed to be in the same file)
col_headers = col_headers;

% =============================
% Select features to analyze
% =============================
% Desired feature names -- ONLY Looking at Pitch
selected_features = {'pitch_mean', 'pitch_stdev', 'pitch_slope'};

% Get indices for selected features
[~, selected_indices] = ismember(selected_features, col_headers);

% Filter data
td_data = td_mean_values_per_mom(:, selected_indices);
asd_data = asd_mean_values_per_mom(:, selected_indices);
feature_labels = col_headers(selected_indices);

% =============================
% Run GLM + plot
% =============================
n_features = numel(selected_indices);

% Preallocate
td_age_betas = nan(n_features, 1);
td_age_pvals = nan(n_features, 1);
td_age_tvals = nan(n_features, 1);
td_df        = nan(n_features, 1);

asd_age_betas = nan(n_features, 1);
asd_age_pvals = nan(n_features, 1);
asd_age_tvals = nan(n_features, 1);
asd_df        = nan(n_features, 1);

interaction_betas = nan(n_features, 1);
interaction_pvals = nan(n_features, 1);
interaction_tvals = nan(n_features, 1);
interaction_df    = nan(n_features, 1);


figure;
set(gcf, 'Position', [100 100 1200 800]);  % Large figure for subplots

fprintf('\nTesting Age × Group interaction and within-group Age effects for selected acoustic features:\n');

for i = 1:n_features
    % Extract feature
    y_td = td_data(:, i);
    y_asd = asd_data(:, i);
    y_all = [y_td; y_asd];
    age_all = [td_age; asd_age];
    group_all = [zeros(size(y_td)); ones(size(y_asd))]; % 0 = TD, 1 = ASD

    % Build table with categorical group for stable coefficient names
    Group = categorical(group_all, [0 1], {'TD','ASD'});
    tbl = table(y_all, age_all, Group, ...
        'VariableNames', {'Acoustic', 'Age', 'Group'});

    % Combined LM with interaction
    lm = fitlm(tbl, 'Acoustic ~ Age * Group');  % includes main effects + interaction

    % Pull the Age×Group interaction (Age:Group_ASD)
    int_name = 'Age:Group_ASD';
    int_idx = find(strcmp(lm.CoefficientNames, int_name), 1, 'first');
    if ~isempty(int_idx)
        interaction_pvals(i) = lm.Coefficients.pValue(int_idx);
        interaction_betas(i) = lm.Coefficients.Estimate(int_idx);
        interaction_tstats(i) = lm.Coefficients.tStat(int_idx);

    else
        warning('Interaction term %s not found for feature %s.', int_name, feature_labels{i});
    end

    fprintf('%s | Age×Group p = %.4f\n', feature_labels{i}, interaction_pvals(i));
    if interaction_pvals(i) < 0.05
        fprintf('  ➤ Significant interaction\n');
    end

    % Within-group Age effects: separate simple LMs per group
    % TD model
    tbl_TD = table(td_data(:, i), td_age, 'VariableNames', {'Acoustic','Age'});
    lm_TD = fitlm(tbl_TD, 'Acoustic ~ Age');
    td_age_betas(i) = lm_TD.Coefficients.Estimate('Age');
    td_age_pvals(i) = lm_TD.Coefficients.pValue('Age');
    td_age_tvals(i) = lm_TD.Coefficients.tStat('Age');
    td_df(i)        = lm_TD.DFE;

    % ASD model
    tbl_ASD = table(asd_data(:, i), asd_age, 'VariableNames', {'Acoustic','Age'});
    lm_ASD = fitlm(tbl_ASD, 'Acoustic ~ Age');
    asd_age_betas(i) = lm_ASD.Coefficients.Estimate('Age');
    asd_age_pvals(i) = lm_ASD.Coefficients.pValue('Age');
    asd_age_tvals(i) = lm_ASD.Coefficients.tStat('Age');
    asd_df(i)        = lm_ASD.DFE;

    % Combined model with interaction
    y_all = [td_data(:, i); asd_data(:, i)];
    age_all = [td_age; asd_age];
    group_all = [zeros(size(td_age)); ones(size(asd_age))];
    Group = categorical(group_all, [0 1], {'TD','ASD'});
    tbl_all = table(y_all, age_all, Group, ...
        'VariableNames', {'Acoustic','Age','Group'});
    lm_all = fitlm(tbl_all, 'Acoustic ~ Age * Group');
    idx = find(strcmp(lm_all.CoefficientNames,'Age:Group_ASD'));
    interaction_betas(i) = lm_all.Coefficients.Estimate(idx);
    interaction_pvals(i) = lm_all.Coefficients.pValue(idx);
    interaction_tvals(i) = lm_all.Coefficients.tStat(idx);
    interaction_df(i)    = lm_all.DFE;


    % Plot (same look)
    subplot(1, 3, i);
    hold on;

    % TD
    scatter(td_age, y_td, 40, 'o', 'MarkerEdgeColor', 'b', 'DisplayName', 'TD', 'LineWidth', 1.5);
    p_td = polyfit(td_age, y_td, 1);
    x_fit = linspace(min(td_age), max(td_age), 100);
    y_fit_td = polyval(p_td, x_fit);
    plot(x_fit, y_fit_td, 'b-', 'LineWidth', 1.5);

    % ASD
    scatter(asd_age, y_asd, 40, 'x', 'MarkerEdgeColor', 'r', 'DisplayName', 'ASD', 'LineWidth', 2);
    p_asd = polyfit(asd_age, y_asd, 1);
    y_fit_asd = polyval(p_asd, x_fit);
    plot(x_fit, y_fit_asd, 'r--', 'LineWidth', 1.5);

    grid off; box off;
    xlim([7 17]);
    set(gca, 'FontWeight', 'bold');
    set(gca, 'FontSize', 14);
end

% Final results table with interaction + within-group Age effects
% Build results table with everything
results_table = table( ...
    feature_labels(:), ...
    td_age_betas, td_age_tvals, td_df, td_age_pvals, ...
    asd_age_betas, asd_age_tvals, asd_df, asd_age_pvals, ...
    interaction_betas, interaction_tvals, interaction_df, interaction_pvals, ...
    'VariableNames', {'Feature', ...
                      'TD_beta','TD_t','TD_df','TD_p', ...
                      'ASD_beta','ASD_t','ASD_df','ASD_p', ...
                      'Age_x_Group_beta','Age_x_Group_t','Age_x_Group_df','Age_x_Group_p'});



disp(results_table);

% =============================
% Save figure + results table
% =============================
fig_dir = '/Users/daa/Documents/Scratch/TD_ASD_CrossSectional/ASD_TD_MothersVoice_Recordings/Results/Scatterplots_Age_vs_Acoustics';
stats_dir = '/Users/daa/Documents/Scratch/TD_ASD_CrossSectional/ASD_TD_MothersVoice_Recordings/Results/Statistical_Results_Mother_Voice_Acoustics';
% if ~exist(save_dir, 'dir'); mkdir(save_dir); end

% Figure (same as before; PNG suggested; EMF if needed for vector editors)
save_fname_fig = 'Acoustical_Results_n39_40.png';
save_path_fig = fullfile(fig_dir, save_fname_fig);
set(gcf, 'Position', [100 653 837 247]);
fig = gcf; fig.PaperPositionMode = 'auto';
resolution = 600; % DPI
% print(save_path_fig, '-dpng', ['-r', num2str(resolution)]);

% Results table files
save_fname_csv = 'Acoustical_Results_stats_n39_40.csv';
save_fname_mat = 'Acoustical_Results_stats_n39_40.mat';
writetable(results_table, fullfile(stats_dir, save_fname_csv));
save(fullfile(stats_dir, save_fname_mat), 'results_table');
fprintf('\nSaved results to:\n  %s\n  %s\n', fullfile(stats_dir, save_fname_csv), fullfile(stats_dir, save_fname_mat));

clear; clc;

% =======================
% Load ROI Data
% =======================
load('/Users/daniela/Documents/Scratch/MotherVoice_Analysis/ASD_TD_MothersVoice_Recordings/Data/ROI_Sig_Levels/TDonly_n40_SigLevels_Age_MotherEnv.mat');
roi_signals_TD = roi_con; clear roi_con;

load('/Users/daniela/Documents/Scratch/MotherVoice_Analysis/ASD_TD_MothersVoice_Recordings/Data/ROI_Sig_Levels/ASDonly_n39_SigLevels_Age_MotherEnv.mat');
roi_signals_ASD = roi_con; clear roi_con;

% =======================
% Load Acoustic Data
% =======================
load('/Users/daniela/Documents/Scratch/MotherVoice_Analysis/ASD_TD_MothersVoice_Recordings/Results/Results_Praat_Acoustical_Analysis/Results_Praat_Acoustical_Analysis_TD_n40.mat');
td_acoust_all = mean_vals_per_mom;

load('/Users/daniela/Documents/Scratch/MotherVoice_Analysis/ASD_TD_MothersVoice_Recordings/Results/Results_Praat_Acoustical_Analysis/Results_Praat_Acoustical_Analysis_ASD_n39.mat');
asd_acoust_all = mean_vals_per_mom;
col_headers = col_headers;

% =======================
% Define Acoustic Features
% =======================
selected_acoustic_labels = {'pitch_mean','pitch_stdev','pitch_slope'};
[is_found, acoustic_indices] = ismember(selected_acoustic_labels, col_headers);

if any(~is_found)
    error('Missing acoustic features: %s', strjoin(selected_acoustic_labels(~is_found), ', '));
end

acoustics_TD = td_acoust_all(:, acoustic_indices);
acoustics_ASD = asd_acoust_all(:, acoustic_indices);
acoustic_labels = selected_acoustic_labels;

roi_labels = roi_name;
R = size(roi_signals_TD, 2);
M = size(acoustics_TD, 2);

% =======================
% Correlation Analysis per Group
% =======================
result_rows = {};

for r = 1:R
    for m = 1:M
        % Get ROI and acoustic values
        x_TD = acoustics_TD(:, m);
        y_TD = roi_signals_TD(:, r);
        x_ASD = acoustics_ASD(:, m);
        y_ASD = roi_signals_ASD(:, r);

        % Correlations within each group
        [r_td, p_td] = corr(x_TD, y_TD, 'Type', 'Pearson');
        [r_asd, p_asd] = corr(x_ASD, y_ASD, 'Type', 'Pearson');

        % Fisher z-transformation for between-group comparison
        n1 = length(x_TD);
        n2 = length(x_ASD);
        z1 = atanh(r_td);  % Fisher z
        z2 = atanh(r_asd);
        se_diff = sqrt(1/(n1 - 3) + 1/(n2 - 3));
        z_diff = (z1 - z2) / se_diff;
        p_diff = 2 * (1 - normcdf(abs(z_diff)));  % Two-tailed test

        % Store results
        result_rows{end+1, 1} = roi_labels{r};
        result_rows{end, 2} = acoustic_labels{m};
        result_rows{end, 3} = r_td;
        result_rows{end, 4} = p_td;
        result_rows{end, 5} = r_asd;
        result_rows{end, 6} = p_asd;
        result_rows{end, 7} = p_diff;
    end
end

results_table = cell2table(result_rows, ...
    'VariableNames', {'ROI', 'AcousticFeature', ...
                      'r_TD', 'p_TD', ...
                      'r_ASD', 'p_ASD', ...
                      'p_GroupDiff'});

% Optional: sort by ROI or by p_GroupDiff
results_table = sortrows(results_table, {'ROI', 'AcousticFeature'});

% Display results
disp(results_table);

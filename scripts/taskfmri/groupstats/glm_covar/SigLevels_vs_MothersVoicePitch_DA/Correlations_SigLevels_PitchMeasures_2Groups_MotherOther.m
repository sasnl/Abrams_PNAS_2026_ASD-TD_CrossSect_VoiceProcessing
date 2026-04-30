clear all; close all; clc

% ===========================================
% Config Files
% ===========================================

% Get Sig Level Data
save_dir = '/oak/stanford/groups/menon/projects/leipold/2022_ASD_CrossDevelop/scripts/taskfmri/groupstats/glm_covar/signal_extraction_DA/ROI_Signal_Extract';
ASD_save_fname = 'ASDonly_n40_SigLevels_Age_MotherOther.mat';
TD_save_fname = 'TDonly_n40_SigLevels_Age_MotherOther.mat';

% Acoustical Data Paths
td_acoust_path = '/oak/stanford/groups/menon/projects/leipold/2022_ASD_CrossDevelop/results/Acoustical/Results_Praat_Acoustical_Analysis_TD_n40.mat';
asd_acoust_path = '/oak/stanford/groups/menon/projects/leipold/2022_ASD_CrossDevelop/results/Acoustical/Results_Praat_Acoustical_Analysis_ASD_n40.mat';

% ===========================================
% ===========================================

% Load TD acoustical data
load(td_acoust_path);
td_mean_vals_per_mom = mean_vals_per_mom;

clear mean_vals_per_mom

% Load TD acoustical data
load(asd_acoust_path);
asd_mean_vals_per_mom = mean_vals_per_mom;

clear mean_vals_per_mom

% load Signal Level Files
load(fullfile(save_dir, ASD_save_fname), 'roi_con', 'roi_name');
asd_roi_con = roi_con;
clear roi_con

load(fullfile(save_dir, TD_save_fname), 'roi_con', 'roi_name');
td_roi_con = roi_con;
clear roi_con

% Here are the headers for the acoustical variable
col_headers = {'pitch_mean', 'pitch_min', 'pitch_max', 'pitch_stdev', 'pitch_slope',...
    'spectral_center_gravity', 'spectral_stdev', 'spectral_skew'};

% Create a TD data matrix (40x8)
td_data = td_roi_con;
td_data(:,6) = td_mean_vals_per_mom(:,1);
td_data(:,7) = td_mean_vals_per_mom(:,4);
td_data(:,8) = td_mean_vals_per_mom(:,5);

corr_vars = roi_name;
corr_vars{6} = 'pitch_mean';
corr_vars{7} = 'pitch_stdev';
corr_vars{8} = 'pitch_slope';

% Create a ASD data matrix (40x8)
asd_data = asd_roi_con;
asd_data(:,6) = asd_mean_vals_per_mom(:,1);
asd_data(:,7) = asd_mean_vals_per_mom(:,4);
asd_data(:,8) = asd_mean_vals_per_mom(:,5);

% % Calculate the TD correlation matrix
td_correlationMatrix = corr(td_data);
[R_td, P_td] = corrcoef(td_data);

% Get subset of correlation -- just want corr between pitch measures and
% sig levels
subsetCorrelation_td_p = P_td(6:8,1);
subsetCorrelation_td_r = R_td(6:8,1);
q_td = mafdr(subsetCorrelation_td_p(:))

% Plot the heatmap of the subset
h = heatmap(subsetCorrelation_td_r);
h.XDisplayLabels = repmat({''}, size(subsetCorrelation_td_r, 2), 1); % Empty labels for X-axis
h.YDisplayLabels = repmat({''}, size(subsetCorrelation_td_r, 1), 1); 

% Adjust color limits and colormap
h.ColorLimits = [-1, 1]; % Set color limits for correlation
colormap(jet); % Change to 'jet' colormap

% Not saving these plots
% % Save the figure as a PNG file with high resolution
% save_path = '/oak/stanford/groups/menon/projects/leipold/2022_ASD_CrossDevelop/results/taskfmri/groupstats/glm_signals_vs_acoustics';
% save_name_td = 'TD_Heatmap_Pitch_vs_SigLevels_MotherOther.png';
% exportgraphics(gcf, save_name_td, 'Resolution', 600); 

% % Calculate the ASD correlation matrix
asd_correlationMatrix = corr(asd_data);
[R_asd, P_asd] = corrcoef(asd_data);

% Get subset of correlation -- just want corr between pitch measures and
% sig levels
subsetCorrelation_asd_p = P_asd(6:8,1);
subsetCorrelation_asd_r = R_asd(6:8,1);
q_asd = mafdr(subsetCorrelation_asd_p(:))

% Plot the heatmap of the subset
figure
h = heatmap(subsetCorrelation_asd_r);
h.XDisplayLabels = repmat({''}, size(subsetCorrelation_asd_r, 2), 1); % Empty labels for X-axis
h.YDisplayLabels = repmat({''}, size(subsetCorrelation_asd_r, 1), 1); 

% Adjust color limits and colormap
h.ColorLimits = [-1, 1]; % Set color limits for correlation
colormap(jet); % Change to 'jet' colormap

% Not saving these plots
% % Save the figure as a PNG file with high resolution
% save_path = '/oak/stanford/groups/menon/projects/leipold/2022_ASD_CrossDevelop/results/taskfmri/groupstats/glm_signals_vs_acoustics';
% save_name_asd = 'ASD_Heatmap_Pitch_vs_SigLevels_MotherOther.png';
% exportgraphics(gcf, save_name_asd, 'Resolution', 600); 








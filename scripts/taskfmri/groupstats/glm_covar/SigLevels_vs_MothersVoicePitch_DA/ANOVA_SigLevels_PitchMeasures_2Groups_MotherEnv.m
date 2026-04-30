clear all; close all; clc

% ===========================================
% Config Files
% ===========================================

% Get Sig Level Data
save_dir = '/oak/stanford/groups/menon/projects/leipold/2022_ASD_CrossDevelop/scripts/taskfmri/groupstats/glm_covar/signal_extraction_DA/ROI_Signal_Extract';
ASD_save_fname = 'ASDonly_n40_SigLevels_Age_MotherEnv.mat';
TD_save_fname = 'TDonly_n40_SigLevels_Age_MotherEnv.mat';

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

numSubjects = 80; % Total number of subjects
numMeasures = 8; % 3 pitch + 5 activation
group = [ones(40, 1); 2*ones(40, 1)]; % Group labels (1 and 2)

% % Load data into variables
pitch1 = [td_mean_vals_per_mom(:,1); asd_mean_vals_per_mom(:,1)]; % Pitch mean
pitch2 = [td_mean_vals_per_mom(:,4); asd_mean_vals_per_mom(:,4)]; % Pitch STDev
pitch3 = [td_mean_vals_per_mom(:,5); asd_mean_vals_per_mom(:,5)]; % Pitch slope;
activation1 = [td_roi_con(:,1); asd_roi_con(:,1); ]; % Left AI
activation2 = [td_roi_con(:,2); asd_roi_con(:,2); ]; % Left OFC
activation3 = [td_roi_con(:,3); asd_roi_con(:,3); ]; % Left Precun
activation4 = [td_roi_con(:,4); asd_roi_con(:,4); ]; % Right AG
activation5 = [td_roi_con(:,5); asd_roi_con(:,5); ]; % Left DLPFC

% Create a table
data = table(pitch1, pitch2, pitch3, activation1, activation2, activation3, activation4, activation5, group);

% Reshape data for three-way RMANOVA
% Create a new table for repeated measures
rmData = table();

% Add measures to the table
rmData.Subject = repmat((1:numSubjects)', numMeasures, 1); % Subject IDs
rmData.Group = repmat(group, numMeasures, 1); % Group labels

% Create a long format for pitch measures and activation measures
rmData.Measure = [repmat({'Pitch1'}, numSubjects, 1); 
                  repmat({'Pitch2'}, numSubjects, 1); 
                  repmat({'Pitch3'}, numSubjects, 1); 
                  repmat({'Activation1'}, numSubjects, 1); 
                  repmat({'Activation2'}, numSubjects, 1); 
                  repmat({'Activation3'}, numSubjects, 1); 
                  repmat({'Activation4'}, numSubjects, 1); 
                  repmat({'Activation5'}, numSubjects, 1)];

% Add the corresponding values
rmData.Value = [data.pitch1; data.pitch2; data.pitch3; 
                data.activation1; data.activation2; 
                data.activation3; data.activation4; 
                data.activation5];


% Perform three-way ANOVA
[p, tbl, stats] = anovan(rmData.Value, {rmData.Group, rmData.Measure}, ...
                          'model', 'interaction', ...
                          'varnames', {'Group', 'Measure'}, ...
                          'display', 'on');







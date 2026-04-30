clear all; close all; clc
% addpath(genpath('\\citron.stanford.edu\mnt\mapricot\musk2\home\daa\FreqUsedMatlabScripts'));

% % ==========================================================
% Check to make sure that Praat analyzed all Exp Moms
% % ==========================================================

% load in the TD sublist
sublist_path = '/Users/daniela/Documents/Scratch/ASD_TD_MothersVoice_Recordings/Data/Sublists_Agelists/TD_selected_PID_List.csv';
sublist = readmatrix(sublist_path);
sublist = sublist(:,1);
no_subs = length(sublist);

PID_ScanID_TD = sublist;

res_dir = '/Users/daniela/Documents/Scratch/ASD_TD_MothersVoice_Recordings/Data/Voice_Samples';

% Check for Praat Result.txt files
for sub_i = 1:no_subs

    path_praat_data = fullfile(res_dir, ['ExpMom_Sub' int2str(PID_ScanID_TD(sub_i))],...
        'FINAL', 'Result.txt');
    
    tf(sub_i,1) = exist(path_praat_data);
    
end
 

% % ==========================================================
% Load and Calc Mean of each acoustical measure for each Exp Mom
% % ==========================================================

col_headers = {'pitch_mean', 'pitch_min', 'pitch_max', 'pitch_stdev', 'pitch_slope',...
    'spectral_center_gravity', 'spectral_stdev', 'spectral_skew'};

% % ====================================================

for sub_i = 1:no_subs

    path_praat_data = fullfile(res_dir, ['ExpMom_Sub' int2str(PID_ScanID_TD(sub_i))],...
        'FINAL', 'Result.txt');

    newData1 = importdata(path_praat_data);

    mean_vals_per_mom(sub_i, :) = mean(newData1.data);

end

% % ==========================================================
% Save Mean of each acoustical measure for each Exp Mom
% % ==========================================================

results_dir = '/Users/daniela/Documents/Scratch/ASD_TD_MothersVoice_Recordings/Results/Results_Praat_Acoustical_Analysis';
save_fname = fullfile(results_dir, 'Results_Praat_Acoustical_Analysis_TD_n40.mat');
save(save_fname, 'mean_vals_per_mom');
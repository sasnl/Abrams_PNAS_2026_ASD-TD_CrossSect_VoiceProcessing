% Create a figure for plotting
clear all; close all; clc

figureHandle = figure('Visible', 'off'); % so that you dont have pop ups

% Add SPM to the MATLAB path
addpath('/oak/stanford/groups/menon/software/spm12'); % Change this to your SPM installation path
spm('defaults', 'FMRI');
spm_jobman('initcfg');

addpath(genpath('/oak/stanford/groups/menon/projects/leipold/2022_ASD_CrossDevelop/scripts/taskfmri/groupstats/gppi_covar/slicer'))

% Specify top-level results directory
groupstats_dir = '/oak/stanford/groups/menon/projects/leipold/2022_ASD_CrossDevelop/results/taskfmri/groupstats/glm';

% Specify folder name with stat comparison
comparison_name = 'gPPI_two_sample_covar_age_ASD_TD';
results_dir = fullfile(groupstats_dir, comparison_name);

% Specify directory names for each gPPI seed
PPI_ROI_Results_Folder = {'PPI_left_AI_spm12', 'PPI_left_pSTS_spm12', 'PPI_left_vmPFC_spm12',...
    'PPI_right_AI_spm12', 'PPI_right_pSTS_spm12'};

% Specify directory names for contrasts
PPI_Contrast_Folders = {'001T_mother_min_environ', '003T_others_min_environ',...
    '009T_mother_min_other', '011T_speech_min_environ'};

for roi_i = 1 %:length(PPI_ROI_Results_Folder);

    for con_i = 1 %:length(PPI_Contrast_Folders);

        % Specify the directory containing the fMRI images
        inputDir = fullfile(results_dir, PPI_ROI_Results_Folder{roi_i}, PPI_Contrast_Folders{con_i}); % Change this to your input directory

        get_thresh_fnames = dir(fullfile(inputDir, 'group*.nii'));

        for spmT_i = 2 % 1:2

            % Get fnames for thresholded images
            spmT_fname = get_thresh_fnames(spmT_i).name;

            % Specify the fMRI image file
            fMRI_image = fullfile(inputDir, spmT_fname); %  image path

            % Specify the path to your NIfTI file
            nifti_file = fMRI_image;

            % Check if the file exists
            if ~isfile(nifti_file)
                error('NIfTI file does not exist at the specified path.');
            end

            slicer({2,nifti_file},...
                'limits',{[],[3.5 6]},...
                'minClusterSize',{0,50},...
                'labels',{[],'T-value'},... % when a layer's label is empty no colorbar will be printed.
                'cbLocation','east',... % colorbar location can be south or east
                'title','Just a Random T-map',...
                'output','example_1')

        end
    end
end

% Configuration file for scsnl_gPPI.m
% _________________________________________________________________________
% 2013 Stanford Cognitive and Systems Neuroscience Laboratory

paralist.spmversion = 'spm12';
paralist.parallel = '1';
% Please specify the data server path
paralist.projectdir = '/oak/stanford/groups/menon/projects/leipold/2022_ASD_CrossDevelop/';

paralist.maskfile ='';  % this will give a whole brain map
% If the mask is specified, only voxels in the mask will be calculated
%paralist.maskfile = '/oak/stanford/groups/menon/projects/leipold/2022_ASD_CrossDevelop/data/imaging/roi/fsl41_greymatter_bin.nii';

% Please specify the subject list file (.txt) or a cell array

paralist.subjectlist = '/oak/stanford/groups/menon/projects/leipold/2022_ASD_CrossDevelop/data/subjectlist/nrunwise/FullSample9Runs_PID_List.csv';

% Please specify the stats folder name (eg., stats_spm8)
paralist.stats_folder = 'stats_swgcar';

% Please speficy the gPPI  output folder; If you don't specify then results will save to ['stats_folder'_gPPI]
paralist.gPPI_output_folder = 'stats_swgcar_gPPI_triplenet_betas';

% Please specify the .nii file(s) for the ROI(s)
paralist.roi_file_list = {'/oak/stanford/groups/menon/projects/leipold/2022_ASD_CrossDevelop/data/imaging/roi/gppi_tripleplusSTS/roi01_PCC_Precuneus.nii',
'/oak/stanford/groups/menon/projects/leipold/2022_ASD_CrossDevelop/data/imaging/roi/gppi_tripleplusSTS/roi02_left_angular.nii',
'/oak/stanford/groups/menon/projects/leipold/2022_ASD_CrossDevelop/data/imaging/roi/gppi_tripleplusSTS/roi03_right_angular.nii',
'/oak/stanford/groups/menon/projects/leipold/2022_ASD_CrossDevelop/data/imaging/roi/gppi_tripleplusSTS/roi04_vmPFC.nii',
'/oak/stanford/groups/menon/projects/leipold/2022_ASD_CrossDevelop/data/imaging/roi/gppi_tripleplusSTS/roi05_left_dlPFC.nii',
'/oak/stanford/groups/menon/projects/leipold/2022_ASD_CrossDevelop/data/imaging/roi/gppi_tripleplusSTS/roi06_right_dlPFC.nii',
'/oak/stanford/groups/menon/projects/leipold/2022_ASD_CrossDevelop/data/imaging/roi/gppi_tripleplusSTS/roi07_left_SPL.nii',
'/oak/stanford/groups/menon/projects/leipold/2022_ASD_CrossDevelop/data/imaging/roi/gppi_tripleplusSTS/roi08_right_SPL.nii',
'/oak/stanford/groups/menon/projects/leipold/2022_ASD_CrossDevelop/data/imaging/roi/gppi_tripleplusSTS/roi09_left_ant_insula.nii',
'/oak/stanford/groups/menon/projects/leipold/2022_ASD_CrossDevelop/data/imaging/roi/gppi_tripleplusSTS/roi10_right_ant_insula.nii',
'/oak/stanford/groups/menon/projects/leipold/2022_ASD_CrossDevelop/data/imaging/roi/gppi_tripleplusSTS/roi11_ACC.nii',
'/oak/stanford/groups/menon/projects/leipold/2022_ASD_CrossDevelop/data/imaging/roi/gppi_tripleplusSTS/roi12_left_pSTS.nii',
'/oak/stanford/groups/menon/projects/leipold/2022_ASD_CrossDevelop/data/imaging/roi/gppi_tripleplusSTS/roi13_right_pSTS.nii'
};

% Please specify the name of the ROI
paralist.roi_name_list = {'roi01_PCC_Precuneus',
'roi02_left_angular',
'roi03_right_angular',
'roi04_vmPFC',
'roi05_left_dlPFC',
'roi06_right_dlPFC',
'roi07_left_SPL',
'roi08_right_SPL',
'roi09_left_ant_insula',
'roi10_right_ant_insula',
'roi11_ACC',
'roi12_left_pSTS',
'roi13_right_pSTS.nii'
};

%% Please specifiy the way to extract time series (mean or eigenvector)
%paralist.extract_type = 'mean';
paralist.extract_type = 'eig';

% Please specify the task to include
% tasks_to_include = { '1', 'task1', 'task2', 'task3'} -> must exist in all sessions
% tasks_to_include = { '0', 'task1', 'task2', 'task3'} -> does not need to exist in all sessions
paralist.tasks_to_include = {'1', 'Exper','Cont1','Cont2','CatMeow'};
%paralist.tasks_to_include = {'0','ON','OFF'};

paralist.contrastmat = 'contrasts_9Runs_gPPI.mat';

% option 1: save all files
% option 2: save only matrices
% option 3: save nothing, either you are a developer or enjoy digging scratch tmp files, or maybe both
paralist.copy_type = '1' ;
%-------------------------------------------------------------------------%
% Please specify the confound names
%$paralist.confound_names = {};
paralist.confound_names = {'R1', 'R2', 'R3', 'R4', 'R5', 'R6'};

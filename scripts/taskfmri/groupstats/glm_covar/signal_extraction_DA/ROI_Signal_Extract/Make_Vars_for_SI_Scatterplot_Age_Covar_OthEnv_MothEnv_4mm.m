clear all; close all; clc

addpath(genpath('/oak/stanford/groups/menon/projects/daa/Abrams_Utils/FreqUsedMatlabScripts'));

warning('off');

% ===========================
% ===========================
% Config Files

sub_list = '/oak/stanford/groups/menon/projects/daa/2014_ASD_auditory_development/data/subjectlist/subjectlist_TD_n46.csv';
age_list = '/oak/stanford/groups/menon/projects/daa/2014_ASD_auditory_development/data/subjectlist/TD_Only_Age_Covar_List_n46.txt';
roi_dir = '/oak/stanford/groups/menon/projects/daa/2014_ASD_auditory_development/scripts/taskfmri/Signal_Levels/Signal_Levels_and_Scatters_spm12/Age_Covar/Other_Mother/Redo_4mm_Sphere';

roi_fname{1} = 'roi_01_Left_AI.nii';
roi_name{1} = 'Left_AI';

roi_fname{2} = 'roi_02_Left_OFC.nii';
roi_name{2} = 'Left_OFC';

roi_fname{3} = 'roi_03_Left_Precun.nii';
roi_name{3} = 'Left_Precun';

roi_fname{4} = 'roi_04_Right_AG.nii';
roi_name{4} = 'Right_AG';

roi_fname{5} = '';
roi_name{5} = '';


% ===========================
% ===========================

[pid,visit,session] = parse_csv(sub_list);

all_age = ReadList(age_list);
all_age = str2num(char(all_age));

for roi_i = 1:length(roi_fname);
    
    [roi, hdr] = cbiReadNifti(fullfile(roi_dir, roi_fname{roi_i}));
    
    roi_ind{roi_i} = find(roi > 0);
    
end

clear roi_fname roi roi_i


for sub_i = 1:length(pid)
    
    sub_i;
    
    this_pid = pid{sub_i};
    
    this_visit = visit{sub_i};
    
    this_session = session{sub_i};
    
    for roi_i = 1:length(roi_ind)
        
        roi_i;
        
        % Con 0003 is Other min Env
        con_fname = fullfile('/oak/stanford/groups/menon/projects/daa/2014_ASD_auditory_development/results/taskfmri/participants',...
            this_pid, this_visit, this_session, 'glm/stats_spm12/stats_swgcaor_spm12_ring_ICA/con_0003.nii');
        
        [con, hdr] = cbiReadNifti(con_fname);
        
        roi_con(sub_i, roi_i) = nanmean(con(roi_ind{roi_i}),1);
        
        clear sub_year con_fname
        
        
    end
    
end

save_dir = '/oak/stanford/groups/menon/projects/daa/2014_ASD_auditory_development/scripts/taskfmri/Signal_Levels/Signal_Levels_and_Scatters_spm12/Age_Covar/Other_Mother';

save_fname = 'TDonly_n46_SI_SigLevels_Age_OtherEnv_Ring_ICA_4mm.mat';

save(fullfile(save_dir, save_fname), 'roi_con', 'roi_name', 'all_age');

% =========================================================================================
% =========================================================================================


clear all; close all; clc

addpath(genpath('/oak/stanford/groups/menon/projects/daa/Abrams_Utils/FreqUsedMatlabScripts'));

warning('off');

[pid,visit,session] = parse_csv('/oak/stanford/groups/menon/projects/daa/2014_ASD_auditory_development/data/subjectlist/subjectlist_TD_n46.csv');


all_age = ReadList('/oak/stanford/groups/menon/projects/daa/2014_ASD_auditory_development/data/subjectlist/TD_Only_Age_Covar_List_n46.txt');
all_age = str2num(char(all_age));

% all_srs = load('/mnt/mabloo1/apricot1_share2/ASD_auditory_development/fMRI_Analysis/Scripts/Brain_Behavior/TD_Only_FINAL_Sample_n47/TD_Only_SRS_SocCommun_Covar_List_n46.txt');

roi_dir = '/oak/stanford/groups/menon/projects/daa/2014_ASD_auditory_development/scripts/taskfmri/Signal_Levels/Signal_Levels_and_Scatters_spm12/Age_Covar/Other_Mother/Redo_4mm_Sphere';



roi_fname{1} = 'roi_01_Left_NAc_-12_8_-8.nii';
roi_name{1} = 'Left_NAc';

roi_fname{2} = 'roi_02_Right_vmPFC_6_50_-10.nii';
roi_name{2} = 'Right_vmPFC';



for roi_i = 1:length(roi_fname);
    
    [roi, hdr] = cbiReadNifti(fullfile(roi_dir, roi_fname{roi_i}));
    
    roi_ind{roi_i} = find(roi > 0);
    
end

clear roi_fname roi roi_i


for sub_i = 1:length(pid)
    
    sub_i;
    
    this_pid = pid{sub_i};
    
    this_visit = visit{sub_i};
    
    this_session = session{sub_i};
    
    for roi_i = 1:length(roi_ind)
        
        roi_i;
        
        % Con 0003 is Other min Env
        con_fname = fullfile('/oak/stanford/groups/menon/projects/daa/2014_ASD_auditory_development/results/taskfmri/participants',...
            this_pid, this_visit, this_session, 'glm/stats_spm12/stats_swgcaor_spm12_ring_ICA/con_0001.nii');
        
        [con, hdr] = cbiReadNifti(con_fname);
        
        roi_con(sub_i, roi_i) = nanmean(con(roi_ind{roi_i}),1);
        
        clear sub_year con_fname
        
        
    end
    
end

save_dir = '/oak/stanford/groups/menon/projects/daa/2014_ASD_auditory_development/scripts/taskfmri/Signal_Levels/Signal_Levels_and_Scatters_spm12/Age_Covar/Other_Mother';

save_fname = 'TDonly_n46_SI_SigLevels_Age_MotherEnv_Ring_ICA_4mm.mat';

save(fullfile(save_dir, save_fname), 'roi_con', 'roi_name', 'all_age');




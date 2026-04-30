clear all; close all; clc

addpath(genpath('/oak/stanford/groups/menon/projects/daa/Abrams_Utils/FreqUsedMatlabScripts'));

warning('off');

% ===========================
% ===========================
% Config Files

sub_list = '/oak/stanford/groups/menon/projects/leipold/2022_ASD_CrossDevelop/data/subjectlist/ASD_selected_PID_List_n39_ADOS.csv';
roi_dir = '/oak/stanford/groups/menon/projects/leipold/2022_ASD_CrossDevelop/scripts/taskfmri/groupstats/glm_covar/signal_extraction_DA/ROI_Creation';

% Specify Contrast File  
% Con 0001 is Mother min Env
% Con 0003 is Other min Env
% Con 0009 is Mother min Other
con_fname = 'con_0009.nii';

roi_fname{1} = 'roi_01_Left_AI_4mm_-36_20_2.nii';
roi_name{1} = 'Left_AI';

roi_fname{2} = 'roi_02_Left_BA44_4mm_-56_12_12.nii';
roi_name{2} = 'Left_BA44';

roi_fname{3} = 'roi_03_Left_pSTG_4mm_-50_-40_8.nii';
roi_name{3} = 'Left_pSTG';

save_dir = '/oak/stanford/groups/menon/projects/leipold/2022_ASD_CrossDevelop/scripts/taskfmri/groupstats/glm_covar/signal_extraction_DA/ROI_Signal_Extract';
save_fname = 'ASDonly_n39_GLM_SigLev_SC_MainEffect_MothOth.mat';

% ===========================
% ===========================

[pid,visit,session] = parse_csv(sub_list);

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
       
        con_path = fullfile('/oak/stanford/groups/menon/projects/leipold/2022_ASD_CrossDevelop/results/taskfmri/participants',...
            this_pid, this_visit, this_session, 'glm/stats_spm12/stats_swgcar', con_fname);
        
        [con, hdr] = cbiReadNifti(con_path);
        
        roi_con(sub_i, roi_i) = nanmean(con(roi_ind{roi_i}),1);
        
        clear sub_year con_path
        
        
    end
    
end

save(fullfile(save_dir, save_fname), 'roi_con', 'roi_name');







clear all; close all; clc
warning('off');

rmpath(genpath('/oak/stanford/groups/menon/software/spm12'));
addpath(genpath('/oak/stanford/groups/menon/software/spm8'));


% ------------------------------------------------------------------------------------------------
output_dir = '/oak/stanford/groups/menon/projects/leipold/2022_ASD_CrossDevelop/scripts/taskfmri/groupstats/glm_covar/signal_extraction_DA/ROI_Creation';
    
% ------------------------------------------------------------------------------------------------

% Input user-specified peaks (i.e., will not use peaks in HO maps)

% Template
% Add_On_Region_Name{} = '';
% Add_On_Region_MNI_Coordinates{} = [];
% Add_On_Region_Radius{} = 5;

% This is OLD but keeping around to help with formatting
% Add_On_Region_Name{2} = 'Left_DLPFC_-42_14_46';
% Add_On_Region_MNI_Coordinates{2} = [-42 14 46];
% Add_On_Region_Radius{2} = 4;

% These are for Mother min Other, Neg Contrast, Main Effect SC, from FULL MODEL which included Age, SC, and Interactions  
% GLM
Add_On_Region_Name{1} = 'Left_AI_4mm_-36_20_2';
Add_On_Region_MNI_Coordinates{1} = [-36 20 2];
Add_On_Region_Radius{1} = 4;

Add_On_Region_Name{2} = 'Left_BA44_4mm_-56_12_12';
Add_On_Region_MNI_Coordinates{2} = [-56 12 12];
Add_On_Region_Radius{2} = 4;

Add_On_Region_Name{3} = 'Left_Post_Insula_4mm_44_-10_2';
Add_On_Region_MNI_Coordinates{3} = [44 -10 2];
Add_On_Region_Radius{3} = 4;



% This is the script for Add_on ROIs


spm('Defaults','fmri')
marsbar('on');

tf = exist('Add_On_Region_Name');

if tf == 1
    
    no_addons = length(Add_On_Region_Name);
    
    for addon_i = 1:no_addons
        
        % -------------------------------------------------------------------------
        % Here is the 'roi_make_sphere.m' script
        % -------------------------------------------------------------------------
        
        
        warning('off', 'MATLAB:FINITE:obsoleteFunction')
        
%         addpath /home/fmri/fmrihome/SPM/spm8/toolbox/marsbar
        
        %   Here is a temp roi_folder
        roi_folder = fullfile(output_dir);
        
        if exist(roi_folder,'dir')
            cd(roi_folder);
        else
            mkdir(roi_folder);
            cd(roi_folder);
        end
        
        
        coords = Add_On_Region_MNI_Coordinates{addon_i};
        radius = Add_On_Region_Radius{addon_i};
        name = Add_On_Region_Name{addon_i};
        
        temp_name = ['roi_' num2str(addon_i,'%02d') '_' name];
        
        roi = maroi_sphere(struct('centre', coords, 'radius', radius));
        roi = label(roi, temp_name);
        
        n = num2str(i);
        r = num2str(radius);
        x = num2str(coords(1));
        y = num2str(coords(2));
        z = num2str(coords(3));
        
        if length(n) == 1
            n = ['0' n];
        end
        
        %     filename = [n '-' r 'mm_' name '_' x '_' y '_' z '_roi.mat'];
        filename = [temp_name '-' r 'mm_' x '_' y '_' z '_roi.mat'];
        fpath    = fullfile(roi_folder,filename);
        save(fpath, 'roi');
        %     end
        
        %     disp('Making ROIs is done.');
        
        %     end
        
        new_img_name = [temp_name '.nii'];
        
        %     mars_rois2img(fpath, new_img_name, roi_space)
        mars_rois2img(fpath, new_img_name);
        
        % This deletes the roi.mat and the labels.mat files
        delete(fpath)
        labels_fname = [temp_name '_labels.mat'];
        delete(labels_fname);
        
        clear roi hdr
        
        
    end
    
end


% -------------------------------------------------------------------------------------
% % Test that new nii retrieves the same values as an ROI created in MarsBar
% % using SPM GUI
% 
% mars_nii = '/mnt/mabloo1/apricot1_share2/asd_auditory/DTI_Analysis/Scripts/ROIs/PNAS_ROIs/temp_dir/sphere_4--63_-42_9.nii';
% myscript_fname = '/mnt/mabloo1/apricot1_share2/asd_auditory/DTI_Analysis/Scripts/ROIs/PNAS_ROIs/temp_dir/temp_1_Left_pSTS_PNAS_4mm.nii';
% 
% [mars, hdr] = cbiReadNifti(mars_nii);
% mars_inds = find(mars == 1);
% 
% [myscript, hdr] = cbiReadNifti(myscript_fname);
% myscript_inds = find(myscript == 1);
% 
% random_img = '/mnt/mapricot/musk2/2014/14-09-27.1_3T2/fmri/stats_spm8/SingleSession_VolRep_AtLeast_7Runs_QuadCheck_CoReg_Collap_gPPI/PPI_Left_aHipp/con_0024.img';
% [data, hdr] = cbiReadNifti(random_img);
% 
% mars_data = data(mars_inds);
% myscript_data = data(myscript_inds);
% 
% tf_data = isequal(mars_data, myscript_data)
% -------------------------------------------------------------------------------------





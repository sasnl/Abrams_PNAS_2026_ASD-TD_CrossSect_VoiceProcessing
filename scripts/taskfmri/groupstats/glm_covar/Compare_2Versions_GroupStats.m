% --------------------------------------------------------
% Compare unthresholded contrast images (old vs new models)
% --------------------------------------------------------
addpath(genpath('/oak/stanford/groups/menon/software/spm12'));

% --- USER INPUTS ----------------------------------------
old_con = ['/oak/stanford/groups/menon/projects/leipold/2022_ASD_CrossDevelop/results/taskfmri/groupstats/glm/'...
    'glm_two_sample_covar_age_ASD_TD_n39_40_spm12/001T_mother_min_environ/con_0001.nii'];

new_con = ['/oak/stanford/groups/menon/projects/leipold/2022_ASD_CrossDevelop/results/taskfmri/groupstats/glm/' ...
    'glm_two_sample_covar_age_ASD_TD_n39_40_FixReg_spm12/001T_mother_min_environ/con_0003.nii'];

output_diff = ['/oak/stanford/groups/menon/projects/leipold/2022_ASD_CrossDevelop/results/taskfmri/groupstats/glm/'...
    'archive/Compare_2Versions_GroupStats/diff_old_vs_new_con_0001.nii'];

% ---------------------------------------------------------

% Load NIfTI volumes
V_old = spm_vol(old_con);
V_new = spm_vol(new_con);

Y_old = spm_read_vols(V_old);
Y_new = spm_read_vols(V_new);

% Compute voxelwise difference
Y_diff = Y_new - Y_old;

% Basic summary statistics
fprintf('\n--- Contrast Difference Summary ---\n');
fprintf('Mean difference:      %.6f\n', mean(Y_diff(:), 'omitnan'));
fprintf('Std difference:       %.6f\n', std(Y_diff(:), 'omitnan'));
fprintf('Max absolute diff:    %.6f\n', max(abs(Y_diff(:)), [], 'omitnan'));
fprintf('95th percentile abs diff: %.6f\n', prctile(abs(Y_diff(:)),95));

% Save the difference image as NIfTI for visual inspection
V_diff = V_old;         % copy header
V_diff.fname = output_diff;
spm_write_vol(V_diff, Y_diff);

fprintf('\nDifference image written to:\n%s\n\n', output_diff);
fprintf('Load it in SPM -> Display to inspect spatial patterns.\n\n');

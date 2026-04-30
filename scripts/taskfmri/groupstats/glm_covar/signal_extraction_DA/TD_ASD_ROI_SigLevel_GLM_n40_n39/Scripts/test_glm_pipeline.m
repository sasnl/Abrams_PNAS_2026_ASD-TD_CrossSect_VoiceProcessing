function test_glm_pipeline()
rng(7);
nRep = 500;   % number of simulations
nA = 39; nT = 40;
roi_defs = {...
    struct('b0',0,'bG',0,'bA',0,'bInt',0.20,'sigma',0.5,'label','ROI1_interaction'), ...
    struct('b0',0,'bG',0,'bA',0,'bInt',0.00,'sigma',0.5,'label','ROI2_null'), ...
    struct('b0',0,'bG',1.0,'bA',0,'bInt',0.00,'sigma',0.5,'label','ROI3_group_main'), ...
    struct('b0',0,'bG',0,'bA',0.60,'bInt',-0.60,'sigma',0.5,'label','ROI4_ASD_only'), ...
    struct('b0',0,'bG',0,'bA',0.00,'bInt',+0.60,'sigma',0.5,'label','ROI5_TD_only')};

roi_names = cellfun(@(x)x.label, roi_defs, 'UniformOutput', false);
nROIs = numel(roi_defs);

% tallies
detect = struct();
for r = 1:nROIs
    detect.(roi_names{r}) = 0;
end

for rep = 1:nRep
    % --- simulate data ---
    Age_ASD = 8 + 10*rand(nA,1);
    Age_TD  = 8 + 10*rand(nT,1);
    Age     = [Age_ASD; Age_TD];
    Age_c   = Age - mean(Age);
    isTD    = [zeros(nA,1); ones(nT,1)];
    Y = nan(nA+nT, nROIs);

    for r = 1:nROIs
        p = roi_defs{r};
        mu = p.b0 + p.bG*isTD + p.bA*Age_c + p.bInt.*(isTD.*Age_c);
        Y(:,r) = mu + p.sigma*randn(size(mu));
    end

    % --- write files your script expects ---
    writematrix(Age_ASD, 'asd_age.txt');
    writematrix(Age_TD,  'td_age.txt');

    roi_con = Y(1:nA,:); roi_name = roi_names;
    save('asd_data.mat', 'roi_con', 'roi_name');

    roi_con = Y(nA+1:end,:); roi_name = roi_names;
    save('td_data.mat', 'roi_con', 'roi_name');

    % --- run your actual GLM script ---
    out_dir = 'glm_out';
    if ~exist(out_dir,'dir'), mkdir(out_dir); end

    R = roi_glm_runner('asd_age.txt','asd_data.mat', ...
                       'td_age.txt','td_data.mat', out_dir);

    % --- check if expected effects are detected ---
    for r = 1:nROIs
        name = roi_names{r};
        switch name
            case 'ROI1_interaction'
                if R.int_p(r) < 0.05, detect.(name) = detect.(name) + 1; end
            case 'ROI2_null'
                if R.int_p(r) >= 0.05, detect.(name) = detect.(name) + 1; end
            case 'ROI3_group_main'
                % no interaction expected
                if R.int_p(r) >= 0.05, detect.(name) = detect.(name) + 1; end
            case 'ROI4_ASD_only'
                if R.ASD_age_p(r) < 0.05 && R.TD_age_p(r) >= 0.05, detect.(name) = detect.(name) + 1; end
            case 'ROI5_TD_only'
                if R.TD_age_p(r) < 0.05 && R.ASD_age_p(r) >= 0.05, detect.(name) = detect.(name) + 1; end
        end
    end
end

% --- show detection rates ---
fprintf('\n=== Detection Rates over %d runs ===\n', nRep);
for r = 1:nROIs
    name = roi_names{r};
    fprintf('%-20s: %.1f%%\n', name, 100*detect.(name)/nRep);
end
end

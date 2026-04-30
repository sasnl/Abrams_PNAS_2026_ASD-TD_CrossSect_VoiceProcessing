clear all; close all; clc

% ======================================
% ======================================
% Config Files
save_dir = '/Users/daa/Documents/Scratch/TD_ASD_CrossSectional/Figure_Generation/Scatterplots/MotherOther_Scatters';
ASD_save_fname = 'ASDonly_n39_SigLevels_Age_MotherOther.mat';
TD_save_fname = 'TDonly_n40_SigLevels_Age_MotherOther.mat';

td_age_fname = '/Users/daa/Documents/Scratch/TD_ASD_CrossSectional/Figure_Generation/Scatterplots/TD_selected_age_scan.txt';
asd_age_fname = '/Users/daa/Documents/Scratch/TD_ASD_CrossSectional/Figure_Generation/Scatterplots/ASD_selected_age_scan_n39_ADOS.txt';

% These should be in order relative to ROI numbers in ROI folder
color_plots(1,:) =  [128 0 128]; % This is purple for DLPFC 



% ======================================
% ======================================
% Get age files and calc age range for all TD/ASD subs
td_age_list = load(td_age_fname);
asd_age_list = load(asd_age_fname);
all_age = [td_age_list; asd_age_list];

% load Signal Level Files
load(fullfile(save_dir, ASD_save_fname), 'roi_con', 'roi_name');
asd_roi_con = roi_con;
clear roi_con

load(fullfile(save_dir, TD_save_fname), 'roi_con', 'roi_name');
td_roi_con = roi_con;
clear roi_con


% This converts from Powerpoint RGB to Matlab RGB units
color_plots = color_plots./255;

% ylims_scatters(1,:) = [-1.5 2];
% ylims_scatters(2,:) = [-2.5 2.5];
% ylims_scatters(3,:) = [-3.5 1.5];
% ylims_scatters(4,:) = [-3 3];
% ylims_scatters(5,:) = [-1.5 1.5];
% ylims_scatters(6,:) = [-3.5 1];
% ylims_scatters(7,:) = [-2.5 1.5];

for roi_i = 1:size(td_roi_con,2)
    
    min_beta = min([td_roi_con(:,roi_i); asd_roi_con(:,roi_i)]);
    max_beta = max([td_roi_con(:,roi_i); asd_roi_con(:,roi_i)]);
    
%     min_age = min(all_age);
%     max_age = max(all_age);


%     min_plotx = [-1 -1.2 -2.2 -2.2 -1.3];
%     max_plotx = min_plotx .* -1;
    
    figure
    % This plots TDs
   
    plot(td_age_list, td_roi_con(:,roi_i), 'o','color',color_plots(roi_i,:), 'LineWidth', 1.5);
    hold on;
    plot(asd_age_list, asd_roi_con(:,roi_i), 'x','color',color_plots(roi_i,:), 'LineWidth', 2);

    %-------------------------------
    % Fit a line to the TD scatterplots and plot
    myfit = polyfit(td_age_list, td_roi_con(:,roi_i), 1);
    x = min(td_age_list):0.01:max(td_age_list);
    
    y=myfit(1)*x+myfit(2)';
    plot(x,y, 'k','linewidth',2.5);

    % Fit a line to the ASD scatterplots and plot
    myfit = polyfit(asd_age_list, asd_roi_con(:,roi_i), 1);
    x = min(asd_age_list):0.01:max(asd_age_list);
    
    y=myfit(1)*x+myfit(2)';
    plot(x,y, 'Color', [0.5 0.5 0.5],'linewidth',3);
 
        
%     xlim([min_beta max_beta]);
    xlim([7 17]);
%     ylim(ylims_scatters(roi_i,:));
    box off
    set(gca, 'fontsize', 12);
%     set(gca, 'YTick', [-2 -1 0 1 2]);
%     set(gca, 'XTick', [-2 -1 0 1 2]);
    set(gca, 'XColor', 'k');
    set(gca, 'YColor', 'k');
    
    set(gcf, 'Position', [150 150 120 120]);
    set(gcf,'color','w');
%     set(gca,'Ydir','reverse')
    set(gca,'Color','w');
    
    
    

    save_fname = [roi_name{roi_i} '.emf'];
    save_path = fullfile(save_dir, save_fname);
    fig = gcf;
    fig.PaperPositionMode = 'auto';
    resolution = 600; % Set the desired resolution (DPI)

    % Use the print function to save the figure
    print(save_path, '-dpng', ['-r', num2str(resolution)]);

    % Calc Pearsons correlations for TDs
    [r_temp, p_temp] = corrcoef(td_roi_con(:,roi_i), td_age_list);
    r_td(roi_i) = r_temp(1,2);
    p_td(roi_i) = p_temp(1,2);
    
    % Calc Pearsons correlations for ASDs
    [r_temp, p_temp] = corrcoef(asd_roi_con(:,roi_i), asd_age_list);
    r_asd(roi_i) = r_temp(1,2);
    p_asd(roi_i) = p_temp(1,2);

    % Compute Cohens f
    % Combine data
    all_age = [td_age_list(:); asd_age_list(:)];
    all_signal = [td_roi_con(:, roi_i); asd_roi_con(:, roi_i)];
    group = [zeros(size(td_age_list(:))); ones(size(asd_age_list(:)))]; % 0 = TD, 1 = ASD

    % Create interaction term
    interaction = all_age .* group;

    % Full model: includes interaction (tests slope difference)
    X_full = [ones(size(all_age)), all_age, group, interaction];
    b_full = X_full \ all_signal;
    yhat_full = X_full * b_full;
    SSres_full = sum((all_signal - yhat_full).^2);
    SStotal = sum((all_signal - mean(all_signal)).^2);
    R2_full = 1 - SSres_full / SStotal;

    % Reduced model: no interaction (assumes same slope)
    X_reduced = [ones(size(all_age)), all_age, group];
    b_reduced = X_reduced \ all_signal;
    yhat_reduced = X_reduced * b_reduced;
    SSres_reduced = sum((all_signal - yhat_reduced).^2);
    R2_reduced = 1 - SSres_reduced / SStotal;

    f_squared = (R2_full - R2_reduced) / (1 - R2_full);
    cohen_f = sqrt(f_squared);

    %
    % % Display the result
    fprintf('ROI: %s — Cohen''s f for group × age interaction = %.3f\n', roi_name{roi_i}, cohen_f);

    
end

roi_name

p_td
r_td
p_asd
r_asd


% 
% r_td
% p_td
% 
% r_asd
% p_asd



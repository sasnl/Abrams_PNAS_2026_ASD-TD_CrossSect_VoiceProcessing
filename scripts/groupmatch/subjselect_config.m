% This is the configuration template file for movementstatsfmri 
% _________________________________________________________________________
% 2009-2018 Stanford Cognitive and Systems Neuroscience Laboratory
%
% $Id: subjselect_config.m, Kaustubh Supekar, 2018-03-16 $
% -------------------------------------------------------------------------

%-SPM version. 
%-Please use spm8_R3028 if compatibility with old servers is desired
paralist.spmversion = 'spm8';

%-Please specify parallel or nonparallel
paralist.parallel = '0';

%-Please specify the projectdir
paralist.projectdir = '/oak/stanford/groups/menon/projects/leipold/2022_ASD_CrossDevelop/scripts/groupmatch/'

% Please specify the path for comma separated subject list file. The output
% subjects will be selected from this list. Note: if the file contains
% gender then encode Male as 1 and Female as 0
paralist.subjectlist = '/oak/stanford/groups/menon/projects/leipold/2022_ASD_CrossDevelop/scripts/groupmatch/all_subjectslist_SL.csv';

% Please specify the path for the output comma separated subject list file.
% The output subjects will be saveed in this file.
paralist.selectedsubjectlist = '/oak/stanford/groups/menon/projects/leipold/2022_ASD_CrossDevelop/scripts/groupmatch/selected_subjectslist_SL.csv';

% Please specify the desired number of subjects that are to be selected
paralist.numberofselectedsubjects = 40;

% Please specify the variable names. Enter as they appear in the subject list. 
% For e.g. if the subjects list contains four columns: PID, Age, IQ, Gender in that order then enter variablenames as {'PID','Age', 'IQ', 'Gender'}
paralist.var_names = {'PID', 'Age', 'FIQ', 'VIQ', 'PIQ', 'Sex','TotMot'};

% Please specify the variable type. 1 for continous; 2 for discrete
paralist.var_type = [1 1 1 1 1 2 1];

% Please specify the desired mean for variables. For variables that are to be ignored enter 0. 
% For e.g. if the desired mean of the selected sample is Age: 10.2, IQ: 110; Gender: 12males/9females then enter as [0 10.2 110 12/9]
paralist.var_mean = [0 0 0 111.85 0 34/6 2.05];

% Please specify the desired standard deviation for variables. For variables that are to be ignored enter 0. 
% For e.g. if the desired standard deviation of the selected sample is Age: 1.2, IQ: 5 then enter as [0 1.2 5 0]
paralist.var_std = [0 0 0 16.11 0 0 1.11];

% Please specify the priority level for variables. This priority will be used while matching. Variable w. high priority will be matched better. 
% For e.g. if the gender distribution is very important criteria then enter as [0 1 1 5]. In this case age and IQ are at same priority level of 1, and gender is 5. PID is ignored
paralist.var_priority = [0 0 0 1 0 1 1];


% =========================================================================

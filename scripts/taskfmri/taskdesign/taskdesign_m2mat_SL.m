% This script use task_design.m file to create task_design.mat 
% and move task_design.mat to
% PROJECT/data/imaging/partiipants/SUBID/visit*/session*/fmri/RUNNAME/task_design/
% 
% _________________________________________________________________________
% 
% Yuan Zhang, 2018-02-13
% ________________________________________________________________________

function taskdesign_m2mat(SubjectI, ConfigFile)

% Utility functions are saved under preprocessing path 
spmpreprocscript_path   = '/oak/stanford/groups/menon/scsnlscripts/brainImaging/mri/fmri/preprocessing/spm8/';
sprintf('adding SPM based preprocessing scripts path: %s\n', spmpreprocscript_path);
addpath(genpath(spmpreprocscript_path));

warning('off', 'MATLAB:FINITE:obsoleteFunction')
c     = fix(clock);
disp('==================================================================');
fprintf('task_deisng convert start at %d/%02d/%02d %02d:%02d:%02d \n',c);
disp('==================================================================');
% fname = sprintf('taskdesign-%d_%02d_%02d-%02d_%02d_%02.0f.log',c);
% diary(fname);
disp(['Current directory is: ',pwd]);
fprintf('Script: %s\n', which('taskdesign_m2mat.m'));
fprintf('Configfile: %s\n', ConfigFile);
fprintf('\n')
disp('------------------------------------------------------------------');

currentdir = pwd;

% -------------------------------------------------------------------------
% Check existence of the configuration file
% -------------------------------------------------------------------------
ConfigFile = strtrim(ConfigFile);
if ~exist(ConfigFile, 'file')
    error('cannot find the configuration file')
end
[ConfigFilePath, ConfigFile, ConfigFileExt] = fileparts(ConfigFile);
eval(ConfigFile);
clear ConfigFile;

% -------------------------------------------------------------------------
% Read parameters
% -------------------------------------------------------------------------
% Ignore white space if there is any
subject_i          = SubjectI;
subjectlist        = strtrim(paralist.subjectlist);
runlist            = strtrim(paralist.runlist);
raw_dir            = strtrim(paralist.rawdir);
project_dir        = strtrim(paralist.projectdir);
task_dsgn           = strtrim(paralist.task_dsgn);
task_dsgn_mat       = strtrim(paralist.task_dsgn_mat);

disp('-------------- Contents of the Parameter List --------------------');
disp(paralist);
disp('------------------------------------------------------------------');
clear paralist;

% -------------------------------------------------------------------------
% Read in subjects and sessions
% Get the subjects, sesses in cell array format
subjectlist       = csvread(subjectlist,1);
subject           = subjectlist(subject_i);
subject           = char(pad(string(subject),4,'left','0'));
visit             = num2str(subjectlist(subject_i,2));
session           = num2str(subjectlist(subject_i,3));

numsub           = 1;
%runs              = ReadList(runlist);
runs              = load(runlist, 'FullSample_Run_List');
runs              = runs.FullSample_Run_List{subject_i}';
numrun            = length(runs);

% -------------------------------------------------------------------------
% Start task_design m2mat
% -------------------------------------------------------------------------
for subcnt = 1:numsub
  fprintf('Processing Subject: %s \n',subject);
  disp('--------------------------------------------------------------');
  
  for irun = 1:numrun
    taskdsgn_mdir = fullfile(raw_dir, subject, ['visit',visit],['session',session],'fmri', runs{irun}, 'task_design');

    if( exist(taskdsgn_mdir, 'dir') == 0)  
        continue;  
    end

    addpath(taskdsgn_mdir);
    str = which(task_dsgn); % check if there is task design m file
    if isempty(str)
       disp('Cannot find task design m file in task_design folder.');
       continue
    %    diary off; 
   %    return;
    end
    
    % If there is a ".m" at the end remove it.
    if(~isempty(regexp(task_dsgn, '\.m$', 'once' )))
      task_dsgn = task_dsgn(1:end-2);
    end
    
    fprintf('Changing to directory: %s \n', taskdsgn_mdir);
    cd (taskdsgn_mdir);
    fprintf('Running the task design file: %s \n',str);
    fprintf(task_dsgn)
    eval(task_dsgn); 
    
    output_dir = fullfile(project_dir, 'data/imaging/participants', ...
                          subject, ['visit',visit],['session',session],'fmri', runs{irun}, 'task_design');
                      
    if( exist(output_dir, 'dir') == 0)
        mkdir(output_dir);
    end
    unix(sprintf('mv task_design.mat %s', fullfile(output_dir, task_dsgn_mat)));
        
    rmpath(taskdsgn_mdir);
    fprintf('Changing back to the directory: %s \n', currentdir);
    cd(currentdir);
  end
  
 
c     = fix(clock);
disp('==================================================================');
fprintf('task_deisng convert finished at %d/%02d/%02d %02d:%02d:%02d \n',c);
disp('==================================================================');
% diary off;
delete(get(0,'Children'));
clear all;
close all;

end


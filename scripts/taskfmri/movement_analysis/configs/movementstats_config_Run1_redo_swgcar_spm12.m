% This is the configuration template file for movementstatsfmri
% _________________________________________________________________________
% 2009-2012 Stanford Cognitive and Systems Neuroscience Laboratory
%
% $Id: movementstatfmri_config.m.template, Kaustubh Supekar, 2018-03-16 $
% -------------------------------------------------------------------------

%-Please specify parallel or nonparallel
paralist.parallel = '0';

%-Subject list
paralist.subjectlist = 'subj_list.txt';
%-Run list
paralist.runlist = 'Run1_redo';

% I/O parameters
% - Raw data directory
paralist.rawdatadir = '/oak/stanford/groups/menon/rawdata/scsnl/';

% - Project directory
paralist.projectdir = '/oak/stanford/groups/menon/projects/leipold/2022_ASD_CrossDevelop/';

% Please specify the foler for preprocessed data via standard pipeline
paralist.preprocessed_folder    = 'swgcar_spm12';

%-Scan-to-scan threshold (unit in voxel)
paralist.scantoscancrit = 0.3;

%-SPM version
paralist.spmversion = 'spm12';

paralist.voxdim='3.4375';

modality="stats_swgcar"

indir="/oak/stanford/groups/menon/projects/leipold/2022_ASD_CrossDevelop/results/taskfmri/participants/"
roidir="/oak/stanford/groups/menon/projects/leipold/2022_ASD_CrossDevelop/data/imaging/roi/glm_jneuro22/"
outdir="/oak/stanford/groups/menon/projects/leipold/2022_ASD_CrossDevelop/results/taskfmri/groupstats/glm_jneuro22/"
## declare an array variable
roilist=(NAcc
vmPFC)

## declare an array variable
filelist=(0336/visit5/session1/glm/stats_spm12/
0457/visit4/session1/glm/stats_spm12/
4017/visit4/session1/glm/stats_spm12/
4023/visit3/session1/glm/stats_spm12/
4058/visit2/session1/glm/stats_spm12/
4062/visit3/session1/glm/stats_spm12/
4074/visit2/session1/glm/stats_spm12/
4076/visit2/session1/glm/stats_spm12/
4079/visit3/session1/glm/stats_spm12/
7014/visit4/session1/glm/stats_spm12/
7081/visit4/session1/glm/stats_spm12/
7112/visit2/session1/glm/stats_spm12/
7176/visit2/session1/glm/stats_spm12/
7178/visit3/session1/glm/stats_spm12/
7185/visit5/session1/glm/stats_spm12/
7211/visit4/session1/glm/stats_spm12/
7253/visit2/session1/glm/stats_spm12/
7266/visit2/session1/glm/stats_spm12/
7281/visit4/session1/glm/stats_spm12/
7307/visit3/session1/glm/stats_spm12/
7309/visit2/session1/glm/stats_spm12/
7330/visit1/session1/glm/stats_spm12/
7331/visit2/session1/glm/stats_spm12/
7341/visit1/session1/glm/stats_spm12/
7357/visit1/session1/glm/stats_spm12/
7371/visit2/session1/glm/stats_spm12/
7372/visit3/session1/glm/stats_spm12/
7384/visit1/session1/glm/stats_spm12/
7395/visit1/session1/glm/stats_spm12/
7413/visit1/session1/glm/stats_spm12/
7429/visit1/session1/glm/stats_spm12/
7437/visit2/session1/glm/stats_spm12/
7438/visit2/session1/glm/stats_spm12/
7442/visit1/session1/glm/stats_spm12/
7446/visit1/session1/glm/stats_spm12/
7464/visit1/session1/glm/stats_spm12/
7466/visit1/session1/glm/stats_spm12/
7477/visit1/session1/glm/stats_spm12/
7489/visit3/session1/glm/stats_spm12/
7491/visit1/session1/glm/stats_spm12/
7498/visit2/session1/glm/stats_spm12/
7507/visit1/session1/glm/stats_spm12/
7521/visit1/session1/glm/stats_spm12/
7526/visit1/session1/glm/stats_spm12/
7527/visit1/session1/glm/stats_spm12/
7540/visit1/session1/glm/stats_spm12/
7543/visit1/session1/glm/stats_spm12/
7544/visit1/session1/glm/stats_spm12/
7552/visit1/session1/glm/stats_spm12/
7571/visit1/session1/glm/stats_spm12/
7582/visit1/session1/glm/stats_spm12/
7589/visit1/session1/glm/stats_spm12/
7598/visit1/session1/glm/stats_spm12/
7620/visit1/session1/glm/stats_spm12/
7621/visit1/session1/glm/stats_spm12/
7623/visit1/session1/glm/stats_spm12/
7634/visit1/session1/glm/stats_spm12/
7652/visit1/session1/glm/stats_spm12/
7654/visit1/session1/glm/stats_spm12/
7657/visit1/session1/glm/stats_spm12/
7666/visit1/session1/glm/stats_spm12/
7669/visit1/session1/glm/stats_spm12/
7676/visit1/session1/glm/stats_spm12/
7679/visit1/session1/glm/stats_spm12/
7680/visit1/session1/glm/stats_spm12/
7685/visit1/session1/glm/stats_spm12/
7686/visit1/session1/glm/stats_spm12/
7689/visit1/session1/glm/stats_spm12/
7691/visit1/session1/glm/stats_spm12/
7693/visit1/session1/glm/stats_spm12/
7695/visit1/session1/glm/stats_spm12/
7696/visit1/session1/glm/stats_spm12/
7702/visit1/session1/glm/stats_spm12/
7707/visit1/session1/glm/stats_spm12/
7710/visit1/session1/glm/stats_spm12/
7730/visit1/session1/glm/stats_spm12/
7750/visit1/session1/glm/stats_spm12/
7758/visit1/session1/glm/stats_spm12/
7759/visit1/session1/glm/stats_spm12/
7761/visit1/session1/glm/stats_spm12/
)
## now loop through the above array
for i in "${filelist[@]}"
do
  for roi in "${roilist[@]}"
  do
    mkdir -p $outdir/$roi
    # extract T-stats from individual subjects stats folder
    fslstats $indir/$i/$modality/spmT_0001.nii -k $roidir/$roi -M >> $outdir/$roi/mother_min_environ.txt
    fslstats $indir/$i/$modality/spmT_0003.nii -k $roidir/$roi -M >> $outdir/$roi/other_min_environ.txt
    fslstats $indir/$i/$modality/spmT_0009.nii -k $roidir/$roi -M >> $outdir/$roi/mother_min_other.txt
    echo $indir/$i/$modality
    echo $roidir/$roi
  done
done

#!/bin/bash
#PBS -A bmc_1mgenome
#PBS -l walltime=95:00:00
#PBS -l ddisk=25000
#PBS -q batch
#PBS -l nodes=1:ppn=1
#PBS -l pmem=4g
#PBS -l feature=epyc
#PBS -j oe 
#PBS -t 1-3

batch=wgs_paraugi_28022024_batch100_11

module load singularity/3.11.4
source activate sarek
hostname
hn=$(hostname)
initial_date=$(date +%s)

config=/mnt/beegfs2/beegfs_large/raimondsre_add2/genome_analysis/g1m_analysis/sarek_array.config
resultsDir=/mnt/beegfs2/beegfs_large/raimondsre_add2/genome_analysis/g1m_analysis/results_${batch}/results_${batch}_${PBS_ARRAYID}
mkdir -p ${resultsDir}
csv=/mnt/beegfs2/beegfs_large/raimondsre_add2/genome_analysis/g1m_analysis/results_${batch}/${batch}_${PBS_ARRAYID}.csv 

mkdir -p /scratch/raimondsre
new_dir=$(mktemp -d /scratch/raimondsre/temp.XXXXXX)
cd ${new_dir}
bash /mnt/beegfs2/beegfs_large/raimondsre_add2/genome_analysis/g1m_analysis/scratch_storage_monitor.sh &

nextflow run nf-core/sarek -r 3.3.2 \
            --input ${csv} \
            -profile singularity --genome GATK.GRCh38 -with-report \
            --three_prime_clip_r1 2 --three_prime_clip_r2 2 --clip_r1 2 --clip_r2 2 \
            -c ${config} --joint_germline \
            --intervals /home_beegfs/groups/bmc/genome_analysis_tmp/hs/ref/wgs_calling_regions_noseconds.hg38.chrM.bed \
            --tools 'haplotypecaller,deepvariant,freebayes,strelka,tiddit,manta,cnvkit' \
            --save_output_as_bam \
            --outdir ${resultsDir} \
            --igenomes_base /beegfs_scratch/raimondsre \
            --igenomes_ignore=false \
            -w ${new_dir} 


outcome=$(nextflow log | awk 'BEGIN{FS="\t"} {print $4}' | tail -n1)
end_date=$(date +%s)
DIFF=$(($((${end_date}-${initial_date}))/3600))
if [ $outcome == "OK" ]; then
       echo "Finished successfully"
        echo ${hn} ${DIFF} ${new_dir} ${batch}_${PBS_ARRAYID} >> /mnt/beegfs2/beegfs_large/raimondsre_add2/genome_analysis/g1m_analysis/results_${batch}/sarek_scratch_directories_to_delete
else
       echo "Finished unsuccessfully"
       python /mnt/beegfs2/beegfs_large/raimondsre_add2/genome_analysis/g1m_analysis/sarek_email.py
       echo ${hn} ${DIFF} ${new_dir} ${batch}_${PBS_ARRAYID} >> /mnt/beegfs2/beegfs_large/raimondsre_add2/genome_analysis/g1m_analysis/results_${batch}/error.sarek_scratch_directories_to_delete
       if [ $DIFF -lt 10 ]; then
              sleep 15h
       fi
fi

cp scratch_storage ${resultsDir}
cp .nextflow.log ${resultsDir}
rm -rf ${new_dir}
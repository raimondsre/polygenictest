process VCF_PGS_post_processing {
    tag "PGS_post_processing"
    label 'process_medium'

    input:
    tuple val(meta), val(trait), file(plink_sscore), val(sex), val(iid)

    output:
    path("pgs_output.csv"), emit: sscore_percentiles
    //tuple val(meta), val(trait), path(genome_file), val(sex), emit: main_variables
    path  "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when 

    script: 
    def prefix = task.ext.prefix ?: "PLINK_sscore"
    def memory_in_mb = MemoryUnit.of("${task.memory}").toUnit('MB')
    // Process memory value allowed range (100 - 10000)
    def mem = memory_in_mb > 10000 ? 10000 : (memory_in_mb < 100 ? 100 : memory_in_mb)
    """  
    module load R/R-4.3.2
    
    less ${projectDir}/assets/PGS001296-run_pgs.txt.gz > homogenised_file
    cp ${plink_sscore} plink_score_file
    cat plink_score_file 
    echo -e "#!/usr/bin/env Rscript" > to_execute.R; 
    echo -e "library(dplyr); library(data.table); sscore <- fread('plink_score_file') %>% mutate(sampleset = 'new_file') %>% select(sampleset,IID='#IID',SUM=PGS001296_hmPOS_GRCh38_SUM); fread('homogenised_file') %>% select(sampleset,IID,SUM) %>% rbind(sscore) %>% mutate(percentile_sum = ntile(SUM, 100)) %>% filter(sampleset != 'reference') %>% mutate(percentile_sum_local = ntile(SUM,100)) %>% filter(sampleset == 'new_file') %>% fwrite('percentile_calculated.txt',sep='\\t')" >> to_execute.R
    Rscript to_execute.R
    cat percentile_calculated.txt
    pgs_score=\$(awk 'BEGIN{FS="\\t"} {print \$5}' percentile_calculated.txt | tail -n1)

    python --version
    echo -e "sample,trait,percentile" > pgs_output.csv
    echo -e "${meta},${trait}_test,\${pgs_score}" >> pgs_output.csv
    echo -e "${meta},${trait},\$((\${pgs_score}+1))" >> pgs_output.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        plink2: \$(plink2 --version 2>&1 | sed 's/^PLINK v//; s/ 64.*\$//' )
    END_VERSIONS
    """
}
process VCF_PGS_post_processing {
    tag "PGS_post_processing"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"

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
    module load R
    cp ${plink_sscore} > ${plink_sscore}
    echo "plink_score=${plink_sscore}\\niid=${iid}" >> .Renviron
    Rscript -e "library(dplyr); library(data.table); fread(Sys.getenv('plink_score')) %>% mutate(percentile_sum = ntile(SUM, 100)) %>% filter(sampleset != 'reference') %>% mutate(percentile_sum_local = ntile(percentile_sum,100)) %>% filter(IID == Sys.getenv('iid')) %>% fwrite('percentile_calculated.txt',sep=='\\t')"
    
    pgs_score=\$(awk 'BEGIN{FS="\\t"} {print \$10}' percentile_calculated.txt | tail -n1)

    echo -e "sample,trait,percentile" > pgs_output.csv
    echo -e "${meta},${trait},\${pgs_score}" >> pgs_output.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        plink2: \$(plink2 --version 2>&1 | sed 's/^PLINK v//; s/ 64.*\$//' )
    END_VERSIONS
    """
}
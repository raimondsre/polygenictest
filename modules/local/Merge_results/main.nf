process Merge_results {
    tag "Merge_results"
    label 'process_medium'

    input:
    path(pgs_output_single_csv)

    output:
    path("pgs_output.csv"), emit: sscore_percentiles
    //tuple val(meta), val(trait), path(genome_file), val(sex), emit: main_variables
    path  "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when 

    script: 
    def prefix = task.ext.prefix ?: "Merge_results"
    def memory_in_mb = MemoryUnit.of("${task.memory}").toUnit('MB')
    // Process memory value allowed range (100 - 10000)
    def mem = memory_in_mb > 10000 ? 10000 : (memory_in_mb < 100 ? 100 : memory_in_mb)
    """  
    
    echo -e "sample,trait,percentile" > pgs_output.csv
    cat ${pgs_output_single_csv.join(' ')} >> pgs_output.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        plink2: \$(plink2 --version 2>&1 | sed 's/^PLINK v//; s/ 64.*\$//' )
    END_VERSIONS
    """
}
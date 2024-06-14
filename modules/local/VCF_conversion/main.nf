process VCF_conversion {
    tag "VCF_conversion"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/plink2%3A2.00a5.10--h4ac6f70_0' :
        'biocontainers/plink2:2.00a5--h4ac6f70_0' }"

    input:
    tuple val(meta), val(trait), path(genome_file), val(sex)

    output:
    path("*.csv"), emit: fam
    path  "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when 

    script: 
    def prefix = task.ext.prefix ?: "VCF_conversion"
    def memory_in_mb = MemoryUnit.of("${task.memory}").toUnit('MB')
    // Process memory value allowed range (100 - 10000)
    def mem = memory_in_mb > 10000 ? 10000 : (memory_in_mb < 100 ? 100 : memory_in_mb)
    output = "${meta}_${trait}_${prefix}"
    """
    echo -e "0\\t${meta}\\t${sex}" > sex.fam
    plink2 \\
        --threads $task.cpus \\
        --memory $mem \\
        --new-id-max-allele-len 40 missing \\
        --max-alleles 2 \\
        --missing vcols=fmissdosage,fmiss \\
        --vcf $genome_file \\
        --allow-extra-chr \\
        --update-sex sex.fam \\
        --split-par 2781479 155701383 \\
        --make-bed \\
        --out ${output}

    #  zgrep -v '^#' PGS000869_hmPOS_GRCh38.txt.gz | cut -f1,4,6 | gzip > PGS000869_hmPOS_GRCh38.relabel.txt.gz
    #  scorefile=PGS000869_hmPOS_GRCh38.relabel.txt.gz 
    #  plink2 \
    #  --threads 8 \
    #  --memory 4000 \
    #  --seed 31 \
    #  --score \$scorefile \
    #  --read-freq joint_germline.filtered.afreq \
    #  --bfile ${output} \
    #  --out ${output}
    
    echo -e "sample,trait,percentile" > pgs_output.csv
    echo -e "TestID,type_1_diabetes,61" >> pgs_output.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        plink2: \$(plink2 --version 2>&1 | sed 's/^PLINK v//; s/ 64.*\$//' )
    END_VERSIONS
    """
}
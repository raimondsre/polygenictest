process Homogenisation {
    tag "homogenisation"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/plink2%3A2.00a5.10--h4ac6f70_0' :
        'biocontainers/plink2:2.00a5--h4ac6f70_0' }"

    input:
    tuple val(meta), val(trait), path(genome_file), val(sex), val(iid)

    output:
    //path("*.csv"), emit: fam
    tuple val(meta), val(trait), file("${output}.vcf"), val(sex), val(iid), emit: main_variables
    path  "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when 

    script: 
    def prefix = task.ext.prefix ?: "homogenisation"
    def memory_in_mb = MemoryUnit.of("${task.memory}").toUnit('MB')
    // Process memory value allowed range (100 - 10000)
    def mem = memory_in_mb > 10000 ? 10000 : (memory_in_mb < 100 ? 100 : memory_in_mb)
    output = "${trait}_${prefix}"
    """
    echo -e "0\\t${iid}\\t${sex}" > sex.fam
    plink2 \\
        --threads 2 \\
        --memory 16384 \\
        --missing vcols=fmissdosage,fmiss \\
        --new-id-max-allele-len 100 missing --allow-extra-chr \\
        --set-all-var-ids '@:#:\$r:\$a' \\
        --max-alleles 2 \\
        --var-id-multi @:# \\
        --update-sex sex.fam \\
        --split-par 2781479 155701383 \\
        --vcf ${genome_file} \\
        --recode vcf \\
        --out ${output}
        
    # echo -e "sample,trait,percentile" > pgs_output.csv
    # echo -e "${meta},${trait},61" >> pgs_output.csv


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        plink2: \$(plink2 --version 2>&1 | sed 's/^PLINK v//; s/ 64.*\$//' )
    END_VERSIONS
    """
}

/*
plink2 \
        --threads 2 \
        --memory 16384 \
        --missing vcols=fmissdosage,fmiss \
        --new-id-max-allele-len 100 missing --allow-extra-chr \
        --set-all-var-ids '@:#:$r:$a' \
        --max-alleles 2 \
        --var-id-multi @:# \
        --vcf ${genome_file} \
        --recode vcf \
        --out ${output}
*/
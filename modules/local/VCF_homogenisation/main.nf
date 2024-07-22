process VCF_homogenisation {
    tag "VCF_homogenisation"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/plink2%3A2.00a5.10--h4ac6f70_0' :
        'biocontainers/plink2:2.00a5--h4ac6f70_0' }"

    input:
    tuple val(meta), val(trait), path(genome_file), val(sex)

    output:
    //path("*.csv"), emit: fam
    tuple val(meta), val(trait), path(${output}".vcf"), val(sex), emit: main_variables
    path  "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when 

    script: 
    def prefix = task.ext.prefix ?: "VCF_conversion"
    def memory_in_mb = MemoryUnit.of("${task.memory}").toUnit('MB')
    // Process memory value allowed range (100 - 10000)
    def mem = memory_in_mb > 10000 ? 10000 : (memory_in_mb < 100 ? 100 : memory_in_mb)
    output = "${meta}_${trait}_${prefix}"
    """
    plink2 \
        --threads 2 \
        --memory 16384 \
        --missing vcols=fmissdosage,fmiss \
        --new-id-max-allele-len 100 missing --allow-extra-chr \
        --set-all-var-ids '@:#:$r:$a' \
        --max-alleles 2 \
        --var-id-multi @:# \
        --vcf ${input_plink} \
        --recode vcf \
        --out ${output}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        plink2: \$(plink2 --version 2>&1 | sed 's/^PLINK v//; s/ 64.*\$//' )
    END_VERSIONS
    """
}
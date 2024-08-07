process PLINK_sscore {
    tag "PLINK_sscore"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/plink2%3A2.00a5.10--h4ac6f70_0' :
        'biocontainers/plink2:2.00a5--h4ac6f70_0' }"

    input:
    tuple val(meta), val(trait), path(genome_file), val(sex), val(iid)

    output:
    tuple val(meta), val(trait), file("${output}.sscore"), val(sex), val(iid), emit: main_variables
    //tuple val(meta), val(trait), path(genome_file), val(sex), emit: main_variables
    path  "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when 

    script: 
    def prefix = task.ext.prefix ?: "PLINK_sscore"
    def memory_in_mb = MemoryUnit.of("${task.memory}").toUnit('MB')
    // Process memory value allowed range (100 - 10000)
    def mem = memory_in_mb > 10000 ? 10000 : (memory_in_mb < 100 ? 100 : memory_in_mb)
    output = "${iid}_${trait}_${prefix}"
    """
    echo -e "0\\t${iid}\\t${sex}" > sex.fam
    plink2 \\
      --threads 2 \\
      --memory 16384 \\
      --seed 31 \\
      --read-freq ${projectDir}/assets/PGS001296-run.afreq_ALL_relabelled.extract.gz \\
      --allow-extra-chr \\
      --update-sex sex.fam \\
      --split-par 2781479 155701383 \\
      --score ${projectDir}/assets/PGS001296-run_ALL_additive_0.scorefile.gz header-read cols=+scoresums,+denom,-fid list-variants \\
      --vcf ${genome_file} \\
      --out ${output}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        plink2: \$(plink2 --version 2>&1 | sed 's/^PLINK v//; s/ 64.*\$//' )
    END_VERSIONS
    """
}
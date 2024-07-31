workflow.onError {
    println "Error: Pipeline execution stopped with the following message: ${workflow.errorMessage}"

    // def email_on_error = "python ${projectDir}/bin/sarek_email.py".execute() 
    // def b = new StringBuffer()
    // email_on_error.consumeProcessErrorStream(b)
    // println email_on_error.text
    // println b.toString()

    
    def email_on_error = "python ${projectDir}/bin/sarek_email.py".execute() 
    email_on_error.waitFor()
    println email_on_error.text

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { FASTQC                  } from '../modules/nf-core/fastqc/main'
include { VCF_validation          } from '../modules/local/VCF_validation/main'
include { VCF_homogenisation      } from '../modules/local/VCF_homogenisation/main'
include { VCF_PLINK_sscore        } from '../modules/local/VCF_PLINK_sscore/main'
include { VCF_PGS_post_processing } from '../modules/local/VCF_PGS_post_processing/main'
include { Merge_results } from '../modules/local/Merge_results/main'

//include { MULTIQC               } from '../modules/nf-core/multiqc/main'
include { paramsSummaryMap        } from 'plugin/nf-validation'
include { paramsSummaryMultiqc    } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML  } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText  } from '../subworkflows/local/utils_nfcore_polygenictest_pipeline'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow POLYGENICTEST {

    take:
    ch_samplesheet // channel: samplesheet read in from --input
    // ch_scorefile

    main:

    ch_versions = Channel.empty()
    sscore_multiple = Channel.empty()

    //
    // MODULE: Run VCF_validation
    //
    VCF_validation (
        ch_samplesheet
        // ch_scorefile
    )
    ch_versions = ch_versions.mix(VCF_validation.out.versions.first())
    main_variables_for_VCF_homogenisation = VCF_validation.out.main_variables
    
    VCF_homogenisation (
        main_variables_for_VCF_homogenisation
    )
    main_variables_for_PLINK_sscore_generation = VCF_homogenisation.out.main_variables

    VCF_PLINK_sscore (
        main_variables_for_PLINK_sscore_generation
    )
    PLINK_sscore_file = VCF_PLINK_sscore.out.main_variables

    VCF_PGS_post_processing (
        PLINK_sscore_file
    )
    sscore_all = sscore_multiple.mix(VCF_PGS_post_processing.out.sscore_single)
    
    Merge_results (
        sscore_all
    )

    emit:
    VCF_PLINK_sscore_report = Merge_results.out.sscore_percentiles.toList() // channel: /path/to/multiqc_report.html
    
    // VCF_conversion (

    // )
    //
    // Collate and save software versions
    //
    softwareVersionsToYAML(ch_versions)
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name: 'nf_core_pipeline_software_mqc_versions.yml',
            sort: true,
            newLine: true
        ).set { ch_collated_versions }

    //   
    // MODULE: MultiQC
    //
    // ch_multiqc_config        = Channel.fromPath(
    //     "$projectDir/assets/multiqc_config.yml", checkIfExists: true)
    // ch_multiqc_custom_config = params.multiqc_config ?
    //     Channel.fromPath(params.multiqc_config, checkIfExists: true) :
    //     Channel.empty()
    // ch_multiqc_logo          = params.multiqc_logo ?
    //     Channel.fromPath(params.multiqc_logo, checkIfExists: true) :
    //     Channel.empty()

    // summary_params      = paramsSummaryMap(
    //     workflow, parameters_schema: "nextflow_schema.json")
    // ch_workflow_summary = Channel.value(paramsSummaryMultiqc(summary_params))

    // ch_multiqc_custom_methods_description = params.multiqc_methods_description ?
    //     file(params.multiqc_methods_description, checkIfExists: true) :
    //     file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)
    // ch_methods_description                = Channel.value(
    //     methodsDescriptionText(ch_multiqc_custom_methods_description))

    // ch_multiqc_files = ch_multiqc_files.mix(
    //     ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    // ch_multiqc_files = ch_multiqc_files.mix(ch_collated_versions)
    // ch_multiqc_files = ch_multiqc_files.mix(
    //     ch_methods_description.collectFile(
    //         name: 'methods_description_mqc.yaml',
    //         sort: true
    //     )
    // )

    // MULTIQC (
    //     ch_multiqc_files.collect(),
    //     ch_multiqc_config.toList(),
    //     ch_multiqc_custom_config.toList(),
    //     ch_multiqc_logo.toList()
    // )

    // emit:
    // multiqc_report = MULTIQC.out.report.toList() // channel: /path/to/multiqc_report.html
    // versions       = ch_versions                 // channel: [ path(versions.yml) ]
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
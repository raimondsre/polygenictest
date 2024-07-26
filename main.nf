#!/usr/bin/env nextflow
//Updates for integration with calculator platform START
// project_dir = projectDir
// //Run this script to notify the platform that task execution has started
// def startProc = "${project_dir}/started.sh".execute()
// def sb = new StringBuffer()
// startProc.consumeProcessErrorStream(sb)
// println startProc.text
// println sb.toString()


// startProc = "${project_dir}/build_input.sh".execute()
// sb = new StringBuffer()
// startProc.consumeProcessErrorStream(sb)
// println startProc.text 
// println sb.toString()

// workflow.onComplete {
//     startProc = "${project_dir}/build_output.sh".execute()
//     sb = new StringBuffer()
//     startProc.consumeProcessErrorStream(sb)
//     println startProc.text
//     println sb.toString()

//     println "Pipeline completed at: $workflow.complete"
//     println "Execution status: ${ workflow.success ? 'OK' : 'failed' }"
//     f = new File("${projectDir}/status.txt")
//     f.append("\nPipeline completed at: $workflow.complete")
//     f.append("\nExecution status: ${ workflow.success ? 'OK' : 'failed' }")

//     def proc = "${project_dir}/completed.sh".execute()
//     def b = new StringBuffer()
//     proc.consumeProcessErrorStream(b)
//     println proc.text
//     println b.toString()
// }

workflow.onError {
    println "Error: Pipeline execution stopped with the following message: ${workflow.errorMessage}"

    def email_on_error = "${projectDir}/bin/sarek_email.py".execute() 
    def b = new StringBuffer()
    email_on_error.consumeProcessErrorStream(b)
    println email_on_error.text
    println b.toString()


}

//Updates for integration with calculator platform END
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    raimondsre/polygenictest
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Github : https://github.com/raimondsre/polygenictest
----------------------------------------------------------------------------------------
*/

nextflow.enable.dsl = 2

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT FUNCTIONS / MODULES / SUBWORKFLOWS / WORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { POLYGENICTEST  } from './workflows/polygenictest'
include { PIPELINE_INITIALISATION } from './subworkflows/local/utils_nfcore_polygenictest_pipeline'
include { PIPELINE_COMPLETION     } from './subworkflows/local/utils_nfcore_polygenictest_pipeline'

//include { getGenomeAttribute      } from './subworkflows/local/utils_nfcore_polygenictest_pipeline'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    GENOME PARAMETER VALUES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// TODO nf-core: Remove this line if you don't need a FASTA file
//   This is an example of how to use getGenomeAttribute() to fetch parameters
//   from igenomes.config using `--genome`
//params.fasta = getGenomeAttribute('fasta')
// params.output_dir = "."
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    NAMED WORKFLOWS FOR PIPELINE
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// WORKFLOW: Run main analysis pipeline depending on type of input
//
workflow LVBMC_POLYGENICTEST {

    take:
    samplesheet // channel: samplesheet read in from --input

    main:

    //
    // WORKFLOW: Run pipeline 
    //
    POLYGENICTEST (
        samplesheet
    )

    emit:
    VCF_PLINK_sscore_report = POLYGENICTEST.out.VCF_PLINK_sscore_report // channel: /path/to/multiqc_report.html

}
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow {

    main:

    //
    // SUBWORKFLOW: Run initialisation tasks
    //
    PIPELINE_INITIALISATION (
        params.version,
        params.help,
        params.validate_params,
        params.monochrome_logs,
        args,
        params.outdir,
        params.input
    )

    //
    // WORKFLOW: Run main workflow
    //
    LVBMC_POLYGENICTEST (
        PIPELINE_INITIALISATION.out.samplesheet
    )

    //
    // SUBWORKFLOW: Run completion tasks
    //
    PIPELINE_COMPLETION (
        params.email,
        params.email_on_fail,
        params.plaintext_email,
        params.outdir,
        params.monochrome_logs,
        params.hook_url,
        LVBMC_POLYGENICTEST.out.VCF_PLINK_sscore_report
    )
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
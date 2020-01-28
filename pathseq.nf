#!/usr/bin/env nextflow

//  SETUP:
// gsutil -m cp -r gs://cruk-pathseq/pathseq_refdata ~
//
// # install GATK
// wget https://github.com/broadinstitute/gatk/releases/download/4.1.4.1/gatk-4.1.4.1.zip
// sudo apt-get install unzip
// unzip gatk-4.1.4.1.zip
// sudo apt-get install openjdk-8-jdk
// curl -s https://get.nextflow.io | bash


params.resource_dir = '/home/mstrasse/pathseq_refdata'
params.host_kmer = params.resource_dir + '/pathseq_host.bfi'
params.host_img = params.resource_dir + '/pathseq_host.fa.img'
params.microbe_img = params.resource_dir + '/pathseq_microbe.fa.img'
params.microbe_fa = params.resource_dir + '/pathseq_microbe.fa'
params.taxdb = params.resource_dir + '/pathseq_taxonomy.db'
gatk='/home/mstrasse/gatk-4.1.4.1/gatk'

// params.resource_dir = '/home/michi/pathseq_tutorial'
// params.host_kmer = params.resource_dir + '/hg19mini.hss'
// params.host_img = params.resource_dir + '/hg19mini.fasta.img'
// params.microbe_img = params.resource_dir + '/e_coli_k12.fasta.img'
// params.microbe_fa = params.resource_dir + '/e_coli_k12.fasta'
// params.taxdb = params.resource_dir + '/e_coli_k12.db'
// gatk='/home/michi/gatk-4.1.4.1/gatk'



params.bampartitionsize = 24000000



if (!params.outdir){
  exit 1, "--outdir not set!"
}
if (!params.bamfile){
  exit 1, "--bamfile not set!"
}


process pathseqfilter {
  publishDir "${params.outdir}/pathseqfilter/", mode: "copy"

  input:
  file 'input.bam' from file(params.bamfile)

  output:
  // file 'paired.bam' into pairedbam_filter  // not needed for the 10x
  file 'unpaired.bam' into unpairedbam_filter
  file 'filter_metrics.txt'

  script:
  """
  ${gatk} PathSeqFilterSpark  \
    --input input.bam \
    --paired-output paired.bam \
    --unpaired-output unpaired.bam \
    --min-clipped-read-length 60 \
    --kmer-file ${params.host_kmer} \
    --filter-bwa-image ${params.host_img} \
    --filter-metrics filter_metrics.txt \
    --bam-partition-size ${params.bampartitionsize}"""
}

process pathseqbwa {
  publishDir "${params.outdir}/pathseqbwa/", mode: "copy"

  input:
  file 'unpaired_in.bam' from unpairedbam_filter

  output:
  file 'bwa.bam' into bwabam

  script:
  """
  ${gatk} PathSeqBwaSpark  \
    --unpaired-input unpaired_in.bam \
    --unpaired-output bwa.bam \
    --microbe-bwa-image ${params.microbe_img} \
    --microbe-fasta ${params.microbe_fa} \
    --bam-partition-size ${params.bampartitionsize}
  """
}

process pathseqscore {
  publishDir "${params.outdir}/pathseqscore/", mode: "copy"

  input:
  file 'bwa.bam' from bwabam

  output:
  file 'scores.txt'
  file 'out.bam'

  script:
  """
  ${gatk} PathSeqScoreSpark  \
    --unpaired-input bwa.bam \
    --taxonomy-file ${params.taxdb} \
    --scores-output scores.txt \
    --output out.bam \
    --min-score-identity 0.90 \
    --identity-margin 0.02
  """
}

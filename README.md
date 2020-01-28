# nf-10x-pathseq

This nextflow pipeline runs the pathseq pipeline for pathogen detection in RNAseq
on 10x bamfiles.
Note that due to the 3' nature of 10x, we only look at **unpaired** reads


## Requirements
```
# download the reference data (~200Gb)
gsutil -m cp -r gs://cruk-pathseq/pathseq_refdata ~

# install GATK
wget https://github.com/broadinstitute/gatk/releases/download/4.1.4.1/gatk-4.1.4.1.zip
sudo apt-get install unzip
unzip gatk-4.1.4.1.zip
sudo apt-get install openjdk-8-jdk

# Install nextflow
curl -s https://get.nextflow.io | bash
```

## Usage
**Note**: currently the paths to the reference data are hardcoded!

**Note**: The second step of the pipleline takes very long (~2h) without calculating much. Its mostly loading a HUGE bwa index file.

```
nextflow run pathseq.nf \
    --outdir=<...> \
    --bamfile=$/path/to/10x/possorted_genome_bam.bam
```

## Output
Here's what will be contained in the output folder:

```
.
├── pathseqbwa
│   └── bwa.bam
├── pathseqfilter
│   ├── filter_metrics.txt
│   └── unpaired.bam
└── pathseqscore
    ├── out.bam
    └── scores.txt
```
`out.bam` and `scores.txt` are the final results of the pipeline, containing the bacterial reads and each samples bacterial content.

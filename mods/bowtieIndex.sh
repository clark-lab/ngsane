#!/bin/bash -e

# Script to run bowtie v1 program.
# It takes comma-seprated list of files containing short sequence reads in fasta or fastq format and bowtie index files as input.
# It produces output files: read alignments in .bam format and other files.
# author: Fabian Buske
# date: August 2013

# QCVARIABLES,Resource temporarily unavailable
# RESULTFILENAME ${FASTA%.*}.1.ebwt


echo ">>>>> index generation for bowtie 1"
echo ">>>>> startdate "`date`
echo ">>>>> hostname "`hostname`
echo ">>>>> job_name "$JOB_NAME
echo ">>>>> job_id "$JOB_ID
echo ">>>>> $(basename $0) $*"

function usage {
echo -e "usage: $(basename $0) -k [OPTIONS]"
exit
}


if [ ! $# -gt 1 ]; then usage ; fi

#INPUTS                                                                                                           
while [ "$1" != "" ]; do
    case $1 in
        -k | --toolkit )        shift; CONFIG=$1 ;; # location of the NGSANE repository                       
        --recover-from )        shift; NGSANE_RECOVERFROM=$1 ;; # attempt to recover from log file
        -h | --help )           usage ;;
        * )                     echo "don't understand "$1
    esac
    shift
done

#PROGRAMS
. $CONFIG
. ${NGSANE_BASE}/conf/header.sh
. $CONFIG

################################################################################
NGSANE_CHECKPOINT_INIT "programs"

# save way to load modules that itself loads other modules
hash module 2>/dev/null && for MODULE in $MODULE_BOWTIE; do module load $MODULE; done && module list 

export PATH=$PATH_BOWTIE:$PATH
echo "PATH=$PATH"

echo -e "--NGSANE      --\n" $(trigger.sh -v 2>&1)
echo -e "--bowtie      --\n "$(bowtie --version)
[ -z "$(which bowtie)" ] && echo "[ERROR] no bowtie detected" && exit 1

NGSANE_CHECKPOINT_CHECK
################################################################################
NGSANE_CHECKPOINT_INIT "parameters"

if [ -z "$FASTA" ]; then
    echo "[ERROR] no reference provided (FASTA)"
    exit 1
fi

NGSANE_CHECKPOINT_CHECK
################################################################################
NGSANE_CHECKPOINT_INIT "recall files from tape"

if [ -n "$DMGET" ]; then
	dmget -a $(dirname $FASTA)/*
fi
    
NGSANE_CHECKPOINT_CHECK
################################################################################
NGSANE_CHECKPOINT_INIT "generating the index files"

if [[ $(NGSANE_CHECKPOINT_TASK) == "start" ]]; then

    if [ ! -e ${FASTA%.*}.1.ebwt ]; then 
        echo "[NOTE] make .ebwt"; 
        bowtie-build $FASTA ${FASTA%.*}; 
    fi
    if [ ! -e $FASTA.fai ]; then 
        echo "[NOTE] make .fai"; 
        samtools faidx $FASTA; 
    fi

    # mark checkpoint
    NGSANE_CHECKPOINT_CHECK ${FASTA%.*}.1.ebwt
fi 

NGSANE_CHECKPOINT_CHECK
################################################################################
[ -e ${FASTA%.*}.1.ebwt.dummy ] && rm ${FASTA%.*}.1.ebwt.dummy
echo ">>>>> index generation for bowtie 1 - FINISHED"
echo ">>>>> enddate "`date`

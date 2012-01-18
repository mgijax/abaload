#!/bin/sh 

#
# Program: abaload.sh
#
# Original Author: Lori Corbani
#
# Purpose:
#
# Job Stream for Allen Brain Atlas load
#
#	1.  Copy ABA file from downloads directory
#	2.  From file, create association loader file
#	3.  Load the Marker/ABA associations into MGI using the association loader
#
# History:
#
# abaload.sh /mgi/all/wts_projects/10900/10932/20120109_aba_gene_list.csv
#
# 01/11/2012	lec
#	- TR10932/new file format
#
# 03/25/2008	lec
#	- TR 8769
#

cd `dirname $0`
LOG=`pwd`/abaload.log
rm -rf ${LOG}

# true if input from radar, false if from command line
RADAR_FLAG=0

#
# Verify arguments to shell script
#
if [ $# -eq 1 ]
then
    APP_INFILE=$1
    RADAR_FLAG=0
elif [ $# -ne 0 ]
then
    echo "Usage: $0 [load file]" | tee -a ${LOG}
    exit 1
fi

CONFIG_LOAD=`pwd`/abaload.config

#
# verify & source the configuration file
#

if [ ! -r ${CONFIG_LOAD} ]
then
    echo "Cannot read configuration file: ${CONFIG_LOAD}"
    exit 1
fi

. ${CONFIG_LOAD}

#
#  Source the DLA library functions.
#

if [ "${DLAJOBSTREAMFUNC}" != "" ]
then
    if [ -r ${DLAJOBSTREAMFUNC} ]
    then
        . ${DLAJOBSTREAMFUNC}
    else
        echo "Cannot source DLA functions script: ${DLAJOBSTREAMFUNC}" | tee -a ${LOG}
        exit 1
    fi
else
    echo "Environment variable DLAJOBSTREAMFUNC has not been defined." | tee -a ${LOG}
    exit 1
fi

#
#  Fetch files to be loaded if not specified
#
if [ "${APP_INFILE}" = "" ]
then
    echo "\n`date`" >> ${LOG_DIAG}
    echo "Fetching files to load..." >> ${LOG_DIAG}
    APP_INFILE=`${RADAR_DBUTILS}/bin/getFilesToProcess.csh ${RADAR_DBSCHEMADIR} ${JOBSTREAM} ABA`
    STAT=$?

    if [ ${STAT} -ne 0 ]
    then
       echo "getFilesToProcess.csh failed. Return status: ${STAT}" | tee -a ${LOG_DIAG} ${LOG_PROC}
       exit 1
    fi
fi

#
# createArchive including OUTPUTDIR, startLog, getConfigEnv, get job key
#
preload ${OUTPUTDIR}

#
# rm all files/dirs from INPUTDIR and OUTPUTDIR
#
cleanDir ${INPUTDIR} ${OUTPUTDIR}

# if no input files report and shutdown gracefully
if [ "${APP_INFILE}" = "" ]
then
    echo "No files to process" | tee -a ${LOG_DIAG} ${LOG_PROC}
    shutDown
    exit 0
fi

#
# generate association file
#

cd ${INPUTDIR}
cp ${APP_INFILE} .
${ABALOAD}/abaparse.py
STAT=$?
checkStatus ${STAT} "${ABALOAD}/abaparse.py"

#
# run association load
#
echo "Running ABA association load" >> ${LOG_DIAG}
${ASSOCLOAD}/bin/AssocLoad.sh ${CONFIG_LOAD} ${JOBKEY}
STAT=$?
checkStatus ${STAT} "${ASSOCLOAD}/bin/AssocLoad.sh"

#
#  Mark the file as having been processed successfully.
#
if [ ${RADAR_FLAG} -eq 1 ]
then
    echo "\n`date`" >> ${LOG_DIAG} 
    echo "Mark file ${APP_INFILE} as processed" >> ${LOG_DIAG}
    echo "command is:  ${RADAR_DBUTILS}/bin/logProcessedFile.csh ${RADAR_DBSCHEMADIR} ${JOBKEY} ${APP_INFILE} ABA"
    ${RADAR_DBUTILS}/bin/logProcessedFile.csh ${RADAR_DBSCHEMADIR} ${JOBKEY} ${APP_INFILE} ABA >> ${LOG_DIAG} 2>&1
    STAT=$?
    if [ ${STAT} -ne 0 ]
    then
	echo "logProcessedFile.csh failed. Return status: ${STAT}" | tee -a ${LOG_DIAG} ${LOG_PROC}
    fi
fi

#
# run postload cleanup and email logs
#
shutDown
echo "`date`" >> ${LOG}

exit 0

#!/usr/local/bin/python

#
# Program: abaparse.py
#
# Original Author: Lori E. Corbani
#
# Purpose:
#
# To generate an association loader input file from the ABA input file.
#
# Requirements Satisfied by This Program:
#
# Usage:  abamparse.py
#
# Envvars:
#
# Inputs:
#
# INFILE_NAME_ABA:  a file of ABA data
#
# Outputs:
#
# INFILE_NAME:  the output of this parser & the input file for the association loader
#
# Processing:
#
# Exit Codes:
#
# Assumes:
#
# Bugs:
#
# Implementation:
#
#    Modules:
#
# Modification History:
#
# 03/25/2008	lec
#	- TR 8769
#

import sys
import os
import re
import db
import string
import mgi_utils

inFileName = os.environ['INFILE_NAME_ABA']
assocFileName = os.environ['INFILE_NAME']

diagFileName = os.environ['LOGDIR'] + '/abaparse.diagnostics'
diagFile = ''		# file descriptor

assocHeader = 'MGI\tABA\n'
assocline = '%s\t%s\n'

def exit(status, message = None):
	#
	# requires: status, the numeric exit status (integer)
	#           message (string)
	#
	# effects:
	# Print message to stderr and exits
	#
	# returns:
	#
 
    if message is not None:
	sys.stderr.write('\n' + str(message) + '\n')
 
    try:
	diagFile.write('\n\nEnd Date/Time: %s\n' % (mgi_utils.date()))
	diagFile.close()
	inputerrorFile.close()
	ens1errorFile.close()
	ens2errorFile.close()
	mgierrorFile.close()
    except:
	pass

    try:
	db.useOneConnection()
    except:
	pass

    sys.exit(status)
 
def init():
	#
	# requires: 
	#
	# effects: 
	# 1. Processes command line options
	# 2. Initializes global file descriptors/file names
	#
	# returns:
	#
 
    global diagFile, inputerrorFile, ens1errorFile, ens2errorFile, mgierrorFile
    global mgiens
 
    try:
	diagFile = open(diagFileName, 'w')
    except:
	exit(1, 'Could not open file %s\n' % diagFileName)
		
    diagFile.write('Start Date/Time: %s\n\n' % (mgi_utils.date()))

    db.useOneConnection(1)

def writeAssoc(assocDict):
	#
	# requires:
	#    assocDict (dictionary):  a key:value dictionary
	#
	# effects: 
	# 1. Writes each association to the output association file
	#
	# returns:  nothing
	#

    try:
	assocFile = open(assocFileName, 'w')
    except:
	exit(1, 'Could not open file %s\n' % assocFileName)
		
    assocFile.write(assocHeader)

    for r in assocDict.keys():
	for a in assocDict[r]:
            assocFile.write(a)

    assocFile.close()

def process():
	#
	# requires:
	#
	# effects: 
	#   input:  input file
	#   output: association loader file
	#
	# returns:  nothing
	#

    assocDict = {}

    try:
	inFile = open(inFileName, 'r')
    except:
	exit(1, 'Could not open file %s\n' % inFileName)
		
    lineNum = 0

    for line in inFile.readlines():

	if lineNum == 0:
	    lineNum = lineNum + 1
	    continue

	s1 = re.sub('","', '|', line[:-1])
	s2 = re.sub('"', '', s1)

        tokens = string.split(s2, '|')

	mgiID = tokens[5]
	if mgiID == '':
	    continue

	if not assocDict.has_key(mgiID):
	    assocDict[mgiID] = []
	assocDict[mgiID].append(assocline % (mgiID, mgiID))

        lineNum = lineNum + 1

    writeAssoc(assocDict)

    inFile.close()

#
# Main Routine
#

init()
process()
exit(0)


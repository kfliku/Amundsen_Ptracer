#!/usr/bin/env python
import sys
import os
from numpy import zeros,ones,unique,savez,load
import glob
import time
import subprocess
import re

### What this code do?
## This code edits the ../run//data file to restart the run from the latest checkpoint file.
### How do you do this?
#### Procedure #1: the code finds the latest pickup file in ../run/, which has a form 'pickup.XX.'
#### Procedure #2: Read the file from #1 and get the new niter0 (NITER0) and the XX part of the pickup file (PICKUP)
#### Procedure #3: Copy the original ../run/data to data_niter0 
#### Procedure #4: Find the line number in ../run/data containing 'niter0' and edit the linenumber to niter0=NITER0
#### Procedure #5: Find the line number in ../run/data containing 'pickupSuff' and edit the linenumber to pickupSuff=PICKUP

def get_line_number(phrase, filename):

	with open(filename) as myFile:
	    for num, line in enumerate(myFile, 1):
	        if phrase in line:
	            #print 'found at line:', num,line
	            picked_line = line
	            picked_num = num
	return picked_line,picked_num

def replace_line(file_name, line_num, text):
    lines = open(file_name, 'r').readlines()
    lines[line_num] = text
    out = open(file_name, 'w')
    out.writelines(lines)
    out.close()


#### Procedure #1
## List all the pickup files
FileList = glob.glob('../run/pickup.*.meta')
## Fild the latest saved checkpoint file
latest_pickup_file = max(FileList, key=os.path.getctime)


#### Procedure #2
## find the middle bits of the checkpoint, Get the XX part of the pickup.XX.
PICKUP = re.search(r"\.([A-Za-z0-9_]+)\.",latest_pickup_file).group(1)

## Get the timeStepNumber from the latesest pickup file
phrase = 'timeStepNumber'
filename = latest_pickup_file
[picked_line,picked_num] = get_line_number(phrase, filename)
NITER0 = re.match(r"[^[]*\[([^]]*)\]", picked_line).groups()[0]
print('Need to replace PICKUP and NITER0 in ./run/data',PICKUP,NITER0)

##### Procedure #3
### Before edit the data file, save the copy
data_file_history = '../run/data_'+str(int(NITER0))
print(data_file_history)
os.system('cp ../run/data '+data_file_history)

## Also save the current STDERR and STDOUT files mv STDERR.0000 stderr_str(int(NITER0))
os.system('mv ../run/STDERR.0000 ../run/STDERR_'+str(int(NITER0)))
os.system('mv ../run/STDOUT.0000 ../run/STDOUT_'+str(int(NITER0)))


##### Procedure #4
# sed_command = 'sed -i "/^ niter0/c\ niter0=133," ../run/data'
### Find the line number containing 'niter0' and replace it with the new niter0, str(int(NITER0))
phrase = 'niter0'
[niter_line,niter_num] = get_line_number(phrase, '../run/data')
## The new niter0 line
new_niter_line = ' niter0='+str(int(NITER0))+',\n'
## Here we replace the niter_num in ../run/data
replace_line('../run/data', niter_num-1, new_niter_line)


##### Procedure #5
### Find the line containing 'pickupSuff'
[pickup_line,pickup_num] = get_line_number('pickupSuff', '../run/data')
## Define the new line
new_pickup_line = ' pickupSuff=\''+PICKUP+'\',\n'
## Here we replace the pickup_num in ../run/data
replace_line('../run/data', pickup_num-1, new_pickup_line)


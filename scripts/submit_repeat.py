#!/usr/bin/env python
import sys
import os
import subprocess

def system_call(command):
    p = subprocess.Popen([command], stdout=subprocess.PIPE, shell=True)
    out = p.stdout.read()
    out = str(out,'utf-8') #Get rid of b'..',https://stackoverflow.com/questions/37016946/remove-b-character-do-in-front-of-a-string-literal-in-python-3
    out = out[0:-1]
    return out



NumberOfRepeat = 30
print('*** Start the repeated submission')
for fid in range(0,NumberOfRepeat,1):


	#### Fail safe to shutdown the submission
	f = open('iAbort.txt','r')
	message = int(f.read())
	print(message)
	f.close()
	if message==0:
	### save the output
		print('****iAbort.txt is 0, so I quit submitting the job')
		sys.exit()



	print('###############Current number of repeat:',fid)
	## submit the job chain
	command_submit = 'qsub -Z submit_one.sh'
	check = system_call(command_submit)
	print('check:',check)

	## now wait until the job finish
	command_wait = 'qwait '+str(check)
	output = os.system(command_wait)

	# execute the Edit_data.py to edit the data file
	command_edit = 'python Edit_data.py'
	output_edit = os.system(command_edit)



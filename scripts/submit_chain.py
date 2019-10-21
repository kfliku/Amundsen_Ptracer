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



command_prep = 'sh ./prepare_run_DA.sh'
output1 = os.system(command_prep)

command_submit = 'python submit_repeat.py'
os.system(command_submit)

# ## submit the job chain
# command_submit = 'qsub -Z submit_one.sh'


# check = system_call(command_submit)
# print('check:',check)

# ## now wait until the job finish
# command_wait = 'qwait '+str(check)
# output = os.system(command_wait)

# # execute the Edit_data.py to edit the data file
# command_edit = 'python Edit_data.py'
# output_edit = os.system(command_edit)

# ### Now submit again to see if this work
# check1 = system_call(command_submit)
# print('re-submit the job check1:',check1)

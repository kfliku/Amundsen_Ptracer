#!/bin/bash
################################################
# Clean out old results and link input files.
################################################

# Empty the run directory - but first make sure it exists!
if [ -d "../run" ]; then
  cd ../run
  rm -rf *
else
  echo 'There is no run directory'
  exit 1
fi

# Link everything from the input directory
ln -s ../input/* . 

# Deep copy of the master namelist (so it doesn't get overwritten in input/)
rm -f data
cp -f ../input/data .

# Deep copy of any pickups (so they don't get overwritten in input/)
rm -f pickup*
cp -f ../input/pickup* . 2>/dev/null

# Link forcing files stored elsewhere
ln -s /work/G10305/skimura/SHARED/baspog/MITgcm/reanalysis/ERAI_075/* .
rm -f  ERAinterim_spfh2m_* 
ln -s /work/G10305/skimura/SHARED/baspog/MITgcm/reanalysis/ERAI_075_humidity_fix_new/* .

#ln -s /work/n02/n02/pahol/CESM/PACE/* .

# Link executables
ln -s ../build/mitgcmuv .
ln -s ../../../utilities/mit2nc/mit2nc .

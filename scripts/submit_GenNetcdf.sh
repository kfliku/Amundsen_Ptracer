#!/bin/bash
#PBS -q l
#PBS -T intmpi
#PBS -b 1
#PBS -l cpunum_job=1
#PBS -l memsz_job=181gb
#PBS -l elapstim_req=03:00:00
#PBS -v OMP_NUM_THREADS=1
#PBS -o stdout.%s.%j
#PBS -e stderr.%s.%j


cd $PBS_O_WORKDIR/../run

# # Link executables
# #


# cd ../run
# ln -s ../build/mitgcmuv .
ln -s ../../../utilities/mit2nc/mit2nc .

# pad meta files for crash files so that mit2nc works
# (copy -noclobber to ensure only done once)
for file in *crash*.meta; do
  cp -n $file ${file}_original  
  cat ${file}_original ../scripts/crashmeta.txt > $file
done

# for each diagnostic file, make netcdf and rsync
VARS="
      state2D
      stateExf
      stateTheta
      stateSalt
      stateUvel
      stateVvel
      stateWvel
     "

for VAR in $VARS
do
  rm -rf $VAR.nc
  echo 'seconds since 1979-01-01 00:00:00' > file_list
  ls $VAR.*.data >> file_list
  ./mit2nc
  
done


#!/bin/bash
#PBS -N c960
#PBS -q l
#PBS -T intmpi
#PBS -b 24
#PBS -l cpunum_job=40
#PBS -l memsz_job=181gb
#PBS -l elapstim_req=24:00:00
#PBS -o stdout ##.%s.%j
#PBS -e stderr ##.%s.%j
#PBS -m b
#PBS -M likukf@jamstec.go.jp

cd $PBS_O_WORKDIR/../run
mpirun ${NQSII_MPIOPTS} -ppn 1 -np 960 ./mitgcmuv

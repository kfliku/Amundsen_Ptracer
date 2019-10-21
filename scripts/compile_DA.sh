
cd ../build
rm -rf *
#module swap PrgEnv-cray PrgEnv-intel
#odule swap cray-netcdf netcdf
module load intel-compiler/18.0.1

export ROOTDIR=/work/G10305/likukf/mitgcm/MITgcm-checkpoint67d

$ROOTDIR/tools/genmake2 -ieee -mods=../code -of=../../../build_options/linux_amd64_ifort_DA -mpi
make depend
make

# Switch Programming Environment back
#module swap PrgEnv-intel PrgEnv-cray
#module swap netcdf cray-netcdf

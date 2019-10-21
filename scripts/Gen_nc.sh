

# Link executables
#ln -s ../build/mitgcmuv .


cd ../run

ln -s ../../../utilities/mit2nc/mit2nc .

# for each diagnostic file, make netcdf and rsync
VARS="
      state2D
     "

for VAR in $VARS
do
  rm -rf $VAR.nc
  echo 'seconds since 1979-01-01 00:00:00' > file_list
  ls $VAR.*.data >> file_list
  ./mit2nc
  
done


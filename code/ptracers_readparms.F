C $Header: /u/gcmpack/MITgcm/pkg/ptracers/ptracers_readparms.F,v 1.38 2010/12/13 20:27:15 jmc Exp $
C $Name: checkpoint62r $

#include "PTRACERS_OPTIONS.h"

C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|
CBOP
C     !ROUTINE: PTRACERS_READPARMS

C     !INTERFACE:
      SUBROUTINE PTRACERS_READPARMS( myThid )

C     !DESCRIPTION:
C     Initialize PTRACERS parameters, read in data.ptracers

C     !USES:
      IMPLICIT NONE
#include "SIZE.h"
#include "EEPARAMS.h"
#ifdef ALLOW_LONGSTEP
#include "LONGSTEP_PARAMS.h"
#endif
#include "PTRACERS_SIZE.h"
#include "PTRACERS_PARAMS.h"
#include "PARAMS.h"
#ifdef ALLOW_MNC
#include "MNC_PARAMS.h"
#endif

C     !INPUT PARAMETERS:
      INTEGER myThid
CEOP

#ifdef ALLOW_PTRACERS
C     !FUNCTIONS
C      LOGICAL  GAD_VALID_ADVSCHEME
C      EXTERNAL GAD_VALID_ADVSCHEME

C     !LOCAL VARIABLES:
C     k,iTracer  :: loop indices
C     iUnit      :: unit number for I/O
C     msgBuf     :: message buffer
      INTEGER k, iTracer
      INTEGER iUnit
      INTEGER ic
      LOGICAL validNum
      CHARACTER*(MAX_LEN_MBUF) msgBuf
      _RL PTRACERS_diffKr(PTRACERS_num)
      _RL tauTr1ClimRelax

C     PTRACERS_taveFreq :: Frequency with which time-averaged PTRACERS
C                          are written to post-processing files.
C     tauTr1ClimRelax :: old parameter (will be removed 1 day)
      NAMELIST /PTRACERS_PARM01/
     &     tauTr1ClimRelax,
     &     PTRACERS_dumpFreq,
     &     PTRACERS_taveFreq,
     &     PTRACERS_monitorFreq,
     &     PTRACERS_advScheme,
     &     PTRACERS_ImplVertAdv,
     &     PTRACERS_diffKh,
     &     PTRACERS_diffK4,
     &     PTRACERS_diffKr,
     &     PTRACERS_diffKrNr,
     &     PTRACERS_ref,
     &     PTRACERS_EvPrRn,
     &     PTRACERS_ROFF,
     &     PTRACERS_PREC,
     &     PTRACERS_EVAP,
     &     PTRACERS_SHFW,
     &     PTRACERS_SICEhr,
     &     PTRACERS_SICEph,
     &     PTRACERS_addSrelax2EmP,
     &     PTRACERS_useGMRedi,
     &     PTRACERS_useDWNSLP,
     &     PTRACERS_useKPP,
     &     PTRACERS_Iter0,
     &     PTRACERS_numInUse,
     &     PTRACERS_initialFile,
     &     PTRACERS_useRecords,
     &     PTRACERS_names,
     &     PTRACERS_long_names,
     &     PTRACERS_units,
     &     PTRACERS_timeave_mnc,
     &     PTRACERS_snapshot_mnc,
     &     PTRACERS_monitor_mnc,
     &     PTRACERS_pickup_write_mnc,
     &     PTRACERS_pickup_read_mnc

      _BEGIN_MASTER(myThid)

C     This routine has been called by the main model so we set our
C     internal flag to indicate we are in business
c     PTRACERSisON=.TRUE.
C Note(jmc): remove this flag which is not really usefull (not set properly
C            when usePTRACERS=F and always TRUE otherwise);
C            much better to use "usePTRACERS" flag instead.

C     Set ptracer IO & diagnostics labels (2 characters long)
      CALL PTRACERS_SET_IOLABEL(
     O                           PTRACERS_ioLabel,
     I                           PTRACERS_num, myThid )

C     Set defaults values for parameters in PTRACERS.h
      PTRACERS_dumpFreq    = dumpFreq
      PTRACERS_taveFreq    = taveFreq
      PTRACERS_monitorFreq = monitorFreq
      PTRACERS_Iter0   = 0
      PTRACERS_numInUse=-1
      DO iTracer=1,PTRACERS_num
        PTRACERS_advScheme(iTracer)=saltAdvScheme
        PTRACERS_ImplVertAdv(iTracer) = .FALSE.
        PTRACERS_diffKh(iTracer)=diffKhS
        PTRACERS_diffK4(iTracer)=diffK4S
        PTRACERS_diffKr(iTracer)=UNSET_RL
        DO k=1,Nr
          PTRACERS_diffKrNr(k,iTracer)=diffKrNrS(k)
          PTRACERS_ref     (k,iTracer)=0. _d 0
        ENDDO
        PTRACERS_EvPrRn(iTracer)=UNSET_RL
        PTRACERS_ROFF(iTracer)=UNSET_RL
        PTRACERS_PREC(iTracer)=UNSET_RL
        PTRACERS_EVAP(iTracer)=UNSET_RL
        PTRACERS_SHFW(iTracer)=UNSET_RL
        PTRACERS_SICEhr(iTracer)=UNSET_RL
        PTRACERS_SICEph(iTracer)=UNSET_RL
        PTRACERS_useGMRedi(iTracer)=useGMRedi
        PTRACERS_useDWNSLP(iTracer)=useDOWN_SLOPE
        PTRACERS_useKPP(iTracer)   =useKPP
        PTRACERS_initialFile(iTracer)=' '
        DO ic = 1,MAX_LEN_FNAM
          PTRACERS_names(iTracer)(ic:ic) = ' '
          PTRACERS_long_names(iTracer)(ic:ic) = ' '
          PTRACERS_units(iTracer)(ic:ic) = ' '
        ENDDO
      ENDDO
      PTRACERS_addSrelax2EmP    = .FALSE.
      PTRACERS_useRecords       = .FALSE.
#ifdef ALLOW_MNC
      PTRACERS_timeave_mnc      = useMNC .AND. timeave_mnc
      PTRACERS_snapshot_mnc     = useMNC .AND. snapshot_mnc
      PTRACERS_monitor_mnc      = useMNC .AND. monitor_mnc
      PTRACERS_pickup_write_mnc = useMNC .AND. pickup_write_mnc
      PTRACERS_pickup_read_mnc  = useMNC .AND. pickup_read_mnc
#else
      PTRACERS_timeave_mnc      = .FALSE.
      PTRACERS_snapshot_mnc     = .FALSE.
      PTRACERS_monitor_mnc      = .FALSE.
      PTRACERS_pickup_write_mnc = .FALSE.
      PTRACERS_pickup_read_mnc  = .FALSE.
#endif
      tauTr1ClimRelax = 0.
      DO k = 1,Nr
#ifdef ALLOW_LONGSTEP
        PTRACERS_dTLev(k) = LS_nIter*dTtracerLev(k)
#else
        PTRACERS_dTLev(k) = dTtracerLev(k)
#endif
      ENDDO

C     Open and read the data.ptracers file
      WRITE(msgBuf,'(A)') ' PTRACERS_READPARMS: opening data.ptracers'
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT , myThid )
      CALL OPEN_COPY_DATA_FILE(
     I                   'data.ptracers', 'PTRACERS_READPARMS',
     O                   iUnit,
     I                   myThid )
      READ(UNIT=iUnit,NML=PTRACERS_PARM01)
      WRITE(msgBuf,'(A)')
     &  ' PTRACERS_READPARMS: finished reading data.ptracers'
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT , myThid )

C     Close the open data file
      CLOSE(iUnit)

C     Now set-up any remaining parameters that result from the input
C     parameters

C     Tracer 1 climatology relaxation time scale (<- but the code is gone !)
      IF ( tauTr1ClimRelax .EQ. 0. ) THEN
       lambdaTr1ClimRelax = 0.
      ELSE
       lambdaTr1ClimRelax = 1./tauTr1ClimRelax
      ENDIF

C     If PTRACERS_numInUse was not set in data.ptracers then we can
C     assume that all PTRACERS fields will be in use
      IF (PTRACERS_numInUse.LT.0) THEN
        PTRACERS_numInUse=PTRACERS_num
      ENDIF
C     Check we are not trying to use more tracers than allowed
      IF (PTRACERS_numInUse.GT.PTRACERS_num) THEN
        WRITE(msgBuf,'(A,I4,A,I4,A)')
     &       ' PTRACERS_READPARMS: You requested',PTRACERS_numInUse,
     &       ' tracers at run time when only',PTRACERS_num,
     &       ' were specified at compile time. Naughty! '
        CALL PRINT_ERROR( msgBuf, myThid )
        STOP 'ABNORMAL END: S/R PTRACERS_READPARMS'
      ENDIF
#ifndef INCLUDE_IMPLVERTADV_CODE
      DO iTracer=1,PTRACERS_numInUse
       IF ( PTRACERS_ImplVertAdv(iTracer) ) THEN
        WRITE(msgBuf,'(A)')
     &   'PTRACERS_READPARMS: #undef INCLUDE_IMPLVERTADV_CODE'
        CALL PRINT_ERROR( msgBuf, myThid )
        WRITE(msgBuf,'(2A,I3,A)') 'PTRACERS_READPARMS:',
     &   ' but pTracers_ImplVertAdv(',iTracer,' ) is TRUE'
        CALL PRINT_ERROR( msgBuf, myThid )
        STOP 'ABNORMAL END: S/R PTRACERS_READPARMS'
       ENDIF
      ENDDO
      IF ( PTRACERS_dTLev(1).NE.PTRACERS_dTLev(Nr)
     &     .AND. implicitDiffusion ) THEN
        WRITE(msgBuf,'(A)')
     &   'PTRACERS_READPARMS: #undef INCLUDE_IMPLVERTADV_CODE'
        CALL PRINT_ERROR( msgBuf , myThid)
        WRITE(msgBuf,'(2A)') 'PTRACERS_READPARMS: ',
     &   'but implicitDiffusion=T with non-uniform PTRACERS_dTLev'
        CALL PRINT_ERROR( msgBuf , myThid)
        STOP 'ABNORMAL END: S/R PTRACERS_READPARMS'
      ENDIF
#endif
      DO iTracer=1,PTRACERS_numInUse
        IF ( PTRACERS_useGMRedi(iTracer) .AND. .NOT.useGMRedi ) THEN
          WRITE(msgBuf,'(2A,I3,A)') 'PTRACERS_READPARMS:',
     &     ' pTracers_useGMRedi(',iTracer,' ) is TRUE'
          CALL PRINT_ERROR( msgBuf, myThid )
          WRITE(msgBuf,'(A,L5,A)')
     &     'PTRACERS_READPARMS: But not useGMRedi (=',useGMRedi,')'
          CALL PRINT_ERROR( msgBuf, myThid )
          STOP 'ABNORMAL END: S/R PTRACERS_READPARMS'
        ENDIF
        IF ( PTRACERS_useDWNSLP(iTracer) .AND. .NOT.useDOWN_SLOPE ) THEN
          WRITE(msgBuf,'(2A,I3,A)') 'PTRACERS_READPARMS:',
     &     ' pTracers_useDWNSLP(',iTracer,' ) is TRUE'
          CALL PRINT_ERROR( msgBuf, myThid )
          WRITE(msgBuf,'(2A,L5,A)') 'PTRACERS_READPARMS:',
     &     ' But not useDOWN_SLOPE (=', useDOWN_SLOPE, ')'
          CALL PRINT_ERROR( msgBuf, myThid )
          STOP 'ABNORMAL END: S/R PTRACERS_READPARMS'
        ENDIF
        IF ( PTRACERS_useKPP(iTracer) .AND. .NOT.useKPP ) THEN
          WRITE(msgBuf,'(2A,I3,A)') 'PTRACERS_READPARMS:',
     &     ' pTracers_useKPP(',iTracer,' ) is TRUE'
          CALL PRINT_ERROR( msgBuf, myThid )
          WRITE(msgBuf,'(A,L5,A)')
     &     'PTRACERS_READPARMS: But not useKPP (=',useKPP,')'
          CALL PRINT_ERROR( msgBuf, myThid )
          STOP 'ABNORMAL END: S/R PTRACERS_READPARMS'
        ENDIF
        IF ( PTRACERS_diffKr(iTracer).NE.UNSET_RL ) THEN
         DO k=1,Nr
          PTRACERS_diffKrNr(k,iTracer)=PTRACERS_diffKr(iTracer)
         ENDDO
        ENDIF
      ENDDO

#ifdef ALLOW_MNC
      PTRACERS_timeave_mnc      = useMNC .AND. PTRACERS_timeave_mnc
      PTRACERS_snapshot_mnc     = useMNC .AND. PTRACERS_snapshot_mnc
      PTRACERS_monitor_mnc      = useMNC .AND. PTRACERS_monitor_mnc
      PTRACERS_pickup_write_mnc = useMNC .AND. PTRACERS_pickup_write_mnc
      PTRACERS_pickup_read_mnc  = useMNC .AND. PTRACERS_pickup_read_mnc

      PTRACERS_timeave_mdsio      = (.NOT. PTRACERS_timeave_mnc)
     &     .OR. outputTypesInclusive
      PTRACERS_snapshot_mdsio     = (.NOT. PTRACERS_snapshot_mnc)
     &     .OR. outputTypesInclusive
      PTRACERS_monitor_stdio      = (.NOT. PTRACERS_monitor_mnc)
     &     .OR. outputTypesInclusive
      PTRACERS_pickup_write_mdsio = (.NOT. PTRACERS_pickup_write_mnc)
     &     .OR. outputTypesInclusive
      PTRACERS_pickup_read_mdsio  = (.NOT. PTRACERS_pickup_read_mnc)
     &     .OR. outputTypesInclusive
#else
      PTRACERS_timeave_mnc        = .FALSE.
      PTRACERS_snapshot_mnc       = .FALSE.
      PTRACERS_monitor_mnc        = .FALSE.
      PTRACERS_pickup_write_mnc   = .FALSE.
      PTRACERS_pickup_read_mnc    = .FALSE.
      PTRACERS_timeave_mdsio      = .TRUE.
      PTRACERS_snapshot_mdsio     = .TRUE.
      PTRACERS_monitor_stdio      = .TRUE.
      PTRACERS_pickup_write_mdsio = .TRUE.
      PTRACERS_pickup_read_mdsio  = .TRUE.
#endif

C--   Print a summary of pTracer parameter values:
      iUnit = standardMessageUnit
      WRITE(msgBuf,'(A)') '// ==================================='
      CALL PRINT_MESSAGE( msgBuf, iUnit, SQUEEZE_RIGHT , myThid )
      WRITE(msgBuf,'(A)') '// PTRACERS parameters '
      CALL PRINT_MESSAGE( msgBuf, iUnit, SQUEEZE_RIGHT , myThid )
      WRITE(msgBuf,'(A)') '// ==================================='
      CALL PRINT_MESSAGE( msgBuf, iUnit, SQUEEZE_RIGHT , myThid )
      CALL WRITE_0D_I( PTRACERS_numInUse, INDEX_NONE,
     &   'PTRACERS_numInUse =',
     &   ' /* number of tracers */')
      CALL WRITE_0D_I( PTRACERS_Iter0, INDEX_NONE,
     &   'PTRACERS_Iter0 =',
     &   ' /* timestep number when tracers are initialized */')
      CALL WRITE_0D_L( PTRACERS_addSrelax2EmP, INDEX_NONE,
     &   'PTRACERS_addSrelax2EmP =','/* add Salt relaxation to EmP */')
      CALL WRITE_1D_RL( PTRACERS_dTLev, Nr, INDEX_K,
     &   'PTRACERS_dTLev =',
     &'   /* Ptracer timestep ( s ) */')
      CALL WRITE_0D_RL(PTRACERS_dumpFreq, INDEX_NONE,
     &   'PTRACERS_dumpFreq =',
     &   ' /* Frequency^-1 for snapshot output (s) */')
      CALL WRITE_0D_RL(PTRACERS_taveFreq, INDEX_NONE,
     &   'PTRACERS_taveFreq =',
     &   ' /* Frequency^-1 for time-Aver. output (s) */')
      CALL WRITE_0D_L( PTRACERS_useRecords, INDEX_NONE,
     &   'PTRACERS_useRecords =', ' /* all tracers in 1 file */')

      CALL WRITE_0D_L( PTRACERS_timeave_mnc, INDEX_NONE,
     &     'PTRACERS_timeave_mnc =',
     &     ' /* use MNC for Tave output */')
      CALL WRITE_0D_L( PTRACERS_snapshot_mnc, INDEX_NONE,
     &     'PTRACERS_snapshot_mnc =',
     &     ' /* use MNC for snapshot output */')
      CALL WRITE_0D_L( PTRACERS_pickup_write_mnc, INDEX_NONE,
     &     'PTRACERS_pickup_write_mnc =',
     &     ' /* use MNC for writing pickups */')
      CALL WRITE_0D_L( PTRACERS_pickup_read_mnc, INDEX_NONE,
     &     'PTRACERS_pickup_read_mnc =',
     &     ' /* use MNC for reading pickups */')

      DO iTracer=1,PTRACERS_numInUse
        WRITE(msgBuf,'(A)') ' -----------------------------------'
        CALL PRINT_MESSAGE( msgBuf, iUnit, SQUEEZE_RIGHT, myThid )
        WRITE(msgBuf,'(A,I4)') ' tracer number : ',iTracer
        CALL PRINT_MESSAGE( msgBuf, iUnit, SQUEEZE_RIGHT, myThid )
        CALL WRITE_0D_C( PTRACERS_names(iTracer), -1, INDEX_NONE,
     &     'PTRACERS_names =', ' /* Tracer short name */')
        CALL WRITE_0D_C( PTRACERS_long_names(iTracer), -1, INDEX_NONE,
     &     'PTRACERS_long_names =', ' /* Tracer long name */')
        CALL WRITE_0D_C( PTRACERS_ioLabel(iTracer), 0, INDEX_NONE,
     &     'PTRACERS_ioLabel =', ' /* tracer IO Label */')
        CALL WRITE_0D_I( PTRACERS_advScheme(iTracer), INDEX_NONE,
     &     'PTRACERS_advScheme =', ' /* Advection Scheme */')
        CALL WRITE_0D_L( PTRACERS_ImplVertAdv(iTracer), INDEX_NONE,
     &     'PTRACERS_ImplVertAdv =',
     &     ' /* implicit vert. advection flag */')
        CALL WRITE_0D_RL( PTRACERS_diffKh(iTracer), INDEX_NONE,
     &     'PTRACERS_diffKh =', ' /* Laplacian Diffusivity */')
        CALL WRITE_0D_RL( PTRACERS_diffK4(iTracer), INDEX_NONE,
     &     'PTRACERS_diffK4 =', ' /* Biharmonic Diffusivity */')
        CALL WRITE_1D_RL( PTRACERS_diffKrNr(1,iTracer), Nr, INDEX_K,
     &     'PTRACERS_diffKrNr =', ' /* Vertical Diffusivity */')
        CALL WRITE_0D_L( PTRACERS_useGMRedi(iTracer), INDEX_NONE,
     &     'PTRACERS_useGMRedi =', ' /* apply GM-Redi */')
        CALL WRITE_0D_L( PTRACERS_useDWNSLP(iTracer), INDEX_NONE,
     &     'PTRACERS_useDWNSLP =', ' /* apply DOWN-SLOPE Flow */')
        CALL WRITE_0D_L( PTRACERS_useKPP(iTracer), INDEX_NONE,
     &     'PTRACERS_useKPP =', ' /* apply KPP scheme */')
        CALL WRITE_1D_RL( PTRACERS_ref(1,iTracer), Nr, INDEX_K,
     &     'PTRACERS_ref =', ' /* Reference vertical profile */')
        CALL WRITE_0D_RL( PTRACERS_EvPrRn(iTracer), INDEX_NONE,
     &     'PTRACERS_EvPrRn =', '/* tracer conc. in Evap. & Rain */')
        CALL WRITE_0D_RL( PTRACERS_ROFF(iTracer), INDEX_NONE,
     &     'PTRACERS_ROFF =', '/* tracer conc. in runoff */')
        CALL WRITE_0D_RL( PTRACERS_PREC(iTracer), INDEX_NONE,
     &     'PTRACERS_PREC =', '/* tracer conc. in runoff */')
        CALL WRITE_0D_RL( PTRACERS_EVAP(iTracer), INDEX_NONE,
     &     'PTRACERS_EVAP =', '/* tracer conc. in runoff */')
        CALL WRITE_0D_RL( PTRACERS_SHFW(iTracer), INDEX_NONE,
     &     'PTRACERS_SHFW =', '/* tracer conc. in runoff */')
        CALL WRITE_0D_RL( PTRACERS_SICEhr(iTracer), INDEX_NONE,
     &     'PTRACERS_SICEhr =', '/* tracer conc. in runoff */')
        CALL WRITE_0D_RL( PTRACERS_SICEph(iTracer), INDEX_NONE,
     &     'PTRACERS_SICEph =', '/* tracer conc. in runoff */')

      ENDDO
        WRITE(msgBuf,'(A)') ' -----------------------------------'
        CALL PRINT_MESSAGE( msgBuf, iUnit, SQUEEZE_RIGHT, myThid )

      _END_MASTER(myThid)
C     Everyone else must wait for the parameters to be loaded
      _BARRIER

#endif /* ALLOW_PTRACERS */

      RETURN
      END

C $Header: /u/gcmpack/MITgcm/pkg/ptracers/ptracers_forcing_surf.F,v 1.10 2010/09/05 22:28:14 jmc Exp $
C $Name: checkpoint62r $

#include "PTRACERS_OPTIONS.h"

CBOP
C !ROUTINE: PTRACERS_FORCING_SURF

C !INTERFACE: ==========================================================
      SUBROUTINE PTRACERS_FORCING_SURF(
     I                            relaxForcingS,
     I                            bi, bj, iMin, iMax, jMin, jMax,
     I                            myTime,myIter,myThid )

C !DESCRIPTION:
C     Precomputes surface forcing term for pkg/ptracers.
C     Precomputation is needed because of non-local KPP transport term,
C     routine KPP_TRANSPORT_PTR.

C !USES: ===============================================================
      IMPLICIT NONE
#include "SIZE.h"
#include "EEPARAMS.h"
#include "PARAMS.h"
#include "GRID.h"
#include "SURFACE.h"
#include "DYNVARS.h"
#include "FFIELDS.h"
#include "PTRACERS_SIZE.h"
#include "PTRACERS_PARAMS.h"
#include "PTRACERS_FIELDS.h"
#include "SHELFICE.h"

C !INPUT PARAMETERS: ===================================================
C  relaxForcingS        :: Salt forcing due to surface relaxation
C  bi,bj                :: tile indices
C  myTime               :: model time
C  myIter               :: time-step number
C  myThid               :: thread number
      _RL relaxForcingS(1-OLx:sNx+OLx,1-OLy:sNy+OLy)
      INTEGER bi, bj, iMin, iMax, jMin, jMax
      _RL myTime
      INTEGER myIter
      INTEGER myThid
#ifdef ALLOW_PTRACERS

C !LOCAL VARIABLES: ====================================================
C  i,j                  :: loop indices
C  iTrc                 :: tracer index
C  ks                   :: surface level index
      INTEGER i, j
      INTEGER iTrc, ks
      _RL add2EmP(1-OLx:sNx+OLx,1-OLy:sNy+OLy)
      _RL epsil, cutoff, tmpVar
CEOP

      IF ( usingPCoords ) THEN
        ks = Nr
      ELSE
        ks = 1
      ENDIF

C Example of how to add forcing at the surface
      DO iTrc=1,PTRACERS_numInUse
          DO j = jMin, jMax
           DO i = iMin, iMax
             surfaceForcingPTr(i,j,bi,bj,iTrc) =
     &               0. _d 0
c    &               surfaceForcingS(i,j,bi,bj)
           ENDDO
          ENDDO
      ENDDO

C--   Option to convert Salt-relaxation into additional EmP contribution
      IF ( PTRACERS_addSrelax2EmP ) THEN
C-    here we assume that salt_EvPrRn = 0
C     set cutoff value to prevent too large additional EmP:
C       current limit is set to 0.1 CFL
        epsil = 1. _d -10
        cutoff = 0.1 _d 0 *drF(ks)/PTRACERS_dTLev(ks)
        IF ( ( (nonlinFreeSurf.GT.0 .OR. usingPCoords)
     &         .AND. useRealFreshWaterFlux )
     &     .OR.convertFW2Salt .EQ. -1. ) THEN
         DO j = jMin, jMax
          DO i = iMin, iMax
            tmpVar = MAX( salt(i,j,ks,bi,bj), epsil )
            add2EmP(i,j) = relaxForcingS(i,j)/tmpVar
            add2EmP(i,j) = rUnit2mass
     &                  *MAX( -cutoff, MIN( add2EmP(i,j), cutoff ) )
          ENDDO
         ENDDO
        ELSE
         DO j = jMin, jMax
          DO i = iMin, iMax
            add2EmP(i,j) = relaxForcingS(i,j)/convertFW2Salt
            add2EmP(i,j) = rUnit2mass
     &                  *MAX( -cutoff, MIN( add2EmP(i,j), cutoff ) )
          ENDDO
         ENDDO
        ENDIF
#ifdef ALLOW_DIAGNOSTICS
        IF ( useDiagnostics ) THEN
         CALL DIAGNOSTICS_FILL(add2EmP,'Add2EmP ',0,1,2,bi,bj,myThid)
        ENDIF
#endif /* ALLOW_DIAGNOSTICS */
      ELSE
        DO j = jMin, jMax
          DO i = iMin, iMax
            add2EmP(i,j) = 0. _d 0
          ENDDO
        ENDDO
      ENDIF
C-- end of "addEmP" setting

#ifdef EXACT_CONSERV
      IF ( (nonlinFreeSurf.GT.0 .OR. usingPCoords)
     &     .AND. useRealFreshWaterFlux ) THEN

       DO iTrc=1,PTRACERS_numInUse

c-  NonLin_FrSurf and RealFreshWaterFlux : PmEpR effectively changes
c   the water column height ; temp., salt, (tracer) flux associated
c   with this input/output of water is added here to the surface tendency.
c
         IF (PTRACERS_EvPrRn(iTrc).NE.UNSET_RL) THEN
          DO j = jMin, jMax
           DO i = iMin, iMax
             surfaceForcingPTr(i,j,bi,bj,iTrc) =
     &          surfaceForcingPTr(i,j,bi,bj,iTrc)
     &        + ( PmEpR(i,j,bi,bj) - add2EmP(i,j) )
     &          *( PTRACERS_EvPrRn(iTrc) - pTracer(i,j,ks,bi,bj,iTrc) )
     &          *mass2rUnit
           ENDDO
          ENDDO
         ENDIF

       ENDDO

C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|
      ELSE
#else /* EXACT_CONSERV */
      IF (.TRUE.) THEN
#endif /* EXACT_CONSERV */

C--   EmPmR does not really affect the water column height (for tracer budget)
C     and is converted to a salt tendency.

       IF (convertFW2Salt .EQ. -1.) THEN
C-    use local surface tracer field to calculate forcing term:

        DO iTrc=1,PTRACERS_numInUse

         IF (PTRACERS_EvPrRn(iTrc).NE.UNSET_RL) THEN
C         print *, 'HR ptr EvPrRn iTrc ', iTrc
C        account for Rain/Evap tracer content (PTRACERS_EvPrRn) using
C        local surface tracer
            DO j = jMin, jMax
             DO i = iMin, iMax
          IF ( ktopC(i,j,bi,bj) .EQ. ks ) THEN 
              surfaceForcingPTr(i,j,bi,bj,iTrc) =
     &            surfaceForcingPTr(i,j,bi,bj,iTrc)
     &        + (( EmPmR(i,j,bi,bj) + add2EmP(i,j) )
     &          *( pTracer(i,j,ks,bi,bj,iTrc) - PTRACERS_EvPrRn(iTrc) )
     &          + ( shelfIceFreshwaterFlux(i,j,bi,bj) + add2EmP(i,j) )
     &            *( pTracer(i,j,ks,bi,bj,iTrc) -PTRACERS_EvPrRn(iTrc)))
     &            *mass2rUnit
          ELSE
            surfaceForcingPTr(i,j,bi,bj,iTrc) = 
     &         surfaceForcingPTr(i,j,bi,bj,iTrc)
     &        + (( EmPmR(i,j,bi,bj) + add2EmP(i,j) )
     &          *( pTracer(i,j,ks,bi,bj,iTrc) - PTRACERS_EvPrRn(iTrc) )
     &        + shelfIceFreshWaterFlux(i,j,bi,bj)
     &        *( pTracer(i,j,ktopC(i,j,bi,bj),bi,bj,iTrc)
     &       - PTRACERS_EvPrRn(iTrc) ))*mass2rUnit  
          ENDIF
         ENDDO  
        ENDDO
       ENDIF

         IF (PTRACERS_ROFF(iTrc).NE.UNSET_RL) THEN
C        account for Runoff tracer content (PTRACERS_RUNOFF) using
C        local surface tracer
C          print *, 'HR forc ROFF ', -ROFF(25,50,1,1)
          DO j = jMin, jMax
           DO i = iMin, iMax
            surfaceForcingPTr(i,j,bi,bj,iTrc) =
     &          surfaceForcingPTr(i,j,bi,bj,iTrc)
     &        + (( -ROFFhr(i,j,bi,bj) + add2EmP(i,j) )
     &          *( pTracer(i,j,ks,bi,bj,iTrc) - PTRACERS_ROFF(iTrc) )
     &        + ( -PREChr(i,j,bi,bj) + add2EmP(i,j) )
     &          *( pTracer(i,j,ks,bi,bj,iTrc) - 0. _d 0 )
     &        + ( EVAPhr(i,j,bi,bj) + add2EmP(i,j) )
     &          *( pTracer(i,j,ks,bi,bj,iTrc) - 0. _d 0 )
     &        + ( SICEph(i,j,bi,bj) + add2EmP(i,j) )
     &          *( pTracer(i,j,ks,bi,bj,iTrc) - 0. _d 0 )
     &          + ( shelfIceFreshwaterFlux(i,j,bi,bj) + add2EmP(i,j) )
     &            *( pTracer(i,j,ks,bi,bj,iTrc) - 0. _d 0))
     &          *mass2rUnit
           ENDDO
          ENDDO
         ENDIF

         IF (PTRACERS_PREC(iTrc).NE.UNSET_RL) THEN
C        account for precipitation tracer content (PTRACERS_PREC) using
C        local surface tracer
C          print *, 'HR forc PREC ', -PREChr(25,50,1,1)
          DO j = jMin, jMax
           DO i = iMin, iMax
            surfaceForcingPTr(i,j,bi,bj,iTrc) =
     &          surfaceForcingPTr(i,j,bi,bj,iTrc)
     &        + (( -ROFFhr(i,j,bi,bj) + add2EmP(i,j) )
     &          *( pTracer(i,j,ks,bi,bj,iTrc) - 0. _d 0 )
     &        + ( -PREChr(i,j,bi,bj) + add2EmP(i,j) )
     &          *( pTracer(i,j,ks,bi,bj,iTrc) - PTRACERS_PREC(iTrc) )
     &        + ( EVAPhr(i,j,bi,bj) + add2EmP(i,j) )
     &          *( pTracer(i,j,ks,bi,bj,iTrc) - 0. _d 0 )
     &        + ( SICEph(i,j,bi,bj) + add2EmP(i,j) )
     &          *( pTracer(i,j,ks,bi,bj,iTrc) - 0. _d 0 )
     &          + ( shelfIceFreshwaterFlux(i,j,bi,bj) + add2EmP(i,j) )
     &            *( pTracer(i,j,ks,bi,bj,iTrc) - 0. _d 0 ))
     &          *mass2rUnit
           ENDDO
          ENDDO
         ENDIF

         IF (PTRACERS_EVAP(iTrc).NE.UNSET_RL) THEN
C        account for evaporation tracer content (PTRACERS_EVAP) using
C        local surface tracer
C          print *, 'HR forc EVAP ', -EVAPhr(25,50,1,1)
          DO j = jMin, jMax
           DO i = iMin, iMax
            surfaceForcingPTr(i,j,bi,bj,iTrc) =
     &          surfaceForcingPTr(i,j,bi,bj,iTrc)
     &        + (( -ROFFhr(i,j,bi,bj) + add2EmP(i,j) )
     &          *( pTracer(i,j,ks,bi,bj,iTrc) - 0. _d 0 )
     &        + ( -PREChr(i,j,bi,bj) + add2EmP(i,j) )
     &          *( pTracer(i,j,ks,bi,bj,iTrc) - 0. _d 0 )
     &        + ( EVAPhr(i,j,bi,bj) + add2EmP(i,j) )
     &          *( pTracer(i,j,ks,bi,bj,iTrc) - PTRACERS_EVAP(iTrc) )
     &        + ( SICEph(i,j,bi,bj) + add2EmP(i,j) )
     &          *( pTracer(i,j,ks,bi,bj,iTrc) - 0. _d 0 )
     &          + ( shelfIceFreshwaterFlux(i,j,bi,bj) + add2EmP(i,j) )
     &            *( pTracer(i,j,ks,bi,bj,iTrc) - 0. _d 0 ))
     &          *mass2rUnit
           ENDDO
          ENDDO
         ENDIF

         IF (PTRACERS_SICEph(iTrc).NE.UNSET_RL) THEN
C        account for sea ice tracer content (PTRACERS_EVAP) using
C        local surface tracer
C          print *, 'HR forc EVAP ', -EVAPhr(25,50,1,1)
          DO j = jMin, jMax
           DO i = iMin, iMax
            surfaceForcingPTr(i,j,bi,bj,iTrc) =
     &          surfaceForcingPTr(i,j,bi,bj,iTrc)
     &        + (( -ROFFhr(i,j,bi,bj) + add2EmP(i,j) )
     &          *( pTracer(i,j,ks,bi,bj,iTrc) - 0. _d 0 )
     &        + ( -PREChr(i,j,bi,bj) + add2EmP(i,j) )
     &          *( pTracer(i,j,ks,bi,bj,iTrc) - 0. _d 0 )
     &        + ( EVAPhr(i,j,bi,bj) + add2EmP(i,j) )
     &          *( pTracer(i,j,ks,bi,bj,iTrc) - 0. _d 0 )
     &        + ( SICEph(i,j,bi,bj) + add2EmP(i,j) )
     &          *( pTracer(i,j,ks,bi,bj,iTrc) - PTRACERS_SICEph(iTrc) )
     &          + ( shelfIceFreshwaterFlux(i,j,bi,bj) + add2EmP(i,j) )
     &            *( pTracer(i,j,ks,bi,bj,iTrc) - 0. _d 0 ))
     &          *mass2rUnit
           ENDDO
          ENDDO
         ENDIF

         IF (PTRACERS_SHFW(iTrc).NE.UNSET_RL) THEN
C          account for shelf ice tracer content (PTRACERS_RUNOFF) using
C          local surface tracer
            DO j = jMin, jMax
             DO i = iMin, iMax
          IF ( ktopC(i,j,bi,bj) .EQ. ks ) THEN 
              surfaceForcingPTr(i,j,bi,bj,iTrc) =
     &            surfaceForcingPTr(i,j,bi,bj,iTrc)
     &        + (( -ROFFhr(i,j,bi,bj) + add2EmP(i,j) )
     &          *( pTracer(i,j,ks,bi,bj,iTrc) - 0. _d 0 )
     &        + ( -PREChr(i,j,bi,bj) + add2EmP(i,j) )
     &          *( pTracer(i,j,ks,bi,bj,iTrc) - 0. _d 0 )
     &        + ( EVAPhr(i,j,bi,bj) + add2EmP(i,j) )
     &          *( pTracer(i,j,ks,bi,bj,iTrc) - 0. _d 0 )
     &        + ( SICEph(i,j,bi,bj) + add2EmP(i,j) )
     &          *( pTracer(i,j,ks,bi,bj,iTrc) - 0. _d 0 )
     &          + ( shelfIceFreshwaterFlux(i,j,bi,bj) + add2EmP(i,j) )
     &            *( pTracer(i,j,ks,bi,bj,iTrc) - PTRACERS_SHFW(iTrc) ))
     &            *mass2rUnit
          ELSE
            surfaceForcingPTr(i,j,bi,bj,iTrc) = 
     &         surfaceForcingPTr(i,j,bi,bj,iTrc)
     &        + (( -ROFFhr(i,j,bi,bj) + add2EmP(i,j) )
     &          *( pTracer(i,j,ks,bi,bj,iTrc) - 0. _d 0 )
     &        + ( -PREChr(i,j,bi,bj) + add2EmP(i,j) )
     &          *( pTracer(i,j,ks,bi,bj,iTrc) - 0. _d 0 )
     &        + ( EVAPhr(i,j,bi,bj) + add2EmP(i,j) )
     &          *( pTracer(i,j,ks,bi,bj,iTrc) - 0. _d 0 )
     &        + ( SICEph(i,j,bi,bj) + add2EmP(i,j) )
     &          *( pTracer(i,j,ks,bi,bj,iTrc) - 0. _d 0 )
     &        + shelfIceFreshWaterFlux(i,j,bi,bj)
     &        *( pTracer(i,j,ktopC(i,j,bi,bj),bi,bj,iTrc)
     &       - PTRACERS_SHFW(iTrc) ))*mass2rUnit  
          ENDIF
         
             ENDDO
            ENDDO
C          CALL WRITE_FLD_XYZ_RS('HRshptr','',pTracer,0,myThid)
C         CALL WRITE_FLD_XY_RS('HRktopC','',ktopC,0,myThid)
        ENDIF

        ENDDO

       ELSE
C-    use uniform tracer value to calculate forcing term:

        DO iTrc=1,PTRACERS_numInUse

         IF (PTRACERS_EvPrRn(iTrc).NE.UNSET_RL) THEN
C     account for Rain/Evap tracer content (PTRACERS_EvPrRn) assuming uniform
C     surface tracer (=PTRACERS_ref)
          DO j = jMin, jMax
           DO i = iMin, iMax
            surfaceForcingPTr(i,j,bi,bj,iTrc) =
     &          surfaceForcingPTr(i,j,bi,bj,iTrc)
     &        + ( EmPmR(i,j,bi,bj) + add2EmP(i,j) )
     &            *( PTRACERS_ref(ks,iTrc) - PTRACERS_EvPrRn(iTrc) )
     &            *mass2rUnit
           ENDDO
          ENDDO
         ENDIF

        ENDDO

C-    end local-surface-tracer / uniform-value distinction
       ENDIF

      ENDIF

C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|

#endif /* ALLOW_PTRACERS */

      RETURN
      END

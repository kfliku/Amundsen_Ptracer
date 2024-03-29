C $Header: /u/gcmpack/MITgcm/pkg/ptracers/PTRACERS_FIELDS.h,v 1.1 2007/11/05 18:48:04 jmc Exp $
C $Name: checkpoint62r $

#ifdef ALLOW_PTRACERS

CBOP
C    !ROUTINE: PTRACERS_FIELDS.h
C    !INTERFACE:
C #include PTRACERS_FIELDS.h

C    !DESCRIPTION:
C Contains passive tracer fields

CEOP

C     COMMON /PTRACERS_FIELDS/
C     pTracer  :: passive tracer concentration (tr per unit volume).
C     gPtr     :: work-space for time-stepping
C     gpTrNm1  :: work-space for time-stepping
C     surfaceForcingPTr :: passive tracer surface forcing
      _RL  pTracer (1-OLx:sNx+OLx,1-OLy:sNy+OLy,Nr,nSx,nSy,
     &              PTRACERS_num)
      _RL  gPtr    (1-OLx:sNx+OLx,1-OLy:sNy+OLy,Nr,nSx,nSy,
     &              PTRACERS_num)
      _RL  gpTrNm1 (1-OLx:sNx+OLx,1-OLy:sNy+OLy,Nr,nSx,nSy,
     &              PTRACERS_num)
      _RL  surfaceForcingPTr (1-OLx:sNx+OLx,1-OLy:sNy+OLy,nSx,nSy,
     &              PTRACERS_num)
      COMMON /PTRACERS_FIELDS/
     &              pTracer, gPtr, gpTrNm1, surfaceForcingPTr

      _RL totSurfCorPTr(PTRACERS_num)
      _RL meanSurfCorPTr(PTRACERS_num)
      COMMON /PTRACERS_SURFCOR_FIELDS/ totSurfCorPTr, meanSurfCorPTr

#endif /* ALLOW_PTRACERS */

CEH3 ;;; Local Variables: ***
CEH3 ;;; mode:fortran ***
CEH3 ;;; End: ***

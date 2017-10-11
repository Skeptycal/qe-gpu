!
! Copyright (C) 2001-2007 Quantum ESPRESSO group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!
!----------------------------------------------------------------------
subroutine init_vloc()
  !----------------------------------------------------------------------
  !
  !    This routine computes the fourier coefficient of the local
  !    potential vloc(ig,it) for each type of atom
  !
  USE atom,       ONLY : msh, rgrid
  USE m_gth,      ONLY : vloc_gth
  USE kinds,      ONLY : dp
  USE uspp_param, ONLY : upf
  USE ions_base,  ONLY : ntyp => nsp
  USE cell_base,  ONLY : omega, tpiba2
  USE vlocal,     ONLY : vloc
#ifdef USE_CUDA
  USE vlocal,     ONLY : vloc_d
#endif
  USE gvect,      ONLY : ngl, gl
  !
  implicit none
  !
  integer :: nt
  ! counter on atomic types
  !
  call start_clock ('init_vloc')
  vloc(:,:) = 0._dp
  do nt = 1, ntyp
     !
     ! compute V_loc(G) for a given type of atom
     !
     IF ( .NOT. ASSOCIATED ( upf(nt)%vloc ) ) THEN
        !
        IF ( upf(nt)%is_gth ) THEN
           !
           ! special case: GTH pseudopotential
           !
           call vloc_gth (nt, upf(nt)%zp, tpiba2, ngl, gl, omega, vloc (1, nt) )
           !
        ELSE
           !
           ! special case: pseudopotential is coulomb 1/r potential
           !
           call vloc_coul (upf(nt)%zp, tpiba2, ngl, gl, omega, vloc (1, nt) )
           !
        END IF
        !
     ELSE
        !
        ! normal case
        !
        call vloc_of_g (rgrid(nt)%mesh, msh (nt), rgrid(nt)%rab, rgrid(nt)%r, &
            upf(nt)%vloc(1), upf(nt)%zp, tpiba2, ngl, gl, omega, vloc (1, nt) )
        !
     END IF
  enddo

#ifdef USE_CUDA
 if(.not. allocated(vloc_d)) then
   ALLOCATE(vloc_d, source=vloc)
 else
   vloc_d = vloc
 endif

#endif
  call stop_clock ('init_vloc')
  return
end subroutine init_vloc


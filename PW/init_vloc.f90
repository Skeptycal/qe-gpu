!
! Copyright (C) 2001 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!
!----------------------------------------------------------------------
subroutine init_vloc
  !----------------------------------------------------------------------
  !
  !    This routine computes the fourier coefficient of the local
  !    potential vloc(ig,it) for each type of atom
  !
#include"machine.h"

  use pwcom
  implicit none
  integer :: nt
  ! counter on atomic types
  !

  call start_clock ('init_vloc')
  vloc(:,:) = 0.d0
  do nt = 1, ntyp
     !
     ! compute V_loc(G) for a given type of atom
     !
     call vloc_of_g (lloc (nt), lmax (nt), numeric (nt), mesh (nt), &
          msh (nt), rab (1, nt), r (1, nt), vnl (1, lloc (nt), nt), cc (1, &
          nt), alpc (1, nt), nlc (nt), nnl (nt), zp (nt), aps (1, 0, nt), &
          alps (1, 0, nt), tpiba2, ngl, gl, omega, vloc (1, nt) )

  enddo
  call stop_clock ('init_vloc')
  return
end subroutine init_vloc


!
! Copyright (C) 2001 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!
!---------------------------------------------------------------------
subroutine symdvscf (nper, irr, dvtosym)
  !---------------------------------------------------------------------
  ! symmetrize the self-consistent potential of the perturbations
  ! belonging to an irreproducible representation
  !
#include"machine.h"

  use pwcom
  use parameters, only : DP
  use phcom
  implicit none

  integer :: nper, irr
  ! the number of perturbations
  ! the representation under conside

  complex(kind=DP) :: dvtosym (nrx1, nrx2, nrx3, nspin, nper)
  ! the potential to symmetriz

  integer :: is, ri, rj, rk, i, j, k, ipert, jpert, ipol, isym, &
       irot
  !  counter on spin polarizations
  !
  !  the rotated points
  !
  !
  !  counter on mesh points
  !
  ! counter on perturbations
  ! counter on perturbations
  ! counter on polarizations
  ! counter on symmetries
  ! the rotation

  real(kind=DP) :: g1 (48), g2 (48), g3 (48), in1, in2, in3
  ! used to construct the phases
  ! used to construct the phases
  ! used to construct the phases
  ! auxiliary variables


  complex(kind=DP), allocatable :: dvsym (:,:,:,:)
  complex(kind=DP) ::  aux2, term (3, 48) &
       , phase (48)
  ! the symmetrized potenti
  ! auxiliary space
  ! the multiplication factor
  ! the phase factor

  if (nsymq.eq.1.and. (.not.minus_q) ) return
  call start_clock ('symdvscf')

  allocate (dvsym(  nrx1 , nrx2 , nrx3 , nper))    
  !
  ! if necessary we symmetrize with respect to  S(irotmq)*q = -q + Gi
  !
  in1 = tpi / float (nr1)
  in2 = tpi / float (nr2)
  in3 = tpi / float (nr3)
  if (minus_q) then
     g1 (1) = 0.d0
     g2 (1) = 0.d0
     g3 (1) = 0.d0
     do ipol = 1, 3
        g1 (1) = g1 (1) + gimq (ipol) * in1 * at (ipol, 1)
        g2 (1) = g2 (1) + gimq (ipol) * in2 * at (ipol, 2)
        g3 (1) = g3 (1) + gimq (ipol) * in3 * at (ipol, 3)
     enddo
     term (1, 1) = DCMPLX (cos (g1 (1) ), sin (g1 (1) ) )
     term (2, 1) = DCMPLX (cos (g2 (1) ), sin (g2 (1) ) )

     term (3, 1) = DCMPLX (cos (g3 (1) ), sin (g3 (1) ) )
     do is = 1, nspin
        phase (1) = (1.d0, 0.d0)
        do k = 1, nr3
           do j = 1, nr2
              do i = 1, nr1
                 ri = s (1, 1, irotmq) * (i - 1) + s (2, 1, irotmq) * (j - 1) &
                      + s (3, 1, irotmq) * (k - 1) - ftau (1, irotmq)
                 ri = mod (ri, nr1) + 1
                 if (ri.lt.1) ri = ri + nr1
                 rj = s (1, 2, irotmq) * (i - 1) + s (2, 2, irotmq) * (j - 1) &
                      + s (3, 2, irotmq) * (k - 1) - ftau (2, irotmq)
                 rj = mod (rj, nr2) + 1
                 if (rj.lt.1) rj = rj + nr2
                 rk = s (1, 3, irotmq) * (i - 1) + s (2, 3, irotmq) * (j - 1) &
                      + s (3, 3, irotmq) * (k - 1) - ftau (3, irotmq)
                 rk = mod (rk, nr3) + 1

                 if (rk.lt.1) rk = rk + nr3
                 do ipert = 1, nper
                    aux2 = (0.d0, 0.d0)
                    do jpert = 1, nper
                       aux2 = aux2 + tmq (jpert, ipert, irr) * dvtosym (ri, rj, rk, &
                            is, jpert) * phase (1)
                    enddo
                    dvsym (i, j, k, ipert) = (dvtosym (i, j, k, is, ipert) + conjg &
                         (aux2) ) * 0.5d0
                 enddo
                 phase (1) = phase (1) * term (1, 1)
              enddo
              phase (1) = phase (1) * term (2, 1)
           enddo
           phase (1) = phase (1) * term (3, 1)
        enddo
        do ipert = 1, nper
           call ZCOPY (nrx1 * nrx2 * nrx3, dvsym (1, 1, 1, ipert), &
                1, dvtosym (1, 1, 1, is, ipert), 1)
        enddo
     enddo
  endif
  !
  ! Here we symmetrize with respect to the small group of q
  !
  do isym = 1, nsymq
     g1 (isym) = 0.d0
     g2 (isym) = 0.d0
     g3 (isym) = 0.d0
     do ipol = 1, 3
        g1 (isym) = g1 (isym) + gi (ipol, isym) * in1 * at (ipol, 1)
        g2 (isym) = g2 (isym) + gi (ipol, isym) * in2 * at (ipol, 2)
        g3 (isym) = g3 (isym) + gi (ipol, isym) * in3 * at (ipol, 3)
     enddo
     term (1, isym) = DCMPLX (cos (g1 (isym) ), sin (g1 (isym) ) )
     term (2, isym) = DCMPLX (cos (g2 (isym) ), sin (g2 (isym) ) )
     term (3, isym) = DCMPLX (cos (g3 (isym) ), sin (g3 (isym) ) )

  enddo
  do is = 1, nspin
     call setv (2 * nrx1 * nrx2 * nrx3 * nper, 0.d0, dvsym, 1)
     do isym = 1, nsymq
        phase (isym) = (1.d0, 0.d0)
     enddo
     do k = 1, nr3
        do j = 1, nr2
           do i = 1, nr1
              do isym = 1, nsymq
                 irot = irgq (isym)
                 ri = s (1, 1, irot) * (i - 1) + s (2, 1, irot) * (j - 1) + s (3, &
                      1, irot) * (k - 1) - ftau (1, irot)
                 ri = mod (ri, nr1) + 1
                 if (ri.lt.1) ri = ri + nr1
                 rj = s (1, 2, irot) * (i - 1) + s (2, 2, irot) * (j - 1) + s (3, &
                      2, irot) * (k - 1) - ftau (2, irot)
                 rj = mod (rj, nr2) + 1
                 if (rj.lt.1) rj = rj + nr2
                 rk = s (1, 3, irot) * (i - 1) + s (2, 3, irot) * (j - 1) + s (3, &
                      3, irot) * (k - 1) - ftau (3, irot)
                 rk = mod (rk, nr3) + 1

                 if (rk.lt.1) rk = rk + nr3
                 do ipert = 1, nper
                    do jpert = 1, nper
                       dvsym (i, j, k, ipert) = dvsym (i, j, k, ipert) + t (jpert, ipert, &
                            irot, irr) * dvtosym (ri, rj, rk, is, jpert) * phase (isym)
                    enddo
                 enddo
              enddo
              do isym = 1, nsymq
                 phase (isym) = phase (isym) * term (1, isym)
              enddo
           enddo
           do isym = 1, nsymq
              phase (isym) = phase (isym) * term (2, isym)
           enddo
        enddo
        do isym = 1, nsymq
           phase (isym) = phase (isym) * term (3, isym)
        enddo
     enddo

     call DSCAL (2 * nrx1 * nrx2 * nrx3 * nper, 1.d0 / float (nsymq), &
          dvsym, 1)
     do ipert = 1, nper
        call ZCOPY (nrx1 * nrx2 * nrx3, dvsym (1, 1, 1, ipert), 1, &
             dvtosym (1, 1, 1, is, ipert), 1)
     enddo

  enddo
  deallocate (dvsym)

  call stop_clock ('symdvscf')
  return
end subroutine symdvscf

!
! Copyright (C) 2001 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!
!----------------------------------------------------------------------
subroutine gen_us_dj (ik, dvkb)
  !----------------------------------------------------------------------
  !
  !   Calculates the beta function pseudopotentials with
  !   the derivative of the Bessel functions
  !
  USE kinds,      ONLY : DP
  USE constants,  ONLY : tpi
  USE ions_base,  ONLY : nat, ntyp => nsp, ityp, tau
  USE cell_base,  ONLY : tpiba
  USE klist,      ONLY : xk, ngk, igk_k
  USE gvect,      ONLY : mill, eigts1, eigts2, eigts3, g
  USE wvfct,      ONLY : npwx
  USE uspp,       ONLY : nkb, indv, nhtol, nhtolm
  USE us,         ONLY : nqx, tab, tab_d2y, dq, spline_ps
  USE m_gth,      ONLY : mk_dffnl_gth
  USE splinelib
  USE uspp_param, ONLY : upf, lmaxkb, nbetam, nh
  !
  implicit none
  !
  integer, intent(in) :: ik
  complex(DP), intent(out) :: dvkb (npwx, nkb)
  !
  ! local variables
  !
  integer :: npw, ikb, nb, ih, ig, i0, i1, i2, i3 , nt
  ! counter on beta functions
  ! counter on beta functions
  ! counter on beta functions
  ! counter on G vectors
  ! index of the first nonzero point in the r
  ! counter on atomic type

  real(DP) :: arg, px, ux, vx, wx
  ! argument of the atomic phase factor

  complex(DP) :: phase, pref
  ! atomic phase factor
  ! prefactor

  integer :: na, l, iig, lm, iq
  real(DP), allocatable :: djl (:,:,:), ylm (:,:), q (:), gk (:,:)
  real(DP) ::  qt
  complex(DP), allocatable :: sk (:)
  real(DP), allocatable :: xdata(:)

  if (nkb.eq.0) return


  npw = ngk(ik)
  allocate (djl( npw , nbetam , ntyp))    
  allocate (ylm( npw ,(lmaxkb + 1) **2))    
  allocate (gk( 3, npw))    
  allocate (q( npw))    
  do ig = 1, npw
     iig = igk_k(ig,ik)
     gk (1,ig) = xk (1, ik) + g(1, iig)
     gk (2,ig) = xk (2, ik) + g(2, iig)
     gk (3,ig) = xk (3, ik) + g(3, iig)
     q (ig) = gk(1, ig)**2 +  gk(2, ig)**2 + gk(3, ig)**2
  enddo

  call ylmr2 ((lmaxkb+1)**2, npw, gk, q, ylm)

  if (spline_ps) then
    allocate(xdata(nqx))
    do iq = 1, nqx
      xdata(iq) = (iq - 1) * dq
    enddo
  endif

  do nt = 1, ntyp
     do nb = 1, upf(nt)%nbeta
        if ( upf(nt)%is_gth ) then
           call mk_dffnl_gth( nt, nb, npw, q, djl(1,nb,nt) )
           cycle
        endif
        do ig = 1, npw
           qt = sqrt(q (ig)) * tpiba
           if (spline_ps) then
             djl(ig,nb,nt) = splint_deriv(xdata, tab(:,nb,nt), & 
                                                 tab_d2y(:,nb,nt), qt)
           else
             px = qt / dq - int (qt / dq)
             ux = 1.d0 - px
             vx = 2.d0 - px
             wx = 3.d0 - px
             i0 = qt / dq + 1
             i1 = i0 + 1
             i2 = i0 + 2
             i3 = i0 + 3
             djl(ig,nb,nt) = ( tab (i0, nb, nt) * (-vx*wx-ux*wx-ux*vx)/6.d0 + &
                               tab (i1, nb, nt) * (+vx*wx-px*wx-px*vx)/2.d0 - &
                               tab (i2, nb, nt) * (+ux*wx-px*wx-px*ux)/2.d0 + &
                               tab (i3, nb, nt) * (+ux*vx-px*vx-px*ux)/6.d0 )/dq
           endif
        enddo
     enddo
  enddo

  deallocate (q)
  deallocate (gk)

  allocate (sk( npw))    
  ikb = 0
  do nt = 1, ntyp
     do na = 1, nat
        if (ityp (na) .eq.nt) then
           arg = (xk (1, ik) * tau(1,na) + &
                  xk (2, ik) * tau(2,na) + &
                  xk (3, ik) * tau(3,na) ) * tpi
           phase = CMPLX(cos (arg), - sin (arg) ,kind=DP)
           do ig = 1, npw
              iig = igk_k (ig,ik)
              sk (ig) = eigts1 (mill (1,iig), na) * &
                        eigts2 (mill (2,iig), na) * &
                        eigts3 (mill (3,iig), na) * phase
           enddo
           do ih = 1, nh (nt)
              nb = indv (ih, nt)
              l = nhtol (ih, nt)
              lm= nhtolm(ih, nt)
              ikb = ikb + 1
              pref = (0.d0, -1.d0) **l
              !
              do ig = 1, npw
                 dvkb (ig, ikb) = djl (ig, nb, nt) * sk (ig) * ylm (ig, lm) &
                      * pref
              enddo
           enddo
        endif
     enddo

  enddo

  if (ikb.ne.nkb) call errore ('gen_us_dj', 'unexpected error', 1)
  deallocate (sk)
  deallocate (ylm)
  deallocate (djl)
  if (spline_ps) deallocate(xdata)
  return
end subroutine gen_us_dj

#ifdef USE_CUDA

!----------------------------------------------------------------------
subroutine gen_us_dj_gpu (ik, dvkb)
  !----------------------------------------------------------------------
  !
  !   Calculates the beta function pseudopotentials with
  !   the derivative of the Bessel functions
  !
  USE kinds,      ONLY : DP
  USE constants,  ONLY : tpi
  USE ions_base,  ONLY : nat, ntyp => nsp, ityp, tau
  USE cell_base,  ONLY : tpiba
  USE klist,      ONLY : xk, ngk, igk_k_d
  USE gvect,      ONLY : mill_d, eigts1_d, eigts2_d, eigts3_d, g_d
  USE wvfct,      ONLY : npwx
  USE uspp,       ONLY : nkb, indv, nhtol, nhtolm
  USE us,         ONLY : nqx, tab_d, tab_d2y_d, dq, spline_ps
  USE m_gth,      ONLY : mk_dffnl_gth
  USE splinelib
  USE uspp_param, ONLY : upf, lmaxkb, nbetam, nh
  USE cudafor
  USE cublas
  USE ylmr2_gpu,  ONLY : ylmr2_d
  !
  implicit none
  !
  integer, intent(in) :: ik
  complex(DP), device, intent(out) :: dvkb (npwx, nkb)
  !
  ! local variables
  !
  integer :: npw, ikb, nb, ih, ig, i0, i1, i2, i3 , nt
  ! counter on beta functions
  ! counter on beta functions
  ! counter on beta functions
  ! counter on G vectors
  ! index of the first nonzero point in the r
  ! counter on atomic type

  real(DP) :: arg, px, ux, vx, wx
  ! argument of the atomic phase factor

  complex(DP) :: phase, pref
  ! atomic phase factor
  ! prefactor

  integer :: na, l, iig, lm, iq
  real(DP), allocatable, device :: djl (:,:,:), ylm (:,:), q (:), gk (:,:), qt_d(:)
  real(DP) ::  qt
  complex(DP), allocatable, device :: sk (:)
  real(DP), allocatable :: xdata(:)
  real(DP) :: xk1, xk2, xk3

  if (nkb.eq.0) return


  npw = ngk(ik)
  allocate (djl( npw , nbetam , ntyp))    
  allocate (ylm( npw ,(lmaxkb + 1) **2))    
  allocate (gk( 3, npw))    
  allocate (q( npw))    
  allocate (qt_d( npw))

  xk1=xk(1,ik)
  xk2=xk(2,ik)
  xk3=xk(3,ik)

  !$cuf kernel do(1) <<<*,*>>>
  do ig = 1, npw
     iig = igk_k_d(ig,ik)
     gk (1, ig) = xk1 + g_d (1,iig)
     gk (2, ig) = xk2 + g_d (2,iig)
     gk (3, ig) = xk3 + g_d (3,iig)
     q (ig) = gk(1, ig)*gk(1, ig) +  gk(2, ig)*gk(2, ig) + gk(3, ig)*gk(3, ig)
  enddo

  call ylmr2_d ((lmaxkb+1)**2, npw, gk, q, ylm)

!  if (spline_ps) then
!    allocate(xdata(nqx))
!    do iq = 1, nqx
!      xdata(iq) = (iq - 1) * dq
!    enddo
!  endif

  !$cuf kernel do(1) <<<*,*>>>
  do ig = 1, npw
     qt_d(ig) = sqrt(q (ig)) * tpiba
  enddo

  do nt = 1, ntyp
     do nb = 1, upf(nt)%nbeta
        if ( upf(nt)%is_gth ) then
           !call mk_dffnl_gth( nt, nb, npw, q, djl(1,nb,nt) )
           !cycle
           CALL errore( 'gen_us_dj_gpu', 'mk_ffnl_gth not implemented on GPU!', 1 )
        else if (spline_ps) then
           call splint_eq_gpu(dq, tab_d(:,nb,nt), tab_d2y_d(:,nb,nt), qt_d, djl(:,nb,nt))
        else
           !$cuf kernel do(1) <<<*,*>>>
           do ig = 1, npw
                qt = qt_d(ig) 
                px = qt / dq - int (qt / dq)
                ux = 1.d0 - px
                vx = 2.d0 - px
                wx = 3.d0 - px
                i0 = qt / dq + 1
                i1 = i0 + 1
                i2 = i0 + 2
                i3 = i0 + 3
                djl(ig,nb,nt) = ( tab_d (i0, nb, nt) * (-vx*wx-ux*wx-ux*vx)/6.d0 + &
                                  tab_d (i1, nb, nt) * (+vx*wx-px*wx-px*vx)/2.d0 - &
                                  tab_d (i2, nb, nt) * (+ux*wx-px*wx-px*ux)/2.d0 + &
                                  tab_d (i3, nb, nt) * (+ux*vx-px*vx-px*ux)/6.d0 )/dq
           enddo

        endif
     enddo
  enddo

  deallocate (q)
  deallocate (gk)
  deallocate (qt_d)

  allocate (sk( npw))    
  ikb = 0
  do nt = 1, ntyp
     do na = 1, nat
        if (ityp (na) .eq.nt) then
           arg = (xk (1, ik) * tau(1,na) + &
                  xk (2, ik) * tau(2,na) + &
                  xk (3, ik) * tau(3,na) ) * tpi
           phase = CMPLX(cos (arg), - sin (arg) ,kind=DP)

           !$cuf kernel do(1) <<<*,*>>>
           do ig = 1, npw
              iig = igk_k_d (ig,ik)
              sk (ig) = eigts1_d (mill_d (1,iig), na) * &
                        eigts2_d (mill_d (2,iig), na) * &
                        eigts3_d (mill_d (3,iig), na) * phase
           enddo
           do ih = 1, nh (nt)
              nb = indv (ih, nt)
              l = nhtol (ih, nt)
              lm= nhtolm(ih, nt)
              ikb = ikb + 1
              pref = (0.d0, -1.d0) **l
              !
              !$cuf kernel do(1) <<<*,*>>>
              do ig = 1, npw
                 dvkb (ig, ikb) = djl (ig, nb, nt) * sk (ig) * ylm (ig, lm) &
                      * pref
              enddo
           enddo
        endif
     enddo

  enddo

  if (ikb.ne.nkb) call errore ('gen_us_dj', 'unexpected error', 1)
  deallocate (sk)
  deallocate (ylm)
  deallocate (djl)
  if (spline_ps) deallocate(xdata)
  return
end subroutine gen_us_dj_gpu

#endif


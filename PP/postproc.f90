!
! Copyright (C) 2001 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!

program postproc

  character :: nodenumber * 3
  call start_postproc (nodenumber)
  call do_postproc (nodenumber)

  call stop_pp
  stop
end program postproc

module FiElec

use paratype
use globals

implicit none

contains


subroutine getInterps_3D(sx, sy, sz2)

use rhs_vars

real(kind=wp), intent(in) :: sx(:), sy(:), sz2(:)

integer(kind=ip) :: xnode, ynode, z2node
integer(kind=ipl) :: i

real(kind=wp) :: locx, locy, locz2, &
                 x_in1, x_in2, y_in1, y_in2, z2_in1, z2_in2

!$OMP DO PRIVATE(xnode, ynode, z2node, locx, locy, locz2, &
!$OMP x_in1, x_in2, y_in1, y_in2, z2_in1, z2_in2)
  do i = 1, maxEl
    if (i<=procelectrons_G(1)) then 


!                  Get surrounding nodes 

      xnode = floor( (sx(i) + halfx ) / dx)  + 1_IP
      locx = sx(i) + halfx - real(xnode  - 1_IP, kind=wp) * dx
      x_in2 = locx / dx
      x_in1 = (1.0_wp - x_in2)

      ynode = floor( (sy(i) + halfy )  / dy)  + 1_IP
      locy = sy(i) + halfy - real(ynode  - 1_IP, kind=wp) * dy
      y_in2 = locy / dy
      y_in1 = (1.0_wp - y_in2)

      z2node = floor(sz2(i)  / dz2)  + 1_IP
      locz2 = sz2(i) - real(z2node  - 1_IP, kind=wp) * dz2
      z2_in2 = locz2 / dz2
      z2_in1 = (1.0_wp - z2_in2)


!                  Get weights for interpolant

      lis_GR(1,i) = x_in1 * y_in1 * z2_in1
      lis_GR(2,i) = x_in2 * y_in1 * z2_in1
      lis_GR(3,i) = x_in1 * y_in2 * z2_in1
      lis_GR(4,i) = x_in2 * y_in2 * z2_in1
      lis_GR(5,i) = x_in1 * y_in1 * z2_in2
      lis_GR(6,i) = x_in2 * y_in1 * z2_in2
      lis_GR(7,i) = x_in1 * y_in2 * z2_in2
      lis_GR(8,i) = x_in2 * y_in2 * z2_in2

    end if
  end do
!$OMP END DO


end subroutine getInterps_3D






!      ##################################################




subroutine getFFelecs_3D(sA)


use rhs_vars

real(kind=wp), intent(in) :: sA(:)
integer(kind=ip) :: i

!$OMP DO
  do i = 1, maxEl
  
    if (i<=procelectrons_G(1)) then

      sField4ElecReal(i) = lis_GR(1,i) * sA(p_nodes(i)) + sField4ElecReal(i)
      sField4ElecReal(i) = lis_GR(2,i) * sA(p_nodes(i) + 1_ip) + sField4ElecReal(i)
      sField4ElecReal(i) = lis_GR(3,i) * sA(p_nodes(i) + ReducedNX_G) + sField4ElecReal(i)
      sField4ElecReal(i) = lis_GR(4,i) * sA(p_nodes(i) + ReducedNX_G + 1_ip) + sField4ElecReal(i)
      sField4ElecReal(i) = lis_GR(5,i) * sA(p_nodes(i) + ntrans) + sField4ElecReal(i)
      sField4ElecReal(i) = lis_GR(6,i) * sA(p_nodes(i) + ntrans + 1_ip) + sField4ElecReal(i)
      sField4ElecReal(i) = lis_GR(7,i) * sA(p_nodes(i) + ntrans + ReducedNX_G) + sField4ElecReal(i)
      sField4ElecReal(i) = lis_GR(8,i) * sA(p_nodes(i) + ntrans + ReducedNX_G + 1) + sField4ElecReal(i)
  
      sField4ElecImag(i) = lis_GR(1,i) * sA(p_nodes(i) + retim) + sField4ElecImag(i)
      sField4ElecImag(i) = lis_GR(2,i) * sA(p_nodes(i) + retim + 1_ip) + sField4ElecImag(i)
      sField4ElecImag(i) = lis_GR(3,i) * sA(p_nodes(i) + retim + ReducedNX_G) + sField4ElecImag(i)
      sField4ElecImag(i) = lis_GR(4,i) * sA(p_nodes(i) + retim + ReducedNX_G + 1_ip) + sField4ElecImag(i)
      sField4ElecImag(i) = lis_GR(5,i) * sA(p_nodes(i) + retim + ntrans) + sField4ElecImag(i)
      sField4ElecImag(i) = lis_GR(6,i) * sA(p_nodes(i) + retim + ntrans + 1_ip) + sField4ElecImag(i)
      sField4ElecImag(i) = lis_GR(7,i) * sA(p_nodes(i) + retim + ntrans + ReducedNX_G) + sField4ElecImag(i)
      sField4ElecImag(i) = lis_GR(8,i) * sA(p_nodes(i) + retim + ntrans + ReducedNX_G + 1) + sField4ElecImag(i)

    end if
  
  end do 
!$OMP END DO

end subroutine getFFelecs_3D



!         ########################################################



subroutine getSource_3D(sDADz, spr, spi)


use rhs_vars

real(kind=wp), intent(inout) :: sDADz(:)
real(kind=wp), intent(in) :: spr(:), spi(:)

integer(kind=ipl) :: i
real(kind=wp) :: dadzRInst, dadzIInst

!$OMP DO PRIVATE(dadzRInst, dadzIInst)
  do i = 1, maxEl
  
    if (i<=procelectrons_G(1)) then


!                  Get 'instantaneous' dAdz

      dadzRInst = ((s_chi_bar_G(i)/dV3) * Lj(i) &
                        * spr(i) )
    
      !$OMP ATOMIC
      sDADz(p_nodes(i)) =                         &
        lis_GR(1,i) * dadzRInst + sDADz(p_nodes(i))
      
      !$OMP ATOMIC
      sDADz(p_nodes(i) + 1_ip) =                  &
        lis_GR(2,i) * dadzRInst + sDADz(p_nodes(i) + 1_ip)                

      !$OMP ATOMIC
      sDADz(p_nodes(i) + ReducedNX_G) =           &
        lis_GR(3,i) * dadzRInst + sDADz(p_nodes(i) + ReducedNX_G)          

      !$OMP ATOMIC
      sDADz(p_nodes(i) + ReducedNX_G + 1_ip) =    &
        lis_GR(4,i) * dadzRInst + sDADz(p_nodes(i) + ReducedNX_G + 1_ip)   

      !$OMP ATOMIC
      sDADz(p_nodes(i) + ntrans) =                &
        lis_GR(5,i) * dadzRInst + sDADz(p_nodes(i) + ntrans)               

      !$OMP ATOMIC
      sDADz(p_nodes(i) + ntrans + 1_ip) =         &
        lis_GR(6,i) * dadzRInst + sDADz(p_nodes(i) + ntrans + 1_ip)         

      !$OMP ATOMIC
      sDADz(p_nodes(i) + ntrans + ReducedNX_G) =  &
        lis_GR(7,i) * dadzRInst + sDADz(p_nodes(i) + ntrans + ReducedNX_G)   

      !$OMP ATOMIC
      sDADz(p_nodes(i) + ntrans + ReducedNX_G + 1) = &
        lis_GR(8,i) * dadzRInst + sDADz(p_nodes(i) + ntrans + ReducedNX_G + 1)

!                   Imaginary part

      dadzIInst = ((s_chi_bar_G(i)/dV3) * Lj(i) &
                        * spi(i) ) 
    
      !$OMP ATOMIC
      sDADz(p_nodes(i) + retim) =                             & 
        lis_GR(1,i) * dadzIInst + sDADz(p_nodes(i) + retim)                        

      !$OMP ATOMIC
      sDADz(p_nodes(i) + 1_ip + retim) =                      & 
        lis_GR(2,i) * dadzIInst + sDADz(p_nodes(i) + 1_ip + retim)           

      !$OMP ATOMIC
      sDADz(p_nodes(i) + ReducedNX_G + retim) =               & 
        lis_GR(3,i) * dadzIInst + sDADz(p_nodes(i) + ReducedNX_G + retim)           

      !$OMP ATOMIC
      sDADz(p_nodes(i) + ReducedNX_G + 1_ip + retim) =        & 
        lis_GR(4,i) * dadzIInst + sDADz(p_nodes(i) + ReducedNX_G + 1_ip + retim)    

      !$OMP ATOMIC
      sDADz(p_nodes(i) + ntrans + retim) =                    & 
        lis_GR(5,i) * dadzIInst + sDADz(p_nodes(i) + ntrans + retim)               

      !$OMP ATOMIC
      sDADz(p_nodes(i) + ntrans + 1_ip + retim) =             & 
        lis_GR(6,i) * dadzIInst + sDADz(p_nodes(i) + ntrans + 1_ip + retim)       

      !$OMP ATOMIC
      sDADz(p_nodes(i) + ntrans + ReducedNX_G + retim) =      & 
        lis_GR(7,i) * dadzIInst + sDADz(p_nodes(i) + ntrans + ReducedNX_G + retim)  

      !$OMP ATOMIC
      sDADz(p_nodes(i) + ntrans + ReducedNX_G + 1 + retim) =  & 
        lis_GR(8,i) * dadzIInst + sDADz(p_nodes(i) + ntrans + ReducedNX_G + 1 + retim)

    end if
  
  end do 
!$OMP END DO

end subroutine getSource_3D

end module FiElec

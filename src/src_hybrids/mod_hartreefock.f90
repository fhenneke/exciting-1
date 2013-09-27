
module mod_hartreefock

    use modinput
    use modmain
    use modgw
    use modmpi, only: rank
    implicit none

! number of HF cycles
    integer :: ihyb

! Hartree-Fock energy
    real(8), allocatable :: exnlk(:)
    real(8)              :: exnl

! Hartree-Fock potential
    complex(8), allocatable :: vxnl(:,:,:)

! Coulomb potential in MB representation
    complex(8), allocatable :: vcmb(:,:,:)

! Size of MB in which Vcmb is diagonal
    integer, allocatable :: vcmbsiz(:)
    
! KS eigenvector from previous iteration
    complex(8), allocatable :: evecfv0(:,:,:,:)
    
!*******************************************************************************
contains

    subroutine init_hf_input_params
        implicit none

! print debugging information    
        debug = .false.

!---------------------------------------
! MB parameters are taken from GW
!---------------------------------------
        if (.not.associated(input%gw)) &
       &  input%gw => getstructgw(emptynode)

!---------------------------------------
! Options for the mixed basis functions
!---------------------------------------
        if (.not.associated(input%gw%MixBasis)) &
       &  input%gw%MixBasis => getstructmixbasis(emptynode)

!---------------------------------------
! Parameters for the bare coulomb potential
!---------------------------------------
        if (.not.associated(input%gw%BareCoul)) &
       &  input%gw%BareCoul => getstructbarecoul(emptynode)

!---------------------------------------
! print out information on MB to INFO.OUT
!---------------------------------------   
        if (rank .Eq. 0) call boxmsg(60,'=','Mixed Product Basis')
!---------------------------------------
! treatment of core electrons
!---------------------------------------
        select case (input%gw%coreflag)
            case('all','ALL')
                iopcore=0
                if (rank .Eq. 0) write(60,*)' all: All electron calculation'
            case('xal','XAL')
                iopcore=1
                if (rank .Eq. 0) write(60,*)' xal: all electron for exchange, valence only for correlation'
            case('val')
                iopcore=2
                if (rank .Eq. 0) write(60,*)' val: Valence electrons only'
            case('vab')
                iopcore=3
                if (rank .Eq. 0) write(60,*)' vab: Valence-only without core states in mixbasis'
        end select         
        if (rank .Eq. 0) then
!---------------------------------------
! MB related parameters
!---------------------------------------
            write(60,*)
            write(60,*) 'Mixed basis parameters:'
            write(60,*) '- Interstitial:'
            write(60,*) '  -- maximum |G| of IPW in gmaxvr units (gmb):', input%gw%MixBasis%gmb
            write(60,*) '- MT-Spheres:'
            write(60,*) '  -- l_max (lmaxmb): ', input%gw%MixBasis%lmaxmb
            write(60,*) '  -- linear dependence tolerance (epsmb): ', input%gw%MixBasis%epsmb
            write(60,*)
            write(60,*) 'Bare Coulomb parameters:'
            write(60,*) 'Maximum |G| in gmaxvr*gmb units:', input%gw%BareCoul%pwm
            write(60,*) 'Error tolerance for struct. const.:', input%gw%BareCoul%stctol
            write(60,*) 'Tolerance to choose basis functions from bare Coulomb &
           &  matrix eigenvectors: ', input%gw%BareCoul%barcevtol
            call linmsg(60,'=','')
            call flushifc(60)
        end if
    
        return
    end subroutine

!-------------------------------------------------------------------------------
!-------------------------------------------------------------------------------
!-------------------------------------------------------------------------------

    subroutine init_mixed_basis

        implicit none
        integer(4) :: i, ia, is, ias, ic, il, ist, m
        integer(4) :: ik, iq, ie, ie1, ie2
        integer(4) :: ir, l
        integer(4) :: kini, kend
        real(8)    :: norm    
        complex(8) :: sum

!---------------------------------------
! Determine the number of core states for each species (auxiliary arrays)
!---------------------------------------    
        if (allocated(ncore)) deallocate(ncore)
        allocate(ncore(nspecies))
        ncmax=0
        nclm=0
        ncg=0
        lcoremax=0
        do is=1,nspecies
            ncore(is)=0
            ic = 0
            do ist=1,spnst(is)
                if (spcore(ist,is)) then
                    ncore(is)=ncore(is)+1
                    il=spl(ist,is)
                    do m=-spk(ist,is),spk(ist,is)-1
                        ic=ic+1
                    end do
                end if
            end do
            ncmax=max(ncmax,ncore(is))
            nclm=max(nclm,ic)
            lcoremax=max(lcoremax,il)
            ncg=ncg+ic*natoms(is)
        end do
! setting a unique index for all the core states of all atoms
        call setcorind

! reciprocal cell volume
        vi=1.0d0/omega

! shortcut for basis vectors 
        avec(:,1)=input%structure%crystal%basevect(:,1)
        avec(:,2)=input%structure%crystal%basevect(:,2)
        avec(:,3)=input%structure%crystal%basevect(:,3)

! reciprocal lattice basis lengths
        do i=1,3
            alat(i)=dsqrt(avec(1,i)*avec(1,i)+avec(2,i)*avec(2,i)+avec(3,i)*avec(3,i))
            pia(i)=2.0d0*pi/alat(i)
        end do

! additional arrays used simply for convenience
        do is=1,nspecies
            do ia=1,natoms(is)
                ias=idxas(ia,is)
! shortcut for atomic positions
                atposl(:,ia,is)=input%structure%speciesarray(is)%species%atomarray(ia)%atom%coord(:)
            end do
! calculate the muffin-tin volume
            vmt(is)=4.0d0*pi*rmt(is)*rmt(is)*rmt(is)/(3.0d0*omega)
        end do

        if (allocated(ipwint)) deallocate(ipwint)
        allocate(ipwint(ngrtot))
        ipwint(:) = conjg(cfunig(:))

!---------------------------------------
!   Mixed basis initialization (GW routine)
!---------------------------------------
        call init_mb

! ***** revert back from GW definition of rwfcr
        do is=1,nspecies
            do ia=1,natoms(is)
                ias=idxas(ia,is)
                do ist=1,ncore(is)
                    l=spl(ist,is)
                    norm=sqrt(0.5d0*spocc(ist,is)/dble(2*l+1))
                    do ir=1,nrmt(is)
                        rwfcr(ir,1,ist,ias)=spr(ir,is)*rwfcr(ir,1,ist,ias)/norm
                    end do
                end do ! ist
            end do
        end do
        
        return
    end subroutine

end module

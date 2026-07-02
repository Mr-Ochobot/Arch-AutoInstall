#!/bin/bash
# Symbols for display
CHECKMARK="[+]"
PROCESS="[*]"
CROSS="[✗]"
ARROW="[→]"
INFO="[i]"

# Display colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m' 

# Global variables
DISK=""
EFI_PART=""
SWAP_PART=""
ROOT_PART=""
HAS_SWAP=""
ZONE=""
HOSTNAME=""
SWAP_SIZE=""

print_success() {
    echo -e "${GREEN}${CHECKMARK}${NC} $1"
}

print_process() {
    echo -e "${BLUE}${PROCESS}${NC} $1"
}

print_error() {
    echo -e "${RED}${CROSS}${NC} $1"
}

print_info() {
    echo -e "${CYAN}${INFO}${NC} $1"
}

print_arrow() {
    echo -e "${YELLOW}${ARROW}${NC} $1"
}

print_step() {
    echo ""
    echo -e "${WHITE}${CHECKMARK} $1${NC}"
    echo ""
}

print_header() {
    clear
    echo -e "${CYAN}"
    echo "   █████╗ ██████╗  ██████╗██╗  ██╗"
    echo "  ██╔══██╗██╔══██╗██╔════╝██║  ██║"
    echo "  ███████║██████╔╝██║     ███████║"
    echo "  ██╔══██║██╔══██╗██║     ██╔══██║"
    echo "  ██║  ██║██║  ██║╚██████╗██║  ██║"
    echo "  ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝"
    echo ""
    echo -e "${WHITE}[+] AUTO ARCH LINUX INSTALLER v2.0${NC}"
    echo ""
}

select_timezone() {
    print_step "SELECT TIMEZONE"
    
    print_info "Loading list of available regions..."
    echo ""
    
    regions=()
    i=1
    for region in $(ls /usr/share/zoneinfo/ | grep -v "right\|posix\|zone.tab\|zone1970.tab" | sort); do
        if [ -d "/usr/share/zoneinfo/$region" ]; then
            printf "  %3d) %s\n" $i "$region"
            regions+=("$region")
            ((i++))
        fi
    done
    
    echo ""
    print_arrow "Select region number [1-${#regions[@]}]: "
    read -p "> " region_choice
    
    if [[ ! "$region_choice" =~ ^[0-9]+$ ]] || [ "$region_choice" -lt 1 ] || [ "$region_choice" -gt "${#regions[@]}" ]; then
        print_error "Invalid selection! Using default: Asia"
        REGION="Asia"
    else
        REGION="${regions[$((region_choice-1))]}"
        print_success "Region selected: $REGION"
    fi
    
    echo ""
    sleep 1
    
    clear
    print_step "SELECT CITY / TIMEZONE"
    print_info "Region: $REGION"
    echo ""
    
    cities=()
    i=1
    for city in $(ls /usr/share/zoneinfo/$REGION/ | sort); do
        if [ -f "/usr/share/zoneinfo/$REGION/$city" ]; then
            printf "  %3d) %s\n" $i "$city"
            cities+=("$city")
            ((i++))
        fi
    done
    
    if [ "${#cities[@]}" -gt 25 ]; then
        echo ""
        print_arrow "Too many cities! Search with keyword (or press Enter to see all): "
        read -p "> " keyword
        
        if [ ! -z "$keyword" ]; then
            clear
            print_step "SEARCH RESULTS: $keyword"
            echo ""
            
            cities=()
            i=1
            for city in $(ls /usr/share/zoneinfo/$REGION/ | sort); do
                if [ -f "/usr/share/zoneinfo/$REGION/$city" ] && [[ "$city" =~ "$keyword" ]]; then
                    printf "  %3d) %s\n" $i "$city"
                    cities+=("$city")
                    ((i++))
                fi
            done
            
            if [ "${#cities[@]}" -eq 0 ]; then
                print_error "Not found! Showing all cities..."
                cities=()
                i=1
                for city in $(ls /usr/share/zoneinfo/$REGION/ | sort); do
                    if [ -f "/usr/share/zoneinfo/$REGION/$city" ]; then
                        printf "  %3d) %s\n" $i "$city"
                        cities+=("$city")
                        ((i++))
                    fi
                done
            fi
        fi
    fi
    
    echo ""
    print_arrow "Select city number [1-${#cities[@]}]: "
    read -p "> " city_choice
    
    if [[ ! "$city_choice" =~ ^[0-9]+$ ]] || [ "$city_choice" -lt 1 ] || [ "$city_choice" -gt "${#cities[@]}" ]; then
        print_error "Invalid selection! Using default: Jakarta"
        ZONE="$REGION/Jakarta"
    else
        ZONE="$REGION/${cities[$((city_choice-1))]}"
    fi
    
    print_success "Timezone selected: $ZONE"
    echo ""
    read -p "Press Enter to continue..."
    
    export ZONE
}

select_timezone_manual() {
    print_step "SELECT TIMEZONE (MANUAL)"
    echo ""
    print_info "Enter timezone manually"
    print_info "Examples: Asia/Jakarta, Europe/London, America/New_York"
    echo ""
    print_arrow "Timezone: "
    read -p "> " ZONE_INPUT
    
    if [ -f "/usr/share/zoneinfo/$ZONE_INPUT" ]; then
        ZONE="$ZONE_INPUT"
        print_success "Timezone selected: $ZONE"
    else
        print_error "Invalid timezone! Using default: Asia/Jakarta"
        ZONE="Asia/Jakarta"
    fi
    
    echo ""
    read -p "Press Enter to continue..."
    export ZONE
}

menu_timezone() {
    print_step "SELECT TIMEZONE METHOD"
    echo ""
    echo "  [1] Select from list (Region -> City)"
    echo "  [2] Manual input"
    echo ""
    print_arrow "Choose method [1-2]: "
    read -p "> " method
    
    case $method in
        1) select_timezone ;;
        2) select_timezone_manual ;;
        *) 
            print_error "Invalid selection! Using default method..."
            select_timezone 
            ;;
    esac
}

input_hostname() {
    print_step "SET HOSTNAME"
    echo ""
    print_info "Enter hostname for your computer"
    print_info "Examples: myarch, arch-pc, laptop-arch"
    echo ""
    print_arrow "Hostname: "
    read -p "> " HOSTNAME_INPUT
    
    if [ -z "$HOSTNAME_INPUT" ]; then
        HOSTNAME="archlinux"
        print_info "Using default: archlinux"
    else
        if [[ "$HOSTNAME_INPUT" =~ ^[a-zA-Z0-9-]+$ ]]; then
            HOSTNAME="$HOSTNAME_INPUT"
            print_success "Hostname: $HOSTNAME"
        else
            print_error "Hostname can only contain letters, numbers, and hyphens!"
            print_info "Using default: archlinux"
            HOSTNAME="archlinux"
        fi
    fi
    
    export HOSTNAME
    echo ""
    read -p "Press Enter to continue..."
}

show_disks() {
    print_step "AVAILABLE DISKS"
    echo ""
    lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,MODEL | grep -E "disk|part" | grep -v "loop"
    echo ""
}

select_disk() {
    while true; do
        show_disks
        print_arrow "Select disk to install (e.g., sda, sdb, nvme0n1): "
        read -p "> " DISK
        
        if [ -z "$DISK" ]; then
            print_error "Disk cannot be empty!"
            continue
        fi
        
        if [ -e "/dev/$DISK" ]; then
            print_success "Disk /dev/$DISK selected"
            export DISK
            return 0
        else
            print_error "Disk /dev/$DISK not found!"
            echo ""
            read -p "Press Enter to try again..."
        fi
    done
}

auto_partition() {
    print_step "AUTOMATIC PARTITIONING"
    echo ""
    
    print_arrow "Do you want to create a SWAP partition? (y/n): "
    read -p "> " HAS_SWAP
    
    print_process "Removing all partitions on /dev/$DISK..."
    wipefs -a /dev/$DISK 2>/dev/null
    parted -s /dev/$DISK mklabel gpt
    
    if [[ "$HAS_SWAP" =~ ^[Yy]$ ]]; then
        print_info "Creating partitions with SWAP"
        echo ""
        
        print_arrow "Enter SWAP size (e.g., 2G, 4G, 8G): "
        read -p "> " SWAP_SIZE
        
        if [ -z "$SWAP_SIZE" ]; then
            SWAP_SIZE="2G"
            print_info "Using default: 2G"
        fi
        
        print_process "Creating EFI partition (512M)..."
        parted -s /dev/$DISK mkpart primary fat32 1MiB 513MiB
        parted -s /dev/$DISK set 1 esp on
        
        print_process "Creating SWAP partition ($SWAP_SIZE)..."
        parted -s /dev/$DISK mkpart primary linux-swap 513MiB $(echo "513 + $(echo $SWAP_SIZE | sed 's/G//') * 1024" | bc)MiB
        
        print_process "Creating ROOT partition (remaining space)..."
        parted -s /dev/$DISK mkpart primary ext4 $(echo "513 + $(echo $SWAP_SIZE | sed 's/G//') * 1024" | bc)MiB 100%
        
        if [[ "$DISK" == nvme* ]]; then
            EFI_PART="/dev/${DISK}p1"
            SWAP_PART="/dev/${DISK}p2"
            ROOT_PART="/dev/${DISK}p3"
        else
            EFI_PART="/dev/${DISK}1"
            SWAP_PART="/dev/${DISK}2"
            ROOT_PART="/dev/${DISK}3"
        fi
        
        print_success "Partitions with SWAP created successfully!"
        echo ""
        echo "  ${GREEN}✓${NC} EFI  : $EFI_PART (512M)"
        echo "  ${GREEN}✓${NC} SWAP : $SWAP_PART ($SWAP_SIZE)"
        echo "  ${GREEN}✓${NC} ROOT : $ROOT_PART (remaining space)"
        
    else
        print_info "Creating partitions WITHOUT SWAP"
        echo ""
        
        print_process "Creating EFI partition (512M)..."
        parted -s /dev/$DISK mkpart primary fat32 1MiB 513MiB
        parted -s /dev/$DISK set 1 esp on
        
        print_process "Creating ROOT partition (remaining space)..."
        parted -s /dev/$DISK mkpart primary ext4 513MiB 100%
        
        if [[ "$DISK" == nvme* ]]; then
            EFI_PART="/dev/${DISK}p1"
            ROOT_PART="/dev/${DISK}p2"
            SWAP_PART=""
        else
            EFI_PART="/dev/${DISK}1"
            ROOT_PART="/dev/${DISK}2"
            SWAP_PART=""
        fi
        
        print_success "Partitions without SWAP created successfully!"
        echo ""
        echo "  ${GREEN}✓${NC} EFI  : $EFI_PART (512M)"
        echo "  ${GREEN}✓${NC} ROOT : $ROOT_PART (remaining space)"
    fi
    
    export EFI_PART SWAP_PART ROOT_PART HAS_SWAP SWAP_SIZE
    echo ""
    read -p "Press Enter to continue..."
}

manual_partition() {
    print_step "MANUAL PARTITIONING WITH CFDISK"
    echo ""
    print_info "Partition Guide:"
    echo "  1. Create first partition: 512M (EFI System - type: EFI)"
    
    print_arrow "Do you want to create a SWAP partition? (y/n): "
    read -p "> " HAS_SWAP
    
    if [[ "$HAS_SWAP" =~ ^[Yy]$ ]]; then
        echo "  2. Create second partition: SWAP (custom size - type: Linux swap)"
        echo "  3. Create third partition: Remaining space (Root - type: Linux filesystem)"
    else
        echo "  2. Create second partition: Remaining space (Root - type: Linux filesystem)"
    fi
    
    echo ""
    print_arrow "Press Enter to open cfdisk..."
    read -p ""
    
    cfdisk /dev/$DISK
    
    clear
    print_step "PARTITIONS CREATED"
    lsblk /dev/$DISK
    echo ""
    
    if [[ "$DISK" == nvme* ]]; then
        EFI_PART="/dev/${DISK}p1"
        if [[ "$HAS_SWAP" =~ ^[Yy]$ ]]; then
            SWAP_PART="/dev/${DISK}p2"
            ROOT_PART="/dev/${DISK}p3"
        else
            ROOT_PART="/dev/${DISK}p2"
            SWAP_PART=""
        fi
    else
        EFI_PART="/dev/${DISK}1"
        if [[ "$HAS_SWAP" =~ ^[Yy]$ ]]; then
            SWAP_PART="/dev/${DISK}2"
            ROOT_PART="/dev/${DISK}3"
        else
            ROOT_PART="/dev/${DISK}2"
            SWAP_PART=""
        fi
    fi
    
    export EFI_PART SWAP_PART ROOT_PART HAS_SWAP
    
    print_success "Partitions detected:"
    echo "  ${GREEN}✓${NC} EFI  : $EFI_PART (512M)"
    [ ! -z "$SWAP_PART" ] && echo "  ${GREEN}✓${NC} SWAP : $SWAP_PART"
    echo "  ${GREEN}✓${NC} ROOT : $ROOT_PART"
    echo ""
    read -p "Press Enter to continue..."
}

menu_partition() {
    print_step "SELECT PARTITION METHOD"
    echo ""
    echo "  [1] Automatic (using parted)"
    echo "  [2] Manual (using cfdisk)"
    echo ""
    print_arrow "Choose method [1-2]: "
    read -p "> " method
    
    case $method in
        1) 
            print_success "SELECTED: AUTOMATIC PARTITIONING"
            auto_partition 
            ;;
        2) 
            print_success "SELECTED: MANUAL PARTITIONING"
            manual_partition 
            ;;
        *) 
            print_error "Invalid selection! Using automatic method..."
            auto_partition 
            ;;
    esac
}

format_partitions() {
    print_step "FORMATTING PARTITIONS"
    
    print_process "Formatting EFI partition (FAT32)..."
    if mkfs.fat -F32 $EFI_PART 2>/dev/null; then
        print_success "EFI partition formatted successfully"
    else
        print_error "Failed to format EFI partition"
        exit 1
    fi
    
    if [ ! -z "$SWAP_PART" ]; then
        print_process "Formatting SWAP partition..."
        if mkswap $SWAP_PART 2>/dev/null; then
            print_success "SWAP partition formatted successfully"
        else
            print_error "Failed to format SWAP partition"
            exit 1
        fi
    fi
    
    print_process "Formatting ROOT partition (ext4)..."
    if mkfs.ext4 -F $ROOT_PART 2>/dev/null; then
        print_success "ROOT partition formatted successfully"
    else
        print_error "Failed to format ROOT partition"
        exit 1
    fi
    
    echo ""
    read -p "Press Enter to continue..."
}

mount_partitions() {
    print_step "MOUNTING PARTITIONS"
    
    print_process "Mounting ROOT partition to /mnt..."
    if mount $ROOT_PART /mnt; then
        print_success "ROOT partition mounted successfully"
    else
        print_error "Failed to mount ROOT partition"
        exit 1
    fi
    
    print_process "Creating /mnt/boot directory..."
    mkdir -p /mnt/boot
    
    print_process "Mounting EFI partition to /mnt/boot..."
    if mount $EFI_PART /mnt/boot; then
        print_success "EFI partition mounted successfully"
    else
        print_error "Failed to mount EFI partition"
        exit 1
    fi
    
    if [ ! -z "$SWAP_PART" ]; then
        print_process "Enabling SWAP..."
        if swapon $SWAP_PART 2>/dev/null; then
            print_success "SWAP enabled successfully"
        else
            print_error "Failed to enable SWAP"
        fi
    fi
    
    echo ""
    print_success "All partitions mounted successfully!"
    echo ""
    lsblk /dev/$DISK
    echo ""
    read -p "Press Enter to continue..."
}

install_base() {
    print_step "INSTALLING BASE SYSTEM"
    
    print_info "Packages: base linux linux-firmware sudo nano networkmanager"
    echo ""
    print_process "Starting base system installation..."
    
    if pacstrap -K /mnt base linux linux-firmware sudo nano networkmanager; then
        print_success "Base system installed successfully!"
    else
        print_error "Base system installation failed!"
        exit 1
    fi
    
    echo ""
    read -p "Press Enter to continue..."
}

generate_fstab() {
    print_step "GENERATING FSTAB"
    
    print_process "Generating fstab..."
    if genfstab -U /mnt >> /mnt/etc/fstab; then
        print_success "Fstab generated successfully!"
    else
        print_error "Failed to generate fstab"
        exit 1
    fi
    
    echo ""
    print_info "Fstab contents:"
    echo -e "${YELLOW}"
    cat /mnt/etc/fstab
    echo -e "${NC}"
    echo ""
    read -p "Press Enter to continue..."
}

configure_chroot() {
    print_step "CONFIGURING INSIDE CHROOT"
    
    cat > /mnt/root/auto_config.sh << 'EOF'
#!/bin/bash

CHECKMARK="[+]"
PROCESS="[*]"
CROSS="[✗]"
ARROW="[→]"
INFO="[i]"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

print_success() {
    echo -e "${GREEN}${CHECKMARK}${NC} $1"
}

print_process() {
    echo -e "${BLUE}${PROCESS}${NC} $1"
}

print_error() {
    echo -e "${RED}${CROSS}${NC} $1"
}

print_info() {
    echo -e "${CYAN}${INFO}${NC} $1"
}

print_arrow() {
    echo -e "${YELLOW}${ARROW}${NC} $1"
}

print_step() {
    echo ""
    echo -e "${WHITE}${CHECKMARK} $1${NC}"
    echo ""
}

print_step "SET TIMEZONE"

select_timezone() {
    print_step "SELECT TIMEZONE"
    
    regions=()
    i=1
    for region in $(ls /usr/share/zoneinfo/ | grep -v "right\|posix\|zone.tab\|zone1970.tab" | sort); do
        if [ -d "/usr/share/zoneinfo/$region" ]; then
            printf "  %3d) %s\n" $i "$region"
            regions+=("$region")
            ((i++))
        fi
    done
    
    echo ""
    print_arrow "Select region number [1-${#regions[@]}]: "
    read -p "> " region_choice
    
    if [[ ! "$region_choice" =~ ^[0-9]+$ ]] || [ "$region_choice" -lt 1 ] || [ "$region_choice" -gt "${#regions[@]}" ]; then
        print_error "Invalid selection!"
        return 1
    fi
    
    REGION="${regions[$((region_choice-1))]}"
    print_success "Region selected: $REGION"
    echo ""
    sleep 1
    
    clear
    print_step "SELECT CITY / TIMEZONE"
    print_info "Region: $REGION"
    echo ""
    
    cities=()
    i=1
    for city in $(ls /usr/share/zoneinfo/$REGION/ | sort); do
        if [ -f "/usr/share/zoneinfo/$REGION/$city" ]; then
            printf "  %3d) %s\n" $i "$city"
            cities+=("$city")
            ((i++))
        fi
    done
    
    echo ""
    print_arrow "Select city number [1-${#cities[@]}]: "
    read -p "> " city_choice
    
    if [[ ! "$city_choice" =~ ^[0-9]+$ ]] || [ "$city_choice" -lt 1 ] || [ "$city_choice" -gt "${#cities[@]}" ]; then
        print_error "Invalid selection!"
        return 1
    fi
    
    ZONE="$REGION/${cities[$((city_choice-1))]}"
    print_success "Timezone selected: $ZONE"
    echo ""
    
    export ZONE
    return 0
}

echo ""
print_arrow "Select timezone method:"
echo "  [1] Select from list (Region -> City)"
echo "  [2] Manual input"
echo ""
read -p "Choice [1-2]: " tz_method

if [ "$tz_method" = "1" ]; then
    select_timezone
    if [ $? -ne 0 ]; then
        print_info "Using default: Asia/Jakarta"
        ZONE="Asia/Jakarta"
    fi
else
    print_arrow "Enter timezone (e.g., Asia/Jakarta): "
    read -p "> " ZONE
    if [ ! -f "/usr/share/zoneinfo/$ZONE" ]; then
        print_info "Invalid timezone! Using default: Asia/Jakarta"
        ZONE="Asia/Jakarta"
    fi
fi

print_process "Setting timezone to: $ZONE"
if ln -sf /usr/share/zoneinfo/$ZONE /etc/localtime && hwclock --systohc; then
    print_success "Timezone set successfully!"
else
    print_error "Failed to set timezone"
    exit 1
fi

print_step "SET LOCALE"

print_process "Setting locale..."
cat > /etc/locale.gen << 'LOCALE_EOF'
en_US.UTF-8 UTF-8
id_ID.UTF-8 UTF-8
LOCALE_EOF

if locale-gen; then
    print_success "Locale generated successfully"
else
    print_error "Failed to generate locale"
    exit 1
fi

echo "LANG=en_US.UTF-8" > /etc/locale.conf
print_success "Locale configured successfully!"

print_step "SET HOSTNAME"

HOSTNAME="${HOSTNAME}"

echo "$HOSTNAME" > /etc/hostname
print_success "Hostname: $HOSTNAME"

print_step "SET HOSTS"

cat > /etc/hosts << HOSTS_EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain  $HOSTNAME
HOSTS_EOF

print_success "Hosts configured successfully with hostname: $HOSTNAME"
print_info "Contents of /etc/hosts:"
echo -e "${YELLOW}"
cat /etc/hosts
echo -e "${NC}"

print_step "SET ROOT PASSWORD"
print_info "Enter password for root:"
passwd

if [ $? -eq 0 ]; then
    print_success "Root password set successfully!"
else
    print_error "Failed to set root password"
    exit 1
fi

print_step "CREATE NEW USER"

print_arrow "Enter new username: "
read -p "> " USERNAME
if [ -z "$USERNAME" ]; then
    USERNAME="archuser"
    print_info "Using default: archuser"
fi

if useradd -m -G wheel -s /bin/bash $USERNAME; then
    print_success "User $USERNAME created successfully!"
else
    print_error "Failed to create user"
    exit 1
fi

print_info "Enter password for user $USERNAME:"
passwd $USERNAME

if [ $? -eq 0 ]; then
    print_success "User password set successfully!"
else
    print_error "Failed to set user password"
    exit 1
fi

print_step "SETUP SUDO"

print_process "Enabling wheel group in sudoers..."
echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers.d/wheel

if [ $? -eq 0 ]; then
    print_success "Wheel group enabled in sudoers!"
else
    print_error "Failed to enable wheel group"
    exit 1
fi

print_step "INSTALL BOOTLOADER GRUB"

print_process "Installing GRUB and efibootmgr..."
if pacman -S --noconfirm grub efibootmgr; then
    print_success "GRUB and efibootmgr installed successfully"
else
    print_error "Failed to install GRUB"
    exit 1
fi

DISK=$(lsblk -npo TYPE,NAME | grep -E "disk.*$(df /boot | tail -1 | awk '{print $1}' | sed 's|/dev/||' | sed 's|p[0-9]*$||' | sed 's|[0-9]*$||')" | awk '{print $2}')

if [ -z "$DISK" ]; then
    DISK=$(lsblk -npo TYPE,NAME | grep -E "disk.*$(df / | tail -1 | awk '{print $1}' | sed 's|/dev/||' | sed 's|p[0-9]*$||' | sed 's|[0-9]*$||')" | awk '{print $2}')
fi

print_process "Installing GRUB to EFI..."
if grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=ARCH $DISK; then
    print_success "GRUB installed to EFI successfully"
else
    print_error "Failed to install GRUB to EFI"
    exit 1
fi

print_process "Generating GRUB config..."
if grub-mkconfig -o /boot/grub/grub.cfg; then
    print_success "GRUB config generated successfully!"
else
    print_error "Failed to generate GRUB config"
    exit 1
fi

print_step "ENABLE NETWORKMANAGER"

print_process "Enabling NetworkManager..."
if systemctl enable NetworkManager; then
    print_success "NetworkManager enabled successfully!"
else
    print_error "Failed to enable NetworkManager"
    exit 1
fi

print_step "CONFIGURATION COMPLETED!"
echo ""
print_success "All configuration completed successfully!"
echo ""
print_info "Next steps:"
echo "  1. Type 'exit' to leave chroot"
echo "  2. Type 'umount -R /mnt' to unmount"
echo "  3. Type 'reboot' to restart"
echo ""
print_success "Congratulations! Arch Linux has been installed!"

EOF

    chmod +x /mnt/root/auto_config.sh
    
    print_success "Configuration script created at /mnt/root/auto_config.sh"
    echo ""
    print_info "Entering Arch-chroot..."
    print_arrow "Inside chroot, run: /root/auto_config.sh"
    print_arrow "To exit chroot, type: exit"
    echo ""
    read -p "Press Enter to enter chroot..."
    
    arch-chroot /mnt
    
    clear
    print_step "EXITED CHROOT"
    print_success "You have exited chroot"
    
    print_process "Unmounting all partitions..."
    if umount -R /mnt 2>/dev/null; then
        print_success "All partitions unmounted successfully!"
    else
        print_info "Some partitions may already be unmounted"
    fi
    
    echo ""
    print_step "ARCH LINUX INSTALLATION COMPLETED!"
    echo ""
    echo -e "${GREEN}[+] CONGRATULATIONS! ARCH LINUX HAS BEEN INSTALLED!${NC}"
    echo ""
    print_info "Next steps:"
    echo "  1. Type 'reboot' to restart"
    echo "  2. Remove the USB installer"
    echo "  3. Login with the user you created"
    echo ""
}

main() {
    if [ "$EUID" -ne 0 ]; then 
        print_error "Script must be run as root (sudo)!"
        exit 1
    fi
    
    print_process "Checking internet connection..."
    if ping -c 1 archlinux.org &>/dev/null; then
        print_success "Internet connection detected!"
    else
        print_error "No internet connection!"
        print_info "Please ensure you are connected to the internet before continuing"
        exit 1
    fi
    
    print_header
    print_info "This script will automatically install Arch Linux"
    print_info "Make sure you are ready with your desired configuration"
    echo ""
    read -p "Press Enter to continue..."
    
    input_hostname
    select_disk
    menu_partition
    format_partitions
    mount_partitions
    install_base
    generate_fstab
    configure_chroot
    
    print_success "Installation process completed!"
}

# Run main
main

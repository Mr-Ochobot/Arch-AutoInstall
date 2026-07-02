# Auto Arch Linux Installer

A professional interactive Bash installer that automates the installation process of Arch Linux while still allowing important user customization.

The installer simplifies the standard Arch Linux installation by providing guided menus for disk selection, partitioning, formatting, system installation, timezone configuration, hostname configuration, user creation, and bootloader installation.

---

## Features

- Interactive terminal interface
- Automatic disk detection
- Automatic or manual partitioning
- GPT partition table creation
- EFI System Partition support
- Optional SWAP partition
- EXT4 filesystem formatting
- Automatic mounting
- Base Arch Linux installation
- Automatic FSTAB generation
- Timezone selection
- Locale configuration
- Hostname configuration
- Root password setup
- User account creation
- Sudo configuration
- GRUB bootloader installation
- NetworkManager installation and activation
- Colored terminal output
- Error handling and validation

---

## Installation Workflow

```
Start
 │
 ├── Check Internet Connection
 │
 ├── Enter Hostname
 │
 ├── Select Target Disk
 │
 ├── Choose Partition Method
 │      ├── Automatic
 │      └── Manual (cfdisk)
 │
 ├── Format Partitions
 │
 ├── Mount Partitions
 │
 ├── Install Base System
 │
 ├── Generate FSTAB
 │
 ├── Enter Arch-Chroot
 │
 ├── Configure System
 │      ├── Timezone
 │      ├── Locale
 │      ├── Hostname
 │      ├── Root Password
 │      ├── User Account
 │      ├── Sudo
 │      ├── GRUB
 │      └── NetworkManager
 │
 └── Installation Complete
```

---

## Requirements

- Arch Linux Installation ISO
- UEFI System
- Internet Connection
- Root Privileges
- GPT Partition Table

---

## Included Packages

The installer installs the following base packages:

- base
- linux
- linux-firmware
- sudo
- nano
- networkmanager

During system configuration it also installs:

- grub
- efibootmgr

---

## Partition Layout

### Without SWAP

| Partition | Size | Filesystem |
|-----------|------|------------|
| EFI | 512 MB | FAT32 |
| ROOT | Remaining Space | EXT4 |

### With SWAP

| Partition | Size | Filesystem |
|-----------|------|------------|
| EFI | 512 MB | FAT32 |
| SWAP | User Defined | Linux Swap |
| ROOT | Remaining Space | EXT4 |

---

## Usage

Clone the repository:

```bash
git clone https://github.com/Mr-Ochobot/Arch-AutoInstall.git
```

Enter the project directory:

```bash
cd Arch-AutoInstall
```

Make the script executable:

```bash
chmod +x install.sh
```

Run the installer as root:

```bash
sudo ./install.sh
```

---

## Installation Steps

1. Boot into the Arch Linux Live ISO.
2. Connect to the Internet.
3. Run the installer.
4. Select the target disk.
5. Choose automatic or manual partitioning.
6. Wait for the base system installation.
7. Enter the generated chroot environment.
8. Run the configuration script.
9. Complete timezone, locale, user, and bootloader setup.
10. Exit, unmount, and reboot.

---

## Supported Storage Devices

- SATA SSD
- NVMe SSD
- HDD
- USB Storage Devices

Examples:

```
/dev/sda
/dev/sdb
/dev/nvme0n1
```

---

## Safety Notice

This installer performs disk partitioning and formatting.

All data on the selected disk will be permanently erased.

Always verify the selected target disk before continuing.

---

## Project Structure

```
.
├── install.sh
├── README.md
└── LICENSE
```
---

## Contributing

Contributions are welcome.

If you discover bugs, have suggestions, or would like to improve the installer, feel free to open an Issue or submit a Pull Request.

---

## Acknowledgments

This project is inspired by the official Arch Linux installation process while providing a simplified interactive installation experience without sacrificing flexibility.

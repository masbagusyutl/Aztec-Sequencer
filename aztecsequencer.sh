#!/bin/bash

# Warna untuk tampilan
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # Tanpa Warna
BOLD='\033[1m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'

# Fungsi untuk menampilkan logo dan pesan selamat datang
display_welcome() {
    clear
    echo -e "${WHITE}"
    echo " _  _ _   _ ____ ____ _    ____ _ ____ ___  ____ ____ ___ "
    echo "|\\ |  \\_/  |__| |__/ |    |__| | |__/ |  \\ |__/ |  | |__]"
    echo "| \\|   |   |  | |  \\ |    |  | | |  \\ |__/ |  \\ |__| |    "
    echo -e "${GREEN}"
    echo "Instalasi Otomatis Node Aztec Sequencer"
    echo -e "${YELLOW}"
    echo "Telegram: https://t.me/nyariairdrop"
    echo -e "${NC}"
    echo -e "${CYAN}Skrip ini akan membantu Anda menginstal dan mengonfigurasi Node Sequencer Aztec${NC}"
    echo -e "${CYAN}==================================================================${NC}"
    echo ""
}

# Fungsi untuk memeriksa apakah perintah ada
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Fungsi untuk memeriksa persyaratan sistem
check_requirements() {
    echo -e "${BLUE}${BOLD}Memeriksa persyaratan sistem...${NC}"
    
    # Periksa jumlah core CPU
    CPU_CORES=$(nproc --all)
    echo -n "Jumlah Core CPU: $CPU_CORES "
    if [ "$CPU_CORES" -lt 8 ]; then
        echo -e "${RED}[TIDAK MEMENUHI] - Direkomendasikan minimal 8 core${NC}"
        REQUIREMENTS_MET=false
    else
        echo -e "${GREEN}[OK]${NC}"
    fi
    
    # Periksa RAM
    TOTAL_RAM=$(free -g | awk '/^Mem:/{print $2}')
    echo -n "RAM: ${TOTAL_RAM}GB "
    if [ "$TOTAL_RAM" -lt 16 ]; then
        echo -e "${RED}[TIDAK MEMENUHI] - Direkomendasikan minimal 16GB RAM${NC}"
        REQUIREMENTS_MET=false
    else
        echo -e "${GREEN}[OK]${NC}"
    fi
    
    # Periksa ruang disk yang tersedia
    AVAILABLE_SPACE=$(df -h / | awk 'NR==2 {print $4}' | sed 's/[^0-9.]//g')
    echo -n "Ruang disk tersedia: ${AVAILABLE_SPACE}GB "
    if (( $(echo "$AVAILABLE_SPACE < 1000" | bc -l) )); then
        echo -e "${RED}[TIDAK MEMENUHI] - Direkomendasikan minimal 1TB SSD${NC}"
        REQUIREMENTS_MET=false
    else
        echo -e "${GREEN}[OK]${NC}"
    fi
    
    # Tes koneksi internet
    echo -n "Menguji kecepatan koneksi internet... "
    if command_exists wget; then
        DOWNLOAD_SPEED=$(wget --output-document=/dev/null http://speedtest.wdc01.softlayer.com/downloads/test10.zip 2>&1 | grep -o "[0-9.]\+ [KM]B/s" | sed 's/KB\/s//' | sed 's/MB\/s/*1000/' | bc 2>/dev/null)
        if [ -z "$DOWNLOAD_SPEED" ]; then
            echo -e "${YELLOW}[TIDAK DIKETAHUI] - Tidak bisa menguji kecepatan${NC}"
        elif (( $(echo "$DOWNLOAD_SPEED < 3000" | bc -l) )); then
            echo -e "${RED}[TIDAK MEMENUHI] - Kecepatan download kurang dari 25 Mbps${NC}"
            REQUIREMENTS_MET=false
        else
            echo -e "${GREEN}[OK]${NC}"
        fi
    else
        echo -e "${YELLOW}[DILEWATI] - wget tidak terpasang${NC}"
    fi
    
    if [ "$REQUIREMENTS_MET" = false ]; then
        echo -e "${RED}${BOLD}Peringatan: Sistem Anda tidak memenuhi semua persyaratan yang direkomendasikan untuk menjalankan Node Sequencer Aztec.${NC}"
        echo -e "Lanjutkan dengan hati-hati atau tingkatkan spesifikasi sistem Anda sebelum melanjutkan."
        echo ""
        read -p "Apakah Anda ingin melanjutkan? (y/n): " -n 1 -r CONTINUE
        echo ""
        if [[ ! $CONTINUE =~ ^[Yy]$ ]]; then
            echo "Instalasi dibatalkan."
            exit 1
        fi
    fi
}

# Fungsi untuk menginstal Docker
install_docker() {
    echo -e "${BLUE}${BOLD}Memeriksa instalasi Docker...${NC}"
    if command_exists docker; then
        echo -e "${GREEN}Docker sudah terpasang.${NC}"
    else
        echo -e "${YELLOW}Docker tidak ditemukan. Menginstal Docker...${NC}"
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        sudo usermod -aG docker $USER
        echo -e "${GREEN}Docker berhasil diinstal. Anda mungkin perlu logout dan login kembali agar perubahan grup berlaku.${NC}"
        echo -e "${YELLOW}Disarankan untuk logout dan login kembali sebelum melanjutkan.${NC}"
        read -p "Apakah Anda ingin melanjutkan sekarang? (y/n): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Silakan logout, login kembali, dan jalankan skrip ini lagi."
            exit 0
        fi
    fi
}

# Fungsi untuk menginstal tools Aztec
install_aztec_tools() {
    echo -e "${BLUE}${BOLD}Menginstal tools Aztec...${NC}"
    
    # Instal Aztec tools
    echo -e "${YELLOW}Menjalankan installer Aztec...${NC}"
    bash -i <(curl -s https://install.aztec.network)
    
    # Instal versi testnet terbaru
    echo -e "${YELLOW}Menginstal versi alpha-testnet...${NC}"
    aztec-up alpha-testnet
    
    echo -e "${GREEN}Tools Aztec berhasil diinstal.${NC}"
}

# Fungsi untuk mendapatkan konfigurasi dari pengguna
get_configuration() {
    echo -e "${BLUE}${BOLD}Mengonfigurasi Node Sequencer Aztec...${NC}"
    echo -e "${YELLOW}Silakan berikan informasi berikut:${NC}"
    
    # Dapatkan URL RPC Ethereum
    read -p "Masukkan URL RPC Ethereum Anda (contoh: https://eth-sepolia.g.alchemy.com/v2/your-key): " ETHEREUM_HOSTS
    while [ -z "$ETHEREUM_HOSTS" ]; do
        echo -e "${RED}URL RPC Ethereum tidak boleh kosong.${NC}"
        read -p "Masukkan URL RPC Ethereum Anda: " ETHEREUM_HOSTS
    done
    
    # Dapatkan URL host konsensus L1
    read -p "Masukkan URL Host Konsensus L1 Anda (contoh: https://eth-sepolia-beacon.g.alchemy.com/eth/v1): " L1_CONSENSUS_HOST_URLS
    while [ -z "$L1_CONSENSUS_HOST_URLS" ]; do
        echo -e "${RED}URL Host Konsensus L1 tidak boleh kosong.${NC}"
        read -p "Masukkan URL Host Konsensus L1 Anda: " L1_CONSENSUS_HOST_URLS
    done
    
    # Dapatkan kunci privat validator
    read -p "Masukkan kunci privat validator Anda (tanpa awalan '0x'): " VALIDATOR_PRIVATE_KEY_INPUT
    VALIDATOR_PRIVATE_KEY="0x${VALIDATOR_PRIVATE_KEY_INPUT#0x}"
    
    while [ -z "$VALIDATOR_PRIVATE_KEY" ] || [ "${#VALIDATOR_PRIVATE_KEY}" -ne 66 ]
    do
        echo -e "${RED}Kunci privat tidak valid. Harus berupa string hex 64 karakter (dengan awalan 0x).${NC}"
        read -p "Masukkan kunci privat validator Anda (tanpa awalan '0x'): " VALIDATOR_PRIVATE_KEY_INPUT
        VALIDATOR_PRIVATE_KEY="0x${VALIDATOR_PRIVATE_KEY_INPUT#0x}"
    done
    
    # Dapatkan alamat coinbase
    read -p "Masukkan alamat evm Anda (penerima hadiah blok): " COINBASE_INPUT
    COINBASE="0x${COINBASE_INPUT#0x}"
    while [ -z "$COINBASE" ] || [ "${#COINBASE}" -ne 42 ]; do
        echo -e "${RED}Alamat Ethereum tidak valid. Harus berupa string hex 40 karakter (dengan awalan 0x).${NC}"
        read -p "Masukkan alamat coinbase Anda: " COINBASE_INPUT
        COINBASE="0x${COINBASE_INPUT#0x}"
    done
    
    # Dapatkan alamat IP publik
    P2P_IP=$(curl -s api.ipify.org)
    echo -e "Alamat IP publik Anda yang terdeteksi adalah: ${CYAN}$P2P_IP${NC}"
    read -p "Tekan Enter untuk menggunakan IP ini atau masukkan IP yang berbeda: " CUSTOM_IP
    if [ ! -z "$CUSTOM_IP" ]; then
        P2P_IP=$CUSTOM_IP
    fi
    
    # Opsional: Port P2P kustom
    read -p "Masukkan port P2P kustom (tekan Enter untuk menggunakan default 40400): " P2P_PORT
    if [ -z "$P2P_PORT" ]; then
        P2P_PORT=40400
    fi
    
    # Ringkasan konfigurasi
    echo -e "${BLUE}${BOLD}Ringkasan Konfigurasi:${NC}"
    echo -e "URL RPC Ethereum: ${CYAN}$ETHEREUM_HOSTS${NC}"
    echo -e "URL Host Konsensus L1: ${CYAN}$L1_CONSENSUS_HOST_URLS${NC}"
    echo -e "Kunci Privat Validator: ${CYAN}${VALIDATOR_PRIVATE_KEY:0:10}...${NC}"
    echo -e "Alamat Coinbase: ${CYAN}$COINBASE${NC}"
    echo -e "Alamat IP P2P: ${CYAN}$P2P_IP${NC}"
    echo -e "Port P2P: ${CYAN}$P2P_PORT${NC}"
    
    read -p "Apakah informasi ini benar? (y/n): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Mari konfigurasi ulang."
        get_configuration
    fi
}

# Fungsi untuk membuat skrip startup
create_startup_script() {
    echo -e "${BLUE}${BOLD}Membuat skrip startup...${NC}"
    
    cat > ~/start_aztec_sequencer.sh << EOF
#!/bin/bash

# Skrip Startup Node Sequencer Aztec
# Dibuat oleh Skrip Nyari Airdrop

# Konfigurasi
export ETHEREUM_HOSTS="$ETHEREUM_HOSTS"
export L1_CONSENSUS_HOST_URLS="$L1_CONSENSUS_HOST_URLS"
export VALIDATOR_PRIVATE_KEY="$VALIDATOR_PRIVATE_KEY"
export COINBASE="$COINBASE"
export P2P_IP="$P2P_IP"
export P2P_PORT="$P2P_PORT"

# Memulai Node Sequencer Aztec
echo "Memulai Node Sequencer Aztec..."
aztec start --node --archiver --sequencer \\
  --network alpha-testnet \\
  --l1-rpc-urls \$ETHEREUM_HOSTS \\
  --l1-consensus-host-urls \$L1_CONSENSUS_HOST_URLS \\
  --sequencer.validatorPrivateKey \$VALIDATOR_PRIVATE_KEY \\
  --sequencer.coinbase \$COINBASE \\
  --p2p.p2pIp \$P2P_IP \\
  --p2p.p2pPort \$P2P_PORT \\
  --p2p.maxTxPoolSize 1000000000
EOF
    
    chmod +x ~/start_aztec_sequencer.sh
    echo -e "${GREEN}Skrip startup dibuat di ~/start_aztec_sequencer.sh${NC}"
}

# Fungsi untuk membuat skrip pendaftaran validator
create_validator_script() {
    echo -e "${BLUE}${BOLD}Membuat skrip pendaftaran validator...${NC}"
    
    cat > ~/register_validator.sh << EOF
#!/bin/bash

# Skrip Pendaftaran Validator Aztec
# Dibuat oleh Skrip Nyari Airdrop

# Konfigurasi
export ETHEREUM_HOSTS="$ETHEREUM_HOSTS"
export PRIVATE_KEY="$VALIDATOR_PRIVATE_KEY"
export ATTESTER="$COINBASE"
export PROPOSER_EOA="$COINBASE"
export STAKING_ASSET_HANDLER="0xF739D03e98e23A7B65940848aBA8921fF3bAc4b2"
export L1_CHAIN_ID="11155111"

# Mendaftar sebagai validator
echo "Mendaftar sebagai validator Aztec..."
aztec add-l1-validator \\
  --l1-rpc-urls \$ETHEREUM_HOSTS \\
  --private-key \$PRIVATE_KEY \\
  --attester \$ATTESTER \\
  --proposer-eoa \$PROPOSER_EOA \\
  --staking-asset-handler \$STAKING_ASSET_HANDLER \\
  --l1-chain-id \$L1_CHAIN_ID

echo ""
echo "Jika Anda melihat kesalahan 'ValidatorQuotaFilledUntil', coba lagi setelah waktu yang ditunjukkan."
EOF
    
    chmod +x ~/register_validator.sh
    echo -e "${GREEN}Skrip pendaftaran validator dibuat di ~/register_validator.sh${NC}"
}

# Fungsi untuk memeriksa port forwarding
check_port_forwarding() {
    echo -e "${BLUE}${BOLD}Memeriksa port forwarding...${NC}"
    echo -e "${YELLOW}Penting: Anda perlu memastikan port $P2P_PORT (TCP dan UDP) diteruskan ke mesin ini dari router Anda.${NC}"
    echo -e "Silakan ikuti langkah-langkah ini:"
    echo -e "1. Akses panel admin router Anda (biasanya di 192.168.1.1 atau sejenisnya)"
    echo -e "2. Navigasi ke pengaturan port forwarding"
    echo -e "3. Buat aturan baru untuk meneruskan port $P2P_PORT (TCP dan UDP) ke IP lokal mesin ini"
    echo -e "4. Siapkan IP statis untuk mesin ini di pengaturan DHCP router Anda jika memungkinkan"
    echo ""
    read -p "Apakah Anda telah mengonfigurasi port forwarding di router Anda? (y/n): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}Peringatan: Node Anda mungkin tidak berfungsi dengan benar tanpa port forwarding yang tepat.${NC}"
        echo -e "Silakan konfigurasikan port forwarding sebelum melanjutkan."
    fi
}

# Fungsi untuk membuat layanan systemd
create_systemd_service() {
    echo -e "${BLUE}${BOLD}Membuat layanan systemd untuk memulai otomatis saat boot...${NC}"
    
    if [ "$EUID" -ne 0 ]; then
        echo -e "${YELLOW}Ini memerlukan hak akses sudo.${NC}"
    fi
    
    read -p "Apakah Anda ingin membuat layanan systemd untuk memulai node Anda secara otomatis saat boot? (y/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo bash -c "cat > /etc/systemd/system/aztec-sequencer.service << EOF
[Unit]
Description=Node Sequencer Aztec
After=network.target

[Service]
User=$USER
ExecStart=$HOME/start_aztec_sequencer.sh
Restart=on-failure
RestartSec=10
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF"
        
        sudo systemctl daemon-reload
        sudo systemctl enable aztec-sequencer.service
        
        echo -e "${GREEN}Layanan systemd dibuat dan diaktifkan.${NC}"
        echo -e "Anda sekarang dapat mengelola node Anda dengan perintah-perintah ini:"
        echo -e "${CYAN}sudo systemctl start aztec-sequencer${NC} - Memulai node"
        echo -e "${CYAN}sudo systemctl stop aztec-sequencer${NC} - Menghentikan node"
        echo -e "${CYAN}sudo systemctl status aztec-sequencer${NC} - Memeriksa status node"
        echo -e "${CYAN}journalctl -u aztec-sequencer -f${NC} - Melihat log"
    else
        echo -e "${YELLOW}Tidak ada layanan systemd yang dibuat. Anda perlu memulai node Anda secara manual menggunakan ~/start_aztec_sequencer.sh${NC}"
    fi
}

# Fungsi untuk menampilkan pesan penyelesaian
display_completion() {
    echo -e "${GREEN}${BOLD}Pengaturan Node Sequencer Aztec selesai!${NC}"
    echo -e "${BLUE}Langkah selanjutnya:${NC}"
    echo -e "1. Mulai node Aztec Anda dengan: ${CYAN}~/start_aztec_sequencer.sh${NC}"
    echo -e "   (Atau jika Anda membuat layanan systemd: ${CYAN}sudo systemctl start aztec-sequencer${NC})"
    echo -e "2. Tunggu node Anda sepenuhnya sinkron dengan jaringan"
    echo -e "3. Daftar sebagai validator dengan: ${CYAN}~/register_validator.sh${NC}"
    echo -e ""
    echo -e "${YELLOW}Catatan: Jika pendaftaran gagal dengan 'ValidatorQuotaFilledUntil', coba lagi setelah waktu yang ditunjukkan.${NC}"
    echo -e ""
    echo -e "${BLUE}Tips pemecahan masalah:${NC}"
    echo -e "- Perbarui tools Aztec: ${CYAN}aztec-up alpha-testnet${NC}"
    echo -e "- Jika Anda melihat kesalahan 'No blob bodies found', periksa endpoint konsensus L1 Anda"
    echo -e "- Untuk 'Insufficient L1 funds', dapatkan Sepolia ETH dari faucet"
    echo -e "- Untuk masalah sinkronisasi, Anda mungkin perlu menghapus data archiver dan memulai ulang:"
    echo -e "  ${CYAN}rm -rf ~/.aztec/alpha-testnet/data/archiver${NC}"
    echo -e ""
    echo -e "${GREEN}Gabung ke Discord Aztec untuk dukungan komunitas: https://discord.gg/aztec${NC}"
    echo -e "${GREEN}Telegram: https://t.me/nyariairdrop${NC}"
}

# Eksekusi utama dimulai di sini
display_welcome

# Inisialisasi variabel
REQUIREMENTS_MET=true

# Periksa persyaratan sistem
check_requirements

# Instal Docker jika diperlukan
install_docker

# Instal tools Aztec
install_aztec_tools

# Dapatkan konfigurasi dari pengguna
get_configuration

# Buat skrip startup dan validator
create_startup_script
create_validator_script

# Periksa port forwarding
check_port_forwarding

# Buat layanan systemd
create_systemd_service

# Tampilkan pesan penyelesaian
display_completion

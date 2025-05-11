#!/bin/bash

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Fungsi untuk menampilkan logo dan pesan selamat datang
display_welcome() {
    clear
    echo -e "${WHITE}"
    echo " _  _ _   _ ____ ____ _    ____ _ ____ ___  ____ ____ ___ "
    echo "|\\ |  \_/  |__| |__/ |    |__| | |__/ |  \ |__/ |  | |__]"
    echo "| \\|   |   |  | |  \ |    |  | | |  \ |__/ |  \ |__| |    "
    echo -e "${GREEN}"
    echo "Instalasi Otomatis Node Aztec Sequencer"
    echo -e "${YELLOW}"
    echo "Telegram: https://t.me/nyariairdrop"
    echo -e "${NC}"
    echo -e "${CYAN}Skrip ini akan membantu Anda menginstal dan mengonfigurasi Node Sequencer Aztec${NC}"
    echo -e "${CYAN}==================================================================${NC}"
    echo ""
}

# Fungsi untuk menampilkan proses instalasi
display_progress() {
    echo -e "${CYAN}[$1/${TOTAL_STEPS}] $2${NC}"
    sleep 1
}

# Fungsi untuk memeriksa persyaratan sistem
check_system_requirements() {
    display_progress "1" "Memeriksa persyaratan sistem..."
    
    # Cek CPU cores
    CPU_CORES=$(nproc)
    
    # Cek RAM (dalam MB)
    TOTAL_RAM=$(free -m | awk '/^Mem:/ {print $2}')
    
    # Cek disk space (dalam GB)
    DISK_SPACE=$(df -BG / | awk '/^\/dev/ {gsub("G", "", $4); print $4}')
    
    echo -e "CPU cores: ${GREEN}$CPU_CORES${NC} (rekomendasi: 8+)"
    echo -e "Total RAM: ${GREEN}$TOTAL_RAM MB${NC} (rekomendasi: 16GB+)"
    echo -e "Ruang disk: ${GREEN}$DISK_SPACE GB${NC} (rekomendasi: 100GB+)"
    
    echo ""
    echo -e "${YELLOW}Catatan: Persyaratan minimal untuk Sequencer Node adalah 8 cores CPU, 16GB RAM, dan 100GB SSD.${NC}"
    echo -e "${YELLOW}Node dapat berjalan dengan spesifikasi yang lebih rendah tetapi mungkin tidak optimal.${NC}"
    
    read -p "Lanjutkan instalasi? (y/n): " CONTINUE
    if [[ $CONTINUE != "y" && $CONTINUE != "Y" ]]; then
        echo -e "${RED}Instalasi dibatalkan.${NC}"
        exit 1
    fi
}

# Fungsi untuk menginstal dependencies
install_dependencies() {
    display_progress "2" "Menginstal dependencies..."
    
    echo -e "${YELLOW}Memperbarui packages...${NC}"
    sudo apt-get update && sudo apt-get upgrade -y
    
    echo -e "${YELLOW}Menginstal packages yang dibutuhkan...${NC}"
    sudo apt install curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev -y
    
    echo -e "${YELLOW}Menginstal Docker...${NC}"
    for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove $pkg; done
    
    sudo apt-get update
    sudo apt-get install ca-certificates curl gnupg -y
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    
    echo \
      "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    sudo apt update -y && sudo apt upgrade -y
    
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
    
    # Test Docker
    sudo docker run hello-world
    
    sudo systemctl enable docker
    sudo systemctl restart docker
    
    echo -e "${GREEN}Dependencies berhasil diinstal.${NC}"
}

# Fungsi untuk menginstal Aztec Tools
install_aztec_tools() {
    display_progress "3" "Menginstal Aztec Tools..."
    
    bash -i <(curl -s https://install.aztec.network)
    
    echo 'export PATH="$HOME/.aztec/bin:$PATH"' >> ~/.bashrc
    
    source ~/.bashrc
    
    echo -e "${GREEN}Aztec Tools berhasil diinstal.${NC}"
    echo -e "${YELLOW}Pastikan untuk membuka terminal baru atau menjalankan 'source ~/.bashrc' setelah instalasi selesai.${NC}"
}

# Fungsi untuk memperbarui Aztec
update_aztec() {
    display_progress "4" "Memperbarui Aztec..."
    
    aztec-up alpha-testnet
    
    echo -e "${GREEN}Aztec berhasil diperbarui.${NC}"
}

# Fungsi untuk mengambil RPC URL
obtain_rpc_urls() {
    display_progress "5" "Mengonfigurasi RPC URLs..."
    
    echo -e "${YELLOW}Anda memerlukan:${NC}"
    echo "1. Sepolia RPC URL (misalnya dari Alchemy)"
    echo "2. Sepolia Beacon URL (misalnya dari drpc)"
    echo ""
    echo -e "${YELLOW}Rekomendasi:${NC}"
    echo "- RPC URL: Daftar di https://dashboard.alchemy.com/ dan buat Sepolia Ethereum HTTP API"
    echo "- Beacon URL: Daftar di https://drpc.org/ dan cari 'Sepolia Ethereum Beacon Chain' Endpoints"
    echo ""
    
    read -p "Masukkan Sepolia RPC URL: " RPC_URL
    read -p "Masukkan Sepolia Beacon URL: " BEACON_URL
    
    echo -e "${GREEN}RPC URLs berhasil dikonfigurasi.${NC}"
}

# Fungsi untuk menghasilkan kunci Ethereum
generate_ethereum_keys() {
    display_progress "6" "Mengonfigurasi kunci Ethereum..."
    
    echo -e "${YELLOW}Anda perlu kunci pribadi dan alamat publik dompet EVM.${NC}"
    echo "Pastikan dompet ini memiliki Sepolia ETH."
    echo ""
    
    read -p "Masukkan Private Key (tanpa 0x): " PRIVATE_KEY
    read -p "Masukkan Public Address (dengan 0x): " PUBLIC_ADDRESS
    
    # Tambahkan 0x jika tidak ada
    if [[ $PRIVATE_KEY != 0x* ]]; then
        PRIVATE_KEY="0x$PRIVATE_KEY"
    fi
    
    echo -e "${GREEN}Kunci Ethereum berhasil dikonfigurasi.${NC}"
}

# Fungsi untuk mendapatkan IP
get_ip() {
    display_progress "7" "Mendapatkan IP server..."
    
    SERVER_IP=$(curl -s ipv4.icanhazip.com)
    
    echo -e "IP Server Anda: ${GREEN}$SERVER_IP${NC}"
    read -p "Gunakan IP ini? (y/n): " USE_IP
    
    if [[ $USE_IP != "y" && $USE_IP != "Y" ]]; then
        read -p "Masukkan IP yang ingin digunakan: " SERVER_IP
    fi
    
    echo -e "${GREEN}IP berhasil dikonfigurasi.${NC}"
}

# Fungsi untuk mengaktifkan firewall dan membuka port
enable_firewall() {
    display_progress "8" "Mengaktifkan firewall dan membuka port..."
    
    sudo ufw allow 22
    sudo ufw allow ssh
    sudo ufw allow 40400
    sudo ufw allow 8080
    echo "y" | sudo ufw enable
    
    echo -e "${GREEN}Firewall diaktifkan dan port dibuka.${NC}"
}

# Fungsi untuk menjalankan Sequencer Node
run_sequencer_node() {
    if [ "$1" == "help_menu" ]; then
        echo -e "${YELLOW}Menjalankan Node Sequencer...${NC}"
    else
        display_progress "9" "Menyiapkan Sequencer Node..."
    fi
    
    if [ "$1" == "help_menu" ] && [ -z "$RPC_URL" -o -z "$BEACON_URL" -o -z "$PRIVATE_KEY" -o -z "$PUBLIC_ADDRESS" -o -z "$SERVER_IP" ]; then
        echo -e "${RED}Error: Informasi konfigurasi tidak lengkap.${NC}"
        echo -e "${YELLOW}Silakan konfigurasi node terlebih dahulu (Opsi 2 di Menu Utama).${NC}"
        return 1
    fi
    
    echo "Perintah untuk menjalankan node:"
    echo -e "${CYAN}aztec start --node --archiver --sequencer \\
  --network alpha-testnet \\
  --l1-rpc-urls $RPC_URL \\
  --l1-consensus-host-urls $BEACON_URL \\
  --sequencer.validatorPrivateKey $PRIVATE_KEY \\
  --sequencer.coinbase $PUBLIC_ADDRESS \\
  --p2p.p2pIp $SERVER_IP \\
  --p2p.maxTxPoolSize 1000000000${NC}"
    
    echo ""
    if [ "$1" == "help_menu" ]; then
        read -p "Jalankan node sekarang? (y/n): " RUN_NODE
    else
        read -p "Jalankan node sekarang? (y/n): " RUN_NODE
    fi
    
    if [[ $RUN_NODE == "y" || $RUN_NODE == "Y" ]]; then
        # Pastikan tidak ada instance node yang berjalan
        docker stop $(docker ps -q --filter "ancestor=aztecprotocol/aztec") 2>/dev/null && docker rm $(docker ps -a -q --filter "ancestor=aztecprotocol/aztec") 2>/dev/null
        screen -ls | grep -i aztec | awk '{print $1}' | xargs -I {} screen -X -S {} quit 2>/dev/null
        
        # Jalankan node baru
        screen -S aztec -dm bash -c "aztec start --node --archiver --sequencer --network alpha-testnet --l1-rpc-urls $RPC_URL --l1-consensus-host-urls $BEACON_URL --sequencer.validatorPrivateKey $PRIVATE_KEY --sequencer.coinbase $PUBLIC_ADDRESS --p2p.p2pIp $SERVER_IP --p2p.maxTxPoolSize 1000000000"
        
        echo -e "${GREEN}Node Sequencer sedang berjalan di latar belakang.${NC}"
        echo -e "Untuk melihat output: ${YELLOW}screen -r aztec${NC}"
        echo -e "Untuk keluar dari screen: ${YELLOW}Ctrl+A+D${NC}"
    else
        echo -e "${YELLOW}Node tidak dijalankan.${NC}"
        echo -e "Untuk menjalankan node nanti, gunakan perintah:"
        echo -e "${CYAN}screen -S aztec${NC}"
        echo -e "${CYAN}aztec start --node --archiver --sequencer \\
  --network alpha-testnet \\
  --l1-rpc-urls $RPC_URL \\
  --l1-consensus-host-urls $BEACON_URL \\
  --sequencer.validatorPrivateKey $PRIVATE_KEY \\
  --sequencer.coinbase $PUBLIC_ADDRESS \\
  --p2p.p2pIp $SERVER_IP \\
  --p2p.maxTxPoolSize 1000000000${NC}"
    fi
}

# Fungsi untuk mendapatkan block number terbaru
get_latest_block() {
    if ! command_exists curl || ! command_exists jq; then
        echo -e "${RED}Error: curl atau jq tidak terinstal.${NC}"
        return 1
    fi
    
    LATEST_BLOCK=$(curl -s -X POST -H 'Content-Type: application/json' \
        -d '{"jsonrpc":"2.0","method":"node_getL2Tips","params":[],"id":67}' \
        http://localhost:8080 | jq -r ".result.proven.number" 2>/dev/null)
    
    if [[ -z "$LATEST_BLOCK" || "$LATEST_BLOCK" == "null" ]]; then
        echo -e "${RED}Error: Tidak dapat mendapatkan block number. Pastikan node berjalan dan tersinkronisasi.${NC}"
        return 1
    fi
    
    echo -e "Block number terbaru: ${GREEN}$LATEST_BLOCK${NC}"
    return 0
}

# Fungsi untuk mendapatkan sync proof
get_sync_proof() {
    if [ -z "$LATEST_BLOCK" ]; then
        get_latest_block
        if [ $? -ne 0 ]; then
            return 1
        fi
    fi
    
    SYNC_PROOF=$(curl -s -X POST -H 'Content-Type: application/json' \
        -d "{\"jsonrpc\":\"2.0\",\"method\":\"node_getArchiveSiblingPath\",\"params\":[\"$LATEST_BLOCK\",\"$LATEST_BLOCK\"],\"id\":67}" \
        http://localhost:8080 | jq -r ".result" 2>/dev/null)
    
    if [[ -z "$SYNC_PROOF" || "$SYNC_PROOF" == "null" ]]; then
        echo -e "${RED}Error: Tidak dapat mendapatkan sync proof. Pastikan node berjalan dan tersinkronisasi.${NC}"
        return 1
    fi
    
    echo -e "Sync proof: ${GREEN}$SYNC_PROOF${NC}"
    return 0
}

# Fungsi untuk mendaftar validator
register_validator() {
    echo -e "${YELLOW}Mendaftarkan validator...${NC}"
    
    # Jalankan perintah register validator
    aztec add-l1-validator \
        --l1-rpc-urls $RPC_URL \
        --private-key $PRIVATE_KEY \
        --attester $PUBLIC_ADDRESS \
        --proposer-eoa $PUBLIC_ADDRESS \
        --staking-asset-handler 0xF739D03e98e23A7B65940848aBA8921fF3bAc4b2 \
        --l1-chain-id 11155111
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Validator berhasil didaftarkan!${NC}"
    else
        echo -e "${RED}Gagal mendaftarkan validator. Mungkin kuota harian telah tercapai.${NC}"
        echo -e "${YELLOW}Catatan: Ada kuota 10 pendaftaran validator per hari.${NC}"
    fi
}

# Fungsi untuk mendapatkan Peer ID node
get_peer_id() {
    PEER_ID=$(sudo docker logs $(docker ps -q --filter ancestor=aztecprotocol/aztec:alpha-testnet | head -n 1) 2>&1 | grep -i "peerId" | grep -o '"peerId":"[^"]*"' | cut -d'"' -f4 | head -n 1)
    
    if [ -z "$PEER_ID" ]; then
        echo -e "${RED}Error: Tidak dapat mendapatkan Peer ID. Pastikan node berjalan.${NC}"
        return 1
    fi
    
    echo -e "Peer ID node Anda: ${GREEN}$PEER_ID${NC}"
    echo -e "Cek status node di: ${CYAN}https://aztec.nethermind.io/${NC}"
    return 0
}

# Fungsi untuk memperbarui node
update_node() {
    echo -e "${YELLOW}Memperbarui node...${NC}"
    
    # Hentikan node
    echo -e "Menghentikan node..."
    docker stop $(docker ps -q --filter "ancestor=aztecprotocol/aztec") 2>/dev/null && docker rm $(docker ps -a -q --filter "ancestor=aztecprotocol/aztec") 2>/dev/null
    screen -ls | grep -i aztec | awk '{print $1}' | xargs -I {} screen -X -S {} quit 2>/dev/null
    
    # Perbarui node
    echo -e "Memperbarui Aztec..."
    aztec-up alpha-testnet
    
    # Hapus data lama
    echo -e "Menghapus data lama..."
    rm -rf ~/.aztec/alpha-testnet/data/
    
    echo -e "${GREEN}Node berhasil diperbarui!${NC}"
    echo -e "${YELLOW}Untuk menjalankan kembali node, pilih opsi 3 dari menu utama.${NC}"
}

# Fungsi untuk mengatasi error umum
fix_common_errors() {
    echo -e "${YELLOW}Mengatasi error umum...${NC}"
    
    # Hentikan node
    echo -e "Menghentikan node..."
    docker stop $(docker ps -q --filter "ancestor=aztecprotocol/aztec") 2>/dev/null && docker rm $(docker ps -a -q --filter "ancestor=aztecprotocol/aztec") 2>/dev/null
    screen -ls | grep -i aztec | awk '{print $1}' | xargs -I {} screen -X -S {} quit 2>/dev/null
    
    # Hapus data node
    echo -e "Menghapus data node..."
    rm -r $HOME/.aztec/alpha-testnet 2>/dev/null
    
    echo -e "${GREEN}Perbaikan selesai!${NC}"
    echo -e "${YELLOW}Untuk menjalankan kembali node, pilih opsi 3 dari menu utama.${NC}"
}

# Fungsi untuk memeriksa apakah command tersedia
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Fungsi untuk menampilkan menu bantuan
display_help_menu() {
    clear
    display_welcome
    
    echo -e "${CYAN}MENU BANTUAN AZTEC SEQUENCER NODE${NC}"
    echo -e "${CYAN}==================================================================${NC}"
    echo ""
    echo -e "  ${GREEN}1${NC}. Jalankan/Restart Node Sequencer"
    echo -e "  ${GREEN}2${NC}. Dapatkan Block Number & Sync Proof"
    echo -e "  ${GREEN}3${NC}. Daftarkan Validator"
    echo -e "  ${GREEN}4${NC}. Cek Peer ID Node"
    echo -e "  ${GREEN}5${NC}. Perbarui Node"
    echo -e "  ${GREEN}6${NC}. Atasi Error Umum"
    echo -e "  ${GREEN}7${NC}. Lihat Status Node"
    echo -e "  ${GREEN}8${NC}. Hentikan Node"
    echo -e "  ${GREEN}0${NC}. Kembali ke Menu Utama"
    echo ""
    echo -e "${CYAN}==================================================================${NC}"
    echo -e "  ${GREEN}x${NC}. Keluar"
    echo ""
    
    read -p "Pilih opsi [0-8]: " HELP_OPTION
    
    case $HELP_OPTION in
        1)
            run_sequencer_node
            echo -e "${YELLOW}Tekan Enter untuk kembali ke menu...${NC}"
            read
            display_help_menu
            ;;
        2)
            get_latest_block
            echo ""
            get_sync_proof
            echo ""
            echo -e "${YELLOW}Gunakan informasi di atas untuk menjalankan perintah /operator start di Discord${NC}"
            echo -e "${YELLOW}dan isi field berikut:${NC}"
            echo -e "address: ${CYAN}$PUBLIC_ADDRESS${NC}"
            echo -e "block-number: ${CYAN}$LATEST_BLOCK${NC}"
            echo -e "proof: ${CYAN}$SYNC_PROOF${NC}"
            echo ""
            echo -e "${YELLOW}Tekan Enter untuk kembali ke menu...${NC}"
            read
            display_help_menu
            ;;
        3)
            register_validator
            echo -e "${YELLOW}Tekan Enter untuk kembali ke menu...${NC}"
            read
            display_help_menu
            ;;
        4)
            get_peer_id
            echo -e "${YELLOW}Tekan Enter untuk kembali ke menu...${NC}"
            read
            display_help_menu
            ;;
        5)
            update_node
            echo -e "${YELLOW}Tekan Enter untuk kembali ke menu...${NC}"
            read
            display_help_menu
            ;;
        6)
            fix_common_errors
            echo -e "${YELLOW}Tekan Enter untuk kembali ke menu...${NC}"
            read
            display_help_menu
            ;;
        7)
            echo -e "${YELLOW}Melihat status node...${NC}"
            if ! screen -ls | grep -q aztec; then
                echo -e "${RED}Node tidak berjalan.${NC}"
            else
                echo -e "${GREEN}Node sedang berjalan.${NC}"
                echo -e "Untuk melihat output node, jalankan: ${CYAN}screen -r aztec${NC}"
            fi
            echo -e "${YELLOW}Tekan Enter untuk kembali ke menu...${NC}"
            read
            display_help_menu
            ;;
        8)
            echo -e "${YELLOW}Menghentikan node...${NC}"
            docker stop $(docker ps -q --filter "ancestor=aztecprotocol/aztec") 2>/dev/null && docker rm $(docker ps -a -q --filter "ancestor=aztecprotocol/aztec") 2>/dev/null
            screen -ls | grep -i aztec | awk '{print $1}' | xargs -I {} screen -X -S {} quit 2>/dev/null
            echo -e "${GREEN}Node berhasil dihentikan.${NC}"
            echo -e "${YELLOW}Tekan Enter untuk kembali ke menu...${NC}"
            read
            display_help_menu
            ;;
        0)
            main_menu
            ;;
        x|X)
            echo -e "${GREEN}Terima kasih telah menggunakan skrip ini!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Opsi tidak valid. Silakan coba lagi.${NC}"
            echo -e "${YELLOW}Tekan Enter untuk kembali ke menu...${NC}"
            read
            display_help_menu
            ;;
    esac
}

# Fungsi untuk menampilkan kesimpulan
display_conclusion() {
    echo ""
    echo -e "${GREEN}==================================================================${NC}"
    echo -e "${GREEN}Instalasi Node Sequencer Aztec selesai!${NC}"
    echo ""
    echo -e "${YELLOW}Ringkasan informasi:${NC}"
    echo -e "RPC URL: ${CYAN}$RPC_URL${NC}"
    echo -e "Beacon URL: ${CYAN}$BEACON_URL${NC}"
    echo -e "Public Address: ${CYAN}$PUBLIC_ADDRESS${NC}"
    echo -e "IP Server: ${CYAN}$SERVER_IP${NC}"
    echo ""
    echo -e "${YELLOW}Perintah penting:${NC}"
    echo -e "- Lihat output node: ${CYAN}screen -r aztec${NC}"
    echo -e "- Keluar dari screen: ${CYAN}Ctrl+A+D${NC}"
    echo -e "- Hentikan node: ${CYAN}screen -XS aztec quit${NC}"
    echo ""
    echo -e "${GREEN}Terima kasih telah menggunakan skrip ini!${NC}"
    echo -e "${GREEN}Telegram: https://t.me/nyariairdrop${NC}"
    echo -e "${GREEN}==================================================================${NC}"
    echo ""
    echo -e "${YELLOW}Tekan Enter untuk membuka menu bantuan...${NC}"
    read
    display_help_menu
}

# Fungsi menu utama
main_menu() {
    clear
    display_welcome
    
    echo -e "${CYAN}MENU UTAMA AZTEC SEQUENCER NODE${NC}"
    echo -e "${CYAN}==================================================================${NC}"
    echo ""
    echo -e "  ${GREEN}1${NC}. Instal Node Sequencer Baru"
    echo -e "  ${GREEN}2${NC}. Konfigurasi Node yang Sudah Ada"
    echo -e "  ${GREEN}3${NC}. Menu Bantuan"
    echo -e "  ${GREEN}0${NC}. Keluar"
    echo ""
    echo -e "${CYAN}==================================================================${NC}"
    echo ""
    
    read -p "Pilih opsi [0-3]: " MAIN_OPTION
    
    case $MAIN_OPTION in
        1)
            install_new_node
            ;;
        2)
            configure_existing_node
            ;;
        3)
            display_help_menu
            ;;
        0)
            echo -e "${GREEN}Terima kasih telah menggunakan skrip ini!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Opsi tidak valid. Silakan coba lagi.${NC}"
            echo -e "${YELLOW}Tekan Enter untuk kembali ke menu...${NC}"
            read
            main_menu
            ;;
    esac
}

# Fungsi untuk menginstal node baru
install_new_node() {
    # Menampilkan pesan selamat datang
    display_welcome
    
    # Mengatur total langkah
    TOTAL_STEPS=9
    
    # Menjalankan fungsi instalasi
    check_system_requirements
    install_dependencies
    install_aztec_tools
    update_aztec
    obtain_rpc_urls
    generate_ethereum_keys
    get_ip
    enable_firewall
    run_sequencer_node
    
    # Menampilkan kesimpulan
    display_conclusion
}

# Fungsi untuk mengkonfigurasi node yang sudah ada
configure_existing_node() {
    clear
    display_welcome
    
    echo -e "${CYAN}KONFIGURASI NODE YANG SUDAH ADA${NC}"
    echo -e "${CYAN}==================================================================${NC}"
    echo ""
    
    # Ambil informasi konfigurasi yang diperlukan
    echo -e "${YELLOW}Masukkan informasi konfigurasi yang diperlukan:${NC}"
    echo ""
    
    read -p "Masukkan Sepolia RPC URL: " RPC_URL
    read -p "Masukkan Sepolia Beacon URL: " BEACON_URL
    read -p "Masukkan Private Key (tanpa 0x): " PRIVATE_KEY
    read -p "Masukkan Public Address (dengan 0x): " PUBLIC_ADDRESS
    
    # Tambahkan 0x jika tidak ada
    if [[ $PRIVATE_KEY != 0x* ]]; then
        PRIVATE_KEY="0x$PRIVATE_KEY"
    fi
    
    # Dapatkan IP server
    SERVER_IP=$(curl -s ipv4.icanhazip.com)
    
    echo -e "IP Server Anda: ${GREEN}$SERVER_IP${NC}"
    read -p "Gunakan IP ini? (y/n): " USE_IP
    
    if [[ $USE_IP != "y" && $USE_IP != "Y" ]]; then
        read -p "Masukkan IP yang ingin digunakan: " SERVER_IP
    fi
    
    echo -e "${GREEN}Konfigurasi berhasil disimpan.${NC}"
    echo -e "${YELLOW}Tekan Enter untuk membuka menu bantuan...${NC}"
    read
    display_help_menu
}

# Fungsi utama
main() {
    main_menu
}

# Menjalankan fungsi utama
main

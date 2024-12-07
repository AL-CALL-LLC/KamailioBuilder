# KamailioBuilder  
**Automate the installation of Kamailio from source with ease**  

[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)  
[![Open Source](https://badges.frapsoft.com/os/v1/open-source.svg?v=103)](https://opensource.org/)  

KamailioBuilder is an open-source tool designed to simplify the process of downloading, compiling, and installing the [Kamailio SIP server](https://kamailio.org). Whether you're a VoIP enthusiast, developer, or system administrator, KamailioBuilder provides a seamless way to set up Kamailio on your system.  

---

## 🚀 Features  
- Fully automated download, compilation, and installation process.  
- Supports Debian-based systems.  
- Configures essential Kamailio modules (e.g., MySQL, TLS).  
- Lightweight, flexible, and easy to use.  

---

## 🛠 Prerequisites  
- A Debian-based Linux distribution (e.g., Ubuntu, Debian).  
- Root or `sudo` privileges.  
- Internet connection for downloading dependencies and source code.  

---

## ⚙️ Installation  
### 1. Download the script 
Download and execute the script. 
```bash
curl -O https://raw.githubusercontent.com/AL-CALL-LLC/KamailioBuilder/refs/heads/main/kamailio_install.sh
chmod +x kamailio_install.sh
./kamailio_install.sh
```

### 2. Update your PATH if ```kamailio``` Command doesn't work directly
After installation, ensure Kamailio is available in your shell's environment:
```bash
source ~/.bashrc
```
Alternatively, run the script in the current shell session:
```bash
. kamailio_install.sh
```

---

## 🧩 How It Works  
The script automates the following tasks:  
1. **System Checks**:  
   Verifies root privileges, system compatibility, and existing installations.  

2. **Dependency Installation**:  
   Installs required packages like `gcc`, `make`, and `libssl-dev`.  

3. **Source Code Management**:  
   Downloads and updates Kamailio's source code from its Git repository.  

4. **Compilation and Installation**:  
   Builds and installs Kamailio with modules like `db_mysql` and `tls`.  

5. **Database Setup**:  
   Configures MySQL for Kamailio's database requirements.  

6. **Systemd Configuration**:  
   Sets up Kamailio as a service managed by `systemd`.  

7. **User Management**:  
   Adds a test user with a randomly generated secure password.  

---

## 🔧 Troubleshooting  
If you encounter issues:  
1. **Ensure your system meets all prerequisites.**  
2. **Check the output logs for specific errors.**  
3. **Open an issue in the GitHub repository** with detailed information.  

---

## 📜 License  
This project is licensed under the [MIT License](LICENSE). See the LICENSE file for more details.  

---

## 🙌 Acknowledgments  
We extend our gratitude to:  
- The Kamailio development team for their incredible SIP server. 

🚀 Simplify your Kamailio setup with **KamailioBuilder**. Contribute, share, and enjoy the power of open source!  

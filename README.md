# HƯỚNG DẪN CHẠY BÀI LAB VỀ METASPLOIT

## Mô tả bài lab
Bài lab này được thiết kế nhằm giúp sinh viên thực hành kỹ thuật tấn công với công cụ Metasploit trên môi trường ảo hóa Labtainer. Nội dung thực hành bao gồm khai thác lỗ hổng trên ứng dụng web hoặc dịch vụ mạng, sử dụng các công cụ như `nmap`, `curl`, `Metasploit Framework`, và nhiều công cụ hỗ trợ khác.

## Yêu cầu hệ thống
- **Hệ điều hành**: Ubuntu (hoặc các phiên bản Linux tương thích)
- **Công cụ cần thiết**:
  - Labtainer
  - Docker
- **Tài nguyên máy tính**: RAM >= 4GB, CPU >= 2 cores.

## Cài đặt môi trường
### 1. Cài đặt Labtainer và Docker
Thực hiện các lệnh sau để cài đặt Labtainer:
```bash
git clone https://github.com/mfthomps/Labtainer.git
cd Labtainer/setup_scripts
./install-labtainer.sh
```
Cài đặt Docker:
```bash
sudo apt update
sudo apt install docker.io
sudo systemctl start docker
sudo systemctl enable docker
```
Hoặc đơn giản hơn có thể tải file Labtair Labtainer cài đặt trên VMWARE: 
```bash
 https://nps.box.com/shared/static/2chwo31xgxm2hs4hewp2n4nblroyagwz.ova
```
### 2. Cài đặt OpenJDK 17 và Sử dụng file upadte-designer.sh để sử dụng Labedit
Thực hiện các lệnh sau để cài đặt Labtainer:
```bash
sudo apt-get install openjdk-17-jdk
```
Cấu hình môi trường để sử dụng Labedit:
```bash
~/labtainer/update-designer.sh
```
### 3. Triển khai bài lab
Copy bài các bài labs đã tải về vào thư mục:
```bash
~/labtainer/trunk/labs
```
Hoặc Sử dụng câu lệnh Imodule:
```bash
imodule https://raw.githubusercontent.com/NguyenHongAnh0812/<tên bài lab>/main/imodule.tar
```
Khởi động bài lab với Labtainer:
```bash
labtainer <tên bài lab>
```




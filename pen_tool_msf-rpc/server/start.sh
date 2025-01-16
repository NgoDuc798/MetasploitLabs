#!/bin/bash

# Khởi động Apache
service apache2 start

# Khởi động msfrpcd
/home/metasploit-framework-5.0.100/msfrpcd -U msf -P abc123 -a 0.0.0.0 -p 55553 -y


msfd -a 0.0.0.0 -p 55554 &

# Giữ cho container chạy
tail -f /dev/null



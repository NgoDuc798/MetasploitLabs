import os
import random

def create_random_flags():
    # Các thư mục mục tiêu
    directories = ["/home/ubuntu/Security", "/home/ubuntu/AppData", "/home/ubuntu/Sharing"]

    # Tạo tất cả các thư mục nếu chưa tồn tại
    for directory in directories:
        os.makedirs(directory, exist_ok=True)

    # Tên file cho các cờ
    file_names = [
        "FLAG1.txt",
        "FLAG2.txt"
    ]

    # Nội dung cờ
    contents = [
        "SUCESS_29AQ39_WELL_DONE",
        "THANK_FOR_DOING_LABS_12HS643X"
    ]

    # Gán ngẫu nhiên vị trí đặt cờ cho từng cờ
    for file_name, content in zip(file_names, contents):
        target_dir = random.choice(directories)  # Chọn ngẫu nhiên thư mục
        file_path = os.path.join(target_dir, file_name)

        # Tạo file với nội dung
        with open(file_path, "w") as f:
            f.write(content)

        print(f"Flag created at: {file_path} with content: {content}")

# Chạy hàm
if __name__ == "__main__":
    create_random_flags()


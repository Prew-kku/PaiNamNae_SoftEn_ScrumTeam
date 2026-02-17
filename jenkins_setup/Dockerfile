# ใช้ตัวตั้งต้นจาก Official
FROM jenkins/jenkins:lts

# เปลี่ยนเป็น root เพื่อติดตั้งโปรแกรม
USER root

# สั่งติดตั้ง Docker ลงไปใน Image นี้เลย (จะได้ไม่ต้องมาพิมพ์เองทีหลัง)
RUN apt-get update && \
    apt-get install -y docker.io && \
    #ไปโหลด Docker Compose มาใส่ใน Image ด้วยเลย (จะได้ไม่ต้องมาพิมพ์เองทีหลัง)
    curl -L "https://github.com/docker/compose/releases/download/v2.24.6/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && \
    chmod +x /usr/local/bin/docker-compose && \
    rm -rf /var/lib/apt/lists/*
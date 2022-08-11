#!/bin/bash

amazon-linux-extras install docker -y
curl -SL https://github.com/docker/compose/releases/download/v2.5.0/docker-compose-linux-x86_64 \
  -o /usr/bin/docker-compose
chmod ugo+x /usr/bin/docker-compose
usermod -aG docker ec2-user
systemctl enable docker
systemctl start docker
yum install -y unzip
cd /tmp
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

cd /home/ec2-user/

su - ec2-user -c 'mkdir ~/vpn/'
su - ec2-user -c "MOST_RECENT_BACKUP=`aws s3 ls --recursive s3://${AWS_BACKUP_BUCKET}/vpn/ | sort | tail -1 | awk '{print \$4}'` && [ ! -z \$MOST_RECENT_BACKUP ] && aws s3 cp s3://${AWS_BACKUP_BUCKET}/\$MOST_RECENT_BACKUP backup.tar.gz && sudo tar --overwrite -xvf backup.tar.gz "
chown ec2-user:ec2-user ./ -R
echo "30 5 * * * tar cvf /home/ec2-user/backup.tar.gz -C /home/ec2-user/ vpn/ && chown ec2-user:ec2-user /home/ec2-user/backup.tar.gz" > /tmp/giteacron 
crontab /tmp/giteacron
su - ec2-user -c 'echo "0 6 * * * aws s3 cp backup.tar.gz s3://${AWS_BACKUP_BUCKET}/vpn/vpn-\$(date --iso).tar.gz" > giteacron'
su - ec2-user -c 'crontab giteacron'
su - ec2-user -c 'docker run -d \
  --name=wireguard \
  --cap-add=NET_ADMIN \
  --cap-add=SYS_MODULE \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=Europe/London \
  -e SERVERURL=vpn.vilarinho.click \
  -e SERVERPORT=51820 \
  -e PEERS=1 \
  -e PEERDNS=auto \
  -e LOG_CONFS=false \
  -p 51820:51820/udp \
  -v /home/ec2-user/vpn/:/config \
  -v /lib/modules:/lib/modules \
  --sysctl="net.ipv4.conf.all.src_valid_mark=1" \
  --restart unless-stopped \
  lscr.io/linuxserver/wireguard:latest'

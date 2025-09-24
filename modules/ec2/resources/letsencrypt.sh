# Setup LetsEncrypt
sudo amazon-linux-extras install epel -y
sudo yum install -y certbot
sudo certbot certonly -n --agree-tos --no-eff-email -a standalone -m webmaster@[[DOMAIN]] -d [[DOMAIN]]
# Add cronjob to renew & restart nightscout
(crontab -l && echo "30 2 * * 1 certbot renew >> /var/log/le-renew.log | systemctl restart nightscout.service") | crontab -

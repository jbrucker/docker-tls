# Run this command inside the running certbot container
# to obtain an initial certbot certificate.
# --webroot    means to use the web-based token challenge (HTTP-01).
# --webroot-path is the path to your web server's html root
#
# Requirements:
# 1. The certbot and nginx containers should already be running (up).
# 2. Set the docker context to the host where this should run.
# 3. Both certbot and docker share an external volume for the
#    challenge file.

HOSTNAME=lab066.kasetsart.university
EMAIL=j.brucker@ku.th

docker compose run --rm certbot -v certonly \
  --webroot \
  --webroot-path=/var/www/certbot \
  --email $EMAIL \
  --agree-tos \
  --force-ipv4 \
  -d $HOSTNAME

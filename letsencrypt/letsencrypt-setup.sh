#! /bin/bash

set -e

if [ -z "$SITES" ]; then
  echo "The SITES variable is unset.  Please set it in any dockerfile which extends from this image." 1>&2
  echo "Example: www.test.com,test.com,web.test.com" 1>&2
  echo "This variable is passed to the letsencrypt client through the -h flag."
  exit 111
fi

LE_ARGS=("certonly" "--standalone" "--agree-tos" "--noninteractive" "-h" "'$SITES'")

if [ -z "$LETSENCRYPT_EMAIL" ]; then
  echo "LETSENCRYPT_EMAIL variable not set... Not setting a user email.  This is discouraged by letsencrypt."
  LE_ARGS+=("--register-unsafely-without-email")
else
  echo "Using \"$LETSENCRYPT_EMAIL\" for email."
  LE_ARGS+=("--email" "$LETSENCRYPT_EMAIL")
fi

if [ -z "$DEVELOPMENT" -o "$DEVELOPMENT" = "True" ]; then
  echo "Development mode detected.. Only attempting a dry run."
  LE_ARGS+=("--dry-run")
  # set up "renewal" to test cron in development.
  cat > /usr/local/bin/le-cron.sh <<!EOF
    #! /bin/bash
    echo "Development mode... Not renewing." >> /var/log/letsencrypt.log"
  EOF
else
  # set up cron to renew in production.
  cat > /usr/local/bin/le-cron.sh <<!EOF
    #! /bin/bash
    echo "Checking for outdated certificates..." >> /var/log/letsencrypt.log
    letsencrypt certonly --noninteractive --webroot --webroot-path /usr/share/nginx/html --keep-until-expiring >> /var/log/letsencrypt.log
  EOF
fi
echo "Setting up proper permissions on the cron script..."
chmod 755 /usr/local/bin/le-cron.sh

echo "Generating certificates..."
letsencrypt "${LE_ARGS[@]}"

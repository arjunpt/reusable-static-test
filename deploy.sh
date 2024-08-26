# #!/bin/bash

# Check for existing application and remove if necessary
if [ -d /var/www/app ]; then
    echo "Deleting old app"
    sudo rm -rf /var/www/app
fi

echo "Creating app folder"
sudo mkdir -p /var/www/app

echo "Moving files to app folder"
sudo mv * /var/www/app

# Update package list and install Python and Pip
echo "Updating package list"
sudo apt-get update

echo "Installing Python and Pip"
sudo apt-get install -y python3 python3-pip

# Install application dependencies from requirements.txt
echo "Installing application dependencies from requirements.txt"
sudo pip3 install -r /var/www/app/requirements.txt

# Install and configure Nginx
if ! command -v nginx > /dev/null; then
    echo "Installing Nginx"
    sudo apt-get install -y nginx
fi

if [ ! -f /etc/nginx/sites-available/myapp ]; then
    echo "Configuring Nginx"
    sudo rm -f /etc/nginx/sites-enabled/default
    sudo bash -c 'cat > /etc/nginx/sites-available/myapp <<EOF
server {
    listen 80;
    server_name _;

    location / {
        include proxy_params;
        proxy_pass http://unix:/var/www/app/src/myapp.sock;
    }
}
EOF'
    sudo ln -s /etc/nginx/sites-available/myapp /etc/nginx/sites-enabled
    sudo systemctl restart nginx
else
    echo "Nginx reverse proxy configuration already exists."
fi

# Install and start Gunicorn
echo "Starting Gunicorn"
cd /var/www/app/src

# Ensure Gunicorn is installed
sudo pip3 install gunicorn

# Run Gunicorn in the background
nohup gunicorn --workers 3 --bind unix:/var/www/app/src/myapp.sock app:app &

# Verify Gunicorn is running
pgrep -af gunicorn

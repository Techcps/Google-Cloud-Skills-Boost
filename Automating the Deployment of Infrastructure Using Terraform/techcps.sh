

mkdir tfinfra
cd tfinfra
wget https://raw.githubusercontent.com/Techcps/Google-Cloud-Skills-Boost/master/Automating%20the%20Deployment%20of%20Infrastructure%20Using%20Terraform/provider.tf
wget https://raw.githubusercontent.com/Techcps/Google-Cloud-Skills-Boost/master/Automating%20the%20Deployment%20of%20Infrastructure%20Using%20Terraform/mynetwork.tf

echo $ZONE1
echo $ZONE2

sed -i "s/\$ZONE1/${ZONE1}/g" mynetwork.tf
sed -i "s/\$ZONE2/${ZONE2}/g" mynetwork.tf

mkdir instance
cd instance

wget https://raw.githubusercontent.com/Techcps/Google-Cloud-Skills-Boost/master/Automating%20the%20Deployment%20of%20Infrastructure%20Using%20Terraform/instance/main.tf
wget https://raw.githubusercontent.com/Techcps/Google-Cloud-Skills-Boost/master/Automating%20the%20Deployment%20of%20Infrastructure%20Using%20Terraform/instance/variables.tf


cd ..
terraform fmt
terraform init
terraform plan


echo "yes" | terraform apply


# Login
az login
# Variáveis
resourceGroup="rg-dev-vm"
location="brazilsouth"
vnetName="vnet-dev"
vnetAddress="10.1.0.0/16"
subnetName="subnet-dev"
subnetAddress="10.1.1.0/24"
vmName="vm-dev-01"
vmSize="Standard_B2ms"
adminUser="azureuser"
adminPassword="SenhaComplexa@123"
publicIPName="$vmName-pip"
nsgName="$vmName-nsg"
nicName="$vmName-nic"
# Seu IP público
myIP=$(curl -s ifconfig.me)
# Criar Resource Group
az group create --name $resourceGroup --location $location
# Criar VNet e Subnet
az network vnet create \
--resource-group $resourceGroup \
--name $vnetName \
--address-prefix $vnetAddress \
--subnet-name $subnetName \
--subnet-prefix $subnetAddress
# Criar IP Público
az network public-ip create \
--resource-group $resourceGroup \
--name $publicIPName \
--allocation-method Dynamic
# Criar NSG
az network nsg create \
--resource-group $resourceGroup \
--name $nsgName
# Criar regra RDP apenas para seu IP
az network nsg rule create \
--resource-group $resourceGroup \
--nsg-name $nsgName \
--name Allow-RDP-MyIP \
--protocol Tcp \
--direction Inbound \
--priority 1000 \
--source-address-prefixes $myIP \
--source-port-ranges '*' \
--destination-address-prefixes '*' \
--destination-port-ranges 3389 \
--access Allow
# Criar NIC
subnetId=$(az network vnet subnet show --resource-group $resourceGroup --vnet-name $vnetName --name $subnetName --query id -o tsv)
pipId=$(az network public-ip show --resource-group $resourceGroup --name $publicIPName --query id -o tsv)
nsgId=$(az network nsg show --resource-group $resourceGroup --name $nsgName --query id -o tsv)
az network nic create \
--resource-group $resourceGroup \
--name $nicName \
--subnet $subnetId \
--public-ip-address $pipId \
--network-security-group $nsgId
# Criar VM
az vm create \
--resource-group $resourceGroup \
--name $vmName \
--nics $nicName \
--image Win2022Datacenter \
--size $vmSize \
--admin-username $adminUser \
--admin-password $adminPassword \
--location $location \
--output json


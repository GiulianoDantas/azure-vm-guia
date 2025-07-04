# Conectar ao Azure
Connect-AzAccount
# Variáveis
$resourceGroup = "rg-dev-vm"
$location = "brazilsouth"
$vnetName = "vnet-dev"
$vnetAddress = "10.1.0.0/16"
$subnetName = "subnet-dev"
$subnetAddress = "10.1.1.0/24"
$vmName = "vm-dev-01"
$vmSize = "Standard_B2ms"
$adminUser = "azureuser"
$adminPassword = ConvertTo-SecureString "SenhaComplexa@123" -AsPlainText -Force
$publicIPName = "$vmName-pip"
$nsgName = "$vmName-nsg"
$nicName = "$vmName-nic"
# Seu IP público
$myIP = (Invoke-RestMethod -Uri "http://ifconfig.me/ip")
# Criar Resource Group
New-AzResourceGroup -Name $resourceGroup -Location $location
# Criar VNet e Subnet
$vnet = New-AzVirtualNetwork -ResourceGroupName $resourceGroup -Location $location `
-Name $vnetName -AddressPrefix $vnetAddress
Add-AzVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $vnet -AddressPrefix $subnetAddress
$vnet | Set-AzVirtualNetwork
# Criar Public IP
$pip = New-AzPublicIpAddress -ResourceGroupName $resourceGroup -Name $publicIPName -Location $location -AllocationMethod Dynamic
# Criar NSG
$nsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroup -Location $location -Name $nsgName
# Criar regra de RDP apenas para seu IP
$nsgRuleRDP = New-AzNetworkSecurityRuleConfig -Name "Allow-RDP-MyIP" -Protocol "Tcp" -Direction "Inbound" -Priority 1000 -SourceAddressPrefix $myIP `
-SourcePortRange "*" -DestinationAddressPrefix "*" -DestinationPortRange 3389 -Access "Allow"
$nsg | Add-AzNetworkSecurityRuleConfig -Name $nsgRuleRDP.Name -SecurityRule $nsgRuleRDP | Set-AzNetworkSecurityGroup
# Criar NIC
$subnet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $subnetName
$nic = New-AzNetworkInterface -ResourceGroupName $resourceGroup -Location $location -Name $nicName -SubnetId $subnet.Id -PublicIpAddressId $pip.Id -NetworkSecurityGroupId $nsg.Id
# Criar VM
$cred = New-Object System.Management.Automation.PSCredential ($adminUser, $adminPassword)
$vmConfig = New-AzVMConfig -VMName $vmName -VMSize $vmSize |
Set-AzVMOperatingSystem -Windows -ComputerName $vmName -Credential $cred -ProvisionVMAgent -EnableAutoUpdate |
Set-AzVMSourceImage -PublisherName "MicrosoftWindowsServer" -Offer "WindowsServer" -Skus "2022-Datacenter" -Version "latest" |
Add-AzVMNetworkInterface -Id $nic.Id
New-AzVM -ResourceGroupName $resourceGroup -Location $location -VM $vmConfig


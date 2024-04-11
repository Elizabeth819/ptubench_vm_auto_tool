#!/bin/bash
# 使用方式: bash ptu_vm.sh [create|delete]

ACTION=$1
# The script is to create a new VM for PTU testing
#create the resource group
#export RANDOM_ID="$(openssl rand -hex 3)"
export RANDOM_ID="123"
export MY_RESOURCE_GROUP_NAME="ptu-rg$RANDOM_ID" # "swedencentral-vm"
#let the user input REGION name
echo "Please input region name - in lowercase (eg: australiaeast, eastus, swedencentral):"
read REGION
#export REGION="australiaeast" #"swedencentral"
export MY_VM_NAME="ptu-$REGION""_vm"  #"swedencentral-vm" #"PTU_VM_$REGION$RANDOM_ID"
export MY_USERNAME=azureuser
export MY_VM_IMAGE="Ubuntu2204"
export SIZE="Standard_D4s_v3" #"Standard_D2s_v3"

# 删除虚拟机和资源组的函数
delete_vm() {
    #ask for confirmation if the user really want to delete the resource group, add a line break after the prompt
    read -p "Are you sure you want to delete the resource group $MY_RESOURCE_GROUP_NAME? (y/n) " -r
    # if not delete, then ask for confirmation if the user really want to delete the VM
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "delete the resource group $MY_RESOURCE_GROUP_NAME"
        az group delete --name $MY_RESOURCE_GROUP_NAME  --yes --no-wait
    else
        echo "skip deleting the resource group $MY_RESOURCE_GROUP_NAME"
    fi

    read -p "Are you sure you want to delete the VM $MY_VM_NAME? (y/n) " -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "delete the VM $MY_VM_NAME"
        az vm delete --resource-group $MY_RESOURCE_GROUP_NAME   --name $MY_VM_NAME --yes --no-wait
    else
        echo "skip deleting the VM $MY_VM_NAME"
    fi

    #echo "delete the VM $MY_VM_NAME"
    #az vm delete --resource-group $MY_RESOURCE_GROUP_NAME   --name $MY_VM_NAME --yes --no-wait
    #echo "delete the resource group $MY_RESOURCE_GROUP_NAME"
    #az group delete --name $MY_RESOURCE_GROUP_NAME  --yes --no-wait
}

# 创建虚拟机的函数
create_vm() {
    echo "Resource group name: $MY_RESOURCE_GROUP_NAME"
    # if not the first time creation, then don't create 
    # 检查资源组是否存在
    EXISTS=$(az group exists -n $MY_RESOURCE_GROUP_NAME)

    if [ "$EXISTS" = "true" ]; then
        echo "resource group $MY_RESOURCE_GROUP_NAME exists"
    else
        echo "Create resource group $MY_RESOURCE_GROUP_NAME";
        az group create --name $MY_RESOURCE_GROUP_NAME --location $REGION;
    fi

    # 检查VM是否存在
    echo "VM name: $MY_VM_NAME, check if the VM exists..."
    if [ "$(az vm list -d -o table --query "[?name=='$MY_VM_NAME']" )" = "" ]; then
        echo "VM $MY_VM_NAME does not exist, Create a VM $MY_VM_NAME ...";
        #create the VM
        az vm create \
        --resource-group $MY_RESOURCE_GROUP_NAME \
        --name $MY_VM_NAME \
        --image $MY_VM_IMAGE \
        --admin-username $MY_USERNAME \
        --assign-identity \
        --generate-ssh-keys \
        --size Standard_D2s_v3 \
        --public-ip-sku Standard;

    else
        echo "VM $MY_VM_NAME was found, skip creating";
    fi
}

  
# 根据ACTION执行相应的函数，if delete, then skip the following "enable Azure AD login and scp script", just exit after delete_vm()
case "$ACTION" in
    create)
        create_vm
        ;;
    delete)
        delete_vm
        exit 0
        ;;
    *)
        echo "Usage: $0 [create|delete]"
        exit 1
        ;;
esac


#enable Azure AD login for a linux VM in Azure,Configure prerequisites for Native SSH
echo "enable Azure AD login"
az vm extension set \
    --publisher Microsoft.Azure.ActiveDirectory \
    --name AADSSHLoginForLinux \
    --resource-group $MY_RESOURCE_GROUP_NAME \
    --vm-name $MY_VM_NAME

# Store IP address of VM in order to SSH
export IP_ADDRESS=$(az vm show --show-details --resource-group $MY_RESOURCE_GROUP_NAME --name $MY_VM_NAME --query publicIps --output tsv)

#先将脚本传输到远程VM
echo 'Transit test_ptuscript.sh to VM, cmd:';
echo "scp -o StrictHostKeyChecking=no test_ptuscript.sh azureuser@$IP_ADDRESS:/home/azureuser/"
scp -o StrictHostKeyChecking=no test_ptuscript.sh azureuser@$IP_ADDRESS:/home/azureuser/

#execute command on the remote VM
COMMANDS="
if [ ! -d "azure-openai-benchmark" ]; then
    echo 'git clone the benchmarking tool';
    git clone https://github.com/michaeltremeer/azure-openai-benchmark.git;
fi 

echo 'Please running test script test_ptuscript.sh on the VM directly...';
"
##execute downloading benchmarking repo command on the remote VM, not login to the VM
echo "ssh to the $IP_ADDRESS, download the benchmarking tool..."
ssh -o StrictHostKeyChecking=no $MY_USERNAME@$IP_ADDRESS "${COMMANDS}"
echo "ssh command: ssh -o StrictHostKeyChecking=no $MY_USERNAME@$IP_ADDRESS"
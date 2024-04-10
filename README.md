# ptubench_vm_auto_tool
Create a new VM node for PTU benchmarking automatically.

You don't need to create VM in the portal, saving the processes to choose VM and region,
wait VM to start and then configure the SSH connection from local network.

1. The ptu_vm.sh script serves as an automation tool for provisioning and managing Azure virtual machines (VMs) specifically set up for PTU. It accepts an argument that directs the script to either create or delete resources. In the 'create' mode, it establishes a new Azure VM within a resource group, sets up the Azure AD login for SSH access, and transfers a test script to the VM for benchmarking. In contrast, the 'delete' mode prompts the user for confirmation before proceeding to remove the VM and its associated resource group, preventing accidental data loss.
Usage:
   bash ptu_vm.sh create|delete
   create: it can detect the resource group name and VM name existant so as to save time for follow-up creations.
   ![image](https://github.com/Elizabeth819/ptubench_vm_auto_tool/assets/140314420/97b16370-a920-4b81-af75-2e633ebf581c)
   ![image](https://github.com/Elizabeth819/ptubench_vm_auto_tool/assets/140314420/e8953074-f18b-4af2-8fc5-822698486477)
   It additionally transfers a test script to the newly created VM and prepares the environment by cloning a benchmarking tool repository.
   
2. The accompanying test_ptuscript.sh script is intended for the initial setup and execution of performance tests on the Azure VM. It checks and installs Python and pip if they are not already installed and ensures all Python dependencies listed in requirements.txt are present. Once the setup is complete, the script moves into the benchmarking directory, sets necessary environment variables, and invokes a Python module to conduct the performance test, capturing the output for analysis. Together, these scripts provide an end-to-end solution for managing VM lifecycles and conducting performance tests in a cloud-based environment.
   ![image](https://github.com/Elizabeth819/ptubench_vm_auto_tool/assets/140314420/77ea9777-a7bb-4e15-bec5-577cbe1cff06)
   Use the command generated by the first script and login to the VM to execute the PTU benchmarking script.
   the command is like:
       ssh -o StrictHostKeyChecking=no azureuser@x.x.x.x
       bash test_ptuscript.sh

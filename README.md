# SIOS DataKeeper / SQL Azure Deployment Template

This template will create a High Availability / Disaster Recovery (HADR) solution featuring the following:
+	A Virtual Network
+	Three data storage accounts and one dedicated diagnostic storage account
+	Four public IP addresses and associated NICs for remote connections to all four VMs via RDP
+	One internal load balancer configured to allow replication traffic across the domain
+	One VM configured as a Domain Controller for a new forest with a single domain
+	Two Vms in a Windows Server Failover Cluster, both running SQL 2014 and SIOS DataKeeper
+	One VM configured as a client outside of the cluster
+	Two Availability Sets; one for the cluster VMs, and the other for the configured client VM

External connections via RDP can be made to all four VMs created by this template.
The cluster is configured to use a file share witness, which is hosted on the AD Domain Controller.

# Known Issues

This template is mostly deployed in a serial manner, and utilizes PowerShell DSC Extensions for final configurations. Due to this and current restrictions in the Azure backend logic, this results in the template requiring 45 min to an hour to complete deployment. Microsoft is working toward a solution allowing more parallel operations (and thus faster deployment times). This template will be updated accordingly as soon as possible.

## Notes

+	The default settings for storage are to deploy using **premium storage**, all four VMs use a P10 Disk for the OS. The domain controller and two cluster nodes are also configured with an additional P10 disk for data and diagnostics. These sizes can be changed by changing the relevant variables.

+ 	By default, these settings require that you have at least 4 cores of available quota to deploy.

+ 	The images used to create this deployment are
	+ 	AD VM - Latest Windows Server 2012 R2 Image
	+ 	SIOS DataKeeeper / SQL Server VMs - DataKeeper 8.3.0 marketplace image (requires license), which is based on the latest Windows Server 2012 R2 Image,  with SQL 2014 SP1 evaluation version 
	+ 	Client - Latest Windows Server 2012 R2 Image  
	
# Click the button below to deploy a<br/>SIOS DataKeeper / SQL 2014 Failover Cluster in the Azure Portal
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FSIOSDataKeeper%2FSIOSDataKeeper-SQL-Cluster%2Fmaster%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

## Deploying from PowerShell

For details on how to install and configure Azure Powershell visit <br/>https://azure.microsoft.com/en-us/documentation/articles/powershell-install-configure

Launch an Azure PowerShell console, and login to your account 
```PowerShell

Login-AzureRmAccount 

```

If you have multiple subscriptions, provide the subscription ID you wish to use with the following
```PowerShell

Select-AzureRmSubscription -SubscriptionID <YourSubscriptionId>

``` 

Switch to the folder containing this template. It is a best practice to create a new Resource Group for the deployment with the following

```PowerShell

New-AzureRmResourceGroup -Name "<new resourcegroup name>" -Location "<new resourcegroup location>"

```

Finally, launch the deployment with the following
```PowerShell

New-AzureRmResourceGroupDeployment -Name <Deployment Name> -ResourceGroupName <resource group name> -TemplateFile .\azuredeploy.json

```

You will be prompted for the following parameters

+ **licenseKeyFtpURL:** - Enter the path to your temporary license file. This path appears in the email that you received from SIOS Technology Corp. when you requested an evaluation key. Provide the folder name which contains the license in this field.<br/>Example input - http://ftp.us.sios.com/pickup/EVAL_Some_User_2016-01-26_DKCE. To request a free 14 day trial, visit http://us.sios.com/clustersyourway/cta/14-day-trial.
+ **newStorageAccountNamePrefix:** - The prefix of the new storage account created to store the VMs disks, different storage accounts will be created for AD and DataKeeper VMs. This value must be composed of all lowercase letters or numbers and be a maximum of 20 characters long and globally unique within all of Azure.
+ **storageAccountType:** - Type of storage account to create. This must be set to Premium if DS size VMs are being created.
+ **domainName:** The domain name in FQDN form. This value should contain at least two parts, separated by a '.' (for example, datakeeper.local). The first part of the FQDN will be used as the login domain name (for example, login as datakeeper&#92;siosadmin), and must not match the DOMAINADMINUSERNAME. If DOMAINNAME does not contain a '.', the suffix '.local' will be appended.
+ **domainAdminUsername:** The username for the Administrator of the new VMs and Domain. The DOMAINADMINUSERNAME chosen must not match the domain specified in the DOMAINNAME parameter (for example: using DOMAINNAME 'datakeeper.local' and DOMAINADMINUSERNAME 'datakeeper' will cause the deployment to fail).
+ **domainAdminPassword:** The password for the Administrator account of the new VMs and Domain.
+ **vMNamePrefix:** The name prefix for all of the SIOS DataKeeper / SQL VMs.


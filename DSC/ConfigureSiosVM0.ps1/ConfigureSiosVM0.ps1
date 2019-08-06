
configuration ConfigureSiosVM0
{
    param
    (
        [Parameter(Mandatory)]
        [String]$DomainName,
    
        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$AdminCreds,
    
        [String]$DomainNetbiosName=(Get-NetBIOSName -DomainName $DomainName),
    
        [Parameter(Mandatory)]
        [String]$LicenseKeyFtpURL,
                
        [Parameter(Mandatory)]
        [String]$ClusterName,
    
        [Parameter(Mandatory)]
        [String]$SharePath,
    
        [Int]$RetryCount=20,
                
        [Int]$RetryIntervalSec=30         
    )
    
    $domainFQDN = Add-TopLevelDomain $DomainName

    Import-DscResource -ModuleName cDisk, xActiveDirectory, xComputerManagement, xCredSSP, xDataKeeper, xDisk, xFailOverCluster, xNetworking
    [System.Management.Automation.PSCredential]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainNetbiosName}\$($AdminCreds.UserName)", $AdminCreds.Password)
    [System.Management.Automation.PSCredential]$DomainFQDNCreds = New-Object System.Management.Automation.PSCredential ("${domainFQDN}\$($AdminCreds.UserName)", $AdminCreds.Password)
    
    Node localhost
    {
        xWaitforDisk Disk2
        {
            DiskNumber          = 2
            RetryIntervalSec    = $RetryIntervalSec
            RetryCount          = $RetryCount
        }
        
        cDiskNoRestart DataDisk
        {
            DiskNumber           = 2
            DriveLetter          = "F"
            DependsOn            = "[xWaitForDisk]Disk2"
        }
        
        WindowsFeature FC
        {
            Name                 = "Failover-Clustering"
            Ensure               = "Present"
        }

        WindowsFeature FCMGMT
        {
            Name                 = "RSAT-Clustering-Mgmt"
            Ensure               = "Present"
        }

        WindowsFeature FCPS
        {
            Name                 = "RSAT-Clustering-PowerShell"
            Ensure               = "Present"
        }

        WindowsFeature ADPS
        {
            Name                 = "RSAT-AD-PowerShell"
            Ensure               = "Present"
        }
        
        WindowsFeature ADDS
        {
            Name                 = "RSAT-ADDS-Tools"
            Ensure               = "Present"
        }
                
        xWaitForADDomain DscForestWait 
        { 
            DomainName           = $domainFQDN 
            DomainUserCredential = $DomainCreds
            RetryCount           = $RetryCount 
            RetryIntervalSec     = $RetryIntervalSec 
            DependsOn            = "[WindowsFeature]ADPS"
        }
                
        xComputer DomainJoin
        {
            Name                 = $env:COMPUTERNAME
            DomainName           = $domainFQDN
            Credential           = $DomainCreds
            DependsOn            = "[xWaitForADDomain]DscForestWait"
        }
        
        xCredSSP Server
        {
            Ensure               = "Present"
            Role                 = "Server"
            DependsOn            = "[xComputer]DomainJoin"
        }
        xCredSSP Client
        {
            Ensure               = "Present"
            Role                 = "Client"
            DelegateComputers    = "*"
            DependsOn            = "[xComputer]DomainJoin"
        }

        InstallLicense GetDKCELic
        {
            LicenseKeyFtpURL     = $LicenseKeyFtpURL 
            RetryIntervalSec     = $RetryIntervalSec
            RetryCount           = $RetryCount 
            DependsOn            = "[xComputer]DomainJoin"
        }
        
        sService StartExtMirr
        {
            Name                 = "extmirrsvc"
            StartupType          = "Automatic"
            State                = "Running"
            DependsOn            = "[InstallLicense]GetDKCELic"
        }
    
        xWaitForCluster WaitForCluster
        {
            Name                 = $ClusterName
            DomainAdministratorCredential = $DomainCreds
            RetryIntervalSec     = 30
            RetryCount           = 120 
            DependsOn            = "[sService]StartExtMirr"
        }
        
        xWaitForFileShareWitness WaitForFSW
        {
            SharePath            = $SharePath
            DomainAdministratorCredential = $DomainCreds
        }
    
        xClusterQuorum FailoverClusterQuorum
        {
            Name                 = $ClusterName
            SharePath            = $SharePath
            DomainAdministratorCredential = $DomainCreds
            DependsOn            = "[xWaitForFileShareWitness]WaitForFSW", "[xWaitForCluster]WaitForCluster"
        }
        
        RegisterClusterVolume RegClusVol
        {
            Volume               = "F"
            DependsOn            = "[xClusterQuorum]FailoverClusterQuorum","[cDiskNoRestart]DataDisk"
        }
        
        InstallClusteredSQL InstallSQL
        {
            AdminCredential      = $AdminCreds
            DomainNetbiosName    = $DomainNetbiosName
            DependsOn            = "[RegisterClusterVolume]RegClusVol"
            PsDscRunAsCredential = $AdminCreds
        }
                
        SetSQLServerIP ResetSQLIP
        {
            InternalLoadBalancerIP = "10.0.0.200"
            DependsOn              = "[InstallClusteredSQL]InstallSQL"
        }
            
        LocalConfigurationManager 
        {
            RebootNodeIfNeeded = $true
        }
    }
}

function Get-NetBIOSName
{ 
    [OutputType([string])]
    param(
        [string]$DomainName
    )

    if ($DomainName.Contains('.')) {
        $length=$DomainName.IndexOf('.')
        if ( $length -ge 16) {
            $length=15
        }
        return $DomainName.Substring(0,$length)
    }
    else {
        if ($DomainName.Length -gt 15) {
            return $DomainName.Substring(0,15)
        }
        else {
            return $DomainName
        }
    }
}

function Add-TopLevelDomain
{ 
    [OutputType([string])]
    param(
        [string]$DomainName
    )

    if ($DomainName.Contains('.')) {
        return $DomainName
    }
    else {
        return ($DomainName + ".local")
    }
}
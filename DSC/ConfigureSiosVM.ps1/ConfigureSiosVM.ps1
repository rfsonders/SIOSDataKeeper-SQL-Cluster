configuration ConfigureSiosVM
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
        [String[]]$Nodes,

        [Int]$RetryCount=40,
                
        [Int]$RetryIntervalSec=30
    )

    $domainFQDN = Add-TopLevelDomain $DomainName
    
    $node0 = $Nodes[0] + "." + $domainFQDN    
    $node1 = $Nodes[1] + "." + $domainFQDN
    
    Import-DscResource -ModuleName cDisk, xActiveDirectory, xComputerManagement, xCredSSP, xDataKeeper, xDisk, xFailOverCluster, xNetworking    
    [System.Management.Automation.PSCredential]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainNetbiosName}\$($AdminCreds.UserName)", $AdminCreds.Password)
    
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
        
        CreateJob NewJob
        {
            JobName              = "vol.F"
            JobDesc              = "Protection for SQL DATA and LOGS"
            SourceName           = $node0
            SourceIP             = "10.0.0.5"
            SourceVol            = "F"
            TargetName           = $node1
            TargetIP             = "10.0.0.6"
            TargetVol            = "F"
            SyncType             = "S"
            RetryIntervalSec     = 20 
            RetryCount           = 30 
            DependsOn            = "[sService]StartExtMirr","[cDiskNoRestart]DataDisk"
        }
    
        CreateMirror NewMirror
        {
            SourceIP             = "10.0.0.5"
            Volume               = "F"
            TargetIP             = "10.0.0.6"
            SyncType             = "S"
            RetryIntervalSec     = 20 
            RetryCount           = 30
            DependsOn            = "[CreateJob]NewJob"
        }
        
        cCreateCluster FailoverCluster
        {
            Name                 = $ClusterName
            Nodes                = $Nodes
            AddressIPv4          = "10.0.0.100"
            DomainAdministratorCredential = $DomainCreds
            DomainName           = $DomainName
            RetryCount           = 30 
            RetryIntervalSec     = 30
            DependsOn            = "[CreateMirror]NewMirror","[xCredSSP]Client","[xCredSSP]Server"
        }
        
        cWaitForClusterGroup WaitForClusterGroup
        {
            Name                 = "SQL Server (MSSQLSERVER)"
            RetryCount           = 120 
            RetryIntervalSec     = 30
            DependsOn            = "[cCreateCluster]FailoverCluster"
        }
        
        AddClusteredSQLNode InstallSQL
        {
            AdminCredential      = $AdminCreds
            DomainNetbiosName    = $DomainNetbiosName
            DependsOn            = "[cWaitForClusterGroup]WaitForClusterGroup"
            PsDscRunAsCredential = $AdminCreds
        }
                
        LocalConfigurationManager 
        {
            RebootNodeIfNeeded   = $true
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
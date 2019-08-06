configuration ConfigureSiosClientVM
{
    param
    (
        [Parameter(Mandatory)]
        [String]$DomainName,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$AdminCreds,

        [String]$DomainNetbiosName=(Get-NetBIOSName -DomainName $DomainName),

        [Int]$RetryCount=20,
				
        [Int]$RetryIntervalSec=30
    )

	Import-DscResource -ModuleName xActiveDirectory, xComputerManagement, xDataKeeper
	
    $domainFQDN = Add-TopLevelDomain $DomainName
    [System.Management.Automation.PSCredential]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainNetbiosName}\$($AdminCreds.UserName)", $AdminCreds.Password)
    
    Node localhost
    {
        WindowsFeature ADPS
        {
            Name = "RSAT-AD-PowerShell"
            Ensure = "Present"
        }
				
        xWaitForADDomain DscForestWait 
        { 
            DomainName = $domainFQDN 
            DomainUserCredential= $DomainCreds
            RetryCount = $RetryCount 
            RetryIntervalSec = $RetryIntervalSec 
			DependsOn = "[WindowsFeature]ADPS"
        }
				
        xComputer DomainJoin
        {
            Name = $env:COMPUTERNAME
            DomainName = $domainFQDN
            Credential = $DomainCreds
			DependsOn = "[xWaitForADDomain]DscForestWait"
        }
		
		InstallSQLTools SQLTools
		{
			Path = "C:\SQL2014\"
			DependsOn = "[xComputer]DomainJoin"
			PsDscRunAsCredential = $AdminCreds
		}
		
		sService StopExtMirr
		{
			Name = "extmirrsvc"
			StartupType = "Manual"
			State = "Stopped"
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
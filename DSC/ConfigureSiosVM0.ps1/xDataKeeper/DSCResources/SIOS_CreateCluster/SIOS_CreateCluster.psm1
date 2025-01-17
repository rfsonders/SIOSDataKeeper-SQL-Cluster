function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory)]
        [string] $Name,

        [parameter(Mandatory)]
        [string] $AddressIPv4,
        
        [parameter(Mandatory)]
        [PSCredential] $DomainAdministratorCredential,
        
        [parameter(Mandatory)]
        [string] $DomainName,

        [parameter(Mandatory)]
        [string[]] $Nodes,

        [System.UInt32]
        $RetryIntervalSec,

        [System.UInt32]
        $RetryCount
    )

    Write-Verbose "In Get-TargetResource"

    $returnValue = @{
        Name = [String]
        AddressIPv4 = [String]
        DomainAdministratorCredential = [PSCredential]
        DomainName = [String]
        Nodes = [String[]]
        RetryIntervalSec = [System.UInt32]
        RetryCount = [System.UInt32]
    }

    Write-Verbose "Leaving Get-TargetResource"
    
    $returnValue
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory)]
        [string] $Name,
        
        [parameter(Mandatory)]
        [string] $AddressIPv4,
        
        [parameter(Mandatory)]
        [PSCredential] $DomainAdministratorCredential,
        
        [parameter(Mandatory)]
        [string] $DomainName,

        [parameter(Mandatory)]
        [string[]] $Nodes,

        [System.UInt32]
        $RetryIntervalSec,

        [System.UInt32]
        $RetryCount
    )

    $ErrorActionPreference = "Continue"
    Start-Transcript -Path "$env:windir\Temp\SIOS_CreateCluster.ps1.txt" -Append
    Write-Verbose "In Set-TargetResource"
    Write-Verbose "The following parameters were passed in:"
    Write-Verbose "Name                   $Name"
    Write-Verbose "AddressIPv4            $AddressIPv4"
    Write-Verbose "DomainAdminUserName    $DomainAdministratorCredential.UserName"
    Write-Verbose "DomainAdminPassword    $DomainAdministratorCredential.GetNetworkCredential().Password"
    Write-Verbose "DomainName             $DomainName"
    Write-Verbose "Nodes                  $Nodes" 
    
    $cluster = $NULL
    try {
        $tries = 30
        netdom verify $Nodes[0] /d:$DomainName
        while(($LastExitCode -ne 0) -And ($tries -gt 1)) {
            "`nLoogking for other node in domain..."
            netdom verify $Nodes[0] /d:$DomainName
            Start-Sleep 30
            $tries--
        }
        
        $node0 = $Nodes[0]
        $node1 = $Nodes[1]
        $cluster = $NULL
        for ($count = 0; $count -lt $RetryCount; $count++)
        {    
            $Config={
                $node = $Using:node0,$Using:node1
                $staticAddress =  $Using:AddressIPv4
                New-Cluster -Name $Using:Name -Node $node -StaticAddress $staticAddress -NoStorage
            }

            $cluster = Invoke-Command -Authentication Credssp -Scriptblock $Config -ComputerName $Nodes[1] -Credential $DomainAdministratorCredential
            Start-Sleep 60
            if($cluster -ne $NULL) {
                "Cluster formed SUCCESSFULLY"
                break
            }
        }
        
        $ErrorActionPreference = "Stop"
        if($cluster -eq $NULL) {
            "Cluster NOT created after 120 attempts."
            throw "Cluster NOT created after 120 attempts."
        } elseif( -Not ((Get-ClusterNode).Name -Contains $Nodes[1]) ) {
            "Local node NOT ADDED TO CLUSTER, failing"
            throw "Local node NOT ADDED TO CLUSTER, failing"
        } else {
            "Node verified added to cluster"
        }
    } 
    catch {} 
    finally { 
        Stop-Transcript
    }
    
    Write-Verbose "Leaving Set-TargetResource"
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory)]
        [string] $Name,

        [parameter(Mandatory)]
        [string] $AddressIPv4,
        
        [parameter(Mandatory)]
        [PSCredential] $DomainAdministratorCredential,
        
        [parameter(Mandatory)]
        [string] $DomainName,

        [parameter(Mandatory)]
        [string[]] $Nodes,

        [System.UInt32]
        $RetryIntervalSec,

        [System.UInt32]
        $RetryCount
    )
    
    return (Test-Path "$env:windir\Temp\datakeeperclusterSUCCESS.log")
}

Export-ModuleMember -Function *-TargetResource


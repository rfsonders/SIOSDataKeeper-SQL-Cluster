#
# xWaitForClusterGroup: DSC Resource that will wait for given name of ClusterGroup

function Get-TargetResource
{
    [OutputType([Hashtable])]
    param
    (    
        [parameter(Mandatory)][string] $Name,

        [UInt64] $RetryIntervalSec = 30,
        [UInt32] $RetryCount = 50
    )

    @{
        Name = $Name
        RetryIntervalSec = $RetryIntervalSec
        RetryCount = $RetryCount
    }
}

function Set-TargetResource
{
    param
    (    
        [parameter(Mandatory)][string] $Name,

        [UInt64] $RetryIntervalSec = 30,
        [UInt32] $RetryCount = 50
    )

    $clustergroupFound = $false

    $logfile = "$env:windir\Temp\datakeeperinstall.log"
    "Checking for clustergroup $Name ..." >> $logfile

    $ErrorActionPreference = "Stop"
    for ($count = 0; $count -lt $RetryCount; $count++)
    {
        try
        {
            $clustergroup = Get-ClusterGroup -Name $Name 
            
            if ($clustergroup -ne $null)
            {
                $state = $clustergroup.State
                "Found clustergroup $Name with state $state" >> $logfile
                
                if($state -eq "Online") {
                    $clustergroupFound = $true
                    break;
                } 
            }
        }
        catch
        {
             "ClusterGroup $Name not found. Will retry again after $RetryIntervalSec sec" >> $logfile
        }
         
        "ClusterGroup $Name not found. Will retry again after $RetryIntervalSec sec" >> $logfile
        Start-Sleep -Seconds $RetryIntervalSec
    }

    if (! $clustergroupFound)
    {
        throw "ClusterGroup $Name not found after $count attempts with $RetryIntervalSec sec interval"
    }
}

function Test-TargetResource
{
    [OutputType([Boolean])]
    param
    (    
        [parameter(Mandatory)][string] $Name,

        [UInt64] $RetryIntervalSec = 30,
        [UInt32] $RetryCount = 50
    )

    $logfile = "$env:windir\Temp\datakeeperinstall.log"
    "Checking for ClusterGroup $Name ..." >> $logfile
    
    $ErrorActionPreference = "Stop"
    try
    {
        $clustergroup = Get-ClusterGroup -Name $Name
        if ($clustergroup -eq $null)
        {
            "ClusterGroup $Name not found" >> $logfile
            $false
        }
        else
        {
            $state = $clustergroup.State
            "Found clustergroup $Name with state $state" >> $logfile
            
            if($state -eq "Online") {
                $true
            } else {
                $false
            }
        }
    }
    catch
    {
        "ClusterGroup $Name not found" >> $logfile
        $false
    } 
}



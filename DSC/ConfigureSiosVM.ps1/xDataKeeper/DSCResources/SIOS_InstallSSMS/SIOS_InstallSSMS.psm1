function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $FullPathToExe
    )

    $returnValue = @{
	    FullPathToExe = [System.String]
    }

    $returnValue
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $FullPathToExe
    )

	$logfile = "$env:windir\Temp\datakeeperSQLInstall.txt"
	if(Test-Path -Path $logFile) {
        "Installing SSMS" >> $logfile
    } else {
        "Installing SSMS" > $logfile
    }
	
	$command = "$FullPathToExe /install /quiet /norestart"
	$command >> $logfile	
	
	$results = & "cmd" /C $command
	$results >> $logfile
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $FullPathToExe
    )

	$logfile = "$env:windir\Temp\datakeeperSQLInstall.txt"
	if(Test-Path -Path $logFile) {
        "Checking for SSMS" >> $logfile
    } else {
        "Checking for SSMS" > $logfile
    }
	
  	if( Test-Path -Path "C:\Program Files (x86)\Microsoft SQL Server\120\Tools\Binn\ManagementStudio\Ssms.exe") {
		"SMSS.exe FOUND!" >> $logfile
		$true
	} else {
		"SMSS.exe NOT found" >> $logfile
		$false
	}
}

Export-ModuleMember -Function *-TargetResource


function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $SQLServerURL
    )

	Write-Verbose "In Get-TargetResource"
    
    $returnValue = @{
		SQLServerURL = [System.String]
		ISODownloadPath = [System.String]
		FinalPathToFiles = [System.String]
    }

	Write-Verbose "Leaving Get-TargetResource"
	
    $returnValue
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $SQLServerURL = "http://care.dlservice.microsoft.com/dl/download/2/F/8/2F8F7165-BB21-4D1E-B5D8-3BD3CE73C77D/SQLServer2014SP1-FullSlipstream-x64-ENU.iso",

        [System.String]
        $ISODownloadPath = "$env:windir\Temp\",

        [System.String]
        $FinalPathToFiles = "C:\SQL2014\"
    )

    Write-Verbose "In Set-TargetResource"

	$isofile = ""
	$logfile = "$env:windir\Temp\datakeeperSQLdownload.log"
	
    if(Test-Path -Path $logfile) {
        "Downloading SQL Server from $SQLServerURL" >> $logfile
	} else {
        "Downloading SQL Server from $SQLServerURL" > $logfile
    }
    
	$isofile = $SQLServerURL.Substring($SQLServerURL.LastIndexOf("/"))

	$isoDLed = $false;
	for ($i = 0; $i -lt 5; $i++)
    {
		Invoke-WebRequest $SQLServerURL -OutFile ($ISODownloadPath+$isofile)
		
		if(Test-Path -Path ($ISODownloadPath+$isofile)) {
			"iso file downloaded successfully" >> $logfile
			$isoDLed = $true
			break
		} else {
			"iso not obtained" >> $logfile
		}
	}
		
	if(-Not $isoDLed) {
		"iso from '$SQLServerURL' NOT found." >> $logfile
		throw "ISO from '$SQLServerURL' NOT found."
	}
	
	Mount-DiskImage ($ISODownloadPath+$isofile)
	$source = Get-DiskImage -ImagePath ($ISODownloadPath+$isofile) | Get-Volume
	md $FinalPathToFiles
	Copy-Item -Path ($source.DriveLetter+":\*") -Destination "$FinalPathToFiles" -Recurse

	Write-Verbose "Leaving Set-TargetResource"
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $SQLServerURL = "http://care.dlservice.microsoft.com/dl/download/2/F/8/2F8F7165-BB21-4D1E-B5D8-3BD3CE73C77D/SQLServer2014SP1-FullSlipstream-x64-ENU.iso",

        [System.String]
        $ISODownloadPath = "$env:windir\Temp\",

        [System.String]
        $FinalPathToFiles = "C:\SQL2014\"
    )

    Write-Verbose "In Test-TargetResource"
	
    $logfile = "$env:windir\Temp\datakeeperSQLdownload.log"

    if(Test-Path -Path $logFile) {
        "Checking for setup file ..." >> $logfile
    } else {
        "Checking for setup file ..." > $logfile
    }
    
	$fileExists = $(Test-Path -Path "$FinalPathToFiles\Setup.exe")
	
	if($fileExists) {
		"Install files found." >> $logfile
		$true
	} else {
		"Install Files NOT found!" >> $logfile
		$false
	}

	Write-Verbose "Leaving Test-TargetResource"
}

Export-ModuleMember -Function *-TargetResource


function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $DataKeeperFTPURL
    )

	Write-Verbose "In Get-TargetResource"
	
    $returnValue = @{
		DataKeeperFTPURL = [System.String]
		DownloadPath = [System.String]
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
        [parameter(Mandatory = $true)]
        [System.String]
        $DataKeeperFTPURL = "http://e512b7db7365eaa2f93b-44b251abad247bc1e9143294cbaa102a.r50.cf5.rackcdn.com/windows/SIOS_DataKeeper_Windows_en_8.4.0/DataKeeperv8.4.0-1995/DK-8.4.0-Setup.exe",

        [System.String]
        $DownloadPath = "$env:windir\Temp\",

        [System.UInt32]
        $RetryIntervalSec = 20,

        [System.UInt32]
        $RetryCount = 30
    )

    Write-Verbose "In Set-TargetResource"
	
	$exeFile = ""
	$logfile = "$env:windir\Temp\datakeeperdownload.log"
	
    if(Test-Path -Path $logFile) {
        "Downloading DKCE executable from '$($DataKeeperFTPURL)'" >> $logfile
    } else {
        "Downloading DKCE executable from '$($DataKeeperFTPURL)'" > $logfile
    }
    
	if($DataKeeperFTPURL.EndsWith(".exe")) {
		$exeFile = $DataKeeperFTPURL.Substring($DataKeeperFTPURL.LastIndexOf("/"))
		$exe = $DataKeeperFTPURL
	} else { # otherwise use the standard file name and hope
		$exeFile = "/DK-8.4.0-Setup.exe"
		$exe = $DataKeeperFTPURL+$exeFile
	}
	
	$dkceDLed = $false;
	for ($count = 0; $count -lt $RetryCount; $count++)
    {
		if( -Not (Test-Path $DownloadPath) ) { 
			New-Item $DownloadPath -type directory 
		}
	
		Invoke-WebRequest $exe -OutFile ($DownloadPath+$exeFile)
		
		if( Test-Path ($DownloadPath+$exeFile) ) {
			"Executable downloaded successfully" >> $logfile
			$dkceDLed = $true
			break
		} else {
			"Executable not obtained"  >> $logfile
			"Retrying in $RetryIntervalSec seconds ..."  >> $logfile
			Start-Sleep -Seconds $RetryIntervalSec
		}
	}
		
	if(-Not $dkceDLed) {
		"Executable from '$($DataKeeperFTPURL)' NOT found after $RetryCount attmpts." >> $logfile
		throw "Executable from '$($DataKeeperFTPURL)' NOT found after $RetryCount attmpts."
	}
	
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
        $DataKeeperFTPURL = "http://e512b7db7365eaa2f93b-44b251abad247bc1e9143294cbaa102a.r50.cf5.rackcdn.com/windows/SIOS_DataKeeper_Windows_en_8.4.0/DataKeeperv8.4.0-1995/DK-8.4.0-Setup.exe",

        [System.String]
        $DownloadPath = "$env:windir\Temp\",

        [System.UInt32]
        $RetryIntervalSec,

        [System.UInt32]
        $RetryCount
    )

    Write-Verbose "In Test-TargetResource"
	
	$exeFile = ""
	$exe = ""
	$logfile = "$env:windir\Temp\datakeeperdownload.log"

    if(Test-Path -Path $logFile) {
        "Checking for executable ..." >> $logfile
    } else {
        "Checking for executable ..." > $logfile
    }
    
	if($DataKeeperFTPURL.EndsWith(".exe")) {
		$exeFile = $DataKeeperFTPURL.Substring($DataKeeperFTPURL.LastIndexOf("/"))
		$exe = $DataKeeperFTPURL
	} else { # otherwise use the standard file name and hope
		$exeFile = "/DK-8.4.0-Setup.exe"
		$exe = $DataKeeperFTPURL+$exeFile
	}

	$fileExists = $(Test-Path ($DownloadPath+$exeFile))
	
	if($fileExists) {
		"Executable found in $DownloadPath$exeFile" >> $logfile
		$true
	} else {
		"Executable NOT found in $DownloadPath$exeFile" >> $logfile
		$false
	}
	
    Write-Verbose "Leaving Test-TargetResource"
}


Export-ModuleMember -Function *-TargetResource


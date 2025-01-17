function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $SSMSURL
    )

	Write-Verbose "In Get-TargetResource"
    
    $returnValue = @{
		SSMSURL = [System.String]
		DownloadPath = [System.String]
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
        $SSMSURL = "http://download.microsoft.com/download/E/E/1/EE12CC0F-A1A5-4B55-9425-2AFBB2D63979/SSMS-Full-Setup.exe",

        [System.String]
        $DownloadPath = "$env:windir\Temp\"
    )

    Write-Verbose "In Set-TargetResource"

	$exefile = ""
	$logfile = "$env:windir\Temp\datakeeperSQLdownload.log"
	
    if(Test-Path -Path $logfile) {
        "Downloading SSMS from $SSMSURL" >> $logfile
	} else {
        "Downloading SSMS from $SSMSURL" > $logfile
    }
    
	$exefile = $SSMSURL.Substring($SSMSURL.LastIndexOf("/"))

	$exeDLed = $false;
	for ($i = 0; $i -lt 5; $i++)
    {
		Invoke-WebRequest $SSMSURL -OutFile ($DownloadPath+$exefile)
		
		if(Test-Path -Path ($DownloadPath+$exefile)) {
			"exe file downloaded successfully" >> $logfile
			$exeDLed = $true
			break
		} else {
			"exe not obtained" >> $logfile
		}
	}
		
	if(-Not $exeDLed) {
		"exe from '$SSMSURL' NOT found." >> $logfile
		throw "Executable from '$SSMSURL' NOT found."
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
        $SSMSURL = "http://download.microsoft.com/download/E/E/1/EE12CC0F-A1A5-4B55-9425-2AFBB2D63979/SSMS-Full-Setup.exe",

        [System.String]
        $DownloadPath = "$env:windir\Temp\"
    )

    Write-Verbose "In Test-TargetResource"
	
    $logfile = "$env:windir\Temp\datakeeperSQLdownload.log"

    if(Test-Path -Path $logFile) {
        "Checking for SSMS file ..." >> $logfile
    } else {
        "Checking for SSMS file ..." > $logfile
    }
    
	$exefile = $SSMSURL.Substring($SSMSURL.LastIndexOf("/"))
	$fileExists = $(Test-Path -Path ($DownloadPath+$exefile))
	
	if($fileExists) {
		"Install file found." >> $logfile
		$true
	} else {
		"Install File NOT found!" >> $logfile
		$false
	}

	Write-Verbose "Leaving Test-TargetResource"
}

Export-ModuleMember -Function *-TargetResource


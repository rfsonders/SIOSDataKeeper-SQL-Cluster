function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Path
    )

    $returnValue = @{
	    Path = [System.String]
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
        $Path
    )

	$logfile = "C:\Windows\Temp\datakeeperSQLInstall.txt"
	"Installing SQL Tools" > $logfile
	$command = $Path + 'setup.exe /ACTION="Install" /IACCEPTSQLSERVERLICENSETERMS /Q /INDICATEPROGRESS /FEATURES="Tools"'
	$command >> $logfile	
	
	try {
		$results = ""
		while(-Not $results.Contains("Success")) {	
			$results = cmd /C $command
			$results>>$logfile
			
			netsh advfirewall firewall add rule name = "SQL Port TCP 1433" dir = in protocol = tcp action = allow localport = 1433 profile = DOMAIN
			netsh advfirewall firewall add rule name = "ILB Probe Port TCP 59999" dir = in protocol = tcp action = allow localport = 59999 profile = DOMAIN
		}
	} catch [Exception] {
		echo $_.Exception|format-list -force >>$logfile
	}
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Path
    )

  	Test-Path "C:\Windows\Temp\datakeeperSQLInstall.txt"
}


Export-ModuleMember -Function *-TargetResource


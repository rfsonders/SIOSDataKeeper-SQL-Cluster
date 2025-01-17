function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
		[parameter(Mandatory = $true)]
        [System.String]
        $DomainNetbiosName,
		
        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $AdminCredential
    )

    $returnValue = @{
		DomainNetbiosName = [System.String]
		AdminCredential = [System.Management.Automation.PSCredential]
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
        $DomainNetbiosName,
		
        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $AdminCredential
    )
	
	mkdir C:\TempDB
	
	$logfile = "C:\Windows\Temp\datakeeperSQLInstall.txt"
	"Adding SQL node to the cluster" > $logfile
	
	try {
	
		$results = $NULL
		while($results -eq $NULL) {
			$results = Get-ClusterResource "SQL Server" -ErrorAction SilentlyContinue
			Start-Sleep 30
			"Cluster resource SQL Server not found">>$logfile
		}

		$results = $results.State
		while($results -ne "Online") {
			$results = $(Get-ClusterResource "SQL Server").State
			Start-Sleep 30
			"Cluster resource SQL Server not online">>$logfile
		}
		
		if($(Get-Service winmgmt).Status -ne "Running") {
			Restart-Service winmgmt
		}
	
		$AdminUser = $DomainNetbiosName + "\" + $AdminCredential.UserName
		$Password = $AdminCredential.GetNetworkCredential().Password
		$results = ""
		while(-Not $results.Contains("Success")) {	
			$results = C:\SQL2014\setup /ACTION="AddNode" /SkipRules=Cluster_VerifyForErrors Cluster_IsWMIServiceOperational /ENU="True" /Q /UpdateEnabled="False" /ERRORREPORTING="False" /USEMICROSOFTUPDATE="False" /UpdateSource="MU" /HELP="False" /INDICATEPROGRESS="False" /X86="False" /INSTANCENAME="MSSQLSERVER" /SQMREPORTING="False" /FAILOVERCLUSTERGROUP="SQL Server (MSSQLSERVER)" /CONFIRMIPDEPENDENCYCHANGE="False" /FAILOVERCLUSTERIPADDRESSES="IPv4;10.0.0.200;Cluster Network 1;255.255.255.0" /FAILOVERCLUSTERNETWORKNAME="siossqlserver" /AGTSVCACCOUNT=$AdminUser /SQLSVCACCOUNT=$AdminUser /FTSVCACCOUNT="NT Service\MSSQLFDLauncher" /SQLSVCPASSWORD=$Password /AGTSVCPASSWORD=$Password /IAcceptSQLServerLicenseTerms
			$results>>$logfile
			
			netsh advfirewall firewall add rule name = "SQL Port TCP 1433" dir = in protocol = tcp action = allow localport = 1433 profile = DOMAIN
			netsh advfirewall firewall add rule name = "ILB Probe Port TCP 59999" dir = in protocol = tcp action = allow localport = 59999 profile = DOMAIN
		}
	} catch [Exception] {
		echo $_.Exception|format-list -force > "C:\Windows\Temp\datakeeperSQLInstalFAILURE.txt"
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
        $DomainNetbiosName,
		
        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $AdminCredential
    )

    Test-Path "C:\Windows\Temp\datakeeperSQLInstall.txt"
}


Export-ModuleMember -Function *-TargetResource



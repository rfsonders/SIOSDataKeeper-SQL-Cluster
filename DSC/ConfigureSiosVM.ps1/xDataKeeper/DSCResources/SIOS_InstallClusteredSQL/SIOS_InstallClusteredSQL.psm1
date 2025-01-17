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
		AdminCredential = [System.Management.Automation.PSCredential]
		DomainNetbiosName = [System.String]
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
	"Installing SQL into the cluster" > $logfile
	
	try {
		if($(Get-Service winmgmt).Status -ne "Running") {
			Restart-Service winmgmt
		}
		
		$AdminUser = $DomainNetbiosName + "\" + $AdminCredential.UserName
		$Password = $AdminCredential.GetNetworkCredential().Password
		$results = ""
		while(-Not $results.Contains("Success")) {
			$results = C:\SQL2014\setup /ACTION="InstallFailoverCluster" /SkipRules=Cluster_VerifyForErrors Cluster_IsWMIServiceOperational /ENU="True" /Q /UpdateEnabled="False" /ERRORREPORTING="False" /USEMICROSOFTUPDATE="False" /FEATURES=SQLENGINE,REPLICATION,FULLTEXT,DQ,SSMS,ADV_SSMS /UpdateSource="MU" /HELP="False" /INDICATEPROGRESS="False" /X86="False" /INSTALLSHAREDDIR="C:\Program Files\Microsoft SQL Server" /INSTALLSHAREDWOWDIR="C:\Program Files (x86)\Microsoft SQL Server" /INSTANCENAME="MSSQLSERVER" /SQMREPORTING="False" /INSTANCEID="MSSQLSERVER" /INSTANCEDIR="C:\Program Files\Microsoft SQL Server" /FAILOVERCLUSTERDISKS="DataKeeper Volume F" /FAILOVERCLUSTERGROUP="SQL Server (MSSQLSERVER)" /FAILOVERCLUSTERIPADDRESSES="IPv4;10.0.0.200;Cluster Network 1;255.255.255.0" /FAILOVERCLUSTERNETWORKNAME="siossqlserver" /AGTSVCACCOUNT=$AdminUser /COMMFABRICPORT="0" /COMMFABRICNETWORKLEVEL="0" /COMMFABRICENCRYPTION="0" /MATRIXCMBRICKCOMMPORT="0" /FILESTREAMLEVEL="0" /SQLCOLLATION="SQL_Latin1_General_CP1_CI_AS" /SQLSVCACCOUNT=$AdminUser /SQLSYSADMINACCOUNTS=$AdminUser /INSTALLSQLDATADIR="F:" /SQLTEMPDBDIR="C:\TempDB" /FTSVCACCOUNT="NT Service\MSSQLFDLauncher" /SQLSVCPASSWORD=$Password /AGTSVCPASSWORD=$Password /IAcceptSQLServerLicenseTerms 
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


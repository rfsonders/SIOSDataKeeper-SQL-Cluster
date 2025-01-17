function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $InstallerPath
    )

    $returnValue = @{
		InstallerPath = [System.String]
		SetupFilePath = [System.String]
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
        $InstallerPath = "$env:windir\Temp\DK-8.5.1-Setup.exe",

        [System.String]
        $SetupFilePath = "$env:windir\Temp\setup.iss",

        [System.Management.Automation.PSCredential]
        $AdminCredential
    )
    Write-Verbose "In Set-TargetResource"

    $logfile = "$env:windir\Temp\datakeeperinstall.log"

    if(Test-Path -Path $logFile) {
        "Installing DKCE" >> $logfile
    } else {
        "Installing DKCE" > $logfile
    }
    
	$AdminUser = $AdminCredential.UserName
	$Password = $AdminCredential.GetNetworkCredential().Password
	
	$text = @"
[InstallShield Silent]
Version=v7.00
File=Response File
[File Transfer]
OverwrittenReadOnly=NoToAll
[{B00365F8-E4E0-11D5-8323-0050DA240D61}-DlgOrder]
Dlg0={B00365F8-E4E0-11D5-8323-0050DA240D61}-SdWelcome-0
Count=10
Dlg1={B00365F8-E4E0-11D5-8323-0050DA240D61}-SdLicense-0
Dlg2={B00365F8-E4E0-11D5-8323-0050DA240D61}-SdComponentTree-0
Dlg3={B00365F8-E4E0-11D5-8323-0050DA240D61}-SdAskDestPath-0
Dlg4={B00365F8-E4E0-11D5-8323-0050DA240D61}-SprintfBox-0
Dlg5={B00365F8-E4E0-11D5-8323-0050DA240D61}-FWOptions
Dlg6={B00365F8-E4E0-11D5-8323-0050DA240D61}-DLTCOptions
Dlg7={B00365F8-E4E0-11D5-8323-0050DA240D61}-AskOptions-0
Dlg8={B00365F8-E4E0-11D5-8323-0050DA240D61}-SdRegisterUserEx-0
Dlg9={B00365F8-E4E0-11D5-8323-0050DA240D61}-SdFinishReboot-0
[{B00365F8-E4E0-11D5-8323-0050DA240D61}-SdWelcome-0]
Result=1
[{B00365F8-E4E0-11D5-8323-0050DA240D61}-SdLicense-0]
Result=1
[{B00365F8-E4E0-11D5-8323-0050DA240D61}-SdComponentTree-0]
szDir=C:\Program Files (x86)\SIOS\DataKeeper
Component-type=string
Component-count=2
Component-0=DataKeeper Server Components
Component-1=DataKeeper User Interface
Result=1
[{B00365F8-E4E0-11D5-8323-0050DA240D61}-SdAskDestPath-0]
szDir=C:\Program Files (x86)\SIOS\DataKeeper
Result=1
[{B00365F8-E4E0-11D5-8323-0050DA240D61}-SprintfBox-0]
Result=6
[{B00365F8-E4E0-11D5-8323-0050DA240D61}-FWOptions]
FWOption=1
[{B00365F8-E4E0-11D5-8323-0050DA240D61}-DLTCOptions]
DLTCOption=1
[Application]
Name=SIOS DataKeeper for Windows v8 Update 5
Version=8.5.0
Company=SIOS Technology Corp.
Lang=0009
[{B00365F8-E4E0-11D5-8323-0050DA240D61}-AskOptions-0]
Result=1
Sel-0=1
Sel-1=0
[{B00365F8-E4E0-11D5-8323-0050DA240D61}-SdRegisterUserEx-0]
szName=$AdminUser
szCompany=$Password
szSerial=$Password
Result=1
[{B00365F8-E4E0-11D5-8323-0050DA240D61}-SdFinishReboot-0]
Result=6
BootOption=3
"@

	$text > $SetupFilePath

	$command = "$InstallerPath /s /f1$SetupFilePath /f2$env:windir\Temp\installshield.log"
	$command >> $logfile	
	$results = & "cmd" /C $command
	$results >> $logfile
    #Include this line if the resource requires a system reboot.
    #$global:DSCMachineStatus = 1
    
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
        $InstallerPath,

        [System.String]
        $SetupFilePath,

        [System.Management.Automation.PSCredential]
        $AdminCredential
    )
    Write-Verbose "In Test-TargetResource"
    
    $logfile = "$env:windir\Temp\datakeeperinstall.log"

    if(Test-Path -Path $logFile) {
        "Checking for %extmirrbase%" >> $logfile
    } else {
        "Checking for %extmirrbase%" > $logfile
    }
    
    $pathExists = $(Test-Path -Path ("C:\Program Files(x86)\SIOS\DataKeeper\"))
	
	if($pathExists) {
		"%ExtMirrBase% found." >> $logfile
		$true
	} else {
		"%ExtMirrBase% NOT found!" >> $logfile
		$false
	}
	
    Write-Verbose "Leaving Test-TargetResource"
}


Export-ModuleMember -Function *-TargetResource


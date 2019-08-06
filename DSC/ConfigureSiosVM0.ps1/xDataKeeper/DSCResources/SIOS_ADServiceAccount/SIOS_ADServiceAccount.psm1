#
# ADService: DSC resource to create a new Managed Service account under Active Directory.
# Most of this has bee repurposed from MSFT_xADUser version 2.7.0
#

function Get-TargetResource
{
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory)]
        [string]$DomainName,

        [Parameter(Mandatory)]
        [string]$ServiceName,

        [Parameter(Mandatory)]
        [PSCredential]$DomainAdministratorCredential,
        
        [string]$DNSHostName,

        [ValidateSet("Present","Absent")]
        [string]$Ensure = "Present"
    )

    try
    {
        Write-Verbose -Message "Checking if the user '$($ServiceName)' in domain '$($DomainName)' is present ..."
        $svcacct = Get-AdServiceAccount -Identity $ServiceName -Credential $DomainAdministratorCredential
        Write-Verbose -Message "Found '$($ServiceName)' in domain '$($DomainName)'."
        $Ensure = "Present"
    }
    catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]
    {
        Write-Verbose -Message "Service Acoount '$($ServiceName)' in domain '$($DomainName)' is NOT present."
        $Ensure = "Absent"
    }
    catch
    {
        Write-Error -Message "Error looking up service account '$($ServiceName)' in domain '$($DomainName)'."
        throw $_
    }

    @{
        DomainName = $DomainName
        ServiceName = $ServiceName
        Ensure = $Ensure
    }
}

function Set-TargetResource
{
    param
    (
        [Parameter(Mandatory)]
        [string]$DomainName,

        [Parameter(Mandatory)]
        [string]$ServiceName,
        
        [Parameter(Mandatory)]
        [PSCredential]$DomainAdministratorCredential,

        [string]$DNSHostName,

        [ValidateSet("Present","Absent")]
        [string]$Ensure = "Present"
    )
    try
    {
		ValidateProperties @PSBoundParameters -Apply
    }
    catch
    {
        Write-Error -Message "Error configuring service account '$($ServiceName)' in domain '$($DomainName)'."
        throw $_
    }
}

function Test-TargetResource
{
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory)]
        [string]$DomainName,

        [Parameter(Mandatory)]
        [string]$ServiceName,
        
        [Parameter(Mandatory)]
        [PSCredential]$DomainAdministratorCredential,

        [string]$DNSHostName,

        [ValidateSet("Present","Absent")]
        [string]$Ensure = "Present"
    )

    try
    {
		$parameters = $PSBoundParameters.Remove("Debug");
        ValidateProperties @PSBoundParameters
    }
    catch
    {
        Write-Error -Message "Error testing service account '$($ServiceName)' in domain '$($DomainName)'."
        throw $_
    }
}

function ValidateProperties
{
    param
    (
        [Parameter(Mandatory)]
        [string]$DomainName,

        [Parameter(Mandatory)]
        [string]$ServiceName,

        [Parameter(Mandatory)]
        [PSCredential]$DomainAdministratorCredential,

        [string]$DNSHostName,

        [ValidateSet("Present","Absent")]
        [string]$Ensure = "Present",

        [Switch]$Apply
    )

    $result = $true
    try
    {
        Write-Verbose -Message "Checking if the service account '$($ServiceName)' in domain '$($DomainName)' is present ..."
        $svcacct = Get-AdServiceAccount -Identity $ServiceName -Credential $DomainAdministratorCredential
        Write-Verbose -Message "Found '$($ServiceName)' in domain '$($DomainName)'."
        
        if ($Ensure -eq "Absent")
        {
            if ($Apply)
            {
                Remove-ADSericeAccount -Identity $ServiceName -Credential $DomainAdministratorCredential -Confirm:$false
                return
            }
            else
            {
                return $false
            }
        }
    }
    catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]
    {
        Write-Verbose -Message "Service account '$($ServiceName)' in domain '$($DomainName)' is NOT present."
        if ($Apply)
        {
            if ($Ensure -ne "Absent")
            {
				# this is spectacular, see https://social.technet.microsoft.com/Forums/sharepoint/en-US/82617035-254f-4078-baa2-7b46abb9bb71/newadserviceaccount-key-does-not-exist?forum=winserver8gen
				Add-KdsRootKey –EffectiveTime ((get-date).addhours(-10))
				Start-Sleep 60
			
				$params = @{
					DNSHostName = $DNSHostName
                    Name = $ServiceName
					Credential = $DomainAdministratorCredential
                }
                New-AdServiceAccount @params 
				Write-Verbose -Message "Successfully created service account '$($ServiceName)' in domain '$($DomainName)'."
            }
        }
        else
        {
            return ($Ensure -eq "Absent")
        }
    }
}


Export-ModuleMember -Function *-TargetResource


# =============================================================================
# Private
# =============================================================================

function Get-AdminAccountName
{
    return (Get-LocalUser | Where-Object { $_.SID -like 'S-1-5-*-500' }).Name
}

# =============================================================================
# Public
# =============================================================================


function Run-AsUser
{
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)][String]$Process,
        [parameter(Mandatory = $false)][String]$ProcArgs,
        [parameter(Mandatory = $false)][String]$User,
        [parameter(Mandatory = $false)][Switch]$Wait
    )
    if (!$User) { $User = $env:UserName }
    $args4run = @()
    $args4run += "/user:$User", "/savecred", "`"$Process $ProcArgs`""
    if($Wait){Start-Process -NoNewWindow -Wait runas -ArgumentList $args4run -WorkingDirectory $(Get-Location)}
    else{
        Start-Process -NoNewWindow runas -ArgumentList $args4run -WorkingDirectory $(Get-Location)
        Write-Output "[DONE] The process is launched in backgroung. Press Enter to continue"
    }
}

function Run-AsAdmin ($Process, $ProcArgs)
{
    $admin_name = Get-AdminAccountName
    Run-AsUser -User $admin_name -Process $Process -ProcArgs $ProcArgs
}


function Run-Elevated ($Process, $ProcArgs)
{
    Start-Process -FilePath $Process -ArgumentList $ProcArgs -Verb RunAs
}

function isAdmin
{
    try
    {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal -ArgumentList $identity
        return $principal.IsInRole( [Security.Principal.WindowsBuiltInRole]::Administrator )
    }
    catch
    {
        throw "Failed to determine if the current user has elevated privileges. The error was: '{0}'." -f $_
    }
}

function isAdminCheck
{
    if (!$(isAdmin))
    {
        Write-Error "You should be an Admin to do this"
        return $false
    }
    return $true
}


function Elevate-Me
{
    if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
    {
        "Not Admin"
        Start-Process pwsh.exe "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit
    }
}

Export-ModuleMember -Function "Run-AsAdmin"
Export-ModuleMember -Function "Run-AsUser"
Export-ModuleMember -Function "Run-Elevated"
Export-ModuleMember -Function "Elevate-Me"
Export-ModuleMember -Function "isAdmin"
Export-ModuleMember -Function "isAdminCheck"

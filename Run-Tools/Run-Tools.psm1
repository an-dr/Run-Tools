function Run-AsUser ($Process, $ProcArgs)
{
    $args4runas = @()
    $args4runas += $Process, $ProcArgs
    $newProcess = New-Object System.Diagnostics.ProcessStartInfo "runas";
    $newProcess.ArgumentList.Add("/trustlevel:0x20000")
    $newProcess.ArgumentList.Add("$args4runas")
    Write-Verbose "$($newProcess.ArgumentList)"
    [System.Diagnostics.Process]::Start($newProcess)
}

function Run-AsAdmin ($Process, $ProcArgs)
{
    $args4runas = @()
    $args4runas += $Process, $ProcArgs
    $newProcess = New-Object System.Diagnostics.ProcessStartInfo "runas";
    $newProcess.ArgumentList.Add("/user:Administrator")
    $newProcess.ArgumentList.Add("/savecred")
    $newProcess.ArgumentList.Add("$args4runas")
    Write-Verbose "$($newProcess.ArgumentList)"
    [System.Diagnostics.Process]::Start($newProcess)
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

function isAdminCheck {
    if (!$(isAdmin))
    {
        Write-Error "You should be an Admin to do this"
        return $false
    }
    return $true
}


function Elevate-Me {
    if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
    {
        "Not Admin"
        Start-Process pwsh.exe "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit
    }
}

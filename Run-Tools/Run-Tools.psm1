# =============================================================================
# Private
# =============================================================================

function Get-AdminAccountName {
    return (Get-LocalUser | Where-Object { $_.SID -like 'S-1-5-*-500' }).Name
}

# =============================================================================
# Public
# =============================================================================


function Run-AsUser {
    param (
        [parameter(Mandatory = $true)][String]$Process,
        [parameter(Mandatory = $false)][String]$ProcArgs,
        [parameter(Mandatory = $false)][String]$User,
        [parameter(Mandatory = $false)][Switch]$Wait
    )
    if (!$User) { $User = $env:UserName }
    $args4run = @()
    $args4run += "/user:$User", "/savecred", "`"$Process $ProcArgs`""
    if ($Wait) { Start-Process -Wait runas -ArgumentList $args4run -WorkingDirectory $(Get-Location) }
    else {
        Start-Process runas -ArgumentList $args4run -WorkingDirectory $(Get-Location)
        Write-Output "[DONE] The process is launched in backgroung. Press Enter to continue"
    }
}

function Run-AsAdmin {
    param (
        [parameter(Mandatory = $true)][String]$Process,
        [parameter(Mandatory = $false)][String]$ProcArgs,
        [parameter(Mandatory = $false)][Switch]$Wait
    )
    $admin_name = Get-AdminAccountName
    if ($Wait) { Run-AsUser -Wait -User $admin_name -Process $Process -ProcArgs $ProcArgs }
    else { Run-AsUser -User $admin_name -Process $Process -ProcArgs $ProcArgs }
}


function Run-Elevated {
    param (
        [parameter(Mandatory = $true)][String]$Process,
        [parameter(Mandatory = $false)][String]$ProcArgs,
        [parameter(Mandatory = $false)][Switch]$Wait
    )
    if ($Wait) { Start-Process -Wait -FilePath $Process -ArgumentList $ProcArgs -Verb RunAs }
    else { Start-Process -FilePath $Process -ArgumentList $ProcArgs -Verb RunAs }
}

function isAdmin {
    try {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal -ArgumentList $identity
        return $principal.IsInRole( [Security.Principal.WindowsBuiltInRole]::Administrator )
    }
    catch {
        throw "Failed to determine if the current user has elevated privileges. The error was: '{0}'." -f $_
    }
}

function isAdminCheck {
    if (!$(isAdmin)) {
        Write-Error "You should be an Admin to do this"
        return $false
    }
    return $true
}

function Elevate-Me
{
    Param(
        [parameter(Mandatory = $false)]
        [String]$CodeBlock
    )

    if (!$(isAdmin)) {
        if ($CodeBlock) {

            Write-Debug "There is a code block at the input"
            Read-Host -Prompt "We are goint to run elevated terminal. Press Enter to Proceed"
            Run-Elevated "pwsh" "-ExecutionPolicy Bypass -NoExit -Command `"$CodeBlock`""
        }
        else{
            Write-Debug "No codeblock"
            $script_to_elevate = $(Get-PSCallStack)[1].ScriptName # previous script from stack - script called this func
            if ($script_to_elevate) {
                Write-Debug "Running from a script..."
                "Your have no Administrator's rights for $script_to_elevate.`Let's fix it..."
                Run-Elevated "pwsh" "-ExecutionPolicy Bypass -File `"$script_to_elevate`""
            }
            else{
                Write-Debug "Running from a shell..."
                Read-Host -Prompt "We are goint to run elevated terminal. Press Enter to Proceed"
                Run-Elevated "pwsh" "-ExecutionPolicy Bypass -NoExit"
            }
        }
        exit
    }
    else {
        if ($CodeBlock) {
            Write-Debug "There is a code block at the input"
            Invoke-Expression -Command $CodeBlock
        }
        else {
            Write-Debug "No codeblock"
            "Your are already elevated"
        }
    }
}

#!/usr/bin/env pwsh

function global:IsElevated {
	if ($IsWindows -and (New-Object System.Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole("Administrators")) {
        return $true
    }
    
    if ($PSVersionTable.Platform -eq 'Unix') {
        if ((id -u) -eq 0) {
            return $true
        }
    }

    return $false
}

# Define prompt
function global:Prompt {
    $host.ui.rawui.WindowTitle = "PowerShell Core $($host.Version.ToString())"

    if ($executionContext.SessionState.Path.CurrentLocation.Path.StartsWith($home)) {
        $path = $executionContext.SessionState.Path.CurrentLocation.Path.Replace($home,"~")
    } else {
        $path = $executionContext.SessionState.Path.CurrentLocation.Path
    }

    if (IsElevated) {
        $host.ui.rawui.WindowTitle += " # "
        "$path$('#' * ($nestedPromptLevel + 1)) ";
	} else {
        $host.ui.rawui.WindowTitle += " - "
        "$path$('>' * ($nestedPromptLevel + 1)) ";
	}
    $host.ui.rawui.WindowTitle += "$($executionContext.SessionState.Path.CurrentLocation.Path)"
}

# Linux & macOS only:
if ($PSVersionTable.PSEdition -and ($PSVersionTable.PSEdition -eq "Core") -and ($IsLinux -or $IsMacOS)) {
    # Path variable
    if (!$env:PATH.Contains("/usr/local/bin")) {
        [System.Collections.ArrayList]$pathArray = $env:PATH.Split(":")
        $pathArray.Insert(1,"/usr/local/bin")
        $env:PATH = $pathArray -Join ":"
    }

    # Source environment variables from ~/.config/powershell/environment.ps1
    $environmentPath = (Join-Path (Split-Path $Profile –Parent) "environment.ps1")
    if (Test-Path -Path $environmentPath) {
        Write-Output "Sourcing $environmentPath"
        . $environmentPath
    } else {
        Write-Output "$environmentPath not found"
    }
}

# Install Az module if not present
if (!(Get-Module Az -ListAvailable)) {
    Write-Host "Az modules not present, installing..."
    Install-Module Az
}
Get-Module Az -ListAvailable | Select-Object -First 1 -Property Name, Version

# Go to home (not automatic for elevated prompt)
if (IsElevated) {
    if ($home -and (Test-Path $home)) {
        Set-Location $home
    } else {
        if ($env:USERPROFILE -and (Test-Path $env:USERPROFILE)) {
            Set-Location $env:USERPROFILE
        } 
    }
}
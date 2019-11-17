#!/usr/bin/env pwsh

function AddorUpdateModule (
    [string]$moduleName,
    [string]$desiredVersion
) {
    if (Get-InstalledModule $moduleName -ErrorAction SilentlyContinue) {
        $moduleVersionString = Get-InstalledModule $moduleName | Sort-Object -Descending Version | Select-Object -First 1 -ExpandProperty Version
        if ($desiredVersion) {
            $newModule = Find-Module $moduleName -MinimumVersion $desiredVersion -AllowPrerelease -ErrorAction SilentlyContinue
            $allowPrerelease = $true
        } else {
            $moduleVersion = New-Object System.Version($moduleVersionString)
            $desiredVersion = "{0}.{1}.{2}" -f $moduleVersion.Major, $moduleVersion.Minor, ($moduleVersion.Build + 1)
            $newModule = Find-Module $moduleName -MinimumVersion $desiredVersion -ErrorAction SilentlyContinue
        }
        
        # Check whether newer module exists
        if ($newModule -and ($($newModule.Version) -ne $moduleVersionString)) {
            Write-Host "PowerShell Core $moduleName module $moduleVersionString is out of date. Updating $moduleName module to $($newModule.Version)..."
            if ($allowPrerelease) {
                Update-Module $moduleName -AcceptLicense -Force -RequiredVersion ${newModule.Version} -AllowPrerelease
            } else {
                Update-Module $moduleName -AcceptLicense -Force -RequiredVersion ${newModule.Version}
            }
        } else {
            Write-Host "PowerShell Core $moduleName module $moduleVersionString is up to date"
        }
    } else {
        # Install module if not present
        if ($desiredVersion) {
            $newModule = Find-Module $moduleName -MinimumVersion $desiredVersion -AllowPrerelease -ErrorAction SilentlyContinue
            if ($newModule) {
                Write-Host "Installing PowerShell Core $moduleName module (pre-release $($newModule.Version))..."
                Install-Module $moduleName -Force -SkipPublisherCheck -AcceptLicense -MinimumVersion $desiredVersion -AllowPrerelease
            } else {
                Write-Host "PowerShell Core $moduleName module version $desiredVersion is not available on $($PSVersionTable.Platform)" -ForegroundColor Red
            }
        } else {
            Write-Host "Installing PowerShell Core $moduleName module..."
            Install-Module $moduleName -Force -SkipPublisherCheck -AcceptLicense
        }
    }
}

# Check whether Az modules have been installed
AddorUpdateModule Az
AddorUpdateModule Oh-My-Posh
AddorUpdateModule Posh-Git
AddorUpdateModule PSReadLine 2.0.0-beta6 # Waiting for 2.0.0 to be released
if ($IsWindows) {
    AddorUpdateModule WindowsCompatibility
}

# Create symbolic link for PowerShell Core profile directory
$psCoreProfileDirectory = Split-Path -Parent $PROFILE
if (!(Test-Path $psCoreProfileDirectory)) {
    New-Item -ItemType Directory -Path $psCoreProfileDirectory -Force
}
if (Test-Path $PROFILE) {
    Write-Host "Powershell Core profile $PROFILE already exists"
} else {
    $psProfileJunctionTarget = $(Join-Path (Split-Path -parent -Path $MyInvocation.MyCommand.Path) "profile.ps1")

    Write-Host "Creating symbolic link from $PROFILE to $psProfileJunctionTarget"
    New-Item -ItemType symboliclink -path "$PROFILE" -value "$psProfileJunctionTarget"
}  
. $PROFILE

if (Get-Command tfenv -ErrorAction SilentlyContinue) {
    tfenv install latest
} else {
    Write-Host "tfenv not found" -ForegroundColor Red
}
<#
.SYNOPSIS
Bulk UWP App Removal Tool v1.14 (Detailed Operation List Version)

.DESCRIPTION
Uninstalls UWP apps and their provisioned packages based on predefined patterns.txt
Supports dry run mode (-DryRun) to preview operations

.PARAMETER DryRun
Dry run mode, only displays planned operations without executing

.EXAMPLE
.\Remove-UWPApps.ps1          # Execute uninstallation
.\Remove-UWPApps.ps1 -DryRun  # Dry run mode
#>

param(
    [switch]$DryRun = $false
)

#region Initialization Settings
$ErrorActionPreference = "Stop"
$scriptVersion = "1.14"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$logDir = "$PSScriptRoot\Remove-UWPLogs"
$logFile = "$logDir\UWP_Removal_$timestamp.log"
$patternsFile = "$PSScriptRoot\patterns.txt"

# Create log directory
if (-not (Test-Path $logDir)) { 
    New-Item -ItemType Directory -Path $logDir | Out-Null 
}

# Logging function
function Log-Message {
    param([string]$Message, [string]$Level = "INFO")
    
    # Write to log file
    Add-Content -Path $logFile -Value $Message
    
    # Console output
    if ($Level -eq "WARNING") {
        Write-Host $Message -ForegroundColor Yellow
    }
    elseif ($Level -eq "ERROR") {
        Write-Host $Message -ForegroundColor Red
    }
    elseif ($Level -eq "SUCCESS") {
        Write-Host $Message -ForegroundColor Green
    }
    else {
        Write-Host $Message
    }
}

# Display header
Log-Message "=== Bulk UWP App Removal Tool v$scriptVersion ==="
Log-Message "====Author: abludypanny@163.com ==="
Log-Message "Start Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
if ($DryRun) {
    Log-Message "Execution Mode: Dry Run (No actual changes)"
} else {
    Log-Message "Execution Mode: Actual Removal"
}
Log-Message "Log File: $logFile"
Log-Message "----------------------------------------"
#endregion

#region Read Pattern File
try {
    $patterns = Get-Content $patternsFile | 
        Where-Object { $_ -notmatch "^\s*#" -and $_ -notmatch "^\s*$" } |
        ForEach-Object { 
            if ($_.Contains('#')) {
                $_.Substring(0, $_.IndexOf('#')).Trim()
            } else {
                $_.Trim()
            }
        }
    
    if (-not $patterns) {
        throw "No valid patterns found in patterns.txt"
    }
    
    Log-Message "Loaded $($patterns.Count) removal patterns"
}
catch {
    Log-Message "Failed to read patterns.txt: $_" -Level "ERROR"
    exit 1
}
#endregion

#region Core Removal Process
$removedPackages = New-Object System.Collections.Generic.List[string]
$removedProvisioned = New-Object System.Collections.Generic.List[string]
$operationList = New-Object System.Collections.Generic.List[System.Object]

try {
    # Process provisioned packages first
    Log-Message "`n=== Processing Provisioned Packages ==="
    $provCount = 0
    $provisioned = Get-AppxProvisionedPackage -Online
    
    foreach ($pattern in $patterns) {
        $matched = $provisioned | Where-Object { $_.PackageName -like $pattern }
        
        if (-not $matched) {
            continue
        }

        foreach ($pkg in $matched) {
            $provCount++
            $operation = [PSCustomObject]@{
                Type = "Provisioned"
                Action = if ($DryRun) {"PlanRemove"} else {"Removing"}
                Name = $pkg.PackageName
                FullName = $pkg.PackageName
            }
            $operationList.Add($operation)
            
            if ($DryRun) {
                Log-Message "$($operation.Action)$provCount`: $($operation.FullName)"
            } else {
                Log-Message "$($operation.Action)$provCount`: $($operation.FullName)"
            }
            
            if (-not $DryRun) {
                try {
                    $pkg | Remove-AppxProvisionedPackage -Online -ErrorAction Stop
                    $removedProvisioned.Add($pkg.PackageName)
                    Log-Message "  √ Success" -Level "SUCCESS"
                }
                catch {
                    Log-Message "  × Failed: $_" -Level "ERROR"
                }
            }
        }
    }
    
    if ($provCount -eq 0) {
        Log-Message "No matching provisioned packages found"
    }

    # Process app packages next
    Log-Message "`n=== Processing User App Packages ==="
    $appCount = 0
    
    foreach ($pattern in $patterns) {
        $packages = Get-AppxPackage -AllUsers | Where-Object { $_.Name -like $pattern }
        
        if (-not $packages) {
            continue
        }

        foreach ($pkg in $packages) {
            $appCount++
            $operation = [PSCustomObject]@{
                Type = "AppPackage"
                Action = if ($DryRun) {"PlanUninstall"} else {"Uninstalling"}
                Name = $pkg.Name
                FullName = $pkg.PackageFullName
            }
            $operationList.Add($operation)
            
            if ($DryRun) {
                Log-Message "$($operation.Action)$appCount`: $($operation.FullName)"
            } else {
                Log-Message "$($operation.Action)$appCount`: $($operation.FullName)"
            }
            
            if (-not $DryRun) {
                try {
                    $pkg | Remove-AppxPackage -AllUsers -ErrorAction Stop
                    $removedPackages.Add($pkg.PackageFullName)
                    Log-Message "  √ Success" -Level "SUCCESS"
                }
                catch {
                    Log-Message "  × Failed: $_" -Level "ERROR"
                }
            }
        }
    }
    
    if ($appCount -eq 0) {
        Log-Message "No matching app packages found"
    }
}
catch {
    Log-Message "Removal process interrupted: $_" -Level "ERROR"
    exit 2
}
#endregion

#region Results Report
Log-Message "`n=== Operation Summary ==="

if ($DryRun) {
    # Dry run mode: show detailed operation list
    $totalPlan = $operationList.Count
    if ($totalPlan -eq 0) {
        Log-Message "No matching UWP apps or provisioned packages found"
    } else {
        # Renumber all planned operations
        $counter = 1
        foreach ($op in $operationList) {
            Log-Message "PlanOperation$($counter.ToString().PadLeft(2, '0')): $($op.FullName)"
            $counter++
        }
        Log-Message "`nTotal Planned Operations: $totalPlan"
    }
    Log-Message "`n[Dry Run Complete] Above are planned operations. Remove -DryRun parameter to execute."
    exit 0
}
else {
    # Actual execution mode: show detailed operation list
    $totalRemoved = $removedPackages.Count + $removedProvisioned.Count
    if ($totalRemoved -eq 0) {
        Log-Message "No UWP apps or provisioned packages were removed"
    } else {
        # Renumber all executed operations
        $counter = 1
        foreach ($op in $operationList) {
            Log-Message "ExecOperation$($counter.ToString().PadLeft(2, '0')): $($op.FullName)"
            $counter++
        }
        Log-Message "`nActual App Packages Removed: $($removedPackages.Count)"
        Log-Message "Actual Provisioned Packages Removed: $($removedProvisioned.Count)"
        Log-Message "Total Operations: $totalRemoved"
    }

    # Generate final report
    $report = @"
=== UWP App Removal Report ===
Execution Time:   $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Script Version:   v$scriptVersion
App Packages Removed: $($removedPackages.Count)
Provisioned Packages Removed: $($removedProvisioned.Count)
Total Operations:   $totalRemoved

【Removed App Packages List】
$($removedPackages -join "`n")

【Removed Provisioned Packages List】
$($removedProvisioned -join "`n")

【Next Steps】
1. Restart system to complete cleanup
2. Verify system functionality
3. Old version cache information:
   - System usually auto-cleans old versions after reboot
   - Manual check locations:
     C:\Program Files\WindowsApps
     C:\Users\$env:USERNAME\AppData\Local\Packages
   - Tools like Dism++ can clean component store
4. Use system restore point if issues occur
"@

    $report | Out-File "$logDir\Removal_Summary_$timestamp.txt"
    Log-Message "Full report saved: $logDir\Removal_Summary_$timestamp.txt"

    # Display key summary
    Write-Host "`n" -NoNewline
    Write-Host "=== Operation Complete ===" -ForegroundColor Green
    if ($totalRemoved -gt 0) {
        Write-Host "App Packages Removed: $($removedPackages.Count)" 
        Write-Host "Provisioned Packages Removed: $($removedProvisioned.Count)"
        Write-Host "Total Operations: $totalRemoved"
    }
    Write-Host "Log Directory: $logDir" 
    Write-Host "`nImportant: Restart system to complete cleanup" -ForegroundColor Yellow
}
#endregion
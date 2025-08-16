<#
.SYNOPSIS
UWPӦ������ж�ع��� v1.14 (��ϸ�����б��)

.DESCRIPTION
����Ԥ�����patterns.txt�б�ж��UWPӦ�ü���Ԥ���
֧��Ԥ��ģʽ(-DryRun)�鿴�����ƻ�

.PARAMETER DryRun
Ԥ��ģʽ��ֻ��ʾ�����ƻ���ʵ��ִ��

.EXAMPLE
.\Remove-UWPApps.ps1          # ִ��ж��
.\Remove-UWPApps.ps1 -DryRun  # Ԥ��ģʽ
#>

param(
    [switch]$DryRun = $false
)

#region ��ʼ������
$ErrorActionPreference = "Stop"
$scriptVersion = "1.14"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$logDir = "$PSScriptRoot\Remove-UWPLogs"
$logFile = "$logDir\UWP_Removal_$timestamp.log"
$patternsFile = "$PSScriptRoot\patterns.txt"

# ������־Ŀ¼
if (-not (Test-Path $logDir)) { 
    New-Item -ItemType Directory -Path $logDir | Out-Null 
}

# ��־��¼����
function Log-Message {
    param([string]$Message, [string]$Level = "INFO")
    
    # д����־�ļ�
    Add-Content -Path $logFile -Value $Message
    
    # ����̨���
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

# ��ʾ����
Log-Message "=== UWPӦ������ж�ع��� v$scriptVersion ==="
Log-Message "====���ߣ�abludypanny@163.com ==="
Log-Message "ִ�п�ʼʱ��: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
if ($DryRun) {
    Log-Message "ִ��ģʽ: Ԥ��(��ʵ��ִ��)"
} else {
    Log-Message "ִ��ģʽ: ʵ��ж��"
}
Log-Message "��־�ļ�: $logFile"
Log-Message "----------------------------------------"
#endregion

#region ��ȡģʽ�ļ�
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
        throw "δ��patterns.txt���ҵ���Чģʽ"
    }
    
    Log-Message "����$($patterns.Count)��ж��ģʽ"
}
catch {
    Log-Message "��ȡpatterns.txtʧ��: $_" -Level "ERROR"
    exit 1
}
#endregion

#region ����ж������
$removedPackages = New-Object System.Collections.Generic.List[string]
$removedProvisioned = New-Object System.Collections.Generic.List[string]
$operationList = New-Object System.Collections.Generic.List[System.Object]

try {
    # ����Ԥ��� (�ȴ���)
    Log-Message "`n=== ����Ԥ��� ==="
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
                Type = "Ԥ���"
                Action = if ($DryRun) {"�ƻ��Ƴ�"} else {"�����Ƴ�"}
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
                    Log-Message "  �� �ɹ�" -Level "SUCCESS"
                }
                catch {
                    Log-Message "  �� ʧ��: $_" -Level "ERROR"
                }
            }
        }
    }
    
    if ($provCount -eq 0) {
        Log-Message "δ�ҵ�ƥ���Ԥ���"
    }

    # ����Ӧ�ð� (����)
    Log-Message "`n=== �����û�Ӧ�ð� ==="
    $appCount = 0
    
    foreach ($pattern in $patterns) {
        $packages = Get-AppxPackage -AllUsers | Where-Object { $_.Name -like $pattern }
        
        if (-not $packages) {
            continue
        }

        foreach ($pkg in $packages) {
            $appCount++
            $operation = [PSCustomObject]@{
                Type = "Ӧ�ð�"
                Action = if ($DryRun) {"�ƻ�ж��"} else {"����ж��"}
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
                    Log-Message "  �� �ɹ�" -Level "SUCCESS"
                }
                catch {
                    Log-Message "  �� ʧ��: $_" -Level "ERROR"
                }
            }
        }
    }
    
    if ($appCount -eq 0) {
        Log-Message "δ�ҵ�ƥ���Ӧ�ð�"
    }
}
catch {
    Log-Message "ж�ع����ж�: $_" -Level "ERROR"
    exit 2
}
#endregion

#region �������
Log-Message "`n=== ����������� ==="

if ($DryRun) {
    # Ԥ��ģʽ��ʾ��ϸ�����б�
    $totalPlan = $operationList.Count
    if ($totalPlan -eq 0) {
        Log-Message "δ�ҵ��κ�ƥ���UWPӦ�û�Ԥ���"
    } else {
        # ���±����ʾ���мƻ�����
        $counter = 1
        foreach ($op in $operationList) {
            Log-Message "�ƻ�����$($counter.ToString().PadLeft(2, '0')): $($op.FullName)"
            $counter++
        }
        Log-Message "`n�ܼƼƻ�������Ŀ: $totalPlan��"
    }
    Log-Message "`n[Ԥ�����] ����Ϊ�ƻ�ִ�еĲ�����ʵ��ִ��ʱ���Ƴ� -DryRun ����"
    exit 0
}
else {
    # ʵ��ִ��ģʽ��ʾ��ϸ�����б�
    $totalRemoved = $removedPackages.Count + $removedProvisioned.Count
    if ($totalRemoved -eq 0) {
        Log-Message "δж���κ�UWPӦ�û�Ԥ���"
    } else {
        # ���±����ʾ����ִ�в���
        $counter = 1
        foreach ($op in $operationList) {
            Log-Message "ִ�в���$($counter.ToString().PadLeft(2, '0')): $($op.FullName)"
            $counter++
        }
        Log-Message "`nʵ��ж��Ӧ�ð�: $($removedPackages.Count)��"
        Log-Message "ʵ���Ƴ�Ԥ���: $($removedProvisioned.Count)��"
        Log-Message "�ܼƴ�����Ŀ: $totalRemoved��"
    }

    # �������ձ���
    $report = @"
=== UWPӦ��ж�ر��� ===
ִ��ʱ��:   $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
�ű��汾:   v$scriptVersion
ж��Ӧ�ð�: $($removedPackages.Count)
ж��Ԥ���: $($removedProvisioned.Count)
�ܼƴ���:   $totalRemoved

����ж��Ӧ�ð��б�
$($removedPackages -join "`n")

�����Ƴ�Ԥ����б�
$($removedProvisioned -join "`n")

���������顿
1. ����ϵͳ�����������
2. ���ϵͳ�����Ƿ�����
3. �ɰ汾����˵��:
   - ϵͳͨ�������������Զ�����ɰ汾�ļ�
   - �����ֶ������ɼ������Ŀ¼:
     C:\Program Files\WindowsApps
     C:\Users\$env:USERNAME\AppData\Local\Packages
   - Dism++�ȹ���Ҳ��������������洢
4. �����쳣ʱ��ʹ��ϵͳ��ԭ��ָ�
"@

    $report | Out-File "$logDir\Removal_Summary_$timestamp.txt"
    Log-Message "���������ѱ���: $logDir\Removal_Summary_$timestamp.txt"

    # ��ʾ�ؼ�ժҪ
    Write-Host "`n" -NoNewline
    Write-Host "=== ������� ===" -ForegroundColor Green
    if ($totalRemoved -gt 0) {
        Write-Host "ж��Ӧ�ð�: $($removedPackages.Count)" 
        Write-Host "�Ƴ�Ԥ���: $($removedProvisioned.Count)"
        Write-Host "�ܼƴ�����Ŀ: $totalRemoved"
    }
    Write-Host "��־Ŀ¼: $logDir" 
    Write-Host "`n��Ҫ��ʾ: ������ϵͳ�����������" -ForegroundColor Yellow
}
#endregion
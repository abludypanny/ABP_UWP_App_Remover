<#
.SYNOPSIS
UWP应用批量卸载工具 v1.14 (详细操作列表版)

.DESCRIPTION
根据预定义的patterns.txt列表卸载UWP应用及其预配包
支持预演模式(-DryRun)查看操作计划

.PARAMETER DryRun
预演模式，只显示操作计划不实际执行

.EXAMPLE
.\Remove-UWPApps.ps1          # 执行卸载
.\Remove-UWPApps.ps1 -DryRun  # 预演模式
#>

param(
    [switch]$DryRun = $false
)

#region 初始化设置
$ErrorActionPreference = "Stop"
$scriptVersion = "1.14"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$logDir = "$PSScriptRoot\Remove-UWPLogs"
$logFile = "$logDir\UWP_Removal_$timestamp.log"
$patternsFile = "$PSScriptRoot\patterns.txt"

# 创建日志目录
if (-not (Test-Path $logDir)) { 
    New-Item -ItemType Directory -Path $logDir | Out-Null 
}

# 日志记录函数
function Log-Message {
    param([string]$Message, [string]$Level = "INFO")
    
    # 写入日志文件
    Add-Content -Path $logFile -Value $Message
    
    # 控制台输出
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

# 显示标题
Log-Message "=== UWP应用批量卸载工具 v$scriptVersion ==="
Log-Message "====作者：abludypanny@163.com ==="
Log-Message "执行开始时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
if ($DryRun) {
    Log-Message "执行模式: 预演(不实际执行)"
} else {
    Log-Message "执行模式: 实际卸载"
}
Log-Message "日志文件: $logFile"
Log-Message "----------------------------------------"
#endregion

#region 读取模式文件
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
        throw "未在patterns.txt中找到有效模式"
    }
    
    Log-Message "加载$($patterns.Count)个卸载模式"
}
catch {
    Log-Message "读取patterns.txt失败: $_" -Level "ERROR"
    exit 1
}
#endregion

#region 核心卸载流程
$removedPackages = New-Object System.Collections.Generic.List[string]
$removedProvisioned = New-Object System.Collections.Generic.List[string]
$operationList = New-Object System.Collections.Generic.List[System.Object]

try {
    # 处理预配包 (先处理)
    Log-Message "`n=== 处理预配包 ==="
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
                Type = "预配包"
                Action = if ($DryRun) {"计划移除"} else {"正在移除"}
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
                    Log-Message "  √ 成功" -Level "SUCCESS"
                }
                catch {
                    Log-Message "  × 失败: $_" -Level "ERROR"
                }
            }
        }
    }
    
    if ($provCount -eq 0) {
        Log-Message "未找到匹配的预配包"
    }

    # 处理应用包 (后处理)
    Log-Message "`n=== 处理用户应用包 ==="
    $appCount = 0
    
    foreach ($pattern in $patterns) {
        $packages = Get-AppxPackage -AllUsers | Where-Object { $_.Name -like $pattern }
        
        if (-not $packages) {
            continue
        }

        foreach ($pkg in $packages) {
            $appCount++
            $operation = [PSCustomObject]@{
                Type = "应用包"
                Action = if ($DryRun) {"计划卸载"} else {"正在卸载"}
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
                    Log-Message "  √ 成功" -Level "SUCCESS"
                }
                catch {
                    Log-Message "  × 失败: $_" -Level "ERROR"
                }
            }
        }
    }
    
    if ($appCount -eq 0) {
        Log-Message "未找到匹配的应用包"
    }
}
catch {
    Log-Message "卸载过程中断: $_" -Level "ERROR"
    exit 2
}
#endregion

#region 结果报告
Log-Message "`n=== 操作结果汇总 ==="

if ($DryRun) {
    # 预演模式显示详细操作列表
    $totalPlan = $operationList.Count
    if ($totalPlan -eq 0) {
        Log-Message "未找到任何匹配的UWP应用或预配包"
    } else {
        # 重新编号显示所有计划操作
        $counter = 1
        foreach ($op in $operationList) {
            Log-Message "计划操作$($counter.ToString().PadLeft(2, '0')): $($op.FullName)"
            $counter++
        }
        Log-Message "`n总计计划处理项目: $totalPlan个"
    }
    Log-Message "`n[预演完成] 以上为计划执行的操作，实际执行时请移除 -DryRun 参数"
    exit 0
}
else {
    # 实际执行模式显示详细操作列表
    $totalRemoved = $removedPackages.Count + $removedProvisioned.Count
    if ($totalRemoved -eq 0) {
        Log-Message "未卸载任何UWP应用或预配包"
    } else {
        # 重新编号显示所有执行操作
        $counter = 1
        foreach ($op in $operationList) {
            Log-Message "执行操作$($counter.ToString().PadLeft(2, '0')): $($op.FullName)"
            $counter++
        }
        Log-Message "`n实际卸载应用包: $($removedPackages.Count)个"
        Log-Message "实际移除预配包: $($removedProvisioned.Count)个"
        Log-Message "总计处理项目: $totalRemoved个"
    }

    # 生成最终报告
    $report = @"
=== UWP应用卸载报告 ===
执行时间:   $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
脚本版本:   v$scriptVersion
卸载应用包: $($removedPackages.Count)
卸载预配包: $($removedProvisioned.Count)
总计处理:   $totalRemoved

【已卸载应用包列表】
$($removedPackages -join "`n")

【已移除预配包列表】
$($removedProvisioned -join "`n")

【后续建议】
1. 重启系统完成最终清理
2. 检查系统功能是否正常
3. 旧版本缓存说明:
   - 系统通常会在重启后自动清理旧版本文件
   - 如需手动清理，可检查以下目录:
     C:\Program Files\WindowsApps
     C:\Users\$env:USERNAME\AppData\Local\Packages
   - Dism++等工具也可用于清理组件存储
4. 发现异常时可使用系统还原点恢复
"@

    $report | Out-File "$logDir\Removal_Summary_$timestamp.txt"
    Log-Message "完整报告已保存: $logDir\Removal_Summary_$timestamp.txt"

    # 显示关键摘要
    Write-Host "`n" -NoNewline
    Write-Host "=== 操作完成 ===" -ForegroundColor Green
    if ($totalRemoved -gt 0) {
        Write-Host "卸载应用包: $($removedPackages.Count)" 
        Write-Host "移除预配包: $($removedProvisioned.Count)"
        Write-Host "总计处理项目: $totalRemoved"
    }
    Write-Host "日志目录: $logDir" 
    Write-Host "`n重要提示: 请重启系统完成最终清理" -ForegroundColor Yellow
}
#endregion
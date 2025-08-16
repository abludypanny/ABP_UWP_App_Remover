ABP UWP应用批量卸载工具
ABP UWP App Remover
*版本 1.14 | 最后更新 2025-08-15*

一个专注于彻底清理 Windows UWP 应用的 PowerShell 脚本工具


🌟 核心优势 
        功能	                         本工具	                          Geek Uninstaller	                  Win11Debloat
清理无注册信息的包  	✅ 完全支持	                            ❌ 无法处理                  ⚠️ 部分支持
清理预配包	                ✅ 完整清除	                            ❌ 无法处理	           ⚠️ 部分支持
自定义卸载列表	        ✅ 完全可控	                             ⚠️ 手动操作	           ⚠️ 预定义选项
详细操作报告	                ✅ 完整日志                               ❌ 无                             ⚠️ 基础日志
安全预演模式            	✅ 无风险预览                           ❌ 无	                           ❌ 无
空间回收效果           	✅ 60%+ 空间释放	            ⚠️ 30-40%	           ⚠️ 40-50%

📥 使用指南
下载文件，解压到纯英文文件夹

# 推荐目录结构
ABP_UWP_App_Remover/
├── ABP_UWPAppRemover_CN.ps1    # 主脚本(中文版)
├── ABP_UWPAppRemover_EN.ps1    # 主脚本(英文版)
├── patterns.txt                                       # 卸载规则文件
└── Remove-UWPLogs/                         # 自动生成的日志目录

重要文件编辑： patterns.txt
如果您想按照你的规则卸载，请按以下规则修改：

# 示例规则 (每行一个匹配模式)
*Microsoft.YourPhone*       # 手机连接应用
*Xbox*                                    # 所有Xbox相关组件
*Bing*                                      # Bing系列应用

执行脚本：

# 以管理员身份运行 PowerShell
Set-ExecutionPolicy Bypass -Scope Process -Force

# 预演模式 (不实际执行)
.\ABP_UWPAppRemover_CN.ps1 -DryRun
或
.\ABP_UWPAppRemover_EN.ps1 -DryRun

# 实际执行
.\ABP_UWPAppRemover_CN.ps1
或
.\ABP_UWPAppRemover_EN.ps1

重启系统


⚙️ 技术特点
三重清理机制
    A[预配包] -->|Remove-AppxProvisionedPackage| B[系统级卸载]
    C[应用包] -->|Remove-AppxPackage| D[用户级卸载]
    E[残留文件] -->|重启后| F[系统自动清理]

安全防护设计
通配符精确匹配：避免误删系统关键组件

核心组件保护：自动跳过 Edge/Store/Security 等核心应用

详细日志记录：所有操作可追溯可审计

空间回收统计
项目	                       平均释放空间	峰值案例
全新安装 Win11	1.2-1.8GB	2.3GB
使用1年后系统	0.8-1.5GB	1.9GB
企业定制系统	        0.5-1.2GB	1.6GB

❓ 常见问题 / FAQ
Q: 和 Win11Debloat 有什么区别？
专注性：Win11Debloat 包含数百项系统调整，而本工具专注于UWP应用的彻底卸载
精确性：通过 patterns.txt 实现完全自定义卸载列表
安全性：不会修改系统设置/注册表/组策略

Q: 哪些应用绝对不要卸载？
Microsoft.WindowsStore*       # 应用商店 (应用更新必需)
Microsoft.MicrosoftEdge*      # Edge浏览器 (WebView核心组件)当然，硬是要删也不是不可以。
AppInstaller*                              # 应用安装引擎
Windows.CBSPreview*             # 系统核心组件
Microsoft.SecHealthUI*           # 安全中心

Q: 卸载后如何恢复？
1.Microsoft Store 重新安装
2.PowerShell 手动安装：
    Get-AppxPackage -AllUsers | Where Name -eq "Microsoft.YourPhone" | 
ForEach {Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml"}
3.使用系统还原点回滚

📜 版本历史
v1.14 (2025-08-15)
添加带序号的操作列表（01, 02,...）

显示完整包名（含版本信息）

优化预演模式输出格式

v1.12 (2025-08-15)
调整处理顺序（先预配包后应用包）

增强预演模式统计功能

添加缓存清理说明

v1.10 (2025-08-14)
简化日志格式（移除冗余时间戳）

优化输出信息（只显示包名称）

添加日志目录自动创建功能

⚠️ 重要提示 
1.始终创建系统还原点	
   powershell
Checkpoint-Computer -Description "Pre-UWP-Clean" -RestorePointType MODIFY_SETTINGS

2.企业环境测试建议：
先在虚拟机或测试机上运行
使用 -DryRun 参数验证效果
重点检查 Teams/Power Automate 等办公应用

3.最佳实践：
    推荐操作流程：
    a.新系统部署
      创建还原点 --> DryRun验证 --> 实际执行 --> 重启系统
    b.定期维护
      更新patterns.txt --> DryRun验证 --> 实际执行 --> 重启系统

免责声明：使用本工具造成的任何数据损失或系统问题，作者概不负责。操作前请务必备份重要数据并创建系统还原点！

开源协议：MIT License
项目维护：abludypanny
反馈问题：https://github.com/abludypanny/ABP_UWP_App_Remover/issues

您的UWP清理之旅从此开始！
ABP UWP应用批量卸载工具
ABP UWP App Remover


*版本 1.14 | 最后更新 2025-08-15*

*Version 1.14 | Last Updated 2025-08-15\**



一个专注于彻底清理 Windows UWP 应用的 PowerShell 脚本工具
A focused PowerShell tool for thorough removal of Windows UWP apps



🌟 核心优势 / Key Advantages
功能 / Feature                                本工具 / This Tool                  Geek Uninstaller	                  Win11Debloat
Clean packages without registry entries

清理无注册信息的包  	                         ✅ 完全支持	                            ❌ 无法处理                    ⚠️ 部分支持

Clean provisioned packages
清理预配包	                                   ✅ 完整清除	                            ❌ 无法处理	                  ⚠️ 部分支持

Custom removal list
自定义卸载列表	                              ✅ 完全可控	                               ⚠️ 手动操作	                ⚠️ 预定义选项
Detailed operation report

详细操作报告	                                ✅ 完整日志                               ❌ 无                         ⚠️ 基础日志
Safe dry run mode

安全预演模式                                	✅ 无风险预览                               ❌ 无	                       ❌ 无
Space recovery

空间回收效果                                	✅ 60%+ 空间释放	                        ⚠️ 30-40%	                 ⚠️ 40-50%

📥 使用指南 / Usage Guide
下载文件，解压到纯英文文件夹

Download the repository contents and extract to a folder with English-only path

# 推荐目录结构

## File Structure

 
- ABP_UWP_App_Remover/    # 主脚本(中文版)/ Chinese version
  - Remove-UWPLogs/       # 自动生成的日志目录/ Auto-generated log directory
  - ABP_UWPAppRemover_CN.ps1         # 主脚本(中文版)/ Chinese version
  - ABP_UWPAppRemover_EN.ps1         # 主脚本(英文版)/ English version
  - patterns.txt          # 卸载规则文件/ Removal patterns
  - README.md
  - LICENSE





Edit Pattern File

重要文件编辑： patterns.txt
如果您想按照你的规则卸载，请按以下规则修改：

# 示例规则 (每行一个匹配模式)

Example patterns (one per line)

*Microsoft.YourPhone*                       # 手机连接应用
*Xbox*                                      # 所有Xbox相关组件
*Bing*                                      # Bing系列应用



## 执行脚本：

## Execute Script



##### 以管理员身份运行 PowerShell / Run PowerShell as Administrator

Set-ExecutionPolicy Bypass -Scope Process -Force



##### 预演模式 (不实际执行) / Dry run mode (no actual changes)

.\ABP_UWPAppRemover_CN.ps1 -DryRun

或/or

.\ABP_UWPAppRemover_EN.ps1 -DryRun



##### 实际执行 / Actual execution

.\ABP_UWPAppRemover_CN.ps1

或/or

.\ABP_UWPAppRemover_EN.ps1



##### 重启系统/ Restart System



⚙️ 技术特点 / Technical Features
三重清理机制
A\[预配包] Provisioned Packages-->|Remove-AppxProvisionedPackage| B\[系统级卸载]System-level Removal
C\[应用包]App Packages -->|Remove-AppxPackage| D\[用户级卸载]User-level Removal
E\[残留文件]Residual Files -->|重启后| F\[系统自动清理]System Auto-cleanup
---



安全防护设计/ Safety Design
通配符精确匹配：避免误删系统关键组件

Precise wildcard matching: Prevents accidental removal of critical components

核心组件保护：自动跳过 Edge/Store/Security 等核心应用

Core component protection: Automatically skips Edge/Store/Security apps

详细日志记录：所有操作可追溯可审计

Detailed logging: All operations are traceable and auditable 



❓ 常见问题 / FAQ
Q: 和 Win11Debloat 有什么区别？ / How is this different from Win11Debloat?

专注性：Win11Debloat 包含数百项系统调整，而本工具专注于UWP应用的彻底卸载

Focus: Win11Debloat includes hundreds of system tweaks, while this tool focuses solely on UWP app removal

精确性：通过 patterns.txt 实现完全自定义卸载列表

Precision: Fully customizable removal list via patterns.txt

安全性：不会修改系统设置/注册表/组策略

Safety: Does not modify system settings/registry/group policies



Q: 哪些应用绝对不要卸载？ / Which apps should never be uninstalled?

Microsoft.WindowsStore\*       # 应用商店 (应用更新必需) / Store (required for app updates)

Microsoft.MicrosoftEdge\*      # Edge浏览器 (WebView核心组件) / Edge (WebView core component)

AppInstaller\*                 # 应用安装引擎 / App installation engine

Windows.CBSPreview\*           # 系统核心组件 / System core component

Microsoft.SecHealthUI\*        # 安全中心 / Security Center



Q: 卸载后如何恢复？ / How to restore after uninstallation?

1\.Microsoft Store 重新安装 / Reinstall from Microsoft Store

2\.PowerShell 手动安装 / Manual installation via PowerShell:

Get-AppxPackage -AllUsers | Where Name -eq "Microsoft.YourPhone" |
ForEach {Add-AppxPackage -DisableDevelopmentMode -Register "$($\_.InstallLocation)\\AppXManifest.xml"}

3.使用系统还原点回滚 / Rollback using system restore point





## 📜 版本历史 / Version History

v1.14 (2025-08-15)

添加带序号的操作列表（01, 02,...）

Added numbered operation list (01, 02,...)

显示完整包名（含版本信息）

Show full package names (with version info)

优化预演模式输出格式

Improved dry run output format



v1.12 (2025-08-15)

调整处理顺序（先预配包后应用包）

Changed processing order (provisioned packages first)

增强预演模式统计功能

Enhanced dry run statistics

添加缓存清理说明

Added cache cleanup instructions



v1.10 (2025-08-14)

简化日志格式（移除冗余时间戳）

Simplified log format (removed redundant timestamps)

优化输出信息（只显示包名称）

Optimized output (show package names only)

添加日志目录自动创建功能

Added auto-creation of log directory





## ⚠️ 重要提示 / Important Notes

1\.始终创建系统还原点 / Always create a system restore point

powershell
Checkpoint-Computer -Description "Pre-UWP-Clean" -RestorePointType MODIFY\_SETTINGS



2\.企业环境测试建议 / Enterprise testing recommendations:

先在虚拟机或测试机上运行

First run on VM or test machine

使用 -DryRun 参数验证效果

Validate with -DryRun parameter

重点检查 Teams/Power Automate 等办公应用

Verify business apps like Teams/Power Automate



3\.最佳实践 / Best practices:

&nbsp;title 推荐操作流程 / Recommended Workflow

&nbsp;   section 新系统部署 / New System Deployment

&nbsp;     创建还原点 --> DryRun验证 --> 实际执行 --> 重启系统

&nbsp;     Create Restore Point --> Dry Run --> Execute --> Restart

&nbsp;   section 定期维护 / Regular Maintenance

&nbsp;     更新patterns.txt --> DryRun验证 --> 实际执行 --> 重启系统

&nbsp;     Update patterns.txt --> Dry Run --> Execute --> Restart



#### 免责声明：使用本工具造成的任何数据损失或系统问题，作者概不负责。操作前请务必备份重要数据并创建系统还原点！

Disclaimer: The author is not responsible for any data loss or system issues caused by using this tool. Always back up important data and create a system restore point before use!



开源协议 / License: MIT License

项目维护 / Maintained by: abludypanny

反馈问题 / Report Issues: https://github.com/abludypanny/ABP_UWP_App_Remover

         **第一次发布Github，也不会写代码，
           主要是DeepSeek和Copilot帮我写的代码，改了一下午总算成功，
           连Git都不知道用，所以只能网页上传，格式页面惨不忍睹，亲大佬们谅解。**
         **This is my first time publishing on Github, and I don't know how to code. 
         DeepSeek and Copilot helped me write the code. After spending the whole afternoon making changes, I finally succeeded. 
         I don't even know how to use Git, so I had to upload through the web page. 
         The formatting of the page is terrible, so please forgive me, dear experts. **

&nbsp;您的UWP清理之旅从此开始！

Start your UWP cleaning journey here!




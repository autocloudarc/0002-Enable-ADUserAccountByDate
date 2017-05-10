#requires -version 2.0
<#
****************************************************************************************************************************************************************************************************************
PROGRAM		
 0002-Enable-ADUserAccountByDateTkn.ps1

DESCRIPTION
 This script enables user accounts based on the value of it's extendedAttribute11. Any extensionAttribute can be used, but the corresponding lines indicating the attribute used will have to be updated.
 This value is a string data type representing the date that the user account is to be activated. It must use the format: YYYY/MM/DD, and MM and DD values must be padded, where 2016/1/1 is represented
 as 2016/01/01. The script can be scheduled to run daily as a scheduled task.

INPUTS
 Newly provisioned, disabled accounts that will be activated at some future time, must have their extensionAttribute11 populated with a string value in the format YYYY/MM/DD.

OUTPUTS
 See log file sample in the multi-line comment at the end of this script.

EXAMPLES
.\Enable-ADUserAccountByDate.ps1

REQUIREMENTS
 Rights: 
 A service account should be used to execute this script as a task, and also have the ability to read and write user properties in Active Directory. 
 This service account should also have the ability to run as a service and as a batch job, and be a member of the local administrators group on the server from which the script executes. 
 As a result, when executing this script, ensure that the PowerShell console or PowerShell_ISE is opened with the "Run as administrator" option.
 Pre-requisites:
 User account information is pre-populated from an external source, for example, the HR department may list the account properties of a new employee that is being on-boarded so that the IT department can perform these initial bulk additions. 
 Alternatively, if access to HR personnel has been granted, HR may update Active Directory directly. Active Directory will therefore be updated before the projected start date for each user, but the account will be provisioned in a disabled state. 
 In order to automatically activate the user account on the designated start date for each user, a scheduled PowerShell 2.0 (or greater) script can be used to enable each account if the scheduled date for activation matches the current date.

LIMITATIONS
 NA

AUTHOR(S)
1. Preston K. Parsard, Microsoft Premier Field Engineer

EDITOR(S) 

REFERENCE(S)
NA

KEYWORD(S) 
1. extensionAttribute11
2. User
3. Account

LICENSE:

The MIT License (MIT)
Copyright (c) 2016 Preston K. Parsard

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software. 

LEGAL DISCLAIMER:
This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.  
THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, 
INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.  
We grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and distribute the object code form of the Sample Code, provided that You agree: 
(i) to not use Our name, logo, or trademarks to market Your software product in which the Sample Code is embedded; 
(ii) to include a valid copyright notice on Your software product in which the Sample Code is embedded; and 
(iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims or lawsuits, including attorneys’ fees, that arise or result from the use or distribution of the Sample Code.
This posting is provided "AS IS" with no warranties, and confers no rights.
****************************************************************************************************************************************************************************************************************
#>

<# 
TASK ITEMS
ITEM-INDEX:
#>

#***************************************************************************************************************************************************************************
# REVISION/CHANGE RECORD	
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# DATE         VERSION    NAME			     CHANGE
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# 12 JAN 2016  00.00.0001 Preston K. Parsard Initial draft
# 13 JAN 2016  00.00.0002 Preston K. Parsard Tested with scheduled task
# 14 JAN 2016  00.00.0003 Preston K. Parsard Applied GPO for service account to run as a service and batch job in the user rights assignment section.
# 14 JAN 2016  00.00.0004 Preston K. Parsard Completed final testing. Updated date format stamped in extensionAttribute11 to YYYY-MM-DD.
# 07 FEB 2016  00.00.0005 Preston K. Parsard Updated heading format and legal disclaimer
# 07 FEB 2016  00.00.0006 Preston K. Parsard Renamed script from Enable-ADUserAccount.ps1 to Enable-ADUserAccountByDate.ps1 to make it more descriptive
# 07 FEB 2016  00.00.0007 Preston K. Parsard Added sample log output at end of script
# 22 MAY 2016  00.00.0008 Preston K. Parsard Added MIT license in header
# 22 MAY 2016  00.00.0009 Preston K. Parsard Updated filename to: 0002-Enable-ADUserAccountByDateTkn.ps1 in order to index and tag as a contributed script

# PRE-REQUISITES 

# Construct log file from hostname and current date/time
$StartTime = Get-Date
# Remove spaces and ":" from the time/date format
$TimeStamp = (((get-date -format u).Substring(0,16)).Replace(" ", "-")).Replace(":","")

# Convert the time/date format to the YYYY/MM/DD format. Note: here MM and DD are padded, so January 13th, 2016 is represented as 2016/13/01, not 2016/1/1
$SubTodayU = $TimeStamp.Substring(0,10)
$SlashSubTodayU = $SubTodayU.ToString()
$SlashSubTodayU
$Index = 0

# ITEM-INDEX: 001. [CHANGE] this path to your server share path, i.e. \\server\share or drive-letter:\folder
$LogPath = "<Path to your log directory>"

# Create log file
$LogFile = "Enable-ADUserAccount" + "-" + $TimeStamp + ".log"
$Log = Join-Path -Path $LogPath -ChildPath $LogFile
$dnc = (Get-ADRootDSE).DefaultNamingContext

# FUNCTIONS	

# Send output to log file only
Function Script:Write-ToLog
{
[CmdletBinding()] Param([Parameter(Mandatory=$True)]$LogData)
$LogData | Out-File -FilePath $Log -Append
} #end Write-ToLog

# Send output to both the console and log file and include a time-stamp
Function Script:Write-WithIndex
{
[CmdletBinding()] Param([Parameter(Mandatory=$True)]$LogEntry)
# Increment index counter to uniquely identify this item being inspected
$Script:Index++
"{0}`t{1}" -f $Script:Index,$LogEntry | Tee-Object -FilePath $Log -Append
} #end Write-WithIndex

# MAIN	
# INITIALIZE VALUES

#region Initialize 
$DesiredForeground = "Green"
$StartTime = Get-Date 
#endregion

# Multi-line headers
$Header = @"
START TIME : $TimeStamp
========================================================================================
|HEADER|
========================================================================================
"@

$SummaryHeader = @"
========================================================================================
|DAILY ACCOUNT ACTIVATION LIST
========================================================================================
"@

$SingleLine = "----------------------------------------------------------------------------------------"
$DoubleLine = "========================================================================================"

# Set foreground color 
$host.ui.RawUI.ForegroundColor = $DesiredForeground

# ITEM-INDEX: 001.Remove before launch
# Show Summary 

Write-ToLog($SummaryHeader)
Write-ToLog("DOMAIN NAMING CONTEXT: $dnc")
Write-ToLog("DATE                 : $SlashSubTodayU")
Write-ToLog("LOG                  : $Log")
Write-ToLog($DoubleLine)

# Get all user account names and their extended attribute 11
$UserAccounts = Get-ADUser -Filter * -Properties SamAccountName, extensionAttribute11 

# Iterate though the list of all users
ForEach ($UserAccount in $UserAccounts)
{
 # Examine the value of extension attribute 11 for each user account
 Switch ($UserAccount.extensionAttribute11)
 {
  # If the activation date is scheduled for today, then enable the account and log the activity
  $SlashSubTodayU 
  { 
   Write-ToLog($SingleLine)
   Write-WithIndex("$($UserAccount.SamAccountName) :checking user status...") 
   # It is expected that the account will be in a disabled state already if it is scheduled to be activated today
   If (-not($UserAccount.Enabled))
   {
    # Indicate that account is already disabled, but will be enabled, then update the status to show that the account has been enabled
    Write-ToLog("`tUser status:DISABLED")
    Write-ToLog("`tChanging status to: ENABLED...")
    Enable-ADAccount -Identity $UserAccount.SamAccountName
    Write-ToLog("`tUser status:ENABLED")
   } #end if
   else 
   {
    # If the account was already enabled, then skip the activation task, but indicate that it was already enabled in the logs.
    Write-ToLog("`tUser status is already: ENABLED. Skipping ENABLE operation")
   } #end else
  } #end $SlashSubTodayU
   
 } #end Switch

} #end foreach

# $UserActivationSchedule | Where-Object { $_.extensionAttribute11 -eq "2016/01/12" } | Format-Table -Property SamAccountName, extensionAttribute11
# ($UserActivationSchedule).extensionAttribute11

# FOOTER	

# Calculate elapsed time
$StopTime = Get-Date
$ExecutionTime = New-TimeSpan -Start $StartTime -End $StopTime

$Footer = @"
----------------------------------------------------------------------------------------										
USERS PROCESSED TODAY: $Index
STOP TIME: $StopTime
EXECUTION: $ExecutionTime 
========================================================================================                                           
----------------------------------------------------------------------------------------
LOG: $Log
----------------------------------------------------------------------------------------
"@	

# Show results 
Write-ToLog($Footer)

# Open log
Start-Process notepad.exe $Log

# ITEM-INDEX: 002. Remove comment when testing to activate the Pause feature. Comment out for production
PAUSE

# SAMPLE LOG OUTPUT
<#
========================================================================================
|DAILY ACCOUNT ACTIVATION LIST
========================================================================================
DOMAIN NAMING CONTEXT: DC=<domain>,DC=lab
DATE                 : 2016-01-14
LOG                  : L:\LOGS\Enable-ADUserAccountByDate-2016-01-14-1630.log
========================================================================================
----------------------------------------------------------------------------------------
1	usr.g001.s001 :checking user status...
	User status:DISABLED
	Changing status to: ENABLED...
	User status:ENABLED
----------------------------------------------------------------------------------------
2	usr.g010.s010 :checking user status...
	User status:DISABLED
	Changing status to: ENABLED...
	User status:ENABLED
----------------------------------------------------------------------------------------
3	usr.g011.s011 :checking user status...
	User status:DISABLED
	Changing status to: ENABLED...
	User status:ENABLED
----------------------------------------------------------------------------------------										
USERS PROCESSED TODAY: 3
STOP TIME: 01/14/2016 16:30:34
EXECUTION: 00:00:02.3750180 
========================================================================================                                           
----------------------------------------------------------------------------------------
LOG: L:\LOGS\Enable-ADUserAccountByDate-2016-01-14-1630.log
----------------------------------------------------------------------------------------
#>
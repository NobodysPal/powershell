#requires -version 2
<#
.SYNOPSIS
  Disables Wi-Fi network adapter if connected to certain domain.

.DESCRIPTION
  This script check the currently connected domain or workgroup, if the criteria matches the desired domain the script will disable the Wi-Fi network adapter.

.PARAMETER computer
  Hostname of the computer to check. Defualt is localhost.

.PARAMETER domain
  This is the domian or workgroup to match.

.INPUTS None
  
.OUTPUTS None

.NOTES
  Version:        1.0
  Author:         Jeff Pierdomenico
  Creation Date:  21 April 2016
  Purpose/Change: Initial script development

.EXAMPLE
  Disable-DomainWifi -computer MyComputer -domain HomeDomain

  This example will check if MyComputer is connected to HomeDomain and if it is, will disable the Wi-Fi adapter. 
#>

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

#Set Default Error Action
$ErrorActionPreference = 'Stop'

#Import PSLogging Module
#Import-Module PSLogging

#----------------------------------------------------------[Declarations]----------------------------------------------------------

#Script Version
$sScriptVersion = '1.0'

#Log File Info
#$sLogPath = 'C:\Windows\Temp'
#$sLogName = '<script_name>.log'
#$sLogFile = Join-Path -Path $sLogPath -ChildPath $sLogName

#-----------------------------------------------------------[Functions]------------------------------------------------------------


function Disable-DomainWifi{             
    [CmdletBinding()]             
    param (             
        [parameter(
            Position=0,            
            Mandatory=$true,            
            ValueFromPipeline=$true,             
            ValueFromPipelineByPropertyName=$true)
        ]            
    [string]$computer=".",
    [string]$domain="WORKGROUP" #set theis to your domain or workgroup to check for             
    )
                 
    BEGIN{
        [int]$OSVersion = [environment]::OSVersion.Version | select -ExpandProperty Major
    }#begin             

    PROCESS{            
        Try{
            $getdomain = Get-WmiObject -Class Win32_ComputerSystem -ComputerName $computer | select -ExpandProperty Domain -ErrorAction Stop
            $wificard = Get-WmiObject -Class Win32_NetworkAdapter -filter "Name LIKE '%Wireless%'" -ErrorAction Stop
        }
        Catch [Exception]{
            write-host “Caught an exception:” -ForegroundColor Red
            write-host “Exception Type: $($_.Exception.GetType().FullName)” -ForegroundColor Red
            write-host “Exception Message: $($_.Exception.Message)” -ForegroundColor Red
            Break
        }
           
    }#process             

    END{
        if($getdomain -eq $domain -and $wificard){
            if($OSVersion -le 6){
                $wificard.disable()
            }
            else{
                Get-NetAdapter -Name Wi-Fi | Disable-NetAdapter -Confirm $false
            }
            return $true
        }
        else{
            return $false
        }
    }#end            
            
}
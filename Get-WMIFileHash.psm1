<#
.SYNOPSIS
  Hashing files using WMI only

.DESCRIPTION
  Hashing files using WMI only

.TODO
  (1) Async

  
.NOTES
  Version:        1.0
  Author:         Jeff Pierdomenico
  Creation Date:  21 August 2016
  Purpose/Change: Initial script development

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

Function Get-WMIFileHash {
#comment based help is here

    [cmdletbinding()]
    Param(
        [Parameter(Position=0,Mandatory=$True,HelpMessage="Which computers to check?")]
        [ValidateNotNullorEmpty()]
        [string[]]$computers=$env:COMPUTERNAME,
        [ValidateNotNullorEmpty()]
        [string]$hashfile,
        [ValidateNotNullorEmpty()]
        [string]$dohash="%TEMP%\do-hash.ps1"
    )
    
    # Sets the verbosity
    $VerbosePreference = "Continue"

    $ascii = "DQAKACAAIAAgAF8AXwBfAF8AXwAgACAAIAAgACAAIABfACAAIAAgACAAIAAgACAAXwBfACAAIAAg
              ACAAIAAgACAAIAAgACAAXwBfAF8AXwAgACAAXwBfACAAXwBfAF8AXwBfACAAXwBfAF8AXwBfAF8A
              IABfACAAXwAgACAAIAAgACAAIABfACAAIAAgACAAXwAgACAAIAAgACAAIAAgACAAIAAgACAAXwAg
              ACAAIAAgACAADQAKACAAIAAvACAAXwBfAF8AXwB8ACAAIAAgACAAfAAgAHwAIAAgACAAIAAgACAA
              XAAgAFwAIAAgACAAIAAgACAAIAAgAC8AIAAvACAAIABcAC8AIAAgAHwAXwAgACAAIABfAHwAIAAg
              AF8AXwBfAF8AKABfACkAIAB8ACAAIAAgACAAfAAgAHwAIAAgAHwAIAB8ACAAIAAgACAAIAAgACAA
              IAAgAHwAIAB8ACAAIAAgACAADQAKACAAfAAgAHwAIAAgAF8AXwAgACAAXwBfAF8AfAAgAHwAXwAg
              AF8AXwBfAF8AXwBcACAAXAAgACAALwBcACAAIAAvACAALwB8ACAAXAAgACAALwAgAHwAIAB8ACAA
              fAAgAHwAIAB8AF8AXwAgACAAIABfAHwAIAB8ACAAXwBfAF8AfAAgAHwAXwBfAHwAIAB8ACAAXwBf
              ACAAXwAgAF8AXwBfAHwAIAB8AF8AXwAgACAADQAKACAAfAAgAHwAIAB8AF8AIAB8AC8AIABfACAA
              XAAgAF8AXwB8AF8AXwBfAF8AXwBfAFwAIABcAC8AIAAgAFwALwAgAC8AIAB8ACAAfABcAC8AfAAg
              AHwAIAB8ACAAfAAgAHwAIAAgAF8AXwB8ACAAfAAgAHwAIAB8AC8AIABfACAAXAAgACAAXwBfACAA
              IAB8AC8AIABfACAALwAgAF8AXwB8ACAAJwBfACAAXAAgAA0ACgAgAHwAIAB8AF8AXwB8ACAAfAAg
              ACAAXwBfAC8AIAB8AF8AIAAgACAAIAAgACAAIAAgAFwAIAAgAC8AXAAgACAALwAgACAAfAAgAHwA
              IAAgAHwAIAB8AF8AfAAgAHwAXwB8ACAAfAAgACAAIAAgAHwAIAB8ACAAfAAgACAAXwBfAC8AIAB8
              ACAAIAB8ACAAfAAgACgAXwB8ACAAXABfAF8AIABcACAAfAAgAHwAIAB8AA0ACgAgACAAXABfAF8A
              XwBfAF8AfABcAF8AXwBfAHwAXABfAF8AfAAgACAAIAAgACAAIAAgACAAXAAvACAAIABcAC8AIAAg
              ACAAfABfAHwAIAAgAHwAXwB8AF8AXwBfAF8AXwB8AF8AfAAgACAAIAAgAHwAXwB8AF8AfABcAF8A
              XwBfAHwAXwB8ACAAIAB8AF8AfABcAF8AXwAsAF8AfABfAF8AXwAvAF8AfAAgAHwAXwB8AA0ACgAg
              ACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAA
              IAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAg
              ACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAA
              IAAgAA0ACgAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAg
              ACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAA
              IAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAg
              ACAAIAAgACAAIAAgAA=="
    
    # Writes Header information
    $header = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($ascii))
    Write-Host $header -ForegroundColor DarkGray
    Write-Host "  Author: Jeff Pierdomenico  Version: 1.0BETA  Date: 21 Aug 2016 `n" -ForegroundColor DarkGray

    # Creating the empty hashed file object
    $hashedfile = New-Object -TypeName PsObject -Property @{
        Time = $Null
        System = $Null
        File = $Null
        Hash = $Null
        }

    # Builds the encoded command to pass to the remote system
    $command = {
        New-EventLog -LogName HASHLOG -Source HASHLOG
        $hash=Invoke-Expression "certutil.exe -hashfile <file>" -ErrorAction SilentlyContinue
        $result=$hash[1] | Out-String
        if($result -match "cannot"){
            Write-EventLog -LogName HASHLOG -Source HASHLOG -EventId 0834 -EntryType Information -Message "$(Get-Date -Format u)|$($env:computername)|<file>|Failed"
        }
        else{Write-EventLog -LogName HASHLOG -Source HASHLOG -EventId 0834 -EntryType Information -Message "$(Get-Date -Format u)|$($env:computername)|<file>|$($result.Replace(' ' ,''))"
        }
    }
    $command = $command -replace "<file>",$hashfile
    $encodedCommand = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($command))

    # Combines all the arguments required for the command line
    $argumentlist = " -NoLogo -NoProfile -Noninteractive -ExecutionPolicy Unrestricted -EncodedCommand"
    
    # Clean up commands
    $cleanup = {
        Remove-EventLog -LogName HASHLOG
        Set-ExecutionPolicy Default -Force
    }
    $cleanup =[Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($cleanup))
    
    Try {
        foreach ($computer in $computers) {     
            # Tasking the remote system with the encoded commands
            Write-Verbose "[$computer] Sending the tasking script encoded"
            Write-Verbose $encodedCommand
            Invoke-WmiMethod -ComputerName $computer -Class Win32_Process -Name Create -ArgumentList "cmd.exe /c powershell.exe $argumentlist $encodedCommand" | Out-Null

            # Pausing for a few seconds to let the remote system hash the file
            Start-Sleep -Seconds 5

            # TIme to retrieve the hash
            Write-Verbose "[$computer] Retrieving the file hash..."
            [string]$message = Get-WmiObject -ComputerName $computer -query "SELECT * FROM Win32_NTLogEvent WHERE (logfile='HASHLOG' and SourceName='HASHLOG')" | Select-Object -ExpandProperty Message
            $i=1
            While(($message.Length -eq 0) -and ($i -lt 10)) {
                [string]$message = Get-WmiObject -ComputerName $computer -query "SELECT * FROM Win32_NTLogEvent WHERE (logfile='HASHLOG' and SourceName='HASHLOG')" | Select-Object -ExpandProperty Message
                Write-Verbose "[$computer] Attempt #$i of 10..."
                $i++
                Start-Sleep -Seconds 10
            }
            
            # Assemble the file object
            $hashedfile.Time = $($message.Split("|")[0]).Trim()
            $hashedfile.System = $($message.Split("|")[1]).Trim()
            $hashedfile.File = $($message.Split("|")[2]).Trim()
            $hashedfile.Hash = $($message.Split("|")[3]).Trim()
            $hashedfile | Format-List System,File,Hash,Time
        }
    }
    Finally {
        Write-Verbose "[i] Cleaning up..."
        Write-Verbose $cleanup
        Invoke-WmiMethod -ComputerName $computers -Class Win32_Process -Name Create -ArgumentList "cmd.exe /c powershell.exe $argumentlist $cleanup" | Out-Null
        Start-Sleep -Seconds 1
        Write-Verbose "[i] Done"    
    }
}
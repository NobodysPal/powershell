#requires -version 2
<#
.SYNOPSIS
  Collects files and provides file hashes based on criteria.

.DESCRIPTION
  This module will collect all the files in a given directory, recursive is an option, and will provide the option to has the files.

.TODO
  (1) Manage large file hashing memore utilization
  (2) Enable PSRemoting
  (3) Comparison to whitlist
  (4) Comparison across multiple machines
  (5) Identify files of interest
  
.NOTES
  Version:        1.0
  Author:         Jeff Pierdomenico
  Creation Date:  24 April 2016
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
﻿function Collect-Files{             
    [CmdletBinding()]             
    param (             
        [parameter(
            Position=0,            
            Mandatory=$true,            
            ValueFromPipeline=$true,             
            ValueFromPipelineByPropertyName=$true)
        ]            
        [string]$path=".",
        [switch]$recursive=$false,
        [string]$outfile="$env:userprofile\Desktop\files.txt"     
    )
                 
    BEGIN{
        Clear-Host
        function Error-Collection($error){
            write-Host “[!] Caught an exception” -ForegroundColor Red
            write-Host “[!] Exception Type: $($_.Exception.GetType().FullName)” -ForegroundColor Red
            write-Host “[!] Exception Message: $($_.Exception.Message)” -ForegroundColor Red
            Break
        }

        function Hash-Files{
            Try{
                $files = Get-Content $outfile
                foreach($file in $files){
                    $progress = $files.count - $files.IndexOf($file)
                    if((Get-Item $file).length -gt 10mb){
                        Write-Host "[!] File is larget than 10mb, skipping for performance:" $file -ForegroundColor Yellow    
                    }
                    else{
                        Get-FileHash -Algorithm MD5 $file -ErrorAction SilentlyContinue | Out-Null
                    }
                    Write-Progress -Activity “Hashing all the files. $progress remaining” -status “Hashing file: $file” -percentComplete ($files.IndexOf($file) / $files.count*100)
                }
            }
            Catch [Exception]{
                Error-Collection($_.Exception)
            }
            Write-Progress -Activity “Hashing all the files” -status “All Done” -PercentComplete 100
            Start-Sleep -Seconds 3
        }

        function User-Prompt{
            param(
                [Parameter(Mandatory=$true)]
                [string]$title = "",
                [Parameter(Mandatory=$true)]
                [string]$message = "",
                [Parameter(Mandatory=$true)]
                $yesaction,
                [Parameter(Mandatory=$true)]
                $noaction
            )

            $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Agrees to the action or question."
            $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Does not agree with the action."
            $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
            $result = $host.ui.PromptForChoice($title, $message, $options, 0) 

            switch($result)
                {
                    0 { Invoke-Expression $yesaction }
                    1 { Invoke-Expression $noaction }
                }
        }

        Try{
            Write-Host "[!] Testing for availability of: "$path -ForegroundColor Yellow
            if(-not (Test-Path -Path $path)){
                throw [System.IO.FileNotFoundException] "$path not found."
            }
            else{
                Write-Host "[#] Path is good:" $path -ForegroundColor Green
                if(-not (Test-Path -PathType Container -Path $path) -and $recursive){
                    Write-Host "[!] Path is a single file, '-recursive' switch not required...removing." -ForegroundColor Yellow
                    $recursive = $false
                }
            }
        }
        Catch [Exception]{
            Error-Collection($_.Exception)
        }
    }#begin             

    PROCESS{            
        Try{
            User-Prompt -title "Ready to Execute File Collection?" -message "This can cause a strain on the system if a large directory is selected." -yesaction Continue -noaction Exit
            if($recursive){
                $files = Get-ChildItem -Path $path -Recurse -File -ErrorAction SilentlyContinue | Select -ExpandProperty FullName
            }
            else{
                $files = Get-ChildItem -Path $path -File -ErrorAction SilentlyContinue | Select -ExpandProperty FullName
            }
        }
        Catch [Exception]{
            Error-Collection($_.Exception)
        }
           
    }#process             

    END{
        Try{
            Out-File -InputObject $files -FilePath $outfile
            Write-Host "[#] All done collecting files. Output written to file: $outfile" -ForegroundColor Green
            User-Prompt -title "Hash the files?" -message "Would you like to hash the files now?" -yesaction Hash-Files -noaction 'Write-Host "[#] Response was No." -ForegroundColor Green'
            Write-Host "[#] Fin...Seriously..." -ForegroundColor Green
        }
        Catch [Exception]{
            Error-Collection($_.Exception)
        }
    }#end            
            
}

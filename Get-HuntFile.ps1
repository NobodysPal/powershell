﻿<#
.SYNOPSIS
  Finds files using WMI across a domain

.DESCRIPTION
  Using custom objects, this module will search the entire file structure of a domain to find files of interest

.TODO
  (1) Pass output to next script

  
.NOTES
  Version:        1.0
  Author:         Jeff Pierdomenico
  Creation Date:  13 August 2016
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

Function Get-HuntFile {
    [cmdletbinding()]
    Param(
        [Parameter(
                   Position=0,
                   Mandatory=$True,
                   HelpMessage="Which file to hunt?"
                  )
        ]
        [ValidateNotNullorEmpty()]
        [string[]]$computers = $env:COMPUTERNAME,
        [ValidateNotNullorEmpty()]
        [ValidateSet("C:","A:","B:","D:","E:","F:","G:","X:","Y:","Z:")]
        [string]$drive = 'C:',
        [ValidateNotNullorEmpty()]
        [string]$filename,
        [switch]$credential,
        [switch]$fulloutput
    )

    # Enables Verbose output
    $VerbosePreference = "Continue"

    # Initalizing private object
    $file = New-Object -TypeName PsObject -Property @{
        Drive = $Null
        Name = $Null
        Extension = $Null
        }
    $output = $NUll
    $ascii = "IAAgACAAXwBfAF8AXwBfACAAIAAgACAAIAAgAF8AIAAgACAAIAAgACAAIAAgACAAIABfACAAIAAg
              ACAAXwAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgAF8AIAAgACAAXwBfAF8AXwBfAF8AIABfACAA
              XwAgACAAIAAgACAAIAAKACAAIAAvACAAXwBfAF8AXwB8ACAAIAAgACAAfAAgAHwAIAAgACAAIAAg
              ACAAIAAgAHwAIAB8ACAAIAB8ACAAfAAgACAAIAAgACAAIAAgACAAIAAgACAAfAAgAHwAIAB8ACAA
              IABfAF8AXwBfACgAXwApACAAfAAgACAAIAAgACAACgAgAHwAIAB8ACAAIABfAF8AIAAgAF8AXwBf
              AHwAIAB8AF8AIABfAF8AXwBfAF8AXwB8ACAAfABfAF8AfAAgAHwAXwAgACAAIABfACAAXwAgAF8A
              XwAgAHwAIAB8AF8AfAAgAHwAXwBfACAAIAAgAF8AfAAgAHwAIABfAF8AXwAgAAoAIAB8ACAAfAAg
              AHwAXwAgAHwALwAgAF8AIABcACAAXwBfAHwAXwBfAF8AXwBfAF8AfAAgACAAXwBfACAAIAB8ACAA
              fAAgAHwAIAB8ACAAJwBfACAAXAB8ACAAXwBfAHwAIAAgAF8AXwB8ACAAfAAgAHwAIAB8AC8AIABf
              ACAAXAAKACAAfAAgAHwAXwBfAHwAIAB8ACAAIABfAF8ALwAgAHwAXwAgACAAIAAgACAAIAAgAHwA
              IAB8ACAAIAB8ACAAfAAgAHwAXwB8ACAAfAAgAHwAIAB8ACAAfAAgAHwAXwB8ACAAfAAgACAAIAAg
              AHwAIAB8ACAAfAAgACAAXwBfAC8ACgAgACAAXABfAF8AXwBfAF8AfABcAF8AXwBfAHwAXABfAF8A
              fAAgACAAIAAgACAAIAB8AF8AfAAgACAAfABfAHwAXABfAF8ALABfAHwAXwB8ACAAfABfAHwAXABf
              AF8AfABfAHwAIAAgACAAIAB8AF8AfABfAHwAXABfAF8AXwB8AAoAIAAgACAAIAAgACAAIAAgACAA
              IAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAg
              ACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAA="
    
    # Writes Header information
    $header = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($ascii))
    Write-Host $header -ForegroundColor DarkGray
    Write-Host "  Author: Jeff Pierdomenico  Version: 1.0BETA  Date: 13 Aug 2016 `n" -ForegroundColor DarkGray

    # Sets up the output directory
    $outputpath = "C:\Users\Administrator\Desktop\output\" #$(Split-Path -Path $PSCommandPath) + "\output"
    $outputfile = "HuntFile-" + $((get-date).ToUniversalTime()).ToString("yyyyMMddTHHmmZ")
    Try {    
        If (Test-Path -Path $outputpath){
            Write-Verbose "[i] Output path okay."
            $outputpath = $outputpath + $outputfile
        }
        Else {
            New-Item -ItemType directory -Path $outputpath
            Write-Warning "[!] New directory created at $outputpath"
            $outputpath = $outputpath + $outputfile
        }
    }
    Catch {
        Write-Warning "[!] Unable to create Output Directory at $outputpath"
    }
    
    # Drive letter clean up and validation
    Function Drive-Cleanup {
        Write-Verbose "[i] Validating Drive: $drive"
        If ($drive.Length -gt 2) {
            $drive = $drive.Substring(0,2)
        }
        If ($drive.EndsWith(":") -ne $true) {
            $drive = $drive.Substring(0,1) + ":"
        }
        $file.Drive = $drive
    }

    # Filename clean up and validation
    Function File-Cleanup {
        Write-Verbose "[i] Validating Filename: $filename"
        If ($filename.Contains(".")){
            $filename = $filename.Trim()
            $index = $filename.LastIndexOf(".")
            $file.Name = $filename.Substring(0,$index)
            $file.Extension = $filename.Substring($index+1)
        }
        Else {
            Write-Verbose "[!] Be sure your file has an extension."
        }
    }

    # Combine parameters into WMI filter
    Function Build-Filter {
        Write-Verbose "[i] Assembling filter."
        if ($file.Name -eq '*') {
            $filter = "extension='$($file.Extension)' AND Drive='$drive'"
        }
        else {
            $filter = "filename='$($file.Name)' AND extension='$($file.Extension)' AND Drive='$drive'"
        }
        Add-Member -InputObject $file –MemberType NoteProperty –Name "Filter" –value $filter
    }

    # Execute the main functions
    Try {
        Drive-Cleanup        
        File-Cleanup
        Build-Filter
        Write-Verbose "[i] Starting Jobs on $computers..."
        if ($credential) {
            $credentials = Get-Credential -Credential "DOMAIN\USER"
            foreach ($computer in $computers) { 
                Get-WmiObject -Class CIM_Datafile -Filter $file.Filter -ComputerName $computer -AsJob | Format-Table
            }
            $jobs = Get-Job
        }
        else {
            foreach ($computer in $computers) { 
                Get-WmiObject -Class CIM_Datafile -Filter $file.Filter -ComputerName $computer -AsJob | Format-Table
            }
            $jobs = Get-Job
        }
        
        $totaljobs = (Get-Job).Count
        While ((Get-Job).State -match 'Running')
        {
            foreach ($job in  $jobs | where {$_.HasMoreData})
            {
                #Write-Progress -Activity “Running Jobs” -status “Systems Remaining: $(($jobs | where {$_.HasMoreData}).Count) ” -percentComplete $((($jobs | where {$_.HasMoreData}).Count) / $totaljobs*100)
                Write-Progress -Activity “Running Jobs” -status “Systems Remaining: $(((Get-Job).State -match 'Running').Count) ” -percentComplete $((((Get-Job).State -match 'Running').Count) / $totaljobs*100)

            }
        Start-Sleep -Milliseconds 100
        } 
        Write-Progress -Activity "Done!" -PercentComplete 0
        Start-Sleep -Seconds 1
        Write-Verbose "[i] Recieving data from job..."
        
        # If the fulloutput switch is passed on the command line, all properties for the found files will be displayed.
        # Else there will be an abreviated output of Host Name and FIle Location
        if ($fulloutput) {
            $output = Receive-Job -Id $jobs.Id | Select-Object -Property *
        }
        else {
            $output = Receive-Job -Id $jobs.Id | Select-Object -Property @{
                    Name="Host Name"
                    Expression={$_.PSComputername}
                }, 
                @{
                    Name="File Location" 
                    Expression={$_.Name}
                } | Format-Table
        }
        # Display the output
        $output | Format-List

        # Write the output to a file
        Try {
            Export-Clixml -InputObject $output -Path $outputpath
            Write-Verbose "[i] Output written to $outputpath"
        }
        Catch {
            Write-Host "[!] There was an error writing output to $outputpath" -ForegroundColor Red
        }
    }
    Finally {
        Write-Verbose "[i] Cleaning up Jobs..."
        Write-Progress -Activity "Cleaning up Jobs..." -PercentComplete 100
        Get-Job | Remove-Job -Force
        Write-Verbose "[i] Done!"
    }
}

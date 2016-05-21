Function Get-WMIFileHash {
# Assumes domain credentials

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
    
    $VerbosePreference = "Continue"

    Try {
        foreach ($computer in $computers) {     
            Write-Verbose "[$computer] Creating a new event log named 'HASHLOG'"
            Invoke-WmiMethod -ComputerName $computer -Class Win32_Process -Name Create -ArgumentList "cmd.exe /c powershell.exe New-EventLog -LogName HASHLOG -Source HASHLOG" | Out-Null
            Write-Verbose "[$computer] Writitng the file to execute."
            Invoke-WmiMethod -ComputerName $computer -Class Win32_Process -Name Create -ArgumentList "cmd.exe /c echo `$file=`"$hashfile`" >> $dohash" | Out-Null
            Invoke-WmiMethod -ComputerName $computer -Class Win32_Process -Name Create -ArgumentList "cmd.exe /c echo `$hash=Invoke-Expression `"certutil.exe `-hashfile `$file`" -ErrorAction SilentlyContinue >> $dohash" | Out-Null
            Invoke-WmiMethod -ComputerName $computer -Class Win32_Process -Name Create -ArgumentList "cmd.exe /c echo `$result=`$hash[1] ^| Out-String >> $dohash" | Out-Null
            Invoke-WmiMethod -ComputerName $computer -Class Win32_Process -Name Create -ArgumentList "cmd.exe /c echo if(`$result -match `"cannot`"){Write-EventLog -LogName HASHLOG -Source HASHLOG -EventId 0834 -EntryType Information -Message `"`$(Get-Date -Format u)|`$(`$env:computername)|`$(`$file)|Failed`"} >> $dohash" | Out-Null
            Invoke-WmiMethod -ComputerName $computer -Class Win32_Process -Name Create -ArgumentList "cmd.exe /c echo else{Write-EventLog -LogName HASHLOG -Source HASHLOG -EventId 0834 -EntryType Information -Message `"`$(Get-Date -Format u)|`$(`$env:computername)|`$(`$file)|`$(`$result.Replace(' ' ,''))`"} >> $dohash" | Out-Null
            Start-Sleep -Seconds 1
            Write-Verbose "[$computer] Setting the Exectuion Policy to 'Unrestricted'"
            Invoke-WmiMethod -ComputerName $computer -Class Win32_Process -Name Create -ArgumentList "cmd.exe /c powershell.exe Set-ExecutionPolicy Unrestricted -Force" | Out-Null
            Start-Sleep -Seconds 1
            Write-Verbose "[$computer] Running the file 'do-hash.ps1'"
            Invoke-WmiMethod -ComputerName $computer -Class Win32_Process -Name Create -ArgumentList "cmd.exe /c powershell.exe $dohash" | Out-Null
            Start-Sleep -Seconds 1
            Write-Verbose "[$computer] Retrieving the file hash..."
            #Start-Sleep -Seconds 5
            [string]$message = Get-WmiObject -ComputerName $computer -query "SELECT * FROM Win32_NTLogEvent WHERE (logfile='HASHLOG' and SourceName='HASHLOG')" | Select-Object -ExpandProperty Message
            $i=1
            While(($message.Length -eq 0) -and ($i -lt 10)) {
                [string]$message = Get-WmiObject -ComputerName $computer -query "SELECT * FROM Win32_NTLogEvent WHERE (logfile='HASHLOG' and SourceName='HASHLOG')" | Select-Object -ExpandProperty Message
                Write-Verbose "[$computer] Attempt #$i of 10..."
                $i++
                Start-Sleep -Seconds 10
            }
            Write-Host $message -ForegroundColor Yellow
        }
    }
    Finally {
        Write-Verbose "[i] Cleaning up..."
        Invoke-WmiMethod -ComputerName $computers -Class Win32_Process -Name Create -ArgumentList "cmd.exe /c del /F $dohash" | Out-Null
        Start-Sleep -Seconds 1
        Write-Verbose "[i] File 'do-hash.ps1' removed from target system"
        Write-Verbose "[i] Retunring Execution Policy to 'Default'"
        Invoke-WmiMethod -ComputerName $computers -Class Win32_Process -Name Create -ArgumentList "cmd.exe /c powershell.exe Set-ExecutionPolicy Default -Force" | Out-Null
        Start-Sleep -Seconds 1
        Invoke-WmiMethod -ComputerName $computers -Class Win32_Process -Name Create -ArgumentList "cmd.exe /c powershell.exe Remove-EventLog HASHLOG" | Out-Null
        Write-Verbose "[i] Done"    
    }
}
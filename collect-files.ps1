function collect-files{             
    [CmdletBinding()]             
    param (             
        [parameter(
            Position=0,            
            Mandatory=$true,            
            ValueFromPipeline=$true,             
            ValueFromPipelineByPropertyName=$true)
        ]            
    [string]$path=".",
    [switch]$recursive             
    )
                 
    BEGIN{
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
            write-Host “[!] Caught an exception” -ForegroundColor Red
            write-Host “[!] Exception Type: $($_.Exception.GetType().FullName)” -ForegroundColor Red
            write-Host “[!] Exception Message: $($_.Exception.Message)” -ForegroundColor Red
            Break
        }
    }#begin             

    PROCESS{            
        Try{
            if($recursive){
                $files = Get-ChildItem -Path $path -Recurse -File -ErrorAction SilentlyContinue | Select -ExpandProperty FullName
            }
            else{
                $files = Get-ChildItem -Path $path -File -ErrorAction SilentlyContinue | Select -ExpandProperty FullName
            }
        }
        Catch [Exception]{
            write-Host “[!] Caught an exception” -ForegroundColor Red
            write-Host “[!] Exception Type: $($_.Exception.GetType().FullName)” -ForegroundColor Red
            write-Host “[!] Exception Message: $($_.Exception.Message)” -ForegroundColor Red
            Break
        }
           
    }#process             

    END{
            Write-Host "[!]" $files.Count "files to Hash" -ForegroundColor Yellow
            foreach ($file in $files) {
                $position = $files.Count - $files.IndexOf($file)
                Write-Progress -Activity “Hashing all the files. $position Left” -status “Hashing: $file” -percentComplete ($files.IndexOf($file) / $files.count*100)
                if((Get-Item $file).length -lt 10mb){
                    Get-FileHash -Algorithm MD5 $file -ErrorAction SilentlyContinue | Out-Null
                }
                else{
                    Write-Host "[!] File is greater than 10MB, skipping for performance:" $file -ForegroundColor Yellow
                }
            }
            Write-Progress -Activity “Hashing all the files.” -status “Complete” -PercentComplete 100
            Start-Sleep -Seconds 3
            Write-Host "[#] All Done." -ForegroundColor Green
    }#end            
            
}
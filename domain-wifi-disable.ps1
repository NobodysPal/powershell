function domain-wifi-disable{             
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
        $ErrorActionPreference = "Stop"
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
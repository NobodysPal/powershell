$scriptblock = { 
                   Get-ChildItem
                   Start-Sleep -Seconds 5
               }
function Do-Async{
    Start-Job -ScriptBlock $scriptblock
    $prorgess = 1
    for ($prorgess -le 100; $prorgess++) {
        $status = (Get-Job).childjobs | Select -ExpandProperty State    
        if ($prorgess -eq 101) {
            $prorgess = 1
            if ($status -eq "Completed") {
                Get-Job | Remove-Job
                Write-Progress -Activity "All Done!" -PercentComplete 100
                Start-Sleep -Seconds 2
                break
            }
        }
        Write-Progress -Activity "Loading" -PercentComplete $prorgess
        $progress++
        Start-Sleep -Milliseconds 10
    }
}
Do-Async

Function Get-WeatherBot {
    param(
          [string]$location,
          [switch]$verbose
         )
    $temp,$condition,$alerts,$arr,$url,$result,$speak = $null
    if($verbose) {
        $VerbosePreference="Continue"
    }
    Try {
        Add-Type -AssemblyName System.speech -ErrorAction SilentlyContinue
        Try {
            $speak=new-object System.Speech.Synthesis.SpeechSynthesizer
            Write-Verbose $location
            $speak.Speak("Checking the weather near $location")
            $url = "https://www.bing.com/search?q=weather $location"
            $result = Invoke-WebRequest $url
            $location = $result.AllElements | Where Class -eq "b_focusLabel b_promoteText" | Select -First 1 -ExpandProperty innerText
            Write-Verbose "Returned location: $location"
            $temp = $result.AllElements | Where Class -eq "wtr_crt_tmp" | Select -First 1 -ExpandProperty innerText
            Write-Verbose $temp
            $condition = $result.AllElements | Where Class -eq "wtr_crt_cndtn" | Select -First 1 -ExpandProperty innerText
            Write-Verbose $condition
            if($temp -and $condition) {
                Write-Verbose "Inside the temp/conditions IF statement"
                if($alerts = $result.AllElements | Where Class -eq "wtr_alrt" | Select -First 1 -ExpandProperty innerText) {
                    Write-Verbose "Inside alerts IF statement"
                    $arr = ($alerts -split "-").Trim(' ')
                    $speak.Speak("There is a $($arr[1]) $($arr[2]) $($arr[0]) for this area.")    
                }
                $speak.Speak("The current conditions in $location are $condition and $temp degrees fahrenheit")
                $speak.Dispose() 
            }
            else {
                $speak.Speak("I could not find that location.")
                $speak.Dispose()
            }
        }
        Catch {
            Write-Verbose "In the Catch Block"
            $speak.Speak("I could not find that location.")
            $speak.Dispose()
        }
    }
    Catch {
        Write-Host "Error: Could not load the Voice Synethesizer." -ForegroundColor Red
        Write-Host $Error -ForegroundColor Red
    }
}

Get-WeatherBot -location "San Antonio" -verbose

# Example useage
# Get-WeatherBot -location "San Antonio" 
# Get-WeatherBot -location "San Antonio Texas" -verbose
# Get-WeatherBot -location "90210"
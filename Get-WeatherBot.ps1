<#
.SYNOPSIS
  Speaks the weather

.DESCRIPTION
  Pulls the weather from NOAA and speaks it aloud

.TODO
  (1) Use NOAA SOAP API
  
.NOTES
  Version:        1.0
  Author:         Jeff Pierdomenico
  Creation Date:  14 August 2016
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

Function Get-WeatherBot {
    param(
          [string]$city,
          [string]$state,
          [string]$zip,
          [switch]$verbose
         )
    $location,$temp,$condition,$forecast,$alerts,$arr,$url,$result,$speak = $null
    $weather = New-Object -TypeName PsObject -Property @{
        Condition = $null
        Temprature = $null
        Humidity = $null
        Wind = $null
        HeatIndex = $null
        Forecast = $null
        }
    
    # For those who verbose
    if($verbose) {
        $VerbosePreference="Continue"
    }

    $ascii = "DQAKACAAIAAgAF8AXwBfAF8AXwAgACAAIAAgACAAIABfACAAIAAgACAAIAAgACAAXwBfACAAIAAg
              ACAAIAAgACAAIAAgACAAXwBfACAAIAAgACAAIAAgACAAIABfACAAIAAgAF8AIAAgACAAIAAgACAA
              IAAgACAAIAAgACAAIAAgACAAXwBfAF8AXwAgACAAIAAgACAAIAAgACAAXwAgACAAIAANAAoAIAAg
              AC8AIABfAF8AXwBfAHwAIAAgACAAIAB8ACAAfAAgACAAIAAgACAAIABcACAAXAAgACAAIAAgACAA
              IAAgACAALwAgAC8AIAAgACAAIAAgACAAIAB8ACAAfAAgAHwAIAB8ACAAIAAgACAAIAAgACAAIAAg
              ACAAIAAgACAAfAAgACAAXwAgAFwAIAAgACAAIAAgACAAfAAgAHwAIAAgAA0ACgAgAHwAIAB8ACAA
              IABfAF8AIAAgAF8AXwBfAHwAIAB8AF8AIABfAF8AXwBfAF8AXAAgAFwAIAAgAC8AXAAgACAALwAg
              AC8AXwBfACAAIABfAF8AIABfAHwAIAB8AF8AfAAgAHwAXwBfACAAIAAgAF8AXwBfACAAXwAgAF8A
              XwB8ACAAfABfACkAIAB8ACAAXwBfAF8AIAB8ACAAfABfACAADQAKACAAfAAgAHwAIAB8AF8AIAB8
              AC8AIABfACAAXAAgAF8AXwB8AF8AXwBfAF8AXwBfAFwAIABcAC8AIAAgAFwALwAgAC8AIABfACAA
              XAAvACAAXwAgAHwAIABfAF8AfAAgACcAXwAgAFwAIAAvACAAXwAgAFwAIAAnAF8AXwB8ACAAIABf
              ACAAPAAgAC8AIABfACAAXAB8ACAAXwBfAHwADQAKACAAfAAgAHwAXwBfAHwAIAB8ACAAIABfAF8A
              LwAgAHwAXwAgACAAIAAgACAAIAAgACAAXAAgACAALwBcACAAIAAvACAAIABfAF8ALwAgACgAXwB8
              ACAAfAAgAHwAXwB8ACAAfAAgAHwAIAB8ACAAIABfAF8ALwAgAHwAIAAgAHwAIAB8AF8AKQAgAHwA
              IAAoAF8AKQAgAHwAIAB8AF8AIAANAAoAIAAgAFwAXwBfAF8AXwBfAHwAXABfAF8AXwB8AFwAXwBf
              AHwAIAAgACAAIAAgACAAIAAgAFwALwAgACAAXAAvACAAXABfAF8AXwB8AFwAXwBfACwAXwB8AFwA
              XwBfAHwAXwB8ACAAfABfAHwAXABfAF8AXwB8AF8AfAAgACAAfABfAF8AXwBfAC8AIABcAF8AXwBf
              AC8AIABcAF8AXwB8AA0ACgAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAA
              IAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAg
              ACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAA
              IAAgACAADQAKACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAg
              ACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAA
              IAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAA="

    # Writes Header information
    $header = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($ascii))
    Write-Host $header -ForegroundColor DarkGray
    Write-Host "          Author: Jeff Pierdomenico  Version: 1.0BETA  Date: 14 Aug 2016 `n" -ForegroundColor DarkGray

    Try {
        
        # Loading all the voice sysnthesis
        Add-Type -AssemblyName System.speech -ErrorAction SilentlyContinue
        $speak=new-object System.Speech.Synthesis.SpeechSynthesizer
        
        # Uses this method is using the zipcode
        if ($zip) {
            Write-Verbose "Looking up the weather in $zip"
            #$speak.Speak("Checking the weather near $zip")
            $url = "http://forecast.weather.gov/zipcity.php?inputstring=$zip"
            $result = Invoke-WebRequest $url

        # Uses this method is using the city and state
        if ($city -and $state) {
            Write-Verbose "Looking up the weather in $city"
            #$speak.Speak("Checking the weather near $city")
            $url = "http://forecast.weather.gov/MapClick.php?CityName=$city&state=$state"
            $result = Invoke-WebRequest $url
            
        }

        # Parses through the response
        $condition = ($result.ParsedHtml.getElementById(‘current-conditions-body’)).innerText #| Where{ $_.className -eq ‘myforecast-current’ } ).innerText
        $condition = $condition | Where-Object { $_ } | Select -Unique
        $condition = $condition.Split("`n")

        # Returns the found location
        $location = ($result.ParsedHtml.getElementById(‘seven-day-forecast’).getElementsByClassName('panel-title')) | Select-Object -ExpandProperty InnerText        }
        #$location = $location -split " "
        #$location = $location[0]

        # Gets the forecast
        $forecast = ($result.ParsedHtml.body.getElementsByTagName('div') | Where {$_.getAttributeNode('class').Value -eq 'col-sm-10 forecast-text'} ).innerText | select -First 1
        
        # Creates the weather object
        $weather.Condition = $condition[1]
        $weather.Temprature = $condition | % {$_} | Select-String -SimpleMatch "°F" | Select -First 1
        $weather.Humidity = $condition | % {$_} | Select-String -SimpleMatch "Humidity" | Select -First 1
        $weather.Wind = $condition | % {$_} | Select-String -SimpleMatch "MPH" | Select -First 1
        $weather.HeatIndex = $condition | % {$_} | Select-String -SimpleMatch "Index" | Select -First 1
        $weather.Forecast = $forecast
        $weather
        
        $speak.Speak("Checking the weather near $location")
        if ($weather.Condition) {
            $speak.Speak("The current conditions are " + $weather.Condition.ToString())
        }
        if ($weather.Temprature) {
            $speak.Speak("The temprature is " + $weather.Temprature.ToString())
        }
        if ($weather.Forecast) {
            $speak.Speak("Forcast for " + $weather.Forecast.ToString())
        }

    }
    Catch {
        Write-Host "Error: Could not load the Voice Synethesizer." -ForegroundColor Red
        Write-Host $Error -ForegroundColor Red
    }
    Finally {
        $speak.Dispose()
    }
}
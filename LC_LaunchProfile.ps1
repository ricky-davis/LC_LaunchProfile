# PowerShell script to launch Lethal Company with specific arguments
Add-Type -AssemblyName System.Windows.Forms

$configFilePath = Join-Path $PSScriptRoot "config.json"

function LoadConfig() {
    if (Test-Path $configFilePath) {
        return Get-Content $configFilePath | ConvertFrom-Json
    } else {
        $defaultConfig = @{
            "exePath" = 'C:\Program Files (x86)\Steam\steamapps\common\Lethal Company\Lethal Company.exe'
            "profileDirectory" = "$($env:APPDATA)\r2modmanPlus-local\LethalCompany\profiles"
            "monitor" = 0
            "selectedProfile" = ""
            "windowCount" = 1
            "windowSize" = 1
        }
        $defaultConfig | ConvertTo-Json | Set-Content $configFilePath
        return $defaultConfig
    }
}

function SaveConfig($config) {
    $config | ConvertTo-Json | Set-Content $configFilePath
}

# Load existing config or create default
$config = LoadConfig



# Modify SelectProfile function
function SelectProfile() {
    $childDirs = Get-ChildItem -Path $config.profileDirectory -Directory
    $defaultProfileIndex = $childDirs.Name.IndexOf($config.selectedProfile) + 1

    for ($i = 0; $i -lt $childDirs.Count; $i++) {
        Write-Host "$($i+1): $($childDirs[$i].Name)"
    }

    Write-Host -ForegroundColor Yellow -Nonewline "Select a profile ($($config.selectedProfile)): "
    $selection = Read-Host
    
    if ([string]::IsNullOrWhiteSpace($selection)) {
        $selection = $defaultProfileIndex
    }

    $selectedDir = $childDirs[$selection - 1]

    if ($selectedDir -and (Test-Path $selectedDir.FullName)) {
        return $selectedDir.Name
    } else {
        Write-Host -ForegroundColor Red "Invalid selection. Please try again."
        SelectProfile $profileDir
    }
}

# Modify SelectConcurrentWindows function
function SelectConcurrentWindows() {

    Write-Host -ForegroundColor Yellow -Nonewline "How many copies of the game do you want to launch? ($($config.windowCount)): "
    $selection = Read-Host

    if ([string]::IsNullOrWhiteSpace($selection)) {
        $selection = $config.windowCount
    }

    if ([int]$selection -in 1..4) {
        return $selection
    } else {
        Write-Host -ForegroundColor Red "Invalid selection. Please try again."
        SelectConcurrentWindows
    }
}

# Modify SelectWindowSize function
function SelectWindowSize() {
    $sizeSelections = @(1.0, 0.75, 0.5, 0.25)
    $defaultProfileIndex = $sizeSelections.IndexOf([double]$config.windowSize) + 1

    for ($i = 0; $i -lt $sizeSelections.Count; $i++) {
        Write-Host "$($i+1): $([int]($sizeSelections[$i]*100))%"
    }

    Write-Host -ForegroundColor Yellow -NoNewline "How big do you want the game windows compared to your screen ($([int]($config.windowSize*100))%): "
    $selection = Read-Host

    if ([string]::IsNullOrWhiteSpace($selection)) {
        $selection = $defaultProfileIndex
    }
    $selectedSize = $sizeSelections[$selection - 1]

    if ( $selectedSize ) {
        return $selectedSize
    } else {
        Write-Host -ForegroundColor Red "Invalid selection. Please try again."
        SelectWindowSize
    }
}


# Main script execution
$config.selectedProfile = SelectProfile
$config.windowCount = SelectConcurrentWindows
$config.windowSize = SelectWindowSize
Write-Host -ForegroundColor Green $config.selectedProfile
Write-Host -ForegroundColor Green $config.windowCount
Write-Host -ForegroundColor Green "$($config.windowSize*100)%"

SaveConfig $config


$doorstopEnable = '--doorstop-enable true'
$fullPath =[IO.Path]::Combine($config.profileDirectory, $config.selectedProfile, "BepInEx\core\BepInEx.Preloader.dll")
Write-Host $fullPath


$doorstopTarget = "--doorstop-target `"$fullPath`""
$monitor = '-monitor ' + $config.monitor
$fullscreen = '--screen-fullscreen 0'

# Getting screen resolution
$ScreenWidth = [System.Windows.Forms.Screen]::AllScreens[0].Bounds.Width
$ScreenHeight = [System.Windows.Forms.Screen]::AllScreens[0].Bounds.Height

# Calculate window size (1/4 of the screen size)
$WindowWidth = [Math]::Floor($ScreenWidth * $config.windowSize)
$WindowHeight = [Math]::Floor($ScreenHeight * $config.windowSize)

$height = '-screen-height ' + $WindowHeight
$width = '-screen-width ' + $WindowWidth

foreach ($i in 1..$config.windowCount){
    Write-Host "Starting game: $i"
    $process = Start-Process $config.exePath -ArgumentList $doorstopEnable, $doorstopTarget, $monitor, $fullscreen, $height, $width
    Start-Sleep -Milliseconds 500
}

Read-Host
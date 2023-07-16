$windowIndex = 0
foreach($line in Get-Content "bot-users.txt") {
    if($line -match "--END--") {
        break;
    }

    $username = $line.Split("-")[0].Trim();
    Write-Host "Starting user: $username"
    Start-Job -ScriptBlock {
        $rowCount = 4
        $columnCount = 4

        $screenIndex = [math]::Floor($using:windowIndex / ($columnCount * $rowCount)) + 1
        $windowIndex = $using:windowIndex % ($columnCount * $rowCount)

        Add-Type -AssemblyName System.Windows.Forms
        $screen = [System.Windows.Forms.Screen]::AllScreens | Select-Object -Skip $screenIndex | Select-Object -First 1

        $windowWidth = $screen.Bounds.Width / $columnCount
        $windowHeight = $screen.Bounds.Height / $rowCount
        .\scripts\launsh.ps1 `
            -SdkPath ..\AIRSDK_Windows\ `
            -bot 1 `
            -profileId "bot-$($using:windowIndex)" `
            -disable3dRendering 1 `
            -WindowPosition "$($screen.Bounds.x + $windowWidth * ($windowIndex % $columnCount)):$($screen.Bounds.y +[math]::Floor($windowIndex / $rowCount) * $windowHeight)" `
            -WindowSuffix "[$using:username]" `
            -Password T2jHn8LC86Pq `
            -Username $using:username
    }
    
    $windowIndex += 1
}
param(
  [Parameter(Mandatory = $true)] [string] $SdkPath,
  [string] $loader = './build/chainloader.swf',
  [string] $serverIp = '127.0.0.1:1234',
  [string] $username,
  [string] $password,
  [bool] $disable3dRendering,
  [bool] $bot = $False,
  [string] $windowPosition,
  [string] $profileId,
  [string] $windowSuffix
)

if ( -Not $(Test-Path "$SdkPath\bin\adl64.exe")) {
    Write-Host "Missing adl64 at $SdkPath\bin\adl64.exe" -ForegroundColor Red
    return
}

# Edit launch parameters here
$parameters = @{
    "debug" = 1
    "showlog"= "*"
    "locale"= "en"
    "library"= "G:\git\repositories\protanki-patched\protanki-instance\230619_library_win.swf"
    "server"= "$serverIp"
    "resources"= "http://146.59.110.103"
    "auto-login" = if($username && $password) { "${username}:${password}" } else { "" }
    "disable-3d-rendering" = if($disable3dRendering) { "yes" } else { "no" }
    "control-server" = if($bot) { "yes" } else { "no" }
    "window-position" = $windowPosition
    "window-suffix" = $windowSuffix
};

$descriptionFile = New-TemporaryFile
$loaderPath = Resolve-Path $loader
Write-Host "$loaderPath, resolve at $(Split-Path -Parent $descriptionFile)"
Push-Location $(Split-Path -Parent $descriptionFile)
$loaderPath = $(Resolve-Path -Relative $loaderPath)
Pop-Location

if([System.IO.Path]::IsPathRooted($loaderPath)) {
    Write-Host "Temp dir is on another drive. Copying loader."
    $copiedLoader = "$(New-TemporaryFile).swf"
    [System.IO.File]::Copy($loader, $copiedLoader, $true);
    $loaderPath = "$(Split-Path -Leaf $copiedLoader)"
}

$applicationTemplate = Get-Content ".\application-template.xml"
$appIdSuffix = if($profileId -ne "") { $profileId } elseif($username -ne "") { $username } else { "default" }
Set-Content $descriptionFile $applicationTemplate.Replace(
    "%%content%%",
    $($parameters.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" } | Join-String -Separator "&amp;")
).Replace(
    "%%loader%%",
    $loaderPath
).Replace(
    "%%app-id%%",
    "protanki-$appIdSuffix"
).Replace(
    "%%window-suffix%%",
    $(if($windowSuffix -eq "") { "[BotLoaded]" } else { $windowSuffix })
)

Write-Host "Running application ($loaderPath) with description file: $descriptionFile"
&"$SdkPath\bin\adl64.exe" "$descriptionFile"
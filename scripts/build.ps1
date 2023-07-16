param(
  [Parameter(Mandatory = $true)] [string] $SdkPath,
  [string] $OutputFile = './build/chainloader.swf',
  [bool] $ReleaseBuild = $false
)

if(!(Get-Command "java" -ErrorAction SilentlyContinue)) {
  Write-Host "[Build] Unable to find java executable" -ForegroundColor Red
  return
}

$ResolvedOutputFile = Join-Path (Resolve-Path .) $OutputFile

Write-Host "[Build] Building client chainloader..." -ForegroundColor Yellow
Write-Host "[Build] Build options:" -ForegroundColor Green
Write-Host "[Build] - Java version: $(Get-Command "java" | Select-Object -ExpandProperty Version)" -ForegroundColor Green
Write-Host "[Build] - Adobe AIR SDK: $(Resolve-Path $SdkPath)" -ForegroundColor Green
Write-Host "[Build] - Debug information: $(if(!$ReleaseBuild) { "yes" } else { "no" })" -ForegroundColor Green
Write-Host "[Build] - Output file: $ResolvedOutputFile" -ForegroundColor Green
Write-Host "[Build] ===== COMPILER LOG BEGIN =====" -ForegroundColor Yellow

java `
  -Dflexlib="$SdkPath/frameworks" `
  -jar "$SdkPath/lib/mxmlc-cli.jar" `
  +configname=air `
  -swf-version 15 `
  -output "$ResolvedOutputFile" `
  -source-path "src/" `
  -default-size="1000,600" `
  -default-background-color="0xFF00FF" `
  "src/jp/assasans/protanki/client/chainloader/Main.as" `
  $(if(!$ReleaseBuild) { "-debug" })

Write-Host "[Build] ===== COMPILER LOG END =====" -ForegroundColor Yellow

if($LastExitCode -eq 0) {
  Write-Host "[Build] Build done!" -ForegroundColor Green
  Write-Host "[Build] Chainloader SWF: $ResolvedOutputFile" -ForegroundColor Green
} else {
  Write-Host "[Build] Build failed! See error message above." -ForegroundColor Red
}

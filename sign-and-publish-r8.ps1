#Requires -Version 5.1
<#
.SYNOPSIS
  Sign r8 Setup with Authenticode, verify, refresh private draft Release; optionally publish.
.EXAMPLE
  .\sign-and-publish-r8.ps1 -PfxPath D:\certs\yuanjing.pfx -PfxPassword '***'
.EXAMPLE
  .\sign-and-publish-r8.ps1 -CertThumbprint ABCDEF... -Publish
#>
param(
  [string]$PfxPath,
  [string]$PfxPassword,
  [string]$CertThumbprint,
  [string]$ExePath = 'D:\yuanjing-installer-build-20261006\r8\Yuanjing-Setup-0.2.2.124-r8-candidate.exe',
  [string]$Repo = 'zhouguida123-svg/yuanjing-desktop-releases',
  [string]$Tag = 'desktop-0.2.2.124-r8',
  [string]$TimestampUrl = 'http://timestamp.digicert.com',
  [switch]$Publish
)

$ErrorActionPreference = 'Stop'
$SignTool = 'C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\x86\signtool.exe'
if (-not (Test-Path $SignTool)) { throw "signtool missing: $SignTool" }
if (-not (Test-Path $ExePath)) { throw "exe missing: $ExePath" }

$prep = Split-Path -Parent $MyInvocation.MyCommand.Path
$signedCopy = Join-Path $prep 'Yuanjing-Setup-0.2.2.124-r8-signed.exe'

Write-Host "== copy =="
Copy-Item $ExePath $signedCopy -Force

Write-Host "== sign =="
if ($PfxPath) {
  if (-not (Test-Path $PfxPath)) { throw "pfx missing: $PfxPath" }
  if ([string]::IsNullOrEmpty($PfxPassword)) {
    $secure = Read-Host -AsSecureString 'PFX password'
    $BSTR = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    $PfxPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
  }
  & $SignTool sign /fd SHA256 /tr $TimestampUrl /td SHA256 /f $PfxPath /p $PfxPassword $signedCopy
  if ($LASTEXITCODE -ne 0) { throw "signtool sign failed: $LASTEXITCODE" }
} elseif ($CertThumbprint) {
  & $SignTool sign /fd SHA256 /tr $TimestampUrl /td SHA256 /sha1 $CertThumbprint $signedCopy
  if ($LASTEXITCODE -ne 0) { throw "signtool sign failed: $LASTEXITCODE" }
} else {
  throw 'Provide -PfxPath or -CertThumbprint'
}

Write-Host "== verify =="
& $SignTool verify /pa /v $signedCopy
if ($LASTEXITCODE -ne 0) { throw "signtool verify failed: $LASTEXITCODE" }

$hash = (Get-FileHash $signedCopy -Algorithm SHA256).Hash.ToLower()
$hash | Set-Content (Join-Path $prep 'Yuanjing-Setup-0.2.2.124-r8-signed.exe.sha256') -Encoding ascii
@"
# r8 signed
$hash  Yuanjing-Setup-0.2.2.124-r8-signed.exe
"@ | Set-Content (Join-Path $prep 'SHA256SUMS-signed.txt') -Encoding utf8

Write-Host "== upload draft assets =="
gh release upload $Tag --repo $Repo --clobber `
  $signedCopy `
  (Join-Path $prep 'Yuanjing-Setup-0.2.2.124-r8-signed.exe.sha256') `
  (Join-Path $prep 'SHA256SUMS-signed.txt')
if ($LASTEXITCODE -ne 0) { throw "gh release upload failed: $LASTEXITCODE" }

if ($Publish) {
  Write-Host "== publish release (undraft) =="
  gh release edit $Tag --repo $Repo --draft=false --title '源景工作台 0.2.2.124-r8'
  if ($LASTEXITCODE -ne 0) { throw "gh release edit failed: $LASTEXITCODE" }
  Write-Host "Published. Consider making repo public if downloads should be open."
} else {
  Write-Host "Signed + uploaded to DRAFT. Re-run with -Publish when ready for public."
}

Write-Host "OK sha256=$hash"
Write-Host "signed=$signedCopy"

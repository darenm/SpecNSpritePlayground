# Download the latest SpectrumNext image and roms for CSpect and expand it
Write-Host "Download and expand the CSpect image from ZXSpectrumNEXT" -ForegroundColor Green
Remove-Item $PSScriptRoot\*.zip 
Remove-Item $PSScriptRoot\*.rom
c:\windows\system32\curl -o $PSScriptRoot\cspect-next-2gb.zip http://www.zxspectrumnext.online/cspect/cspect-next-2gb.zip
Expand-Archive -force $PSScriptRoot\cspect-next-2gb.zip $PSScriptRoot
Remove-Item $PSScriptRoot\*.zip 
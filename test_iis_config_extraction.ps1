#############################################################
## Test the IIS config extraction script in different cases
#############################################################
$iisScript = ".\references\export-iis-config.ps1"
$filename = "$env:computername-IIS.json"
## CASE 1
## IIS roles are not installed
& $iisScript
if ($LASTEXITCODE -ne 1000){
    Write-Host "Return code 1000 was expected but $LASTEXITCODE was obtained!"
    Exit 1
}
## CASE 2
## IIS roles are installed
Install-WindowsFeature -name Web-Server -IncludeManagementTools
& $iisScript
if ($LASTEXITCODE -ne 0){
    Write-Host "Return code 0 was expected but $LASTEXITCODE was obtained!"
    Exit 2
}
$count = (Get-Content $filename | Select-String -Pattern '"InternalFunctionsInError": []').length
if ($count -ne 1){
    Write-Host "Some internal functioons meet an errors!"
    $content = Get-Content $filename
    Write-Host "JSON"
    Write-Host $content
    Exit 3
}
Exit 0
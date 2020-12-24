#############################################################
## Test the IIS config extraction script in different cases
#############################################################
$iisScript = ".\references\export-iis-config.ps1"
$filename = "$env:computername-IIS.json"
$outFile = ".\out.txt"
## CASE 1
## IIS roles are not installed
& $iisScript | Out-File -FilePath $outFile
$count = (Get-Content $outFile | Select-String -Pattern 'are not installed, extraction cancelled!').length
if ($count -ne 1){
    Write-Host "Output of the script is not the one expected:"
    $content = Get-Content $outFile
    Write-Host $content
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
    Write-Host "Some internal functions meet an errors!"
    $content = Get-Content $filename
    Write-Host "JSON"
    Write-Host $content
    Exit 3
}
Exit 0
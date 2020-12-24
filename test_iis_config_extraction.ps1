#############################################################
## Test the IIS config extraction script in different cases
#############################################################
$iisScript = ".\references\export-iis-config.ps1"
$filename = "$env:computername-IIS.json"
$outFile = ".\out.txt"
# Display the web roles installation state
Get-WindowsFeature | Where-Object {($_.name -eq "Web-Server") -or ($_.name -eq "Web-WebServer")}
# CASE 1
Uninstall-WindowsFeature -name Web-Server -IncludeManagementTools
# IIS roles are not installed
& $iisScript | Out-File -FilePath $outFile
$count = (Get-Content $outFile | Select-String -Pattern 'are not installed, extraction cancelled!').length
if ($count -ne 1){
    Write-Host "Output of the script is not the one expected:"
    $content = Get-Content $outFile
    Write-Host $content
    Exit 1
}
# CASE 2
# IIS roles are installed
Install-WindowsFeature -name Web-Server -IncludeManagementTools
& $iisScript
$count = (Get-Content $filename | Select-String -Pattern '"InternalFunctionsInError": []').length
if ($count -ne 1){
    Write-Host "Some internal functions meet an errors!"
    $content = Get-Content $filename
    Write-Host "JSON:"
    Write-Host $content
    Exit 2
}
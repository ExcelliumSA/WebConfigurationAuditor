#############################################################
## Test the IIS config extraction script in different cases
#############################################################
# NOTE:
# Case where IIS roles are not installed cannot be tested because roles cannot be removed 
# and IIS roles are installed by default on runnners
$iisScript = ".\references\export-iis-config.ps1"
$filename = "$env:computername-IIS.json"
$outFile = ".\out.txt"
# Display the web roles installation state
Get-WindowsFeature | Where-Object {($_.name -eq "Web-Server") -or ($_.name -eq "Web-WebServer")}
# CASE 1
# IIS roles are installed
& $iisScript | Out-File -FilePath $outFile
$count = (Get-Content $outFile | Select-String -Pattern 'Finished with 0 error').length
Write-Host "Found: $count"
if ($count -ne 1){
    Write-Host "Some internal functions meet an errors!"
    $content = Get-Content $filename
    Write-Host "JSON:"
    Write-Host $content
    Exit 1
}
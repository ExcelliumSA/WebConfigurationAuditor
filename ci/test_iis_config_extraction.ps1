#############################################################
## Test the IIS config extraction script in different cases
#############################################################
# NOTE:
# Case where IIS roles are not installed cannot be tested because roles cannot be removed 
# and IIS roles are installed by default on runnners
$iisScript = "..\references\export-iis-config.ps1"
$filename = "$env:computername-IIS.json"
# Display the web roles installation state
Get-WindowsFeature | Where-Object {($_.name -eq "Web-Server") -or ($_.name -eq "Web-WebServer")}
# Display IIS version
Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\InetStp\' | select setupstring
# CASE 1
# IIS roles are installed
& $iisScript
$count = (Get-Content $filename | Select-String -SimpleMatch -Pattern '"InternalFunctionsInError":[]').length
if ($count -ne 1){
    Write-Host "Some internal functions raise a error!"
    $content = Get-Content $filename
    Write-Host "JSON:"
    Write-Host $content
    Exit 1
}
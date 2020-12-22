<#
.SYNOPSIS
   Gather the information needed for WSCR to work.
.DESCRIPTION
   Execute different processing in order to extract and gather all the information required to perform a secure configuration review.
.EXAMPLE
   .\export-config.ps1
.INPUTS
   No input needed.
.OUTPUTS
   Generate a JSON file with this name "[HOSTNAME_UPPERCASE]-IIS.json".
.NOTES
   In order to increase the maintainability of the script, each extract is associated to a validation point of the CIS referential and 
   each validation point of the CIS referential is associated to a internal function dedicated to extract the data needed for this point.
   Each internal function dedicated generate a proper object.
   The main code block gather all the objects, generated by each internal functions, in a global object where each sub objects is
   identified by a key that is the CIS validation point identifier. To finish it convert this object ta JSON string that is saved 
	to a file.
#>

##############################
## INTERNAL FUNCTIONS BLOCK ##
##############################
# CIS document source: CIS_Microsoft_IIS_10_Benchmark_v1.1.1.pdf
# Every time it was possible PowerShell command was used otherwise the shell command was used for portability between IIS8 and IIS10.
# Script was developed on WIN2012 with IIS8.5 .
# When a custom lopp is used on a result object, it's because the "ConvertTo-Json" applied on the result object do not return the expected data.

#############
# SECTION 1 #
#############

# Internal function for the validation point 1.1
# CIS title "Ensure web content is on non-system partition"
function Export-DataPoint11{
   # See https://www.jonathanmedd.net/2014/01/adding-and-removing-items-from-a-powershell-array.html
	[System.Collections.ArrayList]$results = @()
	Get-Website | ForEach-Object -Process {$results.Add(@{Name=$_.name; PhysicalPath=$_.physicalPath})} | Out-Null
	return $results 
}

# Internal function for the validation point 1.2
# CIS title "Ensure 'host headers' are on all sites"
function Export-DataPoint12{
	[System.Collections.ArrayList]$results = @()
   Get-WebBinding -Port * | ForEach-Object -Process {$results.Add(@{Protocol=$_.protocol; BindingInformation=$_.bindingInformation; SSLFlags=$_.sslFlags})} | Out-Null
   return $results 
}

# Internal function for the validation point 1.3
# CIS title "Ensure 'directory browsing' is set to disabled"
function Export-DataPoint13{
   # Use the shell command here for portability between IIS8.5 and IIS10
   $results = c:\windows\system32\inetsrv\appcmd list config /section:directoryBrowse 
   return $results
}

# Internal function for the validation point 1.4
# CIS title "Ensure 'application pool identity' is configured for all application pools"
function Export-DataPoint14{
   $results = c:\windows\system32\inetsrv\appcmd list config /section:applicationPools
   return $results
}

# Internal function for the validation point 1.5
# CIS title "Ensure 'unique application pools' is set for sites"
function Export-DataPoint15{
   $results = Get-Website | Select-Object Name, applicationPool
   return $results
}

# Internal function for the validation point 1.6
# CIS title "Ensure 'application pool identity' is configured for anonymous user identity"
function Export-DataPoint16{
   [System.Collections.ArrayList]$results = @()
   Get-WebConfiguration system.webServer/security/authentication/anonymousAuthentication -Recurse | where {$_.enabled -eq $true} | ForEach-Object -Process {$results.Add(@{SectionPath=$_.SectionPath;PSPath=$_.PSPath;Location=$_.Location})} | Out-Null
   return $results
}

# Internal function for the validation point 1.7
# CIS title "Ensure WebDav feature is disabled"
function Export-DataPoint17{
   # Install state flag values:
   # 0 = Available
   # 1 = Installed
   [System.Collections.ArrayList]$results = @()
   Get-WindowsFeature Web-DAV-Publishing | ForEach-Object -Process {$results.Add(@{Name=$_.Name;InstallState=$_.InstallState})} | Out-Null
   return $results
}

#############
# SECTION 2 #
#############

# Internal function for the validation point 2.1
# CIS title "Ensure 'global authorization rule' is set to restrict access"
function Export-DataPoint21{
   [System.Collections.ArrayList]$results = @()
   Get-WebConfiguration -pspath 'IIS:\' -filter 'system.webServer/security/authorization' | ForEach-Object -Process {$results.Add(@{SectionPath=$_.SectionPath;PSPath=$_.PSPath;Location=$_.Location})} | Out-Null
   return $results
}

# Internal function for the validation point 2.2
# CIS title "Ensure access to sensitive site features is restricted to authenticated principals only"
function Export-DataPoint22{
   [System.Collections.ArrayList]$results = @()
   Get-WebConfiguration system.webServer/security/authentication/* -Recurse | Where-Object {$_.enabled -eq $true} | ForEach-Object -Process {$results.Add(@{SectionPath=$_.SectionPath;PSPath=$_.PSPath;Location=$_.Location})} | Out-Null
   return $results
}

# Internal function for the validation point 2.3
# CIS title "Ensure 'forms authentication' require SSL"
function Export-DataPoint23{
   # Apply the command for all defined sites
   [System.Collections.ArrayList]$results = @()
   Get-Website | ForEach-Object -Process {
      $cfgPath = 'MACHINE/WEBROOT/APPHOST/' + $_.Name
      $cfg = Get-WebConfigurationProperty -pspath $cfgPath -filter 'system.web/authentication/forms' -name 'requireSSL'
      $results.Add(@{SiteName=$_.Name;Property=$cfg.Name;Value=$cfg.Value})
   } | Out-Null
   return $results
}

# Internal function for the validation point 2.4
# CIS title "Ensure 'forms authentication' is set to use cookies"
function Export-DataPoint24{
   # Apply the command for all defined sites
   [System.Collections.ArrayList]$results = @()
   Get-Website | ForEach-Object -Process {
      $cfgPath = 'MACHINE/WEBROOT/APPHOST/' + $_.Name
      $cfg = Get-WebConfigurationProperty -pspath $cfgPath -filter 'system.web/authentication/forms' -name 'cookieless'
      $results.Add(@{SiteName=$_.Name;Property='cookieless';Value=$cfg.ToString()})
   } | Out-Null
   return $results
}

# Internal function for the validation point 2.5
# CIS title "Ensure 'cookie protection mode' is configured for forms authentication"
function Export-DataPoint25{
   # Apply the command for all defined sites
   [System.Collections.ArrayList]$results = @()
   Get-Website | ForEach-Object -Process {
      $cfgPath = 'MACHINE/WEBROOT/APPHOST/' + $_.Name
      $cfg = Get-WebConfigurationProperty -pspath $cfgPath -filter 'system.web/authentication/forms' -name 'protection'
      $results.Add(@{SiteName=$_.Name;Property='protection';Value=$cfg.ToString()})
   } | Out-Null
   return $results
}

# Internal function for the validation point 2.6
# CIS title "Ensure transport layer security for 'basic authentication' is configured"
function Export-DataPoint26{
   # Apply the command for all defined sites
   [System.Collections.ArrayList]$results = @()
   Get-Website | ForEach-Object -Process {
      $cfg = Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -location $_.Name -filter 'system.webServer/security/access' -name 'sslFlags'
      $sslEnabled = ($cfg.ToString() -eq 'Ssl')
      $results.Add(@{SiteName=$_.Name;Property='sslFlags';Value=$sslEnabled})
   } | Out-Null
   return $results
}

# Internal function for the validation point 2.7
# CIS title "Ensure 'passwordFormat' is not set to clear"
function Export-DataPoint27{
   # Apply the command for all defined sites
   [System.Collections.ArrayList]$results = @()
   Get-Website | ForEach-Object -Process {
      $cfgPath = 'MACHINE/WEBROOT/APPHOST/' + $_.Name
      $cfg = Get-WebConfigurationProperty -pspath $cfgPath -filter 'system.web/authentication/forms/credentials' -name 'passwordFormat'
      $results.Add(@{SiteName=$_.Name;Property='passwordFormat';Value=$cfg.ToString()})
   } | Out-Null
   return $results
}

# Internal function for the validation point 2.8
# CIS title "Ensure 'credentials' are not stored in configuration files"
function Export-DataPoint28{
   # Apply the command for all defined sites
   [System.Collections.ArrayList]$results = @()
   Get-Website | ForEach-Object -Process {
      $cfgPath = 'MACHINE/WEBROOT/APPHOST/' + $_.Name
      $cfg = Get-WebConfigurationProperty -pspath $cfgPath -filter 'system.web/authentication/forms/credentials' -name 'passwordFormat'
      $results.Add(@{SiteName=$_.Name;Property='passwordFormat';Value=$cfg.ToString()})
   } | Out-Null
   return $results
}

#############
# SECTION 3 #
#############

# Internal function for the validation point 3.1
# CIS title "Ensure 'deployment method retail' is set"
function Export-DataPoint31{
   # Apply the command for all defined sites
   [System.Collections.ArrayList]$results = @()
   Get-Website | ForEach-Object -Process {
      $cfgPath = 'MACHINE/WEBROOT/APPHOST/' + $_.Name
      $cfg = Get-WebConfigurationProperty -pspath $cfgPath -filter 'system.web/deployment' -name 'retail'
      $results.Add(@{SiteName=$_.Name;Property='retail';Value=$cfg.Value})
   } | Out-Null
   return $results 
}

# Internal function for the validation point 3.2
# CIS title "Ensure 'debug' is turned off"
function Export-DataPoint32{
   # Apply the command for all defined sites
   [System.Collections.ArrayList]$results = @()
   Get-Website | ForEach-Object -Process {
      $cfgPath = 'MACHINE/WEBROOT/APPHOST/' + $_.Name
      $cfg = Get-WebConfigurationProperty -pspath $cfgPath -filter 'system.web/compilation' -name 'debug'
      $results.Add(@{SiteName=$_.Name;Property='debug';Value=$cfg.Value})
   } | Out-Null
   return $results 
}

# Internal function for the validation point 3.3
# CIS title "Ensure custom error messages are not off"
function Export-DataPoint33{
   # Apply the command for all defined sites
   [System.Collections.ArrayList]$results = @()
   Get-Website | ForEach-Object -Process {
      $cfgPath = 'MACHINE/WEBROOT/APPHOST/' + $_.Name
      $cfg = Get-WebConfigurationProperty -pspath $cfgPath -filter 'system.web/customErrors' -name 'mode'
      $results.Add(@{SiteName=$_.Name;Property='mode';Value=$cfg.ToString()})
   } | Out-Null
   return $results 
}

# Internal function for the validation point 3.4
# CIS title "Ensure IIS HTTP detailed errors are hidden from displaying remotely"
function Export-DataPoint34{
   # Apply the command for all defined sites
   [System.Collections.ArrayList]$results = @()
   Get-Website | ForEach-Object -Process {
      $cfgPath = 'MACHINE/WEBROOT/APPHOST/' + $_.Name
      $cfg = Get-WebConfigurationProperty -pspath $cfgPath -filter 'system.webServer/httpErrors' -name 'errorMode'
      $results.Add(@{SiteName=$_.Name;Property='errorMode';Value=$cfg.ToString()})
   } | Out-Null
   return $results 
}

# Internal function for the validation point 3.5
# CIS title "Ensure ASP.NET stack tracing is not enabled"
function Export-DataPoint35{
   # Apply the command for all defined sites
   [System.Collections.ArrayList]$results = @()
   Get-Website | ForEach-Object -Process {
      $cfgPath = 'MACHINE/WEBROOT/APPHOST/' + $_.Name
      $cfg = Get-WebConfigurationProperty -pspath $cfgPath -filter 'system.web/trace' -name 'enabled'
      $results.Add(@{SiteName=$_.Name;Property='enabled';Value=$cfg.Value})
   } | Out-Null
   return $results 
}

# Internal function for the validation point 3.6
# CIS title "Ensure 'httpcookie' mode is configured for session state"
function Export-DataPoint36{
   # Apply the command for all defined sites
   [System.Collections.ArrayList]$results = @()
   Get-Website | ForEach-Object -Process {
      $cfgPath = 'MACHINE/WEBROOT/APPHOST/' + $_.Name
      $cfg = Get-WebConfigurationProperty -pspath $cfgPath -filter 'system.web/sessionState' -name 'mode'
      $results.Add(@{SiteName=$_.Name;Property='mode';Value=$cfg.ToString()})
   } | Out-Null
   return $results 
}

# Internal function for the validation point 3.7
# CIS title "Ensure 'cookies' are set with HttpOnly attribute"
function Export-DataPoint37{
   # Apply the command for all defined sites
   [System.Collections.ArrayList]$results = @()
   Get-Website | ForEach-Object -Process {
      $cfgPath = 'MACHINE/WEBROOT/APPHOST/' + $_.Name
      $cfg = Get-WebConfigurationProperty -pspath $cfgPath -filter 'system.web/httpCookies' -name 'httpOnlyCookies'
      $results.Add(@{SiteName=$_.Name;Property='httpOnlyCookies';Value=$cfg.Value})
   } | Out-Null
   return $results 
}

# Internal function for the validation points 3.8 and 3.9
# CIS title "Ensure 'MachineKey validation method - .Net 3.5' is configured" (3.8)
#           "Ensure 'MachineKey validation method - .Net 4.5' is configured" (3.9)
function Export-DataPoint3839{
   # Apply the command for all defined sites
   [System.Collections.ArrayList]$results = @()
   Get-Website | ForEach-Object -Process {
      $cfgPath = 'MACHINE/WEBROOT/APPHOST/' + $_.Name
      $cfgValidation = Get-WebConfigurationProperty -pspath $cfgPath -filter 'system.web/machineKey' -name 'validation'
      $cfgDecryption = Get-WebConfigurationProperty -pspath $cfgPath -filter 'system.web/machineKey' -name 'decryption'
      $results.Add(@{SiteName=$_.Name;ValidationAlgorithm=$cfgValidation.ToString();DecryptionAlgorithm=$cfgDecryption.Value})
   } | Out-Null
   return $results 
}

# Internal function for the validation point 3.10
# CIS title "Ensure global .NET trust level is configured"
function Export-DataPoint310{
   # Apply the command for all defined sites
   [System.Collections.ArrayList]$results = @()
   Get-Website | ForEach-Object -Process {
      $cfgPath = 'MACHINE/WEBROOT/APPHOST/' + $_.Name
      $cfg = Get-WebConfigurationProperty -pspath $cfgPath -filter 'system.web/trust' -name 'level'
      $results.Add(@{SiteName=$_.Name;Property='level';Value=$cfg.Value})
   } | Out-Null
   return $results    
}

# Internal function for the validation point 3.11
# CIS title "Ensure X-Powered-By Header is removed"
function Export-DataPoint311{
   # Apply the command for all defined sites
   [System.Collections.ArrayList]$results = @()
   Get-Website | ForEach-Object -Process {
      $cfgPath = 'MACHINE/WEBROOT/APPHOST/' + $_.Name
      $cfgFile = Get-WebConfigFile $cfgPath
      $xml = New-Object Xml 
      $xml.Load($cfgFile)
      $node = $xml.SelectSingleNode('/configuration/system.webServer/httpProtocol/customHeaders/add[@name="X-Powered-By"]/@value')
      if($node.Value){
         $results.Add(@{SiteName=$_.Name;Property='X-Powered-By';Action="Add";Value=$node.Value})
      }
      $node = $xml.SelectSingleNode('/configuration/system.webServer/httpProtocol/customHeaders/remove[@name="X-Powered-By"]')
      if($node){
         $results.Add(@{SiteName=$_.Name;Property='X-Powered-By';Action="Remove"})
      }      
   } | Out-Null
   return $results   
}

# Internal function for the validation point 3.12
# CIS title "Ensure Server Header is removed"
# See https://developercommunity.visualstudio.com/solutions/637265/view.html
function Export-DataPoint312{
   # Apply the command for all defined sites
   [System.Collections.ArrayList]$results = @()
   Get-Website | ForEach-Object -Process {
      $cfgPath = 'MACHINE/WEBROOT/APPHOST/' + $_.Name
      $cfgFile = Get-WebConfigFile $cfgPath
      $xml = New-Object Xml 
      $xml.Load($cfgFile)
      $node = $xml.SelectSingleNode('/configuration/system.webServer/security/requestFiltering/@removeServerHeader')
      $results.Add(@{SiteName=$_.Name;Property='removeServerHeader';Value=($node.Value -eq "true")})
   } | Out-Null
   return $results  
}

#############
# SECTION 4 #
#############

# Internal function for the validation point 4.1
# CIS title "Ensure 'maxAllowedContentLength' is configured"
function Export-DataPoint41{

}

#############################
## MAIN FUNCTIONS BLOCK   ##
#############################
Export-DataPoint312 | ConvertTo-Json 
<#
.SYNOPSIS
   Gather the information needed for WSCR to work.
.DESCRIPTION
   Execute different processing in order to extract and gather all the information required to perform a secure configuration review.
.EXAMPLE
   .\export-iis-config.ps1
.INPUTS
   No input needed.
.OUTPUTS
   Generate a JSON file with this name "[HOSTNAME]-IIS.json".
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
# All internal functions are independant and it is wanted (it explains why code is duplicated) in order to allow to add special processing for a point in case of need.

###########
# CONTEXT #
###########

# Internal function to extract some context data
# No required by the CIS
function Export-DataContext{
   [System.Collections.ArrayList]$results = @()
   $iisVersion = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\InetStp\' | select setupstring
   $psVersion = Get-Host | Select-Object Version
   $dotNetVersion = [System.Runtime.InteropServices.RuntimeEnvironment]::GetSystemVersion()
   $datetime = Get-Date -Format "dd/MM/yyyy HH:mm K"
   $siteCount = $(Get-Website | measure).count
   $results.Add(@{WebSiteCount=$siteCount;IISVersion=$iisVersion;PowerShellVersion=$psVersion;DotNetCurrentVersion=$dotNetVersion;ExtractionLocalDateTime=$datetime}) | Out-Null
   return $results
}

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
      $cfg = Get-WebConfigurationProperty -pspath $cfgPath -filter 'system.webServer/security/requestFiltering' -name 'removeServerHeader'
      $results.Add(@{SiteName=$_.Name;Property='removeServerHeader';Value=($cfg -eq "true")})
   } | Out-Null
   return $results    
}

#############
# SECTION 4 #
#############

# Internal function for the validation point 4.1
# CIS title "Ensure "maxAllowedContentLength' is configured"
function Export-DataPoint41{
   # Apply the command for all defined sites
   [System.Collections.ArrayList]$results = @()
   Get-Website | ForEach-Object -Process {
      $cfgPath = 'MACHINE/WEBROOT/APPHOST/' + $_.Name
      $cfg = Get-WebConfigurationProperty -pspath $cfgPath -filter 'system.webServer/security/requestFiltering/requestLimits' -name 'maxAllowedContentLength'
      $results.Add(@{SiteName=$_.Name;Property='maxAllowedContentLength';Value=$cfg.Value})
   } | Out-Null
   return $results 
}

# Internal function for the validation point 4.2
# CIS title "Ensure 'maxURL request filter' is configured"
function Export-DataPoint42{
   # Apply the command for all defined sites
   [System.Collections.ArrayList]$results = @()
   Get-Website | ForEach-Object -Process {
      $cfgPath = 'MACHINE/WEBROOT/APPHOST/' + $_.Name
      $cfg = Get-WebConfigurationProperty -pspath $cfgPath -filter 'system.webServer/security/requestFiltering/requestLimits' -name 'maxUrl'
      $results.Add(@{SiteName=$_.Name;Property='maxUrl';Value=$cfg.Value})
   } | Out-Null
   return $results    
}

# Internal function for the validation point 4.3
# CIS title "Ensure 'maxQueryString request filter' is configured"
function Export-DataPoint43{
   # Apply the command for all defined sites
   [System.Collections.ArrayList]$results = @()
   Get-Website | ForEach-Object -Process {
      $cfgPath = 'MACHINE/WEBROOT/APPHOST/' + $_.Name
      $cfg = Get-WebConfigurationProperty -pspath $cfgPath -filter 'system.webServer/security/requestFiltering/requestLimits' -name 'maxQueryString'
      $results.Add(@{SiteName=$_.Name;Property='maxQueryString';Value=$cfg.Value})
   } | Out-Null
   return $results    
}

# Internal function for the validation point 4.4
# CIS title "Ensure non-ASCII characters in URLs are not allowed"
function Export-DataPoint44{
   # Apply the command for all defined sites
   [System.Collections.ArrayList]$results = @()
   Get-Website | ForEach-Object -Process {
      $cfgPath = 'MACHINE/WEBROOT/APPHOST/' + $_.Name
      $cfg = Get-WebConfigurationProperty -pspath $cfgPath -filter 'system.webServer/security/requestFiltering' -name 'allowHighBitCharacters'
      $results.Add(@{SiteName=$_.Name;Property='allowHighBitCharacters';Value=$cfg.Value})
   } | Out-Null
   return $results  
}

# Internal function for the validation point 4.5
# CIS title "Ensure Double-Encoded requests will be rejected"
function Export-DataPoint45{
   # Apply the command for all defined sites
   [System.Collections.ArrayList]$results = @()
   Get-Website | ForEach-Object -Process {
      $cfgPath = 'MACHINE/WEBROOT/APPHOST/' + $_.Name
      $cfg = Get-WebConfigurationProperty -pspath $cfgPath -filter 'system.webServer/security/requestFiltering' -name 'allowDoubleEscaping'
      $results.Add(@{SiteName=$_.Name;Property='allowDoubleEscaping';Value=$cfg.Value})
   } | Out-Null
   return $results  
}

# Internal function for the validation point 4.6
# CIS title "Ensure 'HTTP Trace Method' is disabled"
# See https://docs.microsoft.com/en-us/iis/configuration/system.webserver/security/requestfiltering/verbs/add
function Export-DataPoint46{
   # Apply the command for all defined sites
   [System.Collections.ArrayList]$results = @()
   Get-Website | ForEach-Object -Process {
      $cfgPath = 'MACHINE/WEBROOT/APPHOST/' + $_.Name
      $cfgFile = Get-WebConfigFile $cfgPath
      $xml = New-Object Xml 
      $xml.Load($cfgFile)
      $node = $xml.SelectSingleNode('/configuration/system.webServer/security/requestFiltering/verbs/add[@verb="TRACE"]/@allowed')
      $results.Add(@{SiteName=$_.Name;Property='HTTP-TRACE';Disabled=($node -eq "false")})    
   } | Out-Null
   return $results   
}

# Internal function for the validation point 4.7
# CIS title "Ensure Unlisted File Extensions are not allowed"
function Export-DataPoint47{
   # Apply the command for all defined sites
   [System.Collections.ArrayList]$results = @()
   Get-Website | ForEach-Object -Process {
      $cfgPath = 'MACHINE/WEBROOT/APPHOST/' + $_.Name
      $cfg = Get-WebConfigurationProperty -pspath $cfgPath -filter 'system.webServer/security/requestFiltering/fileExtensions' -name 'allowUnlisted'
      $results.Add(@{SiteName=$_.Name;Property='allowUnlisted';Value=$cfg.Value})
   } | Out-Null
   return $results    
}

# Internal function for the validation point 4.8
# CIS title "Ensure Handler is not granted Write and Script/Execute"
function Export-DataPoint48{
   # Apply the command for all defined sites
   [System.Collections.ArrayList]$results = @()
   Get-Website | ForEach-Object -Process {
      $cfgPath = 'MACHINE/WEBROOT/APPHOST/' + $_.Name
      $cfg = Get-WebConfigurationProperty -pspath $cfgPath -filter 'system.webServer/handlers' -name 'accessPolicy'
      $results.Add(@{SiteName=$_.Name;Property='accessPolicy';Value=$cfg.ToString()})
   } | Out-Null
   return $results      
}

# Internal function for the validation point 4.9
# CIS title "Ensure 'notListedIsapisAllowed' is set to false"
function Export-DataPoint49{
   # Apply the command for all defined sites
   [System.Collections.ArrayList]$results = @()
   Get-Website | ForEach-Object -Process {
      $cfgPath = 'MACHINE/WEBROOT/APPHOST/' + $_.Name
      $cfg = Get-WebConfigurationProperty -pspath $cfgPath -filter 'system.webServer/security/isapiCgiRestriction' -name 'notListedIsapisAllowed'
      $results.Add(@{SiteName=$_.Name;Property='notListedIsapisAllowed';Value=$cfg.Value})
   } | Out-Null
   return $results    
}

# Internal function for the validation point 4.10
# CIS title "Ensure 'notListedCgisAllowed' is set to false"
function Export-DataPoint410{
   # Apply the command for all defined sites
   [System.Collections.ArrayList]$results = @()
   Get-Website | ForEach-Object -Process {
      $cfgPath = 'MACHINE/WEBROOT/APPHOST/' + $_.Name
      $cfg = Get-WebConfigurationProperty -pspath $cfgPath -filter 'system.webServer/security/isapiCgiRestriction' -name 'notListedCgisAllowed'
      $results.Add(@{SiteName=$_.Name;Property='notListedCgisAllowed';Value=$cfg.Value})
   } | Out-Null
   return $results    
}

# Internal function for the validation point 4.11
# CIS title "Ensure 'Dynamic IP Address Restrictions' is enabled"
function Export-DataPoint411{
   # Apply the command for all defined sites
   [System.Collections.ArrayList]$results = @()
   Get-Website | ForEach-Object -Process {
      $cfgPath = 'MACHINE/WEBROOT/APPHOST/' + $_.Name
      $cfgDenyByConcurrentRequestsEnabled = Get-WebConfigurationProperty -pspath $cfgPath -filter 'system.webServer/security/dynamicIpSecurity/denyByConcurrentRequests' -name 'enabled'
      $cfgDenyByConcurrentRequestsMaxConcurrentRequests = Get-WebConfigurationProperty -pspath $cfgPath -filter 'system.webServer/security/dynamicIpSecurity/denyByConcurrentRequests' -name 'maxConcurrentRequests'
      $results.Add(@{SiteName=$_.Name;Property='denyByConcurrentRequests';Enabled=$cfgDenyByConcurrentRequestsEnabled.Value;MaxConcurrentRequests=$cfgDenyByConcurrentRequestsMaxConcurrentRequests.Value})
   } | Out-Null
   return $results     
}

#############
# SECTION 5 #
#############

# Internal function for the validation point 5.1
# CIS title "Ensure Default IIS web log location is moved"
function Export-DataPoint51{
   # Apply the command for all defined sites
   [System.Collections.ArrayList]$results = @()
   Get-Website | ForEach-Object -Process {
      $cfgPath = 'MACHINE/WEBROOT/APPHOST/' + $_.Name
      $cfg = Get-WebConfigurationProperty -pspath $cfgPath -filter 'system.applicationHost/sites/siteDefaults/logFile' -name 'directory'
      $results.Add(@{SiteName=$_.Name;Property='directory';Value=$cfg.Value})
   } | Out-Null
   return $results    
}

# Internal function for the validation point 5.2
# CIS title "Ensure Advanced IIS logging is enabled"
# See https://gallery.technet.microsoft.com/office/Set-IIS-Log-Fields-via-ee9c19b3
function Export-DataPoint52{
   # Apply the command for all defined sites
   [System.Collections.ArrayList]$results = @()
   Get-Website | ForEach-Object -Process {
      $cfgPath = 'MACHINE/WEBROOT/APPHOST/' + $_.Name
      $cfg = Get-WebConfigurationProperty -pspath $cfgPath -filter 'system.applicationHost/sites/siteDefaults/logFile' -name '.'
      # Get log properties
      $properties = @{SiteName=$_.Name;Property='Log';Fields=$cfg.logExtFileFlags;Format=$cfg.logFormat;Target=$cfg.logTargetW3C;Enabled=$cfg.enabled;MaxLogLineLength=$cfg.maxLogLineLength;RotationPeriod=$cfg.period;TruncateSize=$cfg.truncateSize}
      # Get sample lines of the mot recent log to really see the fields used, only extract lines starting with "#Fields:"
      [System.Collections.ArrayList]$lines = @()
      $cfg = Get-WebConfigurationProperty -pspath $cfgPath -filter 'system.applicationHost/sites/siteDefaults/logFile' -name 'directory'
      Get-ChildItem -Path $cfg.Value -Include *.log -Recurse -File -ErrorAction silentlycontinue | sort LastWriteTime | select -last 1 | Get-Content | Select-String -Pattern '#Fields:' -AllMatches | ForEach-Object -Process {
         $lines.Add($_.Line)
      }
      $properties["LogFieldsSamples"] = $lines
      $results.Add($properties)
   } | Out-Null
   return $results 
}

# Internal function for the validation point 5.3
# CIS title "Ensure 'ETW Logging' is enabled"
function Export-DataPoint53{
   # Apply the command for all defined sites
   [System.Collections.ArrayList]$results = @()
   Get-Website | ForEach-Object -Process {
      $cfgPath = 'MACHINE/WEBROOT/APPHOST/' + $_.Name
      $cfg = Get-WebConfigurationProperty -pspath $cfgPath -filter 'system.applicationHost/sites/siteDefaults/logFile' -name '.'
      # Get log properties
      $properties = @{SiteName=$_.Name;Property='Log';Format=$cfg.logFormat;Target=$cfg.logTargetW3C;Enabled=$cfg.enabled;}
      $results.Add($properties)
   } | Out-Null
   return $results    
}

#############
# SECTION 6 #
#############

# Internal function for the validation point 6.1
# CIS title "Ensure FTP requests are encrypted"
function Export-DataPoint61{
   # Apply the command for all defined sites
   [System.Collections.ArrayList]$results = @()
   Get-Website | ForEach-Object -Process {
      $cfgPath = 'MACHINE/WEBROOT/APPHOST/' + $_.Name
      $cfgChannel = Get-WebConfigurationProperty -pspath $cfgPath -filter 'system.applicationHost/sites/siteDefaults/ftpServer/security/ssl' -name 'controlChannelPolicy'
      $cfgData = Get-WebConfigurationProperty -pspath $cfgPath -filter 'system.applicationHost/sites/siteDefaults/ftpServer/security/ssl' -name 'dataChannelPolicy'
      $properties = @{SiteName=$_.Name;ControlChannelPolicy=$cfgChannel.ToString();DataChannelPolicy=$cfgData.ToString()}
      $results.Add($properties)
   } | Out-Null
   return $results    
}

# Internal function for the validation point 6.2
# CIS title "Ensure FTP Logon attempt restrictions is enabled"
function Export-DataPoint62{
   # Apply the command for all defined sites
   [System.Collections.ArrayList]$results = @()
   Get-Website | ForEach-Object -Process {
      $cfgPath = 'MACHINE/WEBROOT/APPHOST/' + $_.Name
      $cfg = Get-WebConfigurationProperty -pspath $cfgPath -filter 'system.ftpServer/security/authentication/denyByFailure' -name 'enabled'
      $results.Add(@{SiteName=$_.Name;Property="denyByFailure";Enabled=$cfg.Value})
   } | Out-Null
   return $results     
}

#############
# SECTION 7 #
#############

# Internal function for the validation point 7.1
# CIS title "Ensure HSTS Header is set"
function Export-DataPoint71{
   # Apply the command for all defined sites
   [System.Collections.ArrayList]$results = @()
   Get-Website | ForEach-Object -Process {
      $cfgPath = 'MACHINE/WEBROOT/APPHOST/' + $_.Name
      $cfgFile = Get-WebConfigFile $cfgPath
      $xml = New-Object Xml 
      $xml.Load($cfgFile)
      $node = $xml.SelectSingleNode('/configuration/system.webServer/httpProtocol/customHeaders/add[@name="Strict-Transport-Security"]/@value')
      if($node.Value){
         $results.Add(@{SiteName=$_.Name;Property='Strict-Transport-Security';Status='Present';Value=$node.Value})
      }else{
         $results.Add(@{SiteName=$_.Name;Property='Strict-Transport-Security';Status='Missing';Value='NA'})
      }     
   } | Out-Null
   return $results     
}

# Internal function for the validation points 7.2 and 7.3 and 7.4 and 7.5 and 7.6
# CIS title "Ensure SSLv2 is Disabled"   (7.2)
#           "Ensure SSLv3 is Disabled"   (7.3)
#           "Ensure TLS 1.0 is Disabled" (7.4)
#           "Ensure TLS 1.1 is Disabled" (7.5)
#           "Ensure TLS 1.2 is Enabled"  (7.6)
function Export-DataPoint7273747576{
   [System.Collections.ArrayList]$results = @()
   $registryKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols'
   $protocols = @('SSL 2.0','SSL 3.0','TLS 1.0','TLS 1.1','TLS 1.2')
   $sides = @('Server','Client')
   $properties = @('Enabled','DisabledByDefault')
   foreach ($protocol in $protocols) {
      foreach ($side in  $sides) {
         $key = "$registryKey\$protocol\$side"
         foreach ($property in  $properties) {
            $value = Get-ItemProperty -path $key -name $property -ErrorAction silentlycontinue | Select-Object -ExpandProperty $property
            if ($value -ge 0){
               $results.Add(@{Protocol=$protocol;Property=$property;RegistryKey=$key;Status='Present';Value=$value}) | Out-Null
            }else{
               $results.Add(@{Protocol=$protocol;Property=$property;RegistryKey=$key;Status='Missing';Value='NA'}) | Out-Null
            }
         }
      }
   }
   return $results
}

# Internal function for the validation points 7.7 and 7.8 and 7.9 and 7.10 and 7.11
# CIS title "Ensure NULL Cipher Suites is Disabled"        (7.7)
#           "Ensure DES Cipher Suites is Disabled"         (7.8)
#           "Ensure RC4 Cipher Suites is Disabled"         (7.9)
#           "Ensure AES 128/128 Cipher Suite is Disabled"  (7.10)
#           "Ensure AES 256/256 Cipher Suite is Enabled"   (7.11)
function Export-DataPoint777879710711{
   [System.Collections.ArrayList]$results = @()
   $registryKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers'
   $ciphers = @('NULL', 'DES 56/56','RC4 40/128','RC4 56/128','RC4 64/128','RC4 128/128','AES 128/128','AES 256/256')
   $property = 'Enabled'
   foreach ($cipher in $ciphers) {
      $key = "$registryKey\$cipher" 
      $value = Get-ItemProperty -path $key -name $property -ErrorAction silentlycontinue | Select-Object -ExpandProperty $property
      if ($value -ge 0){
         $results.Add(@{Cipher=$cipher;Property=$property;RegistryKey=$key;Status='Present';Value=$value}) | Out-Null
      }else{
         $results.Add(@{Cipher=$cipher;Property=$property;RegistryKey=$key;Status='Missing';Value='NA'}) | Out-Null
      } 
   }
   return $results  
}

# Internal function for the validation point 7.12
# CIS title "Ensure NULL Cipher Suites is Disabled" (7.12)
function Export-DataPoint712{
   $registryKey = 'HKLM:\SOFTWARE\Policies\Microsoft\Cryptography\Configuration\SSL\00010002'
   $property = 'Functions'
   $value = Get-ItemProperty -path $registryKey -name $property -ErrorAction silentlycontinue | Select-Object -ExpandProperty $property
   if ($value -ge 0){
      $result = @{Property=$property;RegistryKey=$registryKey;Status='Present';Value=$value}
   }else{
      $result = @{Property=$property;RegistryKey=$registryKey;Status='Missing';Value='NA'}
   }
   return $result  
}

##########################
## MAIN FUNCTIONS BLOCK ##
##########################
# Verify that the machine have the IIS roles installed
Write-Host "[+] Verify the installed roles..."
$rolesCount=$(Get-WindowsFeature | Where-Object {($_. installstate -eq "Installed") -and (($_.name -eq "Web-Server") -or ($_.name -eq "Web-WebServer"))}).count
if($rolesCount -ne 2){
   Write-Host "The IIS roles 'Web-Server' and 'Web-WebServer' are not installed, extraction cancelled!"
   Exit 1
}
# Define the list extraction functions to call
$internalFunctions = @('Export-DataContext','Export-DataPoint11','Export-DataPoint12','Export-DataPoint13','Export-DataPoint14','Export-DataPoint15','Export-DataPoint16','Export-DataPoint17','Export-DataPoint21','Export-DataPoint22','Export-DataPoint23','Export-DataPoint24','Export-DataPoint25','Export-DataPoint26','Export-DataPoint27','Export-DataPoint28','Export-DataPoint31','Export-DataPoint32','Export-DataPoint33','Export-DataPoint34','Export-DataPoint35','Export-DataPoint36','Export-DataPoint37','Export-DataPoint3839','Export-DataPoint310','Export-DataPoint311','Export-DataPoint312','Export-DataPoint41','Export-DataPoint42','Export-DataPoint43','Export-DataPoint44','Export-DataPoint45','Export-DataPoint46','Export-DataPoint47','Export-DataPoint48','Export-DataPoint49','Export-DataPoint410','Export-DataPoint411','Export-DataPoint51','Export-DataPoint52','Export-DataPoint53','Export-DataPoint61','Export-DataPoint62','Export-DataPoint71','Export-DataPoint7273747576','Export-DataPoint777879710711','Export-DataPoint712')
# Gathering information
[System.Collections.ArrayList]$internalFunctionsInError = @()
$results = @{}
$internalFunctionsCount = $internalFunctions.Count
$i = 0
$errorCount = 0
foreach ($internalFunction in $internalFunctions) {
   $progress = ($i / $internalFunctionsCount) * 100 -as [int]
   Write-Host -NoNewline "`r[+] Gathering information: $progress%"
   try{
      $results[$internalFunction] = Invoke-Expression $internalFunction
   }
   catch{
      $results[$internalFunction] = $_
      $errorCount++
      $internalFunctionsInError.Add($internalFunction)
   }
   $i++;
}
$results["InternalFunctionsInError"] = $internalFunctionsInError
Write-Host "`r[+] Gathering information: Finished with $errorCount error(s)."
# Generate and save the JSON file
Write-Host '[+] Generate and save the JSON file...'
$filename = "$env:computername-IIS.json"
ConvertTo-Json $results -Depth 100 -Compress | Out-File -FilePath .\$filename -Encoding utf8 
Write-Host "[+] Content saved to file $filename."
$hash = Get-FileHash -Algorithm SHA256 .\$filename | Select-Object -ExpandProperty Hash
Write-Host "[+] File SHA256 hash:`n$hash"
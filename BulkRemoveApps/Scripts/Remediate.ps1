#For each app in the json file, it will try to uninstall it
foreach ($app in (Invoke-RestMethod -Uri "https://raw.githubusercontent.com/schenardie/IntuneTechSupportFiles/main/BulkRemoveApps/JSON/List.json" -Headers @{"Cache-Control"="no-cache"}).Application) {
    #Log the app name and version
    Write-host "Trying to remove $($app.Name) $($app.Version)" -ForegroundColor Green     
    #Switch to determine if the app is an msi or a program
    switch ($app.type) {
        msi {
            #If msi, get the fastpackagereference (ProductCode) and uninstall it using msiexec with quiet mode
            $FastPackageReference = (Get-Package -AllVersions -ProviderName msi | Where-Object { $_.Name -like $app.name -and $_.Version -like $app.version }).FastPackageReference 
            if ($FastPackageReference) { 
                #If more than one version is found, loop through them and uninstall them
                if ($FastPackageReference.Count -gt 1) { 
                    foreach ($FastPackageReference in $FastPackageReference) { 
                        Start-process -FilePath msiexec.exe -Wait -ArgumentList "/x $FastPackageReference /qn /norestart"
                    }       
                }
                else {
                   Start-process -FilePath msiexec.exe -Wait -ArgumentList "/x $FastPackageReference /qn /norestart"
                }
            } 
        }
        programs {
            #If program, get the uninstallstring and uninstall it using the silent argument
            if ($app.SilentArg) {
                $metadata = (Get-Package -AllVersions -ProviderName programs | Where-Object { $_.Name -like $app.name -and $_.Version -like $app.version }).metadata
                if ($metadata ) {
                    #If more than one version is found, loop through them and uninstall them
                    if ($metadata.Count -gt 1) { 
                        foreach ($metadata in $metadata) {
                            Start-process -FilePath ($($metadata['UninstallString']) -replace '(?<=\.exe).+', '' -replace '"', '') -ArgumentList "$($app.SilentArg)" -Wait
                        }
                    }					
                
                    else { 
                        Start-process -FilePath ($($metadata['UninstallString']) -replace '(?<=\.exe).+', '' -replace '"', '') -ArgumentList "$($app.SilentArg)" -Wait
                    }
                }
            }
                else {
                    #If no silent argument is passed, try to find a quiet uninstallstring and run it
                    $metadata = (Get-Package -AllVersions -ProviderName programs -ErrorAction SilentlyContinue | Where-Object { $_.Name -like $app.name -and $_.version -like $app.Version }).metadata          
                    if ($metadata ) { 
                        if ($metadata['QuietUninstallString'].Count -gt 1) { 
                            foreach ($metadata in $metadata) { 
                                Start-process -FilePath $metadata['QuietUninstallString']
                            }       
                        }
                        else { 
                            Start-process -FilePath $metadata['QuietUninstallString']
                        }

                    }
                    #If no quiet uninstallstring is found, log it
                    else { Write-Host "No silent argument passed and not quiet silent argument found for $($app.Name) $($app.Version)" -ForegroundColor Red }
                }
            } 
        } 
    }

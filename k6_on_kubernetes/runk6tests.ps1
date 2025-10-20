# Run k6 tets in kubernetes
param(
    [string] $testJSPath = ".\test_scripts\test.js",
    [string] $label = "k6-sample-testc",
    [string] $deploymentTemplateYamlPath = ".\deployment_templates\k6-deployment-template.yaml",
    [string] $outputFolder = ".\output",
    [string] $logfilepath = "$($label).log",
    [string] $deploymentYamlPath = "$($label)_deployment.yaml",
    [string] $configMapName = "$($label)-configmap",
    # flags
    [bool] $deleteartefacts = $true,
    [bool] $runk6 = $true
)
   

function EmptyOutputFolder([Parameter(Mandatory = $true)][string] $folderPath) {
    if (Test-Path -Path $folderPath) {
        Write-Host "Emptying output folder: $folderPath"
        Get-ChildItem -Path $folderPath -Recurse | Remove-Item -Force -Recurse
    }
    
}
function CreateDeploymentTemplateObject() {
    $fileName = Split-Path -Path $testJSPath -Leaf
    $parameters = [PSCustomObject]@{
        metadataname   = $label
        parallelism    = "1"
        configMapname  = $configMapName
        testjsfilepath = $fileName
        duration       = "5s"
        rate           = "100"
        prevu          = "10"
        maxuv          = "10"
        functionname   = "function1"
    }

    return $parameters
}
function CreateDeploymentYamlFromTemplate(
    [Parameter(Mandatory = $true)][string] $templatePath,
    [Parameter(Mandatory = $true)][string] $outputPath ,
    [Parameter(Mandatory = $true)][PSCustomObject]$parameters
) {

    write-host "Creating deployment yaml from template $templatePath to $outputPath"

    if (-not(Test-Path -path $templatePath)) {
        Write-Error "Template file $templatePath does not exist."
        return $false
    }
    write-host "Reading template content"
    $templateContent = Get-Content -Path $templatePath -Raw

    write-host "Replacing tokens in template"
    foreach ($key in $parameters.PSObject.Properties) {
        $placeholder = "%$($key.Name)%"
        $value = $key.Value
        $templateContent = $templateContent -replace [regex]::Escape($placeholder), $value
    }

    write-host "Checking for leftover tokens in template..." -NoNewline
    if ($templateContent -match "%[a-zA-Z0-9_]+%") {
        write-host "Error" -ForegroundColor Red
        Write-Error "Not all tokens were replaced in the template. Please check the parameters."
        return $false
    }
    else {
        write-host "Ok" -ForegroundColor Green
    }
    write-host "Writing deployment yaml to $outputPath" -ForegroundColor Green
    Set-Content -Path $outputPath -Value $templateContent

    return $true
}

#runme
function IsDockerRunning() {
    try {
        if ((docker ps 2>&1) -match '^(?!error)') {
            return $true
        }
        else {
            return $false
        }
    }
    catch {
        return $false
    }
}
function RemoveK6Containers(
    [Parameter(Mandatory = $true)][string] $configMapName,
    [Parameter(Mandatory = $true)][string] $deploymentYamlPath

) {
    if (test-path -path $deploymentYamlPath) {
        write-host "Removing existing k6 deployment defined in $deploymentYamlPath"
        kubectl delete -f $deploymentYamlPath | out-null 
    }
    else {
        write-host "Deployment yaml $deploymentYamlPath does not exist, skipping removal of existing k6 deployment"
    }

    write-host "Removing existing k6 configmap $configMapName if it exists"
    & kubectl get configmap $configMapName --output json 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        kubectl delete configmap $configMapName | out-null
        write-host "done" -ForegroundColor Green
        
        return $true
    }
    else {
        write-host "ConfigMap $configMapName does not exist, skipping removal." -ForegroundColor Green
        return $true
    }

}

function CreateK6ConfigMap(
    [Parameter(Mandatory = $true)] $filePath,
    [Parameter(Mandatory = $true)] $configMapName
) {
    write-host "Creating ConfigMap $configMapName from $filepath"
    if (-not(test-path -path $filePath)) {
        Write-Error "Test JS file $filePath does not exist."
        return $false
    }    
    # Check if the ConfigMap already exists
    & kubectl get configmap $configMapName --output json 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "ConfigMap $configMapName already exists. Skipping creation." -ForegroundColor Yellow
        return $true
    }

    try {
        # note we are using the relative filepath here to populate the configmap
        # but the configmap "key" is the filename only
        $resultJson = (& kubectl create configmap $configMapName --from-file=$filePath --output json 2>&1)
        $result = $resultJson | ConvertFrom-Json
        Write-Host "ConfigMap $configMapName created successfully." -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Problem creating ConfigMap $configMapName : $($_.Exception.Message)"
        return $false
    }

}

function StartK6Test(
    [parameter (Mandatory = $true)] $deploymentYamlPath
) {
    write-host "Starting k6 test from $deploymentYamlPath"

    if (-not(test-path -path $deploymentYamlPath)) {
        Write-Error "Deployment YAML file $deploymentYamlPath does not exist."
        return $false
    }
    
    $resultText = (kubectl apply -f $deploymentYamlPath --output "json" 2>&1)
    if (0 -eq $LASTEXITCODE) {
        Write-Host "k6 deployment applied successfully." -ForegroundColor Green
    }
    else {
        Write-Error "Problem applying k6  deployment: " $resultText
        return $false
    }
    
    $result = $resultText | ConvertFrom-Json
    write-host $result.status.stage -ForegroundColor Yellow
    
    return $True
}

function RemoveExistingLogs([Parameter(Mandatory = $true)] $logFilePath = "test.log") {
    if (Test-Path -Path $logFilePath) {
        Remove-Item -Path $logFilePath -Force
        Write-Host "Existing $logFilePath file removed." -ForegroundColor Yellow
    }
}

function WaitForPodsToComplete (
    [Parameter(Mandatory = $true)] $labelfilter
) {
    
    $lastPodStatus = ""
    Write-Host "Waiting for pods to complete..."
    while ($true) {
        $podInfo = (kubectl get pods $labelfilter --output "json" | convertfrom-json)
        $podStatuses = $podInfo.Items | ForEach-Object { $_.status.phase } | Select-Object -Unique

        write-host $podStatuses
       
        $allComplete = $true
        foreach ($podStatus in $podStatuses) {
            if ($podStatus -ne "Succeeded" -and $podStatus -ne "Failed") {
                Write-Host "Pod status is $podStatus. Waiting for completion..."
                $allComplete = $false
                Start-Sleep -Seconds 5
                break    
            }
            else {
                write-host "Pod status is $podStatus."
                $lastPodStatus = $podStatus
            }
        }
        
        if ($allComplete) {
            break
        }
    }
    return $lastPodStatus
}
function OutputInitializerPodLogs(
    [Parameter(Mandatory = $true)] $label = "k6"
) {
    $initPodName = "$($label)-initializer"
    write-host "Fetching logs from initializer pod $initPodName"
    $logs = kubectl logs -l job-name=$initPodName 
    write-host "Initializer pod logs: "  -ForegroundColor Yellow
    write-host $logs -ForegroundColor Yellow
}

function WaitForAndCollectLogs(
    [Parameter(Mandatory = $false)] $logFilePath = "test.log",
    [Parameter(Mandatory = $false)] $label = "k6"
) {
    RemoveExistingLogs -logFilePath $logFilePath
    $initPodName = "$($label)-initializer"

    write-host "Checking status of initializer pod $initPodName"
    $lastStatus = WaitForPodsToComplete -labelfilter "-l job-name=$initPodName"

    if ($lastStatus -ne "Succeeded") {
        write-host "Initializer pod $initPodName did not complete successfully. Last status: $lastStatus" -ForegroundColor Red
        OutputInitializerPodLogs -label $label
        return $false
    }

    # Wait for the k6 pod to complete
    Write-Host "Waiting for k6 'runner' pods to complete..."
    $podStatus = (kubectl get pods -l k6_cr=$label -l runner=true --output "json" | convertfrom-json )
    
    if (($null -eq $podStatus) -or ($podStatus.Items.Count -eq 0)) {
        Write-host  "No pods found with label k6_cr=$label and runner=true" -foregroundcolor Red
        write-host "Checking for initializer pod logs to find out whats wrong..." -ForegroundColor Yellow
        # fetch the initialize pod and get its logs
        Write-Host "Reading logs from initializer pod $initPodName"
        $logs = kubectl logs -l job-name=$initPodName 
        write-host "Initializer pod failed with the following logs: "  -ForegroundColor Red
        write-host $logs -ForegroundColor Red

        return $false
    }

    write-host "Found the following pods:"
    foreach ($pod in $podStatus.Items) {
        Write-Host "Pod: $($pod.metadata.name) - Status: $($pod.status.phase)"
    }

    
    $lastStatus = WaitForPodsToComplete -labelfilter "-l k6_cr=$label -l runner=true"
    if ($lastStatus -ne "Succeeded") {
        Write-Host "k6 'runner' pods did not complete successfully. Last status: $lastStatus" -ForegroundColor Red
        return $false
    }

    # Write-Host "Collecting logs from k6 'runner' pods..."
    # $logCollectionResult = kubectl logs -l k6_cr=$label -l runner=true | Out-File -FilePath $logFilePath -Encoding utf8

    return $true
}

if (-not (IsDockerRunning)) {
    Write-Host "Docker is not running. Please start Docker and try again."
    exit 1
}

$deploymentYamlPath = join-path -path $outputFolder -childpath $deploymentYamlPath

if ($deleteartefacts) {
    write-host "Deleting existing artefacts..." -ForegroundColor Yellow
    EmptyOutputFolder -folderPath $outputFolder
    $result = RemoveK6Containers -configMapName $configMapName -deploymentYamlPath $deploymentYamlPath
    
    write-host "Done" -ForegroundColor Green
}   

if ($runk6) {
    Write-Host "Starting k6 test run..." -ForegroundColor Yellow
    if (CreateK6ConfigMap -filePath $testJSPath -configMapName $configMapName) {
        $parameters = CreateDeploymentTemplateObject
    
        if (-not (CreateDeploymentYamlFromTemplate -templatePath $deploymentTemplateYamlPath -outputPath $deploymentYamlPath -parameters $parameters)) {
            write-host "failed to create deployment yaml, aborting" -foregroundcolor Red
            exit 1
        }

        if (-not (StartK6Test -deploymentYamlPath $deploymentYamlPath )) {
            write-host "failed to start k6 test, aborting" -foregroundcolor Red
            exit 1
        }

        if (WaitForAndCollectLogs -logFilePath $logfilepath -label $label) {
            Write-Host "k6 test completed and logs collected successfully." -ForegroundColor Green
            exit 0
        }
        else {
            write-host "There was a problem collecting  logs, aborting" -foregroundcolor Red
            exit 1
        }
    }
    else {
        Write-Host "failed to create configmap, aborting"
        exit 1
    }

}
else {
    Write-Host "runk6 flag is set to false, skipping k6 test run." -ForegroundColor Yellow
    exit 0
}

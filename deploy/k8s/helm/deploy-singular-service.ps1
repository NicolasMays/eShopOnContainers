Param(
    [parameter(Mandatory=$false)][string]$registry,
    [parameter(Mandatory=$false)][string]$dockerUser,
    [parameter(Mandatory=$false)][securestring]$dockerPassword,
    [parameter(Mandatory=$false)][string]$externalDns,
    [parameter(Mandatory=$false)][string]$appName="eshop",
    [parameter(Mandatory=$false)][bool]$deployInfrastructure=$true,
    [parameter(Mandatory=$false)][bool]$deployCharts=$true,
    [parameter(Mandatory=$false)][bool]$clean=$true,
    [parameter(Mandatory=$false)][string]$aksName="",
    [parameter(Mandatory=$false)][string]$aksRg="",
    [parameter(Mandatory=$false)][string]$imageTag="latest",
    [parameter(Mandatory=$false)][bool]$useLocalk8s=$false,
    [parameter(Mandatory=$false)][bool]$useMesh=$false,
    [parameter(Mandatory=$false)][string][ValidateSet('Always','IfNotPresent','Never', IgnoreCase=$false)]$imagePullPolicy="Always",
    [parameter(Mandatory=$false)][string][ValidateSet('prod','staging','none','custom', IgnoreCase=$false)]$sslSupport = "none",
    [parameter(Mandatory=$false)][string]$tlsSecretName = "eshop-tls-custom",
    [parameter(Mandatory=$false)][string]$chartsToDeploy="*",
    [parameter(Mandatory=$false)][string]$ingressMeshAnnotationsFile="ingress_values_linkerd.yaml"
    )

function Install-Chart  {
    Param([string]$chart,[string]$initialOptions, [bool]$customRegistry)
    $options=$initialOptions
    if ($sslEnabled) {
        $options = "$options --set ingress.tls[0].secretName=$tlsSecretName --set ingress.tls[0].hosts={$dns}"
        if ($sslSupport -ne "custom") {
            $options = "$options --set inf.tls.issuer=$sslIssuer"
        }
    }
    if ($customRegistry) {
        $options = "$options --set inf.registry.server=$registry --set inf.registry.login=$dockerUser --set inf.registry.pwd=$dockerPassword --set inf.registry.secretName=eshop-docker-scret"
    }
    if ($chart -ne "eshop-common" -or $customRegistry)  {       # eshop-common is ignored when no secret must be deployed   
        $command = "install $appName-$chart $options $chart"
        Write-Output "Helm Command: helm $command"
        Invoke-Expression 'cmd /c "helm $command"'
    }
}

$dns = $externalDns
$sslEnabled=$false
$sslIssuer=""

if ($sslSupport -eq "staging") {
    $sslEnabled=$true
    $tlsSecretName="eshop-letsencrypt-staging"
    $sslIssuer="letsencrypt-staging"
}
elseif ($sslSupport -eq "prod") {
    $sslEnabled=$true
    $tlsSecretName="eshop-letsencrypt-prod"
    $sslIssuer="letsencrypt-prod"
}
elseif ($sslSupport -eq "custom") {
    $sslEnabled=$true
}

$ingressValuesFile="ingress_values.yaml"

if ($useLocalk8s -eq $true) {
    $ingressValuesFile="ingress_values_dockerk8s.yaml"
    $dns="localhost"
}

if ($externalDns -eq "aks") {
    if  ([string]::IsNullOrEmpty($aksName) -or [string]::IsNullOrEmpty($aksRg)) {
        Write-Output "Error: When using -dns aks, MUST set -aksName and -aksRg too."
        exit 1
    }
    Write-Output "Getting DNS of AKS of AKS $aksName (in resource group $aksRg)..."
    $dns = $(az aks show -n $aksName  -g $aksRg --query addonProfiles.httpApplicationRouting.config.HTTPApplicationRoutingZoneName)
    if ([string]::IsNullOrEmpty($dns)) {
        Write-Output "Error getting DNS of AKS $aksName (in resource group $aksRg). Please ensure AKS has httpRouting enabled AND Azure CLI is logged & in version 2.0.37 or higher"
        exit 1
    }
    $dns = $dns -replace '[\"]'
    Write-Output "DNS base found is $dns. Will use $appName.$dns for the app!"
    $dns = "$appName.$dns"
}

# Initialization & check commands
if ([string]::IsNullOrEmpty($dns)) {
    Write-Output "No DNS specified. Ingress resources will be bound to public ip"
    if ($sslEnabled) {
        Write-Output "Can't bound SSL to public IP. DNS is mandatory when using TLS"
        exit 1
    }
}

if ($useLocalk8s -and $sslEnabled) {
    Write-Output "SSL can'be enabled on local K8s."
    exit 1
}



if ($clean) {
Write-Output "Chart filter: $chartsToDeploy"
    $listOfReleases=$(helm ls --filter $chartsToDeploy -q)
    if ([string]::IsNullOrEmpty($listOfReleases)) {
        Write-Output "No previous releases found!"
	}else{
        Write-Output "Releases to remove: $listOfReleases"
        Write-Output "Previous releases found"
        Write-Output "Cleaning previous helm releases..."
        helm uninstall $listOfReleases
        Write-Output "Previous releases deleted"
	}
}

$useCustomRegistry=$false

if (-not [string]::IsNullOrEmpty($registry)) {
    $useCustomRegistry=$true
    if ([string]::IsNullOrEmpty($dockerUser) -or [string]::IsNullOrEmpty($dockerPassword)) {
        Write-Output "Error: Must use -dockerUser AND -dockerPassword if specifying custom registry"
        exit 1
    }
}

Write-Output "Begin eShopOnContainers installation using Helm"

$infras = ("sql-data", "nosql-data", "rabbitmq", "keystore-data", "basket-data")
$charts = ("eshop-common", "basket-api","catalog-api", "identity-api", "mobileshoppingagg","ordering-api","ordering-backgroundtasks","ordering-signalrhub", "payment-api", "webmvc", "webshoppingagg", "webspa", "webstatus", "webhooks-api", "webhooks-web")
$gateways = ("apigwms", "apigwws")

if ($deployInfrastructure) {
    foreach ($infra in $infras) {
        Write-Output "Installing infrastructure: $infra"
        helm install "$appName-$infra" --values app.yaml --values inf.yaml --values $ingressValuesFile --set app.name=$appName --set inf.k8s.dns=$dns --set "ingress.hosts={$dns}" $infra
    }
}
else {
    Write-Output "eShopOnContainers infrastructure (bbdd, redis, ...) charts aren't installed (-deployCharts is false)"
}

Write-Output "Charts to Deploy $chartsToDeploy"
if ($deployCharts) {
    foreach ($chart in $charts) {
        if ($chartsToDeploy -eq "*" -or $chartsToDeploy.Contains($chart)) {
            Write-Output "Installing: $chart"
            Install-Chart -chart $chart -initialOptions "-f app.yaml --values inf.yaml -f $ingressValuesFile -f $ingressMeshAnnotationsFile --set app.name=$appName --set inf.k8s.dns=$dns --set ingress.hosts={$dns} --set image.tag=$imageTag --set image.pullPolicy=$imagePullPolicy --set inf.tls.enabled=$sslEnabled --set inf.mesh.enabled=$useMesh --set inf.k8s.local=$useLocalk8s" -customRegistry $useCustomRegistry
        }
    }

    foreach ($chart in $gateways) {
        if ($chartsToDeploy -eq "*" -or $chartsToDeploy.Contains($chart)) {
            Write-Output "Installing Api Gateway Chart: $chart"
            Install-Chart -chart $chart -initialOptions "-f app.yaml -f inf.yaml -f $ingressValuesFile  --set app.name=$appName --set inf.k8s.dns=$dns  --set image.pullPolicy=$imagePullPolicy --set inf.mesh.enabled=$useMesh --set ingress.hosts={$dns} --set inf.tls.enabled=$sslEnabled" -customRegistry $false
        }
    }
}
else {
    Write-Output "eShopOnContainers non-infrastructure charts aren't installed (-deployCharts is false)"
}

Write-Output "helm charts installed."
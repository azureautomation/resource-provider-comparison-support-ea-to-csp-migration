<#
.SYNOPSIS
Comparing EA to CSP resource providers.

.DESCRIPTION
Function which is meant to help you with the migration from EA to CSP.
It queries resources from all resource groups or specific resource group in the EA subscription and takes as a paramter resource providers from CSP
that you already sourced into a variable, right after comparison between arrays is performed and you will get green success messasge
or otherwise you will get red message with the resource providers which are not available in the target CSP subscription.

.PARAMETER All
Parameter All is specified in case you want to query resource providers against all resource groups.

.PARAMETER ResourceGroup
Parameter ResourecGroup is specified in case you want to query resource providers from the specific resource group.

.PARAMETER CspResource
Parameter CspResoure is mandatory in both cases, it's an array with the list of resource providers from CSP subscription.

.EXAMPLE
# Login to CSP subscription and tenant.
Connect-AzAccount -TenantId value -SubscriptionId value
$CspProvider = (Get-AzResourceProvider -ListAvailable).ProviderNamespace
# After retrieving resource providers from CSP execute the function.
Compare-EaToCsp -All -CspResource $CspProvider
#>
Function Compare-EaToCsp {
    [CmdletBinding(DefaultParameterSetName = 'All')]
    # Set this parameter if you want to target all resource groups
    param (
        [Parameter(Mandatory = $true,
            ParameterSetName = 'All')]
        [switch]$All,
        # Name of the specific resource group that you want to target
        [Parameter(Mandatory = $true,
            ParameterSetName = 'ResourceGroup')]
        [ValidateNotNullOrEmpty()]
        [string]$ResourceGroup,
        # List of resource providers from the target CSP subscription
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]$CspResource
    )
    process {
        if ($PSCmdlet.ParameterSetName -eq 'All') {
            $ResourceGroupList = (Get-AzResourceGroup).ResourceGroupName
            if ($ResourceGroupList) {
                $ResourceTypeList = [System.Collections.ArrayList]::new()
                foreach ($ResourceGroup in $ResourceGroupList) {
                    $ResourceType = (Get-AzResource -ResourceGroupName $ResourceGroup).ResourceType
                    if ($ResourceType) {
                        foreach ($Resource in $ResourceType) {
                            $Resource = $Resource.Split('/')[0]
                            [void]$ResourceTypeList.Add($Resource)
                        }
                    }
                }
                $ResourceTypeList = $ResourceTypeList | Sort-Object -Unique
                $Compare = Compare-Object -ReferenceObject $ResourceTypeList -DifferenceObject $($CspResource | Sort-Object -Unique) | Where-Object { $_.SideIndicator -eq '<=' }
                if ([string]::IsNullOrWhiteSpace($Compare)) {
                    Write-Host 'ALL RESOURCES CAN BE MIGRATED - SUCCESS!' -ForegroundColor Green
                }
                else {
                    Write-HOST 'WARNING - FOLLOWING RESOURCES ARE NOT SUPPORTED IN DESTINATION CSP SUBSCRIPTION' -ForegroundColor Red
                    $Compare.InputObject
                }
            }
        }
        if ($PSCmdlet.ParameterSetName -eq 'ResourceGroup') {
            $ResourceType = (Get-AzResource -ResourceGroupName $ResourceGroup).ResourceType
            if ($ResourceType) {
                $ResourceTypeList = [System.Collections.ArrayList]::new()
                foreach ($Resource in $ResourceType) {
                    $Resource = $Resource.Split('/')[0]
                    [void]$ResourceTypeList.Add($Resource)
                }
                $ResourceTypeList = $ResourceTypeList | Sort-Object -Unique
                $Compare = Compare-Object -ReferenceObject $ResourceTypeList -DifferenceObject $($CspResource | Sort-Object -Unique) | Where-Object { $_.SideIndicator -eq '<=' }
                if ([string]::IsNullOrWhiteSpace($Compare)) {
                    Write-Host 'ALL RESOURCES CAN BE MIGRATED - SUCCESS!' -ForegroundColor Green
                }
                else {
                    Write-HOST 'WARNING - FOLLOWING RESOURCES ARE NOT SUPPORTED IN DESTINATION CSP SUBSCRIPTION' -ForegroundColor Red
                    $Compare.InputObject
                }
            }
        }
    }
}
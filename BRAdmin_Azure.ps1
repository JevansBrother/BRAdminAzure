
############################################
#Editable Variables
############################################
# Resource Group
$resourceGroup = "BRAdminAzure"
$location = "West Europe"

# Storage Account
$storageAccount = "bradminazure"

# Storage Container (used for BLOB storage)
$container = "container01"


#Table Name
$table = "table01"


############################################
#Non editable Variables
############################################
# Storage Container Policy start & expire dates
$startTime = (Get-Date).ToUniversalTime().AddYears(0)
$expiryTime = (Get-Date).ToUniversalTime().AddYears(1)


# Validation to remove unsupported characters from storage variables
$storageAccountName = $storageAccount.ToLower().replace(' ','') -replace '[\W]', ''
$containerName = $container.ToLower().replace(' ','') -replace '[\W]', ''
$tableName = $table.ToLower().replace(' ','') -replace '[\W]', ''


# BLOB Name
$blobName = "containerblob"

# Storage Container Policy Name
$containerPolicyName = $containerName+"policy"

# Table Policy Name
$tablePolicyName = $tableName+"policy"



<#
-- Azure BRAdmin Connector Script --

What is the script doing?


The following items are checked to see if they exist using Try & Catch.
If they are, they the script moves on and does not create them
If they cannot be found, it created them:
1. Resource Group
2. Storage Account
3. Storage Container (for BLOB storage)
4. Table
5. Storage Container Policy
6. Table Container Policy

The script then goes onto generare Container & Table SAS keys based on their respective policies


 #>


# Resource Group
# Checks if the named resource group already exists
Get-AzResourceGroup -Name $resourceGroup -ErrorVariable notPresent -ErrorAction SilentlyContinue > $null
 # It the resource group does not exist, this commandlet created it
 if ($notPresent) {
     write-host "Resource Group:   ""$($resourceGroup)"" is being created"
     New-AzResourceGroup -Name $resourceGroup -Location $location > $null
 }
# It the resource group already exists, this part of the if statement moves on the next section of the script
 else {
      write-host "Resource Group:   ""$($resourceGroup)"" has already been created"
 }
 
 

############################################
#Creates a new storage account (needed for the Azure BLOB & Table)
############################################
Get-AzStorageAccount -Name $storageAccountName -ResourceGroupName $resourceGroup -ErrorVariable notPresent -ErrorAction SilentlyContinue  > $null
   if ($notPresent) {
       write-host "Storage Account:  ""$($storageAccountName)"" is being created.  This can take up to 15 minutes"
       $storageAccount = New-AzStorageAccount -ResourceGroupName $resourceGroup -Name $storageAccountName -Location $location -SkuName Standard_RAGRS -Kind StorageV2
        $context = $storageAccount.Context
    }
    else {
        write-host "Storage Account:  ""$($storageAccountName)"" has already been created" 
        $storageAccount = Get-AzStorageAccount -Name $storageAccountName -ResourceGroupName $resourceGroup
        $context = $storageAccount.Context
  }



"`r"








############################################
#Storage Container (BLOB storage)
############################################
try {
Get-AzStorageContainer -Name $containerName -Context $context -ErrorAction Stop  > $null
  
write-host "Container:        ""$($containerName)"" has already been created"
}
catch [Microsoft.WindowsAzure.Commands.Storage.Common.ResourceNotFoundException]{
New-AzStorageContainer -Name $containerName -Context $context -Permission container -ErrorAction Stop  > $null
write-host "Container:        ""$($containerName)"" is being created"

}
catch{
 
    write-host "Other Error"
 
 }




############################################
#Creates BLOB SAS Policy
############################################
try {
Get-AzStorageContainerStoredAccessPolicy -Policy $containerPolicyName -Context $context -Container $containerName -ErrorAction Stop  > $null
  
write-host "Container Policy: ""$($containerPolicyName)"" has already been created"
}

catch [Microsoft.WindowsAzure.Commands.Storage.Common.ResourceNotFoundException]{
New-AzStorageContainerStoredAccessPolicy -Policy $containerPolicyName -Container $containerName  -Permission rwdlac -Context $context -StartTime $startTime -ExpiryTime $expiryTime -ErrorAction Stop  > $null
write-host "Container Policy: ""$($containerPolicyName)"" is being created"

}

catch{
 
    write-host "Other Error"
 

 }
 


"`r"





############################################
#Table
############################################
try {
Get-AzStorageTable -Name $tableName -Context $context -ErrorAction Stop  > $null
  
write-host "Table:            ""$($tableName)"" has already been created"
}
catch [Microsoft.WindowsAzure.Commands.Storage.Common.ResourceNotFoundException]{
 New-AzStorageTable -Name $tableName -Context $context  > $null
write-host "Table:            ""$($tableName)"" is being created"

}
catch{
 
    write-host "Other Error"
 
 }




############################################
#Table Policy
############################################
try {
Get-AzStorageTableStoredAccessPolicy -Name $tableName -Policy $tablePolicyName -Context $context -ErrorAction Stop  > $null
  
write-host "Table Policy:     ""$($tablePolicyName)"" has already been created"
}
catch [Microsoft.WindowsAzure.Commands.Storage.Common.ResourceNotFoundException]{
 New-AzStorageTableStoredAccessPolicy -Table $tableName -Policy $tablePolicyName -Context $context -Permission radu -StartTime $startTime -ExpiryTime $expiryTime  > $null
write-host "Table Policy:     ""$($tablePolicyName)"" is being created"

}
catch{
 
    write-host "Other Error"
 
 }

  

############################################
#SAS Key Generation
############################################

"`r"
"`r"
"`r"
write-host "Copy & paste the below links into BRAdmin Professional"
"`r"

write-host "BLOB URI"

$SASURI = New-AzStorageContainerSASToken -Name $containerName -Context $context -Policy $containerPolicyName -FullUri 

write-host $SASURI

"`r"

Write-host "Table URI" 
 
$tableSasUri = New-AzStorageTableSASToken  -Table $tableName  -Context $context -Policy $tablePolicyName -FullUri 


write-host $tableSasUri -NoNewline 

"`r"


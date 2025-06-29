$source_path= "."
$target_path= "F:\backup_test"
Function Get-ChildItemRecursive {
    param (
        [string]$Path
    )
    $under_directory = Get-ChildItem -Path $Path -Force
    foreach ($item in $under_directory) {
        if (Test-Path $item.FullName -PathType Container) {
            Write-Host "Processing directory: $($item.Fullname)" -BackgroundColor "red"
            Get-ChildItemRecursive $($item.FullName)
        } else {
            Write-Host "Processing file $($item.FullName)" -BackgroundColor "yellow"
        }
    }
}

Function Compare_Items {
    param (
        [string]$SourceItem_path,
        [string]$TargetItem_path
    )
    $SourceItem = Get-Item -Path $SourceItem_path
    $TargetItem = Get-Item -Path $TargetItem_path
    if (($SourceItem.LastWriteTimeUtc -ne $TargetItem.LastWriteTimeUtc) -or
        ($SourceItem.Length -ne $TargetItem.Length)) {
        Write-Host "File $($SourceItem.FullName) differs from $($TargetItem.FullName)`nFile $($SourceItem.FullName) is modified" -BackgroundColor "red"
        return $false
    }
    Write-Host "File $($SourceItem.FullName) is identical to $($TargetItem.FullName)" -BackgroundColor "green"
    return $true
}
Function Create_if_Not_Exist {
    param (
        [string]$SourceItem_Path,
        [string]$TargetItem_Path
    )
    $item = Get-Item $SourceItem_Path
    if ($item.PSIsContainer) {
        $ItemType = "Directory"
    } else {
        $ItemType = "File"
    }
    if (-not (Test-Path $TargetItem_Path)) {
        Write-Host "Creating $($ItemType): $TargetItem_Path" -BackgroundColor "green"
        New-Item -ItemType $ItemType -Path $TargetItem_Path 
    } else {
        Write-Host "$ItemType already exists: $TargetItem_Path" -BackgroundColor "blue"
    }
}

#Get-ChildItemRecursive $source_path
#$source_path= ".\backup.ps1"
#$target_path= "F:\backup_test\backup.ps1"
#Create_if_Not_Exist $source_path $target_path
#Get-ChildItemRecursive $target_path

<#
$source_path = "F:\coding\PS_backup\backup.ps1"
$target_path = "F:\backup_test\backup.ps1"
Copy-Item -Path $source_path -Destination $target_path -Force
Compare_Items $target_path $source_path
#>

$source="F:"
$file= "F:\coding\test\object\objectuser.py"
# powershell 6+ and above
#$PSVersionTable.PSVersion
#$relativePath = [System.IO.Path]::GetRelativePath($source, $file)
#Write-Host $relativePath
Function Get_RelativePath {
    param (
        $sourceRoot,
        $sourceFile
    )
    $relativePath = $sourceFile.Substring($sourceRoot.Length).TrimStart('\')
    #Write-Host $relativePath
    return $relativePath
}

Get_RelativePath $source $file
# $source_path= "F:\coding\application"
# $target_path= "F:\backup_test"

# Function Get-ChildItemRecursive {
#     param (
#         [string]$Path
#     )
#     $under_directory = Get-ChildItem -Path $Path -Force
#     foreach ($item in $under_directory) {
#         if (Test-Path $item.FullName -PathType Container) {
#             Write-Host "Processing directory: $($item.Fullname)" -BackgroundColor "red"
#             Get-ChildItemRecursive $($item.FullName)
#         } else {
#             Write-Host "Processing file $($item.FullName)" -BackgroundColor "yellow"
#         }
#     }
# }

Function Get-ChildItemRecursive {
    param (
        [string]$Path
    )
    $under_directory = Get-ChildItem -Path $Path -Force
    foreach ($item in $under_directory) {
        if (Test-Path $item -PathType Container) {
            Write-Host "Processing directory: $($item.Name)" -BackgroundColor "red"
            Get-ChildItemRecursive $item
        } else {
            Write-Host "Processing file $($item.Name)" -BackgroundColor "yellow"
        }
    }
}
Function Backup-WriteIn {
    param (
        $SourceRootPath,
        $TargetRootPath
    )
    $under_sourceRoot_directory = Get-ChildItem -Path $SourceRootPath -Force
    foreach ($SourceItem in $under_sourceRoot_directory) {
        $basename=$SourceItem.Name
        $TargetItem_path = Join-Path $TargetRootPath $basename
        if (Test-Path $SourceItem -PathType Container) {
            #$NewSourceItem = Join-Path 
            Write-Host "Processing directory: $basename " -BackgroundColor "red"
            Create_if_Not_Exist $SourceItem $TargetItem_path
            Backup-WriteIn $SourceItem $TargetItem_path
        } else {
            Write-Host "Processing file: $basename" -BackgroundColor "yellow"
            $copied = If_File_not_Exist_Copy $SourceItem $TargetItem_path
            if (-not $flag) {
                Compare_Items $SourceItem $TargetItem_path
            }
        }
    }
}
Function If_File_not_Exist_Copy {
    param (
        $SourceItem,
        $TargetItem_path
    )
    if (-not (Test-Path $TargetItem_path)) {
        Write-Host "File $TargetItem_path doesn't not exist, copying from $SourceItem"
        Copy-Item $SourceItem $TargetItem_path
        return $true
    }
    return $false
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
        Write-Host "Item $($SourceItem.FullName) differs from $($TargetItem.FullName)`nFile $($SourceItem.FullName) is modified" -BackgroundColor "red"
        Copy-Item $SourceItem $TargetItem
        return $true
    }
    Write-Host "Item $($SourceItem.FullName) is identical to $($TargetItem.FullName)" -BackgroundColor "green"
    return $false
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


<#
$source_path = "F:\coding\PS_backup\backup.ps1"
$target_path = "F:\backup_test\backup.ps1"
Copy-Item -Path $source_path -Destination $target_path -Force
Compare_Items $target_path $source_path
#>

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

Function Get_TargetItem_Path {
    param (
        $target_root,
        $relativePath
    )
    $TargetItem_Path = Join-Path $target_root $relativePath
    Write-Host $TargetItem_Path
}

# $sourceRoot="F:\"
# $sourceFile="F:\coding\PS_backup\backup.ps1"
# $target_path="F:\backup_test"
# $relative_Path = Get_RelativePath $sourceRoot $sourceFile
# $TargetItem_Path = Get_TargetItem_Path $target_path $relative_Path

$source_path= "F:\backup_source"
$target_path= "F:\backup_test"
Backup-WriteIn $source_path $target_path
# Get-ChildItemRecursive $source_path
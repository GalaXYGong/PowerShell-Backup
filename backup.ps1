#TODO:
# 1. Delete_if_Not_Exist needs to be fixed, it should move items to Deleted_root and create archive in Deleted_root
# 2. Create archive file name with timestamp
# 3. Add logging to the script
# 4. Add performance counters to measure the time taken for each operation
# 5. Automate the folder creation for modified items and deleted items

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
            #Write-Host "Processing directory: $($item.Name)" -BackgroundColor "red"
            Get-ChildItemRecursive $item
        } else {
            #Write-Host "Processing file $($item.Name)" -BackgroundColor "yellow"
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
            #Write-Host "Processing directory: $basename" -BackgroundColor "red"
            $created = Create_if_Not_Exist $SourceItem $TargetItem_path
            Backup-WriteIn $SourceItem $TargetItem_path
        } else {
            #Write-Host "Processing file: $basename" -BackgroundColor "yellow"
            $copied = If_File_not_Exist_Copy $SourceItem $TargetItem_path
            if (-not $copied) {
                $changed = Compare_Items $SourceItem $TargetItem_path
                if ($changed) {
                    # here we need real_target_path
                    Move-Modifed $real_target_path $TargetItem_path $modified_root                 
                    Copy-Item $SourceItem $TargetItem_path
                }
            }
        }
    }
}

Function Backup-Delete {
    param (
        $SourceRootPath,
        $TargetRootPath,
        $DeleteRootPath
    )
    $under_TargetRoot_directory = Get-ChildItem -Path $TargetRootPath -Force
    if (-not (Test-Path $DeleteRootPath)) {
        Write-Host "Creating delete root directory: $DeleteRootPath" -BackgroundColor "green"
        New-Item -ItemType Directory -Path $DeleteRootPath | Out-Null
    }
    foreach ($TargetItem in $under_TargetRoot_directory) {
        $basename=$TargetItem.Name
        $SourceItem_path = Join-Path $SourceRootPath $basename
        $Deleted = Delete_if_Not_Exist $TargetItem $SourceItem_path $DeleteRootPath
        if ((-not $Deleted) -and (Test-Path $TargetItem -PathType Container)) {
            #Write-Host "Processing directory: $basename" -BackgroundColor "red"
            Backup-Delete $SourceItem_path $TargetItem.FullName $DeleteRootPath
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
        Write-Host "File $($SourceItem.Name) is modified" -BackgroundColor "red"
        return $true
    }
    #Write-Host "Item $($SourceItem.FullName) is identical to $($TargetItem.FullName)" -BackgroundColor "green"
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
        return $true
    } else {
        #Write-Host "$ItemType already exists: $TargetItem_Path" -BackgroundColor "blue"
        return $false
    }
}
Function Move-Modifed {
    param (
        [string]$TargetRoot,
        [string]$TargetItem_path,
        [string]$ModifiedRoot
    )
    $relativePath = Get_RelativePath $TargetRoot $TargetItem_path
    if (-not (Test-Path $ModifiedRoot)) {
        Write-Host "Creating modified root directory: $ModifiedRoot" -BackgroundColor "green"
        New-Item -ItemType Directory -Path $ModifiedRoot
    }
    $ParentRelativePath = Get-ParentRelativePath $real_target_path $TargetItem_path
    $ModifiedParentpath = Make_ModifiedItem_Dir_If_Not_Exist $ModifiedRoot $ParentRelativePath
    #Write-Host "Moving modified item from $TargetItem_path, to $ModifiedParentpath" -BackgroundColor "magenta"
    $ArchiveFileName = ArchiveFileName $TargetItem_path
    $ModifiedItem_path = Join-Path $ModifiedParentpath $ArchiveFileName
    Copy-Item -Path $TargetItem_path -Destination $ModifiedItem_path -Force
}

Function Move-Deleted {
    param (
        [string]$TargetRoot,
        [string]$TargetItem_path,
        [string]$DeleteRoot
    )
    $relativePath = Get_RelativePath $TargetRoot $TargetItem_path
    if (-not (Test-Path $DeleteRoot)) {
        Write-Host "Creating delete root directory: $DeleteRoot" -BackgroundColor "green"
        New-Item -ItemType Directory -Path $DeleteRoot
    }
    #Write-Host "DeleteRoot: $DeleteRoot" -BackgroundColor "green"
    $ParentRelativePath = Get-ParentRelativePath $real_target_path $TargetItem_path
    $ModifiedParentpath = Make_ModifiedItem_Dir_If_Not_Exist $ModifiedRoot $ParentRelativePath
    Write-Host "Moving modified item from $TargetItem_path to $ModifiedParentpath" -BackgroundColor "magenta"
    $ArchiveFileName = ArchiveFileName $TargetItem_path
    $ModifiedItem_path = Join-Path $ModifiedParentpath $ArchiveFileName
    Copy-Item -Path $TargetItem_path -Destination $ModifiedItem_path -Force
}
Function Get-ParentRelativePath {
    param (
        [string]$Root_path, #should be the real root path of the source directory
        [string]$File_path
    )
    $File= Get-Item $File_path
    $Parent=$File.Directory
    $ParentRelativePath = Get_RelativePath $Root_path $Parent.FullName
    return $ParentRelativePath
}

Function Make_ModifiedItem_Dir_If_Not_Exist {
    param (
        [string]$ModifiedRoot,
        [string]$ParentRelativePath
    )
    $ArchiveDir = Create-TodayArchiveDir $ModifiedRoot
    $ModifiedItem_Dir = Join-Path $ArchiveDir $ParentRelativePath
    if (-not (Test-Path $ModifiedItem_Dir)) {
        Write-Host "Creating modified item directory: $ModifiedItem_Dir" -BackgroundColor "green"
        New-Item -ItemType Directory -Path $ModifiedItem_Dir | Out-Null
    }
    return $ModifiedItem_Dir
}
Function Get-ArchiveTime {
    param (
        [string]$TargetItem_path
    )
    $TargetItem = Get-Item -Path $TargetItem_path
    $ArchiveTime = $TargetItem.LastWriteTimeUtc.ToString("yyyyMMdd_HHmmss")
    return $ArchiveTime
}
Function Create-TodayArchiveDir {
    param (
        [string]$ModifiedRoot
    )
    $today = Get-Date -Format "yyyy_MM_dd"
    $ArchiveDir = Join-Path $ModifiedRoot $today
    if (-not (Test-Path $ArchiveDir)) {
        Write-Host "Creating archive directory for today: $ArchiveDir" -BackgroundColor "green"
        New-Item -ItemType Directory -Path $ArchiveDir | Out-Null
    }
    return $ArchiveDir
}

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

Function ArchiveFileName {
    param (
        [string]$Item
    )
    $ArchiveTime = Get-ArchiveTime $Item
    $FileName = Get-Item $Item | Select-Object -ExpandProperty Name
    $ArchiveFileName = "$($ArchiveTime)_$($FileName)"
    Write-Host "Archive file name: $ArchiveFileName" -BackgroundColor "cyan"
    return $ArchiveFileName
}
# TODO move items to Deleted_root and create archive in Deleted_root
# TODO create archive file name with timestamp
Function Delete_if_Not_Exist {
    param (
        $TargetItem,
        $SourceItem_path,
        $delete_root
    )
    $relativePath = Get_RelativePath $real_target_path $TargetItem.FullName
    $TargetItem_path = Join-Path $real_target_path $relativePath
    #Write-Host "delete-root: $delete_root" -BackgroundColor "green"
    if (-not (Test-Path $SourceItem_path)) {
        Write-Host "Deleting item: $($TargetItem.FullName) because it does not exist in source" -BackgroundColor "red"
        Move-Item -Path $TargetItem.FullName -Destination $delete_root -Force
        return $true
    }
    return $false
}
# Load configuration from config.json
# $configPath = "F:\coding\PS_backup\config.json"
$configPath = Join-Path -Path $PSScriptRoot -ChildPath "config.json"
$config = Get-Content $configPath | ConvertFrom-Json

$source_path = $config.source_path
$target_path = $config.target_path
$modified_root = $config.modified_root
$real_source_path = $config.real_source_path
$real_target_path = $config.real_target_path
$deleted_root = $config.deleted_root


Backup-WriteIn $source_path $target_path
Backup-Delete $source_path $target_path $deleted_root

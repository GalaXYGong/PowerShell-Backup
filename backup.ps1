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
            Write-Host "Processing directory: $basename" -BackgroundColor "red"
            $created = Create_if_Not_Exist $SourceItem $TargetItem_path
            Backup-WriteIn $SourceItem $TargetItem_path
        } else {
            Write-Host "Processing file: $basename" -BackgroundColor "yellow"
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
        Write-Host "$ItemType already exists: $TargetItem_Path" -BackgroundColor "blue"
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
    $ModifiedItem_path = Make_ModifiedItem_Dir_If_Not_Exist $ModifiedRoot $ParentRelativePath
    Write-Host "Moving modified item from $TargetItem_path, to $ModifiedItem_path" -BackgroundColor "magenta"
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



$source_path= "F:\backup_source"
$target_path= "F:\backup_test"
$modified_root= "F:\backup_modified"
$real_source_path= "F:\backup_source"
$real_target_path= "F:\backup_test"
Backup-WriteIn $source_path $target_path
# Get-ChildItemRecursive $source_path
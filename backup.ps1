# This function recursively lists all files and directories under a given path. The Prototype Function
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
# This script is used to backup files and directories from a source path to a target path.
Function Backup-WriteIn {
    # There are 2 parameters:
    # SourceRootPath: The root path of the source directory, which will be changed in recursion.
    # TargetRootPath: The root path of the target directory, which will be changed in recursion.
    param (
        $SourceRootPath,
        $TargetRootPath
    )
    $under_sourceRoot_directory = Get-ChildItem -Path $SourceRootPath -Force
    foreach ($SourceItem in $under_sourceRoot_directory) {
        $basename=$SourceItem.Name
        $TargetItem_path = Join-Path $TargetRootPath $basename
        # if it is a directory, we need to create it in the target path if it does not exist
        if (Test-Path $SourceItem -PathType Container) {
            #Write-Host "Processing directory: $basename" -BackgroundColor "red"
            $created = Create_if_Not_Exist $SourceItem $TargetItem_path
            Backup-WriteIn $SourceItem $TargetItem_path
        } else {
            # if it is a file, we need to check if it exists in the target path
            #Write-Host "Processing file: $basename" -BackgroundColor "yellow"
            # if the file does not exist in the target path, we copy it
            $copied = If_File_not_Exist_Copy $SourceItem $TargetItem_path
            if (-not $copied) {
                # if the file exists, we need to compare it with the source file
                $changed = Compare_Items $SourceItem $TargetItem_path
                # if the file is modified, we need to move the modified file to the modified root directory
                if ($changed) {
                    # here we need real_target_path
                    # move the modified file to the modified root directory and put it under the "modified directory/today's archive directory/relative path of the item/timestamp_file name"
                    Move-Modified $real_target_path $TargetItem_path $modified_root                 
                    Copy-Item $SourceItem $TargetItem_path
                }
            }
        }
    }
}
# This function deletes items in the target directory that do not exist in the source directory.
Function Backup-Delete {
    # There are 3 parameters:
    # SourceRootPath: The root path of the source directory.
    # TargetRootPath: The root path of the target directory.
    # DeleteRootPath: The root path where deleted items will be moved.
    param (
        $SourceRootPath,
        $TargetRootPath,
        $DeleteRootPath
    )
    $under_TargetRoot_directory = Get-ChildItem -Path $TargetRootPath -Force
    # Check if the delete root directory exists, if not, create it
    if (-not (Test-Path $DeleteRootPath)) {
        Write-Host "Creating delete root directory: $DeleteRootPath" -ForegroundColor "green"
        New-Item -ItemType Directory -Path $DeleteRootPath | Out-Null
    }
    # Iterate through each item in the target directory
    foreach ($TargetItem in $under_TargetRoot_directory) {
        #Write-Host "Processing item: $($TargetItem.FullName)" -ForegroundColor "green"
        $basename=$TargetItem.Name
        $SourceItem_path = Join-Path $SourceRootPath $basename
        # if the item is deleted from the source directory, we need to delete it from the target directory
        $Deleted = Delete_if_Not_Exist $TargetItem $SourceItem_path $DeleteRootPath
        # if the item is not deleted and it is a directory, we need to process it recursively
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
        Write-Host "File $($SourceItem.Name) is modified" -ForegroundColor "red"
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
        Write-Host "Creating $($ItemType): $TargetItem_Path" -ForegroundColor "green"
        New-Item -ItemType $ItemType -Path $TargetItem_Path 
        return $true
    } else {
        #Write-Host "$ItemType already exists: $TargetItem_Path" -BackgroundColor "blue"
        return $false
    }
}
Function Move-Modified {
    param (
        # there are 3 parameters:
        # TargetRoot: The root path of the target directory, which will not be changed in recursion.
        # TargetItem_path: The path of the item in the target directory.
        # ModifiedRoot: The root path of the Modified directory, which will not be changed in recursion.
        [string]$TargetRoot,
        [string]$TargetItem_path,
        [string]$ModifiedRoot
    )
    # Get the relative path of the item in the target directory
    $relativePath = Get_RelativePath $TargetRoot $TargetItem_path
    if (-not (Test-Path $ModifiedRoot)) {
        Write-Host "Creating modified root directory: $ModifiedRoot" -ForegroundColor "green"
        # and create the modified item directory if it does not exist.
        New-Item -ItemType Directory -Path $ModifiedRoot
    }
    # get the parent relative path of the item in the target directory
    $ParentRelativePath = Get-ParentRelativePath $real_target_path $TargetItem_path
    # create the modified item directories under modified directory if it does not exist.
    $ModifiedParentpath = Make_ModifiedItem_Dir_If_Not_Exist $ModifiedRoot $ParentRelativePath
    #Write-Host "Moving modified item from $TargetItem_path, to $ModifiedParentpath" -BackgroundColor "magenta"
    # create the archive file name with timestamp
    $ArchiveFileName = ArchiveFileName $TargetItem_path
    $ModifiedItem_path = Join-Path $ModifiedParentpath $ArchiveFileName
    # and copy the item to the modified item directory.
    Copy-Item -Path $TargetItem_path -Destination $ModifiedItem_path -Force
}

Function Move-Deleted {
    param (
        # there are 3 parameters:
        # TargetRoot: The root path of the target directory, which will not be changed in recursion.
        # TargetItem_path: The path of the item in the target directory.
        # ModifiedRoot: The root path of the Modified directory, which will not be changed in recursion.
        [string]$TargetRoot,
        [string]$TargetItem_path,
        [string]$DeleteRoot
    )
    $relativePath = Get_RelativePath $TargetRoot $TargetItem_path
    if (-not (Test-Path $DeleteRoot)) {
        Write-Host "Creating delete root directory: $DeleteRoot" -ForegroundColor "green"
        New-Item -ItemType Directory -Path $DeleteRoot
    }
    $ParentRelativePath = Get-ParentRelativePath $real_target_path $TargetItem_path
    $DeletedParentpath = Make_ModifiedItem_Dir_If_Not_Exist $DeleteRoot $ParentRelativePath
    #Write-Host "Moving deleted item from $TargetItem_path to $DeletedParentpath" -BackgroundColor "magenta"
    $ArchiveFileName = ArchiveFileName $TargetItem_path
    $DeletedItem_path = Join-Path $DeletedParentpath $ArchiveFileName
    Write-Host "Deleted item $targetItem_path will be moved to $DeletedItem_path" -ForegroundColor "red"
    Move-Item -Path $TargetItem_path -Destination $DeletedItem_path -Force
}
Function Get-ParentRelativePath {
    param (
        [string]$Root_path, #should be the real root path of the source directory
        [string]$File_path
    )
    $File= Get-Item $File_path
    #Write-Host "Getting parent relative path for file: $($File.FullName)" -BackgroundColor "cyan"
    if ($File.PSIsContainer) {
       $parent = $File.Parent.FullName
   } else {
       $parent = $File.Directory.FullName
   }
    $ParentRelativePath = Get_RelativePath $Root_path $parent
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
        Write-Host "Creating modified item directory: $ModifiedItem_Dir" -ForegroundColor "green"
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
        Write-Host "Creating archive directory for today: $ArchiveDir" -ForegroundColor "green"
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
    $ArchiveItemName = "$($ArchiveTime)_$($FileName)"
    #Write-Host "Archive item name: $ArchiveItemName" -BackgroundColor "cyan"
    return $ArchiveItemName
}

Function Delete_if_Not_Exist {
    param (
        # There are 3 parameters:
        # TargetItem: The item in the target directory that we want to check.
        # SourceItem_path: The path of the item in the source directory.
        # delete_root: The root path where deleted items will be moved to, which will not be changed in recursion.
        $TargetItem,
        $SourceItem_path,
        $delete_root
    )
    $relativePath = Get_RelativePath $real_target_path $TargetItem.FullName
    $TargetItem_path = Join-Path $real_target_path $relativePath
    if (-not (Test-Path $SourceItem_path)) {
        Write-Host "Deleting item: $($TargetItem.FullName) because it does not exist in source" -ForegroundColor "red"
        Move-Deleted -TargetRoot $real_target_path -TargetItem_path $TargetItem_path -DeleteRoot $delete_root
        return $true
    }
    return $false
}

$configPath_self = Join-Path -Path $PSScriptRoot -ChildPath "config_self.json"
$configPath = Join-Path -Path $PSScriptRoot -ChildPath "config.json"
if (Test-Path $configPath_self) {
    $configPath = $configPath_self
}

$config = Get-Content $configPath | ConvertFrom-Json

$source_path = $config.source_path
$target_path = $config.target_path
$deleted_root = Join-Path -Path $target_path -ChildPath "deleted"
$modified_root = Join-Path -Path $target_path -ChildPath "modified"
$real_source_path = $source_path 
$real_target_path = Join-Path -Path $target_path -ChildPath "backup"
$target_path = Join-Path -Path $target_path -ChildPath "backup"



$startTime_writeIn = Get-Date
Backup-WriteIn $source_path $target_path
$endTime_writeIn = Get-Date
$duration_writeIn = $endTime_writeIn - $startTime_writeIn
Write-Host "Time taken for WriteIn: $duration_writeIn" -BackgroundColor "green"

$startTime_delete = Get-Date
Backup-Delete $source_path $target_path $deleted_root
$endTime_delete = Get-Date
$duration_delete = $endTime_delete - $startTime_delete
Write-Host "Time taken for Delete: $duration_delete" -BackgroundColor "green"
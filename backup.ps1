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
        [string]$SourceItem,
        [string]$TargetItem
    )
    if ($SourceItem.LastWriteTimeUtc -ne $TargetItem.LastWriteTimeUtc -or
        $SourceItem.Length -ne $TargetItem.Length) {
        Write-Host "File $($SourceItem.FullName) differs from $($TargetItem.FullName)" -BackgroundColor "red"
        return $false

    }
}
Function Create_Folder_if_Not_Exist {
    param (
        [string]$Path
    )
    if (-not (Test-Path $Path)) {
        Write-Host "Creating folder: $Path" -BackgroundColor "green"
        New-Item -ItemType Directory -Path $Path | Out-Null
    } else {
        Write-Host "Folder already exists: $Path" -BackgroundColor "blue"
    }
}

#Get-ChildItemRecursive $source_path
Create_Folder_if_Not_Exist $target_path
Get-ChildItemRecursive $target_path
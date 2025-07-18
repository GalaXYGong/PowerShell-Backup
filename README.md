# PowerShell-Backup
## Introduction
It is a PowerShell Script to backup and archive files using recursing.
## Parameters needed
Current it takes in 2 path in config.json
1. source_path (it is the folder you want to backup)
2. target_path (it is the folder you want to put backups, deleted archived files, and modified archived files)
Making sure you change those path as you wish
## Functions
1. PS_backup create "modified", "backup", and "deleted" under target_path
    - "backup" is to put backup files and directory in the same file system structure as they are in source_path
    - "modified" is to put modified files in the same file system structure as they are in source_path
    - "deleted" is to put deleted files and directories in the same file system structure as they are in source_path
2. Function Backup-WriteIn will run a scan on source_path recursively and then do a comparison between source_path Items and Items of "target_path\backup". If new files/directories are created in source_path, the new items will be copied to target_path\backup. If certain files are changed/modified (we can know that through comparing size and last write time of them), the older version (in target_path\backup) will be moved to "modified" folder to archive, and the newer version (from source_path) will be copied to the corresponding location.
3. Function Backup-Delete will run a scan on "target_path\backup" recursively and then do a comparison between source_path Items and Items of "target_path\backup". If certain files are deleted in source_path but still in "target_path\backup". They will be moved to "deleted" folder to archive. 
4. Archived Files/Folders will get a time stamp in the file/folder name, which is the last write time, so we can see when the version is generated/modified.
5. The running time of Function Backup-WriteIn and Backup-Delete will be record and reported in console.

This Script development is still on-going more features will be added.
# TODO:
1. ~~Delete_if_Not_Exist needs to be fixed, it should move items to Deleted_root and create archive in Deleted_root~~
2. ~~Create archive file name with timestamp~~
3. Add logging to the script
4. ~~Add performance counters to measure the time taken for each operation~~
5. ~~Automate the folder creation for modified items and deleted items~~
6. Add multiple source directory support
7. Add filename exclude directory/file support
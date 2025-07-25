# 📁 PowerShell Backup Script

## 📌 Introduction

A PowerShell script designed to backup, detect changes, and archive files using recursive comparison. It maintains backup integrity by detecting new, modified, and deleted files, and organizing them for easy retrieval.

## ⚙️ How to Use
1.	Open the **config.json** file.
2.	Update the following parameters:
- **source_path**: Folder you want to back up.
- **target_path**: Folder where backup, modified, and deleted files will be stored.
3.	Right-click **backup.ps1** → Run with PowerShell.

## 📁 Configuration Parameters

The script reads the following paths from config.json:
- **source_path**: Source directory to back up.
- **target_path**: Destination directory where backups and archives will be saved.

✅ Make sure both paths are correctly set before running the script.

## 🧠 What the Script Does

1. Folder Structure Creation

The script creates the following subdirectories under target_path:
- backup: Stores the full backup in the same structure as source_path.
- modified: Archives modified files with timestamps.
- deleted: Archives deleted files/directories with timestamps.

2. Backup-WriteIn
- Recursively scans source_path.
- Compares it with target_path\backup:
- New files/directories → copied to backup.
- Modified files (checked by size and last write time) →
- Old versions moved to modified with a timestamp.
- New versions copied to backup.

3. Backup-Delete
- Scans target_path\backup recursively.
- If a file/folder exists in backup but not in source_path:
- It’s considered deleted and moved to the deleted folder with a timestamp.

4. Timestamped Archives
- Archived items in modified and deleted are renamed to include their last modified time for version tracking.

5. Performance Reporting
- Execution time for both Backup-WriteIn and Backup-Delete is measured and reported in the console.

## 🚧 TODO (Upcoming Features)
- ~~Fix Delete_if_Not_Exist to move items to deleted with correct archiving.~~
- ~~Add timestamp to archived file/folder names.~~
- Add logging functionality.
- ~~Add performance counters for timing analysis.~~
- ~~Automate creation of modified and deleted folders.~~
- Support multiple source directories.
- Add exclude list support (ignore specific files/folders).
- Add restoration function

## 🔧 Script is under active development — more features and refinements coming soon!

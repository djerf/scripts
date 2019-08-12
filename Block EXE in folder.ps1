[void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic')

# Credit for this function to Daniel Schroeder, http://blog.danskingdom.com/powershell-multi-line-input-box-dialog-open-file-dialog-folder-browser-dialog-input-box-and-message-box/
function Read-FolderBrowserDialog([string]$Message, [string]$InitialDirectory, [switch]$NoNewFolderButton) {
    $browseForFolderOptions = 0

    if ($NoNewFolderButton) { 
        $browseForFolderOptions += 512
    }
 
    $app = New-Object -ComObject Shell.Application

    $folder = $app.BrowseForFolder(0, $Message, $browseForFolderOptions, $InitialDirectory)

    if ($folder) { 
        $selectedDirectory = $folder.Self.Path } else { $selectedDirectory = '' 
    }

    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($app) > $null

    return $selectedDirectory
}


# Select a directory

$directoryPath = Read-FolderBrowserDialog -Message "Please select a directory" -InitialDirectory 'D:\' -NoNewFolderButton

if (![string]::IsNullOrEmpty($directoryPath)) {
    Write-Host "You selected the directory: $directoryPath"
}

else { 
    Write-Host "You did not select a directory." 
    $directoryPath = $null 
    Exit 
}


# Loop through selected folder and subfolders to find .exe-files and block in firewall

Get-ChildItem $directoryPath -Include *.exe -Recurse -Force | % {
        $name = $_.name
        $date = Get-Date -Format FileDate

        $block = New-NetFirewallRule -DisplayName "$date Block $name" -Direction Outbound -Program $_ -Action Block
        
		Write-Host "Program blocked:" $_        
}
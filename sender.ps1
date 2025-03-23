param (
    [Parameter(Mandatory = $true)]
    [string]$Folder
)

# Validate folder path
if (-Not (Test-Path $Folder -PathType Container)) {
    Write-Host "Folder '$Folder' not found."
    exit
}

# Normalize base folder path with trailing backslash
$baseFolder = (Resolve-Path $Folder).Path.TrimEnd('\') + '\'

# Function to compress data using GZip
function Compress-Data {
    param(
        [byte[]]$Data
    )
    $ms = New-Object System.IO.MemoryStream
    $gzip = New-Object System.IO.Compression.GZipStream($ms, [System.IO.Compression.CompressionMode]::Compress)
    $gzip.Write($Data, 0, $Data.Length)
    $gzip.Close()
    $compressed = $ms.ToArray()
    $ms.Dispose()
    return $compressed
}

# Get all files recursively from the folder
$files = Get-ChildItem -Path $Folder -Recurse -File
foreach ($file in $files) {
    $fullPath = $file.FullName
    $relativePath = $fullPath.Substring($baseFolder.Length)

    # Encode the relative path in Base64
    $encodedPath = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($relativePath))

    Write-Host "Sending file: $relativePath"

    # Read file bytes (empty if the file is empty)
    $bytes = [System.IO.File]::ReadAllBytes($fullPath)

    # Compute SHA1 hash of the original file (even for empty files)
    $sha1 = [System.BitConverter]::ToString(
                [System.Security.Cryptography.SHA1]::Create().ComputeHash($bytes)
            ) -replace "-", ""

    # Handle empty files (avoid GZip issues)
    if ($bytes.Length -eq 0) {
        $encodedData = ""  # Empty Base64 string
    } else {
        # Compress and encode the data
        $compressedBytes = Compress-Data -Data $bytes
        $encodedData = [System.Convert]::ToBase64String($compressedBytes)
    }

    # Create message format: TRANSFER|Base64(relativePath)|Base64(compressedData)|sha1
    $message = "TRANSFER|$encodedPath|$encodedData|$sha1"
    $message | Set-Clipboard
    Write-Host "File '$relativePath' prepared and placed in clipboard."
    Write-Host "Computed SHA1: $sha1"

    # Wait for ACK from receiver
    Write-Host "Waiting for ACK for '$relativePath'..."
    while ($true) {
        Start-Sleep -Seconds 1
        try {
            $clip = Get-Clipboard -Raw
        } catch {
            continue
        }
        if ($clip -match "^ACK\|$encodedPath") {
            Write-Host "ACK received for file '$relativePath'."
            break
        }
    }
}

Write-Host "All files have been sent."

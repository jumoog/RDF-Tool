param (
    [string]$TargetFolder = (Get-Location).Path
)

Write-Host "Receiver is running and waiting for files..."
Write-Host "Files will be restored to: $TargetFolder"

# Function to decompress a byte array using GZip
function Decompress-Data {
    param(
        [byte[]]$Data
    )
    $ms = [System.IO.MemoryStream]::new($Data)
    $gzip = New-Object System.IO.Compression.GZipStream($ms, [System.IO.Compression.CompressionMode]::Decompress)
    $resultStream = New-Object System.IO.MemoryStream
    $buffer = New-Object byte[] 4096
    while (($read = $gzip.Read($buffer, 0, $buffer.Length)) -gt 0) {
        $resultStream.Write($buffer, 0, $read)
    }
    $gzip.Close()
    $ms.Dispose()
    $result = $resultStream.ToArray()
    $resultStream.Dispose()
    return $result
}

while ($true) {
    Start-Sleep -Seconds 1
    try {
        $clip = Get-Clipboard -Raw
    } catch {
        continue
    }
    if ($clip -match "^TRANSFER\|") {
        # Parse the clipboard message into 4 parts: header, Base64(relativePath), Base64(data), and SHA1 hash.
        $parts = $clip -split "\|", 4
        if ($parts.Count -eq 4) {
            # Decode the Base64 relative path
            $encodedPath = $parts[1]
            $relativePath = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($encodedPath))

            $encodedData = $parts[2]
            $expectedHash = $parts[3]

            # Compute the full path
            $targetPath = Join-Path -Path $TargetFolder -ChildPath $relativePath

            # Check if the file already exists and has the same SHA1 hash
            if (Test-Path $targetPath) {
                $existingBytes = [System.IO.File]::ReadAllBytes($targetPath)
                $existingHash = [System.BitConverter]::ToString(
                                    [System.Security.Cryptography.SHA1]::Create().ComputeHash($existingBytes)
                                ) -replace "-", ""

                if ($existingHash -eq $expectedHash) {
                    Write-Host "Skipping existing file: $relativePath (SHA1 match)"
                    "ACK|$encodedPath" | Set-Clipboard
                    Start-Sleep -Seconds 2
                    continue
                }
            }

            Write-Host "Receiving file: $relativePath"
            Write-Host "Expected SHA1: $expectedHash"

            try {
                # Handle empty files (encodedData will be empty)
                if ($encodedData -eq "") {
                    $bytes = @()
                } else {
                    # Decode Base64 data and decompress it
                    $compressedBytes = [System.Convert]::FromBase64String($encodedData)
                    $compressedBytes = [byte[]]$compressedBytes
                    Write-Host "Received compressed data: Length=$($compressedBytes.Length)"
                    
                    # Decompress the data
                    $bytes = Decompress-Data -Data $compressedBytes
                }

                # Compute SHA1 hash of the decompressed data (or empty file)
                $receiverHash = [System.BitConverter]::ToString(
                                    [System.Security.Cryptography.SHA1]::Create().ComputeHash($bytes)
                                ) -replace "-", ""
                Write-Host "Computed SHA1: $receiverHash"
                
                if ($receiverHash -eq $expectedHash) {
                    Write-Host "SHA1 match. Integrity verified."

                    # Ensure the target directory exists
                    $targetDir = Split-Path $targetPath -Parent
                    if ($targetDir -and (-not (Test-Path $targetDir))) {
                        New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
                    }
                    
                    # Write the file (empty files are handled too)
                    [System.IO.File]::WriteAllBytes($targetPath, $bytes)
                    Write-Host "File saved as: $targetPath"

                    # Send ACK handshake back
                    "ACK|$encodedPath" | Set-Clipboard
                    Start-Sleep -Seconds 2
                }
                else {
                    Write-Host "SHA1 mismatch for file '$relativePath'."
                    Write-Host "Expected: $expectedHash, Computed: $receiverHash"
                }
            }
            catch {
                Write-Host "Error processing file: $relativePath"
                Write-Host "Exception: $($_.Exception.Message)"
            }
        }
    }
}

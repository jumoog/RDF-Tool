# RDF-Tool

RDF-Tool is a simple utility for transferring files (such as ZIP archives) between two Windows systems using the clipboard. It supports both single-file and multi-file/folder transfers, with optional compression and integrity checking.

## Usage

### Single File Transfer

1. **Packing:**
   - Drag and drop a file (preferably a ZIP archive) onto `packer.bat`.
   - The script encodes the file as Base64 and copies it to the clipboard.

2. **Extracting:**
   - On the receiving system, run `extractor.bat`.
   - The script reads the clipboard, decodes the file, and saves it in the same directory as the extractor.

**Note:** The maximum file size is limited by available RAM (about 300 MB).

### Folder or Multi-File Transfer

1. **Sending:**
   - Run `sender.ps1` with the folder you want to transfer:

     ```
     powershell -ExecutionPolicy Bypass -File sender.ps1 -Folder "C:\path\to\your\folder"
     ```

   - Each file is compressed, encoded, and sent via the clipboard with integrity (SHA1) checking.

2. **Receiving:**
   - On the target system, run `receiver.ps1`:

     ```
     powershell -ExecutionPolicy Bypass -File receiver.ps1 -TargetFolder "C:\restore\path"
     ```

   - The receiver waits for files in the clipboard, restores them to the target folder, and verifies integrity.

**Note:** Both sender and receiver must run on Windows with clipboard access.

## Files

- `packer.bat` / `packer.ps1`: Encode a file to Base64 and copy to clipboard.
- `extractor.bat` / `extractor.ps1`: Decode Base64 from clipboard and restore the file.
- `sender.ps1`: Recursively sends all files in a folder via clipboard, with compression and SHA1 integrity check.
- `receiver.ps1`: Receives files from clipboard, decompresses, verifies, and restores them.
- `LICENSE`: Apache 2.0 License.

## Limitations

- Clipboard-based transfer: Only one file at a time, and both systems must have access to the clipboard.
- File size is limited by available RAM (approx. 300 MB).
- Designed for Windows PowerShell.

## License

Apache License 2.0. See LICENSE file for details.

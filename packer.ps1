Param(
[string]$arg
)
[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
# encode zip file to base64
$fileName = [io.path]::GetFileName($arg)
# read file as byte
$bytes    = [IO.File]::ReadAllBytes($arg)
# convert byte to base64
$b64      = [Convert]::ToBase64String($bytes)
# add filename before base64 and write to clipboard
[Windows.Forms.Clipboard]::SetText($fileName + ";" + $b64)

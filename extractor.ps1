[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
# decode base64 file back to zip
# get text from clipboard
$Clipboard= [Windows.Forms.Clipboard]::GetText()
# split string
$split    = $Clipboard.Split(";")
# first part is the filename
$filename = $split[0]
# second part is the actual file as base64
$b64      = $split[1]
# encode back to byte
$bytes    = [Convert]::FromBase64String($b64)
# write bytes to file
[IO.File]::WriteAllBytes($scriptPath +"\"+$filename, $bytes)
# clear clipboard
[Windows.Forms.Clipboard]::Clear()

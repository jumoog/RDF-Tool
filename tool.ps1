# decode
$filename = '.\zip.zip'
$b64      = [IO.File]::ReadAllText($fileName + ".b64")
$bytes    = [Convert]::FromBase64String($b64)
[IO.File]::WriteAllBytes($filename, $bytes)

# encode
$filename = '.\zip.zip'
$bytes    = [IO.File]::ReadAllBytes($filename)
$b64      = [Convert]::ToBase64String($bytes)
[IO.File]::WriteAllText($fileName + ".b64", $b64)

Add-Type -AssemblyName System.Drawing
$width = 512
$height = 512
$bmp = New-Object System.Drawing.Bitmap($width, $height)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$rect = New-Object System.Drawing.Rectangle(0, 0, $width, $height)

$brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, ([System.Drawing.Color]::DeepSkyBlue), ([System.Drawing.Color]::Navy), ([System.Drawing.Drawing2D.LinearGradientMode]::Vertical))
$g.FillRectangle($brush, $rect)

$font = New-Object System.Drawing.Font("Arial", 60, ([System.Drawing.FontStyle]::Bold))
$format = New-Object System.Drawing.StringFormat
$format.Alignment = [System.Drawing.StringAlignment]::Center
$format.LineAlignment = [System.Drawing.StringAlignment]::Center
$textBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)

$g.DrawString("Balloon
Hunter", $font, $textBrush, ([System.Drawing.RectangleF]::new(0, 0, $width, $height)), $format)

$bmp.Save("c:\Users\Admin\Downloads\Balloon Hunter\assets\images\app_icon.png", ([System.Drawing.Imaging.ImageFormat]::Png))
$g.Dispose()
$bmp.Dispose()

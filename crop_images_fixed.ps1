[Reflection.Assembly]::LoadWithPartialName("System.Drawing")

$files = @("bg_morning_1.png", "bg_afternoon_1.png", "bg_night_1.png")
$sourceDir = "C:\Users\Admin\Downloads"
$targetDir = "C:\Users\Admin\Downloads\Balloon Hunter\assets\images"

foreach ($f in $files) {
    $src = Join-Path $sourceDir $f
    $name = $f.Replace("_1", "")
    $dest = Join-Path $targetDir $name

    if (Test-Path $src) {
        $img = [System.Drawing.Image]::FromFile($src)
        [int]$w = $img.Width
        # Crop 250 pixels from the bottom to aggressively remove any watermark
        [int]$h = $img.Height - 250
        $rect = New-Object System.Drawing.Rectangle(0, 0, $w, $h)
        $bmp = New-Object System.Drawing.Bitmap($w, $h)
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.DrawImage($img, 0, 0, $rect, [System.Drawing.GraphicsUnit]::Pixel)
        $bmp.Save($dest, [System.Drawing.Imaging.ImageFormat]::Png)
        $g.Dispose()
        $bmp.Dispose()
        $img.Dispose()
        Write-Host "Aggressively cropped $f -> $dest"
    } else {
        Write-Host "File $src not found!"
    }
}

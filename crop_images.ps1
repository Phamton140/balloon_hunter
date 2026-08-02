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
        # Crop 60 pixels from bottom to remove watermark (Gemini watermark is small, usually bottom right)
        $rect = New-Object System.Drawing.Rectangle(0, 0, $img.Width, $img.Height - 60)
        $bmp = New-Object System.Drawing.Bitmap($rect.Width, $rect.Height)
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.DrawImage($img, 0, 0, $rect, [System.Drawing.GraphicsUnit]::Pixel)
        $bmp.Save($dest, [System.Drawing.Imaging.ImageFormat]::Png)
        $g.Dispose()
        $bmp.Dispose()
        $img.Dispose()
        Write-Host "Cropped $f -> $dest"
    } else {
        Write-Host "File $src not found!"
    }
}

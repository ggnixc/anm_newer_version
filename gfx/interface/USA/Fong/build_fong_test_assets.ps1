param(
	[string]$SourceDirectory = ""
)

Add-Type -AssemblyName System.Drawing

$assetDirectory = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($SourceDirectory)) {
	$SourceDirectory = Join-Path $assetDirectory "source"
}

$requiredSources = @("contact.png", "top_rolo.png", "bottom_rolo.png", "top_rolo_portrait.png")
foreach ($sourceName in $requiredSources) {
	$sourcePath = Join-Path $SourceDirectory $sourceName
	if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
		throw "Missing Fong source asset: $sourcePath"
	}
}

$fontPath = Resolve-Path (Join-Path $assetDirectory "..\..\..\fonts\AldrichTNOV13.ttf")
$fontCollection = [System.Drawing.Text.PrivateFontCollection]::new()
$fontCollection.AddFontFile($fontPath.Path)
$fontFamily = $fontCollection.Families[0]

$cyan = [System.Drawing.Color]::FromArgb(255, 89, 199, 194)
$mutedCyan = [System.Drawing.Color]::FromArgb(205, 89, 199, 194)
$black = [System.Drawing.Color]::FromArgb(255, 0, 0, 0)
$transparent = [System.Drawing.Color]::FromArgb(0, 0, 0, 0)
$accentColors = @(
	[System.Drawing.Color]::FromArgb(255, 89, 199, 194),
	[System.Drawing.Color]::FromArgb(255, 210, 118, 119),
	[System.Drawing.Color]::FromArgb(255, 133, 234, 142),
	[System.Drawing.Color]::FromArgb(255, 235, 214, 94),
	[System.Drawing.Color]::FromArgb(255, 142, 173, 225),
	[System.Drawing.Color]::FromArgb(255, 213, 149, 224)
)
$names = @("CONTACT ONE", "CONTACT TWO", "CONTACT THREE", "CONTACT FOUR", "CONTACT FIVE", "CONTACT SIX")
$industries = @("AGRICULTURE", "MANUFACTURING", "FINANCE", "TRANSPORT", "ENERGY", "TELECOMMUNICATIONS")

function New-Canvas([int]$Width, [int]$Height) {
	$bitmap = [System.Drawing.Bitmap]::new($Width, $Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
	$bitmap.SetResolution(96, 96)
	return $bitmap
}

function New-Graphics([System.Drawing.Bitmap]$Bitmap) {
	$graphics = [System.Drawing.Graphics]::FromImage($Bitmap)
	$graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceOver
	$graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
	$graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
	$graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
	$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
	$graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
	return $graphics
}

function Save-Png([System.Drawing.Bitmap]$Bitmap, [string]$Name) {
	$target = Join-Path $assetDirectory $Name
	$Bitmap.Save($target, [System.Drawing.Imaging.ImageFormat]::Png)
}

$contactSource = [System.Drawing.Image]::FromFile((Join-Path $SourceDirectory "contact.png"))
$topSource = [System.Drawing.Image]::FromFile((Join-Path $SourceDirectory "top_rolo.png"))
$bottomSource = [System.Drawing.Image]::FromFile((Join-Path $SourceDirectory "bottom_rolo.png"))
$portraitSource = [System.Drawing.Image]::FromFile((Join-Path $SourceDirectory "top_rolo_portrait.png"))

$selectorAtlas = New-Canvas 1200 50
$selectorGraphics = New-Graphics $selectorAtlas
$selectorFont = [System.Drawing.Font]::new($fontFamily, 20, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
$selectorFormat = [System.Drawing.StringFormat]::new()
$selectorFormat.Alignment = [System.Drawing.StringAlignment]::Center
$selectorFormat.LineAlignment = [System.Drawing.StringAlignment]::Center
for ($index = 0; $index -lt 6; $index++) {
	$left = $index * 200
	$selectorGraphics.DrawImage($contactSource, [System.Drawing.Rectangle]::new($left, 0, 200, 50))
	$selectorGraphics.FillRectangle([System.Drawing.SolidBrush]::new($black), $left + 1, 1, 198, 48)
	$pen = [System.Drawing.Pen]::new($accentColors[$index], 1)
	$selectorGraphics.DrawRectangle($pen, $left, 0, 199, 49)
	$brush = [System.Drawing.SolidBrush]::new($accentColors[$index])
	$selectorGraphics.DrawString(($index + 1).ToString(), $selectorFont, $brush, [System.Drawing.RectangleF]::new($left + 1, 1, 56, 48), $selectorFormat)
	$pen.Dispose()
	$brush.Dispose()
}
Save-Png $selectorAtlas "fong_contact_selector_atlas.png"

$topAtlas = New-Canvas 2958 175
$topGraphics = New-Graphics $topAtlas
$nameFont = [System.Drawing.Font]::new($fontFamily, 24, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
$industryFont = [System.Drawing.Font]::new($fontFamily, 17, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
$portraitFont = [System.Drawing.Font]::new($fontFamily, 26, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
$portraitFormat = [System.Drawing.StringFormat]::new()
$portraitFormat.Alignment = [System.Drawing.StringAlignment]::Center
$portraitFormat.LineAlignment = [System.Drawing.StringAlignment]::Center
for ($index = 0; $index -lt 6; $index++) {
	$left = $index * 493
	$topGraphics.DrawImage($topSource, [System.Drawing.Rectangle]::new($left, 0, 493, 175))
	$topGraphics.DrawImage($portraitSource, [System.Drawing.Rectangle]::new($left + 20, 10, 70, 79))
	$accentBrush = [System.Drawing.SolidBrush]::new($accentColors[$index])
	$topGraphics.DrawString(($index + 1).ToString(), $portraitFont, $accentBrush, [System.Drawing.RectangleF]::new($left + 20, 10, 70, 79), $portraitFormat)
	$topGraphics.DrawString($names[$index], $nameFont, $accentBrush, [System.Drawing.PointF]::new($left + 104, 10))
	$topGraphics.DrawString($industries[$index], $industryFont, $accentBrush, [System.Drawing.PointF]::new($left + 104, 56))
	$accentBrush.Dispose()
}
Save-Png $topAtlas "fong_contact_top_atlas.png"

$flipFrameWidth = 533
$flipAtlas = New-Canvas ($flipFrameWidth * 6) 350
$flipGraphics = New-Graphics $flipAtlas
for ($index = 0; $index -lt 6; $index++) {
	$frameLeft = $index * $flipFrameWidth
	$sourceLeft = $index * 493
	$flipGraphics.DrawImage($topAtlas, [System.Drawing.Rectangle]::new($frameLeft, 0, 493, 175), [System.Drawing.Rectangle]::new($sourceLeft, 0, 493, 175), [System.Drawing.GraphicsUnit]::Pixel)
	$flipGraphics.DrawImage($bottomSource, [System.Drawing.Rectangle]::new($frameLeft, 175, 493, 175))
}
Save-Png $flipAtlas "fong_contact_flip_atlas.png"

$barAtlas = New-Canvas 356 22
$barGraphics = New-Graphics $barAtlas
$barGraphics.Clear($transparent)
$barBrush = [System.Drawing.SolidBrush]::new($mutedCyan)
$barGraphics.FillRectangle($barBrush, 1, 1, 176, 20)
$scanlineBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(65, 0, 20, 22))
for ($y = 2; $y -lt 21; $y += 3) {
	$barGraphics.FillRectangle($scanlineBrush, 1, $y, 176, 1)
}
Save-Png $barAtlas "fong_contact_bar_atlas.png"

$barBrush.Dispose()
$scanlineBrush.Dispose()
$selectorFormat.Dispose()
$portraitFormat.Dispose()
$selectorFont.Dispose()
$nameFont.Dispose()
$industryFont.Dispose()
$portraitFont.Dispose()
$selectorGraphics.Dispose()
$topGraphics.Dispose()
$flipGraphics.Dispose()
$barGraphics.Dispose()
$selectorAtlas.Dispose()
$topAtlas.Dispose()
$flipAtlas.Dispose()
$barAtlas.Dispose()
$contactSource.Dispose()
$topSource.Dispose()
$bottomSource.Dispose()
$portraitSource.Dispose()
$fontCollection.Dispose()

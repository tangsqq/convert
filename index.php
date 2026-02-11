<?php

/**
 * 高级 PDF/图像转换工具 (支持自动识别域名/IP)
 */

// 1. 环境配置
// 如果是 Windows XAMPP 环境，请确保以下路径正确
$magickPath = 'C:\Program Files\ImageMagick-7.1.2-Q16';
$gsPath = 'C:\Program Files\gs\gs10.04.1\bin';

if (strtoupper(substr(PHP_OS, 0, 3)) === 'WIN') {
    putenv("PATH=" . getenv('PATH') . ";" . $magickPath . ";" . $gsPath);
}

$message = "";

// 2. 处理转换逻辑
if (isset($_POST["submit"])) {
    if (isset($_FILES["fileToUpload"]) && $_FILES["fileToUpload"]["error"] == 0) {

        $tempFile = $_FILES["fileToUpload"]["tmp_name"];
        $targetFormat = $_POST["targetFormat"];
        $extension = pathinfo($_FILES["fileToUpload"]["name"], PATHINFO_EXTENSION);

        // 生成唯一文件名
        $fileNameOnly = 'converted_' . time();
        $outputFileName = $fileNameOnly . '.' . $targetFormat;
        $savePath = __DIR__ . DIRECTORY_SEPARATOR . $outputFileName;

        try {
            if (!class_exists('Imagick')) {
                throw new Exception("Imagick extension is not installed or enabled on the server.");
            }

            $image = new Imagick();

            // 针对 PDF 的特殊处理
            if (strtolower($extension) === 'pdf') {
                $image->setResolution(150, 150);
                // [0] 表示只转第一页，如需全转请删除 [0] 并循环处理
                $image->readImage(realpath($tempFile) . '[0]');
            } else {
                $image->readImage(realpath($tempFile));
            }

            // 防止透明背景变黑色
            $image->setImageBackgroundColor('white');
            $image = $image->mergeImageLayers(Imagick::LAYERMETHOD_FLATTEN);
            $image->setImageFormat($targetFormat);

            if ($image->writeImage($savePath)) {
                // --- 动态获取当前访问地址 (核心修改) ---
                $protocol = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? "https://" : "http://";
                $host = $_SERVER['HTTP_HOST']; // 获取域名或 IP (例如 192.168.1.5 或 www.test.com)
                $uri = rtrim(dirname($_SERVER['PHP_SELF']), '/\\');
                $downloadUrl = $protocol . $host . $uri . '/' . $outputFileName;

                $message = "<div style='color:green;'>Successful!<br>
                            <a href='$downloadUrl' target='_blank' style='font-weight:bold; color:#007bff;'>Click here to download: $outputFileName</a><br>
                            <small>Access URL: $downloadUrl</small></div>";
            }

            $image->clear();
            $image->destroy();
        } catch (Exception $e) {
            $message = "<div style='color:red;'>Error： " . $e->getMessage() . "</div>";
        }
    } else {
        $message = "<div style='color:red;'>Please upload a valid file.</div>";
    }
}
?>

<!DOCTYPE html>
<html lang="zh-CN">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Convert</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background-color: #f4f7f6;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
        }

        .container {
            background: white;
            padding: 30px;
            border-radius: 12px;
            box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
            width: 100%;
            max-width: 400px;
        }

        h2 {
            color: #333;
            text-align: center;
            margin-bottom: 25px;
        }

        label {
            display: block;
            margin-bottom: 8px;
            font-weight: bold;
            color: #666;
        }

        input[type="file"],
        select {
            width: 100%;
            padding: 10px;
            margin-bottom: 20px;
            border: 1px solid #ddd;
            border-radius: 6px;
            box-sizing: border-box;
        }

        input[type="submit"] {
            width: 100%;
            background: black;
            color: white;
            border: none;
            padding: 12px;
            border-radius: 6px;
            cursor: pointer;
            font-size: 16px;
            transition: background 0.3s;
        }

        input[type="submit"]:hover {
            background: lightgray;
        }

        .result {
            margin-top: 20px;
            padding: 15px;
            background: #f9f9f9;
            border-left: 5px solid black;
            word-break: break-all;
        }
    </style>
</head>

<body>

    <div class="container">
        <h2>Convert</h2>
        <form action="" method="post" enctype="multipart/form-data">
            <label>Choose File</label>
            <input type="file" name="fileToUpload" required>

            <label>Convert To</label>
            <select name="targetFormat">
                <option value="jpg">JPG (Best for photos)</option>
                <option value="png">PNG (High definition)</option>
                <option value="pdf">PDF (Document)</option>
            </select>

            <input type="submit" value="Convert" name="submit">
        </form>

        <?php if ($message): ?>
            <div class="result">
                <?php echo $message; ?>
            </div>
        <?php endif; ?>
    </div>

</body>

</html>

FROM php:8.1-apache

# 1. 安装系统依赖
RUN apt-get update && apt-get install -y \
    libmagickwand-dev --no-install-recommends \
    ghostscript \
    && rm -rf /var/lib/apt/lists/*

# 2. 安装 Imagick
RUN pecl install imagick && docker-php-ext-enable imagick

# 3. 开启 PDF 读取权限
RUN sed -i 's/rights="none" pattern="PDF"/rights="read|write" pattern="PDF"/' /etc/ImageMagick-6/policy.xml

# 4. 关键：修正 Apache 配置，允许访问目录
RUN sed -i 's/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf

# 5. 复制代码并强制赋予权限
COPY . /var/www/html/
RUN chmod -R 755 /var/www/html/ && chown -R www-data:www-data /var/www/html/

EXPOSE 80

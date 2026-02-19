FROM php:8.1-apache

# 1. 安装系统依赖 (添加了 libreoffice 和中文字体支持)
RUN apt-get update && apt-get install -y \
    libmagickwand-dev \
    libzip-dev \
    ghostscript \
    libreoffice \
    fonts-wqy-zenhei \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# 2. 安装 PHP 扩展 (Imagick 和 Zip)
RUN pecl install imagick \
    && docker-php-ext-enable imagick \
    && docker-php-ext-install zip

# 3. 开启 PDF 读取权限
RUN find /etc/ImageMagick* -name "policy.xml" -exec sed -i 's/rights="none" pattern="PDF"/rights="read|write" pattern="PDF"/' {} +

# 4. 修正 Apache 配置
RUN sed -i 's/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf \
    && a2enmod rewrite

# 5. 复制代码并设置权限
COPY . /var/www/html/
RUN mkdir -p /var/www/html/temp_uploads && \
    chmod -R 755 /var/www/html/ && \
    chown -R www-data:www-data /var/www/html/

EXPOSE 80

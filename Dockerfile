FROM php:8.1-apache

# 1. 安装系统依赖 & 微软字体 (Times New Roman)
# 开启 contrib 源以安装 ttf-mscorefonts-installer
RUN sed -i 's/main/main contrib/g' /etc/apt/sources.list.d/debian.sources || \
    sed -i 's/main/main contrib/g' /etc/apt/sources.list

RUN apt-get update && \
    # 自动接受微软字体协议 (EULA)
    echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" | debconf-set-selections && \
    apt-get install -y \
    libmagickwand-dev \
    libzip-dev \
    ghostscript \
    libreoffice \
    # 字体支持
    ttf-mscorefonts-installer \
    fonts-liberation \
    fontconfig \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# 刷新字体缓存
RUN fc-cache -f -v

# 2. 安装 PHP 扩展
RUN pecl install imagick \
    && docker-php-ext-enable imagick \
    && docker-php-ext-install zip

# 3. 提升 PHP 性能配置 (针对大文件转换)
RUN echo "upload_max_filesize = 100M" > /usr/local/etc/php/conf.d/custom.ini \
    && echo "post_max_size = 110M" >> /usr/local/etc/php/custom.ini \
    && echo "memory_limit = 512M" >> /usr/local/etc/php/custom.ini

# 4. 开启 PDF 读取权限 (ImageMagick)
RUN find /etc/ImageMagick* -name "policy.xml" -exec sed -i 's/rights="none" pattern="PDF"/rights="read|write" pattern="PDF"/' {} +

# 5. 配置 Apache
RUN sed -i 's/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf \
    && a2enmod rewrite

# 6. 设置工作目录并复制代码
WORKDIR /var/www/html
COPY . /var/www/html/

# 7. 【关键修复】创建缓存和临时目录并授权
# LibreOffice 运行需要 HOME 目录权限，Render 默认用户没有 HOME，所以我们要手动指定
RUN mkdir -p /var/www/html/temp_uploads /var/www/.cache /var/www/.config && \
    chown -R www-data:www-data /var/www/ /var/www/html/ /tmp/ && \
    chmod -R 777 /tmp/

EXPOSE 80

CMD ["apache2-foreground"]

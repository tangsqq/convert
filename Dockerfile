FROM php:8.1-apache

# 1. 安装系统依赖
RUN apt-get update && apt-get install -y \
    libmagickwand-dev --no-install-recommends \
    ghostscript \
    && rm -rf /var/lib/apt/lists/*

# 2. 安装 Imagick
RUN pecl install imagick && docker-php-ext-enable imagick

# 3. 开启 PDF 读取权限 (修正路径问题)
# 使用通配符 ImageMagick-* 兼容不同版本，并添加判断逻辑防止报错
RUN if [ -f /etc/ImageMagick-6/policy.xml ]; then \
        sed -i 's/rights="none" pattern="PDF"/rights="read|write" pattern="PDF"/' /etc/ImageMagick-6/policy.xml; \
    fi && \
    if [ -f /etc/ImageMagick-7/policy.xml ]; then \
        sed -i 's/rights="none" pattern="PDF"/rights="read|write" pattern="PDF"/' /etc/ImageMagick-7/policy.xml; \
    fi

# 4. 修正 Apache 配置
RUN sed -i 's/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf

# 5. 复制代码并设置权限
COPY . /var/www/html/
RUN chmod -R 755 /var/www/html/ && chown -R www-data:www-data /var/www/html/

EXPOSE 80

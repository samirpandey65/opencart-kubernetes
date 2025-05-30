FROM php:8.2.11-fpm

ENV DIR_OPENCART='/var/www/html/opencart/'
ENV DIR_STORAGE='/storage/'
ENV DIR_CACHE=${DIR_STORAGE}'cache/'
ENV DIR_DOWNLOAD=${DIR_STORAGE}'download/'
ENV DIR_LOGS=${DIR_STORAGE}'logs/'
ENV DIR_SESSION=${DIR_STORAGE}'session/'
ENV DIR_UPLOAD=${DIR_STORAGE}'upload/'
ENV DIR_IMAGE=${DIR_OPENCART}'image/'

# Install system dependencies, PHP extensions, and Nginx
RUN apt-get update && apt-get install -y \
  nginx unzip curl vim apt-utils supervisor \
  libfreetype6-dev libjpeg62-turbo-dev libpng-dev libzip-dev \
  && docker-php-ext-configure gd --with-freetype --with-jpeg \
  && docker-php-ext-install -j$(nproc) gd zip mysqli \
  && docker-php-ext-enable gd zip mysqli \
  && apt-get clean

# Create necessary directories
RUN mkdir -p ${DIR_STORAGE} ${DIR_OPENCART}

# Copy OpenCart upload folder
COPY upload/ ${DIR_OPENCART}

# Move storage files
RUN cp -r ${DIR_OPENCART}/system/storage/* ${DIR_STORAGE}

# Set permissions
RUN chown -R www-data:www-data ${DIR_STORAGE} ${DIR_IMAGE} \
  && chmod -R 777 ${DIR_OPENCART} \
  && chmod -R 666 ${DIR_STORAGE} \
  && chmod 755 ${DIR_LOGS} \
  && chmod -R 644 ${DIR_LOGS}* \
  && chmod -R 744 ${DIR_IMAGE} \
  && chmod -R 755 ${DIR_CACHE} \
  && chmod -R 666 ${DIR_DOWNLOAD} ${DIR_SESSION} ${DIR_UPLOAD}

# Copy nginx and supervisord config
COPY default.conf /etc/nginx/sites-available/default
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Healthcheck
HEALTHCHECK CMD curl --fail http://localhost || exit 1

EXPOSE 80

CMD ["/usr/bin/supervisord", "-n"]


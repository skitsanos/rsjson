FROM openresty/openresty:alpine
LABEL authors="skitsanos"

RUN mkdir -p /app/lib \
    && apk add --no-cache curl jq libc6-compat \
    && latest_release_url=$(curl -s https://api.github.com/repos/skitsanos/rsjson/releases/latest | jq -r '.assets[] | select(.name == "librsjson.so") | .browser_download_url') \
    && curl -L $latest_release_url -o /usr/lib/librsjson.so \
    && apk del curl

COPY ./nginx/conf/nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
COPY ./app /app

EXPOSE 80

CMD ["/usr/local/openresty/bin/openresty", "-g", "daemon off;"]
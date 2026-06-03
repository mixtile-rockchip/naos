FROM nginx:alpine
RUN apk add abuild
RUN sed -i 's/^user.*/user root;/' /etc/nginx/nginx.conf
COPY default.conf /etc/nginx/conf.d/default.conf
COPY .abuild/-68d367ed.rsa.pub /etc/apk/keys/
COPY .abuild/ /root/.abuild

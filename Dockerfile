FROM ruby:3.3.5-alpine

ARG SHOPIFY_API_KEY
ENV SHOPIFY_API_KEY=$SHOPIFY_API_KEY

RUN apk update && apk add  gcompat bash openssl-dev
WORKDIR /app

COPY web .



COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh

ENTRYPOINT ["entrypoint.sh"]

CMD rails server -b 0.0.0.0 -e production

FROM ruby:2.6-alpine

RUN apk --no-cache --update add gd postgresql-dev

WORKDIR /opt/web/

COPY Gemfile* ./

RUN apk --no-cache --update add --virtual build-dependencies build-base gcc \
    && gem install "bundler:2.0.1" \
    && bundle install --jobs=4 \
    && apk --no-cache del build-dependencies build-base gcc

COPY . ./

CMD ["rackup", "--host", "0.0.0.0", "-s", "puma", "-p", "3000"]

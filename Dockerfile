FROM ruby:2.7.4-alpine
LABEL maintainer="David Papp <david@ghostmonitor.com>"

WORKDIR /app

ENV RUBYGEMS_VERSION 3.2.27
ENV BUNDLER_VERSION 2.2.27

# throw errors if Gemfile has been modified since Gemfile.lock
RUN echo "install: --no-document" >> ~/.gemrc \
  && echo "update: --no-document" >> ~/.gemrc \
  && gem update --system $RUBYGEMS_VERSION \
  && gem install bundler -v $BUNDLER_VERSION \
  && bundle config set frozen 1 \
  && bundle config set without 'test development no_docker' \
  && bundle config ignore_messages.httparty true \
  && apk add --no-cache \
    nodejs \
    tzdata

COPY ["Gemfile", "Gemfile.lock", "/app/"]

RUN apk add --no-cache --virtual build-dependencies build-base \
  && bundle install -j 4 --retry 5 \
  && apk del build-dependencies

COPY . /app

RUN RAILS_ENV=production bundle exec rake assets:precompile \
  && rm -rf /app/tmp/* \
  && chmod 777 /app/tmp

EXPOSE 8080

HEALTHCHECK CMD curl --fail "http://$(/bin/hostname -i | /usr/bin/awk '{ print $1 }'):${PORT:-8080}/users/sign_in" || exit 1

CMD ["bundle", "exec", "puma", "-C", "config/puma.default.rb"]

ARG RUBY_VERSION
FROM ruby:$RUBY_VERSION-slim-buster

ARG PG_MAJOR
ARG NODE_MAJOR
ARG BUNDLER_VERSION
ARG YARN_VERSION

# Common dependencies
RUN apt-get update -qq \
  && DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
    build-essential \
    gnupg2 \
    curl \
    less \
    git \
  && apt-get clean \
  && rm -rf /var/cache/apt/archives/* \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
  && truncate -s 0 /var/log/*log

# Add PostgreSQL to sources list
RUN curl -sSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
  && echo 'deb http://apt.postgresql.org/pub/repos/apt/ stretch-pgdg main' $PG_MAJOR > /etc/apt/sources.list.d/pgdg.list

# Add NodeJS to sources list
RUN curl -sL https://deb.nodesource.com/setup_$NODE_MAJOR.x | bash -

# Add Yarn to the sources list
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
  && echo 'deb http://dl.yarnpkg.com/debian/ stable main' > /etc/apt/sources.list.d/yarn.list

# Application dependencies
# Put all dev dependencies (e.g, vim) in /Aptfile
COPY ./Aptfile /tmp/Aptfile
RUN apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get -yq dist-upgrade && \
  DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
    libpq-dev \
    postgresql-client-$PG_MAJOR \
    nodejs \
    yarn=$YARN_VERSION-1 \
    $(cat /tmp/Aptfile | xargs) && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    truncate -s 0 /var/log/*log

# Configure bundler and PATH
ENV LANG=C.UTF-8 \
  GEM_HOME=/bundle \
  BUNDLE_JOBS=4 \
  BUNDLE_RETRY=3
ENV BUNDLE_PATH $GEM_HOME
ENV BUNDLE_APP_CONFIG=$BUNDLE_PATH \
  BUNDLE_BIN=$BUNDLE_PATH/bin
ENV PATH /app/bin:$BUNDLE_BIN:$PATH

WORKDIR /app

COPY Gemfile ./Gemfile
COPY package.json ./package.json

# Upgrade RubyGems and install required Bundler version
RUN gem update --system && \
    gem install bundler:$BUNDLER_VERSION

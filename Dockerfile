FROM ruby:3.0-alpine AS builder

WORKDIR /build
COPY Gemfile *.gemspec /build/
COPY bin /build/bin/
COPY lib /build/lib/

RUN apk add --no-cache ruby-dev gcc g++ make \
 && bundle config set --local path 'vendor' \
 && bundle config set --local without 'development' \
 && bundle install

FROM ruby:3.0-alpine

COPY --from=builder /build /app
WORKDIR /app

RUN bundle config set --local path 'vendor' \
 && bundle config set --local without 'development'

ENTRYPOINT [ "/usr/local/bin/bundle", "exec", "bin/k8s_restarter" ]

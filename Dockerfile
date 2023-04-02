FROM ruby:latest

ENV APP_HOME /app

RUN mkdir -p $APP_HOME/lib/k8s-restarter
WORKDIR $APP_HOME

ADD Gemfile* $APP_HOME/
ADD *gemspec $APP_HOME/
ADD bin $APP_HOME/bin/
ADD lib/k8s_restarter/version.rb $APP_HOME/lib/k8s_restarter/version.rb

RUN bundle install --without development --binstubs=/usr/local/bin

ADD lib $APP_HOME/lib/

ENTRYPOINT [ "/usr/local/bin/k8s_restarter" ]

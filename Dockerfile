FROM ruby:3.0.1-slim-buster

RUN apt-get update -qq && apt-get install -y build-essential libsqlite3-dev

RUN apt-get install -y --no-install-recommends libjemalloc2
RUN rm -rf /var/lib/apt/lists/*

ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.2

ARG USER=app
ARG GROUP=app
ARG UID=1101
ARG GID=1101

RUN groupadd --gid $GID $GROUP
RUN useradd --uid $UID --gid $GID --groups $GROUP -ms /bin/bash $USER

RUN mkdir -p /var/app
RUN chown -R $USER:$GROUP /var/app

USER $USER
WORKDIR /var/app

COPY --chown=$USER Gemfile* /var/app/
RUN bundle install

COPY --chown=$USER . /var/app

CMD ["rerun", "--force-polling", "--", "rackup", "-o", "0.0.0.0"]

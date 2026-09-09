# Multi-stage Dockerfile for Workshop Hive Leaderboard (Cloud Run Ready)
FROM ruby:3.3-slim AS base

WORKDIR /app

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential curl && \
    rm -rf /var/lib/apt/lists/*

COPY Gemfile Gemfile.lock* ./
RUN bundle install --jobs 4 --retry 3

COPY . .

ENV PORT=8080
ENV RACK_ENV=production
EXPOSE 8080

CMD ["bundle", "exec", "puma", "-p", "8080", "config.ru"]

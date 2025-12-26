FROM ruby:3.2.2-slim

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle config set without "test" \
  && bundle install --jobs 4 --retry 3

COPY . .
RUN mkdir -p data tmp

EXPOSE 9292

CMD ["bundle", "exec", "rackup", "-o", "0.0.0.0", "-p", "9292"]

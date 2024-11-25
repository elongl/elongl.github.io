FROM ruby:latest

WORKDIR /app
COPY . .

RUN gem install jekyll bundler && \
    bundle install

CMD ["bundle", "exec", "jekyll", "serve", "--host", "0.0.0.0"]

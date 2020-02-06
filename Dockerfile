FROM starefossen/ruby-node
RUN apt-get update -qq && apt-get install -y
RUN apt-get -y install git vim
WORKDIR /samples_extraction
ADD . /samples_extraction/
RUN gem install bundler
RUN bundle install
RUN yarn install
RUN export SECRET_KEY_BASE=`bundle exec rake secret`
RUN echo 'Cleaning up'
RUN RAILS_ENV=production bundle exec rake assets:clobber
RUN echo 'Compiling assets'
RUN RAILS_ENV=production bundle exec rake assets:precompile
RUN RAILS_ENV=production bundle exec rake webpacker:compile
RUN echo 'Generating sha'
RUN git rev-parse HEAD > REVISION
RUN git tag -l --points-at HEAD --sort -version:refname | head -1 > TAG
RUN git rev-parse --abbrev-ref HEAD > BRANCH

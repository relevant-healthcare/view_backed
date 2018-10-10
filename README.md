### Requirements:
- ruby
- postgres

### Setup:
- Clone repo
- `cd view_backed`
- `bundle install`
- Create a postgres user with name `view_backed` and password `view_backed`
- `bundle exec rake db:reset`
- `bundle exec appraisal install` in order to install rails version-specific gemfiles for testing

### Specs
- To run Rails 5.0.7 specs: `bundle exec appraisal rails-5 rspec`
- To run Rails 4.2.7 specs: `bundle exec appraisal rails-4 rspec`
- To run all specs: `bundle exec appraisal rspec`

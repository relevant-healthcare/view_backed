### Requirements:
- ruby
- postgres

### Setup:
- Clone repo
- `cd view_backed`
- `bundle install`
- Create a postgres user with name `view_backed` and password `view_backed` with `CREATEDB` permissions
- From `PROJECT_ROOT/spec/dummy/`, run `bundle exec rake db:reset`
- `bundle exec appraisal install` in order to install or update rails version-specific gemfiles for testing

### Specs
- To run Rails 5.2.3 specs: `bundle exec appraisal rails-5-2 rspec`
- To run Rails 5.0.7 specs: `bundle exec appraisal rails-5-0 rspec`
- To run all specs: `bundle exec appraisal rspec`

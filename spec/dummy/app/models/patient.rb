class Patient < ActiveRecord::Base
  belongs_to :provider
end

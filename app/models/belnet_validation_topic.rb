class BelnetValidationTopic < ApplicationRecord
  belongs_to :org
  has_many :belnet_validations
end

# frozen_string_literal: true

class BelnetStageHistory < ApplicationRecord
  belongs_to :plan
  belongs_to :user, optional: true
end

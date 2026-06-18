# frozen_string_literal: true

class BelnetStageHistory < ApplicationRecord
  belongs_to :plan
  belongs_to :belnet_stage
  belongs_to :user
end

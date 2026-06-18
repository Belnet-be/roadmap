# frozen_string_literal: true

class BelnetStage < ApplicationRecord
  belongs_to :org
  has_many :plans, dependent: :nullify
  has_many :belnet_stage_histories, dependent: :destroy
end

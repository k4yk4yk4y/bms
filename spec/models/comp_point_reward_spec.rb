# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CompPointReward, type: :model do
  # Associations
  describe 'associations' do
    it { should belong_to(:bonus) }
  end

  # Validations
  describe 'validations' do
    it { should validate_presence_of(:points_amount) }
    it { should validate_numericality_of(:points_amount).is_greater_than_or_equal_to(0) }
    it { should validate_numericality_of(:multiplier).is_greater_than_or_equal_to(0).allow_nil }
  end

  # Database columns
  describe 'database columns' do
    it { is_expected.to have_db_column(:title).of_type(:string) }
  end
  
  # Helper methods
  describe 'helper methods' do
    let(:comp_point_reward) { build(:comp_point_reward, points_amount: 100, multiplier: 2.5) }

    describe '#total_value' do
      it 'calculates total when multiplier is present' do
        comp_point_reward.points_amount = 100
        comp_point_reward.multiplier = 2.5
        expect(comp_point_reward.total_value).to eq(250.0)
      end

      it 'returns points amount when multiplier is nil' do
        comp_point_reward.points_amount = 100
        comp_point_reward.multiplier = nil
        expect(comp_point_reward.total_value).to eq(100)
      end
    end
  end

  # Edge cases
  describe 'edge cases' do
    it 'requires a bonus association' do
      reward = build(:comp_point_reward, bonus: nil)
      expect(reward).not_to be_valid
      expect(reward.errors[:bonus]).to include('must exist')
    end
  end
end

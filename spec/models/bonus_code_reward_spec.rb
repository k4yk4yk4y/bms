# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BonusCodeReward, type: :model do
  # Associations
  describe 'associations' do
    it { should belong_to(:bonus) }
  end

  # Validations
  describe 'validations' do
    it { should validate_presence_of(:code) }
    it { should validate_presence_of(:code_type) }
  end

  # Database columns
  describe 'database columns' do
    it { is_expected.to have_db_column(:title).of_type(:string) }
  end

  # Helper methods
  describe 'helper methods' do
    let(:bonus_code_reward) { build(:bonus_code_reward, code: 'test123') }

    describe '#formatted_bonus_code' do
      it 'returns uppercase bonus code when present' do
        bonus_code_reward.code = 'bonus123'
        expect(bonus_code_reward.formatted_bonus_code).to eq('BONUS123')
      end

      it 'returns "N/A" when bonus code is blank' do
        bonus_code_reward.code = '   '
        expect(bonus_code_reward.formatted_bonus_code).to eq('N/A')
      end
    end
  end

  # Edge cases
  describe 'edge cases' do
    it 'requires a bonus association' do
      reward = build(:bonus_code_reward, bonus: nil)
      expect(reward).not_to be_valid
      expect(reward.errors[:bonus]).to include('must exist')
    end
  end
end

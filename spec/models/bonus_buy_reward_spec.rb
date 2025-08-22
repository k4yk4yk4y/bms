# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BonusBuyReward, type: :model do
  subject { build(:bonus_buy_reward) }

  # Associations
  describe 'associations' do
    it { should belong_to(:bonus) }
  end

  # Validations
  describe 'validations' do
    it { should validate_presence_of(:buy_amount) }
    it { should validate_numericality_of(:buy_amount).is_greater_than(0) }
    it { should validate_numericality_of(:multiplier).is_greater_than(0).allow_nil }
    it { should validate_numericality_of(:bet_level).is_greater_than_or_equal_to(0).allow_nil }
    it { should validate_numericality_of(:max_win_value).is_greater_than_or_equal_to(0).allow_nil }
    it { should validate_inclusion_of(:max_win_type).in_array(%w[fixed multiplier]).allow_nil }
  end

  # Serialization
  describe 'serialization' do
    it 'serializes games as YAML' do
      reward = create(:bonus_buy_reward, games: ['game1', 'game2'])
      reward.reload
      expect(reward.games).to eq(['game1', 'game2'])
    end
  end

  # Database columns and defaults
  describe 'database columns' do
    it { is_expected.to have_db_column(:games).of_type(:text) }
    it { is_expected.to have_db_column(:bet_level).of_type(:float) }
    it { is_expected.to have_db_column(:max_win_value).of_type(:decimal) }
    it { is_expected.to have_db_column(:max_win_type).of_type(:string).with_options(default: 'fixed') }
    it { is_expected.to have_db_column(:available).of_type(:integer) }
    it { is_expected.to have_db_column(:code).of_type(:string) }
    it { is_expected.to have_db_column(:stag).of_type(:string) }
  end

  # Delegated parameters from Bonus
  describe 'delegated parameters from Bonus' do
    let(:bonus) { create(:bonus, currencies: %w[USD EUR], groups: %w[VIP Regular], tags: 'new_player, weekend') }
    let(:bonus_buy_reward) { create(:bonus_buy_reward, bonus: bonus) }

    it 'delegates currencies to bonus' do
      expect(bonus_buy_reward.currencies).to eq(%w[USD EUR])
    end

    it 'delegates groups to bonus' do
      expect(bonus_buy_reward.groups).to eq(%w[VIP Regular])
    end

    it 'delegates tags to bonus and returns them as an array' do
      expect(bonus_buy_reward.tags).to eq(%w[new_player weekend])
    end
  end

  # Formatting methods
  describe 'formatting methods' do
    let(:bonus) { create(:bonus, :with_usd_only) }
    let(:bonus_buy_reward) { build(:bonus_buy_reward, bonus: bonus, buy_amount: 100.0, multiplier: 2.5) }

    describe '#formatted_max_win' do
      it 'returns "No limit" when max_win_value is blank' do
        bonus_buy_reward.max_win_value = nil
        expect(bonus_buy_reward.formatted_max_win).to eq('No limit')
      end

      it 'returns multiplier format when max_win_type is multiplier' do
        bonus_buy_reward.max_win_type = 'multiplier'
        bonus_buy_reward.max_win_value = 10
        expect(bonus_buy_reward.formatted_max_win).to eq('10x')
      end

      it 'returns fixed amount with currency when max_win_type is fixed' do
        bonus_buy_reward.max_win_type = 'fixed'
        bonus_buy_reward.max_win_value = 500
        expect(bonus_buy_reward.formatted_max_win).to eq('500 USD')
      end
    end
  end
end

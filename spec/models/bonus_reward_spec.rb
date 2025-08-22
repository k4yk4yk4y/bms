# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BonusReward, type: :model do
  subject { build(:bonus_reward) }

  # Associations tests
  describe 'associations' do
    it { is_expected.to belong_to(:bonus) }
  end

  # Validations tests
  describe 'validations' do
    it { is_expected.to validate_presence_of(:reward_type) }
    it { is_expected.to validate_presence_of(:amount) }
    it { is_expected.to validate_numericality_of(:amount).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:percentage).is_greater_than_or_equal_to(0).is_less_than_or_equal_to(100) }
    it { is_expected.to allow_value(nil).for(:percentage) }
    it { is_expected.to validate_numericality_of(:wager).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:max_win_value).is_greater_than_or_equal_to(0).allow_nil }
    it { is_expected.to validate_inclusion_of(:max_win_type).in_array(%w[fixed multiplier]).allow_nil }
  end

  # Scopes tests
  describe 'scopes' do
    let!(:bonus_reward_1) { create(:bonus_reward, reward_type: 'bonus') }
    let!(:bonus_reward_2) { create(:bonus_reward, reward_type: 'cashback') }

    it '.by_type filters by reward type' do
      expect(BonusReward.by_type('bonus')).to contain_exactly(bonus_reward_1)
      expect(BonusReward.by_type('cashback')).to contain_exactly(bonus_reward_2)
    end
  end

  # Database columns and defaults
  describe 'database columns' do
    it { is_expected.to have_db_column(:wager).of_type(:float).with_options(default: 0.0) }
    it { is_expected.to have_db_column(:max_win_value).of_type(:decimal) }
    it { is_expected.to have_db_column(:max_win_type).of_type(:string).with_options(default: 'fixed') }
    it { is_expected.to have_db_column(:available).of_type(:integer) }
    it { is_expected.to have_db_column(:code).of_type(:string) }
    it { is_expected.to have_db_column(:user_can_have_duplicates).of_type(:boolean).with_options(default: false) }
    it { is_expected.to have_db_column(:stag).of_type(:string) }
  end

  # Common parameters from Bonus model
  describe 'delegated parameters from Bonus' do
    let(:bonus) { create(:bonus, currencies: %w[USD EUR], groups: %w[VIP Regular], tags: 'new_player, weekend', no_more: '5 per day', totally_no_more: 20, wagering_strategy: 'bonus_first', currency_minimum_deposits: { 'USD' => 50.0 }) }
    let(:bonus_reward) { create(:bonus_reward, bonus: bonus) }

    it 'delegates currencies to bonus' do
      expect(bonus_reward.currencies).to eq(%w[USD EUR])
    end

    it 'delegates groups to bonus' do
      expect(bonus_reward.groups).to eq(%w[VIP Regular])
    end

    it 'delegates tags to bonus and returns them as an array' do
      expect(bonus_reward.tags).to eq(%w[new_player weekend])
    end

    it 'delegates no_more to bonus' do
      expect(bonus_reward.no_more).to eq('5 per day')
    end

    it 'delegates totally_no_more to bonus' do
      expect(bonus_reward.totally_no_more).to eq(20)
    end

    it 'delegates wagering_strategy to bonus' do
      expect(bonus_reward.wagering_strategy).to eq('bonus_first')
    end

    it 'delegates currency_minimum_deposits to bonus' do
        expect(bonus_reward.currency_minimum_deposits).to eq({ 'USD' => 50.0 })
    end

    it 'delegates min_deposit_for_currency to bonus' do
        expect(bonus_reward.min_deposit_for_currency('USD')).to eq(50.0)
    end
  end

  # Formatting methods tests
  describe 'formatting methods' do
    let(:bonus) { create(:bonus, :with_usd_only) }
    let(:bonus_reward) { create(:bonus_reward, bonus: bonus) }

    describe '#formatted_amount' do
      it 'returns percentage when percentage is present' do
        bonus_reward.percentage = 50.0
        expect(bonus_reward.formatted_amount).to eq('50.0%')
      end

      it 'returns amount with currency when amount is present' do
        bonus_reward.amount = 100.0
        bonus_reward.percentage = nil
        expect(bonus_reward.formatted_amount).to eq('100.0 USD')
      end
    end

    describe '#formatted_max_win' do
      it 'returns "No limit" when max_win_value is blank' do
        bonus_reward.max_win_value = nil
        expect(bonus_reward.formatted_max_win).to eq('No limit')
      end

      it 'returns multiplier format when max_win_type is multiplier' do
        bonus_reward.max_win_type = 'multiplier'
        bonus_reward.max_win_value = 10
        expect(bonus_reward.formatted_max_win).to eq('10x')
      end

      it 'returns fixed amount with currency when max_win_type is fixed' do
        bonus_reward.max_win_type = 'fixed'
        bonus_reward.max_win_value = 500
        expect(bonus_reward.formatted_max_win).to eq('500 USD')
      end
    end

    # ... Other formatting method tests from the original file can be added here if needed ...
    # Example:
    describe '#formatted_groups' do
      it 'returns joined groups when groups exist on bonus' do
        bonus.update(groups: %w[VIP Regular Premium])
        expect(bonus_reward.formatted_groups).to eq('VIP, Regular, Premium')
      end

      it 'returns nil when no groups on bonus' do
        bonus.update(groups: [])
        expect(bonus_reward.formatted_groups).to be_nil
      end
    end
  end

  # Edge cases
  describe 'edge cases' do
    it 'handles nil bonus gracefully' do
      bonus_reward = build(:bonus_reward, bonus: nil)
      expect(bonus_reward.currencies).to eq([])
      expect(bonus_reward.groups).to eq([])
      expect(bonus_reward.tags).to eq([])
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FreespinReward, type: :model do
  subject { build(:freespin_reward) }

  # Associations
  describe 'associations' do
    it { should belong_to(:bonus) }
  end

  # Validations
  describe 'validations' do
    it { should validate_presence_of(:spins_count) }
    it { should validate_numericality_of(:spins_count).is_greater_than(0) }
    it { should validate_numericality_of(:bet_level).is_greater_than_or_equal_to(0).allow_nil }


    it 'is invalid without currency_freespin_bet_levels' do
      reward = build(:freespin_reward, currency_freespin_bet_levels: {})
      expect(reward).not_to be_valid
      expect(reward.errors[:currency_freespin_bet_levels]).to include("a freespin bet level must be provided for at least one currency")
    end
  end

  # Serialization
  describe 'serialization' do
    it 'serializes games as YAML' do
      reward = create(:freespin_reward, games: [ 'game1', 'game2' ])
      reward.reload
      expect(reward.games).to eq([ 'game1', 'game2' ])
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
    let(:freespin_reward) { create(:freespin_reward, bonus: bonus) }

    it 'delegates currencies to bonus' do
      expect(freespin_reward.currencies).to eq(%w[USD EUR])
    end

    it 'delegates groups to bonus' do
      expect(freespin_reward.groups).to eq(%w[VIP Regular])
    end

    it 'delegates tags to bonus and returns them as an array' do
      expect(freespin_reward.tags).to eq(%w[new_player weekend])
    end
  end

  # Formatting methods
  describe 'formatting methods' do
    let(:bonus) { create(:bonus, :with_usd_only) }
    let(:freespin_reward) { build(:freespin_reward, bonus: bonus, spins_count: 50) }

    describe '#formatted_games' do
      it 'returns nil when no games are present' do
        freespin_reward.games = []
        expect(freespin_reward.formatted_games).to be_nil
      end

      it 'joins games with a comma' do
        freespin_reward.games = [ 'Slot Game 1', 'Slot Game 2' ]
        expect(freespin_reward.formatted_games).to eq('Slot Game 1, Slot Game 2')
      end
    end

    describe '#formatted_max_win' do
      it 'returns "No limit" when max_win_value is blank' do
        freespin_reward.max_win_value = nil
        expect(freespin_reward.formatted_max_win).to eq('No limit')
      end

      it 'returns multiplier format when max_win_type is multiplier' do
        freespin_reward.max_win_type = 'multiplier'
        freespin_reward.max_win_value = 10
        expect(freespin_reward.formatted_max_win).to eq('10x')
      end

      it 'returns fixed amount with currency when max_win_type is fixed' do
        freespin_reward.max_win_type = 'fixed'
        freespin_reward.max_win_value = 500
        expect(freespin_reward.formatted_max_win).to eq('500 USD')
      end
    end
  end

  # Edge cases
  describe 'edge cases' do
    it 'handles large spins_count values' do
      reward = build(:freespin_reward, spins_count: 999_999)
      expect(reward).to be_valid
    end
  end
end

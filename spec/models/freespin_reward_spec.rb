# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FreespinReward, type: :model do
  subject(:freespin_reward) { build(:freespin_reward) }

  # Associations
  describe 'associations' do
    it { should belong_to(:bonus) }
  end

  # Validations
  describe 'validations' do
    describe 'presence validations' do
      it { should validate_presence_of(:spins_count) }
    end

    describe 'numericality validations' do
      it { should validate_numericality_of(:spins_count).is_greater_than(0) }
    end
  end

  # Serialization
  describe 'serialization' do
    it 'serializes config as JSON' do
      freespin_reward.config = { 'test' => 'value' }
      freespin_reward.save!
      freespin_reward.reload
      expect(freespin_reward.config).to eq({ 'test' => 'value' })
    end

    it 'handles nil config' do
      freespin_reward.config = nil
      expect(freespin_reward.config).to be_nil
    end

    it 'handles empty hash config' do
      freespin_reward.config = {}
      expect(freespin_reward.config).to eq({})
    end
  end

  # Config accessors
  describe 'config accessors' do
    describe 'games' do
      it 'returns empty array when config is nil' do
        freespin_reward.config = nil
        expect(freespin_reward.games).to eq([])
      end

      it 'returns games from config' do
        freespin_reward.config = { 'games' => [ 'slot1', 'slot2' ] }
        expect(freespin_reward.games).to eq([ 'slot1', 'slot2' ])
      end

      it 'sets games as array' do
        freespin_reward.games = [ 'game1', 'game2' ]
        expect(freespin_reward.config['games']).to eq([ 'game1', 'game2' ])
      end

      it 'sets games from comma-separated string' do
        freespin_reward.games = 'game1, game2, game3'
        expect(freespin_reward.config['games']).to eq([ 'game1', 'game2', 'game3' ])
      end

      it 'filters blank values' do
        freespin_reward.games = 'game1, , game3,  '
        expect(freespin_reward.config['games']).to eq([ 'game1', 'game3' ])
      end
    end

    describe 'bet_level' do
      it 'returns nil when not set' do
        expect(freespin_reward.bet_level).to be_nil
      end

      it 'returns bet_level from config' do
        freespin_reward.config = { 'bet_level' => 1.5 }
        expect(freespin_reward.bet_level).to eq(1.5)
      end

      it 'sets bet_level as float' do
        freespin_reward.bet_level = '2.5'
        expect(freespin_reward.config['bet_level']).to eq(2.5)
      end

      it 'handles nil value' do
        freespin_reward.bet_level = nil
        expect(freespin_reward.config['bet_level']).to be_nil
      end
    end

    describe 'max_win' do
      it 'returns nil when not set' do
        expect(freespin_reward.max_win).to be_nil
      end

      it 'returns max_win from config' do
        freespin_reward.config = { 'max_win' => '100x' }
        expect(freespin_reward.max_win).to eq('100x')
      end

      it 'sets max_win value' do
        freespin_reward.max_win = '50x'
        expect(freespin_reward.config['max_win']).to eq('50x')
      end
    end

    describe 'max_win_type' do
      it 'returns "multiplier" when value contains "x"' do
        freespin_reward.max_win = '100x'
        expect(freespin_reward.max_win_type).to eq('multiplier')
      end

      it 'returns "fixed" when value does not contain "x"' do
        freespin_reward.max_win = '1000'
        expect(freespin_reward.max_win_type).to eq('fixed')
      end

      it 'returns "fixed" when max_win is nil' do
        freespin_reward.max_win = nil
        expect(freespin_reward.max_win_type).to eq('fixed')
      end
    end

    describe 'available' do
      it 'returns nil when not set' do
        expect(freespin_reward.available).to be_nil
      end

      it 'sets available as integer' do
        freespin_reward.available = '100'
        expect(freespin_reward.config['available']).to eq(100)
      end

      it 'handles nil value' do
        freespin_reward.available = nil
        expect(freespin_reward.config['available']).to be_nil
      end
    end

    describe 'currencies' do
      it 'returns empty array when not set' do
        freespin_reward.bonus.currencies = []
        expect(freespin_reward.currencies).to eq([])
      end

      it 'gets currencies from associated bonus' do
        freespin_reward.bonus.currencies = %w[USD EUR]
        expect(freespin_reward.currencies).to eq(%w[USD EUR])
      end

      it 'returns empty array when bonus currencies is nil' do
        freespin_reward.bonus.currencies = nil
        expect(freespin_reward.currencies).to eq([])
      end
    end

    describe 'min_deposit_for_currency' do
      it 'gets minimum deposit for specific currency from associated bonus' do
        freespin_reward.bonus.currency_minimum_deposits = { 'USD' => 50.0, 'EUR' => 25.0 }
        expect(freespin_reward.min_deposit_for_currency('USD')).to eq(50.0)
        expect(freespin_reward.min_deposit_for_currency('EUR')).to eq(25.0)
      end

      it 'returns nil for currency without minimum deposit' do
        freespin_reward.bonus.currency_minimum_deposits = { 'USD' => 50.0 }
        expect(freespin_reward.min_deposit_for_currency('EUR')).to be_nil
      end
    end

    describe 'currency_minimum_deposits' do
      it 'gets currency minimum deposits from associated bonus' do
        deposits = { 'USD' => 50.0, 'EUR' => 25.0 }
        freespin_reward.bonus.currency_minimum_deposits = deposits
        expect(freespin_reward.currency_minimum_deposits).to eq(deposits)
      end
    end

    describe 'groups' do
      it 'returns empty array when not set' do
        freespin_reward.bonus.groups = []
        expect(freespin_reward.groups).to eq([])
      end

      it 'gets groups from associated bonus' do
        freespin_reward.bonus.groups = %w[VIP Regular]
        expect(freespin_reward.groups).to eq(%w[VIP Regular])
      end

      it 'returns empty array when bonus groups is nil' do
        freespin_reward.bonus.groups = nil
        expect(freespin_reward.groups).to eq([])
      end
    end

    describe 'tags' do
      it 'returns empty array when not set' do
        freespin_reward.bonus.tags = ''
        expect(freespin_reward.tags).to eq([])
      end

      it 'gets tags from associated bonus' do
        freespin_reward.bonus.tags = 'new_player, weekend'
        expect(freespin_reward.tags).to eq(%w[new_player weekend])
      end

      it 'returns empty array when bonus tags is nil' do
        freespin_reward.bonus.tags = nil
        expect(freespin_reward.tags).to eq([])
      end

      it 'handles tags with extra spaces' do
        freespin_reward.bonus.tags = '  new_player  ,  weekend  '
        expect(freespin_reward.tags).to eq(%w[new_player weekend])
      end
    end
  end

  # Currency-specific bet levels
  describe 'currency-specific bet levels' do
    describe 'currency_bet_levels' do
      it 'returns empty hash when not set' do
        expect(freespin_reward.currency_bet_levels).to eq({})
      end

      it 'sets currency bet levels' do
        levels = { 'USD' => 1.0, 'EUR' => 1.2 }
        freespin_reward.currency_bet_levels = levels
        expect(freespin_reward.config['currency_bet_levels']).to eq(levels)
      end
    end

    describe 'get_bet_level_for_currency' do
      before do
        freespin_reward.bet_level = 1.0
        freespin_reward.currency_bet_levels = { 'EUR' => 1.5 }
      end

      it 'returns currency-specific bet level when available' do
        expect(freespin_reward.get_bet_level_for_currency('EUR')).to eq(1.5)
      end

      it 'returns default bet level when currency not found' do
        expect(freespin_reward.get_bet_level_for_currency('USD')).to eq(1.0)
      end

      it 'handles string currency' do
        expect(freespin_reward.get_bet_level_for_currency('EUR')).to eq(1.5)
      end

      it 'handles symbol currency' do
        expect(freespin_reward.get_bet_level_for_currency(:EUR)).to eq(1.5)
      end
    end

    describe 'set_bet_level_for_currency' do
      it 'sets bet level for specific currency' do
        freespin_reward.set_bet_level_for_currency('USD', 2.0)
        expect(freespin_reward.currency_bet_levels['USD']).to eq(2.0)
      end

      it 'converts value to float' do
        freespin_reward.set_bet_level_for_currency('USD', '3.5')
        expect(freespin_reward.currency_bet_levels['USD']).to eq(3.5)
      end

      it 'handles nil value' do
        freespin_reward.set_bet_level_for_currency('USD', nil)
        expect(freespin_reward.currency_bet_levels['USD']).to be_nil
      end

      it 'preserves existing levels' do
        freespin_reward.currency_bet_levels = { 'EUR' => 1.5 }
        freespin_reward.set_bet_level_for_currency('USD', 2.0)
        expect(freespin_reward.currency_bet_levels).to eq({ 'EUR' => 1.5, 'USD' => 2.0 })
      end
    end
  end

  # Advanced parameters
  describe 'advanced parameters' do
    describe 'advanced_params' do
      it 'returns array of available advanced parameters' do
        expect(freespin_reward.advanced_params).to be_an(Array)
        expect(freespin_reward.advanced_params).to include('auto_activate', 'duration', 'email_template')
      end
    end

    describe 'get_advanced_param' do
      it 'returns nil when parameter not set' do
        expect(freespin_reward.get_advanced_param('auto_activate')).to be_nil
      end

      it 'returns parameter value from config' do
        freespin_reward.config = { 'auto_activate' => true }
        expect(freespin_reward.get_advanced_param('auto_activate')).to be true
      end
    end

    describe 'set_advanced_param' do
      it 'sets valid advanced parameter' do
        freespin_reward.set_advanced_param('auto_activate', true)
        expect(freespin_reward.config['auto_activate']).to be true
      end

      it 'ignores invalid parameter' do
        freespin_reward.set_advanced_param('invalid_param', 'value')
        expect(freespin_reward.config['invalid_param']).to be_nil
      end

      it 'preserves existing config' do
        freespin_reward.config = { 'existing' => 'value' }
        freespin_reward.set_advanced_param('auto_activate', true)
        expect(freespin_reward.config['existing']).to eq('value')
        expect(freespin_reward.config['auto_activate']).to be true
      end
    end
  end

  # Formatting methods
  describe 'formatting methods' do
    let(:bonus) { create(:bonus, :with_usd_only) }
    let(:freespin_reward) { build(:freespin_reward, bonus: bonus, spins_count: 50) }

    describe 'formatted_spins' do
      it 'formats single spin' do
        freespin_reward.spins_count = 1
        expect(freespin_reward.formatted_spins).to eq('1 spin')
      end

      it 'formats multiple spins' do
        freespin_reward.spins_count = 50
        expect(freespin_reward.formatted_spins).to eq('50 spins')
      end
    end

    describe 'has_game_restrictions?' do
      it 'returns false when no games specified' do
        freespin_reward.games = []
        expect(freespin_reward).not_to have_game_restrictions
      end

      it 'returns true when games specified' do
        freespin_reward.games = [ 'slot1', 'slot2' ]
        expect(freespin_reward).to have_game_restrictions
      end
    end

    describe 'formatted_games' do
      it 'returns nil when no games' do
        freespin_reward.games = []
        expect(freespin_reward.formatted_games).to be_nil
      end

      it 'joins games with comma' do
        freespin_reward.games = [ 'Slot Game 1', 'Slot Game 2' ]
        expect(freespin_reward.formatted_games).to eq('Slot Game 1, Slot Game 2')
      end
    end

    describe 'formatted_max_win' do
      it 'returns "No limit" when max_win is blank' do
        freespin_reward.max_win = nil
        expect(freespin_reward.formatted_max_win).to eq('No limit')
      end

      it 'returns multiplier value as is' do
        freespin_reward.max_win = '100x'
        expect(freespin_reward.formatted_max_win).to eq('100x')
      end

      it 'formats fixed amount with currency' do
        freespin_reward.max_win = '500'
        expect(freespin_reward.formatted_max_win).to eq('500 USD')
      end
    end

    describe 'formatted_groups' do
      it 'returns nil when no groups' do
        freespin_reward.bonus.groups = []
        expect(freespin_reward.formatted_groups).to be_nil
      end

      it 'joins groups with comma' do
        freespin_reward.bonus.groups = %w[group1 group2]
        expect(freespin_reward.formatted_groups).to eq('group1, group2')
      end
    end

    describe 'formatted_tags' do
      it 'returns nil when no tags' do
        freespin_reward.bonus.tags = ''
        expect(freespin_reward.formatted_tags).to be_nil
      end

      it 'joins tags with comma' do
        freespin_reward.bonus.tags = 'tag1, tag2'
        expect(freespin_reward.formatted_tags).to eq('tag1, tag2')
      end
    end

    describe 'formatted_currencies' do
      it 'returns nil when no currencies' do
        freespin_reward.bonus.currencies = []
        expect(freespin_reward.formatted_currencies).to be_nil
      end

      it 'joins currencies with comma' do
        freespin_reward.bonus.currencies = %w[USD EUR]
        expect(freespin_reward.formatted_currencies).to eq('USD, EUR')
      end
    end
  end

  # Edge cases and validations
  describe 'edge cases' do
    it 'handles invalid spins_count values' do
      freespin_reward.spins_count = 0
      expect(freespin_reward).not_to be_valid
      expect(freespin_reward.errors[:spins_count]).to include('must be greater than 0')
    end

    it 'handles negative spins_count values' do
      freespin_reward.spins_count = -5
      expect(freespin_reward).not_to be_valid
      expect(freespin_reward.errors[:spins_count]).to include('must be greater than 0')
    end

    it 'handles very large spins_count values' do
      freespin_reward.spins_count = 999999
      expect(freespin_reward).to be_valid
    end

    it 'preserves config when setting multiple parameters' do
      freespin_reward.games = [ 'game1' ]
      freespin_reward.bet_level = 1.5
      freespin_reward.max_win = '100x'

      expect(freespin_reward.config).to include(
        'games' => [ 'game1' ],
        'bet_level' => 1.5,
        'max_win' => '100x'
      )
    end

    it 'handles config merge correctly' do
      freespin_reward.config = { 'existing' => 'value' }
      freespin_reward.games = [ 'game1' ]

      expect(freespin_reward.config['existing']).to eq('value')
      expect(freespin_reward.config['games']).to eq([ 'game1' ])
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BonusBuyReward, type: :model do
  subject(:bonus_buy_reward) { build(:bonus_buy_reward) }

  # Associations
  describe 'associations' do
    it { should belong_to(:bonus) }
  end

  # Validations
  describe 'validations' do
    describe 'presence validations' do
      it { should validate_presence_of(:buy_amount) }
    end

    describe 'numericality validations' do
      it { should validate_numericality_of(:buy_amount).is_greater_than(0) }
      it { should validate_numericality_of(:multiplier).is_greater_than(0).allow_nil }
    end
  end

  # Serialization
  describe 'serialization' do
    it 'serializes config as JSON' do
      bonus_buy_reward.config = { 'test' => 'value' }
      bonus_buy_reward.save!
      bonus_buy_reward.reload
      expect(bonus_buy_reward.config).to eq({ 'test' => 'value' })
    end

    it 'handles nil config' do
      bonus_buy_reward.config = nil
      expect(bonus_buy_reward.config).to be_nil
    end

    it 'handles empty hash config' do
      bonus_buy_reward.config = {}
      expect(bonus_buy_reward.config).to eq({})
    end
  end

  # Config accessors
  describe 'config accessors' do
    describe 'games' do
      it 'returns empty array when config is nil' do
        bonus_buy_reward.config = nil
        expect(bonus_buy_reward.games).to eq([])
      end

      it 'returns games from config' do
        bonus_buy_reward.config = { 'games' => [ 'slot1', 'slot2' ] }
        expect(bonus_buy_reward.games).to eq([ 'slot1', 'slot2' ])
      end

      it 'sets games as array' do
        bonus_buy_reward.games = [ 'game1', 'game2' ]
        expect(bonus_buy_reward.config['games']).to eq([ 'game1', 'game2' ])
      end

      it 'sets games from comma-separated string' do
        bonus_buy_reward.games = 'game1, game2, game3'
        expect(bonus_buy_reward.config['games']).to eq([ 'game1', 'game2', 'game3' ])
      end

      it 'filters blank values' do
        bonus_buy_reward.games = 'game1, , game3,  '
        expect(bonus_buy_reward.config['games']).to eq([ 'game1', 'game3' ])
      end
    end

    describe 'bet_level' do
      it 'returns nil when not set' do
        expect(bonus_buy_reward.bet_level).to be_nil
      end

      it 'returns bet_level from config' do
        bonus_buy_reward.config = { 'bet_level' => 5 }
        expect(bonus_buy_reward.bet_level).to eq(5)
      end

      it 'sets bet_level as integer' do
        bonus_buy_reward.bet_level = '10'
        expect(bonus_buy_reward.config['bet_level']).to eq(10)
      end

      it 'handles nil value' do
        bonus_buy_reward.bet_level = nil
        expect(bonus_buy_reward.config['bet_level']).to be_nil
      end
    end

    describe 'max_win' do
      it 'returns nil when not set' do
        expect(bonus_buy_reward.max_win).to be_nil
      end

      it 'returns max_win from config' do
        bonus_buy_reward.config = { 'max_win' => '100x' }
        expect(bonus_buy_reward.max_win).to eq('100x')
      end

      it 'sets max_win value' do
        bonus_buy_reward.max_win = '50x'
        expect(bonus_buy_reward.config['max_win']).to eq('50x')
      end
    end

    describe 'max_win_type' do
      it 'returns "multiplier" when value contains "x"' do
        bonus_buy_reward.max_win = '100x'
        expect(bonus_buy_reward.max_win_type).to eq('multiplier')
      end

      it 'returns "fixed" when value does not contain "x"' do
        bonus_buy_reward.max_win = '1000'
        expect(bonus_buy_reward.max_win_type).to eq('fixed')
      end

      it 'returns "fixed" when max_win is nil' do
        bonus_buy_reward.max_win = nil
        expect(bonus_buy_reward.max_win_type).to eq('fixed')
      end
    end

    describe 'available' do
      it 'returns nil when not set' do
        expect(bonus_buy_reward.available).to be_nil
      end

      it 'sets available as integer' do
        bonus_buy_reward.available = '100'
        expect(bonus_buy_reward.config['available']).to eq(100)
      end

      it 'handles nil value' do
        bonus_buy_reward.available = nil
        expect(bonus_buy_reward.config['available']).to be_nil
      end
    end

    describe 'currencies' do
      it 'returns empty array when not set' do
        bonus_buy_reward.bonus.currencies = []
        expect(bonus_buy_reward.currencies).to eq([])
      end

      it 'gets currencies from associated bonus' do
        bonus_buy_reward.bonus.currencies = %w[USD EUR]
        expect(bonus_buy_reward.currencies).to eq(%w[USD EUR])
      end

      it 'returns empty array when bonus currencies is nil' do
        bonus_buy_reward.bonus.currencies = nil
        expect(bonus_buy_reward.currencies).to eq([])
      end
    end

    describe 'min_deposit_for_currency' do
      it 'gets minimum deposit for specific currency from associated bonus' do
        bonus_buy_reward.bonus.currency_minimum_deposits = { 'USD' => 50.0, 'EUR' => 25.0 }
        expect(bonus_buy_reward.min_deposit_for_currency('USD')).to eq(50.0)
        expect(bonus_buy_reward.min_deposit_for_currency('EUR')).to eq(25.0)
      end

      it 'returns nil for currency without minimum deposit' do
        bonus_buy_reward.bonus.currency_minimum_deposits = { 'USD' => 50.0 }
        expect(bonus_buy_reward.min_deposit_for_currency('EUR')).to be_nil
      end
    end

    describe 'currency_minimum_deposits' do
      it 'gets currency minimum deposits from associated bonus' do
        deposits = { 'USD' => 50.0, 'EUR' => 25.0 }
        bonus_buy_reward.bonus.currency_minimum_deposits = deposits
        expect(bonus_buy_reward.currency_minimum_deposits).to eq(deposits)
      end
    end

    describe 'groups' do
      it 'returns empty array when not set' do
        bonus_buy_reward.bonus.groups = []
        expect(bonus_buy_reward.groups).to eq([])
      end

      it 'gets groups from associated bonus' do
        bonus_buy_reward.bonus.groups = %w[VIP Regular]
        expect(bonus_buy_reward.groups).to eq(%w[VIP Regular])
      end

      it 'returns empty array when bonus groups is nil' do
        bonus_buy_reward.bonus.groups = nil
        expect(bonus_buy_reward.groups).to eq([])
      end
    end

    describe 'tags' do
      it 'returns empty array when not set' do
        bonus_buy_reward.bonus.tags = ''
        expect(bonus_buy_reward.tags).to eq([])
      end

      it 'gets tags from associated bonus' do
        bonus_buy_reward.bonus.tags = 'new_player, weekend'
        expect(bonus_buy_reward.tags).to eq(%w[new_player weekend])
      end

      it 'returns empty array when bonus tags is nil' do
        bonus_buy_reward.bonus.tags = nil
        expect(bonus_buy_reward.tags).to eq([])
      end

      it 'handles tags with extra spaces' do
        bonus_buy_reward.bonus.tags = '  new_player  ,  weekend  '
        expect(bonus_buy_reward.tags).to eq(%w[new_player weekend])
      end
    end
  end

  # Currency-specific bet levels
  describe 'currency-specific bet levels' do
    describe 'currency_bet_levels' do
      it 'returns empty hash when not set' do
        expect(bonus_buy_reward.currency_bet_levels).to eq({})
      end

      it 'sets currency bet levels' do
        levels = { 'USD' => 10.0, 'EUR' => 12.0 }
        bonus_buy_reward.currency_bet_levels = levels
        expect(bonus_buy_reward.config['currency_bet_levels']).to eq(levels)
      end
    end

    describe 'get_bet_level_for_currency' do
      before do
        bonus_buy_reward.bet_level = 5
        bonus_buy_reward.currency_bet_levels = { 'EUR' => 8.0 }
      end

      it 'returns currency-specific bet level when available' do
        expect(bonus_buy_reward.get_bet_level_for_currency('EUR')).to eq(8.0)
      end

      it 'returns default bet level when currency not found' do
        expect(bonus_buy_reward.get_bet_level_for_currency('USD')).to eq(5)
      end

      it 'handles string currency' do
        expect(bonus_buy_reward.get_bet_level_for_currency('EUR')).to eq(8.0)
      end

      it 'handles symbol currency' do
        expect(bonus_buy_reward.get_bet_level_for_currency(:EUR)).to eq(8.0)
      end
    end

    describe 'set_bet_level_for_currency' do
      it 'sets bet level for specific currency' do
        bonus_buy_reward.set_bet_level_for_currency('USD', 15.0)
        expect(bonus_buy_reward.currency_bet_levels['USD']).to eq(15.0)
      end

      it 'converts value to float' do
        bonus_buy_reward.set_bet_level_for_currency('USD', '20.5')
        expect(bonus_buy_reward.currency_bet_levels['USD']).to eq(20.5)
      end

      it 'handles nil value' do
        bonus_buy_reward.set_bet_level_for_currency('USD', nil)
        expect(bonus_buy_reward.currency_bet_levels['USD']).to be_nil
      end

      it 'preserves existing levels' do
        bonus_buy_reward.currency_bet_levels = { 'EUR' => 10.0 }
        bonus_buy_reward.set_bet_level_for_currency('USD', 15.0)
        expect(bonus_buy_reward.currency_bet_levels).to eq({ 'EUR' => 10.0, 'USD' => 15.0 })
      end
    end
  end

  # Advanced parameters
  describe 'advanced parameters' do
    describe 'advanced_params' do
      it 'returns array of available advanced parameters' do
        expect(bonus_buy_reward.advanced_params).to be_an(Array)
        expect(bonus_buy_reward.advanced_params).to include('auto_activate', 'duration', 'email_template')
      end
    end

    describe 'get_advanced_param' do
      it 'returns nil when parameter not set' do
        expect(bonus_buy_reward.get_advanced_param('auto_activate')).to be_nil
      end

      it 'returns parameter value from config' do
        bonus_buy_reward.config = { 'auto_activate' => true }
        expect(bonus_buy_reward.get_advanced_param('auto_activate')).to be true
      end
    end

    describe 'set_advanced_param' do
      it 'sets valid advanced parameter' do
        bonus_buy_reward.set_advanced_param('auto_activate', true)
        expect(bonus_buy_reward.config['auto_activate']).to be true
      end

      it 'ignores invalid parameter' do
        bonus_buy_reward.set_advanced_param('invalid_param', 'value')
        expect(bonus_buy_reward.config['invalid_param']).to be_nil
      end

      it 'preserves existing config' do
        bonus_buy_reward.config = { 'existing' => 'value' }
        bonus_buy_reward.set_advanced_param('auto_activate', true)
        expect(bonus_buy_reward.config['existing']).to eq('value')
        expect(bonus_buy_reward.config['auto_activate']).to be true
      end
    end
  end

  # Formatting methods
  describe 'formatting methods' do
    let(:bonus) { create(:bonus, :with_usd_only) }
    let(:bonus_buy_reward) { build(:bonus_buy_reward, bonus: bonus, buy_amount: 100.0, multiplier: 2.5) }

    describe 'formatted_buy_amount' do
      it 'formats buy amount with currency' do
        expect(bonus_buy_reward.formatted_buy_amount).to eq('100.0 USD')
      end
    end

    describe 'formatted_multiplier' do
      it 'formats multiplier with "x"' do
        bonus_buy_reward.multiplier = 2.5
        expect(bonus_buy_reward.formatted_multiplier).to eq('2.5x')
      end

      it 'returns "N/A" when multiplier is nil' do
        bonus_buy_reward.multiplier = nil
        expect(bonus_buy_reward.formatted_multiplier).to eq('N/A')
      end

      it 'returns "N/A" when multiplier is blank' do
        bonus_buy_reward.multiplier = ''
        expect(bonus_buy_reward.formatted_multiplier).to eq('N/A')
      end
    end

    describe 'has_game_restrictions?' do
      it 'returns false when no games specified' do
        bonus_buy_reward.games = []
        expect(bonus_buy_reward).not_to have_game_restrictions
      end

      it 'returns true when games specified' do
        bonus_buy_reward.games = [ 'slot1', 'slot2' ]
        expect(bonus_buy_reward).to have_game_restrictions
      end
    end

    describe 'formatted_games' do
      it 'returns nil when no games' do
        bonus_buy_reward.games = []
        expect(bonus_buy_reward.formatted_games).to be_nil
      end

      it 'joins games with comma' do
        bonus_buy_reward.games = [ 'Slot Game 1', 'Slot Game 2' ]
        expect(bonus_buy_reward.formatted_games).to eq('Slot Game 1, Slot Game 2')
      end
    end

    describe 'formatted_max_win' do
      it 'returns "No limit" when max_win is blank' do
        bonus_buy_reward.max_win = nil
        expect(bonus_buy_reward.formatted_max_win).to eq('No limit')
      end

      it 'returns multiplier value as is' do
        bonus_buy_reward.max_win = '100x'
        expect(bonus_buy_reward.formatted_max_win).to eq('100x')
      end

      it 'formats fixed amount with currency' do
        bonus_buy_reward.max_win = '500'
        expect(bonus_buy_reward.formatted_max_win).to eq('500 USD')
      end
    end

    describe 'formatted_groups' do
      it 'returns nil when no groups' do
        bonus_buy_reward.bonus.groups = []
        expect(bonus_buy_reward.formatted_groups).to be_nil
      end

      it 'joins groups with comma' do
        bonus_buy_reward.bonus.groups = %w[group1 group2]
        expect(bonus_buy_reward.formatted_groups).to eq('group1, group2')
      end
    end

    describe 'formatted_tags' do
      it 'returns nil when no tags' do
        bonus_buy_reward.bonus.tags = ''
        expect(bonus_buy_reward.formatted_tags).to be_nil
      end

      it 'joins tags with comma' do
        bonus_buy_reward.bonus.tags = 'tag1, tag2'
        expect(bonus_buy_reward.formatted_tags).to eq('tag1, tag2')
      end
    end

    describe 'formatted_currencies' do
      it 'returns nil when no currencies' do
        bonus_buy_reward.bonus.currencies = []
        expect(bonus_buy_reward.formatted_currencies).to be_nil
      end

      it 'joins currencies with comma' do
        bonus_buy_reward.bonus.currencies = %w[USD EUR]
        expect(bonus_buy_reward.formatted_currencies).to eq('USD, EUR')
      end
    end
  end

  # Edge cases and validations
  describe 'edge cases' do
    it 'handles invalid buy_amount values' do
      bonus_buy_reward.buy_amount = 0
      expect(bonus_buy_reward).not_to be_valid
      expect(bonus_buy_reward.errors[:buy_amount]).to include('must be greater than 0')
    end

    it 'handles negative buy_amount values' do
      bonus_buy_reward.buy_amount = -50
      expect(bonus_buy_reward).not_to be_valid
      expect(bonus_buy_reward.errors[:buy_amount]).to include('must be greater than 0')
    end

    it 'handles invalid multiplier values' do
      bonus_buy_reward.multiplier = 0
      expect(bonus_buy_reward).not_to be_valid
      expect(bonus_buy_reward.errors[:multiplier]).to include('must be greater than 0')
    end

    it 'handles negative multiplier values' do
      bonus_buy_reward.multiplier = -1.5
      expect(bonus_buy_reward).not_to be_valid
      expect(bonus_buy_reward.errors[:multiplier]).to include('must be greater than 0')
    end

    it 'allows nil multiplier' do
      bonus_buy_reward.multiplier = nil
      expect(bonus_buy_reward).to be_valid
    end

    it 'handles very large buy_amount values' do
      bonus_buy_reward.buy_amount = 999999.99
      expect(bonus_buy_reward).to be_valid
    end

    it 'handles decimal multiplier values' do
      bonus_buy_reward.multiplier = 1.75
      expect(bonus_buy_reward).to be_valid
    end

    it 'preserves config when setting multiple parameters' do
      bonus_buy_reward.games = [ 'game1' ]
      bonus_buy_reward.bet_level = 10
      bonus_buy_reward.max_win = '100x'

      expect(bonus_buy_reward.config).to include(
        'games' => [ 'game1' ],
        'bet_level' => 10,
        'max_win' => '100x'
      )
    end

    it 'handles config merge correctly' do
      bonus_buy_reward.config = { 'existing' => 'value' }
      bonus_buy_reward.games = [ 'game1' ]

      expect(bonus_buy_reward.config['existing']).to eq('value')
      expect(bonus_buy_reward.config['games']).to eq([ 'game1' ])
    end
  end
end

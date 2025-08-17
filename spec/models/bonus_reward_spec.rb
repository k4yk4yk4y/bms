# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BonusReward, type: :model do
  subject(:bonus_reward) { build(:bonus_reward) }

  # Associations tests
  describe 'associations' do
    it { is_expected.to belong_to(:bonus) }
  end

  # Validations tests
  describe 'validations' do
    describe 'presence validations' do
      it { is_expected.to validate_presence_of(:reward_type) }
      it { is_expected.to validate_presence_of(:amount) }
    end

    describe 'numericality validations' do
      it { is_expected.to validate_numericality_of(:amount).is_greater_than_or_equal_to(0) }
      it { is_expected.to validate_numericality_of(:percentage).is_greater_than_or_equal_to(0).is_less_than_or_equal_to(100) }
      it { is_expected.to allow_value(nil).for(:percentage) }
    end
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

  # Serialization tests
  describe 'config serialization' do
    it 'handles nil config' do
      bonus_reward.config = nil
      expect(bonus_reward.config).to be_nil
    end

    it 'stores and retrieves JSON config' do
      config_data = { 'wager' => 35.0, 'max_win' => '500' }
      bonus_reward.config = config_data
      bonus_reward.save!

      expect(bonus_reward.reload.config).to eq(config_data)
    end

    it 'initializes with empty config by default' do
      new_reward = build(:bonus_reward)
      expect(new_reward.config).to eq({})
    end
  end

  # Common parameters accessor tests
  describe 'config accessors' do
    before do
      bonus_reward.config = {
        'wager' => 35.0,
        'max_win' => '500',
        'available' => 100,
        'code' => 'REWARD123',
        'currencies' => %w[USD EUR],
        'min' => 50.0,
        'groups' => %w[VIP Regular],
        'tags' => %w[new_player weekend],
        'user_can_have_duplicates' => true,
        'no_more' => 5,
        'wagering_strategy' => 'bonus_first',
        'stag' => 'TEST_STAG'
      }
    end

    describe '#wager and #wager=' do
      it 'gets wager from config' do
        expect(bonus_reward.wager).to eq(35.0)
      end

      it 'sets wager in config' do
        bonus_reward.wager = 40.5
        expect(bonus_reward.config['wager']).to eq(40.5)
      end

      it 'handles nil values' do
        bonus_reward.wager = nil
        expect(bonus_reward.config['wager']).to be_nil
      end

      it 'converts string to float' do
        bonus_reward.wager = '45.5'
        expect(bonus_reward.config['wager']).to eq(45.5)
      end
    end

    describe '#max_win and #max_win=' do
      it 'gets max_win from config' do
        expect(bonus_reward.max_win).to eq('500')
      end

      it 'sets max_win in config' do
        bonus_reward.max_win = '1000'
        expect(bonus_reward.config['max_win']).to eq('1000')
      end

      it 'handles multiplier format' do
        bonus_reward.max_win = 'x10'
        expect(bonus_reward.config['max_win']).to eq('x10')
      end
    end

    describe '#max_win_type' do
      it 'returns multiplier when max_win includes x' do
        bonus_reward.max_win = 'x10'
        expect(bonus_reward.max_win_type).to eq('multiplier')
      end

      it 'returns fixed when max_win does not include x' do
        bonus_reward.max_win = '500'
        expect(bonus_reward.max_win_type).to eq('fixed')
      end

      it 'returns fixed for nil max_win' do
        bonus_reward.max_win = nil
        expect(bonus_reward.max_win_type).to eq('fixed')
      end
    end

    describe '#available and #available=' do
      it 'gets available from config' do
        expect(bonus_reward.available).to eq(100)
      end

      it 'sets available in config' do
        bonus_reward.available = 50
        expect(bonus_reward.config['available']).to eq(50)
      end

      it 'converts string to integer' do
        bonus_reward.available = '75'
        expect(bonus_reward.config['available']).to eq(75)
      end
    end

    describe '#code and #code=' do
      it 'gets code from config' do
        expect(bonus_reward.code).to eq('REWARD123')
      end

      it 'sets code in config' do
        bonus_reward.code = 'NEW_CODE'
        expect(bonus_reward.config['code']).to eq('NEW_CODE')
      end
    end

    describe '#currencies and #currencies=' do
      it 'gets currencies from config' do
        expect(bonus_reward.currencies).to eq(%w[USD EUR])
      end

      it 'sets currencies as array' do
        bonus_reward.currencies = %w[USD GBP]
        expect(bonus_reward.config['currencies']).to eq(%w[USD GBP])
      end

      it 'converts single value to array' do
        bonus_reward.currencies = 'USD'
        expect(bonus_reward.config['currencies']).to eq([ 'USD' ])
      end

      it 'returns empty array when nil' do
        bonus_reward.config = {}
        expect(bonus_reward.currencies).to eq([])
      end
    end

    describe '#min_deposit and #min_deposit=' do
      it 'gets min from config' do
        expect(bonus_reward.min_deposit).to eq(50.0)
      end

      it 'sets min in config' do
        bonus_reward.min_deposit = 75.5
        expect(bonus_reward.config['min']).to eq(75.5)
      end
    end

    describe '#groups and #groups=' do
      it 'gets groups from config' do
        expect(bonus_reward.groups).to eq(%w[VIP Regular])
      end

      it 'sets groups as array' do
        bonus_reward.groups = %w[Premium Basic]
        expect(bonus_reward.config['groups']).to eq(%w[Premium Basic])
      end

      it 'handles string input' do
        bonus_reward.groups = 'VIP, Premium, Basic'
        expect(bonus_reward.config['groups']).to eq(%w[VIP Premium Basic])
      end

      it 'returns empty array when nil' do
        bonus_reward.config = {}
        expect(bonus_reward.groups).to eq([])
      end
    end

    describe '#tags and #tags=' do
      it 'gets tags from config' do
        expect(bonus_reward.tags).to eq(%w[new_player weekend])
      end

      it 'sets tags as array' do
        bonus_reward.tags = %w[loyalty bonus]
        expect(bonus_reward.config['tags']).to eq(%w[loyalty bonus])
      end

      it 'handles string input' do
        bonus_reward.tags = 'loyalty, bonus, special'
        expect(bonus_reward.config['tags']).to eq(%w[loyalty bonus special])
      end

      it 'returns empty array when nil' do
        bonus_reward.config = {}
        expect(bonus_reward.tags).to eq([])
      end
    end

    describe '#user_can_have_duplicates and #user_can_have_duplicates=' do
      it 'gets user_can_have_duplicates from config' do
        expect(bonus_reward.user_can_have_duplicates).to be true
      end

      it 'sets user_can_have_duplicates in config' do
        bonus_reward.user_can_have_duplicates = false
        expect(bonus_reward.config['user_can_have_duplicates']).to be false
      end

      it 'converts truthy values to boolean' do
        bonus_reward.user_can_have_duplicates = 'true'
        expect(bonus_reward.config['user_can_have_duplicates']).to be true

        bonus_reward.user_can_have_duplicates = '1'
        expect(bonus_reward.config['user_can_have_duplicates']).to be true

        bonus_reward.user_can_have_duplicates = 1
        expect(bonus_reward.config['user_can_have_duplicates']).to be true
      end

      it 'returns false for falsy values' do
        bonus_reward.config = {}
        expect(bonus_reward.user_can_have_duplicates).to be false
      end
    end

    describe '#no_more and #no_more=' do
      it 'gets no_more from config' do
        expect(bonus_reward.no_more).to eq(5)
      end

      it 'sets no_more in config' do
        bonus_reward.no_more = 10
        expect(bonus_reward.config['no_more']).to eq(10)
      end
    end

    describe '#wagering_strategy and #wagering_strategy=' do
      it 'gets wagering_strategy from config' do
        expect(bonus_reward.wagering_strategy).to eq('bonus_first')
      end

      it 'sets wagering_strategy in config' do
        bonus_reward.wagering_strategy = 'deposit_first'
        expect(bonus_reward.config['wagering_strategy']).to eq('deposit_first')
      end
    end

    describe '#stag and #stag=' do
      it 'gets stag from config' do
        expect(bonus_reward.stag).to eq('TEST_STAG')
      end

      it 'sets stag in config' do
        bonus_reward.stag = 'NEW_STAG'
        expect(bonus_reward.config['stag']).to eq('NEW_STAG')
      end
    end

    describe '#totally_no_more and #totally_no_more=' do
      it 'gets totally_no_more from config' do
        bonus_reward.config = { 'totally_no_more' => 20 }
        expect(bonus_reward.totally_no_more).to eq(20)
      end

      it 'sets totally_no_more in config' do
        bonus_reward.totally_no_more = 15
        expect(bonus_reward.config['totally_no_more']).to eq(15)
      end
    end
  end

  # Advanced parameters tests
  describe 'advanced parameters' do
    it 'has defined advanced_params list' do
      expect(bonus_reward.advanced_params).to be_an(Array)
      expect(bonus_reward.advanced_params).to include('range', 'last_login_country', 'total_deposits')
    end

    describe '#get_advanced_param' do
      it 'gets advanced parameter from config' do
        bonus_reward.config = { 'range' => '100-500' }
        expect(bonus_reward.get_advanced_param('range')).to eq('100-500')
      end

      it 'returns nil for missing parameter' do
        expect(bonus_reward.get_advanced_param('nonexistent')).to be_nil
      end
    end

    describe '#set_advanced_param' do
      it 'sets advanced parameter in config' do
        bonus_reward.set_advanced_param('range', '200-1000')
        expect(bonus_reward.config['range']).to eq('200-1000')
      end

      it 'does not set invalid parameter' do
        bonus_reward.set_advanced_param('invalid_param', 'value')
        expect(bonus_reward.config['invalid_param']).to be_nil
      end

      it 'updates existing config without overwriting other values' do
        bonus_reward.config = { 'wager' => 35.0 }
        bonus_reward.set_advanced_param('range', '100-500')
        expect(bonus_reward.config).to eq({ 'wager' => 35.0, 'range' => '100-500' })
      end
    end
  end

  # Formatting methods tests
  describe 'formatting methods' do
    let(:bonus) { create(:bonus, currency: 'USD') }
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
      it 'returns "No limit" when max_win is blank' do
        bonus_reward.max_win = nil
        expect(bonus_reward.formatted_max_win).to eq('No limit')
      end

      it 'returns max_win when it includes x' do
        bonus_reward.max_win = 'x10'
        expect(bonus_reward.formatted_max_win).to eq('x10')
      end

      it 'returns max_win with currency when it does not include x' do
        bonus_reward.max_win = '500'
        expect(bonus_reward.formatted_max_win).to eq('500 USD')
      end
    end

    describe '#formatted_groups' do
      it 'returns joined groups when groups exist' do
        bonus_reward.groups = %w[VIP Regular Premium]
        expect(bonus_reward.formatted_groups).to eq('VIP, Regular, Premium')
      end

      it 'returns nil when no groups' do
        bonus_reward.groups = []
        expect(bonus_reward.formatted_groups).to be_nil
      end
    end

    describe '#formatted_tags' do
      it 'returns joined tags when tags exist' do
        bonus_reward.tags = %w[new_player loyalty weekend]
        expect(bonus_reward.formatted_tags).to eq('new_player, loyalty, weekend')
      end

      it 'returns nil when no tags' do
        bonus_reward.tags = []
        expect(bonus_reward.formatted_tags).to be_nil
      end
    end

    describe '#formatted_currencies' do
      it 'returns joined currencies when currencies exist' do
        bonus_reward.currencies = %w[USD EUR GBP]
        expect(bonus_reward.formatted_currencies).to eq('USD, EUR, GBP')
      end

      it 'returns nil when no currencies' do
        bonus_reward.currencies = []
        expect(bonus_reward.formatted_currencies).to be_nil
      end
    end
  end

  # Edge cases and error conditions
  describe 'edge cases' do
    describe 'with nil config' do
      it 'handles nil config gracefully' do
        bonus_reward.config = nil
        expect(bonus_reward.wager).to be_nil
        expect(bonus_reward.currencies).to eq([])
        expect(bonus_reward.groups).to eq([])
        expect(bonus_reward.tags).to eq([])
        expect(bonus_reward.user_can_have_duplicates).to be false
      end
    end

    describe 'with malformed arrays in config' do
      it 'handles string arrays with extra spaces' do
        bonus_reward.groups = '  VIP  ,  Regular  ,  Premium  '
        expect(bonus_reward.groups).to eq(%w[VIP Regular Premium])
      end

      it 'filters out blank values' do
        bonus_reward.tags = 'tag1, , tag2, , tag3'
        expect(bonus_reward.tags).to eq(%w[tag1 tag2 tag3])
      end
    end

    describe 'with type conversions' do
      it 'handles invalid numeric conversions gracefully' do
        bonus_reward.wager = 'invalid'
        expect(bonus_reward.config['wager']).to eq(0.0)
      end

      it 'handles invalid integer conversions gracefully' do
        bonus_reward.available = 'invalid'
        expect(bonus_reward.config['available']).to eq(0)
      end
    end

    describe 'config merging' do
      it 'preserves existing config when setting new values' do
        bonus_reward.config = { 'existing_key' => 'existing_value' }
        bonus_reward.wager = 35.0
        expect(bonus_reward.config).to include('existing_key' => 'existing_value', 'wager' => 35.0)
      end

      it 'overwrites existing values when setting new ones' do
        bonus_reward.config = { 'wager' => 25.0 }
        bonus_reward.wager = 35.0
        expect(bonus_reward.config['wager']).to eq(35.0)
      end
    end
  end
end

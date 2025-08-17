# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BonusCodeReward, type: :model do
  subject(:bonus_code_reward) { build(:bonus_code_reward) }

  # Associations
  describe 'associations' do
    it { should belong_to(:bonus) }
  end

  # Validations
  describe 'validations' do
    describe 'presence validations' do
      it { should validate_presence_of(:code) }
      it { should validate_presence_of(:code_type) }
    end
  end

  # Serialization
  describe 'serialization' do
    it 'serializes config as JSON' do
      bonus_code_reward.config = { 'test' => 'value' }
      bonus_code_reward.save!
      bonus_code_reward.reload
      expect(bonus_code_reward.config).to eq({ 'test' => 'value' })
    end

    it 'handles nil config' do
      bonus_code_reward.config = nil
      bonus_code_reward.save!
      bonus_code_reward.reload
      expect(bonus_code_reward.config).to eq({})
    end

    it 'handles empty hash config' do
      bonus_code_reward.config = {}
      expect(bonus_code_reward.config).to eq({})
    end
  end

  # Config accessor
  describe 'config accessor' do
    it 'returns empty hash when config is nil' do
      bonus_code_reward.config = nil
      expect(bonus_code_reward.config).to eq({})
    end

    it 'returns config hash when set' do
      test_config = { 'param1' => 'value1', 'param2' => 'value2' }
      bonus_code_reward.config = test_config
      expect(bonus_code_reward.config).to eq(test_config)
    end

    it 'preserves config structure' do
      complex_config = {
        'settings' => {
          'auto_activate' => true,
          'duration' => 30
        },
        'rules' => [ 'rule1', 'rule2' ]
      }
      bonus_code_reward.config = complex_config
      expect(bonus_code_reward.config['settings']['auto_activate']).to be true
      expect(bonus_code_reward.config['rules']).to eq([ 'rule1', 'rule2' ])
    end
  end

  # Helper methods
  describe 'helper methods' do
    let(:bonus_code_reward) { build(:bonus_code_reward, code: 'test123') }

    describe '#formatted_bonus_code' do
      it 'returns uppercase bonus code when present' do
        bonus_code_reward.code = 'bonus123'
        expect(bonus_code_reward.formatted_bonus_code).to eq('BONUS123')
      end

      it 'handles already uppercase codes' do
        bonus_code_reward.code = 'BONUS123'
        expect(bonus_code_reward.formatted_bonus_code).to eq('BONUS123')
      end

      it 'handles mixed case codes' do
        bonus_code_reward.code = 'BonUs123'
        expect(bonus_code_reward.formatted_bonus_code).to eq('BONUS123')
      end

      it 'returns "N/A" when bonus code is nil' do
        bonus_code_reward.code = nil
        expect(bonus_code_reward.formatted_bonus_code).to eq('N/A')
      end

      it 'returns "N/A" when bonus code is empty' do
        bonus_code_reward.code = ''
        expect(bonus_code_reward.formatted_bonus_code).to eq('N/A')
      end

      it 'returns "N/A" when bonus code is blank' do
        bonus_code_reward.code = '   '
        expect(bonus_code_reward.formatted_bonus_code).to eq('N/A')
      end

      it 'handles special characters' do
        bonus_code_reward.code = 'bonus_123-test'
        expect(bonus_code_reward.formatted_bonus_code).to eq('BONUS_123-TEST')
      end

      it 'handles numeric codes' do
        bonus_code_reward.code = '12345'
        expect(bonus_code_reward.formatted_bonus_code).to eq('12345')
      end
    end

    describe '#title' do
      it 'returns title from config when present' do
        bonus_code_reward.config = { 'title' => 'Welcome Bonus' }
        expect(bonus_code_reward.title).to eq('Welcome Bonus')
      end

      it 'returns default title when config title is blank' do
        bonus_code_reward.code = 'WELCOME123'
        bonus_code_reward.config = {}
        expect(bonus_code_reward.title).to eq('Бонус-код WELCOME123')
      end

      it 'sets title in config' do
        bonus_code_reward.title = 'VIP Bonus'
        expect(bonus_code_reward.config['title']).to eq('VIP Bonus')
      end
    end

    describe '#display_title' do
      it 'returns the title' do
        bonus_code_reward.title = 'Welcome Bonus'
        expect(bonus_code_reward.display_title).to eq('Welcome Bonus')
      end

      it 'returns default when no title set' do
        bonus_code_reward.code = 'TEST123'
        bonus_code_reward.config = {}
        expect(bonus_code_reward.display_title).to eq('Бонус-код TEST123')
      end
    end

    describe '#set_bonus_code compatibility methods' do
      it 'gets code through set_bonus_code' do
        bonus_code_reward.code = 'TEST123'
        expect(bonus_code_reward.set_bonus_code).to eq('TEST123')
      end

      it 'sets code through set_bonus_code=' do
        bonus_code_reward.set_bonus_code = 'NEW123'
        expect(bonus_code_reward.code).to eq('NEW123')
      end
    end
  end

  # Edge cases and validations
  describe 'edge cases' do
    describe 'code validations' do
      it 'rejects nil code' do
        bonus_code_reward.code = nil
        expect(bonus_code_reward).not_to be_valid
        expect(bonus_code_reward.errors[:code]).to include("can't be blank")
      end

      it 'rejects empty code' do
        bonus_code_reward.code = ''
        expect(bonus_code_reward).not_to be_valid
        expect(bonus_code_reward.errors[:code]).to include("can't be blank")
      end

      it 'rejects blank code' do
        bonus_code_reward.code = '   '
        expect(bonus_code_reward).not_to be_valid
        expect(bonus_code_reward.errors[:code]).to include("can't be blank")
      end

      it 'accepts valid bonus codes' do
        valid_codes = [ 'BONUS123', 'welcome_2024', 'TEST-CODE', '12345', 'Aa1_-' ]
        valid_codes.each do |code|
          bonus_code_reward.code = code
          expect(bonus_code_reward).to be_valid, "Expected '#{code}' to be valid"
        end
      end

      it 'handles very long bonus codes' do
        long_code = 'A' * 255
        bonus_code_reward.code = long_code
        expect(bonus_code_reward).to be_valid
      end
    end

    describe 'code_type validations' do
      it 'rejects nil code_type' do
        bonus_code_reward.code_type = nil
        expect(bonus_code_reward).not_to be_valid
        expect(bonus_code_reward.errors[:code_type]).to include("can't be blank")
      end

      it 'rejects empty code_type' do
        bonus_code_reward.code_type = ''
        expect(bonus_code_reward).not_to be_valid
        expect(bonus_code_reward.errors[:code_type]).to include("can't be blank")
      end

      it 'accepts valid code types' do
        valid_types = [ 'promocode', 'bonus_code', 'special_code', 'set_bonus_code' ]
        valid_types.each do |type|
          bonus_code_reward.code_type = type
          expect(bonus_code_reward).to be_valid, "Expected '#{type}' to be valid"
        end
      end
    end

    describe 'title methods' do
      it 'returns default title when no config title' do
        bonus_code_reward.code = 'TEST123'
        bonus_code_reward.config = {}
        expect(bonus_code_reward.title).to eq('Бонус-код TEST123')
      end

      it 'sets and gets title through config' do
        bonus_code_reward.title = 'Custom Title'
        expect(bonus_code_reward.title).to eq('Custom Title')
        expect(bonus_code_reward.config['title']).to eq('Custom Title')
      end

      it 'preserves other config when setting title' do
        bonus_code_reward.config = { 'other' => 'value' }
        bonus_code_reward.title = 'New Title'
        expect(bonus_code_reward.config['other']).to eq('value')
        expect(bonus_code_reward.config['title']).to eq('New Title')
      end
    end

    describe 'bonus association' do
      it 'requires a bonus' do
        bonus_code_reward.bonus = nil
        expect(bonus_code_reward).not_to be_valid
        expect(bonus_code_reward.errors[:bonus]).to include('must exist')
      end

      it 'deletes bonus_code_reward when bonus is deleted' do
        bonus_code_reward.save!
        bonus_id = bonus_code_reward.bonus.id
        bonus_code_reward.bonus.destroy
        expect(BonusCodeReward.find_by(bonus_id: bonus_id)).to be_nil
      end
    end

    describe 'config edge cases' do
      it 'handles complex nested config' do
        complex_config = {
          'advanced' => {
            'auto_activate' => true,
            'settings' => {
              'duration' => 30,
              'max_uses' => 100
            }
          },
          'restrictions' => [ 'rule1', 'rule2' ],
          'metadata' => {
            'created_by' => 'admin',
            'version' => 1.2
          }
        }
        bonus_code_reward.config = complex_config
        bonus_code_reward.save!
        bonus_code_reward.reload

        expect(bonus_code_reward.config['advanced']['auto_activate']).to be true
        expect(bonus_code_reward.config['advanced']['settings']['duration']).to eq(30)
        expect(bonus_code_reward.config['restrictions']).to eq([ 'rule1', 'rule2' ])
        expect(bonus_code_reward.config['metadata']['version']).to eq(1.2)
      end

      it 'handles JSON serialization/deserialization correctly' do
        original_config = { 'key' => 'value', 'number' => 42, 'bool' => true }
        bonus_code_reward.config = original_config
        bonus_code_reward.save!

        retrieved = BonusCodeReward.find(bonus_code_reward.id)
        expect(retrieved.config).to eq(original_config)
      end

      it 'preserves data types in config' do
        config_with_types = {
          'string' => 'text',
          'integer' => 42,
          'float' => 3.14,
          'boolean_true' => true,
          'boolean_false' => false,
          'null' => nil,
          'array' => [ 1, 2, 3 ],
          'hash' => { 'nested' => 'value' }
        }
        bonus_code_reward.config = config_with_types
        bonus_code_reward.save!
        bonus_code_reward.reload

        expect(bonus_code_reward.config['string']).to be_a(String)
        expect(bonus_code_reward.config['integer']).to be_a(Integer)
        expect(bonus_code_reward.config['float']).to be_a(Float)
        expect(bonus_code_reward.config['boolean_true']).to be true
        expect(bonus_code_reward.config['boolean_false']).to be false
        expect(bonus_code_reward.config['null']).to be_nil
        expect(bonus_code_reward.config['array']).to be_an(Array)
        expect(bonus_code_reward.config['hash']).to be_a(Hash)
      end
    end

    describe 'database constraints' do
      it 'saves valid bonus_code_reward successfully' do
        expect { bonus_code_reward.save! }.not_to raise_error
      end

      it 'can be retrieved from database correctly' do
        bonus_code_reward.save!
        retrieved = BonusCodeReward.find(bonus_code_reward.id)
        expect(retrieved.code).to eq(bonus_code_reward.code)
        expect(retrieved.code_type).to eq(bonus_code_reward.code_type)
        expect(retrieved.bonus_id).to eq(bonus_code_reward.bonus_id)
      end
    end
  end

  # Factory validation
  describe 'factory' do
    it 'creates valid bonus_code_reward from factory' do
      bonus_code_reward = build(:bonus_code_reward)
      expect(bonus_code_reward).to be_valid
    end

    it 'creates bonus_code_reward with reasonable default values' do
      bonus_code_reward = build(:bonus_code_reward)
      expect(bonus_code_reward.code).to be_present
      expect(bonus_code_reward.code_type).to be_present
      expect(bonus_code_reward.bonus).to be_present
      expect(bonus_code_reward.config).to eq({})
    end

    it 'can create and save bonus_code_reward from factory' do
      expect { create(:bonus_code_reward) }.not_to raise_error
    end
  end
end

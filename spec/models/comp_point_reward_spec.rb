# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CompPointReward, type: :model do
  subject(:comp_point_reward) { build(:comp_point_reward) }

  # Associations
  describe 'associations' do
    it { should belong_to(:bonus) }
  end

  # Validations
  describe 'validations' do
    describe 'presence validations' do
      it { should validate_presence_of(:points_amount) }
    end

    describe 'numericality validations' do
      it { should validate_numericality_of(:points_amount).is_greater_than_or_equal_to(0) }
      it { should validate_numericality_of(:multiplier).is_greater_than_or_equal_to(0).allow_nil }
    end
  end

  # Serialization
  describe 'serialization' do
    it 'serializes config as JSON' do
      comp_point_reward.config = { 'test' => 'value' }
      comp_point_reward.save!
      comp_point_reward.reload
      expect(comp_point_reward.config).to eq({ 'test' => 'value' })
    end

    it 'handles nil config' do
      comp_point_reward.config = nil
      comp_point_reward.save!
      comp_point_reward.reload
      expect(comp_point_reward.config).to eq({})
    end

    it 'handles empty hash config' do
      comp_point_reward.config = {}
      expect(comp_point_reward.config).to eq({})
    end
  end

  # Config accessor
  describe 'config accessor' do
    it 'returns empty hash when config is nil' do
      comp_point_reward.config = nil
      expect(comp_point_reward.config).to eq({})
    end

    it 'returns config hash when set' do
      test_config = { 'param1' => 'value1', 'param2' => 'value2' }
      comp_point_reward.config = test_config
      expect(comp_point_reward.config).to eq(test_config)
    end

    it 'preserves config structure' do
      complex_config = {
        'settings' => {
          'auto_activate' => true,
          'duration' => 30
        },
        'rules' => ['rule1', 'rule2']
      }
      comp_point_reward.config = complex_config
      expect(comp_point_reward.config['settings']['auto_activate']).to be true
      expect(comp_point_reward.config['rules']).to eq(['rule1', 'rule2'])
    end
  end

  # Helper methods
  describe 'helper methods' do
    let(:comp_point_reward) { build(:comp_point_reward, points_amount: 100, multiplier: 2.5) }

    describe '#formatted_points_amount' do
      it 'formats points amount when present' do
        comp_point_reward.points_amount = 150
        expect(comp_point_reward.formatted_points_amount).to eq('150 очков')
      end

      it 'returns "0" when points amount is nil' do
        comp_point_reward.points_amount = nil
        expect(comp_point_reward.formatted_points_amount).to eq('0')
      end

      it 'handles large integer values' do
        comp_point_reward.points_amount = 50
        expect(comp_point_reward.formatted_points_amount).to eq('50 очков')
      end

      it 'handles large values' do
        comp_point_reward.points_amount = 999999
        expect(comp_point_reward.formatted_points_amount).to eq('999999 очков')
      end
    end

    describe '#formatted_multiplier' do
      it 'formats multiplier when present' do
        comp_point_reward.multiplier = 2.5
        expect(comp_point_reward.formatted_multiplier).to eq('×2.5')
      end

      it 'returns "N/A" when multiplier is nil' do
        comp_point_reward.multiplier = nil
        expect(comp_point_reward.formatted_multiplier).to eq('N/A')
      end

      it 'returns "N/A" when multiplier is blank' do
        comp_point_reward.multiplier = ''
        expect(comp_point_reward.formatted_multiplier).to eq('N/A')
      end

      it 'handles integer multipliers' do
        comp_point_reward.multiplier = 3
        expect(comp_point_reward.formatted_multiplier).to eq('×3.0')
      end
    end

    describe '#title' do
      it 'returns title from config when present' do
        comp_point_reward.config = { 'title' => 'Special Points' }
        expect(comp_point_reward.title).to eq('Special Points')
      end

      it 'returns default title when config title is blank' do
        comp_point_reward.points_amount = 100
        comp_point_reward.config = {}
        expect(comp_point_reward.title).to eq('100 comp points')
      end

      it 'sets title in config' do
        comp_point_reward.title = 'VIP Points'
        expect(comp_point_reward.config['title']).to eq('VIP Points')
      end
    end

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

      it 'returns points amount when multiplier is blank' do
        comp_point_reward.points_amount = 100
        comp_point_reward.multiplier = ''
        expect(comp_point_reward.total_value).to eq(100)
      end

      it 'handles decimal calculations' do
        comp_point_reward.points_amount = 33
        comp_point_reward.multiplier = 1.5
        expect(comp_point_reward.total_value).to eq(49.5)
      end
    end
  end

  # Edge cases and validations
  describe 'edge cases' do
    describe 'numericality validations' do
      it 'rejects negative points amount' do
        comp_point_reward.points_amount = -10
        expect(comp_point_reward).not_to be_valid
        expect(comp_point_reward.errors[:points_amount]).to include('must be greater than or equal to 0')
      end

      it 'rejects negative multiplier' do
        comp_point_reward.multiplier = -1.5
        expect(comp_point_reward).not_to be_valid
        expect(comp_point_reward.errors[:multiplier]).to include('must be greater than or equal to 0')
      end

      it 'accepts zero points amount' do
        comp_point_reward.points_amount = 0
        expect(comp_point_reward).to be_valid
      end

      it 'accepts zero multiplier' do
        comp_point_reward.multiplier = 0
        expect(comp_point_reward).to be_valid
      end

      it 'accepts nil multiplier' do
        comp_point_reward.multiplier = nil
        expect(comp_point_reward).to be_valid
      end

      it 'accepts integer points_amount and decimal multiplier' do
        comp_point_reward.points_amount = 50
        comp_point_reward.multiplier = 2.25
        expect(comp_point_reward).to be_valid
      end

      it 'accepts very large values' do
        comp_point_reward.points_amount = 999999
        comp_point_reward.multiplier = 999.99
        expect(comp_point_reward).to be_valid
      end

      it 'requires points_amount' do
        comp_point_reward.points_amount = nil
        expect(comp_point_reward).not_to be_valid
        expect(comp_point_reward.errors[:points_amount]).to include("can't be blank")
      end
    end

    describe 'title methods' do
      it 'returns default title when no config title' do
        comp_point_reward.points_amount = 150
        comp_point_reward.config = {}
        expect(comp_point_reward.title).to eq('150 comp points')
      end

      it 'sets and gets title through config' do
        comp_point_reward.title = 'VIP Points'
        expect(comp_point_reward.title).to eq('VIP Points')
        expect(comp_point_reward.config['title']).to eq('VIP Points')
      end

      it 'preserves other config when setting title' do
        comp_point_reward.config = { 'other' => 'value' }
        comp_point_reward.title = 'New Title'
        expect(comp_point_reward.config['other']).to eq('value')
        expect(comp_point_reward.config['title']).to eq('New Title')
      end
    end

    describe 'bonus association' do
      it 'requires a bonus' do
        comp_point_reward.bonus = nil
        expect(comp_point_reward).not_to be_valid
        expect(comp_point_reward.errors[:bonus]).to include('must exist')
      end

      it 'deletes comp_point_reward when bonus is deleted' do
        comp_point_reward.save!
        bonus_id = comp_point_reward.bonus.id
        comp_point_reward.bonus.destroy
        expect(CompPointReward.find_by(bonus_id: bonus_id)).to be_nil
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
          'restrictions' => ['rule1', 'rule2'],
          'metadata' => {
            'created_by' => 'admin',
            'version' => 1.2
          }
        }
        comp_point_reward.config = complex_config
        comp_point_reward.save!
        comp_point_reward.reload
        
        expect(comp_point_reward.config['advanced']['auto_activate']).to be true
        expect(comp_point_reward.config['advanced']['settings']['duration']).to eq(30)
        expect(comp_point_reward.config['restrictions']).to eq(['rule1', 'rule2'])
        expect(comp_point_reward.config['metadata']['version']).to eq(1.2)
      end

      it 'preserves data types in config' do
        config_with_types = {
          'string' => 'text',
          'integer' => 42,
          'float' => 3.14,
          'boolean_true' => true,
          'boolean_false' => false,
          'null' => nil,
          'array' => [1, 2, 3],
          'hash' => { 'nested' => 'value' }
        }
        comp_point_reward.config = config_with_types
        comp_point_reward.save!
        comp_point_reward.reload
        
        expect(comp_point_reward.config['string']).to be_a(String)
        expect(comp_point_reward.config['integer']).to be_a(Integer)
        expect(comp_point_reward.config['float']).to be_a(Float)
        expect(comp_point_reward.config['boolean_true']).to be true
        expect(comp_point_reward.config['boolean_false']).to be false
        expect(comp_point_reward.config['null']).to be_nil
        expect(comp_point_reward.config['array']).to be_an(Array)
        expect(comp_point_reward.config['hash']).to be_a(Hash)
      end
    end

    describe 'database constraints' do
      it 'saves valid comp_point_reward successfully' do
        expect { comp_point_reward.save! }.not_to raise_error
      end

      it 'can be retrieved from database correctly' do
        comp_point_reward.save!
        retrieved = CompPointReward.find(comp_point_reward.id)
        expect(retrieved.points_amount).to eq(comp_point_reward.points_amount)
        expect(retrieved.multiplier).to eq(comp_point_reward.multiplier)
        expect(retrieved.bonus_id).to eq(comp_point_reward.bonus_id)
      end
    end

    describe 'calculation edge cases' do
      it 'handles small integer values with multiplier' do
        comp_point_reward.points_amount = 1
        comp_point_reward.multiplier = 1.1
        expect(comp_point_reward.total_value).to be_within(0.001).of(1.1)
      end

      it 'handles precision in calculations' do
        comp_point_reward.points_amount = 100
        comp_point_reward.multiplier = 1.1
        expect(comp_point_reward.total_value).to be_within(0.01).of(110.0)
      end
    end
  end

  # Factory validation
  describe 'factory' do
    it 'creates valid comp_point_reward from factory' do
      comp_point_reward = build(:comp_point_reward)
      expect(comp_point_reward).to be_valid
    end

    it 'creates comp_point_reward with reasonable default values' do
      comp_point_reward = build(:comp_point_reward)
      expect(comp_point_reward.points_amount).to be_present
      expect(comp_point_reward.bonus).to be_present
      expect(comp_point_reward.config).to eq({})
    end

    it 'can create and save comp_point_reward from factory' do
      expect { create(:comp_point_reward) }.not_to raise_error
    end
  end
end

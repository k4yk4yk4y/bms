# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FreechipReward, type: :model do
  subject(:freechip_reward) { build(:freechip_reward) }

  # Associations
  describe 'associations' do
    it { should belong_to(:bonus) }
  end

  # Validations
  describe 'validations' do
    describe 'presence validations' do
      it { should validate_presence_of(:chip_value) }
      it { should validate_presence_of(:chips_count) }
    end

    describe 'numericality validations' do
      it { should validate_numericality_of(:chip_value).is_greater_than(0) }
      it { should validate_numericality_of(:chips_count).is_greater_than(0) }
    end
  end

  # Instance methods
  describe 'instance methods' do
    let(:bonus) { create(:bonus, currency: 'USD') }
    let(:freechip_reward) { build(:freechip_reward, bonus: bonus, chip_value: 5.0, chips_count: 10) }

    describe '#total_value' do
      it 'calculates total value correctly' do
        expect(freechip_reward.total_value).to eq(50.0)
      end

      it 'handles decimal values' do
        freechip_reward.chip_value = 2.5
        freechip_reward.chips_count = 4
        expect(freechip_reward.total_value).to eq(10.0)
      end

      it 'handles large values' do
        freechip_reward.chip_value = 100.0
        freechip_reward.chips_count = 1000
        expect(freechip_reward.total_value).to eq(100000.0)
      end
    end

    describe '#formatted_chip_value' do
      it 'formats chip value with currency' do
        expect(freechip_reward.formatted_chip_value).to eq('5.0 USD')
      end

      it 'handles different currencies' do
        bonus.currency = 'EUR'
        expect(freechip_reward.formatted_chip_value).to eq('5.0 EUR')
      end

      it 'handles integer values' do
        freechip_reward.chip_value = 10
        expect(freechip_reward.formatted_chip_value).to eq('10.0 USD')
      end

      it 'handles decimal values' do
        freechip_reward.chip_value = 7.25
        expect(freechip_reward.formatted_chip_value).to eq('7.25 USD')
      end
    end

    describe '#formatted_total_value' do
      it 'formats total value with currency' do
        expect(freechip_reward.formatted_total_value).to eq('50.0 USD')
      end

      it 'handles different currencies' do
        bonus.currency = 'EUR'
        expect(freechip_reward.formatted_total_value).to eq('50.0 EUR')
      end

      it 'calculates and formats correctly for decimal values' do
        freechip_reward.chip_value = 2.5
        freechip_reward.chips_count = 6
        expect(freechip_reward.formatted_total_value).to eq('15.0 USD')
      end
    end
  end

  # Edge cases and validations
  describe 'edge cases' do
    describe 'chip_value validations' do
      it 'rejects zero chip_value' do
        freechip_reward.chip_value = 0
        expect(freechip_reward).not_to be_valid
        expect(freechip_reward.errors[:chip_value]).to include('must be greater than 0')
      end

      it 'rejects negative chip_value' do
        freechip_reward.chip_value = -5.0
        expect(freechip_reward).not_to be_valid
        expect(freechip_reward.errors[:chip_value]).to include('must be greater than 0')
      end

      it 'accepts very small positive values' do
        freechip_reward.chip_value = 0.01
        expect(freechip_reward).to be_valid
      end

      it 'accepts very large values' do
        freechip_reward.chip_value = 999999.99
        expect(freechip_reward).to be_valid
      end

      it 'rejects nil chip_value' do
        freechip_reward.chip_value = nil
        expect(freechip_reward).not_to be_valid
        expect(freechip_reward.errors[:chip_value]).to include("can't be blank")
      end

      it 'handles string assignment to chip_value' do
        freechip_reward.chip_value = '10.5'
        expect(freechip_reward.chip_value).to eq(10.5)
      end
    end

    describe 'chips_count validations' do
      it 'rejects zero chips_count' do
        freechip_reward.chips_count = 0
        expect(freechip_reward).not_to be_valid
        expect(freechip_reward.errors[:chips_count]).to include('must be greater than 0')
      end

      it 'rejects negative chips_count' do
        freechip_reward.chips_count = -10
        expect(freechip_reward).not_to be_valid
        expect(freechip_reward.errors[:chips_count]).to include('must be greater than 0')
      end

      it 'accepts very large counts' do
        freechip_reward.chips_count = 999999
        expect(freechip_reward).to be_valid
      end

      it 'rejects nil chips_count' do
        freechip_reward.chips_count = nil
        expect(freechip_reward).not_to be_valid
        expect(freechip_reward.errors[:chips_count]).to include("can't be blank")
      end

      it 'handles decimal chips_count by converting to integer' do
        freechip_reward.chips_count = 5.5
        expect(freechip_reward.chips_count).to eq(5)
      end

      it 'handles string assignment to chips_count' do
        freechip_reward.chips_count = '10'
        expect(freechip_reward.chips_count).to eq(10)
      end
    end

    describe 'total_value calculations' do
      it 'handles precision correctly for decimal calculations' do
        freechip_reward.chip_value = 0.33
        freechip_reward.chips_count = 3
        expect(freechip_reward.total_value).to be_within(0.01).of(0.99)
      end

      it 'handles large calculations' do
        freechip_reward.chip_value = 1000.0
        freechip_reward.chips_count = 1000
        expect(freechip_reward.total_value).to eq(1000000.0)
      end

      it 'handles very small calculations' do
        freechip_reward.chip_value = 0.01
        freechip_reward.chips_count = 1
        expect(freechip_reward.total_value).to eq(0.01)
      end
    end

    describe 'bonus association' do
      it 'requires a bonus' do
        freechip_reward.bonus = nil
        expect(freechip_reward).not_to be_valid
        expect(freechip_reward.errors[:bonus]).to include('must exist')
      end

      it 'deletes freechip_reward when bonus is deleted' do
        freechip_reward.save!
        bonus_id = freechip_reward.bonus.id
        freechip_reward.bonus.destroy
        expect(FreechipReward.find_by(bonus_id: bonus_id)).to be_nil
      end
    end

    describe 'database constraints' do
      it 'saves valid freechip_reward successfully' do
        expect { freechip_reward.save! }.not_to raise_error
      end

      it 'can be retrieved from database correctly' do
        freechip_reward.save!
        retrieved = FreechipReward.find(freechip_reward.id)
        expect(retrieved.chip_value).to eq(freechip_reward.chip_value)
        expect(retrieved.chips_count).to eq(freechip_reward.chips_count)
        expect(retrieved.bonus_id).to eq(freechip_reward.bonus_id)
      end
    end

    describe 'formatting edge cases' do
      it 'handles currency with nil bonus currency' do
        freechip_reward.chip_value = 5.0
        freechip_reward.chips_count = 10
        freechip_reward.bonus.currency = nil
        expect(freechip_reward.formatted_chip_value).to eq('5.0 ')
        expect(freechip_reward.formatted_total_value).to eq('50.0 ')
      end

      it 'handles empty currency' do
        freechip_reward.chip_value = 5.0
        freechip_reward.chips_count = 10
        freechip_reward.bonus.currency = ''
        expect(freechip_reward.formatted_chip_value).to eq('5.0 ')
        expect(freechip_reward.formatted_total_value).to eq('50.0 ')
      end

      it 'handles zero total value display' do
        freechip_reward.chip_value = 0.01
        freechip_reward.chips_count = 0  # This would be invalid, but testing calculation
        expect(freechip_reward.total_value).to eq(0.0)
      end
    end
  end

  # Factory validation
  describe 'factory' do
    it 'creates valid freechip_reward from factory' do
      freechip_reward = build(:freechip_reward)
      expect(freechip_reward).to be_valid
    end

    it 'creates freechip_reward with reasonable default values' do
      freechip_reward = build(:freechip_reward)
      expect(freechip_reward.chip_value).to be > 0
      expect(freechip_reward.chips_count).to be > 0
      expect(freechip_reward.bonus).to be_present
    end

    it 'can create and save freechip_reward from factory' do
      expect { create(:freechip_reward) }.not_to raise_error
    end
  end
end

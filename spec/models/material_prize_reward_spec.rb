# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MaterialPrizeReward, type: :model do
  subject(:material_prize_reward) { build(:material_prize_reward) }

  # Associations
  describe 'associations' do
    it { should belong_to(:bonus) }
  end

  # Validations
  describe 'validations' do
    describe 'presence validations' do
      it { should validate_presence_of(:prize_name) }
    end

    describe 'numericality validations' do
      it { should validate_numericality_of(:prize_value).is_greater_than_or_equal_to(0).allow_nil }
    end
  end

  # Instance methods
  describe 'instance methods' do
    let(:bonus) { create(:bonus, currency: 'USD') }
    let(:material_prize_reward) { build(:material_prize_reward, bonus: bonus, prize_name: 'iPhone 15', prize_value: 999.99) }

    describe '#formatted_prize_value' do
      it 'formats prize value with currency when value is present' do
        expect(material_prize_reward.formatted_prize_value).to eq('999.99 USD')
      end

      it 'returns "N/A" when prize value is nil' do
        material_prize_reward.prize_value = nil
        expect(material_prize_reward.formatted_prize_value).to eq('N/A')
      end

      it 'returns "N/A" when prize value is blank' do
        material_prize_reward.prize_value = ''
        expect(material_prize_reward.formatted_prize_value).to eq('N/A')
      end

      it 'formats zero value correctly' do
        material_prize_reward.prize_value = 0
        expect(material_prize_reward.formatted_prize_value).to eq('0.0 USD')
      end

      it 'handles different currencies' do
        bonus.currency = 'EUR'
        expect(material_prize_reward.formatted_prize_value).to eq('999.99 EUR')
      end

      it 'handles integer values' do
        material_prize_reward.prize_value = 500
        expect(material_prize_reward.formatted_prize_value).to eq('500.0 USD')
      end

      it 'handles decimal values' do
        material_prize_reward.prize_value = 123.45
        expect(material_prize_reward.formatted_prize_value).to eq('123.45 USD')
      end

      it 'handles very large values' do
        material_prize_reward.prize_value = 999999.99
        expect(material_prize_reward.formatted_prize_value).to eq('999999.99 USD')
      end

      it 'handles very small values' do
        material_prize_reward.prize_value = 0.01
        expect(material_prize_reward.formatted_prize_value).to eq('0.01 USD')
      end

      it 'handles nil currency' do
        bonus.currency = nil
        expect(material_prize_reward.formatted_prize_value).to eq('999.99 ')
      end

      it 'handles empty currency' do
        bonus.currency = ''
        expect(material_prize_reward.formatted_prize_value).to eq('999.99 ')
      end
    end

    describe '#has_monetary_value?' do
      it 'returns true when prize value is present and greater than zero' do
        material_prize_reward.prize_value = 100.0
        expect(material_prize_reward).to have_monetary_value
      end

      it 'returns true for very small positive values' do
        material_prize_reward.prize_value = 0.01
        expect(material_prize_reward).to have_monetary_value
      end

      it 'returns false when prize value is zero' do
        material_prize_reward.prize_value = 0
        expect(material_prize_reward).not_to have_monetary_value
      end

      it 'returns false when prize value is nil' do
        material_prize_reward.prize_value = nil
        expect(material_prize_reward).not_to have_monetary_value
      end

      it 'returns false when prize value is blank' do
        material_prize_reward.prize_value = ''
        expect(material_prize_reward).not_to have_monetary_value
      end

      it 'returns false for negative values (though validation should prevent this)' do
        material_prize_reward.prize_value = -10.0
        expect(material_prize_reward).not_to have_monetary_value
      end

      it 'handles edge case of very large values' do
        material_prize_reward.prize_value = 999999999.99
        expect(material_prize_reward).to have_monetary_value
      end
    end
  end

  # Edge cases and validations
  describe 'edge cases' do
    describe 'prize_name validations' do
      it 'rejects nil prize_name' do
        material_prize_reward.prize_name = nil
        expect(material_prize_reward).not_to be_valid
        expect(material_prize_reward.errors[:prize_name]).to include("can't be blank")
      end

      it 'rejects empty prize_name' do
        material_prize_reward.prize_name = ''
        expect(material_prize_reward).not_to be_valid
        expect(material_prize_reward.errors[:prize_name]).to include("can't be blank")
      end

      it 'rejects blank prize_name' do
        material_prize_reward.prize_name = '   '
        expect(material_prize_reward).not_to be_valid
        expect(material_prize_reward.errors[:prize_name]).to include("can't be blank")
      end

      it 'accepts valid prize names' do
        valid_names = [
          'iPhone 15 Pro',
          'MacBook Air',
          'Tesla Model S',
          'Rolex Watch',
          'Gift Card $100',
          'Vacation Package',
          'Gaming Console',
          'Smartphone',
          'Laptop Computer',
          'Smart TV 55"'
        ]

        valid_names.each do |name|
          material_prize_reward.prize_name = name
          expect(material_prize_reward).to be_valid, "Expected '#{name}' to be valid"
        end
      end

      it 'accepts prize names with special characters' do
        special_names = [
          'Prize #1',
          'Gift (Premium)',
          'Item-123',
          'Product/Service',
          'Award & Trophy',
          'Bonus: Special Edition',
          'Item 50%',
          'Package €500',
          'Device 10"',
          'Set 2x1'
        ]

        special_names.each do |name|
          material_prize_reward.prize_name = name
          expect(material_prize_reward).to be_valid, "Expected '#{name}' to be valid"
        end
      end

      it 'accepts very long prize names' do
        long_name = 'A' * 1000
        material_prize_reward.prize_name = long_name
        expect(material_prize_reward).to be_valid
      end

      it 'handles unicode characters' do
        unicode_names = [
          'Приз iPhone',
          'Подарок 🎁',
          'Награда №1',
          'Премия "Лучший"',
          'Товар для дома',
          'Электроника'
        ]

        unicode_names.each do |name|
          material_prize_reward.prize_name = name
          expect(material_prize_reward).to be_valid, "Expected '#{name}' to be valid"
        end
      end
    end

    describe 'prize_value validations' do
      it 'accepts nil prize_value' do
        material_prize_reward.prize_value = nil
        expect(material_prize_reward).to be_valid
      end

      it 'accepts zero prize_value' do
        material_prize_reward.prize_value = 0
        expect(material_prize_reward).to be_valid
      end

      it 'accepts positive prize_value' do
        material_prize_reward.prize_value = 100.50
        expect(material_prize_reward).to be_valid
      end

      it 'rejects negative prize_value' do
        material_prize_reward.prize_value = -50.0
        expect(material_prize_reward).not_to be_valid
        expect(material_prize_reward.errors[:prize_value]).to include('must be greater than or equal to 0')
      end

      it 'accepts very small positive values' do
        material_prize_reward.prize_value = 0.01
        expect(material_prize_reward).to be_valid
      end

      it 'accepts very large values' do
        material_prize_reward.prize_value = 999999999.99
        expect(material_prize_reward).to be_valid
      end

      it 'accepts decimal values with many decimal places' do
        material_prize_reward.prize_value = 123.456789
        expect(material_prize_reward).to be_valid
      end

      it 'handles string assignment to prize_value' do
        material_prize_reward.prize_value = '123.45'
        expect(material_prize_reward.prize_value).to eq(123.45)
      end

      it 'handles string numeric values' do
        material_prize_reward.prize_value = '123.45'
        expect(material_prize_reward.prize_value).to eq(123.45)
        expect(material_prize_reward).to be_valid
      end
    end

    describe 'bonus association' do
      it 'requires a bonus' do
        material_prize_reward.bonus = nil
        expect(material_prize_reward).not_to be_valid
        expect(material_prize_reward.errors[:bonus]).to include('must exist')
      end

      it 'deletes material_prize_reward when bonus is deleted' do
        material_prize_reward.save!
        bonus_id = material_prize_reward.bonus.id
        material_prize_reward.bonus.destroy
        expect(MaterialPrizeReward.find_by(bonus_id: bonus_id)).to be_nil
      end
    end

    describe 'database constraints' do
      it 'saves valid material_prize_reward successfully' do
        expect { material_prize_reward.save! }.not_to raise_error
      end

      it 'can be retrieved from database correctly' do
        material_prize_reward.save!
        retrieved = MaterialPrizeReward.find(material_prize_reward.id)
        expect(retrieved.prize_name).to eq(material_prize_reward.prize_name)
        expect(retrieved.prize_value).to eq(material_prize_reward.prize_value)
        expect(retrieved.bonus_id).to eq(material_prize_reward.bonus_id)
      end

      it 'preserves data types after save/reload' do
        material_prize_reward.prize_value = 123.45
        material_prize_reward.save!
        material_prize_reward.reload
        expect(material_prize_reward.prize_value).to be_a(BigDecimal)
        expect(material_prize_reward.prize_value.to_f).to eq(123.45)
      end
    end

    describe 'formatting edge cases' do
      it 'handles precision in floating point calculations' do
        bonus = create(:bonus, currency: 'USD')
        material_prize_reward = build(:material_prize_reward, bonus: bonus)
        material_prize_reward.prize_value = 0.1 + 0.2  # Classic floating point precision issue
        expect(material_prize_reward.formatted_prize_value).to match(/0\.30*\d* USD/)
      end

      it 'handles very precise decimal values' do
        bonus = create(:bonus, currency: 'USD')
        material_prize_reward = build(:material_prize_reward, bonus: bonus)
        material_prize_reward.prize_value = 99.999999999
        expect(material_prize_reward.formatted_prize_value).to include('100.0')
        expect(material_prize_reward.formatted_prize_value).to include('USD')
      end

      it 'handles scientific notation values' do
        bonus = create(:bonus, currency: 'USD')
        material_prize_reward = build(:material_prize_reward, bonus: bonus)
        material_prize_reward.prize_value = 1e6  # 1,000,000
        expect(material_prize_reward.formatted_prize_value).to eq('1000000.0 USD')
      end
    end

    describe 'business logic edge cases' do
      it 'handles prizes without monetary value correctly' do
        material_prize_reward.prize_name = 'Free T-Shirt'
        material_prize_reward.prize_value = nil
        expect(material_prize_reward).to be_valid
        expect(material_prize_reward).not_to have_monetary_value
        expect(material_prize_reward.formatted_prize_value).to eq('N/A')
      end

      it 'handles symbolic prizes (zero value) correctly' do
        bonus = create(:bonus, currency: 'USD')
        material_prize_reward = build(:material_prize_reward, bonus: bonus)
        material_prize_reward.prize_name = 'Certificate of Achievement'
        material_prize_reward.prize_value = 0
        expect(material_prize_reward).to be_valid
        expect(material_prize_reward).not_to have_monetary_value
        expect(material_prize_reward.formatted_prize_value).to eq('0.0 USD')
      end

      it 'handles expensive prizes correctly' do
        bonus = create(:bonus, currency: 'USD')
        material_prize_reward = build(:material_prize_reward, bonus: bonus)
        material_prize_reward.prize_name = 'Luxury Car'
        material_prize_reward.prize_value = 75000.00
        expect(material_prize_reward).to be_valid
        expect(material_prize_reward).to have_monetary_value
        expect(material_prize_reward.formatted_prize_value).to eq('75000.0 USD')
      end
    end
  end

  # Real-world scenarios
  describe 'real-world scenarios' do
    let(:bonus) { create(:bonus, currency: 'USD') }

    it 'handles electronic device prizes' do
      electronic_prizes = [
        { name: 'iPhone 15 Pro Max', value: 1199.99 },
        { name: 'MacBook Pro 16"', value: 2499.00 },
        { name: 'iPad Air', value: 599.99 },
        { name: 'AirPods Pro', value: 249.00 },
        { name: 'Apple Watch Ultra', value: 799.00 }
      ]

      electronic_prizes.each do |prize_data|
        reward = build(:material_prize_reward,
                      bonus: bonus,
                      prize_name: prize_data[:name],
                      prize_value: prize_data[:value])
        expect(reward).to be_valid
        expect(reward).to have_monetary_value
        expect(reward.formatted_prize_value).to include(prize_data[:value].to_s)
      end
    end

    it 'handles gift card prizes' do
      gift_cards = [
        { name: 'Amazon Gift Card $50', value: 50.00 },
        { name: 'Steam Wallet $25', value: 25.00 },
        { name: 'Google Play $10', value: 10.00 },
        { name: 'App Store $100', value: 100.00 }
      ]

      gift_cards.each do |card_data|
        reward = build(:material_prize_reward,
                      bonus: bonus,
                      prize_name: card_data[:name],
                      prize_value: card_data[:value])
        expect(reward).to be_valid
        expect(reward).to have_monetary_value
      end
    end

    it 'handles non-monetary prizes' do
      non_monetary_prizes = [
        'VIP Status',
        'Special Badge',
        'Certificate',
        'Trophy',
        'Medal'
      ]

      non_monetary_prizes.each do |prize_name|
        reward = build(:material_prize_reward,
                      bonus: bonus,
                      prize_name: prize_name,
                      prize_value: nil)
        expect(reward).to be_valid
        expect(reward).not_to have_monetary_value
        expect(reward.formatted_prize_value).to eq('N/A')
      end
    end
  end

  # Factory validation
  describe 'factory' do
    it 'creates valid material_prize_reward from factory' do
      material_prize_reward = build(:material_prize_reward)
      expect(material_prize_reward).to be_valid
    end

    it 'creates material_prize_reward with reasonable default values' do
      material_prize_reward = build(:material_prize_reward)
      expect(material_prize_reward.prize_name).to be_present
      expect(material_prize_reward.prize_value).to be_present
      expect(material_prize_reward.bonus).to be_present
    end

    it 'can create and save material_prize_reward from factory' do
      expect { create(:material_prize_reward) }.not_to raise_error
    end
  end
end

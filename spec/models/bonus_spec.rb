# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bonus, type: :model do
  subject(:bonus) { build(:bonus) }

  # Constants tests
  describe 'constants' do
    it 'has valid STATUSES' do
      expect(Bonus::STATUSES).to eq(%w[draft active inactive expired])
    end

    it 'has valid EVENT_TYPES' do
      expect(Bonus::EVENT_TYPES).to eq(%w[deposit input_coupon manual collection groups_update scheduler])
    end
  end

  # Associations tests
  describe 'associations' do
    it { is_expected.to have_many(:bonus_rewards).dependent(:destroy) }
    it { is_expected.to have_many(:freespin_rewards).dependent(:destroy) }
    it { is_expected.to have_many(:bonus_buy_rewards).dependent(:destroy) }
    it { is_expected.to have_many(:comp_point_rewards).dependent(:destroy) }
    it { is_expected.to have_many(:bonus_code_rewards).dependent(:destroy) }
    it { is_expected.to have_many(:freechip_rewards).dependent(:destroy) }
    it { is_expected.to have_many(:material_prize_rewards).dependent(:destroy) }
    it { is_expected.to belong_to(:dsl_tag).optional }
  end

  # Validations tests
  describe 'validations' do
    describe 'presence validations' do
      it { is_expected.to validate_presence_of(:name) }

      it 'allows code to be blank' do
        bonus.code = nil
        expect(bonus).to be_valid
        bonus.code = ""
        expect(bonus).to be_valid
      end

      it { is_expected.to validate_presence_of(:event) }
      it { is_expected.to validate_presence_of(:status) }
      it { is_expected.to validate_presence_of(:availability_start_date) }
      it { is_expected.to validate_presence_of(:availability_end_date) }
      it 'validates currencies presence' do
        bonus.currencies = []
        expect(bonus).to be_valid # currencies can be empty (all currencies)
      end
    end

    describe 'length validations' do
      it { is_expected.to validate_length_of(:name).is_at_most(255) }
      it { is_expected.to validate_length_of(:code).is_at_most(50) }
      # Currency length validation removed - now using currencies array
      it 'validates length of dsl_tag string attribute' do
        bonus = build(:bonus)
        bonus.write_attribute(:dsl_tag, 'x' * 256)
        expect(bonus).not_to be_valid
        expect(bonus.errors[:dsl_tag]).to be_present
      end
      it { is_expected.to validate_length_of(:description).is_at_most(1000) }
    end

    describe 'inclusion validations' do
      it { is_expected.to validate_inclusion_of(:event).in_array(Bonus::EVENT_TYPES) }
      it { is_expected.to validate_inclusion_of(:status).in_array(Bonus::STATUSES) }
    end



    describe 'custom validations' do
      context 'end_date_after_start_date' do
        it 'is invalid when end date is before start date' do
          bonus.availability_start_date = 1.day.from_now
          bonus.availability_end_date = 1.day.ago
          expect(bonus).not_to be_valid
          expect(bonus.errors[:availability_end_date]).to include('must be after start date')
        end

        it 'is invalid when end date equals start date' do
          date = Time.current
          bonus.availability_start_date = date
          bonus.availability_end_date = date
          expect(bonus).not_to be_valid
          expect(bonus.errors[:availability_end_date]).to include('must be after start date')
        end

        it 'is valid when end date is after start date' do
          bonus.availability_start_date = 1.day.ago
          bonus.availability_end_date = 1.day.from_now
          expect(bonus).to be_valid
        end
      end

      context 'valid_decimal_fields' do
        %i[minimum_deposit wager maximum_winnings].each do |field|
          it "validates #{field} is not negative" do
            bonus.send("#{field}=", -1)
            expect(bonus).not_to be_valid
            expect(bonus.errors[field]).to include('must be greater than or equal to 0')
          end

          it "allows #{field} to be zero" do
            bonus.send("#{field}=", 0)
            expect(bonus).to be_valid
          end

          it "allows #{field} to be positive" do
            bonus.send("#{field}=", 100.50)
            expect(bonus).to be_valid
          end

          it "allows #{field} to be nil" do
            bonus.send("#{field}=", nil)
            expect(bonus).to be_valid
          end
        end
      end

      context 'minimum_deposit_for_appropriate_types' do
        %w[input_coupon manual collection groups_update scheduler].each do |event_type|
          it "does not allow minimum_deposit for #{event_type} event" do
            bonus.event = event_type
            bonus.minimum_deposit = 50.0
            bonus.currency_minimum_deposits = {}
            expect(bonus).not_to be_valid
            expect(bonus.errors[:minimum_deposit]).to include("must not be set for event #{event_type}")
          end

          it "allows nil minimum_deposit for #{event_type} event" do
            bonus.event = event_type
            bonus.minimum_deposit = nil
            bonus.currency_minimum_deposits = {}
            expect(bonus).to be_valid
          end
        end

        it 'allows minimum_deposit for deposit event' do
          bonus.event = 'deposit'
          bonus.minimum_deposit = 50.0
          expect(bonus).to be_valid
        end
      end

      context 'valid_currency_minimum_deposits' do
        it 'does not allow currency_minimum_deposits for non-deposit events' do
          bonus.event = 'input_coupon'
          bonus.currency_minimum_deposits = { 'USD' => 50.0 }
          expect(bonus).not_to be_valid
          expect(bonus.errors[:currency_minimum_deposits]).to include('must not be set for event input_coupon')
        end

        it 'validates positive amounts' do
          bonus.event = 'deposit'
          bonus.currency_minimum_deposits = { 'USD' => 0 }
          expect(bonus).not_to be_valid
          expect(bonus.errors[:currency_minimum_deposits]).to include('for currency USD must be a positive number')
        end

        it 'validates currencies are in supported list' do
          bonus.event = 'deposit'
          bonus.currencies = [ 'USD' ]
          bonus.currency_minimum_deposits = { 'EUR' => 50.0 }
          expect(bonus).not_to be_valid
          expect(bonus.errors[:currency_minimum_deposits]).to include('contains currencies not listed as supported: EUR')
        end

        it 'allows valid currency_minimum_deposits for deposit event' do
          bonus.event = 'deposit'
          bonus.currencies = %w[USD EUR]
          bonus.currency_minimum_deposits = { 'USD' => 50.0, 'EUR' => 45.0 }
          expect(bonus).to be_valid
        end
      end
    end
  end

  # Serialization tests
  describe 'serialization' do
    describe '#currencies' do
      it 'returns empty array when nil' do
        bonus.write_attribute(:currencies, nil)
        expect(bonus.currencies).to eq([])
      end

      it 'handles array input' do
        bonus.currencies = %w[USD EUR RUB]
        expect(bonus.currencies).to eq(%w[USD EUR RUB])
      end

      it 'handles string input' do
        bonus.currencies = 'USD, EUR, RUB'
        expect(bonus.currencies).to eq(%w[USD EUR RUB])
      end

      it 'filters blank values' do
        bonus.currencies = [ 'USD', '', 'EUR', nil, 'RUB' ]
        expect(bonus.currencies).to eq(%w[USD EUR RUB])
      end
    end

    describe '#groups' do
      it 'returns empty array when nil' do
        bonus.write_attribute(:groups, nil)
        expect(bonus.groups).to eq([])
      end

      it 'handles array input' do
        bonus.groups = %w[VIP Regular Premium]
        expect(bonus.groups).to eq(%w[VIP Regular Premium])
      end

      it 'handles string input' do
        bonus.groups = 'VIP, Regular, Premium'
        expect(bonus.groups).to eq(%w[VIP Regular Premium])
      end
    end

    describe '#currency_minimum_deposits' do
      it 'returns empty hash when nil' do
        bonus.write_attribute(:currency_minimum_deposits, nil)
        expect(bonus.currency_minimum_deposits).to eq({})
      end

      it 'handles hash input' do
        deposits = { 'USD' => 50.0, 'EUR' => 45.0 }
        bonus.currency_minimum_deposits = deposits
        expect(bonus.currency_minimum_deposits).to eq(deposits)
      end

      it 'converts string values to float' do
        bonus.currency_minimum_deposits = { 'USD' => '50.5', 'EUR' => '45' }
        expect(bonus.currency_minimum_deposits).to eq({ 'USD' => 50.5, 'EUR' => 45.0 })
      end

      it 'filters blank values' do
        bonus.currency_minimum_deposits = { 'USD' => 50.0, 'EUR' => '', 'RUB' => nil }
        expect(bonus.currency_minimum_deposits).to eq({ 'USD' => 50.0 })
      end
    end
  end

  # Callbacks tests
  describe 'callbacks' do
    describe 'after_find :check_and_update_expired_status!' do
      it 'updates status to inactive when expired and active' do
        bonus = create(:bonus, :active, availability_start_date: 2.days.ago, availability_end_date: 1.day.ago)
        reloaded_bonus = Bonus.find(bonus.id)
        expect(reloaded_bonus.status).to eq('inactive')
      end

      it 'does not update status when not expired' do
        bonus = create(:bonus, :active, availability_end_date: 1.day.from_now)
        reloaded_bonus = Bonus.find(bonus.id)
        expect(reloaded_bonus.status).to eq('active')
      end

      it 'does not update status when already inactive' do
        bonus = create(:bonus, :inactive, availability_start_date: 2.days.ago, availability_end_date: 1.day.ago)
        reloaded_bonus = Bonus.find(bonus.id)
        expect(reloaded_bonus.status).to eq('inactive')
      end
    end
  end

  # Scopes tests
  describe 'scopes' do
    let!(:draft_bonus) { create(:bonus, :draft) }
    let!(:active_bonus) { create(:bonus, :active) }
    let!(:inactive_bonus) { create(:bonus, :inactive) }
    let!(:expired_bonus) { create(:bonus, :expired) }

    it '.draft returns only draft bonuses' do
      expect(Bonus.draft).to contain_exactly(draft_bonus)
    end

    it '.active returns only active bonuses' do
      expect(Bonus.active).to contain_exactly(active_bonus)
    end

    it '.inactive returns only inactive bonuses' do
      expect(Bonus.inactive).to contain_exactly(inactive_bonus)
    end

    it '.expired returns only expired bonuses' do
      expect(Bonus.expired).to contain_exactly(expired_bonus)
    end

    context 'event scopes' do
      let!(:deposit_bonus) { create(:bonus, :deposit_event) }
      let!(:coupon_bonus) { create(:bonus, :input_coupon_event) }

      it '.by_event filters by event type' do
        expect(Bonus.by_event('deposit')).to include(deposit_bonus)
        expect(Bonus.by_event('deposit')).not_to include(coupon_bonus)
      end

      it '.deposit_event returns only deposit bonuses' do
        expect(Bonus.deposit_event).to include(deposit_bonus)
        expect(Bonus.deposit_event).not_to include(coupon_bonus)
      end

      it '.input_coupon_event returns only input_coupon bonuses' do
        expect(Bonus.input_coupon_event).to include(coupon_bonus)
        expect(Bonus.input_coupon_event).not_to include(deposit_bonus)
      end
    end

    context 'filter scopes' do
      let!(:usd_bonus) { create(:bonus, currencies: [ 'USD' ], currency_minimum_deposits: { 'USD' => 50.0 }) }
      let!(:eur_bonus) { create(:bonus, currencies: [ 'EUR' ], currency_minimum_deposits: { 'EUR' => 45.0 }) }
      let!(:us_bonus) { create(:bonus, country: 'US') }
      let!(:de_bonus) { create(:bonus, country: 'DE') }

      it '.by_currency filters by currency' do
        expect(Bonus.by_currency('USD')).to include(usd_bonus)
        expect(Bonus.by_currency('USD')).not_to include(eur_bonus)
      end

      it '.by_country filters by country' do
        expect(Bonus.by_country('US')).to include(us_bonus)
        expect(Bonus.by_country('US')).not_to include(de_bonus)
      end
    end

    context '.available_now' do
      let!(:available_bonus) { create(:bonus, :available_now) }
      let!(:future_bonus) { create(:bonus, :future) }
      let!(:past_bonus) { create(:bonus, :past) }

      it 'returns only currently available bonuses' do
        expect(Bonus.available_now).to include(available_bonus)
        expect(Bonus.available_now).not_to include(future_bonus, past_bonus)
      end
    end
  end

  # Instance methods tests
  describe 'instance methods' do
    let(:bonus) { build(:bonus, :active, :available_now) }

    describe '#active?' do
      it 'returns true for active and available bonus' do
        expect(bonus).to be_active
      end

      it 'returns false for inactive bonus even if available' do
        bonus.status = 'inactive'
        expect(bonus).not_to be_active
      end

      it 'returns false for active but unavailable bonus' do
        bonus.availability_start_date = 1.day.from_now
        expect(bonus).not_to be_active
      end

      it 'returns false for expired bonus' do
        bonus.availability_end_date = 1.day.ago
        expect(bonus).not_to be_active
      end
    end

    describe '#available_now?' do
      it 'returns true when current time is within availability period' do
        expect(bonus).to be_available_now
      end

      it 'returns false when current time is before start date' do
        bonus.availability_start_date = 1.day.from_now
        expect(bonus).not_to be_available_now
      end

      it 'returns false when current time is after end date' do
        bonus.availability_end_date = 1.day.ago
        expect(bonus).not_to be_available_now
      end

      it 'handles exact boundary times' do
        freeze_time do
          bonus.availability_start_date = Time.current
          bonus.availability_end_date = Time.current + 1.hour
          expect(bonus).to be_available_now
        end
      end
    end

    describe '#expired?' do
      it 'returns true when end date is in the past' do
        bonus.availability_end_date = 1.day.ago
        expect(bonus).to be_expired
      end

      it 'returns false when end date is in the future' do
        bonus.availability_end_date = 1.day.from_now
        expect(bonus).not_to be_expired
      end

      it 'returns false when end date is now' do
        freeze_time do
          bonus.availability_end_date = Time.current
          expect(bonus).not_to be_expired
        end
      end
    end

    describe 'reward system methods' do
      let!(:bonus_with_rewards) { create(:bonus, :with_bonus_rewards, :with_freespin_rewards) }

      describe '#all_rewards' do
        it 'returns all reward types in a flattened array' do
          rewards = bonus_with_rewards.all_rewards
          expect(rewards).to be_an(Array)
          expect(rewards.length).to eq(2)
        end

        it 'returns empty array when no rewards' do
          empty_bonus = create(:bonus)
          expect(empty_bonus.all_rewards).to eq([])
        end
      end

      describe '#has_rewards?' do
        it 'returns true when bonus has rewards' do
          expect(bonus_with_rewards).to have_rewards
        end

        it 'returns false when bonus has no rewards' do
          empty_bonus = create(:bonus)
          expect(empty_bonus).not_to have_rewards
        end
      end

      describe '#reward_types' do
        it 'returns array of reward type names' do
          types = bonus_with_rewards.reward_types
          expect(types).to include('bonus', 'freespins')
        end

        it 'returns empty array when no rewards' do
          empty_bonus = create(:bonus)
          expect(empty_bonus.reward_types).to eq([])
        end
      end
    end

    describe 'display methods' do
      let!(:bonus_with_code_reward) { create(:bonus, :with_bonus_code_rewards) }

      describe '#display_code' do
        it 'returns reward code when available' do
          reward = bonus_with_code_reward.bonus_code_rewards.first
          reward.code = 'REWARD_CODE'
          reward.save!
          expect(bonus_with_code_reward.display_code).to eq('REWARD_CODE')
        end

        it 'falls back to bonus code when no reward code' do
          bonus.code = 'BONUS_CODE'
          expect(bonus.display_code).to eq('BONUS_CODE')
        end
      end

      describe '#display_currency' do
        it 'returns reward currencies when available' do
          bonus_with_code_reward.currencies = [ 'USD', 'EUR' ]
          result = bonus_with_code_reward.display_currency
          expect(result).to eq('USD, EUR')
        end

        it 'falls back to bonus currencies when no reward currencies' do
          bonus.currencies = [ 'GBP', 'EUR' ]
          expect(bonus.display_currency).to eq('GBP, EUR')
        end
      end
    end

    describe 'status management methods' do
      describe '#activate!' do
        it 'sets status to active' do
          bonus.status = 'draft'
          bonus.save!
          bonus.activate!
          expect(bonus.status).to eq('active')
        end
      end

      describe '#deactivate!' do
        it 'sets status to inactive' do
          bonus.status = 'active'
          bonus.save!
          bonus.deactivate!
          expect(bonus.status).to eq('inactive')
        end
      end

      describe '#mark_as_expired!' do
        it 'sets status to expired' do
          bonus.status = 'active'
          bonus.save!
          bonus.mark_as_expired!
          expect(bonus.status).to eq('expired')
        end
      end
    end

    describe '#tags_array and #tags_array=' do
      it 'converts comma-separated tags to array' do
        bonus.tags = 'tag1, tag2, tag3'
        expect(bonus.tags_array).to eq([ 'tag1', 'tag2', 'tag3' ])
      end

      it 'sets tags from array' do
        bonus.tags_array = [ 'new1', 'new2' ]
        expect(bonus.tags).to eq('new1, new2')
      end

      it 'handles empty tags' do
        bonus.tags = ''
        expect(bonus.tags_array).to eq([])
      end

      it 'handles nil tags' do
        bonus.tags = nil
        expect(bonus.tags_array).to eq([])
      end
    end

    describe 'formatting methods' do
      describe '#formatted_currencies' do
        it 'joins currencies with comma' do
          bonus.currencies = [ 'USD', 'EUR', 'GBP' ]
          expect(bonus.formatted_currencies).to eq('USD, EUR, GBP')
        end

        it 'returns nil for empty currencies' do
          bonus.currencies = []
          expect(bonus.formatted_currencies).to be_nil
        end
      end

      describe '#formatted_groups' do
        it 'joins groups with comma' do
          bonus.groups = [ 'VIP', 'Regular', 'Premium' ]
          expect(bonus.formatted_groups).to eq('VIP, Regular, Premium')
        end

        it 'returns nil for empty groups' do
          bonus.groups = []
          expect(bonus.formatted_groups).to be_nil
        end
      end

      describe '#formatted_currency_minimum_deposits' do
        it 'formats currency deposits correctly' do
          bonus.currency_minimum_deposits = { 'USD' => 50.0, 'EUR' => 45.0 }
          result = bonus.formatted_currency_minimum_deposits
          expect(result).to include('USD: 50.0')
          expect(result).to include('EUR: 45.0')
        end

        it 'returns default message for empty deposits' do
          bonus.currency_minimum_deposits = {}
          expect(bonus.formatted_currency_minimum_deposits).to eq('No minimum deposits specified')
        end
      end

      describe '#minimum_deposit_for_currency' do
        it 'returns deposit amount for specified currency' do
          bonus.currency_minimum_deposits = { 'USD' => 100.0, 'EUR' => 85.0 }
          expect(bonus.minimum_deposit_for_currency('USD')).to eq(100.0)
          expect(bonus.minimum_deposit_for_currency(:EUR)).to eq(85.0)
        end

        it 'returns nil for non-existent currency' do
          bonus.currency_minimum_deposits = { 'USD' => 100.0 }
          expect(bonus.minimum_deposit_for_currency('GBP')).to be_nil
        end
      end

      describe '#has_minimum_deposit_requirements?' do
        it 'returns true when deposits are specified' do
          bonus.currency_minimum_deposits = { 'USD' => 50.0 }
          expect(bonus).to have_minimum_deposit_requirements
        end

        it 'returns false when no deposits specified' do
          bonus.currency_minimum_deposits = {}
          expect(bonus).not_to have_minimum_deposit_requirements
        end
      end

      describe 'limitation formatting' do
        describe '#formatted_no_more' do
          it 'returns the value when present' do
            bonus.no_more = 5
            expect(bonus.formatted_no_more).to eq('5')
          end

          it 'returns "No limit" when blank' do
            bonus.no_more = nil
            expect(bonus.formatted_no_more).to eq('No limit')
          end
        end

        describe '#formatted_totally_no_more' do
          it 'returns formatted value when present' do
            bonus.totally_no_more = 10
            expect(bonus.formatted_totally_no_more).to eq('10 total')
          end

          it 'returns "Unlimited" when blank' do
            bonus.totally_no_more = nil
            expect(bonus.formatted_totally_no_more).to eq('Unlimited')
          end
        end
      end
    end
  end

  # Class methods tests
  describe 'class methods' do
    describe '.update_expired_bonuses!' do
      let!(:expired_active_bonus) { create(:bonus, :active, availability_start_date: 2.days.ago, availability_end_date: 1.day.ago) }
      let!(:expired_inactive_bonus) { create(:bonus, :inactive, availability_start_date: 2.days.ago, availability_end_date: 1.day.ago) }
      let!(:active_available_bonus) { create(:bonus, :active, availability_start_date: 1.day.ago, availability_end_date: 1.day.from_now) }

      it 'updates only active expired bonuses to inactive' do
        Bonus.update_expired_bonuses!

        expired_active_bonus.reload
        expired_inactive_bonus.reload
        active_available_bonus.reload

        expect(expired_active_bonus.status).to eq('inactive')
        expect(expired_inactive_bonus.status).to eq('inactive')  # Unchanged
        expect(active_available_bonus.status).to eq('active')    # Unchanged
      end

      it 'returns number of updated records' do
        count = Bonus.update_expired_bonuses!
        expect(count).to eq(1)  # Only expired_active_bonus should be updated
      end
    end
  end

  # Advanced edge cases
  describe 'advanced edge cases' do
    context 'with complex validation scenarios' do
      it 'handles multiple validation errors simultaneously' do
        bonus = build(:bonus,
                      name: '',  # Missing name
                      code: '',  # Missing code
                      event: 'invalid_event',  # Invalid event
                      status: 'invalid_status',  # Invalid status
                      availability_start_date: nil,  # Missing start date
                      availability_end_date: nil)   # Missing end date

        expect(bonus).not_to be_valid
        expect(bonus.errors.count).to be >= 5
      end

      it 'validates complex currency minimum deposits scenarios' do
        bonus = build(:bonus, :deposit_event)
        bonus.currencies = [ 'USD', 'EUR' ]
        bonus.currency_minimum_deposits = {
          'USD' => 50.0,
          'EUR' => 0,      # Invalid - zero amount
          'GBP' => 100.0   # Invalid - not in currencies list
        }

        expect(bonus).not_to be_valid
        expect(bonus.errors[:currency_minimum_deposits]).to include(/EUR.*positive number/)
        expect(bonus.errors[:currency_minimum_deposits]).to include(/contains currencies.*GBP/)
      end
    end

    context 'with timezone edge cases' do
      it 'handles timezone boundaries correctly' do
        # Test around timezone boundaries
        Time.use_zone('UTC') do
          utc_bonus = create(:bonus, :active,
                            availability_start_date: Time.current.beginning_of_day,
                            availability_end_date: Time.current.end_of_day)
          expect(utc_bonus).to be_available_now
        end

        Time.use_zone('America/New_York') do
          ny_bonus = create(:bonus, :active,
                           availability_start_date: Time.current.beginning_of_day,
                           availability_end_date: Time.current.end_of_day)
          expect(ny_bonus).to be_available_now
        end
      end
    end

    context 'with serialization edge cases' do
      it 'handles corrupted JSON data gracefully' do
        bonus = create(:bonus)

        # Simulate corrupted JSON in database
        bonus.update_column(:currencies, 'invalid json')
        bonus.reload

        # Should handle gracefully
        expect { bonus.currencies }.not_to raise_error
      end

      it 'handles very large JSON objects' do
        # Используем поддерживаемые валюты для теста
        supported_currencies = %w[EUR USD RUB BTC ETH LTC BCH XRP TRX DOGE USDT]
        large_array = (1..1000).map { |i| supported_currencies[i % supported_currencies.length] }
        bonus.currencies = large_array
        bonus.currency_minimum_deposits = {}  # Clear currency_minimum_deposits to avoid validation errors
        bonus.save!

        bonus.reload
        expect(bonus.currencies).to eq(large_array)
      end
    end

    context 'with concurrent access scenarios' do
      it 'handles simultaneous code validation' do
        codes = [ 'CODE_001', 'CODE_002', 'CODE_003', 'CODE_004', 'CODE_005' ]
        threads = []
        bonuses = []

        codes.each_with_index do |code, index|
          threads << Thread.new do
            bonus = build(:bonus, code: code)
            expect(bonus).to be_valid
            bonuses << bonus.code
          end
        end

        threads.each(&:join)

        # All codes should be unique
        expect(bonuses.uniq.length).to eq(bonuses.length)
      end

      it 'handles race conditions in status updates' do
        bonus = create(:bonus, :active, availability_start_date: 2.days.ago, availability_end_date: 1.day.ago)

        # Simulate concurrent access
        bonus1 = Bonus.find(bonus.id)
        bonus2 = Bonus.find(bonus.id)

        # Both should handle expired status update correctly
        expect(bonus1.expired?).to be true
        expect(bonus2.expired?).to be true
      end
    end

    context 'with memory and performance edge cases' do
      it 'handles bonuses with many rewards efficiently' do
        bonus = create(:bonus)

        # Create many rewards of different types
        create_list(:bonus_reward, 20, bonus: bonus)
        create_list(:freespin_reward, 15, bonus: bonus)
        create_list(:comp_point_reward, 10, bonus: bonus)

        expect(bonus.all_rewards.count).to eq(45)
        expect(bonus).to have_rewards
        expect(bonus.reward_types.length).to eq(3)
      end

      it 'handles very long attribute values' do
        bonus = build(:bonus,
                      name: 'A' * 255,  # Maximum length
                      dsl_tag_string: 'B' * 255,  # Maximum length
                      description: 'C' * 1000)  # Maximum length

        expect(bonus).to be_valid
      end
    end
  end

  # Database constraint and referential integrity tests
  describe 'database constraints' do
    it 'maintains referential integrity when deleting bonus with rewards' do
      bonus = create(:bonus, :with_bonus_rewards, :with_freespin_rewards)
      bonus_id = bonus.id

      expect {
        bonus.destroy
      }.to change(Bonus, :count).by(-1)
        .and change(BonusReward, :count).by(-1)
        .and change(FreespinReward, :count).by(-1)

      expect(Bonus.find_by(id: bonus_id)).to be_nil
    end

    it 'allows duplicate codes' do
      existing_bonus = create(:bonus, code: 'DUPLICATE_CODE')
      duplicate_bonus = build(:bonus, code: 'DUPLICATE_CODE')

      expect(duplicate_bonus).to be_valid
      expect(duplicate_bonus.save).to be_truthy
    end
  end
end

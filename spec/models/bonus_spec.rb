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

    it 'has valid PROJECTS' do
      expect(Bonus::PROJECTS).to include('VOLNA', 'ROX', 'FRESH', 'SOL')
    end

    it 'has PERMANENT_BONUS_TYPES' do
      expect(Bonus::PERMANENT_BONUS_TYPES).to be_an(Array)
      expect(Bonus::PERMANENT_BONUS_TYPES.first).to have_key(:name)
      expect(Bonus::PERMANENT_BONUS_TYPES.first).to have_key(:slug)
      expect(Bonus::PERMANENT_BONUS_TYPES.first).to have_key(:dsl_tag)
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
  end

  # Validations tests
  describe 'validations' do
    describe 'presence validations' do
      it { is_expected.to validate_presence_of(:name) }

      it 'validates presence of code or generates one' do
        bonus.code = nil
        expect(bonus).to be_valid
        expect(bonus.code).to be_present
      end

      it { is_expected.to validate_presence_of(:event) }
      it { is_expected.to validate_presence_of(:status) }
      it { is_expected.to validate_presence_of(:availability_start_date) }
      it { is_expected.to validate_presence_of(:availability_end_date) }
      it { is_expected.to validate_presence_of(:currency) }
    end

    describe 'length validations' do
      it { is_expected.to validate_length_of(:name).is_at_most(255) }
      it { is_expected.to validate_length_of(:code).is_at_most(50) }
      it { is_expected.to validate_length_of(:currency).is_at_most(3) }
      it { is_expected.to validate_length_of(:dsl_tag).is_at_most(255) }
      it { is_expected.to validate_length_of(:description).is_at_most(1000) }
    end

    describe 'inclusion validations' do
      it { is_expected.to validate_inclusion_of(:event).in_array(Bonus::EVENT_TYPES) }
      it { is_expected.to validate_inclusion_of(:status).in_array(Bonus::STATUSES) }
      it { is_expected.to validate_inclusion_of(:project).in_array(Bonus::PROJECTS) }
    end

    describe 'uniqueness validations' do
      before { create(:bonus) }
      it { is_expected.to validate_uniqueness_of(:code) }
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
            expect(bonus.errors[:minimum_deposit]).to include("не должно быть установлено для события #{event_type}")
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
          expect(bonus.errors[:currency_minimum_deposits]).to include('не должно быть установлено для события input_coupon')
        end

        it 'validates positive amounts' do
          bonus.event = 'deposit'
          bonus.currency_minimum_deposits = { 'USD' => 0 }
          expect(bonus).not_to be_valid
          expect(bonus.errors[:currency_minimum_deposits]).to include('для валюты USD должно быть положительным числом')
        end

        it 'validates currencies are in supported list' do
          bonus.event = 'deposit'
          bonus.currencies = [ 'USD' ]
          bonus.currency_minimum_deposits = { 'EUR' => 50.0 }
          expect(bonus).not_to be_valid
          expect(bonus.errors[:currency_minimum_deposits]).to include('содержит валюты, которые не указаны в списке поддерживаемых валют: EUR')
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
    describe 'before_validation :generate_code' do
      it 'generates code when blank' do
        bonus.code = nil
        bonus.valid?
        expect(bonus.code).to be_present
        expect(bonus.code).to start_with('BONUS_')
      end

      it 'does not generate code when present' do
        original_code = 'CUSTOM_CODE'
        bonus.code = original_code
        bonus.valid?
        expect(bonus.code).to eq(original_code)
      end

      it 'generates unique codes' do
        bonus1 = create(:bonus, code: nil)
        bonus2 = build(:bonus, code: nil)
        bonus2.valid?
        expect(bonus1.code).not_to eq(bonus2.code)
      end
    end

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
      let!(:usd_bonus) { create(:bonus, currency: 'USD') }
      let!(:eur_bonus) { create(:bonus, currency: 'EUR') }
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
end

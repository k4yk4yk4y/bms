# frozen_string_literal: true

require 'rails_helper'

# Part 2 of Bonus model tests - Instance methods, Class methods, and Edge cases
RSpec.describe Bonus, type: :model do
  subject(:bonus) { build(:bonus) }

  # Instance methods tests
  describe 'instance methods' do
    describe '#active?' do
      it 'returns true when status is active and currently available' do
        bonus = build(:bonus, :available_now)
        expect(bonus).to be_active
      end

      it 'returns false when status is active but not currently available' do
        bonus = build(:bonus, status: 'active', availability_start_date: 1.day.from_now, availability_end_date: 2.days.from_now)
        expect(bonus).not_to be_active
      end

      it 'returns false when status is not active but currently available' do
        bonus = build(:bonus, :available_now, status: 'inactive')
        expect(bonus).not_to be_active
      end
    end

    describe '#available_now?' do
      it 'returns true when current time is between start and end dates' do
        bonus = build(:bonus, :available_now)
        expect(bonus).to be_available_now
      end

      it 'returns false when current time is before start date' do
        bonus = build(:bonus, :future)
        expect(bonus).not_to be_available_now
      end

      it 'returns false when current time is after end date' do
        bonus = build(:bonus, :past)
        expect(bonus).not_to be_available_now
      end

      it 'handles edge case when current time equals start date' do
        now = Time.current
        bonus = build(:bonus, availability_start_date: now, availability_end_date: 1.hour.from_now)
        expect(bonus).to be_available_now
      end

      it 'handles edge case when current time equals end date' do
        now = Time.current
        bonus = build(:bonus, availability_start_date: 1.hour.ago, availability_end_date: now)
        # Travel to exact time to ensure accuracy
        travel_to(now) do
          expect(bonus).to be_available_now
        end
      end
    end

    describe '#expired?' do
      it 'returns true when end date is in the past' do
        bonus = build(:bonus, :past)
        expect(bonus).to be_expired
      end

      it 'returns false when end date is in the future' do
        bonus = build(:bonus, :future)
        expect(bonus).not_to be_expired
      end

      it 'returns false when end date is now' do
        now = Time.current
        bonus = build(:bonus, availability_end_date: now)
        travel_to(now) do
          expect(bonus).not_to be_expired
        end
      end
    end

    describe '#type_specific_record (deprecated)' do
      it 'returns nil as it is deprecated' do
        expect(bonus.type_specific_record).to be_nil
      end
    end

    describe '#all_rewards' do
      let(:bonus) { create(:bonus) }

      it 'returns empty array when no rewards' do
        expect(bonus.all_rewards).to eq([])
      end

      it 'returns all types of rewards' do
        bonus_reward = create(:bonus_reward, bonus: bonus)
        freespin_reward = create(:freespin_reward, bonus: bonus)
        bonus_buy_reward = create(:bonus_buy_reward, bonus: bonus)

        rewards = bonus.all_rewards
        expect(rewards).to include(bonus_reward, freespin_reward, bonus_buy_reward)
      end
    end

    describe '#has_rewards?' do
      let(:bonus) { create(:bonus) }

      it 'returns false when no rewards' do
        expect(bonus).not_to have_rewards
      end

      it 'returns true when has any reward' do
        create(:bonus_reward, bonus: bonus)
        expect(bonus).to have_rewards
      end
    end

    describe '#reward_types' do
      let(:bonus) { create(:bonus) }

      it 'returns empty array when no rewards' do
        expect(bonus.reward_types).to eq([])
      end

      it 'returns correct reward types' do
        create(:bonus_reward, bonus: bonus)
        create(:freespin_reward, bonus: bonus)

        expect(bonus.reward_types).to contain_exactly('bonus', 'freespins')
      end
    end

    describe 'display methods' do
      let(:bonus) { create(:bonus) }
      let(:bonus_reward) { create(:bonus_reward, :with_code, bonus: bonus) }

      before { bonus_reward } # Create the reward

      describe '#display_code' do
        it 'returns reward code when available' do
          expect(bonus.display_code).to eq(bonus_reward.code)
        end

        it 'returns bonus code when no reward code' do
          bonus_reward.config = {}
          bonus_reward.save
          expect(bonus.display_code).to eq(bonus.code)
        end
      end

      describe '#display_currency' do
        it 'returns reward currencies when available' do
          bonus_reward.config = { 'currencies' => %w[USD EUR] }
          bonus_reward.save
          expect(bonus.display_currency).to eq('USD, EUR')
        end

        it 'returns bonus currency when no reward currencies' do
          bonus_reward.config = {}
          bonus_reward.save
          expect(bonus.display_currency).to eq(bonus.currency)
        end
      end
    end

    describe '#tags_array' do
      it 'returns empty array when tags is blank' do
        bonus.tags = nil
        expect(bonus.tags_array).to eq([])
      end

      it 'splits tags by comma and strips whitespace' do
        bonus.tags = 'vip, weekend , bonus'
        expect(bonus.tags_array).to eq([ 'vip', 'weekend', 'bonus' ])
      end
    end

    describe '#tags_array=' do
      it 'joins array elements with comma and space' do
        bonus.tags_array = %w[vip weekend bonus]
        expect(bonus.tags).to eq('vip, weekend, bonus')
      end
    end

    describe '#formatted_currencies' do
      it 'returns joined currencies' do
        bonus.currencies = %w[USD EUR RUB]
        expect(bonus.formatted_currencies).to eq('USD, EUR, RUB')
      end

      it 'returns nil when no currencies' do
        bonus.currencies = []
        expect(bonus.formatted_currencies).to be_nil
      end
    end

    describe '#formatted_groups' do
      it 'returns joined groups' do
        bonus.groups = %w[VIP Regular Premium]
        expect(bonus.formatted_groups).to eq('VIP, Regular, Premium')
      end

      it 'returns nil when no groups' do
        bonus.groups = []
        expect(bonus.formatted_groups).to be_nil
      end
    end

    describe '#formatted_currency_minimum_deposits' do
      it 'returns formatted string when deposits exist' do
        bonus.currency_minimum_deposits = { 'USD' => 50.0, 'EUR' => 45.0 }
        expect(bonus.formatted_currency_minimum_deposits).to eq('USD: 50.0, EUR: 45.0')
      end

      it 'returns default message when no deposits' do
        bonus.currency_minimum_deposits = {}
        expect(bonus.formatted_currency_minimum_deposits).to eq('No minimum deposits specified')
      end
    end

    describe '#minimum_deposit_for_currency' do
      it 'returns deposit amount for currency' do
        bonus.currency_minimum_deposits = { 'USD' => 50.0, 'EUR' => 45.0 }
        expect(bonus.minimum_deposit_for_currency('USD')).to eq(50.0)
        expect(bonus.minimum_deposit_for_currency(:EUR)).to eq(45.0)
      end

      it 'returns nil for unknown currency' do
        bonus.currency_minimum_deposits = { 'USD' => 50.0 }
        expect(bonus.minimum_deposit_for_currency('EUR')).to be_nil
      end
    end

    describe '#has_minimum_deposit_requirements?' do
      it 'returns true when deposits exist' do
        bonus.currency_minimum_deposits = { 'USD' => 50.0 }
        expect(bonus).to have_minimum_deposit_requirements
      end

      it 'returns false when no deposits' do
        bonus.currency_minimum_deposits = {}
        expect(bonus).not_to have_minimum_deposit_requirements
      end
    end

    describe 'limitation formatting methods' do
      describe '#formatted_no_more' do
        it 'returns value when present' do
          bonus.no_more = '5 times'
          expect(bonus.formatted_no_more).to eq('5 times')
        end

        it 'returns default when blank' do
          bonus.no_more = nil
          expect(bonus.formatted_no_more).to eq('No limit')
        end
      end

      describe '#formatted_totally_no_more' do
        it 'returns formatted value when present' do
          bonus.totally_no_more = 10
          expect(bonus.formatted_totally_no_more).to eq('10 total')
        end

        it 'returns default when blank' do
          bonus.totally_no_more = nil
          expect(bonus.formatted_totally_no_more).to eq('Unlimited')
        end
      end
    end

    describe 'status change methods' do
      let(:bonus) { create(:bonus, :draft) }

      describe '#activate!' do
        it 'changes status to active' do
          expect { bonus.activate! }.to change { bonus.status }.to('active')
        end
      end

      describe '#deactivate!' do
        it 'changes status to inactive' do
          expect { bonus.deactivate! }.to change { bonus.status }.to('inactive')
        end
      end

      describe '#mark_as_expired!' do
        it 'changes status to expired' do
          expect { bonus.mark_as_expired! }.to change { bonus.status }.to('expired')
        end
      end
    end

    describe '#check_and_update_expired_status!' do
      it 'does not update unsaved records' do
        bonus = build(:bonus, :past, status: 'active')
        expect { bonus.check_and_update_expired_status! }.not_to change { bonus.status }
      end

      it 'updates expired active bonuses to inactive' do
        bonus = create(:bonus, :past, status: 'active')
        bonus.check_and_update_expired_status!
        expect(bonus.reload.status).to eq('inactive')
      end

      it 'does not update non-expired bonuses' do
        bonus = create(:bonus, :future, status: 'active')
        bonus.check_and_update_expired_status!
        expect(bonus.reload.status).to eq('active')
      end

      it 'does not update already inactive bonuses' do
        bonus = create(:bonus, :past, status: 'inactive')
        bonus.check_and_update_expired_status!
        expect(bonus.reload.status).to eq('inactive')
      end
    end
  end

  # Class methods tests
  describe 'class methods' do
    describe '.find_permanent_bonus_for_project' do
      let!(:permanent_bonus) { create(:bonus, :permanent, project: 'VOLNA', dsl_tag: 'welcome_bonus') }
      let!(:other_bonus) { create(:bonus, project: 'ROX', dsl_tag: 'welcome_bonus') }

      it 'finds active permanent bonus for project and dsl_tag' do
        result = Bonus.find_permanent_bonus_for_project('VOLNA', 'welcome_bonus')
        expect(result).to eq(permanent_bonus)
      end

      it 'returns nil when no matching bonus found' do
        result = Bonus.find_permanent_bonus_for_project('VOLNA', 'nonexistent_tag')
        expect(result).to be_nil
      end

      it 'does not return inactive bonuses' do
        permanent_bonus.update!(status: 'inactive')
        result = Bonus.find_permanent_bonus_for_project('VOLNA', 'welcome_bonus')
        expect(result).to be_nil
      end
    end

    describe '.permanent_bonus_previews_for_project' do
      let!(:welcome_bonus) { create(:bonus, :permanent, project: 'VOLNA', dsl_tag: 'welcome_bonus') }

      it 'returns empty array when project is blank' do
        result = Bonus.permanent_bonus_previews_for_project(nil)
        expect(result).to eq([])
      end

      it 'returns bonus previews for project' do
        result = Bonus.permanent_bonus_previews_for_project('VOLNA')
        expect(result).to be_an(Array)
        expect(result.first).to have_key(:name)
        expect(result.first).to have_key(:existing_bonus)
      end

      it 'includes existing bonus when found' do
        result = Bonus.permanent_bonus_previews_for_project('VOLNA')
        welcome_preview = result.find { |r| r[:dsl_tag] == 'welcome_bonus' }
        expect(welcome_preview[:existing_bonus]).to eq(welcome_bonus)
      end

      it 'has nil existing_bonus when not found' do
        result = Bonus.permanent_bonus_previews_for_project('ROX')
        welcome_preview = result.find { |r| r[:dsl_tag] == 'welcome_bonus' }
        expect(welcome_preview[:existing_bonus]).to be_nil
      end
    end

    describe '.update_expired_bonuses!' do
      it 'updates expired active bonuses to inactive' do
        # Skip the after_find callback for this test by using update_all directly
        expired_bonus = Bonus.create!(
          name: 'Expired Bonus',
          code: 'EXPIRED123',
          event: 'deposit',
          status: 'active',
          availability_start_date: 2.days.ago,
          availability_end_date: 1.day.ago,
          currency: 'USD',
          currencies: [ 'USD' ],
          groups: [ 'test' ],
          currency_minimum_deposits: { 'USD' => 50.0 }
        )

        # Force the status to be active in the database (bypass callbacks)
        expired_bonus.update_column(:status, 'active')

        # Count how many active expired bonuses exist
        count_before = Bonus.active.where("availability_end_date < ?", Time.current).count
        expect(count_before).to be > 0

        # Run the update method
        result = Bonus.update_expired_bonuses!

        # Check that the count was returned and bonuses were updated
        expect(result).to eq(count_before)

        # Verify the specific bonus was updated (accessing directly from DB to avoid callbacks)
        updated_status = Bonus.connection.select_value("SELECT status FROM bonuses WHERE id = #{expired_bonus.id}")
        expect(updated_status).to eq('inactive')
      end

      it 'does not update non-expired bonuses' do
        current_bonus = create(:bonus, :available_now, status: 'active')
        expect { Bonus.update_expired_bonuses! }.not_to change { current_bonus.reload.status }
      end

      it 'does not update already inactive bonuses' do
        expired_inactive = create(:bonus, status: 'inactive', availability_start_date: 2.days.ago, availability_end_date: 1.day.ago)
        expect { Bonus.update_expired_bonuses! }.not_to change { expired_inactive.reload.status }
      end
    end
  end

  # Edge cases and error conditions
  describe 'edge cases' do
    describe 'with time zone changes' do
      it 'handles different time zones correctly' do
        Time.use_zone('UTC') do
          utc_bonus = create(:bonus,
                           availability_start_date: Time.zone.parse('2024-01-01 00:00:00'),
                           availability_end_date: Time.zone.parse('2024-01-02 00:00:00'))

          travel_to Time.zone.parse('2024-01-01 12:00:00') do
            expect(utc_bonus).to be_available_now
          end
        end
      end
    end

    describe 'with boundary conditions' do
      it 'handles exact boundary times' do
        # Test availability at exact start time
        travel_to 1.hour.ago do
          start_time = Time.current
          end_time = 1.hour.from_now
          bonus = create(:bonus, availability_start_date: start_time, availability_end_date: end_time)
          expect(bonus).to be_available_now
        end

        # Test availability at exact end time
        travel_to 1.hour.from_now do
          start_time = 1.hour.ago
          end_time = Time.current
          bonus = create(:bonus, availability_start_date: start_time, availability_end_date: end_time)
          expect(bonus).to be_available_now
        end

        # Test unavailability after end time
        travel_to 1.hour.from_now do
          start_time = 2.hours.ago
          end_time = 1.second.ago
          bonus = create(:bonus, availability_start_date: start_time, availability_end_date: end_time)
          expect(bonus).not_to be_available_now
        end
      end
    end

    describe 'with invalid data scenarios' do
      it 'handles very large numbers gracefully' do
        bonus.minimum_deposit = 999_999_999.99
        expect(bonus).to be_valid
      end

      it 'handles very long strings within limits' do
        bonus.name = 'A' * 255
        bonus.description = 'B' * 1000
        expect(bonus).to be_valid
      end

      it 'rejects strings exceeding limits' do
        bonus.name = 'A' * 256
        expect(bonus).not_to be_valid
      end
    end

    describe 'concurrent modifications' do
      it 'handles concurrent code generation' do
        bonus1 = build(:bonus, code: nil)
        bonus2 = build(:bonus, code: nil)

        bonus1.valid?
        bonus2.valid?

        expect(bonus1.code).not_to eq(bonus2.code)
        expect(bonus1.code).to match(/\ABONUS_[A-Z0-9]{8}\z/)
        expect(bonus2.code).to match(/\ABONUS_[A-Z0-9]{8}\z/)
      end
    end

    describe 'JSON serialization edge cases' do
      it 'handles nil and empty values gracefully' do
        bonus.write_attribute(:currencies, nil)
        expect(bonus.currencies).to eq([])

        bonus.write_attribute(:groups, nil)
        expect(bonus.groups).to eq([])
      end

      it 'handles valid currency_minimum_deposits structure' do
        valid_data = { 'USD' => 50.0, 'EUR' => 45.0 }
        bonus.currency_minimum_deposits = valid_data
        expect(bonus.currency_minimum_deposits['USD']).to eq(50.0)
        expect(bonus.currency_minimum_deposits['EUR']).to eq(45.0)
      end
    end
  end
end

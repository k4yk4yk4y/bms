require 'rails_helper'

RSpec.describe BonusTemplate, type: :model do
  describe '#apply_to_bonus' do
    let(:template) { create(:bonus_template, :welcome_bonus) }
    let(:bonus) { build(:bonus) }

    context 'when applying a complete template' do
      before do
        template.update!(
          name: 'Complete Welcome Template',
          dsl_tag: 'complete_welcome',
          project: 'VOLNA',
          event: 'deposit',
          wager: 35.0,
          maximum_winnings: 500.0,
          no_more: 1,
          totally_no_more: 5,
          currencies: [ 'USD', 'EUR', 'GBP' ],
          groups: [ 'VIP', 'Premium', 'Gold' ],
          currency_minimum_deposits: { 'USD' => 10.0, 'EUR' => 8.0, 'GBP' => 7.0 },
          description: 'Complete welcome bonus template'
        )
      end

      it 'applies all template attributes to bonus' do
        template.apply_to_bonus(bonus)

        expect(bonus.dsl_tag).to eq('complete_welcome')
        expect(bonus.project).to eq('VOLNA')
        expect(bonus.event).to eq('deposit')
        expect(bonus.wager).to eq(35.0)
        expect(bonus.maximum_winnings).to eq(500.0)
        expect(bonus.no_more.to_i).to eq(1)
        expect(bonus.totally_no_more.to_i).to eq(5)
        expect(bonus.currencies).to eq([ 'USD', 'EUR', 'GBP' ])
        expect(bonus.groups).to eq([ 'VIP', 'Premium', 'Gold' ])
        expect(bonus.currency_minimum_deposits).to eq({ 'USD' => 10.0, 'EUR' => 8.0, 'GBP' => 7.0 })
        expect(bonus.description).to eq('Complete welcome bonus template')
      end

      it 'overwrites existing bonus attributes' do
        # Set some existing attributes on bonus
        bonus.write_attribute(:dsl_tag, 'old_tag')
        bonus.project = 'ROX'
        bonus.event = 'manual'
        bonus.wager = 50.0
        bonus.maximum_winnings = 1000.0
        bonus.currencies = [ 'BTC' ]
        bonus.groups = [ 'OldGroup' ]
        bonus.currency_minimum_deposits = { 'BTC' => 0.001 }
        bonus.description = 'Old description'

        template.apply_to_bonus(bonus)

        # Verify template values overwrote existing values
        expect(bonus.dsl_tag).to eq('complete_welcome')
        expect(bonus.project).to eq('VOLNA')
        expect(bonus.event).to eq('deposit')
        expect(bonus.wager).to eq(35.0)
        expect(bonus.maximum_winnings).to eq(500.0)
        expect(bonus.currencies).to eq([ 'USD', 'EUR', 'GBP' ])
        expect(bonus.groups).to eq([ 'VIP', 'Premium', 'Gold' ])
        expect(bonus.currency_minimum_deposits).to eq({ 'USD' => 10.0, 'EUR' => 8.0, 'GBP' => 7.0 })
        expect(bonus.description).to eq('Complete welcome bonus template')
      end
    end

    context 'when applying template with minimal data' do
      let(:minimal_template) do
        template = create(:bonus_template,
          name: 'Minimal Template',
          dsl_tag: 'minimal',
          project: 'SOL',
          event: 'manual',
          wager: nil,
          maximum_winnings: nil,
          no_more: nil,
          totally_no_more: nil,
          groups: [],
          currency_minimum_deposits: {},
          description: nil
        )
        # Bypass the callback by updating directly
        template.update_column(:currencies, [])
        template.reload
        template
      end

      it 'applies only available attributes' do
        minimal_template.apply_to_bonus(bonus)

        expect(bonus.dsl_tag).to eq('minimal')
        expect(bonus.project).to eq('SOL')
        expect(bonus.event).to eq('manual')
        expect(bonus.wager).to be_nil
        expect(bonus.maximum_winnings).to be_nil
        expect(bonus.no_more).to be_nil
        expect(bonus.totally_no_more).to be_nil
        expect(bonus.currencies).to eq([])
        expect(bonus.groups).to eq([])
        expect(bonus.currency_minimum_deposits).to eq({})
        expect(bonus.description).to be_nil
      end
    end

    context 'when applying template with different event types' do
      it 'applies deposit event template correctly' do
        deposit_template = create(:bonus_template, :welcome_bonus)
        deposit_template.apply_to_bonus(bonus)
        expect(bonus.event).to eq('deposit')
        expect(bonus.currency_minimum_deposits).to eq({ 'USD' => 10.0, 'EUR' => 8.0 })
      end

      it 'applies manual event template correctly' do
        manual_template = create(:bonus_template, :manual_event)
        manual_template.apply_to_bonus(bonus)
        expect(bonus.event).to eq('manual')
        expect(bonus.currency_minimum_deposits).to eq({})
      end

      it 'applies input_coupon event template correctly' do
        coupon_template = create(:bonus_template, :input_coupon_event)
        coupon_template.apply_to_bonus(bonus)
        expect(bonus.event).to eq('input_coupon')
        expect(bonus.currency_minimum_deposits).to eq({})
      end
    end

    context 'when applying template with complex currency data' do
      let(:complex_template) do
        create(:bonus_template,
          currencies: [ 'USD', 'EUR', 'GBP', 'RUB', 'UAH' ],
          currency_minimum_deposits: {
            'USD' => 10.0,
            'EUR' => 8.0,
            'GBP' => 7.0,
            'RUB' => 750.0,
            'UAH' => 300.0
          }
        )
      end

      it 'applies complex currency data correctly' do
        complex_template.apply_to_bonus(bonus)

        expect(bonus.currencies).to eq([ 'USD', 'EUR', 'GBP', 'RUB', 'UAH' ])
        expect(bonus.currency_minimum_deposits).to eq({
          'USD' => 10.0,
          'EUR' => 8.0,
          'GBP' => 7.0,
          'RUB' => 750.0,
          'UAH' => 300.0
        })
      end
    end

    context 'when applying template with complex groups data' do
      let(:groups_template) do
        create(:bonus_template,
          groups: [ 'VIP', 'Premium', 'Gold', 'Platinum', 'Diamond' ]
        )
      end

      it 'applies complex groups data correctly' do
        groups_template.apply_to_bonus(bonus)

        expect(bonus.groups).to eq([ 'VIP', 'Premium', 'Gold', 'Platinum', 'Diamond' ])
      end
    end

    context 'when applying template with decimal values' do
      let(:decimal_template) do
        create(:bonus_template,
          wager: 35.5,
          maximum_winnings: 500.75,
          no_more: 1,
          totally_no_more: 5
        )
      end

      it 'applies decimal values correctly' do
        decimal_template.apply_to_bonus(bonus)

        expect(bonus.wager).to eq(35.5)
        expect(bonus.maximum_winnings).to eq(500.75)
        expect(bonus.no_more.to_i).to eq(1)
        expect(bonus.totally_no_more.to_i).to eq(5)
      end
    end

    context 'when applying template to bonus with existing rewards' do
      let(:template) { create(:bonus_template, :welcome_bonus) }
      let(:bonus_with_rewards) { create(:bonus) }

      before do
        # Create some existing rewards
        create(:bonus_reward, bonus: bonus_with_rewards, reward_type: 'bonus', amount: 50.0)
        create(:freespin_reward, bonus: bonus_with_rewards, spins_count: 25)
      end

      it 'applies template without affecting existing rewards' do
        expect(bonus_with_rewards.bonus_rewards.count).to eq(1)
        expect(bonus_with_rewards.freespin_rewards.count).to eq(1)

        template.apply_to_bonus(bonus_with_rewards)

        # Template should be applied
        expect(bonus_with_rewards.dsl_tag).to eq(template.dsl_tag)
        expect(bonus_with_rewards.project).to eq(template.project)

        # Rewards should remain unchanged
        expect(bonus_with_rewards.bonus_rewards.count).to eq(1)
        expect(bonus_with_rewards.freespin_rewards.count).to eq(1)
      end
    end

    context 'when applying template multiple times' do
      let(:template1) { create(:bonus_template, :welcome_bonus) }
      let(:template2) { create(:bonus_template, :reload_bonus) }
      let(:bonus) { build(:bonus) }

      it 'overwrites previous template application' do
        # Apply first template
        template1.apply_to_bonus(bonus)
        expect(bonus.dsl_tag).to eq('welcome_bonus')
        expect(bonus.project).to eq('VOLNA')
        expect(bonus.wager).to eq(40.0)

        # Apply second template
        template2.apply_to_bonus(bonus)
        expect(bonus.dsl_tag).to eq('reload_cash')
        expect(bonus.project).to eq('ROX')
        expect(bonus.wager).to eq(30.0)
      end
    end

    context 'when applying template with edge cases' do
      it 'handles empty strings correctly' do
        template = create(:bonus_template,
          dsl_tag: 'empty_test',
          description: '',
          groups: []
        )
        # Bypass the callback by updating directly
        template.update_column(:currencies, [])
        template.reload

        template.apply_to_bonus(bonus)

        expect(bonus.dsl_tag).to eq('empty_test')
        expect(bonus.description).to eq('')
        expect(bonus.currencies).to eq([])
        expect(bonus.groups).to eq([])
      end

      it 'handles nil values correctly' do
        template = create(:bonus_template,
          wager: nil,
          maximum_winnings: nil,
          no_more: nil,
          totally_no_more: nil
        )

        template.apply_to_bonus(bonus)

        expect(bonus.wager).to be_nil
        expect(bonus.maximum_winnings).to be_nil
        expect(bonus.no_more).to be_nil
        expect(bonus.totally_no_more).to be_nil
      end

      it 'handles zero values correctly' do
        template = create(:bonus_template,
          wager: 0.0,
          maximum_winnings: 0.0,
          no_more: 0,
          totally_no_more: 0
        )

        template.apply_to_bonus(bonus)

        expect(bonus.wager).to eq(0.0)
        expect(bonus.maximum_winnings).to eq(0.0)
        expect(bonus.no_more.to_i).to eq(0)
        expect(bonus.totally_no_more.to_i).to eq(0)
      end
    end

    context 'when applying template to different bonus types' do
      it 'works with new bonus instance' do
        template = create(:bonus_template, :welcome_bonus)
        new_bonus = Bonus.new

        template.apply_to_bonus(new_bonus)

        expect(new_bonus.dsl_tag).to eq(template.dsl_tag)
        expect(new_bonus.project).to eq(template.project)
        expect(new_bonus.event).to eq(template.event)
      end

      it 'works with existing bonus instance' do
        template = create(:bonus_template, :welcome_bonus)
        existing_bonus = create(:bonus, dsl_tag_string: 'old_tag', project: 'ROX')

        template.apply_to_bonus(existing_bonus)

        expect(existing_bonus.dsl_tag).to eq(template.dsl_tag)
        expect(existing_bonus.project).to eq(template.project)
      end
    end
  end
end

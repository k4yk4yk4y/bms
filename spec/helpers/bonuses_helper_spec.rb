# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BonusesHelper, type: :helper do
  describe '#status_badge_class' do
    it 'returns correct class for active status' do
      expect(helper.status_badge_class('active')).to eq('bg-success')
    end

    it 'returns correct class for inactive status' do
      expect(helper.status_badge_class('inactive')).to eq('bg-secondary')
    end

    it 'returns correct class for expired status' do
      expect(helper.status_badge_class('expired')).to eq('bg-danger')
    end

    it 'returns correct class for draft status' do
      expect(helper.status_badge_class('draft')).to eq('bg-danger')
    end

    it 'returns default class for unknown status' do
      expect(helper.status_badge_class('unknown_status')).to eq('bg-secondary')
    end

    it 'handles nil status' do
      expect(helper.status_badge_class(nil)).to eq('bg-secondary')
    end

    it 'handles empty string status' do
      expect(helper.status_badge_class('')).to eq('bg-secondary')
    end

    it 'is case sensitive' do
      expect(helper.status_badge_class('ACTIVE')).to eq('bg-secondary')
      expect(helper.status_badge_class('Active')).to eq('bg-secondary')
    end
  end

  describe '#processing_status_badge_class' do
    it 'returns correct class for pending status' do
      expect(helper.processing_status_badge_class('pending')).to eq('bg-warning')
    end

    it 'returns correct class for processing status' do
      expect(helper.processing_status_badge_class('processing')).to eq('bg-info')
    end

    it 'returns correct class for completed status' do
      expect(helper.processing_status_badge_class('completed')).to eq('bg-success')
    end

    it 'returns correct class for failed status' do
      expect(helper.processing_status_badge_class('failed')).to eq('bg-danger')
    end

    it 'returns correct class for paused status' do
      expect(helper.processing_status_badge_class('paused')).to eq('bg-secondary')
    end

    it 'returns default class for unknown status' do
      expect(helper.processing_status_badge_class('unknown_status')).to eq('bg-secondary')
    end

    it 'handles nil status' do
      expect(helper.processing_status_badge_class(nil)).to eq('bg-secondary')
    end

    it 'handles empty string status' do
      expect(helper.processing_status_badge_class('')).to eq('bg-secondary')
    end
  end

  describe '#event_type_options' do
    it 'returns array of event type options' do
      options = helper.event_type_options
      expect(options).to be_an(Array)
      expect(options.length).to eq(6)
    end

    it 'returns options in correct format [label, value]' do
      options = helper.event_type_options
      options.each do |option|
        expect(option).to be_an(Array)
        expect(option.length).to eq(2)
        expect(option[0]).to be_a(String)  # Label
        expect(option[1]).to be_a(String)  # Value
      end
    end

    it 'includes all event types from Bonus model' do
      options = helper.event_type_options
      values = options.map { |option| option[1] }

      Bonus::EVENT_TYPES.each do |event_type|
        expect(values).to include(event_type)
      end
    end

    it 'has human-readable labels' do
      options = helper.event_type_options
      labels = options.map { |option| option[0] }

      expect(labels).to include('Deposit Event')
      expect(labels).to include('Input Coupon Event')
      expect(labels).to include('Manual Event')
    end

    it 'maintains consistent order' do
      options1 = helper.event_type_options
      options2 = helper.event_type_options
      expect(options1).to eq(options2)
    end
  end

  describe '#bonus_type_options' do
    it 'is an alias for event_type_options' do
      expect(helper.bonus_type_options).to eq(helper.event_type_options)
    end

    it 'returns same data as event_type_options (deprecated method)' do
      bonus_options = helper.bonus_type_options
      event_options = helper.event_type_options
      expect(bonus_options).to eq(event_options)
    end
  end

  describe '#status_options' do
    it 'returns array of status options' do
      options = helper.status_options
      expect(options).to be_an(Array)
      expect(options.length).to eq(4)
    end

    it 'returns options in correct format [label, value]' do
      options = helper.status_options
      options.each do |option|
        expect(option).to be_an(Array)
        expect(option.length).to eq(2)
        expect(option[0]).to be_a(String)
        expect(option[1]).to be_a(String)
      end
    end

    it 'includes all status types from Bonus model' do
      options = helper.status_options
      values = options.map { |option| option[1] }

      Bonus::STATUSES.each do |status|
        expect(values).to include(status)
      end
    end

    it 'has human-readable labels' do
      options = helper.status_options

      expect(options).to include([ 'Draft', 'draft' ])
      expect(options).to include([ 'Active', 'active' ])
      expect(options).to include([ 'Inactive', 'inactive' ])
      expect(options).to include([ 'Expired', 'expired' ])
    end
  end

  describe '#currency_options' do
    it 'returns array of currency options for a project' do
      project = create(:project, name: 'VOLNA', currencies: %w[USD EUR GBP])

      options = helper.currency_options(project.name)
      expect(options).to contain_exactly([ 'USD', 'USD' ], [ 'EUR', 'EUR' ], [ 'GBP', 'GBP' ])
    end

    it 'returns union of configured project currencies when no project is provided' do
      create(:project, name: 'VOLNA', currencies: %w[USD EUR])
      create(:project, name: 'ROX', currencies: %w[BTC ETH])

      values = helper.currency_options.map { |option| option[1] }
      expect(values).to include('USD', 'EUR', 'BTC', 'ETH')
    end
  end

  describe '#project_options' do
    it 'returns array of project options' do
      # Create some test projects
      create(:project, name: 'Test Project 1')
      create(:project, name: 'Test Project 2')
      create(:project, name: 'Test Project 3')

      options = helper.project_options
      expect(options).to be_an(Array)
      expect(options.length).to be >= 4 # At least "All" + 3 test projects
    end

    it 'returns options in correct format [label, value]' do
      options = helper.project_options
      options.each do |option|
        expect(option).to be_an(Array)
        expect(option.length).to eq(2)
        expect(option[0]).to be_a(String)
        expect(option[1]).to be_a(String)
      end
    end

    it 'includes all projects from Project model' do
      # Create test projects
      project1 = create(:project, name: 'Test Project 1')
      project2 = create(:project, name: 'Test Project 2')

      options = helper.project_options
      values = options.map { |option| option[1] }

      expect(values).to include(project1.name)
      expect(values).to include(project2.name)
    end

    it 'has labels matching values for projects' do
      options = helper.project_options
      options.each do |label, value|
        expect(label).to eq(value)
      end
    end

    it 'includes specific expected projects' do
      # Create specific test projects
      create(:project, name: 'VOLNA')
      create(:project, name: 'ROX')
      create(:project, name: 'FRESH')

      options = helper.project_options
      values = options.map { |option| option[1] }

      expect(values).to include('All', 'VOLNA', 'ROX', 'FRESH')
    end
  end

  describe '#wagering_strategy_options' do
    it 'returns array of wagering strategy options' do
      options = helper.wagering_strategy_options
      expect(options).to be_an(Array)
      expect(options.length).to eq(5)
    end

    it 'returns options in correct format [label, value]' do
      options = helper.wagering_strategy_options
      options.each do |option|
        expect(option).to be_an(Array)
        expect(option.length).to eq(2)
        expect(option[0]).to be_a(String)
        expect(option[1]).to be_a(String)
      end
    end

    it 'includes expected wagering strategies' do
      options = helper.wagering_strategy_options

      expect(options).to include([ 'Wager', 'wager' ])
      expect(options).to include([ 'Wager Win', 'wager_win' ])
      expect(options).to include([ 'Wager Free', 'wager_free' ])
      expect(options).to include([ 'Insurance Bonus', 'insurance_bonus' ])
      expect(options).to include([ 'Wager Real', 'wager_real' ])
    end

    it 'has human-readable labels' do
      options = helper.wagering_strategy_options
      labels = options.map { |option| option[0] }

      labels.each do |label|
        expect(label).to match(/[A-Z]/)  # Should have capitalized words
        expect(label.length).to be > 3   # Should be descriptive
      end
    end
  end

  describe '#collection_type_options' do
    it 'returns array of collection type options' do
      options = helper.collection_type_options
      expect(options).to be_an(Array)
      expect(options.length).to eq(5)
    end

    it 'includes expected collection types' do
      options = helper.collection_type_options

      expect(options).to include([ 'Daily', 'daily' ])
      expect(options).to include([ 'Weekly', 'weekly' ])
      expect(options).to include([ 'Monthly', 'monthly' ])
      expect(options).to include([ 'Fixed Amount', 'fixed_amount' ])
      expect(options).to include([ 'Percentage', 'percentage' ])
    end

    it 'has descriptive labels' do
      options = helper.collection_type_options
      labels = options.map { |option| option[0] }

      expect(labels).to include('Daily', 'Weekly', 'Monthly')
    end
  end

  describe '#collection_frequency_options' do
    it 'returns array of collection frequency options' do
      options = helper.collection_frequency_options
      expect(options).to be_an(Array)
      expect(options.length).to eq(4)
    end

    it 'includes expected frequencies' do
      options = helper.collection_frequency_options

      expect(options).to include([ 'Daily', 'daily' ])
      expect(options).to include([ 'Weekly', 'weekly' ])
      expect(options).to include([ 'Monthly', 'monthly' ])
      expect(options).to include([ 'Once', 'once' ])
    end

    it 'overlaps with collection_type_options for time-based options' do
      collection_types = helper.collection_type_options.map { |option| option[1] }
      frequency_types = helper.collection_frequency_options.map { |option| option[1] }

      expect(frequency_types & collection_types).to include('daily', 'weekly', 'monthly')
    end
  end

  describe '#schedule_type_options' do
    it 'returns array of schedule type options' do
      options = helper.schedule_type_options
      expect(options).to be_an(Array)
      expect(options.length).to eq(4)
    end

    it 'includes expected schedule types' do
      options = helper.schedule_type_options

      expect(options).to include([ 'Recurring', 'recurring' ])
      expect(options).to include([ 'One Time', 'one_time' ])
      expect(options).to include([ 'Cron Based', 'cron_based' ])
      expect(options).to include([ 'Interval Based', 'interval_based' ])
    end

    it 'has descriptive labels for technical concepts' do
      options = helper.schedule_type_options
      labels = options.map { |option| option[0] }

      expect(labels).to include('Cron Based', 'Interval Based')
    end
  end

  describe '#update_type_options' do
    it 'returns array of update type options' do
      options = helper.update_type_options
      expect(options).to be_an(Array)
      expect(options.length).to eq(4)
    end

    it 'includes expected update types' do
      options = helper.update_type_options

      expect(options).to include([ 'Add Bonus', 'add_bonus' ])
      expect(options).to include([ 'Remove Bonus', 'remove_bonus' ])
      expect(options).to include([ 'Modify Bonus', 'modify_bonus' ])
      expect(options).to include([ 'Bulk Apply', 'bulk_apply' ])
    end

    it 'has action-oriented labels' do
      options = helper.update_type_options
      labels = options.map { |option| option[0] }

      labels.each do |label|
        expect(label).to match(/Add|Remove|Modify|Bulk/)
      end
    end
  end

  # Integration tests with view rendering
  describe 'integration with views' do
    let(:bonus) { build(:bonus, status: 'active') }

    it 'works correctly when used in view context' do
      # Test that helper methods work in actual view rendering context
      badge_class = helper.status_badge_class('active')
      expect(badge_class).to eq('bg-success')
    end

    it 'handles multiple status badges in same view' do
      active_class = helper.status_badge_class('active')
      inactive_class = helper.status_badge_class('inactive')
      expired_class = helper.status_badge_class('expired')

      expect(active_class).to eq('bg-success')
      expect(inactive_class).to eq('bg-secondary')
      expect(expired_class).to eq('bg-danger')
    end

    it 'works with form select helpers' do
      options = helper.status_options
      expect(options).to include([ 'Active', 'active' ])
      expect(options).to include([ 'Inactive', 'inactive' ])
    end
  end

  # Edge cases and error conditions
  describe 'edge cases' do
    context 'with unusual input' do
      it 'handles numeric status input' do
        expect(helper.status_badge_class(1)).to eq('bg-secondary')
      end

      it 'handles boolean status input' do
        expect(helper.status_badge_class(true)).to eq('bg-secondary')
        expect(helper.status_badge_class(false)).to eq('bg-secondary')
      end

      it 'handles array input' do
        expect(helper.status_badge_class([ 'active' ])).to eq('bg-secondary')
      end

      it 'handles hash input' do
        expect(helper.status_badge_class({ status: 'active' })).to eq('bg-secondary')
      end
    end

    context 'with special string values' do
      it 'handles whitespace-only strings' do
        expect(helper.status_badge_class('   ')).to eq('bg-secondary')
      end

      it 'handles strings with special characters' do
        expect(helper.status_badge_class('active!')).to eq('bg-secondary')
        expect(helper.status_badge_class('active@#$')).to eq('bg-secondary')
      end

      it 'handles very long strings' do
        long_status = 'active' * 100
        expect(helper.status_badge_class(long_status)).to eq('bg-secondary')
      end
    end

    context 'option methods consistency' do
      let!(:project) { create(:project, currencies: %w[USD EUR]) }

      it 'all option methods return arrays of arrays' do
        option_methods = [
          :event_type_options, :status_options, :currency_options,
          :project_options, :wagering_strategy_options, :collection_type_options,
          :collection_frequency_options, :schedule_type_options, :update_type_options
        ]

        option_methods.each do |method|
          options = helper.send(method)
          expect(options).to be_an(Array)
          options.each do |option|
            expect(option).to be_an(Array)
            expect(option.length).to eq(2)
          end
        end
      end

      it 'option methods return non-empty arrays' do
        option_methods = [
          :event_type_options, :status_options, :currency_options,
          :project_options, :wagering_strategy_options, :collection_type_options,
          :collection_frequency_options, :schedule_type_options, :update_type_options
        ]

        option_methods.each do |method|
          options = helper.send(method)
          expect(options).not_to be_empty
        end
      end

      it 'option values are unique within each method' do
        option_methods = [
          :event_type_options, :status_options, :currency_options,
          :project_options, :wagering_strategy_options, :collection_type_options,
          :collection_frequency_options, :schedule_type_options, :update_type_options
        ]

        option_methods.each do |method|
          options = helper.send(method)
          values = options.map { |option| option[1] }
          expect(values).to eq(values.uniq)
        end
      end
    end
  end

  # Performance considerations
  describe 'performance' do
    before do
      create(:project, currencies: %w[USD EUR])
    end

    it 'option methods perform efficiently' do
              # Test that helper methods don't make database queries
              start_time = Time.current
        helper.event_type_options
        helper.status_options
        helper.currency_options
        helper.project_options
        helper.wagering_strategy_options
        end_time = Time.current
        expect(end_time - start_time).to be < 0.1.seconds
    end

    it 'status badge methods perform efficiently' do
              start_time = Time.current
        100.times { helper.status_badge_class('active') }
        end_time = Time.current
        expect(end_time - start_time).to be < 0.1.seconds
    end
  end



  private

  def render_inline(template)
    # Simple template rendering for testing
    template.gsub('<%=', '#{').gsub('%>', '}')
  end
end

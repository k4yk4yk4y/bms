# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HeatmapHelper, type: :helper do
  describe '#heatmap_color' do
    context 'when not current month' do
      it 'returns light gray background for any intensity' do
        expect(helper.heatmap_color(0, false)).to eq('background-color: #f8f9fa;')
        expect(helper.heatmap_color(0.5, false)).to eq('background-color: #f8f9fa;')
        expect(helper.heatmap_color(1, false)).to eq('background-color: #f8f9fa;')
      end
    end

    context 'when current month' do
      it 'returns white for zero intensity' do
        expect(helper.heatmap_color(0)).to eq('background-color: #ffffff;')
        expect(helper.heatmap_color(0.0)).to eq('background-color: #ffffff;')
      end

      it 'returns light green for low intensity (0.01-0.2)' do
        expect(helper.heatmap_color(0.01)).to eq('background-color: #c6e48b;')
        expect(helper.heatmap_color(0.1)).to eq('background-color: #c6e48b;')
        expect(helper.heatmap_color(0.2)).to eq('background-color: #c6e48b;')
      end

      it 'returns medium green for medium-low intensity (0.21-0.4)' do
        expect(helper.heatmap_color(0.21)).to eq('background-color: #7bc96f;')
        expect(helper.heatmap_color(0.3)).to eq('background-color: #7bc96f;')
        expect(helper.heatmap_color(0.4)).to eq('background-color: #7bc96f;')
      end

      it 'returns dark green for medium-high intensity (0.41-0.6)' do
        expect(helper.heatmap_color(0.41)).to eq('background-color: #239a3b;')
        expect(helper.heatmap_color(0.5)).to eq('background-color: #239a3b;')
        expect(helper.heatmap_color(0.6)).to eq('background-color: #239a3b;')
      end

      it 'returns red for high intensity (0.61-0.8)' do
        expect(helper.heatmap_color(0.61)).to eq('background-color: #d73027;')
        expect(helper.heatmap_color(0.7)).to eq('background-color: #d73027;')
        expect(helper.heatmap_color(0.8)).to eq('background-color: #d73027;')
      end

      it 'returns dark red for maximum intensity (0.81+)' do
        expect(helper.heatmap_color(0.81)).to eq('background-color: #a50026;')
        expect(helper.heatmap_color(0.9)).to eq('background-color: #a50026;')
        expect(helper.heatmap_color(1.0)).to eq('background-color: #a50026;')
      end

      it 'handles intensity above 1.0' do
        expect(helper.heatmap_color(1.5)).to eq('background-color: #a50026;')
        expect(helper.heatmap_color(10)).to eq('background-color: #a50026;')
      end

      context 'boundary testing' do
        it 'handles exact boundary values correctly' do
          # Test exact boundary values
          expect(helper.heatmap_color(0.2)).to eq('background-color: #c6e48b;')
          expect(helper.heatmap_color(0.21)).to eq('background-color: #7bc96f;')

          expect(helper.heatmap_color(0.4)).to eq('background-color: #7bc96f;')
          expect(helper.heatmap_color(0.41)).to eq('background-color: #239a3b;')

          expect(helper.heatmap_color(0.6)).to eq('background-color: #239a3b;')
          expect(helper.heatmap_color(0.61)).to eq('background-color: #d73027;')

          expect(helper.heatmap_color(0.8)).to eq('background-color: #d73027;')
          expect(helper.heatmap_color(0.81)).to eq('background-color: #a50026;')
        end

        it 'handles very small positive values' do
          expect(helper.heatmap_color(0.001)).to eq('background-color: #ffffff;')
          expect(helper.heatmap_color(0.009)).to eq('background-color: #ffffff;')
        end
      end

      context 'edge cases' do
        it 'handles negative intensity' do
          expect(helper.heatmap_color(-0.1)).to eq('background-color: #ffffff;')
          expect(helper.heatmap_color(-1)).to eq('background-color: #ffffff;')
        end

        it 'handles nil intensity' do
          expect(helper.heatmap_color(nil)).to eq('background-color: #ffffff;')
        end

        it 'handles string intensity' do
          # Should convert to numeric or default to zero
          result = helper.heatmap_color('0.5')
          expect(result).to be_a(String)
          expect(result).to start_with('background-color:')
        end

        it 'handles float precision edge cases' do
          # Test with values that might have floating point precision issues
          expect(helper.heatmap_color(0.200000001)).to eq('background-color: #c6e48b;')
          expect(helper.heatmap_color(0.199999999)).to eq('background-color: #c6e48b;')
        end
      end
    end
  end

  describe '#format_month_year' do
    it 'formats date with full month name and year' do
      date = Date.new(2023, 6, 15)
      expect(helper.format_month_year(date)).to eq('June 2023')
    end

    it 'handles different months correctly' do
      expect(helper.format_month_year(Date.new(2023, 1, 1))).to eq('January 2023')
      expect(helper.format_month_year(Date.new(2023, 12, 31))).to eq('December 2023')
    end

    it 'handles different years correctly' do
      expect(helper.format_month_year(Date.new(2020, 6, 15))).to eq('June 2020')
      expect(helper.format_month_year(Date.new(2025, 6, 15))).to eq('June 2025')
    end

    it 'handles leap year February' do
      expect(helper.format_month_year(Date.new(2024, 2, 29))).to eq('February 2024')
    end

    context 'edge cases' do
      it 'handles very old dates' do
        expect(helper.format_month_year(Date.new(1900, 1, 1))).to eq('January 1900')
      end

      it 'handles far future dates' do
        expect(helper.format_month_year(Date.new(2100, 12, 31))).to eq('December 2100')
      end

      it 'handles DateTime objects' do
        datetime = DateTime.new(2023, 6, 15, 12, 30, 45)
        expect(helper.format_month_year(datetime)).to eq('June 2023')
      end

      it 'handles Time objects' do
        time = Time.new(2023, 6, 15, 12, 30, 45)
        expect(helper.format_month_year(time)).to eq('June 2023')
      end
    end

    context 'localization' do
      it 'uses English month names by default' do
        date = Date.new(2023, 3, 15)
        expect(helper.format_month_year(date)).to eq('March 2023')
      end

      # Note: If your app supports i18n, you might want to test different locales
      it 'respects locale settings if configured' do
        # This test assumes default English locale
        # Uncomment and modify if you support multiple locales
        # I18n.with_locale(:ru) do
        #   date = Date.new(2023, 3, 15)
        #   expect(helper.format_month_year(date)).to include('март')
        # end
      end
    end
  end

  describe '#bonus_type_badge_class' do
    it 'returns correct class for deposit bonus type' do
      expect(helper.bonus_type_badge_class('deposit')).to eq('bg-success')
    end

    it 'returns correct class for input_coupon bonus type' do
      expect(helper.bonus_type_badge_class('input_coupon')).to eq('bg-primary')
    end

    it 'returns correct class for manual bonus type' do
      expect(helper.bonus_type_badge_class('manual')).to eq('bg-warning')
    end

    it 'returns correct class for collection bonus type' do
      expect(helper.bonus_type_badge_class('collection')).to eq('bg-info')
    end

    it 'returns correct class for groups_update bonus type' do
      expect(helper.bonus_type_badge_class('groups_update')).to eq('bg-secondary')
    end

    it 'returns correct class for scheduler bonus type' do
      expect(helper.bonus_type_badge_class('scheduler')).to eq('bg-dark')
    end

    it 'returns default class for unknown bonus type' do
      expect(helper.bonus_type_badge_class('unknown_type')).to eq('bg-light text-dark')
    end

    it 'handles nil bonus type' do
      expect(helper.bonus_type_badge_class(nil)).to eq('bg-light text-dark')
    end

    it 'handles empty string bonus type' do
      expect(helper.bonus_type_badge_class('')).to eq('bg-light text-dark')
    end

    context 'all valid bonus event types' do
      it 'has specific classes for all Bonus::EVENT_TYPES' do
        Bonus::EVENT_TYPES.each do |event_type|
          result = helper.bonus_type_badge_class(event_type)
          expect(result).to be_a(String)
          expect(result).to match(/^bg-\w+/)
        end
      end
    end

    context 'edge cases' do
      it 'is case sensitive' do
        expect(helper.bonus_type_badge_class('DEPOSIT')).to eq('bg-light text-dark')
        expect(helper.bonus_type_badge_class('Deposit')).to eq('bg-light text-dark')
      end

      it 'handles special characters' do
        expect(helper.bonus_type_badge_class('deposit!')).to eq('bg-light text-dark')
        expect(helper.bonus_type_badge_class('deposit@#$')).to eq('bg-light text-dark')
      end

      it 'handles numeric input' do
        expect(helper.bonus_type_badge_class(1)).to eq('bg-light text-dark')
      end

      it 'handles boolean input' do
        expect(helper.bonus_type_badge_class(true)).to eq('bg-light text-dark')
      end
    end
  end

  # Testing CSS class consistency
  describe 'CSS class consistency' do
    it 'all badge methods return valid Bootstrap classes' do
      bootstrap_bg_classes = %w[
        bg-primary bg-secondary bg-success bg-danger bg-warning bg-info bg-light bg-dark
      ]

      # Test status badge classes
      %w[active inactive expired draft unknown].each do |status|
        result = helper.status_badge_class(status)
        expect(result).to start_with('bg-')
        expect(bootstrap_bg_classes).to include(result)
      end

      # Test bonus type badge classes
      (Bonus::EVENT_TYPES + [ 'unknown' ]).each do |bonus_type|
        result = helper.bonus_type_badge_class(bonus_type)
        badge_class = result.split(' ').first
        expect(bootstrap_bg_classes).to include(badge_class)
      end
    end

    it 'returns CSS-safe class names' do
      test_inputs = [ 'active', 'inactive', 'deposit', 'manual', 'unknown', nil, '' ]

      test_inputs.each do |input|
        status_result = helper.status_badge_class(input)
        type_result = helper.bonus_type_badge_class(input)

        # CSS class names should not contain special characters
        expect(status_result).to match(/^[\w\s-]+$/)
        expect(type_result).to match(/^[\w\s-]+$/)
      end
    end
  end
end

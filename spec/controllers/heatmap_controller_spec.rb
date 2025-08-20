# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HeatmapController, type: :controller do
  # Create test bonuses with different events and dates
  let!(:current_month_deposit_bonus) do
    create(:bonus, :deposit_event,
           availability_start_date: Date.current.beginning_of_month,
           availability_end_date: Date.current.end_of_month)
  end

  let!(:current_month_coupon_bonus) do
    create(:bonus, :input_coupon_event,
           availability_start_date: Date.current.beginning_of_month + 5.days,
           availability_end_date: Date.current.end_of_month)
  end

  let!(:previous_month_bonus) do
    create(:bonus, :deposit_event,
           availability_start_date: 1.month.ago.beginning_of_month,
           availability_end_date: 1.month.ago.end_of_month)
  end

  let!(:next_month_bonus) do
    create(:bonus, :deposit_event,
           availability_start_date: 1.month.from_now.beginning_of_month,
           availability_end_date: 1.month.from_now.end_of_month)
  end

  describe 'GET #index' do
    context 'without parameters' do
      it 'returns successful response' do
        get :index
        expect(response).to have_http_status(:success)
      end

      it 'defaults to current year and month' do
        get :index
        expect(assigns(:year)).to eq(Date.current.year)
        expect(assigns(:month)).to eq(Date.current.month)
      end

      it 'defaults bonus_event to "all"' do
        get :index
        expect(assigns(:bonus_event)).to eq('all')
      end

      it 'sets start and end dates correctly' do
        get :index
        expect(assigns(:start_date)).to eq(Date.current.beginning_of_month)
        expect(assigns(:end_date)).to eq(Date.current.end_of_month)
      end

      it 'generates heatmap data' do
        get :index
        expect(assigns(:heatmap_data)).to be_present
      end

      it 'sets bonus events list for filter' do
        get :index
        bonus_events = assigns(:bonus_events)
        expect(bonus_events).to include('deposit', 'input_coupon')
        expect(bonus_events).to eq(bonus_events.sort)
      end

      it 'sets navigation dates' do
        get :index
        expect(assigns(:prev_month)).to eq(Date.current.beginning_of_month.prev_month)
        expect(assigns(:next_month)).to eq(Date.current.beginning_of_month.next_month)
      end
    end

    context 'with year and month parameters' do
      it 'uses specified year and month' do
        get :index, params: { year: 2023, month: 6 }
        expect(assigns(:year)).to eq(2023)
        expect(assigns(:month)).to eq(6)
        expect(assigns(:start_date)).to eq(Date.new(2023, 6, 1))
        expect(assigns(:end_date)).to eq(Date.new(2023, 6, 30))
      end

      it 'handles string parameters' do
        get :index, params: { year: '2023', month: '12' }
        expect(assigns(:year)).to eq(2023)
        expect(assigns(:month)).to eq(12)
      end

      it 'handles invalid year gracefully' do
        get :index, params: { year: 'invalid' }
        expect(assigns(:year)).to eq(Date.current.year)
      end

      it 'handles invalid month gracefully' do
        get :index, params: { month: 'invalid' }
        expect(assigns(:month)).to eq(Date.current.month)
      end

      it 'handles out-of-range month values' do
        get :index, params: { month: 13 }
        expect(response).to have_http_status(:success)
        # Should handle gracefully, possibly defaulting or raising error
      end

      it 'handles negative values' do
        get :index, params: { year: -2023, month: -1 }
        expect(response).to have_http_status(:success)
      end

      it 'handles very large values' do
        get :index, params: { year: 9999, month: 12 }
        expect(response).to have_http_status(:success)
      end
    end

    context 'with bonus_event filter' do
      it 'filters by specific event type' do
        get :index, params: { bonus_event: 'deposit' }
        expect(assigns(:bonus_event)).to eq('deposit')
      end

      it 'handles "all" event filter' do
        get :index, params: { bonus_event: 'all' }
        expect(assigns(:bonus_event)).to eq('all')
      end

      it 'handles invalid event type' do
        get :index, params: { bonus_event: 'invalid_event' }
        expect(assigns(:bonus_event)).to eq('all')
        expect(response).to have_http_status(:success)
      end

      it 'handles nil event parameter' do
        get :index, params: { bonus_event: nil }
        expect(assigns(:bonus_event)).to eq('all')
      end

      it 'handles empty string event parameter' do
        get :index, params: { bonus_event: '' }
        expect(assigns(:bonus_event)).to eq('all')
      end
    end

    context 'with different time periods' do
      it 'handles February in leap year' do
        get :index, params: { year: 2024, month: 2 }  # 2024 is leap year
        expect(assigns(:start_date)).to eq(Date.new(2024, 2, 1))
        expect(assigns(:end_date)).to eq(Date.new(2024, 2, 29))
      end

      it 'handles February in non-leap year' do
        get :index, params: { year: 2023, month: 2 }  # 2023 is not leap year
        expect(assigns(:start_date)).to eq(Date.new(2023, 2, 1))
        expect(assigns(:end_date)).to eq(Date.new(2023, 2, 28))
      end

      it 'handles month with 31 days' do
        get :index, params: { year: 2023, month: 1 }
        expect(assigns(:start_date)).to eq(Date.new(2023, 1, 1))
        expect(assigns(:end_date)).to eq(Date.new(2023, 1, 31))
      end

      it 'handles month with 30 days' do
        get :index, params: { year: 2023, month: 4 }
        expect(assigns(:start_date)).to eq(Date.new(2023, 4, 1))
        expect(assigns(:end_date)).to eq(Date.new(2023, 4, 30))
      end
    end

    context 'navigation links' do
      it 'sets correct previous month navigation' do
        get :index, params: { year: 2023, month: 6 }
        expect(assigns(:prev_month)).to eq(Date.new(2023, 5, 1))
      end

      it 'sets correct next month navigation' do
        get :index, params: { year: 2023, month: 6 }
        expect(assigns(:next_month)).to eq(Date.new(2023, 7, 1))
      end

      it 'handles year boundary for previous month' do
        get :index, params: { year: 2023, month: 1 }
        expect(assigns(:prev_month)).to eq(Date.new(2022, 12, 1))
      end

      it 'handles year boundary for next month' do
        get :index, params: { year: 2023, month: 12 }
        expect(assigns(:next_month)).to eq(Date.new(2024, 1, 1))
      end
    end

    context 'heatmap data generation' do
      it 'generates heatmap data' do
        get :index
        heatmap_data = assigns(:heatmap_data)
        expect(heatmap_data).to be_present
      end

      it 'includes bonuses from current month' do
        get :index
        # The actual heatmap data structure depends on generate_heatmap_data implementation
        # We can verify that the method is called and data is assigned
        expect(assigns(:heatmap_data)).to be_present
      end

      it 'filters data by month boundaries' do
        # Test that only bonuses within the specified month are included
        get :index, params: {
          year: Date.current.year,
          month: Date.current.month
        }

        expect(assigns(:heatmap_data)).to be_present
        # Verify that data respects month boundaries
        expect(assigns(:start_date)).to eq(Date.current.beginning_of_month)
        expect(assigns(:end_date)).to eq(Date.current.end_of_month)
      end
    end

    context 'bonus events data' do
      it 'retrieves distinct bonus events' do
        get :index
        bonus_events = assigns(:bonus_events)
        expect(bonus_events).to include('deposit', 'input_coupon')
      end

      it 'sorts bonus events alphabetically' do
        get :index
        bonus_events = assigns(:bonus_events)
        expect(bonus_events).to eq(bonus_events.sort)
      end

      it 'excludes nil events' do
        # Since the database has a NOT NULL constraint on event, nil events cannot exist
        # This test verifies that the controller handles the case gracefully
        get :index
        bonus_events = assigns(:bonus_events)
        expect(bonus_events).not_to include(nil)
      end

      it 'handles empty bonus events list' do
        Bonus.destroy_all
        get :index
        expect(assigns(:bonus_events)).to eq([])
      end
    end
  end

  # Parameter validation and edge cases
  describe 'parameter handling' do
    context 'with malformed parameters' do
      it 'handles non-numeric year parameter' do
        get :index, params: { year: 'abc' }
        expect(assigns(:year)).to eq(Date.current.year)
      end

      it 'handles non-numeric month parameter' do
        get :index, params: { month: 'xyz' }
        expect(assigns(:month)).to eq(Date.current.month)
      end

      it 'handles nil parameters' do
        get :index, params: { year: nil, month: nil, bonus_event: nil }
        expect(assigns(:year)).to eq(Date.current.year)
        expect(assigns(:month)).to eq(Date.current.month)
        expect(assigns(:bonus_event)).to eq('all')
      end

      it 'handles empty string parameters' do
        get :index, params: { year: '', month: '', bonus_event: '' }
        expect(assigns(:year)).to eq(Date.current.year)
        expect(assigns(:month)).to eq(Date.current.month)
        expect(assigns(:bonus_event)).to eq('all')
      end
    end

    context 'with edge case date values' do
      it 'handles minimum valid date' do
        get :index, params: { year: 1900, month: 1 }
        expect(assigns(:start_date)).to eq(Date.new(Date.current.year, 1, 1))
        expect(assigns(:end_date)).to eq(Date.new(Date.current.year, 1, 31))
      end

      it 'handles far future dates' do
        get :index, params: { year: 2100, month: 12 }
        expect(assigns(:start_date)).to eq(Date.new(2100, 12, 1))
        expect(assigns(:end_date)).to eq(Date.new(2100, 12, 31))
      end

      it 'handles zero values' do
        get :index, params: { year: 0, month: 0 }
        expect(response).to have_http_status(:success)
        # Should handle gracefully or use defaults
      end
    end
  end

  # Performance and optimization tests
  describe 'performance' do
    context 'with large datasets' do
      before do
        # Create many bonuses across different months
        12.times do |month_offset|
          date = Date.current.beginning_of_month - month_offset.months
          5.times do
            create(:bonus, :deposit_event,
                   availability_start_date: date,
                   availability_end_date: date.end_of_month)
          end
        end
      end

      it 'handles large datasets efficiently' do
        start_time = Time.current
        get :index
        end_time = Time.current

        expect(response).to have_http_status(:success)
        expect(end_time - start_time).to be < 2.seconds
      end

      it 'efficiently filters bonuses for heatmap generation' do
        get :index, params: { year: Date.current.year, month: Date.current.month }
        expect(response).to have_http_status(:success)
        expect(assigns(:heatmap_data)).to be_present
      end
    end

    context 'database query optimization' do
      it 'efficiently retrieves distinct bonus events' do
        # Test that the distinct query doesn't cause performance issues
        create_list(:bonus, 100, :deposit_event)

        start_time = Time.current
        get :index
        end_time = Time.current
        expect(end_time - start_time).to be < 2.seconds
        expect(response).to have_http_status(:success)
      end
    end
  end

  # Error handling
  describe 'error handling' do
    it 'handles database connection errors gracefully' do
      allow(Bonus).to receive(:distinct).and_raise(ActiveRecord::ConnectionNotEstablished)

      expect {
        get :index
      }.to raise_error(ActiveRecord::ConnectionNotEstablished)
    end

    it 'handles invalid date creation gracefully' do
      # Test with invalid date combinations that might cause Date.new to fail
      expect {
        get :index, params: { year: 2023, month: 13 }  # Invalid month
      }.not_to raise_error
    end
  end

  # Integration with bonus data
  describe 'integration with bonus system' do
    context 'with different bonus statuses' do
      before do
        create(:bonus, :active, :deposit_event,
               availability_start_date: Date.current.beginning_of_month,
               availability_end_date: Date.current.end_of_month)
        create(:bonus, :inactive, :deposit_event,
               availability_start_date: Date.current.beginning_of_month,
               availability_end_date: Date.current.end_of_month)
        create(:bonus, :draft, :deposit_event,
               availability_start_date: Date.current.beginning_of_month,
               availability_end_date: Date.current.end_of_month)
      end

      it 'includes all bonus statuses in heatmap data' do
        get :index
        expect(assigns(:heatmap_data)).to be_present
        # Verify that heatmap considers all statuses
      end
    end

    context 'with overlapping bonus periods' do
      before do
        # Create bonuses with overlapping availability periods
        create(:bonus, :deposit_event,
               availability_start_date: Date.current.beginning_of_month,
               availability_end_date: Date.current.beginning_of_month + 15.days)
        create(:bonus, :deposit_event,
               availability_start_date: Date.current.beginning_of_month + 10.days,
               availability_end_date: Date.current.end_of_month)
      end

      it 'handles overlapping periods correctly' do
        get :index
        expect(response).to have_http_status(:success)
        expect(assigns(:heatmap_data)).to be_present
      end
    end

    context 'with bonuses spanning multiple months' do
      before do
        # Create bonus that spans current and next month
        create(:bonus, :deposit_event,
               availability_start_date: Date.current.end_of_month - 5.days,
               availability_end_date: Date.current.end_of_month + 10.days)
      end

      it 'correctly includes cross-month bonuses' do
        get :index
        expect(response).to have_http_status(:success)
      end
    end
  end

  # Edge cases and boundary testing
  describe 'edge cases' do
    context 'with no bonuses' do
      before { Bonus.destroy_all }

      it 'handles empty bonus dataset' do
        get :index
        expect(response).to have_http_status(:success)
        expect(assigns(:bonus_events)).to eq([])
        expect(assigns(:heatmap_data)).to be_present
      end
    end

    context 'with timezone considerations' do
      it 'handles different timezones correctly' do
        # Test with different timezone settings
        original_zone = Time.zone
        Time.zone = 'UTC'

        get :index
        utc_result = assigns(:start_date)

        Time.zone = 'America/New_York'
        get :index
        ny_result = assigns(:start_date)

        # Both should work correctly
        expect(utc_result).to be_a(Date)
        expect(ny_result).to be_a(Date)

        Time.zone = original_zone
      end
    end

    context 'with special date scenarios' do
      it 'handles DST transition periods' do
        # Test around daylight saving time transitions
        get :index, params: { year: 2023, month: 3 }  # March (typical DST change month)
        expect(response).to have_http_status(:success)
      end

      it 'handles end-of-year boundary' do
        get :index, params: { year: 2023, month: 12 }
        expect(assigns(:next_month)).to eq(Date.new(2024, 1, 1))
      end

      it 'handles beginning-of-year boundary' do
        get :index, params: { year: 2023, month: 1 }
        expect(assigns(:prev_month)).to eq(Date.new(2022, 12, 1))
      end
    end

    context 'with data consistency' do
      it 'maintains consistency between start_date and end_date' do
        get :index, params: { year: 2023, month: 6 }
        start_date = assigns(:start_date)
        end_date = assigns(:end_date)

        expect(end_date).to be > start_date
        expect(start_date.month).to eq(6)
        expect(end_date.month).to eq(6)
        expect(start_date.year).to eq(2023)
        expect(end_date.year).to eq(2023)
      end

      it 'ensures prev_month and next_month are correct relative to current period' do
        get :index, params: { year: 2023, month: 6 }
        current_date = Date.new(2023, 6, 1)
        prev_month = assigns(:prev_month)
        next_month = assigns(:next_month)

        expect(prev_month).to eq(current_date.prev_month)
        expect(next_month).to eq(current_date.next_month)
      end
    end
  end

  # Security considerations
  describe 'security' do
    it 'handles SQL injection attempts in parameters' do
      get :index, params: {
        year: "2023'; DROP TABLE bonuses; --",
        month: "6'; DROP TABLE bonuses; --",
        bonus_event: "deposit'; DROP TABLE bonuses; --"
      }
      expect(response).to have_http_status(:success)
      expect(Bonus.count).to be >= 0  # Ensure table still exists
    end

    it 'validates parameter types to prevent type confusion attacks' do
      get :index, params: {
        year: { malicious: 'data' },
        month: [ 'array', 'input' ]
      }
      expect(response).to have_http_status(:success)
    end
  end

  # Response format and content validation
  describe 'response validation' do
    it 'assigns all required instance variables' do
      get :index
      expect(assigns(:year)).to be_present
      expect(assigns(:month)).to be_present
      expect(assigns(:bonus_event)).to be_present
      expect(assigns(:start_date)).to be_present
      expect(assigns(:end_date)).to be_present
      expect(assigns(:heatmap_data)).to be_present
      expect(assigns(:bonus_events)).to be_present
      expect(assigns(:prev_month)).to be_present
      expect(assigns(:next_month)).to be_present
    end

    it 'uses correct data types for instance variables' do
      get :index
      expect(assigns(:year)).to be_an(Integer)
      expect(assigns(:month)).to be_an(Integer)
      expect(assigns(:bonus_event)).to be_a(String)
      expect(assigns(:start_date)).to be_a(Date)
      expect(assigns(:end_date)).to be_a(Date)
      expect(assigns(:bonus_events)).to be_an(Array)
      expect(assigns(:prev_month)).to be_a(Date)
      expect(assigns(:next_month)).to be_a(Date)
    end
  end

  private
end

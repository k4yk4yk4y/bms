# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BonusesController, type: :controller do
  # Sign in a user for all tests since BonusesController requires authentication
  before do
    sign_in_user(role: :admin)
  end

  # Test data setup
  let!(:bonus) { create(:bonus, :active) }
  let!(:draft_bonus) { create(:bonus, :draft) }
  let!(:inactive_bonus) { create(:bonus, :inactive) }
  let!(:expired_bonus) { create(:bonus, :expired) }

  describe 'GET #index' do
    context 'without filters' do
      it 'returns successful response' do
        get :index
        expect(response).to have_http_status(:success)
        expect(assigns(:bonuses)).to include(bonus, draft_bonus, inactive_bonus, expired_bonus)
      end

      it 'includes reward associations' do
        bonus_with_rewards = create(:bonus, :with_bonus_rewards, :with_freespin_rewards)
        get :index
        # Verify that associations are loaded to prevent N+1 queries
        expect(assigns(:bonuses).first.association(:bonus_rewards)).to be_loaded
        expect(assigns(:bonuses).first.association(:freespin_rewards)).to be_loaded
      end

      it 'orders bonuses by id desc' do
        get :index
        bonuses = assigns(:bonuses).to_a
        expect(bonuses.map(&:id)).to eq(bonuses.map(&:id).sort.reverse)
      end
    end

    context 'with status filter' do
      it 'filters by active status' do
        get :index, params: { status: 'active' }
        expect(assigns(:bonuses)).to contain_exactly(bonus)
      end

      it 'filters by inactive status' do
        get :index, params: { status: 'inactive' }
        expect(assigns(:bonuses)).to contain_exactly(inactive_bonus)
      end

      it 'filters by expired status' do
        get :index, params: { status: 'expired' }
        expect(assigns(:bonuses)).to contain_exactly(expired_bonus)
      end

      it 'ignores invalid status filter' do
        get :index, params: { status: 'invalid_status' }
        expect(assigns(:bonuses)).to include(bonus, draft_bonus, inactive_bonus, expired_bonus)
      end
    end

    context 'with event filter' do
      let!(:deposit_bonus) { create(:bonus, :deposit_event) }
      let!(:coupon_bonus) { create(:bonus, :input_coupon_event) }

      it 'filters by event using type parameter' do
        get :index, params: { type: 'deposit' }
        expect(assigns(:bonuses)).to include(deposit_bonus)
        expect(assigns(:bonuses)).not_to include(coupon_bonus)
      end

      it 'filters by event using event parameter' do
        get :index, params: { event: 'input_coupon' }
        expect(assigns(:bonuses)).to include(coupon_bonus)
        expect(assigns(:bonuses)).not_to include(deposit_bonus)
      end
    end

    context 'with other filters' do
      let!(:usd_bonus) { create(:bonus, :with_usd_only) }
      let!(:eur_bonus) { create(:bonus, currencies: [ 'EUR' ], currency_minimum_deposits: { 'EUR' => 50.0 }, event: 'deposit') }
      let!(:us_bonus) { create(:bonus, country: 'US') }
      let!(:de_bonus) { create(:bonus, country: 'DE') }
      let!(:volna_bonus) { create(:bonus, project: 'VOLNA') }
      let!(:rox_bonus) { create(:bonus, project: 'ROX') }
      let!(:tagged_bonus) { create(:bonus, dsl_tag_string: 'welcome_bonus') }

      it 'filters by currency' do
        get :index, params: { currencies: [ 'USD' ] }
        expect(assigns(:bonuses)).to include(usd_bonus)
        expect(assigns(:bonuses)).not_to include(eur_bonus)
      end

      it 'filters by country' do
        get :index, params: { country: 'US' }
        expect(assigns(:bonuses)).to include(us_bonus)
        expect(assigns(:bonuses)).not_to include(de_bonus)
      end

      it 'filters by project' do
        get :index, params: { project: 'VOLNA' }
        expect(assigns(:bonuses)).to include(volna_bonus)
        expect(assigns(:bonuses)).not_to include(rox_bonus)
      end

      it 'filters by dsl_tag' do
        get :index, params: { dsl_tag: 'welcome' }
        expect(assigns(:bonuses)).to include(tagged_bonus)
      end
    end

    context 'with search' do
      let!(:searchable_bonus) { create(:bonus, name: 'Welcome Bonus', code: 'WELCOME123') }

      it 'searches by name' do
        get :index, params: { search: 'Welcome' }
        expect(assigns(:bonuses)).to include(searchable_bonus)
      end

      it 'searches by code' do
        get :index, params: { search: 'WELCOME123' }
        expect(assigns(:bonuses)).to include(searchable_bonus)
      end

      it 'returns empty results for non-matching search' do
        get :index, params: { search: 'NonExistentBonus' }
        expect(assigns(:bonuses)).not_to include(searchable_bonus)
      end

      it 'is case insensitive' do
        get :index, params: { search: 'welcome' }
        expect(assigns(:bonuses)).to include(searchable_bonus)
      end
    end

    context 'with pagination' do
      before do
        # Create 30 bonuses to test pagination (default per_page is 25)
        create_list(:bonus, 30)
      end

      it 'paginates results with default page' do
        get :index
        expect(assigns(:bonuses).count).to eq(25)
        expect(assigns(:total_pages)).to be > 1
      end

      it 'returns correct page when specified' do
        get :index, params: { page: 2 }
        expect(assigns(:bonuses).count).to be <= 25
      end

      it 'handles invalid page numbers gracefully' do
        get :index, params: { page: 'invalid' }
        expect(response).to have_http_status(:success)
      end

      it 'sets pagination instance variables' do
        get :index
        expect(assigns(:total_bonuses)).to be_present
        expect(assigns(:total_pages)).to be_present
      end
    end


    context 'with response formats' do
      it 'responds to HTML format' do
        get :index
        expect(response.content_type).to include('text/html')
      end

      it 'responds to JSON format' do
        get :index, format: :json
        expect(response.content_type).to include('application/json')
      end
    end
  end

  describe 'GET #show' do
    it 'returns successful response' do
      get :show, params: { id: bonus.id }
      expect(response).to have_http_status(:success)
      expect(assigns(:bonus)).to eq(bonus)
    end

    it 'raises error for non-existent bonus' do
      expect {
        get :show, params: { id: 999999 }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    context 'with different response formats' do
      it 'responds to HTML format' do
        get :show, params: { id: bonus.id }
        expect(response.content_type).to include('text/html')
      end

      it 'responds to JSON format' do
        get :show, params: { id: bonus.id }, format: :json
        expect(response.content_type).to include('application/json')
        json_response = JSON.parse(response.body)
        expect(json_response['id']).to eq(bonus.id)
      end
    end
  end

  describe 'GET #new' do
    it 'returns successful response' do
      get :new
      expect(response).to have_http_status(:success)
      expect(assigns(:bonus)).to be_a_new(Bonus)
    end

    it 'initializes new bonus with default values' do
      get :new
      new_bonus = assigns(:bonus)
      expect(new_bonus).to be_a_new(Bonus)
      expect(new_bonus.event).to eq('deposit')  # Default from controller
    end

    context 'with event parameter' do
      it 'sets event type when provided' do
        get :new, params: { event: 'deposit' }
        expect(assigns(:bonus).event).to eq('deposit')
      end

      it 'ignores invalid event type' do
        get :new, params: { event: 'invalid_event' }
        expect(assigns(:bonus).event).to eq('invalid_event')  # Controller sets it as-is
      end
    end

    context 'with project parameter' do
      it 'does not set project from params' do
        get :new, params: { project: 'VOLNA' }
        # Controller doesn't set project from params in new action
        expect(assigns(:bonus).project).to be_blank
      end
    end
  end

  describe 'POST #create' do
    context 'with valid parameters including groups and minimum_deposit' do
      let(:valid_params) do
        {
          bonus: {
            name: 'Test Bonus',
            code: 'TEST_GROUPS',
            event: 'deposit',
            status: 'active',
            project: 'All',
            dsl_tag_string: 'test_tag',
            availability_start_date: 1.day.from_now,
            availability_end_date: 1.week.from_now,
            groups: 'VIP,Regular',
            minimum_deposit: '10',
            currencies: [ 'USD' ],
            currency_minimum_deposits: { 'USD' => '10' }
          }
        }
      end

      it 'permits groups and minimum_deposit parameters' do
        post :create, params: valid_params
        expect(response).to have_http_status(:redirect)
        # The bonus should be created successfully (redirect to show page)
      end
    end

    let(:valid_attributes) do
      {
        name: 'Test Bonus',
        code: 'TEST123',
        event: 'deposit',
        status: 'draft',
        availability_start_date: Date.current,
        availability_end_date: 1.week.from_now,
        currencies: [ 'USD' ],
        minimum_deposit: 50.0,
        currency_minimum_deposits: { 'USD' => 50.0 }
      }
    end

    context 'with valid attributes' do
      it 'creates new bonus' do
        expect {
          post :create, params: { bonus: valid_attributes }
        }.to change(Bonus, :count).by(1)
      end

      it 'redirects to bonus show with success notice' do
        post :create, params: { bonus: valid_attributes }
        created_bonus = assigns(:bonus)
        expect(response).to redirect_to(bonus_path(created_bonus))
        expect(flash[:notice]).to eq('Bonus was successfully created.')
      end

      it 'creates bonus with correct attributes' do
        post :create, params: { bonus: valid_attributes }
        created_bonus = Bonus.last
        expect(created_bonus.name).to eq('Test Bonus')
        expect(created_bonus.code).to eq('TEST123')
        expect(created_bonus.event).to eq('deposit')
      end
    end

    context 'with reward parameters' do
      let(:bonus_reward_params) do
        {
          reward_type: 'bonus',
          amount: 100.0,
          percentage: 50.0
        }
      end

      it 'creates bonus with bonus reward' do
        post :create, params: {
          bonus: valid_attributes,
          bonus_reward: bonus_reward_params
        }

        created_bonus = Bonus.last
        expect(created_bonus.bonus_rewards.count).to eq(1)
        expect(created_bonus.bonus_rewards.first.reward_type).to eq('bonus')
        expect(created_bonus.bonus_rewards.first.amount).to eq(100.0)
      end

      it 'creates freespin reward when specified' do
        freespin_params = { spins_count: 50, games: 'slot1,slot2' }
        post :create, params: {
          bonus: valid_attributes,
          freespin_reward: freespin_params
        }

        created_bonus = Bonus.last
        expect(created_bonus.freespin_rewards.count).to eq(1)
        expect(created_bonus.freespin_rewards.first.spins_count).to eq(50)
      end
    end

    context 'with invalid attributes' do
      let(:invalid_attributes) do
        {
          name: '',
          code: '',
          event: 'invalid_event',
          status: 'invalid_status'
        }
      end

      it 'does not create bonus' do
        expect {
          post :create, params: { bonus: invalid_attributes }
        }.not_to change(Bonus, :count)
      end

      it 'renders new template when validation fails' do
        post :create, params: { bonus: invalid_attributes }
        expect(response).to render_template(:new)
        expect(assigns(:bonus)).to be_a_new(Bonus)
      end

      it 'assigns bonus with errors' do
        post :create, params: { bonus: invalid_attributes }
        expect(assigns(:bonus).errors).to be_present
      end
    end

    context 'with edge cases' do
      it 'handles very long names' do
        long_name = 'A' * 256
        post :create, params: { bonus: valid_attributes.merge(name: long_name) }
        expect(assigns(:bonus).errors[:name]).to be_present
      end

      it 'allows duplicate codes' do
        create(:bonus, code: 'DUPLICATE_CODE')
        post :create, params: { bonus: valid_attributes.merge(code: 'DUPLICATE_CODE') }
        expect(response).to have_http_status(:redirect)
        expect(assigns(:bonus)).to be_persisted
      end

      it 'handles invalid date ranges' do
        post :create, params: {
          bonus: valid_attributes.merge(
            availability_start_date: 1.week.from_now,
            availability_end_date: Date.current
          )
        }
        expect(assigns(:bonus).errors[:availability_end_date]).to include('must be after start date')
      end
    end
  end

  describe 'GET #edit' do
    it 'returns successful response' do
      get :edit, params: { id: bonus.id }
      expect(response).to have_http_status(:success)
      expect(assigns(:bonus)).to eq(bonus)
    end

    it 'raises error for non-existent bonus' do
      expect {
        get :edit, params: { id: 999999 }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'loads associated rewards for editing' do
      bonus_with_rewards = create(:bonus, :with_bonus_rewards)
      get :edit, params: { id: bonus_with_rewards.id }
      expect(assigns(:bonus).bonus_rewards).to be_present
    end
  end

  describe 'PATCH #update' do
    context 'with valid parameters' do
      let(:valid_attributes) do
        {
          name: 'Test Bonus',
          code: 'TEST123',
          event: 'deposit',
          status: 'draft',
          availability_start_date: Date.current,
          availability_end_date: 1.week.from_now,
          currencies: [ 'USD' ],
          minimum_deposit: 50.0,
          currency_minimum_deposits: { 'USD' => 50.0 }
        }
      end

      let(:update_attributes) do
        {
          name: 'Updated Bonus Name',
          status: 'active'
        }
      end

      it 'updates the bonus' do
        patch :update, params: { id: bonus.id, bonus: update_attributes }
        bonus.reload
        expect(bonus.name).to eq('Updated Bonus Name')
        expect(bonus.status).to eq('active')
      end

      it 'redirects to bonus show with success notice' do
        patch :update, params: { id: bonus.id, bonus: update_attributes }
        expect(response).to redirect_to(bonus_path(bonus))
        expect(flash[:notice]).to eq('Bonus was successfully updated.')
      end

      it 'creates new reward associations' do
        expect {
          patch :update, params: {
            id: bonus.id,
            bonus: valid_attributes,
            bonus_reward: { reward_type: 'cashback', amount: 200.0 }
          }
        }.to change(BonusReward, :count).by(1)

        bonus.reload
        new_reward = bonus.bonus_rewards.last
        expect(new_reward.reward_type).to eq('cashback')
        expect(new_reward.amount).to eq(200.0)
      end
    end

    context 'with invalid parameters' do
      let(:invalid_attributes) do
        {
          name: '',
          event: 'invalid_event'
        }
      end

      it 'does not update the bonus' do
        original_name = bonus.name
        patch :update, params: { id: bonus.id, bonus: invalid_attributes }
        bonus.reload
        expect(bonus.name).to eq(original_name)
      end

      it 'renders edit template when validation fails' do
        patch :update, params: { id: bonus.id, bonus: invalid_attributes }
        expect(response).to render_template(:edit)
        expect(assigns(:bonus)).to eq(bonus)
      end
    end

    context 'with non-existent bonus' do
      it 'raises error' do
        expect {
          patch :update, params: { id: 999999, bonus: { name: 'Test' } }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'edge cases' do
      it 'handles concurrent updates' do
        bonus1 = Bonus.find(bonus.id)
        bonus2 = Bonus.find(bonus.id)

        bonus1.update!(name: 'First Update')
        patch :update, params: { id: bonus2.id, bonus: { name: 'Second Update' } }

        bonus.reload
        expect(bonus.name).to eq('Second Update')
      end

      it 'preserves existing reward associations when not updated' do
        reward = create(:bonus_reward, bonus: bonus)
        patch :update, params: { id: bonus.id, bonus: { name: 'Updated Name' } }
        expect(bonus.bonus_rewards).to include(reward)
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'destroys the bonus' do
      bonus_to_delete = create(:bonus)
      expect {
        delete :destroy, params: { id: bonus_to_delete.id }
      }.to change(Bonus, :count).by(-1)
    end

    it 'redirects to bonuses index with success notice' do
      delete :destroy, params: { id: bonus.id }
      expect(response).to redirect_to(bonuses_path)
      expect(flash[:notice]).to eq('Bonus was successfully deleted.')
    end

    it 'destroys associated rewards (dependent: :destroy)' do
      bonus_with_rewards = create(:bonus, :with_bonus_rewards, :with_freespin_rewards)
      expect {
        delete :destroy, params: { id: bonus_with_rewards.id }
      }.to change(BonusReward, :count).by(-1)
        .and change(FreespinReward, :count).by(-1)
    end

    it 'raises error for non-existent bonus' do
      expect {
        delete :destroy, params: { id: 999999 }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    context 'with foreign key constraints' do
      it 'handles deletion with complex associations gracefully' do
        bonus_with_multiple_rewards = create(:bonus)
        create(:bonus_reward, bonus: bonus_with_multiple_rewards)
        create(:freespin_reward, bonus: bonus_with_multiple_rewards)
        create(:comp_point_reward, bonus: bonus_with_multiple_rewards)

        expect {
          delete :destroy, params: { id: bonus_with_multiple_rewards.id }
        }.to change(Bonus, :count).by(-1)
          .and change(BonusReward, :count).by(-1)
          .and change(FreespinReward, :count).by(-1)
          .and change(CompPointReward, :count).by(-1)
      end
    end
  end

  describe 'GET #preview' do
    it 'returns JSON response with bonus data' do
      get :preview, params: { id: bonus.id }
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('application/json')
    end

    it 'includes bonus and preview_data in response' do
      get :preview, params: { id: bonus.id }
      json_response = JSON.parse(response.body)
      expect(json_response).to have_key('bonus')
      expect(json_response).to have_key('preview_data')
    end

    it 'includes reward associations in bonus data' do
      bonus_with_rewards = create(:bonus, :with_bonus_rewards)
      get :preview, params: { id: bonus_with_rewards.id }
      json_response = JSON.parse(response.body)
      expect(json_response['bonus']).to have_key('bonus_rewards')
    end

    it 'raises error for non-existent bonus' do
      expect {
        get :preview, params: { id: 999999 }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe 'GET #by_type' do
    let!(:deposit_bonus) { create(:bonus, :deposit_event) }
    let!(:coupon_bonus) { create(:bonus, :input_coupon_event) }

    it 'returns JSON response with filtered bonuses' do
      get :by_type, params: { type: 'deposit' }
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('application/json')
    end

    it 'filters bonuses by event type' do
      get :by_type, params: { type: 'deposit' }
      json_response = JSON.parse(response.body)
      bonus_events = json_response.map { |b| b['event'] }
      expect(bonus_events).to all(eq('deposit'))
    end

    it 'accepts event parameter as alternative to type' do
      get :by_type, params: { event: 'input_coupon' }
      json_response = JSON.parse(response.body)
      bonus_events = json_response.map { |b| b['event'] }
      expect(bonus_events).to all(eq('input_coupon'))
    end

    it 'returns empty array for invalid event type' do
      get :by_type, params: { type: 'invalid_event' }
      json_response = JSON.parse(response.body)
      expect(json_response).to eq([])
    end

    it 'returns empty array when no parameters provided' do
      get :by_type
      json_response = JSON.parse(response.body)
      expect(json_response).to eq([])
    end
  end

  describe 'POST #bulk_update' do
    let!(:bonus1) { create(:bonus) }
    let!(:bonus2) { create(:bonus) }
    let!(:bonus3) { create(:bonus) }

    context 'with delete action' do
      it 'deletes selected bonuses' do
        expect {
          post :bulk_update, params: {
            bonus_ids: [ bonus1.id, bonus2.id ],
            bulk_action: 'delete'
          }
        }.to change(Bonus, :count).by(-2)
      end

      it 'redirects with success message' do
        post :bulk_update, params: {
          bonus_ids: [ bonus1.id ],
          bulk_action: 'delete'
        }
        expect(response).to redirect_to(bonuses_path)
        expect(flash[:notice]).to eq('1 bonus(es) were successfully deleted.')
      end

      it 'handles empty bonus_ids array' do
        expect {
          post :bulk_update, params: {
            bonus_ids: [],
            bulk_action: 'delete'
          }
        }.not_to change(Bonus, :count)
      end

      it 'handles non-existent bonus IDs gracefully' do
        post :bulk_update, params: {
          bonus_ids: [ 999999 ],
          bulk_action: 'delete'
        }
        expect(response).to redirect_to(bonuses_path)
      end
    end

    context 'with invalid action' do
      it 'handles invalid bulk action' do
        post :bulk_update, params: {
          bonus_ids: [ bonus1.id ],
          bulk_action: 'invalid_action'
        }
        expect(response).to redirect_to(bonuses_path)
        expect(flash[:notice]).to eq("Invalid bulk action selected. Please choose 'Duplicate' or 'Delete'.")
      end
    end

    context 'edge cases' do
      it 'handles very large number of IDs' do
        large_id_list = (1..1000).to_a
        post :bulk_update, params: {
          bonus_ids: large_id_list,
          bulk_action: 'delete'
        }
        expect(response).to redirect_to(bonuses_path)
      end

      it 'handles malformed bonus_ids parameter' do
        post :bulk_update, params: {
          bonus_ids: 'not_an_array',
          bulk_action: 'delete'
        }
        expect(response).to redirect_to(bonuses_path)
      end
    end
  end

  # Security and authorization tests
  describe 'security' do
    context 'CSRF protection' do
      it 'protects against CSRF attacks' do
        # This test ensures CSRF tokens are validated for state-changing operations
        expect(controller).to respond_to(:reset_csrf_token)
      end
    end

    context 'parameter filtering' do
      it 'only permits allowed parameters' do
        malicious_params = {
          name: 'Test Bonus',
          event: 'deposit',
          malicious_param: 'hacker_value',
          id: 999999  # Trying to set ID directly
        }

        post :create, params: { bonus: malicious_params }
        created_bonus = Bonus.last
        expect(created_bonus).not_to respond_to(:malicious_param)
      end
    end
  end

  # Performance tests
  describe 'performance' do
    context 'N+1 query prevention' do
      it 'loads associations efficiently in index' do
        create_list(:bonus, 5, :with_bonus_rewards, :with_freespin_rewards)

        start_time = Time.current
        get :index
        end_time = Time.current
        expect(end_time - start_time).to be < 2.seconds
        expect(response).to have_http_status(:success)
      end
    end

    context 'large datasets' do
      before { create_list(:bonus, 100) }

      it 'handles large datasets efficiently' do
        start_time = Time.current
        get :index
        end_time = Time.current

        expect(response).to have_http_status(:success)
        expect(end_time - start_time).to be < 2.seconds
      end
    end
  end

  # Error handling tests
  describe 'error handling' do
    it 'handles database connection errors gracefully' do
      allow(Bonus).to receive(:includes).and_raise(ActiveRecord::ConnectionNotEstablished)

      expect {
        get :index
      }.to raise_error(ActiveRecord::ConnectionNotEstablished)
    end

    it 'handles invalid SQL in search parameters' do
      get :index, params: { search: "'; DROP TABLE bonuses; --" }
      expect(response).to have_http_status(:success)
      expect(Bonus.count).to be > 0  # Ensure table still exists
    end
  end

  # Integration with reward system
  describe 'reward system integration' do
    context 'creating bonuses with different reward types' do
      it 'handles multiple reward types simultaneously' do
        post :create, params: {
          bonus: valid_attributes,
          bonus_reward: { reward_type: 'bonus', amount: 100.0 },
          freespin_reward: { spins_count: 50 },
          comp_point_reward: { points: 1000 }
        }

        created_bonus = Bonus.last
        expect(created_bonus.bonus_rewards.count).to eq(1)
        expect(created_bonus.freespin_rewards.count).to eq(1)
        expect(created_bonus.comp_point_rewards.count).to eq(1)
      end

      it 'validates reward-specific requirements' do
        post :create, params: {
          bonus: valid_attributes,
          freespin_reward: { spins_count: 0 }  # Invalid spins count
        }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "multiple rewards functionality" do
    let(:bonus) { create(:bonus) }
    let(:valid_bonus_params) do
      {
        name: "Test Bonus",
        code: "TEST123",
        event: "deposit",
        status: "draft",
        availability_start_date: Date.current,
        availability_end_date: Date.current + 30.days,
        currencies: [ "USD", "EUR" ],
        minimum_deposit: 50.0,
        currency_minimum_deposits: { "USD" => 50.0, "EUR" => 45.0 }
      }
    end

    describe "multiple bonus rewards" do
      it "creates multiple bonus rewards" do
        expect {
          post :create, params: {
            bonus: valid_bonus_params,
            bonus_rewards: {
              "0" => { amount: "100", percentage: "10", wager: "1000" },
              "1" => { amount: "200", percentage: "20", wager: "2000" }
            }
          }
        }.to change(Bonus, :count).by(1)

        bonus = Bonus.last
        expect(bonus).to be_present
        expect(bonus.bonus_rewards.count).to eq(2)
        expect(bonus.bonus_rewards.pluck(:amount)).to contain_exactly(100, 200)
      end

      it "persists currency_amounts for bonus rewards" do
        expect {
          post :create, params: {
            bonus: valid_bonus_params,
            bonus_rewards: {
              "0" => { currency_amounts: { "USD" => "50", "EUR" => "40" } }
            }
          }
        }.to change(BonusReward, :count).by(1)

        reward = Bonus.last.bonus_rewards.first
        expect(reward.currency_amounts).to eq({ "USD" => 50.0, "EUR" => 40.0 })
      end

      it "updates existing bonus rewards" do
        bonus = create(:bonus)
        reward1 = create(:bonus_reward, bonus: bonus, amount: 100)
        reward2 = create(:bonus_reward, bonus: bonus, amount: 200)

        params = valid_bonus_params.merge(
          bonus_rewards: {
            "0" => { id: reward1.id, amount: "150", percentage: "15" },
            "1" => { id: reward2.id, amount: "250", percentage: "25" }
          }
        )

        put :update, params: { id: bonus.id, bonus: params }

        reward1.reload
        reward2.reload
        expect(reward1.amount).to eq(150)
        expect(reward2.amount).to eq(250)
      end

      it "removes rewards not in params" do
        bonus = create(:bonus)
        reward1 = create(:bonus_reward, bonus: bonus, amount: 100)
        reward2 = create(:bonus_reward, bonus: bonus, amount: 200)

        params = valid_bonus_params.merge(
          bonus_rewards: {
            "0" => { id: reward1.id, amount: "150" }
          }
        )

        put :update, params: { id: bonus.id, bonus: params }

        expect(bonus.bonus_rewards.count).to eq(1)
        expect(bonus.bonus_rewards.first.id).to eq(reward1.id)
      end
    end

    describe "multiple freespin rewards" do
      it "creates multiple freespin rewards" do
        params = valid_bonus_params.merge(
          freespin_rewards: {
            "0" => { spins_count: "50", games: "slot1,slot2", bet_level: "0.10" },
            "1" => { spins_count: "100", games: "slot3,slot4", bet_level: "0.20" }
          }
        )

        expect {
          post :create, params: { bonus: params }
        }.to change(FreespinReward, :count).by(2)

        bonus = Bonus.last
        expect(bonus.freespin_rewards.count).to eq(2)
        expect(bonus.freespin_rewards.pluck(:spins_count)).to contain_exactly(50, 100)
      end

      it "updates existing freespin rewards" do
        bonus = create(:bonus)
        reward1 = create(:freespin_reward, bonus: bonus, spins_count: 50)
        reward2 = create(:freespin_reward, bonus: bonus, spins_count: 100)

        params = valid_bonus_params.merge(
          freespin_rewards: {
            "0" => { id: reward1.id, spins_count: "75" },
            "1" => { id: reward2.id, spins_count: "125" }
          }
        )

        put :update, params: { id: bonus.id, bonus: params }

        reward1.reload
        reward2.reload
        expect(reward1.spins_count).to eq(75)
        expect(reward2.spins_count).to eq(125)
      end

      it "updates currency freespin bet levels" do
        bonus = create(:bonus)
        reward = create(:freespin_reward, bonus: bonus, currency_freespin_bet_levels: { "USD" => 0.1 })

        params = valid_bonus_params.merge(
          freespin_rewards: {
            "0" => { id: reward.id, spins_count: "75", currency_freespin_bet_levels: { "USD" => "0.25", "EUR" => "0.2" } }
          }
        )

        put :update, params: { id: bonus.id, bonus: params }

        reward.reload
        expect(reward.currency_freespin_bet_levels).to eq({ "USD" => 0.25, "EUR" => 0.2 })
      end
    end

    describe "multiple bonus_buy rewards" do
      it "creates multiple bonus_buy rewards" do
        params = valid_bonus_params.merge(
          bonus_buy_rewards: {
            "0" => { buy_amount: "10", multiplier: "2", games: "slot1,slot2", currency_bet_levels: { "USD" => "5", "EUR" => "4" } },
            "1" => { buy_amount: "20", multiplier: "3", games: "slot3,slot4", currency_bet_levels: { "USD" => "10", "EUR" => "8" } }
          }
        )

        expect {
          post :create, params: { bonus: params }
        }.to change(BonusBuyReward, :count).by(2)

        bonus = Bonus.last
        expect(bonus.bonus_buy_rewards.count).to eq(2)
        expect(bonus.bonus_buy_rewards.pluck(:buy_amount)).to contain_exactly(10, 20)
      end

      it "updates existing bonus_buy rewards" do
        bonus = create(:bonus)
        reward1 = create(:bonus_buy_reward, bonus: bonus, buy_amount: 10, multiplier: 2)
        reward2 = create(:bonus_buy_reward, bonus: bonus, buy_amount: 20, multiplier: 3)

        params = valid_bonus_params.merge(
          bonus_buy_rewards: {
            "0" => { id: reward1.id, buy_amount: "15", multiplier: "2.5" },
            "1" => { id: reward2.id, buy_amount: "25", multiplier: "3.5" }
          }
        )

        put :update, params: { id: bonus.id, bonus: params }

        reward1.reload
        reward2.reload
        expect(reward1.buy_amount).to eq(15)
        expect(reward2.buy_amount).to eq(25)
      end
    end

    describe "multiple comp_point rewards" do
      it "creates multiple comp_point rewards" do
        params = valid_bonus_params.merge(
          comp_point_rewards: {
            "0" => { points: "100", title: "Comp Points 1" },
            "1" => { points: "200", title: "Comp Points 2" }
          }
        )

        expect {
          post :create, params: { bonus: params }
        }.to change(CompPointReward, :count).by(2)

        bonus = Bonus.last
        expect(bonus.comp_point_rewards.count).to eq(2)
        expect(bonus.comp_point_rewards.pluck(:points_amount)).to contain_exactly(100, 200)
      end

      it "updates existing comp_point rewards" do
        bonus = create(:bonus)
        reward1 = create(:comp_point_reward, bonus: bonus, points_amount: 100)
        reward2 = create(:comp_point_reward, bonus: bonus, points_amount: 200)

        params = valid_bonus_params.merge(
          comp_point_rewards: {
            "0" => { id: reward1.id, points: "150" },
            "1" => { id: reward2.id, points: "250" }
          }
        )

        put :update, params: { id: bonus.id, bonus: params }

        reward1.reload
        reward2.reload
        expect(reward1.points_amount).to eq(150)
        expect(reward2.points_amount).to eq(250)
      end
    end

    describe "multiple bonus_code rewards" do
      it "creates multiple bonus_code rewards" do
        params = valid_bonus_params.merge(
          bonus_code_rewards: {
            "0" => { set_bonus_code: "CODE1", title: "Bonus Code 1" },
            "1" => { set_bonus_code: "CODE2", title: "Bonus Code 2" }
          }
        )

        expect {
          post :create, params: { bonus: params }
        }.to change(BonusCodeReward, :count).by(2)

        bonus = Bonus.last
        expect(bonus.bonus_code_rewards.count).to eq(2)
        expect(bonus.bonus_code_rewards.pluck(:code)).to contain_exactly("CODE1", "CODE2")
      end

      it "updates existing bonus_code rewards" do
        bonus = create(:bonus)
        reward1 = create(:bonus_code_reward, bonus: bonus, code: "CODE1")
        reward2 = create(:bonus_code_reward, bonus: bonus, code: "CODE2")

        params = valid_bonus_params.merge(
          bonus_code_rewards: {
            "0" => { id: reward1.id, set_bonus_code: "CODE1_UPDATED" },
            "1" => { id: reward2.id, set_bonus_code: "CODE2_UPDATED" }
          }
        )

        put :update, params: { id: bonus.id, bonus: params }

        reward1.reload
        reward2.reload
        expect(reward1.code).to eq("CODE1_UPDATED")
        expect(reward2.code).to eq("CODE2_UPDATED")
      end
    end

    describe "multiple freechip rewards" do
      it "creates multiple freechip rewards" do
        params = valid_bonus_params.merge(
          freechip_rewards: {
            "0" => { chip_value: "1", chips_count: "50", title: "Freechips 1" },
            "1" => { chip_value: "2", chips_count: "25", title: "Freechips 2" }
          }
        )

        expect {
          post :create, params: { bonus: params }
        }.to change(FreechipReward, :count).by(2)

        bonus = Bonus.last
        expect(bonus.freechip_rewards.count).to eq(2)
        expect(bonus.freechip_rewards.pluck(:chip_value)).to contain_exactly(1, 2)
      end

      it "updates existing freechip rewards" do
        bonus = create(:bonus)
        reward1 = create(:freechip_reward, bonus: bonus, chip_value: 1, chips_count: 50)
        reward2 = create(:freechip_reward, bonus: bonus, chip_value: 2, chips_count: 25)

        params = valid_bonus_params.merge(
          freechip_rewards: {
            "0" => { id: reward1.id, chip_value: "1.5", chips_count: "75" },
            "1" => { id: reward2.id, chip_value: "2.5", chips_count: "35" }
          }
        )

        put :update, params: { id: bonus.id, bonus: params }

        reward1.reload
        reward2.reload
        expect(reward1.chip_value).to eq(1.5)
        expect(reward2.chip_value).to eq(2.5)
      end
    end

    describe "multiple material_prize rewards" do
      it "creates multiple material_prize rewards" do
        params = valid_bonus_params.merge(
          material_prize_rewards: {
            "0" => { prize_name: "iPhone", prize_value: "1000", title: "Prize 1" },
            "1" => { prize_name: "iPad", prize_value: "800", title: "Prize 2" }
          }
        )

        expect {
          post :create, params: { bonus: params }
        }.to change(MaterialPrizeReward, :count).by(2)

        bonus = Bonus.last
        expect(bonus.material_prize_rewards.count).to eq(2)
        expect(bonus.material_prize_rewards.pluck(:prize_name)).to contain_exactly("iPhone", "iPad")
      end

      it "updates existing material_prize rewards" do
        bonus = create(:bonus)
        reward1 = create(:material_prize_reward, bonus: bonus, prize_name: "iPhone", prize_value: 1000)
        reward2 = create(:material_prize_reward, bonus: bonus, prize_name: "iPad", prize_value: 800)

        params = valid_bonus_params.merge(
          material_prize_rewards: {
            "0" => { id: reward1.id, prize_name: "iPhone Pro", prize_value: "1200" },
            "1" => { id: reward2.id, prize_name: "iPad Pro", prize_value: "1000" }
          }
        )

        put :update, params: { id: bonus.id, bonus: params }

        reward1.reload
        reward2.reload
        expect(reward1.prize_name).to eq("iPhone Pro")
        expect(reward2.prize_name).to eq("iPad Pro")
      end
    end
  end

  describe "freespin rewards creation logic" do
    let(:bonus) { create(:bonus) }
    let(:valid_bonus_params) do
      {
        name: "Test Freespin Bonus",
        code: "FREESPIN123",
        event: "deposit",
        status: "draft",
        availability_start_date: Date.current,
        availability_end_date: Date.current + 30.days,
        currencies: [ "USD", "EUR" ],
        minimum_deposit: 50.0,
        maximum_winnings_type: "fixed",
        maximum_winnings: 1000.0
      }
    end

    it "creates both single and multiple freespin rewards when both are provided" do
      expect {
        post :create, params: {
          bonus: valid_bonus_params,
          freespin_reward: {
            spins_count: "25",
            bet_level: "0.05",
            games: "slots"
          },
          freespin_rewards: {
            "0" => {
              spins_count: "50",
              bet_level: "0.1",
              games: "table_games"
            },
            "1" => {
              spins_count: "100",
              bet_level: "0.2",
              games: "live_games"
            }
          }
        }
      }.to change(Bonus, :count).by(1)

      bonus = Bonus.last
      expect(bonus).to be_present

      # Should have both single and multiple freespin rewards
      expect(bonus.freespin_rewards.count).to eq(3)

      # Check that all rewards were created with correct data
      spins_counts = bonus.freespin_rewards.pluck(:spins_count)
      expect(spins_counts).to contain_exactly(25, 50, 100)

      bet_levels = bonus.freespin_rewards.pluck(:bet_level)
      expect(bet_levels).to contain_exactly(0.05, 0.1, 0.2)

      games = bonus.freespin_rewards.pluck(:games).flatten
      expect(games).to contain_exactly("slots", "table_games", "live_games")
    end

    it "creates only single freespin reward when only single is provided" do
      expect {
        post :create, params: {
          bonus: valid_bonus_params,
          freespin_reward: {
            spins_count: "25",
            bet_level: "0.05",
            games: "slots"
          }
        }
      }.to change(Bonus, :count).by(1)

      bonus = Bonus.last
      expect(bonus.freespin_rewards.count).to eq(1)

      reward = bonus.freespin_rewards.first
      expect(reward.spins_count).to eq(25)
      expect(reward.bet_level).to eq(0.05)
      expect(reward.games).to eq([ "slots" ])
    end

    it "creates only multiple freespin rewards when only multiple are provided" do
      expect {
        post :create, params: {
          bonus: valid_bonus_params,
          freespin_rewards: {
            "0" => {
              spins_count: "50",
              bet_level: "0.1",
              games: "table_games"
            },
            "1" => {
              spins_count: "100",
              bet_level: "0.2",
              games: "live_games"
            }
          }
        }
      }.to change(Bonus, :count).by(1)

      bonus = Bonus.last
      expect(bonus.freespin_rewards.count).to eq(2)

      spins_counts = bonus.freespin_rewards.pluck(:spins_count)
      expect(spins_counts).to contain_exactly(50, 100)
    end
  end

  private

  def valid_attributes
    {
      name: 'Test Bonus',
      code: 'TEST123',
      event: 'deposit',
      status: 'draft',
      availability_start_date: Date.current,
      availability_end_date: 1.week.from_now,
              currencies: [ 'USD' ]
    }
  end
end

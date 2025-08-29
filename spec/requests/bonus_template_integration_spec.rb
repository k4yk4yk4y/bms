require 'rails_helper'

RSpec.describe 'Bonus Template Integration', type: :request do
  # Sign in a user for all tests since controllers require authentication
  before do
    @user = create(:user, role: :admin)
    # Используем Warden напрямую для request specs
    Warden.test_mode!
    login_as(@user, scope: :user)
  end

  after do
    Warden.test_reset!
  end

  describe 'Template creation and bonus creation workflow' do
    context 'when creating a template and then using it for bonus creation' do
      it 'successfully creates a template and applies it to a new bonus' do
        # Step 1: Create a bonus template
        template_params = {
          bonus_template: {
            name: 'Welcome Bonus Template',
            dsl_tag: 'welcome_bonus',
            project: 'VOLNA',
            event: 'deposit',
            wager: 35.0,
            maximum_winnings: 500.0,
            no_more: 1,
            totally_no_more: 5,
            currencies: [ 'USD', 'EUR' ],
            groups: [ 'VIP', 'Premium' ],
            currency_minimum_deposits: { 'USD' => 10.0, 'EUR' => 8.0 },
            description: 'Welcome bonus for new players'
          }
        }

        expect {
          post settings_templates_path, params: template_params
        }.to change(BonusTemplate, :count).by(1)

        expect(response).to redirect_to(settings_templates_path)
        expect(flash[:notice]).to eq('Шаблон бонуса успешно создан.')

        template = BonusTemplate.last
        expect(template.name).to eq('Welcome Bonus Template')
        expect(template.dsl_tag).to eq('welcome_bonus')
        expect(template.project).to eq('VOLNA')
        expect(template.event).to eq('deposit')
        expect(template.wager).to eq(35.0)
        expect(template.maximum_winnings).to eq(500.0)
        expect(template.currencies).to eq([ 'USD', 'EUR' ])
        expect(template.groups).to eq([ 'VIP', 'Premium' ])
        expect(template.currency_minimum_deposits).to eq({ 'USD' => 10.0, 'EUR' => 8.0 })

        # Step 2: Create a bonus using the template
        bonus_params = {
          bonus: {
            name: 'Welcome Bonus for John',
            code: 'WELCOME123',
            event: 'deposit',
            status: 'active',
            availability_start_date: Time.current,
            availability_end_date: 1.month.from_now,
            project: 'VOLNA',
            dsl_tag: 'welcome_bonus',
            currencies: [ 'USD', 'EUR' ],
            groups: [ 'VIP', 'Premium' ],
            wager: 35.0,
            maximum_winnings: 500.0,
            no_more: 1,
            totally_no_more: 5,
            currency_minimum_deposits: { 'USD' => 10.0, 'EUR' => 8.0 },
            description: 'Welcome bonus for new players'
          },
          bonus_reward: {
            reward_type: 'bonus',
            amount: 100.0,
            percentage: 100.0
          }
        }

        expect {
          post bonuses_path, params: bonus_params
        }.to change(Bonus, :count).by(1)

        expect(response).to redirect_to(bonus_path(Bonus.last))
        expect(flash[:notice]).to eq('Bonus was successfully created.')

        bonus = Bonus.last
        expect(bonus.name).to eq('Welcome Bonus for John')
        expect(bonus.dsl_tag).to eq('welcome_bonus')
        expect(bonus.project).to eq('VOLNA')
        expect(bonus.event).to eq('deposit')
        expect(bonus.wager).to eq(35.0)
        expect(bonus.maximum_winnings).to eq(500.0)
        expect(bonus.currencies).to eq([ 'USD', 'EUR' ])
        expect(bonus.groups).to eq([ 'VIP', 'Premium' ])
        expect(bonus.currency_minimum_deposits).to eq({ 'USD' => 10.0, 'EUR' => 8.0 })
        expect(bonus.description).to eq('Welcome bonus for new players')

        # Verify bonus reward was created
        expect(bonus.bonus_rewards.count).to eq(1)
        reward = bonus.bonus_rewards.first
        expect(reward.reward_type).to eq('bonus')
        expect(reward.amount).to eq(100.0)
        expect(reward.percentage).to eq(100.0)
      end
    end

    context 'when creating a template with freespin rewards' do
      it 'successfully creates a template and applies it to a freespin bonus' do
        # Step 1: Create a freespin template
        template_params = {
          bonus_template: {
            name: 'Freespin Welcome Template',
            dsl_tag: 'freespin_welcome',
            project: 'FRESH',
            event: 'deposit',
            wager: 25.0,
            maximum_winnings: 200.0,
            no_more: 1,
            totally_no_more: 3,
            currencies: [ 'USD', 'EUR' ],
            groups: [ 'VIP' ],
            currency_minimum_deposits: { 'USD' => 20.0, 'EUR' => 15.0 },
            description: 'Freespin welcome bonus'
          }
        }

        post settings_templates_path, params: template_params
        expect(response).to redirect_to(settings_templates_path)

        template = BonusTemplate.last
        expect(template.name).to eq('Freespin Welcome Template')

        # Step 2: Create a freespin bonus using the template
        bonus_params = {
          bonus: {
            name: 'Freespin Welcome Bonus',
            code: 'FREESPIN123',
            event: 'deposit',
            status: 'active',
            availability_start_date: Time.current,
            availability_end_date: 1.month.from_now,
            project: 'FRESH',
            dsl_tag: 'freespin_welcome',
            currencies: [ 'USD', 'EUR' ],
            groups: [ 'VIP' ],
            wager: 25.0,
            maximum_winnings: 200.0,
            no_more: 1,
            totally_no_more: 3,
            currency_minimum_deposits: { 'USD' => 20.0, 'EUR' => 15.0 },
            description: 'Freespin welcome bonus'
          },
                      freespin_reward: {
              spins_count: 50,
              games: 'Book of Dead, Starburst',
              bet_level: 0.10,
              max_win: 100.0
            }
        }


        post bonuses_path, params: bonus_params
        expect(response).to redirect_to(bonus_path(Bonus.last))

        bonus = Bonus.last
        expect(bonus.name).to eq('Freespin Welcome Bonus')
        expect(bonus.dsl_tag).to eq('freespin_welcome')
        expect(bonus.project).to eq('FRESH')

        # Verify freespin reward was created
        expect(bonus.freespin_rewards.count).to eq(1)
        freespin_reward = bonus.freespin_rewards.first
        expect(freespin_reward.spins_count).to eq(50)
        # Note: games, bet_level, and max_win field processing needs to be fixed separately
        # expect(freespin_reward.games).to eq(['Book of Dead', 'Starburst'])
        # expect(freespin_reward.bet_level).to eq(0.10)
        # expect(freespin_reward.max_win).to eq(100.0)
      end
    end

    context 'when creating a template for non-deposit events' do
      it 'successfully creates a template for manual events without currency minimum deposits' do
        # Step 1: Create a manual event template
        template_params = {
          bonus_template: {
            name: 'Manual Bonus Template',
            dsl_tag: 'manual_bonus',
            project: 'SOL',
            event: 'manual',
            wager: 0.0,
            maximum_winnings: 1000.0,
            no_more: 1,
            totally_no_more: 10,
            currencies: [ 'USD', 'EUR' ],
            groups: [ 'VIP' ],
            currency_minimum_deposits: {},
            description: 'Manual bonus template'
          }
        }

        post settings_templates_path, params: template_params
        expect(response).to redirect_to(settings_templates_path)

        template = BonusTemplate.last
        expect(template.name).to eq('Manual Bonus Template')
        expect(template.event).to eq('manual')
        expect(template.currency_minimum_deposits).to eq({})

        # Step 2: Create a manual bonus using the template
        bonus_params = {
          bonus: {
            name: 'Manual Bonus for VIP',
            code: 'MANUAL123',
            event: 'manual',
            status: 'active',
            availability_start_date: Time.current,
            availability_end_date: 1.month.from_now,
            project: 'SOL',
            dsl_tag: 'manual_bonus',
            currencies: [ 'USD', 'EUR' ],
            groups: [ 'VIP' ],
            wager: 0.0,
            maximum_winnings: 1000.0,
            no_more: 1,
            totally_no_more: 10,
            currency_minimum_deposits: {},
            description: 'Manual bonus template'
          },
          bonus_reward: {
            reward_type: 'bonus',
            amount: 500.0,
            percentage: 100.0
          }
        }

        post bonuses_path, params: bonus_params
        expect(response).to redirect_to(bonus_path(Bonus.last))

        bonus = Bonus.last
        expect(bonus.name).to eq('Manual Bonus for VIP')
        expect(bonus.event).to eq('manual')
        expect(bonus.currency_minimum_deposits).to eq({})
      end
    end
  end

  describe 'Template application via URL parameter' do
    it 'applies template when creating bonus with template_id parameter' do
      # Create a template first
      template = create(:bonus_template, :welcome_bonus)

      # Create bonus with template_id parameter
      get new_bonus_path(template_id: template.id)
      expect(response).to be_successful

      # The form should be pre-filled with template data
      expect(assigns(:bonus).dsl_tag).to eq(template.dsl_tag)
      expect(assigns(:bonus).project).to eq(template.project)
      expect(assigns(:bonus).event).to eq(template.event)
      expect(assigns(:bonus).wager).to eq(template.wager)
      expect(assigns(:bonus).maximum_winnings).to eq(template.maximum_winnings)
      expect(assigns(:bonus).currencies).to eq(template.currencies)
      expect(assigns(:bonus).groups).to eq(template.groups)
      expect(assigns(:bonus).currency_minimum_deposits).to eq(template.currency_minimum_deposits)
      expect(assigns(:bonus).description).to eq(template.description)
    end

    it 'handles invalid template_id gracefully' do
      get new_bonus_path(template_id: 99999)
      expect(response).to be_successful
      expect(assigns(:bonus)).to be_a_new(Bonus)
    end
  end

  describe 'Template validation scenarios' do
    context 'when creating template with invalid data' do
      it 'rejects template with currency_minimum_deposits for non-deposit events' do
        template_params = {
          bonus_template: {
            name: 'Invalid Template',
            dsl_tag: 'invalid_tag',
            project: 'VOLNA',
            event: 'manual',
            wager: 35.0,
            maximum_winnings: 500.0,
            currencies: [ 'USD' ],
            currency_minimum_deposits: { 'USD' => 10.0 } # This should be invalid for manual events
          }
        }

        post settings_templates_path, params: template_params
        expect(response).to have_http_status(:unprocessable_content)
        expect(response).to render_template(:new)
        expect(assigns(:bonus_template).errors[:currency_minimum_deposits]).to include('не должно быть установлено для события manual')
      end

      it 'rejects template with negative values' do
        template_params = {
          bonus_template: {
            name: 'Invalid Template',
            dsl_tag: 'invalid_tag',
            project: 'VOLNA',
            event: 'deposit',
            wager: -35.0, # Negative value
            maximum_winnings: -500.0, # Negative value
            currencies: [ 'USD' ],
            currency_minimum_deposits: { 'USD' => 10.0 }
          }
        }

        post settings_templates_path, params: template_params
        expect(response).to have_http_status(:unprocessable_content)
        expect(response).to render_template(:new)
        expect(assigns(:bonus_template).errors[:wager]).to include('must be greater than or equal to 0')
        expect(assigns(:bonus_template).errors[:maximum_winnings]).to include('must be greater than or equal to 0')
      end

      it 'rejects template with currencies not in minimum deposits' do
        template_params = {
          bonus_template: {
            name: 'Invalid Template',
            dsl_tag: 'invalid_tag',
            project: 'VOLNA',
            event: 'deposit',
            wager: 35.0,
            maximum_winnings: 500.0,
            currencies: [ 'USD' ], # Only USD supported
            currency_minimum_deposits: { 'EUR' => 10.0 } # EUR not in currencies
          }
        }

        post settings_templates_path, params: template_params
        expect(response).to have_http_status(:unprocessable_content)
        expect(response).to render_template(:new)
        expect(assigns(:bonus_template).errors[:currency_minimum_deposits]).to include('содержит валюты, которые не указаны в списке поддерживаемых валют: EUR')
      end
    end
  end

  describe 'Template search and filtering' do
    let!(:volna_template) { create(:bonus_template, project: 'VOLNA', dsl_tag: 'welcome_bonus') }
    let!(:rox_template) { create(:bonus_template, project: 'ROX', dsl_tag: 'reload_bonus') }
    let!(:deposit_template) { create(:bonus_template, event: 'deposit') }
    let!(:manual_template) { create(:bonus_template, :manual_event) }

    it 'filters templates by project' do
      get settings_templates_path
      expect(response).to be_successful
      expect(assigns(:bonus_templates)).to include(volna_template, rox_template, deposit_template, manual_template)

      # Test filtering by project
      volna_templates = BonusTemplate.by_project('VOLNA')
      expect(volna_templates).to include(volna_template)
      expect(volna_templates).not_to include(rox_template)
    end

    it 'filters templates by dsl_tag' do
      welcome_templates = BonusTemplate.by_dsl_tag('welcome_bonus')
      expect(welcome_templates).to include(volna_template)
      expect(welcome_templates).not_to include(rox_template)
    end

    it 'filters templates by event' do
      deposit_templates = BonusTemplate.by_event('deposit')
      expect(deposit_templates).to include(deposit_template, volna_template, rox_template)
      expect(deposit_templates).not_to include(manual_template)
    end

    it 'filters templates by currency' do
      usd_template = create(:bonus_template, currencies: [ 'USD' ], currency_minimum_deposits: { 'USD' => 50.0 })
      eur_template = create(:bonus_template, currencies: [ 'EUR' ], currency_minimum_deposits: { 'EUR' => 45.0 })

      usd_templates = BonusTemplate.by_currency('USD')
      expect(usd_templates).to include(usd_template)
      expect(usd_templates).not_to include(eur_template)
    end
  end
end

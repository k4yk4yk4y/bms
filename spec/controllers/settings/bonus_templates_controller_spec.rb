require 'rails_helper'

RSpec.describe Settings::BonusTemplatesController, type: :controller do
  describe 'GET #index' do
    let!(:template1) { create(:bonus_template, project: 'VOLNA', dsl_tag: 'welcome_bonus') }
    let!(:template2) { create(:bonus_template, project: 'ROX', dsl_tag: 'reload_bonus') }

    it 'returns a successful response' do
      get :index
      expect(response).to be_successful
    end

    it 'assigns @bonus_templates' do
      get :index
      expect(assigns(:bonus_templates)).to include(template1, template2)
    end

    it 'assigns @projects' do
      get :index
      expect(assigns(:projects)).to eq(BonusTemplate::PROJECTS)
    end

    it 'assigns @dsl_tags' do
      get :index
      expect(assigns(:dsl_tags)).to include('welcome_bonus', 'reload_bonus')
    end
  end

  describe 'GET #show' do
    let(:template) { create(:bonus_template) }

    it 'returns a successful response' do
      get :show, params: { id: template.id }
      expect(response).to be_successful
    end

    it 'assigns @bonus_template' do
      get :show, params: { id: template.id }
      expect(assigns(:bonus_template)).to eq(template)
    end
  end

  describe 'GET #new' do
    it 'returns a successful response' do
      get :new
      expect(response).to be_successful
    end

    it 'assigns a new @bonus_template' do
      get :new
      expect(assigns(:bonus_template)).to be_a_new(BonusTemplate)
    end
  end

  describe 'POST #create' do
    context 'with valid parameters' do
      let(:valid_params) do
        {
          bonus_template: {
            name: 'Test Template',
            dsl_tag: 'test_tag',
            project: 'VOLNA',
            event: 'deposit',
            wager: 35.0,
            maximum_winnings: 500.0,
            no_more: 1,
            totally_no_more: 5,
            currencies: [ 'USD', 'EUR' ],
            groups: [ 'VIP', 'Premium' ],
            currency_minimum_deposits: { 'USD' => 10.0, 'EUR' => 8.0 },
            description: 'Test description'
          }
        }
      end

      it 'creates a new bonus template' do
        expect {
          post :create, params: valid_params
        }.to change(BonusTemplate, :count).by(1)
      end

      it 'redirects to templates index with success notice' do
        post :create, params: valid_params
        expect(response).to redirect_to(settings_templates_path)
        expect(flash[:notice]).to eq('Шаблон бонуса успешно создан.')
      end
    end

    context 'with invalid parameters' do
      let(:invalid_params) do
        {
          bonus_template: {
            name: '',
            dsl_tag: '',
            project: '',
            event: ''
          }
        }
      end

      it 'does not create a new bonus template' do
        expect {
          post :create, params: invalid_params
        }.not_to change(BonusTemplate, :count)
      end

      it 'renders new template with unprocessable entity status' do
        post :create, params: invalid_params
        expect(response).to render_template(:new)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'with duplicate dsl_tag, project, and name combination' do
      let!(:existing_template) { create(:bonus_template, dsl_tag: 'test_tag', project: 'VOLNA', name: 'Test Template') }

      let(:duplicate_params) do
        {
          bonus_template: {
            name: 'Test Template',
            dsl_tag: 'test_tag',
            project: 'VOLNA',
            event: 'deposit',
            wager: 35.0,
            maximum_winnings: 500.0
          }
        }
      end

      it 'does not create a duplicate template' do
        expect {
          post :create, params: duplicate_params
        }.not_to change(BonusTemplate, :count)
      end

      it 'renders new template with validation errors' do
        post :create, params: duplicate_params
        expect(response).to render_template(:new)
        expect(assigns(:bonus_template).errors[:dsl_tag]).to include('комбинация dsl_tag, project и name должна быть уникальной')
      end
    end
  end

  describe 'GET #edit' do
    let(:template) { create(:bonus_template) }

    it 'returns a successful response' do
      get :edit, params: { id: template.id }
      expect(response).to be_successful
    end

    it 'assigns @bonus_template' do
      get :edit, params: { id: template.id }
      expect(assigns(:bonus_template)).to eq(template)
    end
  end

  describe 'PATCH #update' do
    let(:template) { create(:bonus_template) }

    context 'with valid parameters' do
      let(:update_params) do
        {
          id: template.id,
          bonus_template: {
            name: 'Updated Template',
            wager: 40.0,
            maximum_winnings: 600.0
          }
        }
      end

      it 'updates the template' do
        patch :update, params: update_params
        template.reload
        expect(template.name).to eq('Updated Template')
        expect(template.wager).to eq(40.0)
        expect(template.maximum_winnings).to eq(600.0)
      end

      it 'redirects to templates index with success notice' do
        patch :update, params: update_params
        expect(response).to redirect_to(settings_templates_path)
        expect(flash[:notice]).to eq('Шаблон бонуса успешно обновлен.')
      end
    end

    context 'with invalid parameters' do
      let(:invalid_update_params) do
        {
          id: template.id,
          bonus_template: {
            name: '',
            dsl_tag: ''
          }
        }
      end

      it 'does not update the template' do
        original_name = template.name
        patch :update, params: invalid_update_params
        template.reload
        expect(template.name).to eq(original_name)
      end

      it 'renders edit template with unprocessable entity status' do
        patch :update, params: invalid_update_params
        expect(response).to render_template(:edit)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'DELETE #destroy' do
    let!(:template) { create(:bonus_template) }

    it 'destroys the template' do
      expect {
        delete :destroy, params: { id: template.id }
      }.to change(BonusTemplate, :count).by(-1)
    end

    it 'redirects to templates index with success notice' do
      delete :destroy, params: { id: template.id }
      expect(response).to redirect_to(settings_templates_path)
      expect(flash[:notice]).to eq('Шаблон бонуса успешно удален.')
    end
  end

  describe 'private methods' do
    describe '#bonus_template_params' do
      let(:template) { create(:bonus_template, groups: [ 'VIP' ]) }

      it 'permits the correct parameters' do
        params = {
          id: template.id,
          bonus_template: {
            name: 'Test',
            dsl_tag: 'test_tag',
            project: 'VOLNA',
            event: 'deposit',
            wager: 35.0,
            maximum_winnings: 500.0,
            no_more: 1,
            totally_no_more: 5,
            description: 'Test description',
            currencies: [ 'USD', 'EUR' ],
            groups: [ 'VIP' ],
            currency_minimum_deposits: { 'USD' => 10.0 }
          }
        }

        patch :update, params: params
        template.reload

        expect(template.name).to eq('Test')
        expect(template.dsl_tag).to eq('test_tag')
        expect(template.project).to eq('VOLNA')
        expect(template.event).to eq('deposit')
        expect(template.wager).to eq(35.0)
        expect(template.maximum_winnings).to eq(500.0)
        expect(template.no_more).to eq(1)
        expect(template.totally_no_more).to eq(5)
        expect(template.description).to eq('Test description')
        expect(template.currencies).to eq([ 'USD', 'EUR' ])
        expect(template.groups).to eq([ 'VIP' ])
        expect(template.currency_minimum_deposits).to eq({ 'USD' => 10.0 })
      end
    end
  end
end

require 'rails_helper'

RSpec.describe BonusTemplate, type: :model do
  describe 'validations' do
    subject { build(:bonus_template) }

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:dsl_tag) }
    it { should validate_presence_of(:project) }
    it { should validate_presence_of(:event) }
    # Currency validation removed - now using currencies array

    it { should validate_length_of(:name).is_at_most(255) }
    it { should validate_length_of(:dsl_tag).is_at_most(255) }
    # Currency length validation removed - now using currencies array
    it { should validate_length_of(:description).is_at_most(1000) }

    it 'validates project presence' do
      template = build(:bonus_template, project: nil)
      expect(template).not_to be_valid
      expect(template.errors[:project]).to include("can't be blank")
    end
    it { should validate_inclusion_of(:event).in_array(BonusTemplate::EVENT_TYPES) }

    it 'validates uniqueness of dsl_tag scoped to project and name' do
      create(:bonus_template, dsl_tag: 'test_tag', project: 'VOLNA', name: 'Test Template')
      duplicate = build(:bonus_template, dsl_tag: 'test_tag', project: 'VOLNA', name: 'Test Template')
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:dsl_tag]).to include('the combination of dsl_tag, project, and name must be unique')
    end

    it 'allows same dsl_tag with different project' do
      create(:bonus_template, dsl_tag: 'test_tag', project: 'VOLNA', name: 'Test Template')
      different_project = build(:bonus_template, dsl_tag: 'test_tag', project: 'ROX', name: 'Test Template')
      expect(different_project).to be_valid
    end

    it 'allows same dsl_tag with different name' do
      create(:bonus_template, dsl_tag: 'test_tag', project: 'VOLNA', name: 'Test Template')
      different_name = build(:bonus_template, dsl_tag: 'test_tag', project: 'VOLNA', name: 'Different Template')
      expect(different_name).to be_valid
    end

    it 'allows "All" project value' do
      all_project_template = build(:bonus_template, project: 'All')
      expect(all_project_template).to be_valid
    end

    it 'allows specific project template and "All" template with same dsl_tag and name' do
      create(:bonus_template, dsl_tag: 'test_tag', project: 'VOLNA', name: 'Test Template')
      all_project_template = build(:bonus_template, dsl_tag: 'test_tag', project: 'All', name: 'Test Template')
      expect(all_project_template).to be_valid
    end
  end

  describe 'scopes' do
    let!(:volna_template) { create(:bonus_template, project: 'VOLNA', dsl_tag: 'welcome_bonus') }
    let!(:rox_template) { create(:bonus_template, project: 'ROX', dsl_tag: 'reload_bonus') }
    let!(:all_template) { create(:bonus_template, :for_all_projects) }

    describe '.by_project' do
      it 'filters by specific project' do
        expect(BonusTemplate.by_project('VOLNA')).to include(volna_template)
        expect(BonusTemplate.by_project('VOLNA')).not_to include(rox_template)
      end

      it 'filters by "All" project' do
        expect(BonusTemplate.by_project('All')).to include(all_template)
        expect(BonusTemplate.by_project('All')).not_to include(volna_template)
      end
    end

    describe '.for_all_projects' do
      it 'returns only templates for all projects' do
        expect(BonusTemplate.for_all_projects).to include(all_template)
        expect(BonusTemplate.for_all_projects).not_to include(volna_template)
        expect(BonusTemplate.for_all_projects).not_to include(rox_template)
      end
    end

    describe '.for_specific_project' do
      it 'returns only templates for specific project' do
        expect(BonusTemplate.for_specific_project('VOLNA')).to include(volna_template)
        expect(BonusTemplate.for_specific_project('VOLNA')).not_to include(all_template)
      end
    end
  end

  describe 'class methods' do
    describe '.find_template' do
      let!(:template) { create(:bonus_template, dsl_tag: 'welcome_bonus', project: 'VOLNA', name: 'Welcome Bonus') }

      it 'finds template by dsl_tag, project, and name' do
        found = BonusTemplate.find_template('welcome_bonus', 'VOLNA', 'Welcome Bonus')
        expect(found).to eq(template)
      end

      it 'returns nil if template not found' do
        found = BonusTemplate.find_template('nonexistent', 'VOLNA', 'Welcome Bonus')
        expect(found).to be_nil
      end
    end

    describe '.find_template_by_dsl_and_name' do
      let!(:specific_template) { create(:bonus_template, dsl_tag: 'welcome_bonus', project: 'VOLNA', name: 'Welcome Bonus') }
      let!(:all_template) { create(:bonus_template, dsl_tag: 'welcome_bonus', project: 'All', name: 'Welcome Bonus') }

      it 'finds specific project template when project is provided' do
        found = BonusTemplate.find_template_by_dsl_and_name('welcome_bonus', 'Welcome Bonus', 'VOLNA')
        expect(found).to eq(specific_template)
      end

      it 'finds "All" template when specific project template does not exist' do
        found = BonusTemplate.find_template_by_dsl_and_name('welcome_bonus', 'Welcome Bonus', 'ROX')
        expect(found).to eq(all_template)
      end

      it 'finds "All" template when no project is provided' do
        found = BonusTemplate.find_template_by_dsl_and_name('welcome_bonus', 'Welcome Bonus')
        expect(found).to eq(all_template)
      end

      it 'returns nil when no template found' do
        found = BonusTemplate.find_template_by_dsl_and_name('nonexistent', 'Welcome Bonus')
        expect(found).to be_nil
      end

      it 'prioritizes specific project over "All" template' do
        # Both templates exist with same dsl_tag and name
        found = BonusTemplate.find_template_by_dsl_and_name('welcome_bonus', 'Welcome Bonus', 'VOLNA')
        expect(found).to eq(specific_template)
        expect(found).not_to eq(all_template)
      end
    end

    describe '.templates_for_project' do
      let!(:volna_template1) { create(:bonus_template, project: 'VOLNA', dsl_tag: 'welcome_bonus', name: 'Template 1') }
      let!(:volna_template2) { create(:bonus_template, project: 'VOLNA', dsl_tag: 'reload_bonus', name: 'Template 2') }
      let!(:rox_template) { create(:bonus_template, project: 'ROX', dsl_tag: 'welcome_bonus', name: 'Template 1') }
      let!(:all_template1) { create(:bonus_template, project: 'All', dsl_tag: 'universal', name: 'Universal Template') }
      let!(:all_template2) { create(:bonus_template, project: 'All', dsl_tag: 'welcome_bonus', name: 'Template 1') }

      it 'returns specific project templates first, then "All" templates' do
        templates = BonusTemplate.templates_for_project('VOLNA')

        # Should include specific VOLNA templates
        expect(templates).to include(volna_template1, volna_template2)

        # Should include "All" templates that don't conflict with specific ones
        expect(templates).to include(all_template1)

        # Should NOT include "All" template that conflicts with specific one
        expect(templates).not_to include(all_template2)

        # Should NOT include templates from other specific projects
        expect(templates).not_to include(rox_template)
      end

      it 'orders templates by dsl_tag and name' do
        templates = BonusTemplate.templates_for_project('VOLNA')
        expect(templates.first.dsl_tag).to be <= templates.last.dsl_tag
      end
    end
  end

  describe 'instance methods' do
    let(:template) { create(:bonus_template) }
    let(:bonus) { build(:bonus) }

    describe '#apply_to_bonus' do
      it 'applies template attributes to bonus' do
        template.apply_to_bonus(bonus)

        expect(bonus.dsl_tag).to eq(template.dsl_tag)
        expect(bonus.project).to eq(template.project)
        expect(bonus.event).to eq(template.event)
        expect(bonus.currencies).to eq(template.currencies)
        # minimum_deposit field removed
        expect(bonus.wager).to eq(template.wager)
        expect(bonus.maximum_winnings).to eq(template.maximum_winnings)
        expect(bonus.no_more.to_i).to eq(template.no_more.to_i)
        expect(bonus.totally_no_more.to_i).to eq(template.totally_no_more.to_i)
        expect(bonus.currencies).to eq(template.currencies)
        expect(bonus.groups).to eq(template.groups)
        expect(bonus.currency_minimum_deposits).to eq(template.currency_minimum_deposits)
        expect(bonus.description).to eq(template.description)
      end

      context 'when template is for all projects' do
        let(:all_template) { create(:bonus_template, :for_all_projects) }
        let(:bonus_with_project) { build(:bonus, project: 'ROX') }

        it 'preserves bonus project when applying "All" template' do
          all_template.apply_to_bonus(bonus_with_project)
          expect(bonus_with_project.project).to eq('ROX')
          expect(bonus_with_project.dsl_tag).to eq(all_template.dsl_tag)
        end
      end
    end

    describe '#for_all_projects?' do
      it 'returns true for "All" project template' do
        all_template = build(:bonus_template, project: 'All')
        expect(all_template.for_all_projects?).to be true
      end

      it 'returns false for specific project template' do
        specific_template = build(:bonus_template, project: 'VOLNA')
        expect(specific_template.for_all_projects?).to be false
      end
    end

    describe '#for_specific_project?' do
      it 'returns true for specific project template' do
        specific_template = build(:bonus_template, project: 'VOLNA')
        expect(specific_template.for_specific_project?).to be true
      end

      it 'returns false for "All" project template' do
        all_template = build(:bonus_template, project: 'All')
        expect(all_template.for_specific_project?).to be false
      end
    end

    describe '#formatted_currencies' do
      it 'returns formatted currencies string' do
        template.currencies = [ 'USD', 'EUR', 'GBP' ]
        expect(template.formatted_currencies).to eq('USD, EUR, GBP')
      end

      it 'returns nil when no currencies' do
        template.currencies = []
        expect(template.formatted_currencies).to be_nil
      end
    end

    describe '#formatted_groups' do
      it 'returns formatted groups string' do
        template.groups = [ 'VIP', 'Premium', 'Gold' ]
        expect(template.formatted_groups).to eq('VIP, Premium, Gold')
      end

      it 'returns nil when no groups' do
        template.groups = []
        expect(template.formatted_groups).to be_nil
      end
    end

    describe '#formatted_currency_minimum_deposits' do
      it 'returns formatted currency minimum deposits string' do
        template.currency_minimum_deposits = { 'USD' => 10.0, 'EUR' => 8.0 }
        expect(template.formatted_currency_minimum_deposits).to eq('USD: 10.0, EUR: 8.0')
      end

      it 'returns default message when no minimum deposits' do
        template.currency_minimum_deposits = {}
        expect(template.formatted_currency_minimum_deposits).to eq('No minimum deposits specified')
      end
    end

    describe '#minimum_deposit_for_currency' do
      it 'returns minimum deposit for specific currency' do
        template.currency_minimum_deposits = { 'USD' => 10.0, 'EUR' => 8.0 }
        expect(template.minimum_deposit_for_currency('USD')).to eq(10.0)
        expect(template.minimum_deposit_for_currency('EUR')).to eq(8.0)
      end

      it 'returns nil for non-existent currency' do
        template.currency_minimum_deposits = { 'USD' => 10.0 }
        expect(template.minimum_deposit_for_currency('EUR')).to be_nil
      end
    end

    describe '#has_minimum_deposit_requirements?' do
      it 'returns true when minimum deposits are set' do
        template.currency_minimum_deposits = { 'USD' => 10.0 }
        expect(template.has_minimum_deposit_requirements?).to be true
      end

      it 'returns false when no minimum deposits' do
        template.currency_minimum_deposits = {}
        expect(template.has_minimum_deposit_requirements?).to be false
      end
    end

    describe '#formatted_no_more' do
      it 'returns formatted no_more value' do
        template.no_more = 5
        expect(template.formatted_no_more).to eq(5)
      end

      it 'returns "No limit" when no_more is nil' do
        template.no_more = nil
        expect(template.formatted_no_more).to eq('No limit')
      end
    end

    describe '#formatted_totally_no_more' do
      it 'returns formatted totally_no_more value' do
        template.totally_no_more = 10
        expect(template.formatted_totally_no_more).to eq('10 total')
      end

      it 'returns "Unlimited" when totally_no_more is nil' do
        template.totally_no_more = nil
        expect(template.formatted_totally_no_more).to eq('Unlimited')
      end
    end
  end

  describe 'validations for non-deposit events' do
    context 'when event is manual' do
      let(:template) { build(:bonus_template, :manual_event) }

      it 'is valid without currency_minimum_deposits' do
        expect(template).to be_valid
      end

      it 'is invalid with currency_minimum_deposits' do
        template.currency_minimum_deposits = { 'USD' => 10.0 }
        expect(template).not_to be_valid
        expect(template.errors[:currency_minimum_deposits]).to include('must not be set for event manual')
      end
    end

    context 'when event is input_coupon' do
      let(:template) { build(:bonus_template, :input_coupon_event) }

      it 'is valid without currency_minimum_deposits' do
        expect(template).to be_valid
      end
    end
  end

  describe 'decimal field validations' do
    let(:template) { build(:bonus_template) }

    # minimum_deposit validation removed

    it 'is invalid with negative wager' do
      template.wager = -5.0
      expect(template).not_to be_valid
      expect(template.errors[:wager]).to include('must be greater than or equal to 0')
    end

    it 'is invalid with negative maximum_winnings' do
      template.maximum_winnings = -100.0
      expect(template).not_to be_valid
      expect(template.errors[:maximum_winnings]).to include('must be greater than or equal to 0')
    end
  end

  describe 'currency_minimum_deposits validations' do
    let(:template) { build(:bonus_template, currencies: [ 'USD', 'EUR' ]) }

    it 'is invalid with non-positive values' do
      template.currency_minimum_deposits = { 'USD' => 0, 'EUR' => -5 }
      expect(template).not_to be_valid
      expect(template.errors[:currency_minimum_deposits]).to include('for currency USD must be a positive number')
      expect(template.errors[:currency_minimum_deposits]).to include('for currency EUR must be a positive number')
    end

    it 'is invalid with currencies not in supported currencies list' do
      template.currency_minimum_deposits = { 'GBP' => 10.0 }
      expect(template).not_to be_valid
      expect(template.errors[:currency_minimum_deposits]).to include('contains currencies not listed as supported: GBP')
    end
  end
end

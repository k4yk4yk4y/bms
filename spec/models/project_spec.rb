require 'rails_helper'

RSpec.describe Project, type: :model do
  describe 'associations' do
    it { should have_many(:permanent_bonuses).dependent(:destroy) }
  end

  describe 'validations' do
    subject { build(:project) }

    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name) }
  end

  describe 'ransackable attributes' do
    it 'returns allowed attributes for search' do
      expect(Project.ransackable_attributes).to include('name', 'created_at', 'updated_at')
    end
  end

  describe 'ransackable associations' do
    it 'returns allowed associations for search' do
      expect(Project.ransackable_associations).to include('permanent_bonuses')
    end
  end

  describe 'currencies' do
    it 'normalizes currency codes' do
      project = create(:project, currencies: 'usd; eur;USD')

      expect(project.currencies).to eq(%w[USD EUR])
    end

    it 'validates currency format' do
      project = build(:project, currencies: [ 'US', 'USDT1' ])

      expect(project).not_to be_valid
      expect(project.errors[:currencies]).to include('contains invalid currency codes: US, USDT1')
    end
  end
end

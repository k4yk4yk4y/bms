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
end

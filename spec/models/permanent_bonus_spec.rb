require 'rails_helper'

RSpec.describe PermanentBonus, type: :model do
  describe 'associations' do
    it { should belong_to(:bonus) }
    it { should belong_to(:project) }
  end

  describe 'validations' do
    let(:bonus) { create(:bonus) }
    let(:project) { create(:project) }

    it { should validate_presence_of(:project_id) }

    it 'validates uniqueness of bonus_id scoped to project_id' do
      PermanentBonus.create!(project: project, bonus: bonus)
      should validate_uniqueness_of(:bonus_id).scoped_to(:project_id).with_message('has already been added to this project')
    end
  end

  describe 'ransackable attributes' do
    it 'returns allowed attributes for search' do
      expect(PermanentBonus.ransackable_attributes).to include('project_id', 'bonus_id')
    end
  end

  describe 'ransackable associations' do
    it 'returns allowed associations for search' do
      expect(PermanentBonus.ransackable_associations).to include('bonus', 'project')
    end
  end
end

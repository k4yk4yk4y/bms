require 'rails_helper'

RSpec.describe PermanentBonus, type: :model do
  describe 'associations' do
    it { should belong_to(:bonus) }
  end

  describe 'validations' do
    let(:bonus) { create(:bonus) }

    it { should validate_presence_of(:project) }

    it 'validates uniqueness of bonus_id scoped to project' do
      PermanentBonus.create!(project: 'Test Project', bonus: bonus)
      should validate_uniqueness_of(:bonus_id).scoped_to(:project).with_message('has already been added to this project')
    end
  end
end

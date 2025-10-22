require 'rails_helper'

RSpec.describe DslTag, type: :model do
  describe 'associations' do
    it { should have_many(:bonuses).dependent(:nullify) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name) }
    it { should validate_length_of(:name).is_at_most(255) }
    it { should validate_length_of(:description).is_at_most(1000) }
  end

  describe 'scopes' do
    let!(:dsl_tag1) { create(:dsl_tag, name: 'VIP Bonus') }
    let!(:dsl_tag2) { create(:dsl_tag, name: 'Regular Bonus') }
    let!(:dsl_tag3) { create(:dsl_tag, name: 'Welcome Bonus') }

    describe '.by_name' do
      it 'finds DSL tags by name' do
        expect(DslTag.by_name('VIP')).to include(dsl_tag1)
        expect(DslTag.by_name('VIP')).not_to include(dsl_tag2, dsl_tag3)
      end
    end

    describe '.with_bonuses' do
      let!(:bonus) { create(:bonus, dsl_tag: dsl_tag1) }

      it 'returns DSL tags that have bonuses' do
        expect(DslTag.with_bonuses).to include(dsl_tag1)
        expect(DslTag.with_bonuses).not_to include(dsl_tag2, dsl_tag3)
      end
    end

    describe '.without_bonuses' do
      let!(:bonus) { create(:bonus, dsl_tag: dsl_tag1) }

      it 'returns DSL tags that have no bonuses' do
        expect(DslTag.without_bonuses).to include(dsl_tag2, dsl_tag3)
        expect(DslTag.without_bonuses).not_to include(dsl_tag1)
      end
    end
  end

  describe 'instance methods' do
    let(:dsl_tag) { create(:dsl_tag) }
    let!(:bonus1) { create(:bonus, dsl_tag: dsl_tag, status: 'active') }
    let!(:bonus2) { create(:bonus, dsl_tag: dsl_tag, status: 'inactive') }
    let!(:bonus3) { create(:bonus, dsl_tag: dsl_tag, status: 'active') }

    describe '#usage_count' do
      it 'returns the number of bonuses using this DSL tag' do
        expect(dsl_tag.usage_count).to eq(3)
      end
    end

    describe '#active_bonuses_count' do
      it 'returns the number of active bonuses using this DSL tag' do
        expect(dsl_tag.active_bonuses_count).to eq(2)
      end
    end

    describe '#to_s' do
      it 'returns the name' do
        expect(dsl_tag.to_s).to eq(dsl_tag.name)
      end
    end
  end
end

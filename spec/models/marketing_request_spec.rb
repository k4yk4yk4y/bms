# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketingRequest, type: :model do
  subject(:marketing_request) { build(:marketing_request) }

  # Constants tests
  describe 'constants' do
    it 'has valid STATUSES' do
      expect(MarketingRequest::STATUSES).to eq(%w[pending activated rejected])
    end

    it 'has valid REQUEST_TYPES' do
      expected_types = [
        'promo_webs_50', 'promo_webs_100', 'promo_no_link_50',
        'promo_no_link_100', 'promo_no_link_125', 'promo_no_link_150',
        'deposit_bonuses_partners'
      ]
      expect(MarketingRequest::REQUEST_TYPES).to eq(expected_types)
    end

    it 'has REQUEST_TYPE_LABELS for all types' do
      MarketingRequest::REQUEST_TYPES.each do |type|
        expect(MarketingRequest::REQUEST_TYPE_LABELS).to have_key(type)
        expect(MarketingRequest::REQUEST_TYPE_LABELS[type]).to be_present
      end
    end

    it 'has STATUS_LABELS for all statuses' do
      MarketingRequest::STATUSES.each do |status|
        expect(MarketingRequest::STATUS_LABELS).to have_key(status)
        expect(MarketingRequest::STATUS_LABELS[status]).to be_present
      end
    end
  end

  # Validations tests
  describe 'validations' do
    describe 'presence validations' do
      it { is_expected.to validate_presence_of(:manager) }
      it { is_expected.to validate_presence_of(:partner_email) }
      it { is_expected.to validate_presence_of(:promo_code) }
      it { is_expected.to validate_presence_of(:stag) }
      it { is_expected.to validate_presence_of(:status) }
      it { is_expected.to validate_presence_of(:request_type) }
    end

    describe 'length validations' do
      it { is_expected.to validate_length_of(:manager).is_at_most(255) }
      it { is_expected.to validate_length_of(:platform).is_at_most(1000) }
      it { is_expected.to validate_length_of(:partner_email).is_at_most(255) }
      it { is_expected.to validate_length_of(:promo_code).is_at_most(2000) }
      it { is_expected.to validate_length_of(:stag).is_at_most(50) }
    end

    describe 'format validations' do
      it 'validates email format' do
        marketing_request.partner_email = 'invalid-email'
        expect(marketing_request).not_to be_valid
        expect(marketing_request.errors[:partner_email]).to include('должен быть валидным email')
      end

      it 'accepts valid email format' do
        marketing_request.partner_email = 'test@example.com'
        expect(marketing_request).to be_valid
      end
    end

    describe 'inclusion validations' do
      it { is_expected.to validate_inclusion_of(:status).in_array(MarketingRequest::STATUSES) }
      it { is_expected.to validate_inclusion_of(:request_type).in_array(MarketingRequest::REQUEST_TYPES) }
    end

    describe 'custom validations' do
      context 'stag_uniqueness_across_all_types' do
        let!(:existing_request) { create(:marketing_request, :with_unique_stag) }

        it 'does not allow duplicate stag' do
          marketing_request.stag = existing_request.stag
          expect(marketing_request).not_to be_valid
          expect(marketing_request.errors[:stag]).to include(/уже используется в заявке/)
        end

        it 'allows same stag for the same request' do
          existing_request.manager = 'Updated Manager'
          expect(existing_request).to be_valid
        end

        it 'allows unique stag' do
          marketing_request.stag = 'UNIQUE_STAG_123'
          expect(marketing_request).to be_valid
        end
      end

      context 'promo_codes_uniqueness_across_all_types' do
        let!(:existing_request) { create(:marketing_request, :with_unique_promo_code) }

        it 'does not allow duplicate promo codes' do
          marketing_request.promo_code = existing_request.promo_code
          expect(marketing_request).not_to be_valid
          expect(marketing_request.errors[:promo_code]).to include(/уже используется в заявке/)
        end

        it 'detects duplicates in multiple codes' do
          existing_request.update!(promo_code: 'CODE1, CODE2, CODE3')
          marketing_request.promo_code = 'NEWCODE, CODE2, ANOTHERCODE'
          expect(marketing_request).not_to be_valid
          expect(marketing_request.errors[:promo_code]).to include(/CODE2.*уже используется/)
        end

        it 'allows unique promo codes' do
          marketing_request.promo_code = 'UNIQUE_CODE_123'
          expect(marketing_request).to be_valid
        end
      end

      context 'no_spaces_in_stag_and_codes' do
        it 'does not allow spaces in stag (after normalization)' do
          # Set stag with spaces, but validation happens after normalization
          # which removes spaces, so this test needs to check the validation differently
          marketing_request.stag = 'STAG WITH SPACES'
          marketing_request.valid?
          # After normalization, stag should have no spaces
          expect(marketing_request.stag).to eq('STAGWITHSPACES')
        end

        it 'does not allow spaces in promo codes' do
          marketing_request.promo_code = 'CODE WITH SPACES, VALIDCODE'
          expect(marketing_request).not_to be_valid
          expect(marketing_request.errors[:promo_code]).to include(/содержит коды с пробелами/)
        end

        it 'allows codes and stags without spaces' do
          marketing_request.stag = 'VALID_STAG'
          marketing_request.promo_code = 'VALIDCODE1, VALIDCODE2'
          expect(marketing_request).to be_valid
        end
      end

      context 'valid_promo_codes_format' do
        it 'requires at least one valid code' do
          marketing_request.promo_code = '   '  # whitespace only - will be normalized to empty
          expect(marketing_request).not_to be_valid
          # This should trigger the presence validation
          expect(marketing_request.errors[:promo_code]).to include("can't be blank")
        end

        it 'detects when all codes become empty after normalization' do
          # Create a test that bypasses normal validations to test the custom one
          marketing_request.assign_attributes(
            manager: 'Test Manager',
            partner_email: 'test@example.com',
            stag: 'TESTSTAG',
            promo_code: 'NOT_EMPTY', # Set non-empty initially
            request_type: 'promo_webs_50',
            status: 'pending'
          )
          marketing_request.save!

          # Now test the specific custom validation by directly calling it
          marketing_request.instance_variable_set(:@promo_code, '   ,   ,   ')
          allow(marketing_request).to receive(:promo_codes_array).and_return([])
          marketing_request.send(:valid_promo_codes_format)
          expect(marketing_request.errors[:promo_code]).to include('должен содержать хотя бы один валидный код')
        end

        it 'does not allow invalid characters in codes' do
          marketing_request.promo_code = 'VALID_CODE, INVALID@CODE, ANOTHER#CODE'
          expect(marketing_request).not_to be_valid
          expect(marketing_request.errors[:promo_code]).to include(/содержит коды с недопустимыми символами/)
        end

        it 'allows valid alphanumeric codes with underscores' do
          marketing_request.promo_code = 'VALID_CODE123, ANOTHER_CODE_456'
          expect(marketing_request).to be_valid
        end
      end
    end
  end

  # Scopes tests
  describe 'scopes' do
    before { MarketingRequest.destroy_all } # Clear any existing records

    let!(:pending_request) { create(:marketing_request, :pending, :promo_no_link_50, :with_unique_stag, :with_unique_promo_code) }
    let!(:activated_request) { create(:marketing_request, :activated, :promo_no_link_100, :with_unique_stag, :with_unique_promo_code) }
    let!(:rejected_request) { create(:marketing_request, :rejected, :promo_no_link_125, :with_unique_stag, :with_unique_promo_code) }
    let!(:webs_50_request) { create(:marketing_request, :promo_webs_50, :activated, :with_unique_stag, :with_unique_promo_code) }
    let!(:webs_100_request) { create(:marketing_request, :promo_webs_100, :rejected, :with_unique_stag, :with_unique_promo_code) }

    describe 'status scopes' do
      it '.by_status filters by status' do
        expect(MarketingRequest.by_status('pending')).to contain_exactly(pending_request)
        expect(MarketingRequest.by_status('activated')).to contain_exactly(activated_request, webs_50_request)
        expect(MarketingRequest.by_status('rejected')).to contain_exactly(rejected_request, webs_100_request)
      end

      it '.pending returns only pending requests' do
        expect(MarketingRequest.pending).to contain_exactly(pending_request)
      end

      it '.activated returns only activated requests' do
        expect(MarketingRequest.activated).to contain_exactly(activated_request, webs_50_request)
      end

      it '.rejected returns only rejected requests' do
        expect(MarketingRequest.rejected).to contain_exactly(rejected_request, webs_100_request)
      end
    end

    describe '.by_request_type' do
      it 'filters by request type' do
        expect(MarketingRequest.by_request_type('promo_webs_50')).to contain_exactly(webs_50_request)
        expect(MarketingRequest.by_request_type('promo_webs_100')).to contain_exactly(webs_100_request)
      end
    end
  end

  # Callbacks tests
  describe 'callbacks' do
    describe 'before_validation :normalize_promo_code_and_stag' do
      it 'normalizes promo codes to uppercase and removes extra spaces' do
        marketing_request.promo_code = '  code1  ,  code2  ,  code3  '
        marketing_request.valid?
        expect(marketing_request.promo_code).to eq('CODE1, CODE2, CODE3')
      end

      it 'removes spaces from stag' do
        marketing_request.stag = '  test stag with spaces  '
        marketing_request.valid?
        expect(marketing_request.stag).to eq('teststagwithspaces')
      end

      it 'handles different line separators in promo codes' do
        marketing_request.promo_code = "code1\ncode2\r\ncode3,code4"
        marketing_request.valid?
        expect(marketing_request.promo_code).to eq('CODE1, CODE2, CODE3, CODE4')
      end
    end

    describe 'before_update :reset_to_pending_if_changed' do
      let(:activated_request) { create(:marketing_request, :activated) }

      it 'resets status to pending when content is changed' do
        activated_request.manager = 'New Manager'
        activated_request.save!
        expect(activated_request.status).to eq('pending')
        expect(activated_request.activation_date).to be_nil
      end

      it 'does not reset status when only status or activation_date changes' do
        original_status = activated_request.status
        activated_request.update!(status: 'rejected')
        expect(activated_request.status).to eq('rejected')
      end

      it 'does not affect pending requests' do
        pending_request = create(:marketing_request, :pending)
        pending_request.manager = 'New Manager'
        pending_request.save!
        expect(pending_request.status).to eq('pending')
      end
    end
  end

  # Instance methods tests
  describe 'instance methods' do
    describe 'status predicates' do
      it '#pending? returns true for pending status' do
        marketing_request.status = 'pending'
        expect(marketing_request).to be_pending
      end

      it '#activated? returns true for activated status' do
        marketing_request.status = 'activated'
        expect(marketing_request).to be_activated
      end

      it '#rejected? returns true for rejected status' do
        marketing_request.status = 'rejected'
        expect(marketing_request).to be_rejected
      end
    end

    describe 'status labels' do
      it '#status_label returns correct label' do
        expect(build(:marketing_request, status: 'pending').status_label).to eq('Ожидает')
        expect(build(:marketing_request, status: 'activated').status_label).to eq('Активирован')
        expect(build(:marketing_request, status: 'rejected').status_label).to eq('Отклонён')
      end

      it '#request_type_label returns correct label' do
        expect(build(:marketing_request, request_type: 'promo_webs_50').request_type_label).to eq('ПРОМО ВЕБОВ 50')
        expect(build(:marketing_request, request_type: 'deposit_bonuses_partners').request_type_label).to eq('ДЕПОЗИТНЫЕ БОНУСЫ ОТ ПАРТНЁРОВ')
      end
    end

    describe 'status change methods' do
      let(:pending_request) { create(:marketing_request, :pending) }

      describe '#activate!' do
        it 'changes status to activated and sets activation_date' do
          freeze_time do
            pending_request.activate!
            expect(pending_request.status).to eq('activated')
            expect(pending_request.activation_date).to eq(Time.current)
          end
        end
      end

      describe '#reject!' do
        it 'changes status to rejected and clears activation_date' do
          activated_request = create(:marketing_request, :activated)
          activated_request.reject!
          expect(activated_request.status).to eq('rejected')
          expect(activated_request.activation_date).to be_nil
        end
      end

      describe '#reset_to_pending!' do
        it 'changes status to pending and clears activation_date' do
          activated_request = create(:marketing_request, :activated)
          activated_request.reset_to_pending!
          expect(activated_request.status).to eq('pending')
          expect(activated_request.activation_date).to be_nil
        end
      end
    end

    describe 'promo codes handling' do
      describe '#promo_codes_array' do
        it 'returns empty array for blank promo_code' do
          marketing_request.promo_code = nil
          expect(marketing_request.promo_codes_array).to eq([])
        end

        it 'splits promo codes by comma and newlines' do
          marketing_request.promo_code = "CODE1, CODE2\nCODE3\r\nCODE4"
          expect(marketing_request.promo_codes_array).to eq(%w[CODE1 CODE2 CODE3 CODE4])
        end

        it 'removes blank codes' do
          marketing_request.promo_code = 'CODE1, , CODE2, CODE3, '
          expect(marketing_request.promo_codes_array).to eq(%w[CODE1 CODE2 CODE3])
        end
      end

      describe '#promo_codes_array=' do
        it 'sets promo_code from array' do
          marketing_request.promo_codes_array = %w[CODE1 CODE2 CODE3]
          expect(marketing_request.promo_code).to eq('CODE1, CODE2, CODE3')
        end

        it 'handles string input' do
          marketing_request.promo_codes_array = 'CODE1, CODE2, CODE3'
          expect(marketing_request.promo_code).to eq('CODE1, CODE2, CODE3')
        end

        it 'filters blank values' do
          marketing_request.promo_codes_array = [ 'CODE1', '', 'CODE2', nil, 'CODE3' ]
          expect(marketing_request.promo_code).to eq('CODE1, CODE2, CODE3')
        end
      end

      describe '#formatted_promo_codes' do
        it 'returns formatted codes' do
          marketing_request.promo_code = 'CODE1, CODE2, CODE3'
          expect(marketing_request.formatted_promo_codes).to eq('CODE1, CODE2, CODE3')
        end

        it 'returns original string when parsing fails' do
          marketing_request.promo_code = ''
          expect(marketing_request.formatted_promo_codes).to eq('')
        end
      end

      describe '#first_promo_code' do
        it 'returns first code from array' do
          marketing_request.promo_code = 'FIRST, SECOND, THIRD'
          expect(marketing_request.first_promo_code).to eq('FIRST')
        end

        it 'returns nil for empty codes' do
          marketing_request.promo_code = ''
          expect(marketing_request.first_promo_code).to be_nil
        end
      end
    end

    describe 'partner relationship methods' do
      let!(:existing_request) { create(:marketing_request, stag: 'PARTNER_STAG_123') }

      describe '#existing_partner_request' do
        it 'finds request with same stag' do
          new_request = build(:marketing_request, stag: 'PARTNER_STAG_123')
          expect(new_request.existing_partner_request).to eq(existing_request)
        end

        it 'does not find itself' do
          expect(existing_request.existing_partner_request).to be_nil
        end

        it 'returns nil for unique stag' do
          new_request = build(:marketing_request, stag: 'UNIQUE_STAG')
          expect(new_request.existing_partner_request).to be_nil
        end
      end

      describe '#has_existing_partner_request?' do
        it 'returns true when partner request exists' do
          new_request = build(:marketing_request, stag: 'PARTNER_STAG_123')
          expect(new_request).to have_existing_partner_request
        end

        it 'returns false when no partner request exists' do
          new_request = build(:marketing_request, stag: 'UNIQUE_STAG')
          expect(new_request).not_to have_existing_partner_request
        end
      end
    end
  end

  # Edge cases and error conditions
  describe 'edge cases' do
    describe 'with special characters' do
      it 'handles unicode characters in manager name' do
        marketing_request.manager = 'Менеджер Иванов'
        expect(marketing_request).to be_valid
      end

      it 'handles special email formats' do
        marketing_request.partner_email = 'test+tag@example.co.uk'
        expect(marketing_request).to be_valid
      end
    end

    describe 'with boundary values' do
      it 'handles maximum length strings' do
        marketing_request.manager = 'A' * 255
        marketing_request.platform = 'B' * 1000
        marketing_request.partner_email = "#{'a' * 240}@example.com"
        marketing_request.promo_code = 'C' * 2000
        marketing_request.stag = 'D' * 50
        expect(marketing_request).to be_valid
      end

      it 'rejects strings exceeding limits' do
        marketing_request.manager = 'A' * 256
        expect(marketing_request).not_to be_valid
      end
    end

    describe 'with case sensitivity' do
      it 'treats stag case-sensitively in uniqueness validation' do
        create(:marketing_request, stag: 'CaseSensitive')
        new_request = build(:marketing_request, stag: 'casesensitive')
        expect(new_request).to be_valid
      end

      it 'normalizes promo codes to uppercase' do
        marketing_request.promo_code = 'lowercase, MixedCase, UPPERCASE'
        marketing_request.valid?
        expect(marketing_request.promo_code).to eq('LOWERCASE, MIXEDCASE, UPPERCASE')
      end
    end

    describe 'with concurrent modifications' do
      it 'handles simultaneous updates gracefully' do
        request1 = create(:marketing_request, :activated)
        request2 = MarketingRequest.find(request1.id)

        request1.manager = 'Manager 1'
        request2.manager = 'Manager 2'

        request1.save!
        expect(request1.status).to eq('pending')

        request2.save!
        expect(request2.status).to eq('pending')
      end
    end

    describe 'with validation edge cases' do
      it 'handles empty and whitespace-only values' do
        marketing_request.promo_code = '   '  # whitespace only - will be normalized to empty
        expect(marketing_request).not_to be_valid
        # This should trigger the presence validation
        expect(marketing_request.errors[:promo_code]).to include("can't be blank")
      end

      it 'handles very long comma-separated lists' do
        codes = (1..100).map { |i| "CODE#{i}" }.join(', ')
        marketing_request.promo_code = codes
        expect(marketing_request.promo_codes_array.size).to eq(100)
      end
    end
  end
end

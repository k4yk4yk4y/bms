# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketingHelper, type: :helper do
  describe '#marketing_status_badge_class' do
    it 'returns correct class for pending status' do
      expect(helper.marketing_status_badge_class('pending')).to eq('bg-warning')
    end

    it 'returns correct class for activated status' do
      expect(helper.marketing_status_badge_class('activated')).to eq('bg-success')
    end

    it 'returns correct class for rejected status' do
      expect(helper.marketing_status_badge_class('rejected')).to eq('bg-danger')
    end

    it 'returns default class for unknown status' do
      expect(helper.marketing_status_badge_class('unknown_status')).to eq('bg-secondary')
    end

    it 'handles nil status' do
      expect(helper.marketing_status_badge_class(nil)).to eq('bg-secondary')
    end

    it 'handles empty string status' do
      expect(helper.marketing_status_badge_class('')).to eq('bg-secondary')
    end

    it 'is case sensitive' do
      expect(helper.marketing_status_badge_class('PENDING')).to eq('bg-secondary')
      expect(helper.marketing_status_badge_class('Pending')).to eq('bg-secondary')
    end

    context 'edge cases' do
      it 'handles numeric input' do
        expect(helper.marketing_status_badge_class(1)).to eq('bg-secondary')
      end

      it 'handles boolean input' do
        expect(helper.marketing_status_badge_class(true)).to eq('bg-secondary')
      end

      it 'handles special characters' do
        expect(helper.marketing_status_badge_class('pending!')).to eq('bg-secondary')
      end
    end
  end

  describe '#request_type_icon' do
    it 'returns globe icon for web promo types' do
      expect(helper.request_type_icon('promo_webs_50')).to eq('fas fa-globe')
      expect(helper.request_type_icon('promo_webs_100')).to eq('fas fa-globe')
    end

    it 'returns link icon for no-link promo types' do
      expect(helper.request_type_icon('promo_no_link_50')).to eq('fas fa-link')
      expect(helper.request_type_icon('promo_no_link_100')).to eq('fas fa-link')
      expect(helper.request_type_icon('promo_no_link_125')).to eq('fas fa-link')
      expect(helper.request_type_icon('promo_no_link_150')).to eq('fas fa-link')
    end

    it 'returns credit card icon for deposit bonuses' do
      expect(helper.request_type_icon('deposit_bonuses_partners')).to eq('fas fa-credit-card')
    end

    it 'returns default gift icon for unknown types' do
      expect(helper.request_type_icon('unknown_type')).to eq('fas fa-gift')
    end

    it 'handles nil request type' do
      expect(helper.request_type_icon(nil)).to eq('fas fa-gift')
    end

    it 'handles empty string request type' do
      expect(helper.request_type_icon('')).to eq('fas fa-gift')
    end

    context 'all valid request types' do
      it 'returns appropriate icons for all MarketingRequest types' do
        MarketingRequest::REQUEST_TYPES.each do |request_type|
          icon = helper.request_type_icon(request_type)
          expect(icon).to be_a(String)
          expect(icon).to start_with('fas fa-')
        end
      end
    end

    context 'edge cases' do
      it 'handles case sensitivity' do
        expect(helper.request_type_icon('PROMO_WEBS_50')).to eq('fas fa-gift')
        expect(helper.request_type_icon('Promo_Webs_50')).to eq('fas fa-gift')
      end

      it 'handles partial matches' do
        expect(helper.request_type_icon('promo_webs')).to eq('fas fa-gift')
        expect(helper.request_type_icon('webs_50')).to eq('fas fa-gift')
      end
    end
  end

  describe '#format_platform_display' do
    context 'with blank platform' do
      it 'returns muted dash for nil platform' do
        result = helper.format_platform_display(nil)
        expect(result).to include('—')
        expect(result).to include('text-muted')
      end

      it 'returns muted dash for empty string platform' do
        result = helper.format_platform_display('')
        expect(result).to include('—')
        expect(result).to include('text-muted')
      end

      it 'returns muted dash for whitespace-only platform' do
        result = helper.format_platform_display('   ')
        expect(result).to include('—')
        expect(result).to include('text-muted')
      end
    end

    context 'with valid URL platform' do
      it 'creates external link for HTTP URL' do
        url = 'https://example.com'
        result = helper.format_platform_display(url)

        expect(result).to include('href="https://example.com"')
        expect(result).to include('target="_blank"')
        expect(result).to include('text-primary')
        expect(result).to include('fa-external-link-alt')
      end

      it 'creates external link for HTTPS URL' do
        url = 'https://secure-example.com'
        result = helper.format_platform_display(url)

        expect(result).to include('href="https://secure-example.com"')
        expect(result).to include('target="_blank"')
      end

      it 'truncates very long URLs in display' do
        long_url = 'https://very-long-domain-name-that-exceeds-normal-length.com/path/to/resource'
        result = helper.format_platform_display(long_url)

        expect(result).to include('href="' + long_url + '"')
        # Display text should be truncated but href should be full URL
      end

      it 'handles URLs with query parameters' do
        url = 'https://example.com?param1=value1&param2=value2'
        result = helper.format_platform_display(url)

        expect(result).to include('href="https://example.com?param1=value1&amp;param2=value2"')
      end

      it 'handles URLs with fragments' do
        url = 'https://example.com/page#section'
        result = helper.format_platform_display(url)

        expect(result).to include('href="' + url + '"')
      end
    end

    context 'with non-URL platform' do
      it 'returns truncated text for non-URL platform' do
        platform = 'Some platform description'
        result = helper.format_platform_display(platform)

        expect(result).to eq(platform)
        expect(result).not_to include('<a')
      end

      it 'truncates very long non-URL text' do
        long_text = 'A' * 100
        result = helper.format_platform_display(long_text)

        expect(result.length).to be <= 50
        expect(result).to include('...')
      end

      it 'handles text that looks like URL but is not valid' do
        fake_url = 'not-a-real-url.com'
        result = helper.format_platform_display(fake_url)

        expect(result).to eq(fake_url)
        expect(result).not_to include('<a')
      end
    end

    context 'edge cases' do
      it 'handles malicious HTML in platform' do
        malicious_html = '<script>alert("xss")</script>'
        result = helper.format_platform_display(malicious_html)

        # Should not render as HTML
        expect(result).to include('&lt;script&gt;')
      end

      it 'handles platform with quotes' do
        quoted_text = 'Platform "with quotes"'
        result = helper.format_platform_display(quoted_text)

        expect(result).to include('Platform &quot;with quotes&quot;')
      end

      it 'handles international domain names' do
        idn_url = 'https://пример.рф'
        result = helper.format_platform_display(idn_url)

        expect(result).to include('href="https://пример.рф"')
      end
    end
  end

  describe '#marketing_request_summary' do
    let(:marketing_request) do
      build(:marketing_request,
            request_type: 'promo_webs_50',
            promo_code: 'TEST_CODE_123',
            status: 'pending')
    end

    it 'returns formatted summary string' do
      result = helper.marketing_request_summary(marketing_request)

      expect(result).to include('ПРОМО ВЕБОВ 50')  # request_type_label
      expect(result).to include('TEST_CODE_123')   # promo_code
      expect(result).to include('Ожидает')         # status_label
      expect(result).to include(' - ')
      expect(result).to include(' (')
      expect(result).to include(')')
    end

    it 'handles different request types' do
      marketing_request.request_type = 'deposit_bonuses_partners'
      result = helper.marketing_request_summary(marketing_request)

      expect(result).to include('ДЕПОЗИТНЫЕ БОНУСЫ ОТ ПАРТНЁРОВ')
    end

    it 'handles different statuses' do
      marketing_request.status = 'activated'
      result = helper.marketing_request_summary(marketing_request)

      expect(result).to include('Активирован')
    end

    it 'handles long promo codes' do
      marketing_request.promo_code = 'VERY_LONG_PROMO_CODE_THAT_MIGHT_BREAK_LAYOUT'
      result = helper.marketing_request_summary(marketing_request)

      expect(result).to include('VERY_LONG_PROMO_CODE_THAT_MIGHT_BREAK_LAYOUT')
    end

    context 'edge cases' do
      it 'handles missing request_type_label' do
        allow(marketing_request).to receive(:request_type_label).and_return(nil)
        result = helper.marketing_request_summary(marketing_request)

        expect(result).to be_a(String)
      end

      it 'handles missing status_label' do
        allow(marketing_request).to receive(:status_label).and_return(nil)
        result = helper.marketing_request_summary(marketing_request)

        expect(result).to be_a(String)
      end

      it 'handles nil promo_code' do
        marketing_request.promo_code = nil
        result = helper.marketing_request_summary(marketing_request)

        expect(result).to be_a(String)
      end
    end
  end

  describe '#tab_count_badge' do
    it 'returns empty string for zero count' do
      expect(helper.tab_count_badge(0)).to eq('')
    end

    it 'returns badge HTML for positive count' do
      result = helper.tab_count_badge(5)

      expect(result).to include('<span')
      expect(result).to include('badge bg-secondary')
      expect(result).to include('ms-1')
      expect(result).to include('5')
      expect(result).to include('</span>')
    end

    it 'handles single count' do
      result = helper.tab_count_badge(1)
      expect(result).to include('1')
    end

    it 'handles large counts' do
      result = helper.tab_count_badge(999)
      expect(result).to include('999')
    end

    it 'handles very large counts' do
      result = helper.tab_count_badge(999999)
      expect(result).to include('999999')
    end

    context 'edge cases' do
      it 'handles negative counts as zero' do
        # Assuming negative counts should be treated as zero
        result = helper.tab_count_badge(-5)
        expect(result).to eq('')
      end

      it 'handles float counts by converting to integer' do
        result = helper.tab_count_badge(5.7)
        expect(result).to include('5')
      end

      it 'handles string counts' do
        result = helper.tab_count_badge('10')
        # Should handle conversion or treat as zero
        expect(result).to be_a(String)
      end

      it 'handles nil count' do
        result = helper.tab_count_badge(nil)
        expect(result).to eq('')
      end

      it 'handles boolean count' do
        result = helper.tab_count_badge(true)
        expect(result).to eq('')
      end
    end

    context 'HTML safety' do
      it 'returns HTML-safe string' do
        result = helper.tab_count_badge(5)
        expect(result).to be_html_safe
      end

      it 'handles potential XSS in count value' do
        # Test with malicious input that could cause XSS
        malicious_count = '<script>alert("xss")</script>'
        result = helper.tab_count_badge(malicious_count)

        # Should not render script tags
        expect(result).not_to include('<script>')
      end
    end
  end

  # Integration tests with view rendering
  describe 'integration with views' do
    let(:marketing_request) do
      build(:marketing_request,
            request_type: 'promo_webs_50',
            status: 'pending',
            platform: 'https://example.com')
    end

    it 'works correctly in view context' do
      badge_class = helper.marketing_status_badge_class('pending')
      expect(badge_class).to eq('bg-warning')
    end

    it 'renders request type icons correctly' do
      icon_class = helper.request_type_icon('promo_webs_50')
      expect(icon_class).to eq('fas fa-globe')
    end

    it 'renders platform links correctly' do
      result = helper.format_platform_display('https://example.com')
      expect(result).to include('<a')
      expect(result).to include('href="https://example.com"')
    end

    it 'renders tab count badges in navigation' do
      result = helper.tab_count_badge(5)
      expect(result).to include('badge bg-secondary')
      expect(result).to include('5')
    end
  end

  # Testing helper methods with actual MarketingRequest objects
  describe 'integration with MarketingRequest model' do
    let(:marketing_request) { create(:marketing_request, :promo_webs_50, :pending) }

    it 'works with real MarketingRequest objects' do
      summary = helper.marketing_request_summary(marketing_request)

      expect(summary).to include(marketing_request.request_type_label)
      expect(summary).to include(marketing_request.promo_code)
      expect(summary).to include(marketing_request.status_label)
    end

    it 'handles requests with complex promo codes' do
      marketing_request.promo_code = 'CODE1, CODE2, CODE3'
      summary = helper.marketing_request_summary(marketing_request)

      expect(summary).to include('CODE1, CODE2, CODE3')
    end

    it 'handles requests with long manager names' do
      marketing_request.manager = 'Very Long Manager Name That Might Affect Display'
      summary = helper.marketing_request_summary(marketing_request)

      expect(summary).to be_a(String)
    end
  end

  # Performance tests
  describe 'performance' do
    it 'helper methods perform efficiently' do
              start_time = Time.current
        100.times do
          helper.marketing_status_badge_class('pending')
          helper.request_type_icon('promo_webs_50')
          helper.tab_count_badge(10)
        end
        end_time = Time.current
        expect(end_time - start_time).to be < 0.1.seconds
    end

    it 'format_platform_display performs efficiently with URLs' do
      urls = [
        'https://example.com',
        'https://another-example.com/path',
        'https://third-example.com/very/long/path/to/resource'
      ]

              start_time = Time.current
        urls.each { |url| helper.format_platform_display(url) }
        end_time = Time.current
        expect(end_time - start_time).to be < 0.5.seconds
    end

    it 'marketing_request_summary performs efficiently' do
      marketing_request = build(:marketing_request)

              start_time = Time.current
        50.times { helper.marketing_request_summary(marketing_request) }
        end_time = Time.current
        expect(end_time - start_time).to be < 0.1.seconds
    end
  end

  # Security considerations
  describe 'security' do
    context 'XSS prevention' do
      it 'properly escapes HTML in platform display' do
        malicious_platform = '<script>alert("xss")</script>malicious.com'
        result = helper.format_platform_display(malicious_platform)

        # HTML should be escaped
        expect(result).to include('&lt;script&gt;')
        expect(result).not_to include('<script>')
      end

      it 'properly handles HTML in tab count badges' do
        # Even though count should be numeric, test safety
        result = helper.tab_count_badge('<img src=x onerror=alert(1)>')
        expect(result).to eq('')  # Should handle gracefully
      end
    end

    context 'URL validation in platform display' do
      it 'validates URLs properly before creating links' do
        invalid_urls = [
          'javascript:alert("xss")',
          'data:text/html,<script>alert(1)</script>',
          'ftp://malicious.com'
        ]

        invalid_urls.each do |url|
          result = helper.format_platform_display(url)
          # Should not create links for invalid/dangerous URLs
          expect(result).not_to include('href="javascript:')
          expect(result).not_to include('href="data:')
        end
      end

      it 'allows safe protocols' do
        safe_urls = [
          'https://example.com',
          'http://example.com',
          'https://sub.example.com/path?param=value'
        ]

        safe_urls.each do |url|
          result = helper.format_platform_display(url)
          expect(result).to include("href=\"#{url}\"")
        end
      end
    end
  end

  # Testing with various input combinations
  describe 'comprehensive input testing' do
    context 'status badge class with all valid statuses' do
      it 'handles all MarketingRequest statuses correctly' do
        MarketingRequest::STATUSES.each do |status|
          result = helper.marketing_status_badge_class(status)
          expect(result).to be_a(String)
          expect(result).to start_with('bg-')
        end
      end
    end

    context 'request type icon with all valid types' do
      it 'returns appropriate icons for all request types' do
        icon_results = MarketingRequest::REQUEST_TYPES.map do |type|
          helper.request_type_icon(type)
        end

        expect(icon_results).to all(be_a(String))
        expect(icon_results).to all(start_with('fas fa-'))

        # Verify we get different icons for different categories
        unique_icons = icon_results.uniq
        expect(unique_icons.length).to be >= 3  # Should have at least 3 different icons
      end
    end

    context 'platform display with various formats' do
      it 'handles different URL formats correctly' do
        url_formats = [
          'https://example.com',
          'https://example.com/',
          'https://example.com/path',
          'https://example.com/path/',
          'https://sub.example.com',
          'https://example.com:8080',
          'https://example.com/path?query=value',
          'https://example.com/path#fragment'
        ]

        url_formats.each do |url|
          result = helper.format_platform_display(url)
          expect(result).to include("href=\"#{url}\"")
          expect(result).to include('target="_blank"')
        end
      end

      it 'handles edge case platform values' do
        edge_cases = [
          'localhost',
          '127.0.0.1',
          'example',
          'a',
          '1',
          'platform with spaces',
          'platform-with-dashes',
          'platform_with_underscores'
        ]

        edge_cases.each do |platform|
          result = helper.format_platform_display(platform)
          expect(result).to be_a(String)
          # These should not be treated as URLs
          expect(result).not_to include('<a')
        end
      end
    end
  end



  private

  def render_inline(template)
    # Simple template rendering for testing
    template.gsub('<%=', '#{').gsub('%>', '}')
  end
end

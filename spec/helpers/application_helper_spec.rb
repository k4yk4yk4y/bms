# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  # Since ApplicationHelper appears to be empty or contains only basic Rails helper methods,
  # we'll test the default Rails helper functionality and ensure it works correctly

  describe 'Rails helper integration' do
    it 'provides access to standard Rails helpers' do
      # Test that basic Rails helpers are available
      expect(helper).to respond_to(:link_to)
      expect(helper).to respond_to(:content_tag)
      expect(helper).to respond_to(:truncate)
      expect(helper).to respond_to(:number_to_currency)
    end

    it 'link_to helper works correctly' do
      result = helper.link_to('Test Link', '/test/path')
      expect(result).to include('<a href="/test/path">Test Link</a>')
    end

    it 'content_tag helper works correctly' do
      result = helper.content_tag(:div, 'Test Content', class: 'test-class')
      expect(result).to include('<div class="test-class">Test Content</div>')
    end

    it 'truncate helper works correctly' do
      long_text = 'This is a very long text that should be truncated'
      result = helper.truncate(long_text, length: 20)
      expect(result.length).to be <= 23  # 20 + "..."
      expect(result).to include('...')
    end

    it 'number_to_currency helper works correctly' do
      result = helper.number_to_currency(100.50)
      expect(result).to include('100.50')
      expect(result).to include('$')
    end
  end

  describe 'custom helper methods' do
    # If ApplicationHelper has custom methods, test them here
    # Currently it appears to be the default empty helper

    it 'can be extended with custom methods' do
      # Test that we can add methods to ApplicationHelper if needed
      expect(ApplicationHelper).to be_a(Module)
    end

    it 'is included in view context' do
      # Verify that ApplicationHelper methods are available in views
      expect(helper.class.ancestors).to include(ApplicationHelper)
    end
  end

  describe 'error handling' do
    it 'handles nil values gracefully in standard helpers' do
      expect { helper.truncate(nil) }.not_to raise_error
      expect(helper.truncate(nil)).to be_nil
    end

    it 'handles invalid HTML attributes' do
      result = helper.content_tag(:div, 'content', class: nil)
      expect(result).to include('<div>content</div>')
    end
  end

  describe 'HTML safety' do
    it 'properly escapes HTML content' do
      malicious_content = '<script>alert("xss")</script>'
      result = helper.content_tag(:div, malicious_content)
      expect(result).to include('&lt;script&gt;')
      expect(result).not_to include('<script>')
    end

    it 'preserves HTML safety for safe content' do
      safe_content = '<strong>Bold Text</strong>'.html_safe
      result = helper.content_tag(:div, safe_content)
      expect(result).to include('<strong>Bold Text</strong>')
    end
  end

  describe 'performance' do
    it 'standard helpers perform efficiently' do
              start_time = Time.current
        100.times do
          helper.link_to('Test', '/path')
          helper.content_tag(:span, 'content')
          helper.truncate('long text', length: 10)
        end
        end_time = Time.current
        expect(end_time - start_time).to be < 1.second
    end
  end
end

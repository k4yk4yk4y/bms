module MarketingHelper
  def marketing_status_badge_class(status)
    case status
    when 'pending'
      'bg-warning'
    when 'activated'
      'bg-success'
    when 'rejected'
      'bg-danger'
    else
      'bg-secondary'
    end
  end

  def request_type_icon(request_type)
    case request_type
    when 'promo_webs_50', 'promo_webs_100'
      'fas fa-globe'
    when 'promo_no_link_50', 'promo_no_link_100', 'promo_no_link_125', 'promo_no_link_150'
      'fas fa-link'
    when 'deposit_bonuses_partners'
      'fas fa-credit-card'
    else
      'fas fa-gift'
    end
  end

  def format_platform_display(platform)
    return content_tag(:span, '—', class: 'text-muted') if platform.blank?
    
    if platform.match?(URI::DEFAULT_PARSER.make_regexp)
      link_to platform, platform, target: '_blank', class: 'text-primary text-decoration-none' do
        "#{truncate(platform, length: 30)} #{content_tag(:i, '', class: 'fas fa-external-link-alt ms-1')}".html_safe
      end
    else
      truncate(platform, length: 50)
    end
  end

  def marketing_request_summary(request)
    "#{request.request_type_label} - #{request.promo_code} (#{request.status_label})"
  end

  def tab_count_badge(count)
    return '' if count.zero?
    
    content_tag(:span, count, class: 'badge bg-secondary ms-1')
  end
end

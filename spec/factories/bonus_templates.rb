FactoryBot.define do
  factory :bonus_template do
    sequence(:name) { |n| "Template #{n}" }
    sequence(:dsl_tag) { |n| "dsl_tag_#{n}" }
    project { "VOLNA" }
    event { "deposit" }

    wager { 35.0 }
    maximum_winnings { 500.0 }
    no_more { 1 }
    totally_no_more { 5 }
    currencies { [ "USD", "EUR" ] }
    groups { [ "VIP", "Premium" ] }
    currency_minimum_deposits { { "USD" => 10.0, "EUR" => 8.0 } }
    description { "Test bonus template" }

    trait :welcome_bonus do
      name { "Welcome Bonus Template" }
      dsl_tag { "welcome_bonus" }
      project { "VOLNA" }
      event { "deposit" }

      wager { 40.0 }
      maximum_winnings { 1000.0 }
    end

    trait :reload_bonus do
      name { "Reload Bonus Template" }
      dsl_tag { "reload_cash" }
      project { "ROX" }
      event { "deposit" }

      wager { 30.0 }
      maximum_winnings { 300.0 }
    end

    trait :freespin_bonus do
      name { "Freespin Bonus Template" }
      dsl_tag { "reload_freespins" }
      project { "FRESH" }
      event { "deposit" }

      wager { 25.0 }
      maximum_winnings { 200.0 }
    end

    trait :for_all_projects do
      name { "Universal Template" }
      dsl_tag { "universal" }
      project { "All" }
      event { "deposit" }

      wager { 35.0 }
      maximum_winnings { 500.0 }
    end

    trait :manual_event do
      event { "manual" }
      currency_minimum_deposits { {} }
    end

    trait :input_coupon_event do
      event { "input_coupon" }
      currency_minimum_deposits { {} }
    end
  end
end

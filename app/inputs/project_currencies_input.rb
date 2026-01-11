module Formtastic
  module Inputs
    class ProjectCurrenciesInput
      include Base

      def to_html
        input_wrapping do
          label_html <<
            hidden_field_html <<
            currencies_inputs_html
        end
      end

      private

      def hidden_field_html
        builder.hidden_field(method, id: "project_currencies", value: hidden_value)
      end

      def hidden_value
        values = object.respond_to?(method) ? object.public_send(method) : nil
        Array(values).map { |code| code.to_s }.reject(&:blank?).join(";")
      end

      def currencies_inputs_html
        template.content_tag(:div, class: "project-currencies-inputs") do
          template.safe_join([ entry_input_html, tags_container_html ])
        end
      end

      def entry_input_html
        template.tag(:input,
          type: "text",
          id: "project_currencies_entry",
          class: "project-currencies-entry",
          placeholder: "USD;EUR",
          autocomplete: "off"
        )
      end

      def tags_container_html
        template.content_tag(:div, "",
          class: "project-currencies-tags",
          id: "project_currencies_tags"
        )
      end

      def label_html_options
        {
          for: "project_currencies_entry",
          class: ["label"]
        }
      end

      def wrapper_html_options
        options = super
        options[:class] = [options[:class], "project-currencies-field"].compact.join(" ")
        options
      end
    end
  end
end

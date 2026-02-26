# app/controllers/bonus_templates_controller.rb
class BonusTemplatesController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_bonus_templates_access!

  def find
    dsl_tag_name = params[:dsl_tag_name]
    name = params[:name]
    project_name = params[:project_name]

    template = BonusTemplate.find_template_by_dsl_and_name(dsl_tag_name, name, project_name)

    if template
      render json: template.as_json(only: [ :minimum_deposit, :wager, :deposit_percentage ])
    else
      render json: { error: "Template not found" }, status: :not_found
    end
  end

  private

  def authorize_bonus_templates_access!
    authorize! :read, BonusTemplate
  end
end

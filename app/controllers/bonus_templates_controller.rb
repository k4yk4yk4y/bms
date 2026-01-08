# app/controllers/bonus_templates_controller.rb
class BonusTemplatesController < ApplicationController
  before_action :authenticate_user!

  def find
    dsl_tag_name = params[:dsl_tag_name]
    name = params[:name]
    project_name = params[:project_name]

    # Find dsl_tag by name
    dsl_tag = DslTag.find_by(name: dsl_tag_name)

    # Find project by name
    project = Project.find_by(name: project_name)

    # Find template based on provided parameters
    template = BonusTemplate.find_by(
      name: name,
      dsl_tag_id: dsl_tag&.id, # Use dsl_tag_id if dsl_tag is found
      project_id: project&.id # Use project_id if project is found
    )

    if template
      render json: template.as_json(only: [ :minimum_deposit, :wager ]) # Return relevant fields
    else
      render json: { error: "Template not found" }, status: :not_found
    end
  end
end

module PlanExportsControllerExtension
  extend ActiveSupport::Concern

  def file_name
    p = "plan_#{@plan.id}"
    p += "_phase_#{@selected_phases.first.id}" if @selected_phases.length == 1
    p += "_#{@plan.updated_at.utc.strftime('%Y%m%dT%H%M%SZ')}"
    p
  end

  def show
    # COPY FROM ORIGINAL PlanExportsController#show
    @plan = Plan.includes(:answers, { template: { phases: { sections: :questions } } })
                .find(params[:plan_id])

    # preliminary fix for https://github.com/DMPRoadmap/roadmap/issues/3345
    if privately_authorized?
      skip_authorization

      if export_params[:form].present?

        @show_coversheet         = export_params[:project_details].present?
        @show_sections_questions = export_params[:question_headings].present?
        @show_unanswered         = export_params[:unanswered_questions].present?
        @show_custom_sections    = export_params[:custom_sections].present?
        @show_research_outputs   = export_params[:research_outputs].present?
        @public_plan             = false

      else

        @show_coversheet         = true
        @show_sections_questions = true
        @show_unanswered         = true
        @show_custom_sections    = true
        @show_research_outputs   = @plan.research_outputs&.any? || false
        @public_plan             = false

      end

    elsif publicly_authorized?
      skip_authorization

      @show_coversheet         = true
      @show_sections_questions = true
      @show_unanswered         = true
      @show_custom_sections    = true
      @show_research_outputs   = @plan.research_outputs&.any? || false
      @public_plan             = true

    else

      raise Pundit::NotAuthorizedError

    end

    @formatting      = export_params[:formatting] || @plan.settings(:export).formatting
    @selected_phases = if params.key?(:phase_id)
                         @plan.phases.where(id: params[:phase_id]).all
                       else
                         @plan.phases.sort { |a, b| b.updated_at <=> a.updated_at }
                       end

    respond_to do |format|
      format.html do
        @hash = @plan.as_pdf(current_user, @show_coversheet)
        show_html
      end
      format.csv  { show_csv }
      format.text do
        @hash = @plan.as_pdf(current_user, @show_coversheet)
        show_text
      end
      format.docx do
        @hash = @plan.as_pdf(current_user, @show_coversheet)
        show_docx
      end
      format.pdf do
        @hash = @plan.as_pdf(current_user, @show_coversheet)
        show_pdf
      end
      format.json { show_json }
    end
  end

  def show_csv
    send_data @plan.as_csv(current_user, @show_sections_questions,
                           @show_unanswered,
                           @selected_phases,
                           @show_custom_sections,
                           @show_coversheet,
                           @show_research_outputs),
              filename: "#{file_name}.csv"
  end
end

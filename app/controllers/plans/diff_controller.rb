# frozen_string_literal: true

# Controller for the Write plan and create plan pages
module Plans
  class DiffController < ApplicationController
    include ConditionalUserMailer
    include OrgSelectable

    helper PaginableHelper
    helper SettingsTemplateHelper

    after_action :verify_authorized, except: [:overview]
    before_action :set_plans
    before_action :set_navigation_buttons

    # GET /plans
    def show
      # Base plan

      authorize @base_plan

      @base_plan_partial = if @base_plan.editable_by?(current_user.id) && @base_plan.is_plan_live_version?
                             'edit_details'
                           else
                             'show_details'
                           end
      @base_plan_visibility = if @base_plan.visibility.present?
                                @base_plan.visibility.to_s
                              else
                                Rails.configuration.x.plans.default_visibility
                              end
      # Get all of the available funders
      @base_plan_funders = Org.funder
                              .joins(:templates)
                              .where(templates: { published: true }).uniq.sort_by(&:name)
      # TODO: Seems strange to do this. Why are we just not using an `edit` route?
      @base_plan_editing = !params[:editing].nil? && @base_plan.administerable_by?(current_user.id)

      # Get all Guidance Groups applicable for the plan and group them by org
      @base_plan_all_guidance_groups = @base_plan.guidance_group_options
      @base_plan_all_ggs_grouped_by_org = @base_plan_all_guidance_groups.sort.group_by(&:org)
      @base_plan_selected_guidance_groups = @base_plan.guidance_groups

      # Important ones come first on the page - we grab the user's org's GGs and
      # "Organisation" org type GGs
      @base_plan_important_ggs = []

      if @base_plan_all_ggs_grouped_by_org.include?(current_user.org)
        @base_plan_important_ggs << [current_user.org, @base_plan_all_ggs_grouped_by_org[current_user.org]]
      end
      @base_plan_default_orgs = Org.default_orgs
      @base_plan_all_ggs_grouped_by_org.each do |org, ggs|
        # @default_orgs and already selected guidance groups are important.
        if (@base_plan_default_orgs.include?(org) || ggs.intersect?(@base_plan_selected_guidance_groups)) && !@base_plan_important_ggs.include?([org,
                                                                                                                                                 ggs])
          @base_plan_important_ggs << [org, ggs]
        end
      end

      # Sort the rest by org name for the accordion
      @base_plan_important_ggs = @base_plan_important_ggs.sort_by { |org, _gg| (org.nil? ? '' : org.name) }
      @base_plan_all_ggs_grouped_by_org = @base_plan_all_ggs_grouped_by_org.sort_by do |org, _gg|
        (org.nil? ? '' : org.name)
      end
      @base_plan_selected_guidance_groups = @base_plan_selected_guidance_groups.ids

      @base_plan_based_on = if @base_plan.template.customization_of.nil?
                              @base_plan.template
                            else
                              Template.where(family_id: @base_plan.template.customization_of).first
                            end

      @base_plan_research_domains = ResearchDomain.all.order(:label)
      # Secondary plan
      authorize @secondary_plan

      @secondary_plan_partial = if @secondary_plan.editable_by?(current_user.id) && @secondary_plan.is_plan_live_version?
                                  'edit_details'
                                else
                                  'show_details'
                                end
      @secondary_plan_visibility = if @secondary_plan.visibility.present?
                                     @secondary_plan.visibility.to_s
                                   else
                                     Rails.configuration.x.plans.default_visibility
                                   end
      # Get all of the available funders
      @secondary_plan_funders = Org.funder
                                   .joins(:templates)
                                   .where(templates: { published: true }).uniq.sort_by(&:name)
      # TODO: Seems strange to do this. Why are we just not using an `edit` route?
      @secondary_plan_editing = !params[:editing].nil? && @secondary_plan.administerable_by?(current_user.id)

      # Get all Guidance Groups applicable for the plan and group them by org
      @secondary_plan_all_guidance_groups = @secondary_plan.guidance_group_options
      @secondary_plan_all_ggs_grouped_by_org = @secondary_plan_all_guidance_groups.sort.group_by(&:org)
      @secondary_plan_selected_guidance_groups = @secondary_plan.guidance_groups

      # Important ones come first on the page - we grab the user's org's GGs and
      # "Organisation" org type GGs
      @secondary_plan_important_ggs = []

      if @secondary_plan_all_ggs_grouped_by_org.include?(current_user.org)
        @secondary_plan_important_ggs << [current_user.org, @secondary_plan_all_ggs_grouped_by_org[current_user.org]]
      end
      @secondary_plan_default_orgs = Org.default_orgs
      @secondary_plan_all_ggs_grouped_by_org.each do |org, ggs|
        # @default_orgs and already selected guidance groups are important.
        if (@secondary_plan_default_orgs.include?(org) || ggs.intersect?(@secondary_plan_selected_guidance_groups)) && !@secondary_plan_important_ggs.include?([org,
                                                                                                                                                                ggs])
          @secondary_plan_important_ggs << [org, ggs]
        end
      end

      # Sort the rest by org name for the accordion
      @secondary_plan_important_ggs = @secondary_plan_important_ggs.sort_by { |org, _gg| (org.nil? ? '' : org.name) }
      @secondary_plan_all_ggs_grouped_by_org = @secondary_plan_all_ggs_grouped_by_org.sort_by do |org, _gg|
        (org.nil? ? '' : org.name)
      end
      @secondary_plan_selected_guidance_groups = @secondary_plan_selected_guidance_groups.ids

      @secondary_plan_based_on = if @secondary_plan.template.customization_of.nil?
                                   @secondary_plan.template
                                 else
                                   Template.where(family_id: @secondary_plan.template.customization_of).first
                                 end

      @secondary_plan_research_domains = ResearchDomain.all.order(:label)
      respond_to :html
    end

    def overview
      authorize @base_plan

      render(:overview, locals: { plan: @base_plan })
    rescue ActiveRecord::RecordNotFound
      flash[:alert] = format(_('There is no plan associated with id %{<id}>s'), id: params[:id])
      redirect_to(action: :index)
    end

    def edit
      # Base plan
      @base_plan = Plan.includes(
        { template: {
          phases: {
            sections: {
              questions: %i[question_format annotations]
            }
          }
        } },
        { answers: :notes }
      )
                       .find(params[:base_plan])
      authorize @base_plan
      base_plan_phase_id = params[:phase_id].to_i
      base_plan_phase = @base_plan.template.phases.find { |p| p.id == base_plan_phase_id }
      raise ActiveRecord::RecordNotFound if base_plan_phase.nil?

      base_plan_guidance_groups = GuidanceGroup.where(published: true, id: @base_plan.guidance_group_ids)

      # Secondary plan
      @secondary_plan = Plan.includes(
        { template: {
          phases: {
            sections: {
              questions: %i[question_format annotations]
            }
          }
        } },
        { answers: :notes }
      )
                            .find(params[:head_plan])
      authorize @secondary_plan
      secondary_plan_phase_id = params[:phase_id].to_i
      secondary_plan_phase = @secondary_plan.template.phases.find { |p| p.id == secondary_plan_phase_id }
      raise ActiveRecord::RecordNotFound if secondary_plan_phase.nil?

      secondary_plan_guidance_groups = GuidanceGroup.where(published: true, id: @secondary_plan.guidance_group_ids)

      render_phases_edit(@base_plan, base_plan_phase, base_plan_guidance_groups, @secondary_plan, secondary_plan_phase,
                         secondary_plan_guidance_groups)
    end

    private

    def set_plans
      @secondary_plan = Plan.includes(
        :guidance_groups, template: [:phases]
      ).find(params[:head_plan])
      @base_plan = Plan.includes(
        :guidance_groups, template: [:phases]
      ).find(params[:base_plan])
    end

    def set_navigation_buttons
      @navigation_button_show = diff_show_plan_path(head_plan: @secondary_plan, base_plan: @base_plan)
      @navigation_button_overview = diff_overview_plan_path(head_plan: @secondary_plan, base_plan: @base_plan)
    end

    def render_phases_edit(base_plan, base_plan_phase, base_plan_guidance_groups, secondary_plan, secondary_plan_phase,
                           secondary_plan_guidance_groups)
      base_plan_readonly = !base_plan.editable_by?(current_user.id) || !base_plan.is_plan_live_version?
      secondary_plan_readonly = !secondary_plan.editable_by?(current_user.id) || !secondary_plan.is_plan_live_version?
      # Since the answers have been pre-fetched through plan (see Plan.load_for_phase)
      # we create a hash whose keys are question id and value is the answer associated
      base_plan_answers = base_plan.answers.each_with_object({}) { |a, m| m[a.question_id] = a }
      secondary_plan_answers = secondary_plan.answers.each_with_object({}) { |a, m| m[a.question_id] = a }

      render('plans/diff/phases/edit', locals: {
               base_plan_base_template_org: base_plan_phase.template.base_org,
               base_plan: base_plan,
               base_plan_phase: base_plan_phase,
               base_plan_readonly: base_plan_readonly,
               base_plan_guidance_groups: base_plan_guidance_groups,
               base_plan_answers: base_plan_answers,
               base_plan_guidance_presenter: GuidancePresenter.new(base_plan),
               secondary_plan_base_template_org: secondary_plan_phase.template.base_org,
               secondary_plan: secondary_plan,
               secondary_plan_phase: secondary_plan_phase,
               secondary_plan_readonly: secondary_plan_readonly,
               secondary_plan_guidance_groups: secondary_plan_guidance_groups,
               secondary_plan_answers: secondary_plan_answers,
               secondary_plan_guidance_presenter: GuidancePresenter.new(secondary_plan)

             })
    end
  end
end

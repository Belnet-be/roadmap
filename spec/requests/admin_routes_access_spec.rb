# frozen_string_literal: true

require 'rails_helper'

# Every admin route refuses people who may not use it, before it changes anything. The spec
# calls each route under /super_admin, /org_admin and /org/admin, and the admin lists under
# /paginable, with real records of institute A: as nobody, as a user of institute A without admin
# rights, as an admin of institute B, and (for the super admin routes) as an admin of institute A.
# A route passes when it shows no page (no 2xx answer) and no database table changes.
RSpec.describe 'Admin routes: access without the right', type: :request do
  let!(:org_a) { create(:org, managed: true, name: 'Institute A') }
  let!(:org_b) { create(:org, managed: true, name: 'Institute B') }

  # Belnet sets a new user's org from the email domain and falls back to Org.guest
  before do
    create(:org, abbreviation: 'guests') unless Org.guest.present?
    Ugent::OrgDomain.create!(name: 'institute-a.example', org: org_a)
    Ugent::OrgDomain.create!(name: 'institute-b.example', org: org_b)
  end

  let!(:member) { create(:user, email: 'member@institute-a.example') }
  let!(:colleague) { create(:user, email: 'colleague@institute-a.example') }
  let!(:admin_a) { create(:user, :org_admin, email: 'admin@institute-a.example') }
  let!(:admin_b) { create(:user, :org_admin, email: 'admin@institute-b.example') }
  let!(:super_admin) { create(:user, :super_admin, email: 'super@institute-a.example') }

  let!(:template) { create(:template, org: org_a) }
  let!(:phase) { create(:phase, template: template) }
  let!(:section) { create(:section, phase: phase) }
  let!(:question) { create(:question, section: section) }
  let!(:question_option) { create(:question_option, question: question) }
  let!(:condition) { create(:condition, question: question) }
  let!(:guidance_group) { create(:guidance_group, org: org_a) }
  let!(:guidance) { create(:guidance, guidance_group: guidance_group) }
  let!(:department) { create(:department, org: org_a) }
  let!(:plan) { create(:plan, org: org_a, template: template).tap { |p| p.add_user!(colleague.id, :creator) } }
  let!(:api_client) { create(:api_client, org: org_a) }
  let!(:notification) { create(:notification) }
  let!(:theme) { create(:theme) }

  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
  def admin_lists
    %w[paginable/orgs#index paginable/themes#index paginable/notifications#index paginable/api_clients#index
       paginable/users#index paginable/plans#org_admin paginable/plans#index paginable/templates#index
       paginable/templates#customisable paginable/templates#organisational paginable/templates#history
       paginable/guidances#index paginable/guidance_groups#index paginable/departments#index]
  end

  def super_admin_lists
    %w[paginable/orgs paginable/themes paginable/notifications paginable/api_clients]
  end

  # Actions that always work on the user's own organisation, whatever id the path holds. An admin
  # of institute B may use them; the tests at the bottom check that they never reach institute A.
  def own_org_actions
    %w[guidances#admin_index guidances#admin_new guidance_groups#admin_new guidance_groups#admin_create
       org_admin/departments#new org_admin/departments#create]
  end

  def admin_routes
    Rails.application.routes.routes.filter_map do |route|
      controller = route.defaults[:controller].to_s
      action = route.defaults[:action].to_s
      path = route.path.spec.to_s.sub('(.:format)', '')
      next if controller.empty? || route.verb.blank?
      next unless path.start_with?('/super_admin/', '/org_admin/', '/org/admin/') ||
                  controller == 'super_admin/org_swaps' || admin_lists.include?("#{controller}##{action}")

      { verb: route.verb, path: path, controller: controller, action: action }
    end.uniq
  end

  def super_admin_route?(route)
    route[:path].start_with?('/super_admin/') || route[:controller].start_with?('super_admin/') ||
      super_admin_lists.include?(route[:controller])
  end

  # A route that names a record (not only a page number)
  def names_a_record?(route)
    route[:path].scan(/:(\w+)/).flatten.any? { |param| param != 'page' }
  end

  # The record of institute A that an :id in the route stands for, from the path segment before it
  def record_for(route)
    segment = route[:path][%r{/([a-z_]+)/:id}, 1]
    case segment
    when 'orgs', 'admin' then org_a
    when 'users' then colleague
    when 'themes' then theme
    when 'notifications' then notification
    when 'api_clients' then api_client
    when 'question_options' then question_option
    when 'conditions' then condition
    when 'plans' then plan
    when 'templates' then template
    when 'phases' then phase
    when 'sections' then section
    when 'questions' then question
    when 'departments' then department
    when 'guidance' then %w[admin_index admin_new admin_create].include?(route[:action]) ? org_a : guidance
    when 'guidancegroup' then %w[admin_new admin_create].include?(route[:action]) ? org_a : guidance_group
    end
  end

  def path_for(route)
    values = { 'template_id' => template.id, 'phase_id' => phase.id, 'section_id' => section.id,
               'question_id' => question.id, 'org_id' => org_a.id, 'user_id' => colleague.id,
               'plan_id' => plan.id, 'page' => 1, 'id' => record_for(route)&.id }
    route[:path].gsub(/:(\w+)/) { values.fetch(Regexp.last_match(1)) || raise("No record for #{route[:path]}") }
  end

  # Plausible form data, so that an action that skips its check would really change something
  def params_for(route)
    return {} if route[:verb] == 'GET'

    changes = { name: 'Changed by the test', title: 'Changed by the test', description: 'Changed',
                text: 'Changed', abbreviation: 'CHG', email: 'changed@institute-b.example' }
    key = route[:controller].split('/').last.singularize
    { key => changes, merge_id: member.id, perm_ids: Perm.pluck(:id) }
  end

  def tables
    @tables ||= ActiveRecord::Base.connection.tables - %w[schema_migrations ar_internal_metadata]
  end

  # One checksum per table over all rows and columns, so any write shows up, plus the mails sent
  # or queued (sending credentials changes no table)
  def fingerprint
    @fingerprint_sql ||= tables.map do |table|
      columns = ActiveRecord::Base.connection.columns(table).map { |column| "`#{column.name}`" }.join(', ')
      "SELECT '#{table}', COUNT(*), COALESCE(BIT_XOR(CRC32(CONCAT_WS('|', #{columns}))), 0) FROM `#{table}`"
    end.join(' UNION ALL ')
    sums = ActiveRecord::Base.connection.select_rows(@fingerprint_sql).to_h { |table, *values| [table, values] }
    queued = ActiveJob::Base.queue_adapter.try(:enqueued_jobs)&.size
    sums.merge('mails' => [ActionMailer::Base.deliveries.size, queued])
  end

  # Calls each route as the given user (nil: nobody signed in) and returns what happened
  def sweep(user, routes)
    if user
      sign_in user
      get '/plans' # the sign-in itself updates the account; do that before measuring
    end

    routes.map do |route|
      path = path_for(route)
      before = fingerprint
      status = begin
        send(route[:verb].downcase, path, params: params_for(route))
        response.status
      rescue StandardError => e
        e.class.name
      end
      changed = fingerprint.reject { |table, sums| before[table] == sums }.keys
      route.merge(status: status, changed: changed,
                  refused: (status.is_a?(String) || !(200..299).cover?(status)) && changed.empty?)
    end
  end

  def violations(results)
    results.reject { |result| result[:refused] }.map do |result|
      "#{result[:verb]} #{result[:path]} (#{result[:controller]}##{result[:action]}): " \
        "#{result[:status]}#{" – changed #{result[:changed].join(', ')}" if result[:changed].any?}"
    end
  end

  # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity

  it 'covers the admin routes' do
    expect(admin_routes.size).to be >= 134
  end

  it 'refuses every admin route to someone who is not signed in' do
    list = violations(sweep(nil, admin_routes))
    expect(list).to be_empty, "Not refused:\n#{list.join("\n")}"
  end

  it 'refuses every admin route to a user without admin rights' do
    list = violations(sweep(member, admin_routes))
    expect(list).to be_empty, "Not refused:\n#{list.join("\n")}"
  end

  it "refuses an admin of another organisation every route on institute A's records" do
    routes = admin_routes.select do |route|
      names_a_record?(route) && own_org_actions.exclude?("#{route[:controller]}##{route[:action]}")
    end
    list = violations(sweep(admin_b, routes))
    expect(list).to be_empty, "Not refused:\n#{list.join("\n")}"
  end

  # Form data naming institute A, sent by an admin of institute B to their own forms
  describe 'an admin of another organisation naming institute A in a form' do
    let!(:group_b) { create(:guidance_group, org: org_b) }
    let!(:guidance_b) { create(:guidance, guidance_group: group_b) }
    let!(:department_b) { create(:department, org: org_b) }

    before { sign_in admin_b }

    it "can't add guidance to institute A's guidance group" do
      expect do
        post "/org/admin/guidance/#{org_b.id}/admin_create",
             params: { guidance: { guidance_group_id: guidance_group.id, text: 'Injected', published: '1',
                                   theme_ids: [theme.id] } }
      end.not_to(change { guidance_group.reload.guidances.count })
      expect(guidance_group.published).to eq(guidance_group.reload.published)
    end

    it "can't move guidance into institute A's guidance group" do
      put "/org/admin/guidance/#{guidance_b.id}/admin_update",
          params: { guidance: { guidance_group_id: guidance_group.id, text: 'Moved' } }

      expect(guidance_b.reload.guidance_group).to eq(group_b)
    end

    it "can't move a guidance group to institute A" do
      put "/org/admin/guidancegroup/#{group_b.id}/admin_update",
          params: { guidance_group: { org_id: org_a.id, name: 'Moved group' } }

      expect(group_b.reload.org).to eq(org_b)
    end

    it 'can only create departments in its own organisation' do
      expect do
        post "/org/admin/#{org_a.id}/departments", params: { department: { org_id: org_a.id, name: 'Injected' } }
      end.not_to(change { org_a.departments.count })
      expect(org_b.departments.pluck(:name)).to include('Injected')
    end

    it "can't move a department to institute A" do
      put "/org/admin/#{org_b.id}/departments/#{department_b.id}", params: { department: { org_id: org_a.id } }

      expect(department_b.reload.org).to eq(org_b)
    end
  end

  it 'refuses the super admin routes to an organisation admin' do
    list = violations(sweep(admin_a, admin_routes.select { |route| super_admin_route?(route) }))
    expect(list).to be_empty, "Not refused:\n#{list.join("\n")}"
  end

  # Control: the same calls do show pages for someone who may use them. Every action checks
  # authorization, also when it allows (after_action :verify_authorized raises otherwise).
  it 'lets a super admin in, through an authorization check on every route' do
    results = sweep(super_admin, admin_routes)

    expect(results.count { |result| result[:verb] == 'GET' && result[:status] == 200 }).to be > 30
    unchecked = results.select { |result| result[:status] == 'Pundit::AuthorizationNotPerformedError' }
    expect(unchecked.map { |result| "#{result[:verb]} #{result[:path]}" }).to eq([])
  end

  it 'still shows the plan lists to users, and the public lists to everyone' do
    sign_in member
    %w[/paginable/plans/privately_visible/1 /paginable/plans/organisationally_or_publicly_visible/1].each do |path|
      get path
      expect(response).to have_http_status(:ok), path
    end
    sign_out member
    # The public lists redirect to the public pages, which keep the paging in the address
    get '/paginable/plans/publicly_visible/1'
    expect(response).to redirect_to(%r{/public_plans})
    get '/paginable/templates/publicly_visible/1'
    expect(response).to redirect_to(%r{/public_templates})
  end
end

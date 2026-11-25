# frozen_string_literal: true

require 'rails_helper'

# Through the Belnet API a user may change a plan only as far as the web interface allows
# (PlanPolicy): versions, lifecycle stages and validation requests need edit rights; reviewing a
# validation needs edit rights or the "Review plans" permission in the plan's organisation. Only
# active roles count, also for reading. An API client acts for its organisation.
RSpec.describe 'Belnet API: changing plans', type: :request do
  let!(:org_a) { create(:org) }
  let!(:org_b) { create(:org) }
  let!(:template) { create(:template, :publicly_visible, published: true) }

  # Belnet sets a new user's org from the email domain and falls back to Org.guest
  before do
    create(:org, abbreviation: 'guests') unless Org.guest.present?
    Ugent::OrgDomain.create!(name: 'institute-a.example', org: org_a)
    Ugent::OrgDomain.create!(name: 'institute-b.example', org: org_b)
    BelnetConfigLifecycleStage.create!(org_id: nil, current_list_order: %w[draft final],
                                       full_list_order: %w[draft final])
    BelnetConfigValidationTopic.create!(org_id: nil, current_list_order: %w[ethics],
                                        full_list_order: %w[ethics])
    BelnetConfigValidationStatus.create!(org_id: nil, current_list_order: %w[approved],
                                         full_list_order: %w[approved])
  end

  let!(:owner) { api_user('owner@institute-a.example') }
  let!(:reader) { api_user('reader@institute-a.example') }
  let!(:colleague) { api_user('colleague@institute-a.example') }
  let!(:revoked) { api_user('revoked@institute-a.example') }
  let!(:reviewer) { api_user('reviewer@institute-a.example', 'review_org_plans') }
  let!(:outsider) { api_user('outsider@institute-b.example') }

  # A live, organisationally visible plan: owner, a read-only collaborator and a collaborator
  # whose edit role was deactivated. It has one version with a pending validation request.
  let!(:plan) do
    create(:plan, template: template, org: org_a,
                  visibility: Plan.visibilities[:organisationally_visible]).tap do |live|
      live.add_user!(owner.id, :creator)
      live.add_user!(reader.id, :commenter)
      live.add_user!(revoked.id, :editor)
      Role.find_by(plan_id: live.id, user_id: revoked.id).update!(active: false)
    end
  end
  let!(:version) do
    plan.create_plan_with_new_version!(reason: 'First version for the API access test',
                                       current_user: owner, original_plan: plan)
  end
  let!(:validation) do
    plan.governance_validations.create!(validated_plan: version, validation_topic: 'ethics',
                                        requested_by: owner)
  end

  let(:json_headers) { { 'Content-Type' => 'application/json', 'Accept' => 'application/json' } }

  def api_user(email, *extra_perms)
    user = create(:user, email: email, api_token: SecureRandom.uuid)
    (['use_api'] + extra_perms).each { |perm| user.perms << Perm.find_or_create_by(name: perm) }
    user
  end

  def token_for(caller)
    credentials = if caller.is_a?(ApiClient)
                    { grant_type: 'client_credentials', client_id: caller.client_id,
                      client_secret: caller.client_secret }
                  else
                    { grant_type: 'authorization_code', email: caller.email, code: caller.api_token }
                  end
    post '/api/v1/authenticate', params: credentials.to_json, headers: json_headers
    JSON.parse(response.body)['access_token']
  end

  def writes
    {
      'create a version' => [:post, '/versions', { reason: 'Version made through the API' }],
      'change a version' => [:put, "/versions/#{version.belnet_version}", { reason: 'Reason changed through the API' }],
      'set the lifecycle stage' => [:post, '/lifecycle-stage', { lifecycle_stage: 'final' }],
      'change the lifecycle stage' => [:put, '/lifecycle-stage', { lifecycle_stage: 'final' }],
      'request a validation' => [:post, '/validations',
                                 { topic: 'ethics', dmp_version_number: version.belnet_version }],
      'review a validation' => [:put, "/validations/#{validation.id}", { status: 'approved' }]
    }
  end

  def write(action, caller)
    verb, path, body = writes.fetch(action)
    token = token_for(caller)
    send(verb, "/api/belnet-v1/plans/#{plan.id}#{path}",
         params: body.to_json, headers: json_headers.merge('Authorization' => "Bearer #{token}"))
    response.status
  end

  def read(path, caller)
    token = token_for(caller)
    get path, headers: json_headers.merge('Authorization' => "Bearer #{token}")
    response.status
  end

  def plan_state
    { plan: plan_fields, validation_status: validation.reload.validation_status,
      version_reason: version.reload.belnet_version_metadata&.reason }
  end

  def plan_fields
    plan.reload
    [Plan.where(belnet_family_id: plan.belnet_family_id).count, plan.current_lifecycle_stage_name,
     plan.governance_validations.count]
  end

  all_writes = ['create a version', 'change a version', 'set the lifecycle stage',
                'change the lifecycle stage', 'request a validation', 'review a validation']

  { 'a read-only collaborator' => :reader,
    'a colleague who can see the plan through its organisation' => :colleague,
    'a collaborator whose role was deactivated' => :revoked }.each do |who, name|
    context "as #{who}" do
      all_writes.each do |action|
        it "can't #{action}" do
          caller = public_send(name)
          status = nil

          expect { status = write(action, caller) }.not_to(change { plan_state })
          expect(status).to be_in([403, 404])
        end
      end
    end
  end

  context 'as a reviewer of the organisation' do
    it 'can review a validation' do
      expect(write('review a validation', reviewer)).to eq(202)
      expect(validation.reload.validation_status).to eq('approved')
    end

    it "can't create a version" do
      expect { write('create a version', reviewer) }.not_to(change { plan_state })
      expect(response).to have_http_status(:forbidden)
    end
  end

  context 'as the owner' do
    it 'can make every change' do
      expect(write('create a version', owner)).to eq(201)
      expect(write('change a version', owner)).to eq(202)
      expect(write('set the lifecycle stage', owner)).to eq(201)
      expect(write('request a validation', owner)).to eq(201)
      expect(write('review a validation', owner)).to eq(202)
    end
  end

  context 'as an API client' do
    it 'can change plans of its own organisation' do
      expect(write('set the lifecycle stage', create(:api_client, org: org_a))).to eq(201)
    end

    it "can't see plans of another organisation" do
      expect { write('set the lifecycle stage', create(:api_client, org: org_b)) }.not_to(change { plan_state })
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'reading a plan' do
    it 'is allowed for active collaborators' do
      expect(read("/api/belnet-v1/plans/#{plan.id}", reader)).to eq(200)
      expect(read("/api/v1/plans/#{plan.id}", reader)).to eq(200)
    end

    it 'is not allowed once a collaborator role is deactivated' do
      plan.update!(visibility: Plan.visibilities[:privately_visible])

      expect(read("/api/belnet-v1/plans/#{plan.id}", revoked)).to eq(404)
      expect(read("/api/v1/plans/#{plan.id}", revoked)).to eq(404)
    end

    it 'is not allowed for users of another organisation' do
      expect(read("/api/belnet-v1/plans/#{plan.id}", outsider)).to eq(404)
    end
  end
end

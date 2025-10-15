# frozen_string_literal: true

# RailsAdmin configuration

# RailsAdmin route is added in config/routes/ugent.rb under prefix "/admin"

# More configuration info can be found at https://github.com/sferik/rails_admin/wiki

RailsAdmin.config do |config|
  # because roadmap uses sprockets too
  config.asset_source = :sprockets

  # use ApplicationController as its parent class
  config.parent_controller = "::ApplicationController"

  config.current_user_method { current_user }

  config.authorize_with do |controller|

    if current_user.nil? || !(current_user.can_super_admin?)

      flash[:alert] = "not authorized"
      redirect_to main_app.root_path

    end

  end

  # other stuff should be done in roadmap (some logic is contained not in their models but in their controllers)
  config.actions do
    dashboard                     # mandatory
    index                         # mandatory
    new do
      only %w(Ugent::OrgDomain Identifier)
    end
    export
    bulk_delete do
      only %w(Ugent::OrgDomain)
    end
    show
    edit do
      only %w(Ugent::OrgDomain Identifier)
    end
    delete do
      only %w(Ugent::OrgDomain Identifier)
    end
    show_in_app
  end

  # only allow these model in RailsAdmin
  config.included_models = [
    :Org,
    :'Ugent::OrgDomain',
    :Identifier,
  ]

  config.model "Identifier" do

    navigation_label "Organisation management"
    label "Identifier"
    label_plural "Identifiers"

    weight 0
    object_label_method :value

    list do
      field :id
      field :identifier_scheme
      field :identifiable
      field :identifiable_type do
        filterable true
      end
      field :label
      field :value
      field :created_at
      field :updated_at
    end

    show do
      field :id
      field :identifier_scheme
      field :label
      field :value
      field :created_at
      field :updated_at
    end

    edit do
      field :identifier_scheme
      field :label
      field :value
      field :identifiable
      field :attrs
    end

  end

  config.model "Org" do

    navigation_label "Organisation management"
    label "Organisation"
    label_plural "Organisations"

    weight 0
    object_label_method :name

    list do
      field :id
      field :name
      field :abbreviation
      field :managed
      field :created_at
      field :updated_at
    end

  end

  config.model "Ugent::OrgDomain" do

    navigation_label "Organisation management"
    label "Organisation domain"
    label_plural "Organisation domains"

    weight 1
    object_label_method :name

  end

end

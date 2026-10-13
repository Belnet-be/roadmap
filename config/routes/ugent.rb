# frozen_string_literal: true

Rails.application.routes.draw do

  get "selectable_user/edit", controller: "ugent/selectable_user", action: :edit, as: :edit_selectable_user
  post "selectable_user", controller: "ugent/selectable_user", action: :update, as: :update_selectable_user

  get "switch_user/edit", controller: "ugent/switch_user", action: :edit, as: :edit_switch_user
  post "switch_user", controller: "ugent/switch_user", action: :update, as: :update_switch_user

  mount RailsAdmin::Engine => "/admin", as: "rails_admin"

  # legacy routes
  get "/projects", to: "ugent/legacy/projects#index"
  get "/projects/:id", to: "ugent/legacy/projects#show"

  # extra route to update a plan role with an existing contributor together
  patch "/roles/:id/with_contributor", controller: "ugent/roles", action: :update_role_with_contributor, as: :update_role_with_contributor

end

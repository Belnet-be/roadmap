# config/initializers/rails_admin_timestamptz.rb
RailsAdmin::Config::Fields::Types.register(
  :timestamptz,
  RailsAdmin::Config::Fields::Types::Timestamp
)

# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Gevoelige parameters worden uit ALLE logs gefilterd en vervangen door [FILTERED]
# Belangrijk: dit beschermt tegen accidentele logging van wachtwoorden, tokens
# en persoonlijke data — ook als een gebruiker een wachtwoord in een zoekveld typt

Rails.application.config.filter_parameters += %i[
  password
  password_confirmation
  token
  secret
  api_key
  access_token
  auth_token
  _key
  crypt
  salt
  certificate
  otp
  ssn
]

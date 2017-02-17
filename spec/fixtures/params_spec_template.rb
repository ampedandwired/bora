CloudFormation do
  default_db_username = external_parameters.fetch(:default_db_username, 'user_default_inside_template')

  Parameter(:DbUsername) do
    Type 'String'
    Default default_db_username
  end
end

Fabricator :provider do
  name { sequence(:provider_id) { |i| "Provider #{i}" } }
end

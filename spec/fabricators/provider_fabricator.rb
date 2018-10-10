Fabricator :provider do
  name { sequence(:provider) { |i| "Provider #{i}" } }
end

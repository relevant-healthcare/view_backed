Fabricator :patient do
  name { sequence(:patient_name) { |i| "Patient #{i}" } }
  date_of_birth '1980-06-01'
  provider
end

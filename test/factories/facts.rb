FactoryBot.define do
  factory :fact, class: 'Fact' do

  end

  factory :relation_fact, class: 'Fact' do
    literal  { false }
  end

  factory :literal_fact, class: 'Fact' do
    literal  { true }
  end

  factory :tube_fact, class: Fact do
    predicate   { 'a' }
    object      { 'Tube' }
    literal  { true }
  end

  factory :well_fact, class: Fact do
    predicate   { 'a' }
    object      { 'Well' }
    literal  { true }
  end

  factory :tube_rack_fact, class: Fact do
    predicate   { 'a' }
    object      { 'TubeRack' }
    literal  { true }
  end

  factory :plate_fact, class: Fact do
    predicate   { 'a' }
    object      { 'Plate' }
    literal  { true }
  end

end

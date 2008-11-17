require 'activefacts/api'

module SubTypeWithoutRoles

  class Thing_ID < AutoCounter
    value_type 
  end

  class Thing
    identified_by :thing_id
    one_to_one :thing_id, Thing_ID              # See Thing_ID.thing_by_thing_id
  end

  class Thong < Thing
  end

end
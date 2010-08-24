require 'activefacts/api'

module ::WaiterTips

  class AUDValue < Money
    value_type 
  end

  class MealId < AutoCounter
    value_type 
  end

  class WaiterNr < SignedInteger
    value_type :length => 32
  end

  class Amount
    identified_by :audvalue
    one_to_one :audvalue, :class => AUDValue, :mandatory => true  # See AUDValue.amount
  end

  class Meal
    identified_by :meal_id
    one_to_one :meal_id, :mandatory => true     # See MealId.meal
  end

  class Waiter
    identified_by :waiter_nr
    one_to_one :waiter_nr, :mandatory => true   # See WaiterNr.waiter
  end

  class WaiterTip
    identified_by :waiter, :meal
    has_one :amount, :mandatory => true         # See Amount.all_waiter_tip
    has_one :meal, :mandatory => true           # See Meal.all_waiter_tip
    has_one :waiter, :mandatory => true         # See Waiter.all_waiter_tip
  end

  class Service
    identified_by :waiter, :meal
    has_one :meal, :mandatory => true           # See Meal.all_service
    has_one :waiter, :mandatory => true         # See Waiter.all_service
    has_one :amount                             # See Amount.all_service
  end

end

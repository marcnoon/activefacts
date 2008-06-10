#
# ActiveFacts tests: Roles of concept classes in the Runtime API
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#
describe "Roles" do
  setup do
    Object.send :remove_const, :Mod if Object.const_defined?("Mod")
    module Mod
      class Name < String
        value_type
      end
      class LegalEntity
        identified_by :name
        has_one :name
      end
      class Contract
        identified_by :first, :second
        has_one :first, LegalEntity
        has_one :second, LegalEntity
      end
      class Person < LegalEntity
        # identified_by         # No identifier needed, inherit from superclass
        # New identifier:
        identified_by :family, :given
        has_one :family, Name
        has_one :given, Name
        has_one :related_to, LegalEntity
      end
    end
    # print "concept: "; p Mod.concept
  end

  it "should associate a role name with a matching existing concept" do
    module Mod
      class Existing1 < String
        value_type
        has_one :name
      end
    end
    role = Mod::Existing1.roles(:name)
    role.should_not be_nil
    role.player.should == Mod::Name
  end

  it "should inject the respective role name into the matching concept" do
    module Mod
      class Existing1 < String
        value_type
        has_one :name
      end
    end
    Mod::Name.roles(:all_existing1).should_not be_nil
    Mod::LegalEntity.roles(:all_contract_by_first).should_not be_nil
  end

  it "should associate a role name with a matching concept after it's created" do
    module Mod
      class Existing2 < String
        value_type
        has_one :given_name
      end
    end
    # print "Mod::Existing2.roles = "; p Mod::Existing2.roles
    r = Mod::Existing2.roles(:given_name)
    r.should_not be_nil
    Symbol.should === r.player
    module Mod
      class GivenName < String
        value_type
      end
    end
    # puts "Should resolve now:"
    r = Mod::Existing2.roles(:given_name)
    r.should_not be_nil
    r.player.should == Mod::GivenName
  end

  it "should handle subtyping a value type" do
    module Mod
      class FamilyName < Name
        value_type
        one_to_one :patriarch, Person
      end
    end
    r = Mod::FamilyName.roles(:patriarch)
    r.should_not be_nil
    r.player.should == Mod::Person
    r.player.roles(:family_name).player.should == Mod::FamilyName
  end

  it "should instantiate the matching concept on assignment" do
    c = ActiveFacts::Constellation.new(Mod)
    bloggs = c.LegalEntity("Bloggs")
    acme = c.LegalEntity("Acme, Inc")
    contract = c.Contract("Bloggs", acme)
    #contract = c.Contract("Bloggs", "Acme, Inc")
    contract.first.should == bloggs
    contract.second.should == acme
    end

  it "should append the player into the respective role array in the matching concept" do
    foo = Mod::Name.new("Foo")
    le = Mod::LegalEntity.new(foo)
    le.respond_to?(:name).should be_true
    name = le.name
    name.respond_to?(:all_legal_entity).should be_true

    #pending
    name.all_legal_entity.should === [le]
  end

  it "should instantiate subclasses sensibly" do
    c = ActiveFacts::Constellation.new(Mod)
    bloggs = c.LegalEntity("Bloggs & Co")
    #pending
    p = c.Person("Fred", "Bloggs")
    p.related_to = "Bloggs & Co"
    Mod::LegalEntity.should === p.related_to
    bloggs.object_id.should == p.related_to.object_id
  end

end

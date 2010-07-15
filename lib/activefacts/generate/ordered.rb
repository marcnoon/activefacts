#
#       ActiveFacts Generators.
#       Generation support superclass that sequences entity types to avoid forward references.
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
require 'activefacts/api'

module ActiveFacts
  module Generate #:nodoc:
    class OrderedDumper #:nodoc:
      # Base class for generators of object-oriented class libraries for an ActiveFacts vocabulary.
      def initialize(vocabulary, *options)
        @vocabulary = vocabulary
        @vocabulary = @vocabulary.Vocabulary.values[0] if ActiveFacts::API::Constellation === @vocabulary
        options.each{|option| set_option(option) }
      end

      def set_option(option)
      end

      def puts(*a)
        @out.puts *a
      end

      def print(*a)
        @out.print *a
      end

      def generate(out = $>)
        @out = out
        vocabulary_start(@vocabulary)

        build_indices
        @concept_types_dumped = {}
        @fact_types_dumped = {}
        units_dump()
        value_types_dump()
        entity_types_dump()
        fact_types_dump()
        constraints_dump(@constraints_used)
        vocabulary_end
      end

      def build_indices
        @presence_constraints_by_fact = Hash.new{ |h, k| h[k] = [] }
        @ring_constraints_by_fact = Hash.new{ |h, k| h[k] = [] }

        @vocabulary.all_constraint.each { |c|
            case c
            when ActiveFacts::Metamodel::PresenceConstraint
              fact_types = c.role_sequence.all_role_ref.map{|rr| rr.role.fact_type}.uniq  # All fact types spanned by this constraint
              if fact_types.size == 1     # There's only one, save it:
                # debug "Single-fact constraint on #{fact_types[0].fact_type_id}: #{c.name}"
                (@presence_constraints_by_fact[fact_types[0]] ||= []) << c
              end
            when ActiveFacts::Metamodel::RingConstraint
              (@ring_constraints_by_fact[c.role.fact_type] ||= []) << c
            else
              # debug "Found unhandled constraint #{c.class} #{c.name}"
            end
          }
        @constraints_used = {}
      end

      def units_dump
        done_banner = false
        units = @vocabulary.all_unit.to_a.sort_by{|u| u.name.gsub(/ /,'')}
        while units.size > 0
          if !done_banner
            done_banner = true
            units_banner
          end
          i = 0
          while i < units.size
            unit = units[i]
            i += 1
            # Skip this one if the precursors haven't yet been dumped:
            next if unit.all_derivation_as_derived_unit.detect{|d| units.include?(d.base_unit) }

            unit_dump(unit)
            units.delete(unit)
            i -= 1
          end
        end
      end

      def value_types_dump
        done_banner = false
        @value_type_dumped = {}
        @vocabulary.all_concept.sort_by{|o| o.name.gsub(/ /,'')}.each{|o|
            next unless o.is_a?(ActiveFacts::Metamodel::ValueType)

            value_type_banner unless done_banner
            done_banner = true

            value_type_chain_dump(o)
            @concept_types_dumped[o] = true
          }
        value_type_end if done_banner
      end

      # Ensure that supertype gets dumped first
      def value_type_chain_dump(o)
        return if @value_type_dumped[o]
        value_type_chain_dump(o.supertype) if (o.supertype && !@value_type_dumped[o.supertype])
        value_type_dump(o) if o.name != "_ImplicitBooleanValueType"
        @value_type_dumped[o] = true
      end

      # Try to dump entity types in order of name, but we need
      # to dump ETs before they're referenced in preferred ids
      # if possible (it's not always, there may be loops!)
      def entity_types_dump
        # Build hash tables of precursors and followers to use:
        @precursors, @followers = *build_entity_dependencies

        done_banner = false
        sorted = @vocabulary.all_concept.select{|o|
          o.is_a?(ActiveFacts::Metamodel::EntityType) # and !o.fact_type
        }.sort_by{|o| o.name.gsub(/ /,'')}
        panic = nil
        while true do
          count_this_pass = 0
          skipped_this_pass = 0
          sorted.each{|o|
              next if @concept_types_dumped[o]    # Already done

              # Can we do this yet?
              if (o != panic and                  # We don't *have* to do it (panic mode)
                  (p = @precursors[o]) and         # There might be...
                  p.size > 0)                     # precursors - still blocked
                skipped_this_pass += 1
                next
              end

              entity_type_banner unless done_banner
              done_banner = true

              # We're going to emit o - remove it from precursors of others:
              (@followers[o]||[]).each{|f|
                  @precursors[f] -= [o]
                }
              count_this_pass += 1
              panic = nil

              if (o.fact_type)
                fact_type_dump_with_dependents(o.fact_type)
                released_fact_types_dump(o)
              else
                entity_type_dump(o)
                released_fact_types_dump(o)
              end

              entity_type_group_end
            }

            # Check that we made progress if there's any to make:
            if count_this_pass == 0 && skipped_this_pass > 0
              if panic        # We were already panicing... what to do now?
                # This won't happen again unless the above code is changed to decide it can't dump "panic".
                raise "Unresolvable cycle of forward references: " +
                  (bad = sorted.select{|o| EntityType === o && !@concept_types_dumped[o]}).map{|o| o.name }.inspect +
                  ":\n\t" + bad.map{|o|
                    o.name +
                    ": " +
                    @precursors[o].map{|p| p.name}.uniq.inspect
                  } * "\n\t" + "\n"
              else
                # Find the object that has the most followers and no fwd-ref'd supertypes:
                # This selection might be better if we allow PI roles to be fwd-ref'd...
                panic = sorted.
                  select{|o| !@concept_types_dumped[o] }.
                  sort_by{|o|
                      f = @followers[o] || []; 
                      o.supertypes.detect{|s| !@concept_types_dumped[s] } ? 0 : -f.size
                    }[0]
                # debug "Panic mode, selected #{panic.name} next"
              end
            end

            break if skipped_this_pass == 0       # All done.

        end
      end

      def entity_type_dump(o)
        @concept_types_dumped[o] = true
        pi = o.preferred_identifier

        supers = o.supertypes
        if (supers.size > 0)
          # Ignore identification by a supertype:
          pi = nil if pi && pi.role_sequence.all_role_ref.detect{|rr| rr.role.fact_type.is_a?(ActiveFacts::Metamodel::TypeInheritance) }
          subtype_dump(o, supers, pi)
        else
          non_subtype_dump(o, pi)
        end
        @constraints_used[pi] = true
      end

      def identified_by(o, pi)
        # Different adjectives might be used for different readings.
        # Here, we must find the role_ref containing the adjectives that we need for each identifier,
        # which will be attached to the uniqueness constraint on this object in the binary FT that
        # attaches that identifying role.
        role_refs = pi.role_sequence.all_role_ref.sort_by{|role_ref| role_ref.ordinal}

        # We need to get the adjectives for the roles from the identifying fact's preferred readings:
        identifying_facts = ([o.fact_type]+role_refs.map{|rr| rr.role.fact_type }).compact.uniq

        identifying_roles = role_refs.map(&:role)
        identification = identified_by_roles_and_facts(o, identifying_roles, identifying_facts)
        #identifying_facts.each{|f| @fact_types_dumped[f] = true }

        identification
      end

      def fact_readings_with_constraints(fact_type, fact_constraints = nil)
        define_role_names = true
        fact_constraints ||= @presence_constraints_by_fact[fact_type]
        readings = fact_type.all_reading_by_ordinal.inject([]) do |reading_array, reading|
          reading_array << expanded_reading(reading, fact_constraints, define_role_names)

          define_role_names = false     # No need to define role names in subsequent readings

          reading_array
        end

        readings
      end

      def expanded_reading(reading, fact_constraints, define_role_names)
        # Find all role numbers in order of occurrence in this reading:
        role_refs = reading.role_sequence.all_role_ref.sort_by{|role_ref| role_ref.ordinal}
        role_numbers = reading.text.scan(/\{(\d)\}/).flatten.map{|m| Integer(m) }
        roles = role_numbers.map{|m| role_refs[m].role }
        # debug "Considering #{reading.text} having #{role_numbers.inspect}"

        # Find the constraints that constrain frequency over each role we can verbalise:
        frequency_constraints = []
        value_constraints = []
        roles.each do |role|
          # Find a mandatory constraint that's *not* unique; this will need an extra reading
          role_is_first_in = reading.fact_type.all_reading.detect{|r|
              role == r.role_sequence.all_role_ref.sort_by{|role_ref|
                  role_ref.ordinal
                }[0].role
            }

          if vr = role.role_value_constraint
            if @constraints_used[vr]
              vr = nil
            else
              @constraints_used[vr] = true
              vr = vr.describe
            end
          end
          value_constraints << vr
          if (role == roles.last)   # First role of the reading?
            # REVISIT: With a ternary, doing this on other than the last role can be ambiguous,
            # in case both the 2nd and 3rd roles have frequencies. Think some more!

            constraint = fact_constraints.find{|c|  # Find a UC that spans all other Roles
                # internal uniqueness constraints span all roles but one, the residual:
                c.is_a?(ActiveFacts::Metamodel::PresenceConstraint) &&
                  !@constraints_used[c] &&  # Already verbalised
                  roles-c.role_sequence.all_role_ref.map(&:role) == [role]
              }
            # Index the frequency implied by the constraint under the role position in the reading
            if constraint     # Mark this constraint as "verbalised" so we don't do it again:
              @constraints_used[constraint] = true
            end
            frequency_constraints << show_frequency(role, constraint)
          else
            frequency_constraints << show_frequency(role, nil)
          end
        end

        expanded = reading.expand(frequency_constraints, define_role_names, value_constraints)

        if (ft_rings = @ring_constraints_by_fact[reading.fact_type]) &&
           (ring = ft_rings.detect{|rc| !@constraints_used[rc]})
          @constraints_used[ring] = true
          append_ring_to_reading(expanded, ring)
        end
        expanded
      end

      def show_frequency role, constraint
        constraint ? constraint.frequency : nil
      end

      def describe_fact_type(fact_type, highlight = nil)
        (fact_type.entity_type ? fact_type.entity_type.name : "")+
        describe_roles(fact_type.all_role, highlight)
      end

      def describe_roles(roles, highlight = nil)
        "("+
        roles.map{|role| role.concept.name + (role == highlight ? "*" : "")}*", "+
        ")"
      end

      def describe_role_sequence(role_sequence)
        "("+
        role_sequence.all_role_ref.map{|role_ref| role_ref.role.concept.name }*", "+
        ")"
      end

      # This returns an array of two hash tables each keyed by an EntityType.
      # The values of each hash entry are the precursors and followers (respectively) of that entity.
      def build_entity_dependencies
        @vocabulary.all_concept.inject([{},{}]) { |a, o|
            if o.is_a?(ActiveFacts::Metamodel::EntityType)
              precursor = a[0]
              follower = a[1]
              blocked = false
              pi = o.preferred_identifier
              if pi
                pi.role_sequence.all_role_ref.each{|rr|
                    role = rr.role
                    player = role.concept
                    # REVISIT: If we decide to emit value types on demand, need to remove this:
                    next unless player.is_a?(ActiveFacts::Metamodel::EntityType)
                    # player is a precursor of o
                    (precursor[o] ||= []) << player if (player != o)
                    (follower[player] ||= []) << o if (player != o)
                  }
              end
              if o.fact_type
                o.fact_type.all_role.each do |role|
                  next unless role.concept.is_a?(ActiveFacts::Metamodel::EntityType)
                  (precursor[o] ||= []) << role.concept
                  (follower[role.concept] ||= []) << o
                end
              end

              # Supertypes are precursors too:
              subtyping = o.all_type_inheritance_as_supertype
              next a if subtyping.size == 0
              subtyping.each{|ti|
                  # debug ti.class.roles.verbalise; debug "all_type_inheritance_as_supertype"; exit
                  s = ti.subtype
                  (precursor[s] ||= []) << o
                  (follower[o] ||= []) << s
                }
#            REVISIT: Need to use this to order ValueTypes after their supertypes
#            else
#              o.all_value_type_as_supertype.each { |s|
#                (precursor[s] ||= []) << o
#                (follower[o] ||= []) << s
#              }
            end
            a
          }
      end

      # Dump all fact types for which all precursors (of which "o" is one) have been emitted:
      def released_fact_types_dump(o)
        roles = o.all_role
        begin
          progress = false
          roles.map(&:fact_type).uniq.select{|fact_type|
              # The fact type hasn't already been dumped but all its role players have
              !@fact_types_dumped[fact_type] &&
                !fact_type.is_a?(ActiveFacts::Metamodel::ImplicitFactType) &&
                !fact_type.all_role.detect{|r| !@concept_types_dumped[r.concept] } &&
                !fact_type.entity_type
#                !(fact_type.entity_type && (p = @precursors[fact_type.entity_type]) && p.size > 0)
            }.sort_by{|fact_type|
              fact_type_key(fact_type)
            }.each{|fact_type|
              fact_type_dump_with_dependents(fact_type)
              # Objectified Fact Types may release additional fact types
              roles += fact_type.entity_type.all_role.sort_by{|role| role.ordinal} if fact_type.entity_type
              progress = true
            }
        end while progress
      end

      def skip_fact_type(f)
        # REVISIT: There might be constraints we have to merge into the nested entity or subtype. 
        # These will come up as un-handled constraints:
        pcs = @presence_constraints_by_fact[f]
        f.is_a?(ActiveFacts::Metamodel::TypeInheritance) ||
          (pcs && pcs.size > 0 && !pcs.detect{|c| !@constraints_used[c] })
      end

      # Dump one fact type.
      # Include as many as possible internal constraints in the fact type readings.
      def fact_type_dump_with_dependents(fact_type)
        @fact_types_dumped[fact_type] = true
        # debug "Trying to dump FT again" if @fact_types_dumped[fact_type]
        return if skip_fact_type(fact_type)

        if (et = fact_type.entity_type) &&
            (pi = et.preferred_identifier) &&
            pi.role_sequence.all_role_ref.detect{|rr| rr.role.fact_type != fact_type }
          # debug "Dumping objectified FT #{et.name} as an entity, non-fact PI"
          entity_type_dump(et)
          released_fact_types_dump(et)
          return
        end

        fact_constraints = @presence_constraints_by_fact[fact_type]

        # debug "for fact type #{fact_type.to_s}, considering\n\t#{fact_constraints.map(&:to_s)*",\n\t"}"
        # debug "#{fact_type.name} has readings:\n\t#{fact_type.readings.map(&:name)*"\n\t"}"
        # debug "Dumping #{fact_type.fact_type_id} as a fact type"

        # Fact types that aren't nested have no names
        name = fact_type.entity_type && fact_type.entity_type.name

        fact_type_dump(fact_type, name)

        # REVISIT: Go through the residual constraints and re-process appropriate readings to show them

        @fact_types_dumped[fact_type] = true
        @concept_types_dumped[fact_type.entity_type] = true if fact_type.entity_type
      end

      # Dump fact types.
      def fact_types_dump
        # REVISIT: Uniqueness on the LHS of a binary can be coded using "distinct"

        # The only fact types that can be remaining are those involving only value types,
        # since we dumped every fact type as soon as all relevant entities were dumped.
        # Iterate over all fact types of all value types, looking for these strays.

        done_banner = false
        fact_collection = @vocabulary.constellation.FactType
        fact_collection.keys.select{|fact_id|
                fact_type = fact_collection[fact_id] and
                !fact_type.is_a?(ActiveFacts::Metamodel::TypeInheritance) and
                !fact_type.is_a?(ActiveFacts::Metamodel::ImplicitFactType) and
                !@fact_types_dumped[fact_type] and
                !skip_fact_type(fact_type) and
                !fact_type.all_role.detect{|r| r.concept.is_a?(ActiveFacts::Metamodel::EntityType) }
            }.sort_by{|fact_id|
                fact_type = fact_collection[fact_id]
                fact_type_key(fact_type)
            }.each{|fact_id|
                fact_type = fact_collection[fact_id]

                fact_type_banner unless done_banner
                done_banner = true
                fact_type_dump_with_dependents(fact_type)
          }

        # REVISIT: Find out why some fact types are missed during entity dumping:
        @vocabulary.constellation.FactType.values.select{|fact_type|
            !fact_type.is_a?(ActiveFacts::Metamodel::TypeInheritance) &&
              !fact_type.is_a?(ActiveFacts::Metamodel::ImplicitFactType)
          }.sort_by{|fact_type|
            fact_type_key(fact_type)
          }.each{|fact_type|
            next if @fact_types_dumped[fact_type]
            # debug "Not dumped #{fact_type.verbalise}(#{fact_type.all_role.map{|r| r.concept.name}*", "})"
            fact_type_banner unless done_banner
            done_banner = true
            fact_type_dump_with_dependents(fact_type)
          }

        fact_type_end if done_banner
        # unused = constraints - @constraints_used.keys
        # debug "residual constraints are\n\t#{unused.map(&:to_s)*",\n\t"}"

        @constraints_used
      end

      def fact_instances_dump
        @vocabulary.fact_types.each{|f|
            # Dump the instances:
            f.facts.each{|i|
              raise "REVISIT: Not dumping fact instances"
              debug "\t\t"+i.to_s
            }
        }
      end

      # Arrange for objectified fact types to appear in order of name, after other fact types.
      # Facts are ordered alphabetically by the names of their role players,
      # then by preferred_reading (subtyping fact types have no preferred_reading).
      def fact_type_key(fact_type)
        role_names =
          if (pr = fact_type.preferred_reading)
            pr.role_sequence.
              all_role_ref.
              sort_by{|role_ref| role_ref.ordinal}.
              map{|role_ref| [ role_ref.leading_adjective, role_ref.role.concept.name, role_ref.trailing_adjective ].compact*"-" } +
              [pr.text]
          else
            fact_type.all_role.map{|role| role.concept.name }
          end

        (fact_type.entity_type ? [fact_type.entity_type.name] : [""]) + role_names
      end

      def role_ref_key(role_ref)
        [ role_ref.leading_adjective, role_ref.role.concept.name, role_ref.trailing_adjective ].compact*"-" +
        " in " +
        role_ref.role.fact_type.preferred_reading.expand
      end

      def constraint_sort_key(c)
        case c
        when ActiveFacts::Metamodel::RingConstraint
          [ 1,
            c.ring_type,
            c.role.concept.name,
            c.other_role.concept.name,
            c.name||""
          ]
        when ActiveFacts::Metamodel::SetExclusionConstraint
          [ 2+(c.is_mandatory ? 0 : 1),
            c.all_set_comparison_roles.map{|scrs|
              scrs.role_sequence.all_role_ref.map{|rr|
                role_ref_key(rr)
              }
            },
            c.name||""
          ]
        when ActiveFacts::Metamodel::SetEqualityConstraint
          [ 4,
            c.all_set_comparison_roles.map{|scrs|
              scrs.role_sequence.all_role_ref.map{|rr|
                role_ref_key(rr)
              }
            },
            c.name||""
          ]
        when ActiveFacts::Metamodel::SubsetConstraint
          [ 5,
            [c.superset_role_sequence, c.subset_role_sequence].map{|rs|
              rs.all_role_ref.map{|rr|
                role_ref_key(rr)
              }
            },
            c.name||""
          ]
        when ActiveFacts::Metamodel::PresenceConstraint
          [ 6,
            c.role_sequence.all_role_ref.map{|rr|
              role_ref_key(rr)
            },
            c.name||""
          ]
        end
      end

      def constraints_dump(except = {})
        heading = false
        @vocabulary.all_constraint.reject{|c| except[c]}.sort_by{ |c| constraint_sort_key(c) }.each do|c|
          # Skip some PresenceConstraints:
          if c.is_a?(ActiveFacts::Metamodel::PresenceConstraint)
            # Skip uniqueness constraints that cover all roles of a fact type, they're implicit
            fact_types = c.role_sequence.all_role_ref.map{|rr| rr.role.fact_type}.uniq
            next if fact_types.size == 1 &&
              c.max_frequency == 1 &&         # Uniqueness
              fact_types[0].all_role.size == c.role_sequence.all_role_ref.size

            # Skip internal PresenceConstraints over TypeInheritances:
            next if c.role_sequence.all_role_ref.size == 1 &&
              fact_types[0].is_a?(ActiveFacts::Metamodel::TypeInheritance)
          end

          constraint_banner unless heading
          heading = true

          # Skip presence constraints on value types:
          # next if ActiveFacts::PresenceConstraint === c &&
          #     ActiveFacts::ValueType === c.concept
          constraint_dump(c)
        end
        constraint_end if heading
      end

      def vocabulary_start(vocabulary)
        debug "Should override vocabulary_start"
      end

      def vocabulary_end
        debug "Should override vocabulary_end"
      end

      def units_banner
      end

      def unit_dump unit
      end

      def value_type_banner
        debug "Should override value_type_banner"
      end

      def value_type_end
        debug "Should override value_type_end"
      end

      def value_type_dump(o)
        debug "Should override value_type_dump"
      end

      def entity_type_banner
        debug "Should override entity_type_banner"
      end

      def entity_type_group_end
        debug "Should override entity_type_group_end"
      end

      def non_subtype_dump(o, pi)
        debug "Should override non_subtype_dump"
      end

      def subtype_dump(o, supertypes, pi = nil)
        debug "Should override subtype_dump"
      end

      def append_ring_to_reading(reading, ring)
        debug "Should override append_ring_to_reading"
      end

      def fact_type_banner
        debug "Should override fact_type_banner"
      end

      def fact_type_end
        debug "Should override fact_type_end"
      end

      def fact_type_dump(fact_type, name)
        debug "Should override fact_type_dump"
      end

      def constraint_banner
        debug "Should override constraint_banner"
      end

      def constraint_end
        debug "Should override constraint_end"
      end

      def constraint_dump(c)
        debug "Should override constraint_dump"
      end

    end

    def dump(vocabulary, out = $>)
      OrderedDumper.new(vocabulary).dump(out)
    end
  end
end

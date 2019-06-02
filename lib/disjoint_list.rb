require 'ruby-xxhash'

class DisjointList
  SEED_FOR_UNIQUE_IDS = Random.rand(1000)
  MAX_DEEP_UNIQUE_ID = 3

  MAX_OPPOSITE_DISJOINT_CYCLE_LENGTH = 100

  include Enumerable

  attr_accessor :cached_instances_by_unique_id, :cached_unique_ids
  attr_accessor :enabled_ids
  attr_accessor :list
  attr_accessor :opposite_disjoint

  def initialize(list, opposite_disjoint=nil)
    @list = list
    @opposite_disjoint = opposite_disjoint
    @cached_unique_ids = {}
    @cached_instances_by_unique_id = {}
    @enabled_ids = {}

    list.each{|e| enable(unique_id_for_element(e))}
  end

  def already_added?(unique_id)
    @enabled_ids.has_key?(unique_id)
  end

  def enabled?(element)
    @enabled_ids[unique_id_for_element(element)]
  end

  def opposite_disjoint_enabled(unique_id)
    return opposite_disjoint.enabled_ids[unique_id] if opposite_disjoint
  end

  def include?(element)
    !!@enabled_ids[unique_id_for_element(element)]
  end

  def remove(element)
    unique_id = unique_id_for_element(element)
    remove_from_raw_list_by_id(unique_id)
    @enabled_ids.delete(unique_id)
    if opposite_disjoint && opposite_disjoint.already_added?(unique_id)
      opposite_disjoint.enabled_ids[unique_id]=true
    end
  end

  def remove_from_raw_list_by_id(unique_id)
    @list.delete_if do |a|
      unique_id_for_element(a) == unique_id
    end
  end

  def length
    @list.length
  end

  def each(&block)
    @list.each(&block)
  end

  def [](index)
    @list[index]
  end

  def flatten
    @list.flatten
  end

  def uniq!
    @list.uniq!
  end

  def <<(element)
    if element.kind_of?(Array)
      element.each{|e| add(e)}
    else
      add(element)
    end
  end

  def concat(element)
    if element.kind_of?(Array)
      element.each{|e| add(e)}
    else
      add(element)
    end
  end

  def push(element)
    add(element)
  end

  def add(element)
    return merge(element) if element.kind_of?(DisjointList)
    unique_id = unique_id_for_element(element)
    if opposite_disjoint_enabled(unique_id)
      disable(unique_id)
    elsif include?(element)
      # It is already in our list, so we do not add it again
      return false
    else
      # Is not in any of the lists so we can add it
      if (element.kind_of?(Enumerable) && (!element.kind_of?(Hash)))
        @list.concat(element)
      else
        @list.push(element)
      end
      enable(unique_id)
    end
    self
  end

  # SET_MUTUAL_DISJOINT
  #
  # Creates a minimal cycled relation mutually exclujent between two lists
  # If we want to have the same behaviour between multiple lists we should use
  # set_opposite_disjoint() and create a cyclic linked structure with it
  def set_mutual_disjoint(disjoint_list)
    set_opposite_disjoint(disjoint_list)
    disjoint_list.set_opposite_disjoint(self)
  end

  #
  # SET_OPPOSITE_DISJOINT
  #
  # This relation by itself is not useful. It is only useful when there is a cycle,
  # as the cycled linked structure will make sure that elements only reside in one
  # of the disjoint lists or they will be removed.
  # Examples of cycles:
  #
  # Mutual opposites:
  #
  #     A <=> B
  #
  # Linked structure:
  #
  #     ---------------
  #     |              |
  #     V              |
  #     A => B => C => D
  #
  def set_opposite_disjoint(opposite_disjoint)
    @opposite_disjoint = opposite_disjoint

    # Remove elements that are no longer valid because of the opposite list
    if @opposite_disjoint.length > 0
      @opposite_disjoint.enabled_ids.keys.each do |key|
        if (@opposite_disjoint.enabled_ids[key] == true)
          @enabled_ids[key]=false
          remove_from_raw_list_by_id(key)
        end
      end
    end
  end

  def sum_function_for(value)
    # Value to create checksum and seed
    XXhash.xxh32(value, SEED_FOR_UNIQUE_IDS)
  end

  def unique_id_for_element(element)
    return @cached_unique_ids[element] if @cached_unique_ids[element]
    @cached_unique_ids[element]||=_unique_id_for_element(element, 0)
    @cached_instances_by_unique_id[@cached_unique_ids[element]]=element
    @cached_unique_ids[element]
  end

  def merge(disjoint_list)
    # We copy the cache of all instances from the list we want to merge
    @cached_instances_by_unique_id.merge!(disjoint_list.cached_instances_by_unique_id)

    # We copy the raw content of the list into our list.
    concat(disjoint_list.list)
    #@list.concat(disjoint_list.list).uniq!

    # We clean from the copied raw content all the elements that create a conflict with our
    # current contents

    # All enabled elements I have that are not valid because of the opposite disjoint of the
    # instance I am merging with
    enabled_ids.keys.each do |key|
      if (enabled_ids[key]==true) && (disjoint_list.enabled_ids[key]==false)
        @enabled_ids[key]=false
        remove_from_raw_list_by_id(key)
      end
    end
    disjoint_list.enabled_ids.keys.each do |key|
      if (disjoint_list.enabled_ids[key]==true)
        if (enabled_ids[key]==false)
          remove_from_raw_list_by_id(key)
        else
          @enabled_ids[key]=true
        end
      else
        @enabled_ids[key]=false
        remove_from_raw_list_by_id(key)
      end
    end
    self
  end

  def value_for(key, caller=nil, deep=0)
    return nil if caller==self
    return nil if deep > MAX_OPPOSITE_DISJOINT_CYCLE_LENGTH
    cached_instances_by_unique_id[key] || opposite_disjoint.value_for(key, self, deep+1)
  end

  def disabled_values
    enabled_ids.keys.select{|key| enabled_ids[key] == false}.map do |key|
      value_for(key)
    end
  end

  def enabled_values
    enabled_ids.keys.select{|key| enabled_ids[key] == true}.map do |key|
      value_for(key)
    end
  end

   def values
    enabled_ids.keys.map do |key|
      cached_instances_by_unique_id[key]
    end
  end

  protected

  def _unique_id_for_element(element, deep=0)
    return sum_function_for(SecureRandom.uuid) if deep==MAX_DEEP_UNIQUE_ID
    if element.kind_of?(String)
      sum_function_for(element)
    elsif element.kind_of?(Enumerable)
      sum_function_for(element.map{|o| _unique_id_for_element(o, deep+1)}.join(""))
    elsif element.kind_of?(Hash)
      sum_function_for(element.keys.dup.concat(element.values.map{|val| _unique_id_for_element(val, deep+1)}).join(""))
    elsif element.respond_to?(:uuid)
      sum_function_for(element.uuid)
    elsif element.respond_to?(:id)
      sum_function_for("#{element.class.to_s}_#{element.id.to_s}")
    else
      sum_function_for(element.to_s)
    end
  end

  def enable(unique_id)
    _set_enable(unique_id, true) unless @enabled_ids[unique_id]==false
  end

  def disable(unique_id)
    _set_enable(unique_id, false)
  end

  def _set_enable(unique_id, value, caller=nil, deep=0)
    return if caller==self
    return if (deep > MAX_OPPOSITE_DISJOINT_CYCLE_LENGTH)

    @enabled_ids[unique_id]=value
    remove_from_raw_list_by_id(unique_id) unless value
    if opposite_disjoint
      #opposite_disjoint.enabled_ids[unique_id]=false
      #opposite_disjoint.remove_from_raw_list_by_id(unique_id)
      opposite_disjoint._set_enable(unique_id, false, (caller||self), deep+1)
    end
  end


end

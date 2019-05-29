require 'ruby-xxhash'

class DisjointList
  SEED_FOR_UNIQUE_IDS = Random.rand(1000)
  MAX_DEEP_UNIQUE_ID = 3

  include Enumerable

  attr_accessor :cached_instances_by_unique_id, :already_added_ids, :list, :opposite_disjoint

  def initialize(list, opposite_disjoint=nil)
    @list = list
    @opposite_disjoint = opposite_disjoint
    @cached_unique_ids = {}
    @cached_instances_by_unique_id = {}
    @already_added_ids = {}
  end

  def already_added?(unique_id)
    @already_added_ids[unique_id]==true
  end

  def opposite_already_added?(unique_id)
    return false unless @opposite_disjoint
    @opposite_disjoint.already_added?(unique_id)
  end

  def remove(element)
    @list.delete_if do |a|
      unique_id_for_element(a) == unique_id_for_element(element)
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

  def <<(element)
    add(element)
  end

  def concat(element)
    add(element)
  end

  def push(element)
    add(element)
  end

  def add(element)
    return merge(element) if element.kind_of?(DisjointList)
    unique_id = unique_id_for_element(element)
    if already_added?(unique_id) && opposite_already_added?(unique_id)
      remove(element)
    elsif already_added?(unique_id)
      # It is already in our list, so we do not add it again
      return false
    elsif opposite_already_added?(unique_id)
      # It is in the opposite list, so we remove it from that list to not add it again
      @opposite_disjoint.remove(element)
    else
      # Is not in any of the lists so we can add it
      if (element.kind_of?(Enumerable) && (!element.kind_of?(Hash)))
        @list.concat(element)
      else
        @list.push(element)
      end
    end
    add_id(unique_id)
  end

  def set_opposite_disjoint(opposite_disjoint)
    @opposite_disjoint = opposite_disjoint
  end

  def add_id(unique_id)
    @already_added_ids[unique_id]=true
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

  def merge(disjoint_list)
    # We copy the cache of all instances from the list we want to merge
    @cached_instances_by_unique_id.merge!(disjoint_list.cached_instances_by_unique_id)

    # We copy the raw content of the list into our list.
    @list.concat(disjoint_list.list).uniq!

    # As we merge both lists now we have added all elements from both lists
    @already_added_ids.merge!(disjoint_list.already_added_ids)

    # We clean from the copied raw content all the elements that create a conflict with our
    # current contents
    @already_added_ids.keys.each do |key|
      # Any element I have conflicting with my opposite disjoint
      # Any element I have conflicting with the opposite disjoint of my merged list
      if (opposite_disjoint.already_added?(key) || disjoint_list.opposite_disjoint.already_added?(key))
        remove(@cached_instances_by_unique_id[key])
      end
    end
  end

end

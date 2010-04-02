# refer to model object attributes in a Rails' conventional manner
# <tt>model.user_name # for unconventional table column UserName</tt>
# assumes camel-casing used by all db column names (not a mix of camel-case and underscore)

class ActiveRecord::Base
  
  class << self
    def set_primary_key_with_conventionals(value = nil, &block)
      set_primary_key_without_conventionals((value ? value.camelize : nil), &block)
    end
    
    alias_method_chain :set_primary_key, :conventionals
    
    def set_inheritance_column_with_conventionals(value = nil, &block)
      set_inheritance_column_without_conventionals((value ? value.camelize : nil), &block)
    end
    
    alias_method_chain :set_inheritance_column, :conventionals


    private
          
      def construct_finder_sql_with_conventionals(options)
        if options[:select].is_a? Array
           # :select => [:user_name, :password] becomes :select => "UserName,Password"
          options[:select] = options[:select].map{ |x| x.to_s.camelize }.join(',')
        elsif options[:select].is_a? String
          # :select => "user_name, password" becomes :select => "UserName,Password"
          options[:select] = options[:select].split(',').map{ |x| x.strip.camelize }.join(',')
        end
        construct_finder_sql_without_conventionals(options)
      end
      
      alias_method_chain :construct_finder_sql, :conventionals
      
          
      def add_conditions_with_conventionals!(sql, conditions, scope = :auto)
        if conditions.is_a? Hash
          stringed_conditions = ''
          # :conditions => {:user_name => 'Sam'} becomes "UserName = 'Sam' AND..."
          conditions.each_pair{ |k,v| stringed_conditions += "#{k.to_s.camelize} = '#{v.to_s}' AND " }
          stringed_conditions.chomp!(' AND ')
          conditions = stringed_conditions #conditions now a string
        elsif conditions.is_a? String
          # TODO: string conditions not conventionalized
        end
        # TODO: modify scope[:conditions]
        add_conditions_without_conventionals!(sql, conditions, scope)
        
      end
      
      alias_method_chain :add_conditions!, :conventionals
    end # self


    
  private
    def method_missing_with_conventionals(meth_id, *args)
      method_missing_without_conventionals meth_id.to_s.camelize.to_sym, *args
      rescue NoMethodError # try again in case camelizing breaks something that should work
        method_missing_without_conventionals(meth_id, *args)
    end
  
    alias_method_chain :method_missing, :conventionals

end
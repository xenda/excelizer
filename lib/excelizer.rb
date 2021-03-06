require "excelizer/version"
require "excelizer/writer"

module Excelizer
  class Base
    def self.attr_downloadable(*attrs)
      attrs.each do |attr|
        define_method(attr) do
          self.instance_variable_get("@#{attr}")
        end
      end
    end

    def build_xls(collection=model_class.all)
      headers = *methods.select { |m| self.method(m).owner == self.class }.map { |m| m.to_s.titleize }
      records = get_collection_data(collection)

      Excelizer::Writer.write headers, records
    end

    def get_collection_data(collection=model_class.all)
      model_methods = model_clean_attributes model_class

      # Gets the methods in the class definition and attr_downloadable
      own_methods = methods.select { |m| self.method(m).owner == self.class }

      # If the model class has the same method as the one defined in
      # attr_downloadble, that method will be called.
      collection.map do |child_instance|
        @model = child_instance
        own_methods.map do |attr|
          # Checks if the model has a method with the same name and
          # if the class definition overrides the model method
          reciever = self
          if model_methods.include?(attr.to_s) && reciever.send(attr).nil?
            reciever = child_instance
          end
          reciever.send(attr)
        end.compact
      end
    end

    def model_class
      Object.const_get self.class.name.gsub "Downloader", ""
    end

    def model_clean_attributes(model_class_ref)
      model_class_ref.new.attributes.keys - model_class_ref.protected_attributes.to_a
    end

  end
end

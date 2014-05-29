module Sprockets

  Context.class_eval do

    #  Patches #resolve method to properly handle virtual assets.
    #
    def resolve_with_virtuals(path, options = {}, &block) 
      proc = SprocketsVirtualAssets.virtuals[path]

      if proc
        builder = proc.call(path, environment, options)
        return builder.virtual_path
      end

      resolve_without_virtuals(path, options, &block)
    end

    alias_method_chain :resolve, :virtuals

    #  Patches #evaluate method to properly handle virtual assets.
    #
    def evaluate_with_virtuals(path, options = {})
      proc = SprocketsVirtualAssets.virtuals[path]

      if proc
        builder     = proc.call(path, environment, options)
        
        pathname    = builder.virtual_path
        attributes  = environment.attributes_for(pathname)
        processors  = options[:processors] || attributes.processors
  
        result      = builder.virtual_source

        processors.each do |processor|
          begin
            template = processor.new(pathname.to_s) { result }
            result = template.render(self, {})
          rescue Exception => e
            annotate_exception! e
            raise
          end
        end

        result
      else
        evaluate_without_virtuals(path, options)
      end
    end

    alias_method_chain :evaluate, :virtuals

  end

end
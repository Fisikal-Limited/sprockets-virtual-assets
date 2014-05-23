module Sprockets

  Environment.class_eval do
  
    #  Returns asset instance trying to fetch it through virtual hash.
    #
    def find_asset_with_virtuals(*args)
      path    = args.first
      options = args[1] || {}

      proc = SprocketsVirtualAssets.virtuals[path]
      return proc.call(path, self, options) if proc
      
      find_asset_without_virtuals(*args)
    end
  
    alias_method_chain :find_asset, :virtuals
  
  end

end
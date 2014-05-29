module Sprockets

  Index.class_eval do
  
    #  Returns asset instance trying to fetch it through virtual hash.
    #
    def find_asset_with_virtuals(path, options = {})
      proc = SprocketsVirtualAssets.virtuals[path]
      return proc.call(path, @environment, options).asset if proc
      
      find_asset_without_virtuals(path, options)
    end
  
    alias_method_chain :find_asset, :virtuals
  
  end

end
module SprocketsVirtualAssets

  #  This class represents an sprocket-compatible asset to be passed down to sprockets.
  #
  class VirtualAsset < Sprockets::Asset
    
    attr_reader :source
    
    #  Initializes the virtual asset with logical path and source.
    #
    def initialize(environment, logical_path, dependencies, content_type)
      @dependencies = dependencies.map { |path| environment.find_asset(path) }
      @logical_path = logical_path
      @source = @dependencies.map(&:to_s).join("\n")
      @mtime  = Time.now
      @length = Rack::Utils.bytesize(@source)
      @digest = environment.digest.update(@source).hexdigest
      @content_type = content_type
    end
    
    #  Retruns all dependent assets.
    #
    def to_a
      @dependencies.map(&:to_a).flatten
    end
    
  end
  
end
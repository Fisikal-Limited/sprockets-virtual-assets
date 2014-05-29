module SprocketsVirtualAssets

  #  This class represents an sprocket-compatible asset to be passed down to sprockets.
  #
  class VirtualAsset < Sprockets::BundledAsset
    
    #  Initializes the virtual asset with logical path and source.
    #
    def initialize(virtual_source, environment, path, virtual_path, options = {})
      @root         = environment.root
      @logical_path = path.to_s
      @pathname     = Pathname.new(virtual_path)
      @content_type = environment.content_type_of(pathname)      
      @mtime        = Time.now

      @source       = dependencies.map(&:to_s).join("\n") + "\n"

      context       = environment.context_class.new(environment, logical_path, pathname)
      @source      += context.evaluate(path, options)
      build_required_assets(environment, context)
      build_dependency_paths(environment, context)

      
      @length       = Rack::Utils.bytesize(source)
      @digest       = environment.digest.update(source).hexdigest

      @mtime        = required_assets.map(&:mtime).max
    end

    #  Virtual asset's body is always empty.
    #
    def body
      ""
    end

    #  Return an `Array` of `Asset` files that are declared dependencies.
    #
    def dependencies
      required_assets
    end

    #  Expand asset into an `Array` of parts.
    #
    def to_a
      required_assets
    end

    #  Checks if Asset is stale by comparing the actual mtime and
    #  digest to the inmemory model.
    #
    def fresh?(environment)
      @dependency_paths.all? { |dep| dependency_fresh?(environment, dep) }
    end

  private

    class DependencyFile < Struct.new(:pathname, :mtime, :digest)
      def initialize(pathname, mtime, digest)
        pathname = Pathname.new(pathname) unless pathname.is_a?(Pathname)
        mtime    = Time.parse(mtime) if mtime.is_a?(String)
        super
      end

      def eql?(other)
        other.is_a?(DependencyFile) &&
          pathname.eql?(other.pathname) &&
          mtime.eql?(other.mtime) &&
          digest.eql?(other.digest)
      end

      def hash
        pathname.to_s.hash
      end
    end

    def build_dependency_paths(environment, context)
      dependency_paths = {}

      context._dependency_paths.each do |path|
        dep = DependencyFile.new(path, environment.stat(path).mtime, environment.file_digest(path).hexdigest)
        dependency_paths[dep] = true
      end

      context._dependency_assets.each do |path|
        if path != self.pathname.to_s
          if asset = environment.find_asset(path, bundle: false)
            asset.dependency_paths.each do |d|
              dependency_paths[d] = true
            end
          end
        end
      end

      @dependency_paths = dependency_paths.keys
    end

    def build_required_assets(environment, context)
      @required_assets  = resolve_dependencies(environment, context._required_paths + [self.pathname.to_s]) -
                          resolve_dependencies(environment, context._stubbed_assets.to_a)
    end

    def resolve_dependencies(environment, paths)
      assets = []
      cache  = {}

      paths.each do |path|
        if path != self.pathname.to_s
          if asset = environment.find_asset(path, bundle: false)
            asset.required_assets.each do |asset_dependency|
              unless cache[asset_dependency]
                cache[asset_dependency] = true
                assets << asset_dependency
              end
            end
          end
        end
      end

      assets
    end

    def compute_dependency_digest(environment)
      required_assets.inject(environment.digest) { |digest, asset|
        digest.update asset.digest
      }.hexdigest
    end
    
  end
  
end
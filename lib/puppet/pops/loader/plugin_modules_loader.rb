# frozen_string_literal: true

# =PluginModulesLoader
# Provides visibility into the per-module type aliases and Puppet language
# functions that pluginsync stores in `Puppet[:pluginmoduledest]`, i.e.
# `<pluginmoduledest>/<module>/types` and `<pluginmoduledest>/<module>/functions`.
#
# It is the parent of the loader for the plugins that pluginsync stores in
# `Puppet[:libdir]`, so that synced Ruby functions can use the synced type
# aliases. Each module loader uses that loader as its private loader, so the
# synced Puppet code can in turn see the synced Ruby functions and data types,
# as well as the types and functions of every other synced module.
#
# The module loaders are created when first needed, since pluginsync may add
# modules after the loaders have been created.
#
# @api private
#
class Puppet::Pops::Loader::PluginModulesLoader < Puppet::Pops::Loader::DependencyLoader
  LOADABLES = [:type_pp, :func_4xpp].freeze

  # The loader that the module loaders use as their private loader
  attr_writer :module_private_loader

  # @param parent_loader [Puppet::Pops::Loader::Loader] the parent loader
  # @param loaders [Puppet::Pops::Loaders] the loaders that this loader belongs to
  # @param path [String] the directory that pluginsync stores the modules in
  #
  def initialize(parent_loader, loaders, path)
    super(parent_loader, 'cached_puppet_modules', nil, loaders.environment)
    @loaders = loaders
    @path = path
  end

  def discover(type, error_collector = nil, name_authority = Puppet::Pops::Pcore::RUNTIME_NAME_AUTHORITY, &block)
    create_module_loaders
    super
  end

  def find(typed_name)
    create_module_loaders
    super
  end

  def loaded_entry(typed_name, check_dependencies = false)
    create_module_loaders
    super
  end

  def to_s
    "(PluginModulesLoader '#{@loader_name}' '#{@path}')"
  end

  private

  def create_module_loaders
    return unless @dependency_loaders.nil?

    module_names = Dir.children(@path).select do |name|
      Puppet::Module.is_module_directory_name?(name) && File.directory?(File.join(@path, name))
    end.sort
    @dependency_loaders = module_names.map do |name|
      loader = Puppet::Pops::Loader::ModuleLoaders::FileBased.new(
        @parent, @loaders, name, File.join(@path, name), "cached_puppet_module_#{name}", LOADABLES
      )
      loader.private_loader = @module_private_loader
      loader
    end
  rescue Errno::ENOENT, Errno::ENOTDIR
    @dependency_loaders = []
  end
end

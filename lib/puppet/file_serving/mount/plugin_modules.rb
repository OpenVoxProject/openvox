# frozen_string_literal: true

require_relative '../../../puppet/file_serving/mount'
require_relative '../../../puppet/file_serving/fileset'

# Find files in the modules' types and functions directories, i.e. the
# Puppet language code that agents need in order to resolve deferred
# functions. Unlike the plugins mount, files are not merged into a single
# tree; each module keeps its own directory so that the module name, and
# thus the names of the types and functions, is preserved:
#
#   <module>/types/<name>.pp
#   <module>/functions/<name>.pp
class Puppet::FileServing::Mount::PluginModules < Puppet::FileServing::Mount
  SUBDIRECTORIES = %w[types functions].freeze

  # Return the path of the file or directory for the given relative path,
  # or nil if it does not exist.
  def find(relative_path, request)
    return root_directory(request) if relative_path.nil? || relative_path.empty?
    return nil unless Puppet[:serve_pluginmodules]

    module_name, subdirectory, *rest = relative_path.split('/')
    mod = request.environment.module(module_name)
    return nil unless mod

    if subdirectory.nil?
      synced_subdirectories(mod).empty? ? nil : mod.path
    elsif SUBDIRECTORIES.include?(subdirectory)
      path = ::File.join(mod.path, subdirectory, *rest)
      Puppet::FileSystem.exist?(path) ? path : nil
    end
  end

  def search(relative_path, request)
    unless relative_path.nil? || relative_path.empty?
      path = find(relative_path, request)
      return path ? [path] : nil
    end

    root = Puppet::FileServing::Fileset.new(root_directory(request), request)
    root.recurse = false
    filesets = [root]
    return filesets unless Puppet[:serve_pluginmodules]

    request.environment.modules.each do |mod|
      subdirectories = synced_subdirectories(mod)
      next if subdirectories.empty?

      base = ::File.dirname(mod.path)
      module_dir = Puppet::FileServing::Fileset.new(mod.path, request)
      module_dir.recurse = false
      filesets << Puppet::FileServing::Fileset::Relocated.new(module_dir, base)

      subdirectories.each do |path|
        filesets << Puppet::FileServing::Fileset::Relocated.new(Puppet::FileServing::Fileset.new(path, request), base)
      end
    end
    filesets
  end

  def valid?
    true
  end

  private

  def synced_subdirectories(mod)
    SUBDIRECTORIES.map { |dir| ::File.join(mod.path, dir) }.select { |path| ::File.directory?(path) }
  end

  # The directory used for the root of the mount. It only needs to be an
  # existing directory, since the mount's contents come from the modules.
  def root_directory(request)
    request.environment.modulepath.find { |path| ::File.directory?(path) } || Puppet[:codedir]
  end
end

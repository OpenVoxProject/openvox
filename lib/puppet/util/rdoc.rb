# frozen_string_literal: true

require_relative '../../puppet/util'
module Puppet::Util::RDoc
  module_function

  # launch a rdoc documentation process
  # with the files/dir passed in +files+
  def rdoc(outputdir, files, charset = nil)
    # then rdoc
    require 'rdoc/rdoc'
    require 'rdoc/options'

    # load our parser
    require_relative 'rdoc/parser'

    r = RDoc::RDoc.new

    # Documentation is rendered by RDoc's default generator using our custom
    # parser. The historical custom "puppet" generator and its HTML template
    # targeted RDoc 1.x and could not be loaded under any supported RDoc; the
    # template also carried a CC-BY-1.0 license, which is incompatible with
    # the Debian Free Software Guidelines. Both were removed.
    options = ["--quiet",
               "--exclude", "/modules/[^/]*/spec/.*$",
               "--exclude", "/modules/[^/]*/files/.*$",
               "--exclude", "/modules/[^/]*/tests/.*$",
               "--exclude", "/modules/[^/]*/templates/.*$",
               "--op", outputdir]

    options << "--force-update"
    options += ["--charset", charset] if charset
    options += files

    # launch the documentation process
    r.document(options)
  end

  # launch an output to console manifest doc
  def manifestdoc(files)
    raise _("RDOC SUPPORT FOR MANIFEST HAS BEEN REMOVED - See PUP-3638")
  end

  # Outputs to the console the documentation
  # of a manifest
  def output(file, ast)
    raise _("RDOC SUPPORT FOR MANIFEST HAS BEEN REMOVED - See PUP-3638")
  end

  def output_astnode_doc(ast)
    raise _("RDOC SUPPORT FOR MANIFEST HAS BEEN REMOVED - See PUP-3638")
  end

  def output_resource_doc(code)
    raise _("RDOC SUPPORT FOR MANIFEST HAS BEEN REMOVED - See PUP-3638")
  end
end

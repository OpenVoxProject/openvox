# frozen_string_literal: true

require_relative '../../puppet/reports'

report = Puppet::Util::Reference.newreference :report, :doc => "All available transaction reports" do
  Puppet::Reports.reportdocs
end

report.header = "
OpenVox can generate a report after applying a catalog. This report includes
events, log messages, resource statuses, and metrics and metadata about the run.
OpenVox agent sends its report to a OpenVox server, and puppet apply
processes its own reports.

OpenVox Server and puppet apply will handle every report with a set of report
processors, configurable with the `reports` setting in puppet.conf. This page
documents the built-in report processors.

See [About Reporting](https://puppet.com/docs/puppet/latest/reporting_about.html)
for more details.

"

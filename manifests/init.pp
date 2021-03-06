# This class installs the Elastic filebeat log shipper and
# helps manage which files are shipped
#
# @example
# class { 'filebeat':
#   outputs => {
#     'logstash' => {
#       'hosts' => [
#         'localhost:5044',
#       ],
#     },
#   },
# }
#
# @param package_ensure [String] The ensure parameter for the filebeat package (default: present)
# @param manage_repo [Boolean] Whether or not the upstream (elastic) repo should be configured or not (default: true)
# @param service_ensure [String] The ensure parameter on the filebeat service (default: running)
# @param service_enable [String] The enable parameter on the filebeat service (default: true)
# @param spool_size [Integer] How large the spool should grow before being flushed to the network (default: 1024)
# @param idle_timeout [String] How often the spooler should be flushed even if spool size isn't reached (default: 5s)
# @param registry_file [String] The registry file used to store positions, absolute or relative to working directory (default .filebeat)
# @param config_dir [String] The directory where prospectors should be defined (default: /etc/filebeat/conf.d)
# @param config_dir_mode [String] The unix permissions mode set on the configuration directory (default: 0755)
# @param config_file_mode [String] The unix permissions mode set on configuration files (default: 0644)
# @param purge_conf_dir [Boolean] Should files in the prospector configuration directory not managed by puppet be automatically purged
# @param outputs [Hash] Will be converted to YAML for the required outputs section of the configuration (see documentation, and above)
# @param shipper [Hash] Will be converted to YAML to create the optional shipper section of the filebeat config (see documentation)
# @param logging [Hash] Will be converted to YAML to create the optional logging section of the filebeat config (see documentation)
# @param conf_template [String] The configuration template to use to generate the main filebeat.yml config file
# @param download_url [String] The URL of the zip file that should be downloaded to install filebeat (windows only)
# @param install_dir [String] Where filebeat should be installed (windows only)
# @param tmp_dir [String] Where filebeat should be temporarily downloaded to so it can be installed (windows only)
# @param prospectors [Hash] Prospectors that will be created. Commonly used to create prospectors using hiera
class filebeat (
  $package_ensure   = $filebeat::params::package_ensure,
  $manage_repo      = $filebeat::params::manage_repo,
  $service_ensure   = $filebeat::params::service_ensure,
  $service_enable   = $filebeat::params::service_enable,
  $spool_size       = $filebeat::params::spool_size,
  $idle_timeout     = $filebeat::params::idle_timeout,
  $registry_file    = $filebeat::params::registry_file,
  $config_dir       = $filebeat::params::config_dir,
  $config_dir_mode  = $filebeat::params::config_dir_mode,
  $config_file_mode = $filebeat::params::config_file_mode,
  $purge_conf_dir   = $filebeat::params::purge_conf_dir,
  $outputs          = $filebeat::params::outputs,
  $shipper          = $filebeat::params::shipper,
  $logging          = $filebeat::params::logging,
  $run_options      = $filebeat::params::run_options,
  $conf_template    = $filebeat::params::conf_template,
  $download_url     = $filebeat::params::download_url,
  $install_dir      = $filebeat::params::install_dir,
  $tmp_dir          = $filebeat::params::tmp_dir,
  $prospectors      = {},
) inherits filebeat::params {

  $kernel_fail_message = "${::kernel} is not supported by filebeat."

  validate_bool($manage_repo)
  validate_hash($outputs, $logging, $prospectors)
  validate_string($idle_timeout, $registry_file, $config_dir, $package_ensure)

  if $package_ensure == '1.0.0-beta4' or $package_ensure == '1.0.0-rc1' {
    fail('Filebeat versions 1.0.0-rc1 and before are unsupported because they don\'t parse normal YAML headers')
  }

  anchor { 'filebeat::begin': } ->
  class { 'filebeat::install': } ->
  class { 'filebeat::config': } ->
  class { 'filebeat::service': } ->
  anchor { 'filebeat::end': }

  if !empty($prospectors) {
    create_resources('filebeat::prospector', $prospectors)
  }
}

require "thor"

module CloudstackCloner
  class Cli < Thor
    include Thor::Actions
    include CloudstackCloner::OptionResolver
    include CloudstackCloner::Helper

    package_name "cloudstack_cloner"

    class_option :config_file,
      default: File.join(Dir.home, '.cloudstack-cli.yml'),
      aliases: '-c',
      desc: 'Location of your cloudstack-cli configuration file'

    class_option :env,
      aliases: '-e',
      desc: 'Environment to use'

    desc "version", "Print cloudstack-cloner version number"
    def version
      say "cloudstack-cloner version #{CloudstackCloner::VERSION}"
    end

    desc "clone", "Clone a virtual machine"
    option :virtual_machine,
      desc: "name of the vm to clone",
      required: true
    option :project,
      desc: "name of project"
    option :clone_name,
      desc: "name of the new vm",
      required: true
    option :offering,
      desc: "name of the compute offering for the new vm"
    option :data_volumes,
      desc: "names of data volumes to attach",
      type: :array
    def clone
      opts = options.dup
      opts = resolve_project(opts)
      opts = resolve_virtual_machine(opts)
      opts = resolve_compute_offering(opts)
      clone_vm(opts)
    end

  end
end

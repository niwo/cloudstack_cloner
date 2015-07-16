require "yaml"
require "cloudstack_cloner/option_resolver"

module CloudstackCloner
  module Helper

    def clone_vm(opts)
      vm = client.list_virtual_machines(
        opts.merge(listall: true, name: opts[:virtual_machine])
      ).first

      if vm["state"] == "Running"
        say "Failure: ", :red
        say "VM #{vm["name"]} has to be stopped in order to create a template."
        exit 1
      end

      data_volumes = opts[:data_volumes].map do |disk|
        unless volume = client.list_volumes(
          name: disk,
          listall: true,
          type: "DATADISK",
          project_id: opts[:project_id]
        ).first
          say "Failure: ", :red
          say "Volume #{disk} not found."
          exit 1
        end
        volume
      end

      volume = client.list_volumes(opts.merge(listall: true, type: "root")).first

      templ_name = "#{vm["name"]}-#{Time.now.strftime("%F")}"

      if template = client.list_templates(
        name: templ_name,
        listall: true,
        projectid: opts[:project_id],
        templatefilter: "self"
      ).first
        say "Template #{templ_name} already exists.", :green
      else
        say "Create template from volume #{volume["name"]} ", :yellow
        template = client.create_template(
          name: templ_name,
          displaytext: templ_name,
          ostypeid: vm["guestosid"],
          volumeid: volume["id"]
        )["template"]
        say " [OK]", :green
      end

      say "Creating VM from template #{template["name"]} ", :yellow
      clone = client.deploy_virtual_machine(
        name: opts[:clone_name],
        displaytext: opts[:clone_name],
        templateid: template["id"],
        serviceofferingid: opts[:service_offering_id] || vm["serviceofferingid"],
        networkids: vm["networkids"],
        zoneid: vm["zoneid"],
        projectid: opts[:project_id]
      )["virtualmachine"]
      say " [OK]", :green


      data_volumes.each do |volume|
        say "Creating snapshot for volume #{volume["name"]} ", :yellow
        snapshot = client.create_snapshot(volumeid: volume["id"])["snapshot"]
        say " [OK]", :green

        say "Creating clone of volume #{volume["name"]} ", :yellow
        volume = client.create_volume(
          name: "#{volume["name"]}_#{opts[:clone_name]}",
          snapshot_id: snapshot["id"],
          projectid: opts[:project_id]
        )["volume"]
        say " [OK]", :green

        say "Attach clone of volume #{volume["name"]} to VM #{clone["name"]} ", :yellow
        client.attach_volume(
          id: volume["id"],
          virtualmachineid: clone["id"]
        )
        say " [OK]", :green

        say "Delete snapshot of volume #{volume["name"]} ", :yellow
        volume = client.delete_snapshot(id: snapshot["id"])
        say " [OK]", :green
      end

    end

    private

    def client
      @config ||= load_configuration(options[:config_file], options[:env]).first
      @client ||= CloudstackClient::Client.new(
        @config[:url],
        @config[:api_key],
        @config[:secret_key],
        options
      )
    end

    def load_configuration(config_file, env)
      unless File.exists?(config_file)
        puts "Configuration file #{config_file} not found."
        puts "Please run 'cloudstack-cli environment add' to create one."
        exit 1
      end

      begin
        config = YAML::load(IO.read(config_file))
      rescue
        puts "Can't load configuration from file #{config_file}."
        exit 1
      end

      if env ||= config[:default]
        unless config = config[env]
          puts "Can't find environment #{env}."
          exit 1
        end
      end

      unless config.key?(:url) && config.key?(:api_key) && config.key?(:secret_key)
        puts "The environment #{env || '\'-\''} contains no valid data."
        exit 1
      end
      return config, env
    end

  end
end

require "yaml"
require "cloudstack_cloner/option_resolver"

module CloudstackCloner
  module Helper

    def clone_vm(opts)
      vm = client.list_virtual_machines(
        opts.merge(listall: true, name: opts[:virtual_machine])
      ).first

      if client.list_virtual_machines(
        opts.merge(listall: true, name: opts[:clone_name])
      ).size > 0
        say_log "Failure: ", :red
        say "VM with name #{opts[:clone_name]} already exists."
        exit 1
      end

      if vm["state"] == "Running"
        say_log "Failure: ", :red
        say "VM #{vm["name"]} has to be stopped in order to create a template."
        exit 1
      end

      data_volumes = if opts[:data_volumes]
        opts[:data_volumes].map do |disk|
          unless volume = client.list_volumes(
            name: disk,
            listall: true,
            type: "DATADISK",
            project_id: opts[:project_id]
          ).first
            say_log "Failure: ", :red
            say "Volume #{disk} not found."
            exit 1
          end
          volume
        end
      else
        []
      end

      volume = client.list_volumes(opts.merge(listall: true, type: "root")).first
      templ_name = "#{vm["name"]}-#{Time.now.strftime("%F")}"

      if template = client.list_templates(
        name: templ_name,
        listall: true,
        projectid: opts[:project_id],
        templatefilter: "self"
      ).first
        say_log "Template #{templ_name} already exists.", :green
      else
        say_log "Create template from volume #{volume["name"]} ", :yellow
        template = client.create_template(
          name: templ_name,
          displaytext: templ_name,
          ostypeid: vm["guestosid"],
          volumeid: volume["id"]
        )["template"]
        say " [OK]", :green
      end

      say_log "Creating VM from template #{template["name"]} ", :yellow
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
        say_log "Creating snapshot for volume #{volume["name"]} ", :yellow
        snapshot = client.create_snapshot(volumeid: volume["id"])["snapshot"]
        say " [OK]", :green

        say_log "Creating clone of volume #{volume["name"]} ", :yellow
        volume = client.create_volume(
          name: "#{volume["name"]}_#{opts[:clone_name]}",
          snapshot_id: snapshot["id"],
          projectid: opts[:project_id]
        )["volume"]
        say " [OK]", :green

        say_log "Attach clone of volume #{volume["name"]} to VM #{clone["name"]} ", :yellow
        client.attach_volume(
          id: volume["id"],
          virtualmachineid: clone["id"]
        )
        say " [OK]", :green

        say_log "Delete snapshot of volume #{volume["name"]} ", :yellow
        volume = client.delete_snapshot(id: snapshot["id"])
        say " [OK]", :green
      end

    end

    private

    def say_log(message, color = nil)
      say "[#{Time.new.strftime("%F-%X")}] - "
      say "#{message}", color
    end

    def client
      @config ||= CloudstackClient::Configuration.load(options)
      @client ||= CloudstackClient::Client.new(
        @config[:url],
        @config[:api_key],
        @config[:secret_key],
        options
      )
    end

  end
end

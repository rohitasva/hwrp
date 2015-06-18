class Chef
  class Resource
    class Directories < Chef::Resource
      identity_attr :name

      def initialize(name, run_context=nil)
        super
        @resource_name = :directories
        @provider = Chef::Provider::Hwrp
        @action = [:create, :modify]
        @allowed_actions.push(:create, :mofify)

        @name = name
        @returns = 0
      end

      def locations(arg=nil)
        set_or_return(:locations, arg, :kind_of => [Array])
      end

      def user(arg=nil)
        set_or_return(:user, arg, :kind_of => [String])
      end

      def group(arg=nil)
        set_or_return(:group, arg, :kind_of => [String])
      end
    end
  end
end

class Chef
  class Provider
    class Directories < Chef::Provider
      def load_current_resource

        # Include these lines if you want the node variables to be loaded
        # It can be accessed by "node" variable just like in recipes
        # extend Chef::DSL::IncludeAttribute
        # include_attribute "hwrp::default"

        @current_resource = Chef::Resource::Directories.new(@new_resource.name)
        @current_resource.name(@new_resource.name)
        @current_resource.locations(@new_resource.locations)
        @current_resource.user(@new_resource.user)
        @current_resource.group(@new_resource.group)
        @current_resource
      end

      def action_create
        Chef::Log.info "Creating locations: #{@current_resource.locations} for user: #{@current_resource.user} and group: #{@current_resource.group}"
        @new_resource.locations.each do |location|
          directory location do
            user @current_resource.user
            group @current_resource.group
            action :create
          end
        end
        action_modify
      end

      def action_modify
        Chef::Log.info "Modifying locations: #{@current_resource.locations} for user: #{@current_resource.user} and group: #{@current_resource.group}"
        @new_resource.locations.each do |location|
          script "Changing permission for #{location}" do
            user "root"
            interpreter "bash"
            code <<-EOH
              chown -R #{@current_resource.user}:#{@current_resource.group} #{location}
            EOH
          end
        end
      end
    end
  end
end

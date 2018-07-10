require 'puppet/property/ordered_list'

module Puppet
  Type.newtype(:host) do
    ensurable

    newproperty(:ip) do
      desc "The host's IP address, IPv4 or IPv6."

      def valid_v4?(addr)
        if %r{^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$} =~ addr
          return $LAST_MATCH_INFO.captures.all? { |i| i = i.to_i; i >= 0 && i <= 255 }
        end
        false
      end

      def valid_v6?(addr)
        # http://forums.dartware.com/viewtopic.php?t=452
        # ...and, yes, it is this hard. Doing it programmatically is harder.
        return true if addr =~ %r{^\s*((([0-9A-Fa-f]{1,4}:){7}([0-9A-Fa-f]{1,4}|:))|(([0-9A-Fa-f]{1,4}:){6}(:[0-9A-Fa-f]{1,4}|((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){5}(((:[0-9A-Fa-f]{1,4}){1,2})|:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){4}(((:[0-9A-Fa-f]{1,4}){1,3})|((:[0-9A-Fa-f]{1,4})?:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){3}(((:[0-9A-Fa-f]{1,4}){1,4})|((:[0-9A-Fa-f]{1,4}){0,2}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){2}(((:[0-9A-Fa-f]{1,4}){1,5})|((:[0-9A-Fa-f]{1,4}){0,3}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){1}(((:[0-9A-Fa-f]{1,4}){1,6})|((:[0-9A-Fa-f]{1,4}){0,4}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(:(((:[0-9A-Fa-f]{1,4}){1,7})|((:[0-9A-Fa-f]{1,4}){0,5}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:)))(%.+)?\s*$}

        false
      end

      def valid_newline?(addr)
        return false if addr =~ %r{\n} || addr =~ %r{\r}
        true
      end

      validate do |value|
        return true if (valid_v4?(value) || valid_v6?(value)) && valid_newline?(value)
        raise Puppet::Error, _('Invalid IP address %{value}') % { value: value.inspect }
      end
    end

    # for now we use OrderedList to indicate that the order does matter.
    newproperty(:host_aliases, parent: Puppet::Property::OrderedList) do
      desc "Any aliases the host might have.  Multiple values must be
        specified as an array."

      def delimiter
        ' '
      end

      def inclusive?
        true
      end

      validate do |value|
        # This regex already includes newline check.
        raise Puppet::Error, _('Host aliases cannot include whitespace') if value =~ %r{\s}
        raise Puppet::Error, _('Host aliases cannot be an empty string. Use an empty array to delete all host_aliases ') if value =~ %r{^\s*$}
      end
    end

    newproperty(:comment) do
      desc 'A comment that will be attached to the line with a # character.'
      validate do |value|
        raise Puppet::Error, _('Comment cannot include newline') if value =~ %r{\n} || value =~ %r{\r}
      end
    end

    newproperty(:target) do
      desc "The file in which to store service information.  Only used by
        those providers that write to disk. On most systems this defaults to `/etc/hosts`."

      defaultto do
        if @resource.class.defaultprovider.ancestors.include?(Puppet::Provider::ParsedFile)
          @resource.class.defaultprovider.default_target
        else
          nil
        end
      end
    end

    newparam(:name) do
      desc 'The host name.'

      isnamevar

      validate do |value|
        value.split('.').each do |hostpart|
          unless hostpart =~ %r{^([\w]+|[\w][\w\-]+[\w])$}
            raise Puppet::Error, _('Invalid host name')
          end
        end
        raise Puppet::Error, _('Hostname cannot include newline') if value =~ %r{\n} || value =~ %r{\r}
      end
    end

    @doc = "Installs and manages host entries.  For most systems, these
      entries will just be in `/etc/hosts`, but some systems (notably OS X)
      will have different solutions."
  end
end

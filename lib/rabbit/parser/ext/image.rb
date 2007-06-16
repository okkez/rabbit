require 'uri'
require 'cgi'
require 'open-uri'
require 'fileutils'

require 'rabbit/element'

module Rabbit
  module Parser
    module Ext
      module Image
        ALLOWED_IMG_URL_SCHEME = ['http', 'file', '']

        module_function
        def make_image(canvas, uri_str, prop={})
          uri = URI.parse(uri_str)
          scheme = uri.scheme
          unless ALLOWED_IMG_URL_SCHEME.include?(scheme.to_s.downcase)
            return nil
          end
          begin
            Element::Image.new(Private.image_filename(canvas, uri), prop)
          rescue Error
            canvas.logger.warn($!.message)
            nil
          end
        end

        module Private
          module_function
          def image_filename(canvas, uri)
            case uri.scheme
            when /file/i
              GLib.filename_from_utf8(uri.path)
            when /http|ftp/i
              other_uri_filename(canvas, uri)
            else
              related_path_filename(canvas, uri)
            end
          end

          def tmp_filename(canvas, key)
            dir = canvas.tmp_dir_name
            FileUtils.mkdir_p(dir)
            File.join(dir, CGI.escape(key))
          end

          def related_path_filename(canvas, uri)
            image_uri = canvas.full_path(GLib.filename_from_utf8(uri.to_s))
            filename = nil

            if URI.parse(image_uri).scheme.nil?
              filename = image_uri
            else
              filename = tmp_filename(canvas, image_uri)
              setup_image_file(canvas, image_uri, filename)
            end

            filename
          end

          def other_uri_filename(canvas, uri)
            filename = tmp_filename(canvas, uri.to_s)
            setup_image_file(canvas, uri, filename)
            filename
          end

          def setup_image_file(canvas, uri, filename)
            begin
              open(uri, "rb") do |in_file|
                File.open(filename, "wb") do |out|
                  out.print(in_file.read)
                end
              end
            rescue SocketError, OpenURI::HTTPError
              canvas.logger.warn("#{$!.message}: #{uri}")
            end
          end
        end
      end
    end
  end
end

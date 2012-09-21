class LayoutDumper
  def self.dump(apk_filename, output_dir = nil)
    aapt = aapt_path()

    files = `"#{aapt}" list "#{apk_filename}"`.lines.map(&:strip)
    layouts = files.select { |file| file =~ /\/layout\// }

    output_dir ||= layout_output_dir(apk_filename)
    Dir.mkdir(output_dir)

    layouts.each { |layout|
      output_filename = layout.gsub(/^res\/layout\//i, '').gsub(/\//, '_')
      output_path = File.join(output_dir, output_filename)

      File.open(output_path, 'w') { |file|
        contents = `#{aapt} dump xmltree "#{apk_filename}" "#{layout}"`
        file.write(contents)
      }
    }

    return output_dir
  end

private
  def self.layout_output_dir(apk_filename)
    extension = File.extname(apk_filename)
    return File.basename(apk_filename).gsub(/#{extension}$/i, '')
  end

  def self.aapt_path()
    aapt = where('aapt') || where('aapt.exe')
    if aapt.nil?
      raise RuntimeError, 'Could not find aapt or aapt.exe. Please ensure the Android SDK tools are on your PATH.'
    end

    return aapt
  end

  def self.where(executable)
    path = ENV['PATH']
    path.split(File::PATH_SEPARATOR).each { |p|
      file = File.join(p, executable)
      if File.exists?(file) && File.executable?(file)
        return File.absolute_path(file)
      end
    }

    return nil
  end
end

begin
  if ARGV.length < 1
    raise RuntimeError, 'Please specify an APK filename.'
  end

  apk_filename = ARGV[0]
  output_dir = LayoutDumper.dump(apk_filename)

  puts "Layouts dumped to #{output_dir}."

  exit 0
rescue => e
  puts "Error: #{e.message}"
  exit 1
end

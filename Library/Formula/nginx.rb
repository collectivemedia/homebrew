require 'formula'

class Nginx < Formula
  homepage 'http://nginx.org/'
  url 'http://nginx.org/download/nginx-1.2.3.tar.gz'
  sha1 '98059ae08ebbfaaead868128f7b66ebce16be9af'

  devel do
    url 'http://nginx.org/download/nginx-1.3.6.tar.gz'
    sha1 '8f1f1bd9a98a2d72a5b6fce24d67e9d5f48b5224'
  end

  env :userpaths

  depends_on 'pcre'

  option 'with-passenger', 'Compile with support for Phusion Passenger module'
  option 'with-webdav', 'Compile with support for WebDAV module'

  skip_clean 'logs'

  # Changes default port to 8080
  def patches
    DATA
  end

  def options
    [
      ['--with-passenger', "Compile with support for Phusion Passenger module"],
      ['--with-webdav',    "Compile with support for WebDAV module"],
      ['--with-status', "Compile with support for sub status module"]
    ]
  end

  def passenger_config_args
      passenger_root = `passenger-config --root`.chomp

      if File.directory?(passenger_root)
        return "--add-module=#{passenger_root}/ext/nginx"
      end

      puts "Unable to install nginx with passenger support. The passenger"
      puts "gem must be installed and passenger-config must be in your path"
      puts "in order to continue."
      exit
  end

  def install
    args = ["--prefix=#{prefix}",
            "--with-http_ssl_module",
            "--with-pcre",
            "--with-ipv6",
            "--with-cc-opt=-I#{HOMEBREW_PREFIX}/include",
            "--with-ld-opt=-L#{HOMEBREW_PREFIX}/lib",
            "--conf-path=#{etc}/nginx/nginx.conf",
            "--pid-path=#{var}/run/nginx.pid",
            "--lock-path=#{var}/nginx/nginx.lock"]

    args << passenger_config_args if ARGV.include? '--with-passenger'
    args << "--with-http_dav_module" if ARGV.include? '--with-webdav'
    args << "--with-http_stub_status_module" if ARGV.include? '--with-status'

    system "./configure", *args
    system "make"
    system "make install"
    man8.install "objs/nginx.8"
  end

  def caveats; <<-EOS.undent
    In the interest of allowing you to run `nginx` without `sudo`, the default
    port is set to localhost:8080.

    If you want to host pages on your local machine to the public, you should
    change that to localhost:80, and run `sudo nginx`. You'll need to turn off
    any other web servers running port 80, of course.

    You can start nginx automatically on login running as your user with:
      mkdir -p ~/Library/LaunchAgents
      cp #{plist_path} ~/Library/LaunchAgents/
      launchctl load -w ~/Library/LaunchAgents/#{plist_path.basename}

    Though note that if running as your user, the launch agent will fail if you
    try to use a port below 1024 (such as http's default of 80.)
    EOS
  end

  def startup_plist
    return <<-EOPLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>#{plist_name}</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
    <key>UserName</key>
    <string>#{`whoami`.chomp}</string>
    <key>ProgramArguments</key>
    <array>
        <string>#{HOMEBREW_PREFIX}/sbin/nginx</string>
    </array>
    <key>WorkingDirectory</key>
    <string>#{HOMEBREW_PREFIX}</string>
  </dict>
</plist>
    EOPLIST
  end
end

__END__
--- a/conf/nginx.conf
+++ b/conf/nginx.conf
@@ -33,7 +33,7 @@
     #gzip  on;

     server {
-        listen       80;
+        listen       8080;
         server_name  localhost;

         #charset koi8-r;

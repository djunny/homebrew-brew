require 'etc'

class Openresty < Formula
  desc "Scalable Web Platform by Extending NGINX with Lua"
  homepage "https://openresty.org"
  VERSION = "1.21.4.2".freeze
  revision 2
  url "https://openresty.org/download/openresty-1.21.4.2rc1.tar.gz"
  sha256 "ee96bbcf119abe5f1fc90461dd4674bd9397aa3db5544139578d9ace81983fdb"

  option "with-postgresql", "Compile with ngx_http_postgres_module"
  option "with-iconv", "Compile with ngx_http_iconv_module"
  option "with-slice", "Compile with ngx_http_slice_module"

  depends_on "geoip"
  depends_on "openresty/brew/openresty-openssl111"
  depends_on "pcre"
  depends_on "postgresql" => :optional

  skip_clean "site"
  skip_clean "pod"
  skip_clean "nginx"
  skip_clean "luajit"

  def install
    # Configure
    cc_opt = "-I#{HOMEBREW_PREFIX}/include -I#{Formula["pcre"].opt_include} -I#{Formula["openresty/brew/openresty-openssl111"].opt_include}"
    ld_opt = "-L#{HOMEBREW_PREFIX}/lib -L#{Formula["pcre"].opt_lib} -L#{Formula["openresty/brew/openresty-openssl111"].opt_lib}"

    args = %W[
      -j#{Etc.nprocessors}
      --prefix=#{prefix}
      --pid-path=#{var}/run/openresty.pid
      --lock-path=#{var}/run/openresty.lock
      --conf-path=#{etc}/openresty/nginx.conf
      --http-log-path=#{var}/log/nginx/access.log
      --error-log-path=#{var}/log/nginx/error.log
      --with-cc-opt=#{cc_opt}
      --with-ld-opt=#{ld_opt}
      --with-pcre-jit
      --without-http_rds_json_module
      --without-http_rds_csv_module
      --without-lua_rds_parser
      --with-ipv6
      --with-stream
      --with-stream_ssl_module
      --with-stream_ssl_preread_module
      --with-http_v2_module
      --without-mail_pop3_module
      --without-mail_imap_module
      --without-mail_smtp_module
      --with-http_stub_status_module
      --with-http_realip_module
      --with-http_addition_module
      --with-http_auth_request_module
      --with-http_secure_link_module
      --with-http_random_index_module
      --with-http_geoip_module
      --with-http_gzip_static_module
      --with-http_sub_module
      --with-http_dav_module
      --with-http_flv_module
      --with-http_mp4_module
      --with-http_gunzip_module
      --with-threads
      --with-http_image_filter_module=dynamic
      --with-luajit-xcflags=-DLUAJIT_NUMMODE=2\ -DLUAJIT_ENABLE_LUA52COMPAT\ -fno-stack-check
    ]

    args << "--with-http_postgres_module" if build.with? "postgresql"
    args << "--with-http_iconv_module" if build.with? "iconv"
    args << "--with-http_slice_module" if build.with? "slice"

    system "./configure", *args

    # Install
    system "make"
    system "make", "install"
  end

  plist_options :manual => "openresty"

  def plist
    <<~EOS
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
          <key>ProgramArguments</key>
          <array>
            <string>#{opt_prefix}/bin/openresty</string>
            <string>-g</string>
            <string>daemon off;</string>
          </array>
          <key>WorkingDirectory</key>
          <string>#{HOMEBREW_PREFIX}</string>
        </dict>
      </plist>
    EOS
  end

  def caveats
    <<~EOS
      You can find the configuration files for openresty under #{etc}/openresty/.
    EOS
  end

  test do
    system "#{bin}/openresty", "-V"
  end
end

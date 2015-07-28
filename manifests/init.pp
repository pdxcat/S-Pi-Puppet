class spi(
  $nginx                    = false,
  $manage_nginx             = true,
  $frontend_dir             = '/var/www/spi',
  $backend_dir              = '/opt/s-pi',
  $api_server_name          = undef,
  $web_server_name          = undef,
  $proxy_port               = 9000,
  $vertx_host               = undef,
  $vertx_port               = undef,
  $vertx_sstore             = undef,
  $vertx_sstore_client_host = undef,
  $vertx_sstore_client_port = undef,
  $big_dawg                 = undef,
  $big_dawg_url             = undef,
) {

  package { 'maven': }

  $vertx_settings = {
    'vertxHost'        => $vertx_host,
    'vertxPort'        => $vertx_port,
    'sstore'           => $vertx_sstore,
    'sstoreClientHost' => $vertx_sstore_client_host,
    'sstoreClientPort' => $vertx_sstore_client_port,
    'bigDawg'          => $big_dawg,
    'bigDawgUrl'       => $big_dawg_url,
  }

  file { 's-pi-settings.json':
    path    => "${backend_dir}/settings.json",
    content => template('spi/settings.json.erb'),
  }

  if $nginx {
    if $manage_nginx {
      class { 'nginx':
      }
    }

    nginx::resource::vhost { 'spi-api':
      www_root    => "${frontend_dir}/api",
      server_name => $api_server_name,
      proxy_set_header => [
        'X-Real-IP $remote_addr',
        'X-Forwarded-For $proxy_add_forwarded_for',
        'Upgrade $http_upgrade',
        'Connection "upgrade"',
        'Host $host',
      ],
      location_cfg_append => 
      {
        'proxy_http_version' => '1.1',
        'proxy_pass'         => "http://127.0.0.1:${proxy_port}/"
      }
    }

    nginx::resource::vhost { 'spi-web':
      www_root    => "${frontend_dir}/S-Pi-Web",
      index       => ['overview.html'],
      server_name => $web_server_name,
      try_files   => ['$uri $uri/ =404'],
    }
  }
}

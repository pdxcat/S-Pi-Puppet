class spi(
  $nginx                    = false,
  $manage_nginx             = true,
  $frontend_dir             = '/var/www/spi',
  $backend_dir              = '/opt/s-pi',
  $backend_repo_source      = 'https://github.com/Team-B-Capstone/S-Pi-Backend.git',
  $frontend_repo_source     = 'https://github.com/Team-B-Capstone/S-Pi-Web.git',
  $api_server_name          = undef,
  $web_server_name          = undef,
  $proxy_port               = 9000,
) {

  if $operatingsystem != 'Ubuntu' {
    fail("The S-PI puppet module requires Ubuntu")
  }

  ensure_packages(['gcc', 'maven', 'ant', 'python', 'openssh-server'])


  vcsrepo { "${backend_dir}/api":
    ensure   => present,
    provider => 'git',
    source   => $backend_repo_source,
  }

  vcsrepo { "${frontend_dir}/S-Pi-Web":
    ensure   => present,
    provider => 'git',
    source   => $frontend_repo_source,
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
        'X-Forwarded-For $proxy_add_x_forwarded_for',
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
      www_root       => "${frontend_dir}/S-Pi-Web",
      listen_options => ' default',
      index_files    => ['overview.html'],
      server_name    => $web_server_name,
      try_files      => ['$uri $uri/ =404'],
    }
  }
}

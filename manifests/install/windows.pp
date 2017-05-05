class filebeat::install::windows {
  $base_filename = regsubst($filebeat::source_zip, '^.*[\/|\\]([^\/|\\]+)\.zip$', '\1')
  $foldername = 'Filebeat'
  $dest_dir = "${filebeat::install_dir}/${foldername}"

  file { $filebeat::install_dir:
    ensure => directory,
  }

  exec { "unzip ${filebeat::source_zip}":
    command  => "\$sh=New-Object -COM Shell.Application;\$sh.namespace((Convert-Path '${filebeat::install_dir}')).Copyhere(\$sh.namespace((Convert-Path '${filebeat::source_zip}')).items(), 16)",
    creates  => $dest_dir,
    provider => powershell,
    require  => [
      File[$filebeat::install_dir],
    ],
  }

  exec { 'rename folder':
    command  => "Rename-Item '${filebeat::install_dir}/${base_filename}' ${foldername}",
    creates  => $dest_dir,
    provider => powershell,
    require  => Exec["unzip ${filebeat::source_zip}"],
  }

  exec { "install ${base_filename}":
    cwd      => $dest_dir,
    command  => './install-service-filebeat.ps1',
    onlyif   => "if(Get-WmiObject -Class Win32_Service -Filter \"Name=\'${foldername}\'\") { exit 1 } else { exit 0 }",
    provider => powershell,
    require  => Exec['rename folder'],
  }
}

class winexitcode {
  file { "c:\\tmp":
    ensure  => directory,
    mode    => '0660',
    group   => 'Administrators',
  }
  ->
  file { "c:\\tmp\\test.bat":
    ensure  => file,
    mode    => '0660',
    group   => 'Administrators',
    content => 'exit /b %1',
  }
}

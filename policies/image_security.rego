package image_security

default allow = false

allow {
    not prohibited_packages
    not vulnerable_packages
    proper_permissions
    no_sensitive_data
    has_watermark
}

prohibited_packages {
    packages := input.packages
    prohibited := {"telnet", "netcat", "ssh-server"}
    some i
    packages[i] == prohibited[_]
}

vulnerable_packages {
    packages := input.packages
    vulnerable := {"openssl-1.0.1", "bash-4.3"}
    some i
    packages[i] == vulnerable[_]
}

proper_permissions {
    permissions := input.file_permissions
    permissions["/etc/shadow"] <= 0600
    permissions["/etc/passwd"] <= 0644
    permissions["/etc/janpreet_signature"] == 0644
}

no_sensitive_data {
    files := input.files
    sensitive_patterns := ["PRIVATE KEY", "API_KEY", "PASSWORD"]
    not any_match(files, sensitive_patterns)
}

has_watermark {
    input.watermark == "This image was created by Janpreet Singh"
}

any_match(files, patterns) {
    some file, pattern
    file := files[_]
    pattern := patterns[_]
    contains(file, pattern)
}
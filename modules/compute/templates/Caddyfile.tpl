# HTTP-only fallback for raw IP access
http://:80 {
    reverse_proxy nightscout:1337
}

# Your domain with automatic HTTPS
${domain} {
    encode gzip
    reverse_proxy nightscout:1337
}
#!/bin/bash

echo "Generating index page with Pagefind..."

wget https://github.com/Pagefind/pagefind/releases/download/v1.3.0/pagefind_extended-v1.3.0-x86_64-unknown-linux-musl.tar.gz
tar -zxvf pagefind_extended-v1.3.0-x86_64-unknown-linux-musl.tar.gz
./pagefind_extended --site public --glob="{posts}/*/*.html"

echo "Index page generated successfully."

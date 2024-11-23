#!/bin/bash

tarball_url=https://gitlab.com/pdftk-java/pdftk/-/archive/v3.3.3/pdftk-v3.3.3.zip
temp_dir=$(mktemp -d /tmp/compile.XXXXXXXXXX)

echo "Serving files from /tmp on $PORT"
cd /tmp
python -m http.server $PORT &

cd $temp_dir
echo "Temp dir: $temp_dir"

# Download and extract source
echo "Downloading $tarball_url"
curl -L $tarball_url > pdftk.zip
unzip pdftk.zip

# Install Java and required build tools
echo "Setting up build environment"
apt-get update
apt-get install -y openjdk-17-jdk gradle

# Build pdftk-java
echo "Building pdftk-java"
(
    cd pdftk-*

    # Build using gradle
    gradle clean build

    # Create distribution directory
    mkdir -p dist/pdftk
    cp build/libs/pdftk-*.jar dist/pdftk/

    # Create wrapper script
    cat > dist/pdftk/pdftk <<'EOF'
#!/bin/bash
java -jar "$(dirname "$0")/pdftk-$(cat "$(dirname "$0")/version").jar" "$@"
EOF
    chmod +x dist/pdftk/pdftk

    # Package everything
    cd dist
    zip -9 /tmp/pdftk.zip pdftk/*
)

# Keep the server running
while true
do
    sleep 1
    echo "."
done

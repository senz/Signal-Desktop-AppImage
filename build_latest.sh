#!/bin/bash

#     This program is free software: you can redistribute it and/or modify
#     it under the terms of the GNU Affero General Public License as
#     published by the Free Software Foundation, either version 3 of the
#     License, or (at your option) any later version.
#
#     This program is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU Affero General Public License for more details.
#
#     You should have received a copy of the GNU Affero General Public License
#     along with this program.  If not, see <https://www.gnu.org/licenses/>.

set -eop pipefail
# Install dependencies
sudo apt-get update
sudo apt-get install build-essential -y
sudo apt-get install python3 -y

sudo apt-get install curl -y
sudo apt-get install git -y
sudo apt-get install git-lfs -y

# Install AppImage dependencies
sudo apt-get install fuse libfuse2 -y
wget https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage -O /tmp/appimagetool
chmod +x /tmp/appimagetool
sudo mv /tmp/appimagetool /usr/local/bin/appimagetool


# Install Node.js v22 directly
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash - 
sudo apt-get install -y nodejs


# Clone Signal-Desktop repo
if [ ! -d "Signal-Desktop" ]; then
  echo "Cloning Signal-Desktop repository..."
  git clone https://github.com/signalapp/Signal-Desktop.git
  cd Signal-Desktop
  git-lfs install
else
  echo "Signal-Desktop directory already exists. Skipping clone."
  cd Signal-Desktop
fi

# Build Signal

sudo npm install --global pnpm
pnpm install --frozen-lockfile

# Edit package.json to add the option to produce .AppImage
python3 << 'EOF'
import json

# Read package.json
with open("package.json", 'r') as file:
    data = json.load(file)

# Find and modify the build.linux.target array
if 'build' in data and 'linux' in data['build'] and 'target' in data['build']['linux']:
    targets = data['build']['linux']['target']
    if isinstance(targets, list) and 'AppImage' not in targets:
        targets.append('AppImage')
        print("Added AppImage to build targets")
    else:
        print("AppImage already in targets or targets is not a list")
else:
    print("Could not find build.linux.target in package.json")

# Write back to package.json
with open("package.json", 'w') as file:
    json.dump(data, file, indent=2)
EOF

# Build
pnpm run build-release
echo "Output is in Signal-Desktop/release/"


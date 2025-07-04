## run chef kitchen-tests for macOS

cd ~
if [ ! -d chef ]
then
	git clone https://github.com/chef/chef
fi
cd chef
git fetch origin
git checkout $TEST_BRANCH
git pull

which brew 2> /dev/null

if [ $? -ne 0 ]
then
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
#  brew install coreutils
curl -L https://omnitruck.chef.io/install.sh | sudo bash -s -- -c current -v $TEST_VERSION
/opt/chef/bin/chef-client -v
/opt/chef/bin/ohai -v
/opt/chef/embedded/bin/rake --version
export OHAI_VERSION=$(sed -n '/ohai .[0-9]/{s/.*(//;s/)//;p;}' Gemfile.lock)
sudo /opt/chef/embedded/bin/gem install appbundler appbundle-updater --no-doc
export GITHUB_SHA=$(git rev-parse --short HEAD)
export GITHUB_REPOSITORY=chef/chef
sudo /opt/chef/embedded/bin/appbundle-updater chef chef $GITHUB_SHA --tarball --github $GITHUB_REPOSITORY
